#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# build.sh - "난 입력하기 싫다"를 위한 실행 래퍼
#
# 원칙:
#   - 기본 실행은 그냥 "$W55BUILD"
#   - 모든 기본값은 여기서 세팅하고, w55build.sh는 그대로 둔다.
#   - 필요할 때만(꼼수) 환경변수로 오버라이드 가능.
#
# ----------------------------------------------------------------------------
# 상황별 레시피(필요할 때만)
#
# 1) 기본 빌드:
#   ./w55build.sh
#
# 2) 이미지가 없으면 자동으로 이미지 빌드까지:
#   AUTO_BUILD_IMAGE=1 ./w55build.sh
#
# 3) out(산출물)만 정리하고 다시:
#   CLEAN=1 ./w55build.sh
#
# 4) 레포 갱신(fetch/checkout/submodule update) 포함:
#   UPDATE_REPO=1 ./w55build.sh
#
# 5) 측정용(거의 풀빌드): ccache 비우고 out 정리 후
#   rm -rf "$HOME/.ccache-w55rp20"/* && CLEAN=1 ./w55build.sh
#
# 6) 병렬도/램디스크만 잠깐 바꾸기(꼼수):
#   JOBS=8 TMPFS_SIZE=12g ./w55build.sh
#
# 7) 특정 태그/커밋으로 맞추기(꼼수):
#   REPO_REF=vX.Y.Z ./w55build.sh
#
# ============================================================================

# ===== Refresh control (CSV) =====
# Usage:
#   ./build.sh
#   REFRESH="apt,sdk" ./build.sh
# Options: apt, sdk, toolchain, all
: "${REFRESH:=}"

echo "[INFO] REFRESH options (CSV): apt,sdk,toolchain,all (e.g., REFRESH=\"apt,sdk\")"

# Parse CSV -> flags
REFRESH_APT=0
REFRESH_SDK=0
REFRESH_TOOLCHAIN=0
REFRESH_ALL=0

if [ -n "${REFRESH}" ]; then
  # allow commas/spaces
  _tokens="$(echo "${REFRESH}" | tr ',' ' ')"
  for t in ${_tokens}; do
    case "${t}" in
      apt) REFRESH_APT=1 ;;
      sdk) REFRESH_SDK=1 ;;
      toolchain) REFRESH_TOOLCHAIN=1 ;;
      all) REFRESH_ALL=1 ;;
      "")
        ;;
      *)
        echo "[ERROR] invalid REFRESH token: '${t}' (allowed: apt,sdk,toolchain,all)"
        exit 2
        ;;
    esac
  done
fi

# all overrides others
if [ "${REFRESH_ALL}" -eq 1 ]; then
  REFRESH_APT=1
  REFRESH_SDK=1
  REFRESH_TOOLCHAIN=1
fi

# BuildKit cache-bust args (only for selected scopes)
# One timestamp is enough (makes cache bust deterministic per run)
_BUST="$(date +%s)"
DOCKER_BUILD_EXTRA_ARGS=""

if [ "${REFRESH_APT}" -eq 1 ]; then
  DOCKER_BUILD_EXTRA_ARGS="${DOCKER_BUILD_EXTRA_ARGS} --build-arg REFRESH_APT=${_BUST}"
fi
if [ "${REFRESH_SDK}" -eq 1 ]; then
  DOCKER_BUILD_EXTRA_ARGS="${DOCKER_BUILD_EXTRA_ARGS} --build-arg REFRESH_SDK=${_BUST}"
fi
if [ "${REFRESH_TOOLCHAIN}" -eq 1 ]; then
  DOCKER_BUILD_EXTRA_ARGS="${DOCKER_BUILD_EXTRA_ARGS} --build-arg REFRESH_TOOLCHAIN=${_BUST}"
fi

export DOCKER_BUILD_EXTRA_ARGS
echo "[INFO] DOCKER_BUILD_EXTRA_ARGS=${DOCKER_BUILD_EXTRA_ARGS:-<none>}"

# ---- 기본값 영역(평소엔 건드리지 말고 그냥 "$W55BUILD") -----------------------
# 병렬도 / RAM 빌드 공간
: "${JOBS:=16}"
: "${TMPFS_SIZE:=24g}"

# 이미지/플랫폼
: "${IMAGE:=w55rp20:auto}"
: "${PLATFORM:=linux/amd64}"

# 기본은 "자동 이미지 빌드 안 함"
: "${AUTO_BUILD_IMAGE:=0}"

# 기본은 "레포 자동 업데이트 안 함"
: "${UPDATE_REPO:=0}"

# 기본은 "out 정리 안 함"
: "${CLEAN:=0}"

# 기본은 Release
: "${BUILD_TYPE:=Release}"

# 경로(대개 수정 불필요)
: "${W55BUILD:=./w55build.sh}"
# ----------------------------------------------------------------------------

if [[ ! -f "$W55BUILD" ]]; then
  echo "[ERROR] $W55BUILD 를 찾을 수 없습니다. (현재 위치: $(pwd))" >&2
  exit 1
fi

# time 있으면 측정 붙이고, 없으면 그냥 실행
if [[ -x /usr/bin/time ]]; then
  exec /usr/bin/time -v env \
    JOBS="$JOBS" TMPFS_SIZE="$TMPFS_SIZE" IMAGE="$IMAGE" PLATFORM="$PLATFORM" \
    AUTO_BUILD_IMAGE="$AUTO_BUILD_IMAGE" UPDATE_REPO="$UPDATE_REPO" CLEAN="$CLEAN" BUILD_TYPE="$BUILD_TYPE" \
    W55BUILD="$W55BUILD" \
    "$W55BUILD"
else
  exec env \
    JOBS="$JOBS" TMPFS_SIZE="$TMPFS_SIZE" IMAGE="$IMAGE" PLATFORM="$PLATFORM" \
    AUTO_BUILD_IMAGE="$AUTO_BUILD_IMAGE" UPDATE_REPO="$UPDATE_REPO" CLEAN="$CLEAN" BUILD_TYPE="$BUILD_TYPE" \
    W55BUILD="$W55BUILD" \
    "$W55BUILD"
fi
