#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# build.sh - W55RP20-S2E Docker 빌드 "귀찮음 제거" 래퍼
#
# 목적:
#   - 매번 JOBS=..., TMPFS_SIZE=... 같은 환경변수 치기 귀찮아서 만든 실행용 스크립트
#   - 기본값을 여기서 고정하고, 필요하면 실행 시 덮어쓰기(환경변수)만 하면 됨
#
# 기본 사용:
#   ./build.sh
#
# (권장) 처음 1회: 이미지까지 자동으로 빌드하고 싶으면:
#   AUTO_BUILD_IMAGE=1 ./build.sh
#
# ----------------------------------------------------------------------------
# 상황별 "한 줄" 레시피 (주석으로만 제공)
#
# 1) 산출물(out) 정리 후 빌드:
#   CLEAN=1 ./build.sh
#
# 2) 레포 갱신(fetch/checkout/submodule update)까지 포함:
#   UPDATE_REPO=1 ./build.sh
#
# 3) ccache까지 싹 비우고(진짜 풀빌드에 가까운) 측정:
#   rm -rf "$HOME/.ccache-w55rp20"/* && CLEAN=1 ./build.sh
#
# 4) Docker 이미지 자체를 완전 새로(캐시 없이) 빌드 후 실행:
#   sudo docker buildx build --no-cache --platform linux/amd64 -t w55rp20:auto --load -f Dockerfile .
#   ./build.sh
#
# 5) 병렬도/램디스크 크기 바꾸기(일회성):
#   JOBS=8 TMPFS_SIZE=12g ./build.sh
#
# 6) 컨테이너 내부로 들어가서 수동 디버깅:
#   sudo docker run --rm -it --entrypoint bash w55rp20:auto
#
# 7) 특정 브랜치/태그/커밋으로 맞추기:
#   REPO_REF=vX.Y.Z ./build.sh
#
# 8) Docker 이미지 일부만 refresh(캐시 깨기):
#   REFRESH="apt" ./build.sh         # apt 패키지만
#   REFRESH="sdk" ./build.sh         # pico-sdk + picotool만
#   REFRESH="cmake" ./build.sh       # cmake만
#   REFRESH="gcc" ./build.sh         # arm-none-eabi-gcc만
#   REFRESH="toolchain" ./build.sh   # cmake + gcc (별칭)
#   REFRESH="cmake,gcc" ./build.sh   # 위와 동일
#   REFRESH="all" ./build.sh         # 전부
# ============================================================================
#

# ---- 기본값(여기만 바꾸면 됨) ----------------------------------------------
: "${JOBS:=16}"
: "${TMPFS_SIZE:=24g}"
: "${IMAGE:=w55rp20:auto}"
: "${PLATFORM:=linux/amd64}"

# AUTO_BUILD_IMAGE=1 이면 w55build.sh가 이미지 없을 때 자동 빌드 시도
: "${AUTO_BUILD_IMAGE:=0}"

# 레포 업데이트(fetch/checkout/submodule update)
: "${UPDATE_REPO:=0}"

# OUT_DIR 정리(산출물 삭제)
: "${CLEAN:=0}"

# 빌드 타입(Release/Debug)
: "${BUILD_TYPE:=Release}"

# ===== Refresh control (CSV) =====
# REFRESH를 지정하면, build cache를 해당 구간만 깨서 "이미지 재빌드"를 유도한다.
# Options: apt, sdk, cmake, gcc, toolchain(=cmake+gcc), all
: "${REFRESH:=}"

echo "[INFO] REFRESH options (CSV): apt,sdk,cmake,gcc,toolchain,all"

REFRESH_APT=0
REFRESH_SDK=0
REFRESH_CMAKE=0
REFRESH_GCC=0
REFRESH_ALL=0

if [ -n "${REFRESH}" ]; then
  _tokens="$(echo "${REFRESH}" | tr ',' ' ')"
  for t in ${_tokens}; do
    case "${t}" in
      apt) REFRESH_APT=1 ;;
      sdk) REFRESH_SDK=1 ;;
      cmake) REFRESH_CMAKE=1 ;;
      gcc) REFRESH_GCC=1 ;;
      toolchain) REFRESH_CMAKE=1; REFRESH_GCC=1 ;;  # 별칭: cmake + gcc
      all) REFRESH_ALL=1 ;;
      "") ;;
      *)
        echo "[ERROR] invalid REFRESH token: '${t}' (allowed: apt,sdk,cmake,gcc,toolchain,all)" >&2
        exit 2
        ;;
    esac
  done
fi

if [ "${REFRESH_ALL}" -eq 1 ]; then
  REFRESH_APT=1
  REFRESH_SDK=1
  REFRESH_CMAKE=1
  REFRESH_GCC=1
fi

_BUST="$(date +%s)"

# w55build.sh가 읽을 변수들 생성
# - 값이 있으면 w55build.sh가 해당 레이어 재빌드
# - timestamp로 매번 캐시 무효화 보장
export REFRESH_APT_BUST=""
export REFRESH_SDK_BUST=""
export REFRESH_CMAKE_BUST=""
export REFRESH_GCC_BUST=""

if [ "${REFRESH_APT}" -eq 1 ]; then
  REFRESH_APT_BUST="$_BUST"
fi
if [ "${REFRESH_SDK}" -eq 1 ]; then
  REFRESH_SDK_BUST="$_BUST"
fi
if [ "${REFRESH_CMAKE}" -eq 1 ]; then
  REFRESH_CMAKE_BUST="$_BUST"
fi
if [ "${REFRESH_GCC}" -eq 1 ]; then
  REFRESH_GCC_BUST="$_BUST"
fi

echo "[INFO] REFRESH: APT=${REFRESH_APT_BUST:-0} SDK=${REFRESH_SDK_BUST:-0} CMAKE=${REFRESH_CMAKE_BUST:-0} GCC=${REFRESH_GCC_BUST:-0}"

# w55build.sh 경로(같은 폴더에 있다고 가정)
W55BUILD="${W55BUILD:-./w55build.sh}"

if [[ ! -f "$W55BUILD" ]]; then
  echo "[ERROR] $W55BUILD 를 찾을 수 없습니다. (현재 위치: $(pwd))" >&2
  exit 1
fi

# /usr/bin/time -v 가 없으면 그냥 time 없이 실행 (RSS 피크 측정 불가)
TIMEBIN="/usr/bin/time"
if [[ -x "$TIMEBIN" ]]; then
  exec "$TIMEBIN" -v env \
    JOBS="$JOBS" TMPFS_SIZE="$TMPFS_SIZE" IMAGE="$IMAGE" PLATFORM="$PLATFORM" \
    AUTO_BUILD_IMAGE="$AUTO_BUILD_IMAGE" UPDATE_REPO="$UPDATE_REPO" CLEAN="$CLEAN" BUILD_TYPE="$BUILD_TYPE" \
    REFRESH_APT_BUST="$REFRESH_APT_BUST" \
    REFRESH_SDK_BUST="$REFRESH_SDK_BUST" \
    REFRESH_CMAKE_BUST="$REFRESH_CMAKE_BUST" \
    REFRESH_GCC_BUST="$REFRESH_GCC_BUST" \
    "$W55BUILD"
else
  echo "[WARN] /usr/bin/time 이 없습니다. (sudo apt-get install -y time)" >&2
  exec env \
    JOBS="$JOBS" TMPFS_SIZE="$TMPFS_SIZE" IMAGE="$IMAGE" PLATFORM="$PLATFORM" \
    AUTO_BUILD_IMAGE="$AUTO_BUILD_IMAGE" UPDATE_REPO="$UPDATE_REPO" CLEAN="$CLEAN" BUILD_TYPE="$BUILD_TYPE" \
    REFRESH_APT_BUST="$REFRESH_APT_BUST" \
    REFRESH_SDK_BUST="$REFRESH_SDK_BUST" \
    REFRESH_CMAKE_BUST="$REFRESH_CMAKE_BUST" \
    REFRESH_GCC_BUST="$REFRESH_GCC_BUST" \
    "$W55BUILD"
fi
