#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# build.sh - W55RP20-S2E Docker 빌드 시스템 v1.1.0
#
# 변경사항 (v1.1.0):
#   - CLI 옵션 지원 (--project, --output 등)
#   - .build-config 자동 저장/로드
#   - 대화형 모드 (--interactive)
#   - 도움말 및 버전 정보
#
# 기본 사용:
#   ./build.sh                    # 대화형 모드 (향후 구현)
#   ./build.sh --project PATH     # 프로젝트 지정
#   ./build.sh --help             # 도움말
# ============================================================================

VERSION="1.1.0"

# ---- 함수 정의 -------------------------------------------------------------

show_version() {
  cat <<EOF
W55RP20 Build System v${VERSION}
Docker-based build environment for W55RP20 microcontroller
EOF
}

show_help() {
  cat <<EOF
Usage: ./build.sh [OPTIONS]

W55RP20 펌웨어 빌드 시스템

OPTIONS:
  프로젝트 선택:
    --project PATH         프로젝트 디렉토리 지정
    --official             공식 W55RP20-S2E 사용 (기본값)

  산출물:
    --output PATH          빌드 산출물 디렉토리 (기본: ./out)

  빌드 옵션:
    --clean                산출물 정리 후 빌드
    --debug                디버그 빌드 (BUILD_TYPE=Debug)
    --jobs N               병렬 작업 수 (기본: 16)
    --refresh WHAT         캐시 무효화 (apt|sdk|cmake|gcc|toolchain|all)

  편의 기능:
    --no-confirm           확인 없이 즉시 실행
    --quiet                최소 출력 (에러만)
    --verbose              상세 출력 (디버깅용)

  설정 관리:
    --setup                설정 초기화 및 재설정
    --show-config          현재 설정 표시
    --save-config          현재 옵션을 .build-config에 저장

  도움말:
    --help, -h             이 도움말 표시
    --version              버전 정보

EXAMPLES:
  # 기본 빌드
  ./build.sh

  # 사용자 프로젝트 빌드
  ./build.sh --project ~/my-w55rp20-project

  # 산출물 위치 지정
  ./build.sh --project ~/my-project --output ./artifacts

  # 정리 후 빌드
  ./build.sh --clean

  # 자동화 (CI/CD)
  ./build.sh --project ~/proj --no-confirm --quiet

  # 캐시 무효화
  ./build.sh --refresh sdk

ENVIRONMENT VARIABLES (레거시 지원):
  SRC_DIR, OUT_DIR, JOBS, TMPFS_SIZE, BUILD_TYPE, CLEAN, VERBOSE, REFRESH

  우선순위: CLI 옵션 > 환경 변수 > .build-config > 기본값

FILES:
  .build-config          로컬 빌드 설정 (자동 생성)
  build.config           사용자 설정 (선택)

MORE INFO:
  Documentation: ./USER_GUIDE.md
  GitHub: https://github.com/WIZnet-ioNIC/W55RP20-S2E
EOF
}

# 대화형 설정 함수
interactive_setup() {
  echo "╔═══════════════════════════════════════════════════════╗"
  echo "║         W55RP20 펌웨어 빌드 시스템 v${VERSION}              ║"
  echo "╚═══════════════════════════════════════════════════════╝"
  echo ""
  echo "🎯 목표: W55RP20 펌웨어(.uf2)를 빌드합니다"
  echo ""
  echo "📋 빌드할 프로젝트를 선택하세요:"
  echo ""
  echo "  1) 공식 예제 프로젝트 (추천)"
  echo "  2) 내 프로젝트"
  echo ""

  # 프로젝트 선택
  read -r -p "선택 [1-2] (기본값: 1): " project_choice
  project_choice="${project_choice:-1}"

  case "$project_choice" in
    1)
      echo "✓ 공식 예제 프로젝트 선택됨"
      OPT_OFFICIAL=1
      SRC_DIR="./src"
      ;;
    2)
      echo "✓ 내 프로젝트 선택됨"
      echo ""
      echo "📁 프로젝트 경로를 입력하세요:"
      echo ""
      echo "   예시:"
      echo "   • ~/my-w55rp20-project"
      echo "   • /home/user/workspace/w55-firmware"
      echo "   • ../my-project"
      echo ""
      echo "   💡 팁: Tab 키로 자동완성 가능"
      echo ""

      # 프로젝트 경로 입력 (읽기 모드에서 Tab 자동완성 활성화)
      read -e -r -p "프로젝트 경로: " user_project

      # 경로 확장 (~, 상대경로 등)
      user_project=$(eval echo "$user_project")
      user_project=$(readlink -f "$user_project" 2>/dev/null || echo "$user_project")

      echo ""
      echo "✓ 경로 확인 중... $user_project"

      # 경로 검증
      if [ ! -d "$user_project" ]; then
        echo ""
        echo "[ERROR] 디렉토리가 존재하지 않습니다: $user_project" >&2
        exit 1
      fi

      if [ ! -f "$user_project/CMakeLists.txt" ]; then
        echo ""
        echo "[WARN] CMakeLists.txt를 찾을 수 없습니다"
        echo "[WARN] W55RP20 프로젝트가 아닐 수 있습니다"
        echo ""
        read -r -p "계속하시겠습니까? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
          echo "취소되었습니다."
          exit 0
        fi
      else
        echo "   ✓ CMakeLists.txt 발견"
        echo "   ✓ 유효한 W55RP20 프로젝트입니다"
      fi

      OPT_PROJECT="$user_project"
      SRC_DIR="$user_project"
      ;;
    *)
      echo "[ERROR] 잘못된 선택: $project_choice" >&2
      exit 1
      ;;
  esac

  echo ""
  echo "📦 산출물을 어디에 저장할까요?"
  echo ""
  echo "  1) 현재 디렉토리 (./out/)  ← 추천"
  if [ "$project_choice" = "2" ]; then
    echo "  2) 프로젝트 디렉토리 안 ($SRC_DIR/build/)"
  fi
  echo "  3) 직접 지정"
  echo ""

  read -r -p "선택 [1-3] (기본값: 1): " output_choice
  output_choice="${output_choice:-1}"

  case "$output_choice" in
    1)
      OPT_OUTPUT="./out"
      OUT_DIR="./out"
      ;;
    2)
      if [ "$project_choice" = "2" ]; then
        OPT_OUTPUT="$SRC_DIR/build"
        OUT_DIR="$SRC_DIR/build"
      else
        OPT_OUTPUT="./out"
        OUT_DIR="./out"
      fi
      ;;
    3)
      read -e -r -p "산출물 디렉토리: " custom_output
      custom_output=$(eval echo "$custom_output")
      OPT_OUTPUT="$custom_output"
      OUT_DIR="$custom_output"
      ;;
    *)
      echo "[ERROR] 잘못된 선택: $output_choice" >&2
      exit 1
      ;;
  esac

  echo ""
  echo "✓ 산출물 위치: $OUT_DIR"
  echo ""
  echo "⚙️  설정 확인:"
  echo "   • 프로젝트: $SRC_DIR"
  echo "   • 산출물:   $OUT_DIR"
  echo "   • 병렬작업: ${JOBS:-16}개"
  echo "   • 빌드타입: ${BUILD_TYPE:-Release}"
  echo ""

  read -r -p "계속하시겠습니까? [Y/n]: " final_confirm
  if [[ "$final_confirm" =~ ^[Nn]$ ]]; then
    echo "취소되었습니다."
    exit 0
  fi

  echo "✓ 시작합니다!"
  echo ""

  # 설정을 .build-config에 저장
  cat > .build-config <<EOF
# W55RP20 Build Configuration
# Generated: $(date --iso-8601=seconds)

SRC_DIR="$SRC_DIR"
OUT_DIR="$OUT_DIR"
JOBS=${JOBS:-16}
BUILD_TYPE="${BUILD_TYPE:-Release}"
EOF

  echo "💾 설정을 저장했습니다 (.build-config)"
  echo ""
}

# ---- 옵션 파싱 -------------------------------------------------------------

# 옵션 변수 초기화
OPT_PROJECT=""
OPT_OUTPUT=""
OPT_OFFICIAL=0
OPT_CLEAN=0
OPT_DEBUG=0
OPT_JOBS=""
OPT_REFRESH=""
OPT_NO_CONFIRM=0
OPT_QUIET=0
OPT_VERBOSE=0
OPT_SETUP=0
OPT_SHOW_CONFIG=0
OPT_SAVE_CONFIG=0

# 옵션 파싱
while [ $# -gt 0 ]; do
  case "$1" in
    --project)
      if [ -z "${2:-}" ]; then
        echo "[ERROR] --project requires a path argument" >&2
        exit 1
      fi
      OPT_PROJECT="$2"
      shift 2
      ;;
    --output)
      if [ -z "${2:-}" ]; then
        echo "[ERROR] --output requires a path argument" >&2
        exit 1
      fi
      OPT_OUTPUT="$2"
      shift 2
      ;;
    --official)
      OPT_OFFICIAL=1
      shift
      ;;
    --clean)
      OPT_CLEAN=1
      shift
      ;;
    --debug)
      OPT_DEBUG=1
      shift
      ;;
    --jobs)
      if [ -z "${2:-}" ]; then
        echo "[ERROR] --jobs requires a number argument" >&2
        exit 1
      fi
      OPT_JOBS="$2"
      shift 2
      ;;
    --refresh)
      if [ -z "${2:-}" ]; then
        echo "[ERROR] --refresh requires an argument (apt|sdk|cmake|gcc|toolchain|all)" >&2
        exit 1
      fi
      OPT_REFRESH="$2"
      shift 2
      ;;
    --no-confirm)
      OPT_NO_CONFIRM=1
      shift
      ;;
    --quiet)
      OPT_QUIET=1
      shift
      ;;
    --verbose)
      OPT_VERBOSE=1
      shift
      ;;
    --setup)
      OPT_SETUP=1
      shift
      ;;
    --show-config)
      OPT_SHOW_CONFIG=1
      shift
      ;;
    --save-config)
      OPT_SAVE_CONFIG=1
      shift
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    --version)
      show_version
      exit 0
      ;;
    -*)
      echo "[ERROR] Unknown option: $1" >&2
      echo "Use --help for usage information" >&2
      exit 1
      ;;
    *)
      echo "[ERROR] Unexpected argument: $1" >&2
      echo "Use --help for usage information" >&2
      exit 1
      ;;
  esac
done

# 옵션 충돌 검사
if [ "$OPT_OFFICIAL" -eq 1 ] && [ -n "$OPT_PROJECT" ]; then
  echo "[ERROR] --official and --project cannot be used together" >&2
  exit 1
fi

if [ "$OPT_QUIET" -eq 1 ] && [ "$OPT_VERBOSE" -eq 1 ]; then
  echo "[ERROR] --quiet and --verbose cannot be used together" >&2
  exit 1
fi

# --show-config만 실행
if [ "$OPT_SHOW_CONFIG" -eq 1 ]; then
  echo "Current build configuration:"
  echo ""
  if [ -f ".build-config" ]; then
    cat .build-config
  else
    echo "No .build-config file found"
    echo "Run ./build.sh to create one"
  fi
  echo ""
  if [ -f "build.config" ]; then
    echo "User config (build.config):"
    cat build.config
  fi
  exit 0
fi

# --setup: 대화형 설정 모드
if [ "$OPT_SETUP" -eq 1 ]; then
  interactive_setup
  # interactive_setup에서 SRC_DIR, OUT_DIR 등이 설정됨
  # 이후 정상적으로 빌드 진행
fi

# ---- 사용자 설정 로드 (build.config) ----------------------------------------
# build.config 파일이 있으면 로드 (JOBS, TMPFS_SIZE 등 사전 설정 가능)
# 우선순위: 낮음 (CLI > .build-config > build.config > 기본값)
if [ -f "build.config" ]; then
  if [ "$OPT_QUIET" -eq 0 ]; then
    echo "[INFO] Loading build.config"
  fi
  # shellcheck disable=SC1091
  source "build.config"
fi

# ---- 로컬 설정 로드 (.build-config) -----------------------------------------
# .build-config가 있고 --setup이 아니면 로드
# 우선순위: 중간 (CLI > .build-config > build.config)
if [ -f ".build-config" ] && [ "$OPT_SETUP" -eq 0 ]; then
  if [ "$OPT_QUIET" -eq 0 ]; then
    echo "[INFO] Loading .build-config"
  fi
  # shellcheck disable=SC1091
  source ".build-config"
fi

# ---- CLI 옵션으로 환경 변수 덮어쓰기 ----------------------------------------

# 프로젝트 경로
if [ -n "$OPT_PROJECT" ]; then
  SRC_DIR="$OPT_PROJECT"
elif [ "$OPT_OFFICIAL" -eq 1 ]; then
  SRC_DIR="./src"
fi

# 산출물 경로
if [ -n "$OPT_OUTPUT" ]; then
  OUT_DIR="$OPT_OUTPUT"
fi

# 빌드 옵션
if [ "$OPT_CLEAN" -eq 1 ]; then
  CLEAN=1
fi

if [ "$OPT_DEBUG" -eq 1 ]; then
  BUILD_TYPE="Debug"
fi

if [ -n "$OPT_JOBS" ]; then
  JOBS="$OPT_JOBS"
fi

if [ -n "$OPT_REFRESH" ]; then
  REFRESH="$OPT_REFRESH"
fi

# 출력 모드
if [ "$OPT_QUIET" -eq 1 ]; then
  VERBOSE=0
elif [ "$OPT_VERBOSE" -eq 1 ]; then
  VERBOSE=1
fi

# ---- 기본값(설정 파일 없거나 미지정 시) --------------------------------------
: "${JOBS:=16}"
: "${TMPFS_SIZE:=24g}"
: "${IMAGE:=w55rp20:auto}"
: "${PLATFORM:=linux/amd64}"
: "${SRC_DIR:=}"
: "${OUT_DIR:=./out}"

# 이미지 자동 빌드 (이미지 없으면 자동 빌드, 있으면 재사용)
: "${AUTO_BUILD_IMAGE:=1}"

# 레포 업데이트(fetch/checkout/submodule update)
: "${UPDATE_REPO:=0}"

# OUT_DIR 정리(산출물 삭제)
: "${CLEAN:=0}"

# 빌드 타입(Release/Debug)
: "${BUILD_TYPE:=Release}"

# 상세 정보 출력 (디버깅용)
: "${VERBOSE:=0}"

# ===== Refresh control (CSV) =====
# REFRESH를 지정하면, build cache를 해당 구간만 깨서 "이미지 재빌드"를 유도한다.
# Options: apt, sdk, cmake, gcc, toolchain(=cmake+gcc), all
: "${REFRESH:=}"

# ---- 설정 저장 (--save-config) ---------------------------------------------
if [ "$OPT_SAVE_CONFIG" -eq 1 ]; then
  cat > .build-config <<EOF
# W55RP20 Build Configuration
# Generated: $(date --iso-8601=seconds)

SRC_DIR="$SRC_DIR"
OUT_DIR="$OUT_DIR"
JOBS=$JOBS
BUILD_TYPE="$BUILD_TYPE"
EOF
  echo "[INFO] Configuration saved to .build-config"
  exit 0
fi

# ---- Verbose 정보 출력 ------------------------------------------------------
if [ "$VERBOSE" = "1" ]; then
  echo "[INFO] ===== build.sh v${VERSION} ====="
  echo "[INFO] SRC_DIR=$SRC_DIR"
  echo "[INFO] OUT_DIR=$OUT_DIR"
  echo "[INFO] JOBS=$JOBS"
  echo "[INFO] TMPFS_SIZE=$TMPFS_SIZE"
  echo "[INFO] IMAGE=$IMAGE"
  echo "[INFO] PLATFORM=$PLATFORM"
  echo "[INFO] AUTO_BUILD_IMAGE=$AUTO_BUILD_IMAGE"
  echo "[INFO] UPDATE_REPO=$UPDATE_REPO"
  echo "[INFO] CLEAN=$CLEAN"
  echo "[INFO] BUILD_TYPE=$BUILD_TYPE"
  echo "[INFO] VERBOSE=$VERBOSE"
  echo "[INFO] ==============================="
fi

# ---- REFRESH 토큰 파싱 ------------------------------------------------------
if [ "$VERBOSE" = "1" ]; then
  echo "[INFO] REFRESH options (CSV): apt,sdk,cmake,gcc,toolchain,all"
fi

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

if [ "$VERBOSE" = "1" ]; then
  echo "[INFO] REFRESH: APT=${REFRESH_APT_BUST:-0} SDK=${REFRESH_SDK_BUST:-0} CMAKE=${REFRESH_CMAKE_BUST:-0} GCC=${REFRESH_GCC_BUST:-0}"
fi

# REFRESH 지정되었는데 AUTO_BUILD_IMAGE=0이면 warning
# - 명시적 지정은 존중하되, 초보자 복붙 실수 대비 정보 제공
if [ -n "$REFRESH_APT_BUST$REFRESH_SDK_BUST$REFRESH_CMAKE_BUST$REFRESH_GCC_BUST" ]; then
  if [ "$AUTO_BUILD_IMAGE" = "0" ]; then
    if [ "$VERBOSE" = "1" ]; then
      echo "" >&2
      echo "[WARN] ============================================================" >&2
      echo "[WARN] REFRESH가 지정되었지만 AUTO_BUILD_IMAGE=0입니다." >&2
      echo "[WARN] 이미지 재빌드가 필요하지만 수행되지 않으므로," >&2
      echo "[WARN] REFRESH가 적용되지 않습니다." >&2
      echo "[WARN]" >&2
      echo "[WARN] 의도한 것이 아니라면:" >&2
      echo "[WARN]   REFRESH=\"${REFRESH}\" ./build.sh" >&2
      echo "[WARN] ============================================================" >&2
      echo "" >&2
    fi
  fi
fi

# ---- 빌드 전 확인 및 Progress Display -------------------------------------

# .build-config가 있고 OPT_SETUP이 아닌 경우 저장된 설정 사용 알림
if [ -f ".build-config" ] && [ "$OPT_SETUP" -eq 0 ] && [ "$OPT_QUIET" -eq 0 ]; then
  if [ -z "$OPT_PROJECT" ] && [ -z "$OPT_OUTPUT" ]; then
    # CLI 옵션으로 덮어쓰지 않은 경우만 알림
    echo "💾 저장된 설정을 사용합니다:"
    echo "   • 프로젝트: $SRC_DIR"
    echo "   • 산출물:   $OUT_DIR"
    echo ""
    echo "다른 설정을 사용하려면: ./build.sh --setup"
    echo ""
  fi
fi

# --no-confirm이 아니면 확인 프롬프트
if [ "$OPT_NO_CONFIRM" -eq 0 ] && [ "$OPT_QUIET" -eq 0 ]; then
  read -r -p "계속하시겠습니까? [Y/n]: " build_confirm
  if [[ "$build_confirm" =~ ^[Nn]$ ]]; then
    echo "취소되었습니다."
    exit 0
  fi
  echo "✓ 시작합니다!"
  echo ""
fi

# ---- w55build.sh 실행 -------------------------------------------------------

# w55build.sh 경로(같은 폴더에 있다고 가정)
W55BUILD="${W55BUILD:-./w55build.sh}"

if [[ ! -f "$W55BUILD" ]]; then
  echo "[ERROR] $W55BUILD 를 찾을 수 없습니다. (현재 위치: $(pwd))" >&2
  exit 1
fi

# /usr/bin/time -v 가 없으면 그냥 time 없이 실행 (RSS 피크 측정 불가)
TIMEBIN="/usr/bin/time"
if [ "$VERBOSE" = "1" ]; then
  echo "[INFO] w55build.sh 실행: $W55BUILD"
  echo "[INFO] 전달 변수:"
  echo "[INFO]   SRC_DIR=$SRC_DIR"
  echo "[INFO]   OUT_DIR=$OUT_DIR"
  echo "[INFO]   JOBS=$JOBS"
  echo "[INFO]   TMPFS_SIZE=$TMPFS_SIZE"
  echo "[INFO]   IMAGE=$IMAGE"
  echo "[INFO]   PLATFORM=$PLATFORM"
  echo "[INFO]   AUTO_BUILD_IMAGE=$AUTO_BUILD_IMAGE"
  echo "[INFO]   UPDATE_REPO=$UPDATE_REPO"
  echo "[INFO]   CLEAN=$CLEAN"
  echo "[INFO]   BUILD_TYPE=$BUILD_TYPE"
  echo "[INFO]   VERBOSE=$VERBOSE"
  echo "[INFO]   REFRESH_APT_BUST=$REFRESH_APT_BUST"
  echo "[INFO]   REFRESH_SDK_BUST=$REFRESH_SDK_BUST"
  echo "[INFO]   REFRESH_CMAKE_BUST=$REFRESH_CMAKE_BUST"
  echo "[INFO]   REFRESH_GCC_BUST=$REFRESH_GCC_BUST"
fi

# 빌드 실행
BUILD_EXIT_CODE=0
if [[ -x "$TIMEBIN" ]]; then
  "$TIMEBIN" -v env \
    SRC_DIR="$SRC_DIR" OUT_DIR="$OUT_DIR" \
    JOBS="$JOBS" TMPFS_SIZE="$TMPFS_SIZE" IMAGE="$IMAGE" PLATFORM="$PLATFORM" \
    AUTO_BUILD_IMAGE="$AUTO_BUILD_IMAGE" UPDATE_REPO="$UPDATE_REPO" CLEAN="$CLEAN" BUILD_TYPE="$BUILD_TYPE" \
    VERBOSE="$VERBOSE" \
    REFRESH_APT_BUST="$REFRESH_APT_BUST" \
    REFRESH_SDK_BUST="$REFRESH_SDK_BUST" \
    REFRESH_CMAKE_BUST="$REFRESH_CMAKE_BUST" \
    REFRESH_GCC_BUST="$REFRESH_GCC_BUST" \
    "$W55BUILD" || BUILD_EXIT_CODE=$?
else
  if [ "$VERBOSE" = "1" ]; then
    echo "[WARN] /usr/bin/time 이 없습니다. (sudo apt-get install -y time)" >&2
  fi
  env \
    SRC_DIR="$SRC_DIR" OUT_DIR="$OUT_DIR" \
    JOBS="$JOBS" TMPFS_SIZE="$TMPFS_SIZE" IMAGE="$IMAGE" PLATFORM="$PLATFORM" \
    AUTO_BUILD_IMAGE="$AUTO_BUILD_IMAGE" UPDATE_REPO="$UPDATE_REPO" CLEAN="$CLEAN" BUILD_TYPE="$BUILD_TYPE" \
    VERBOSE="$VERBOSE" \
    REFRESH_APT_BUST="$REFRESH_APT_BUST" \
    REFRESH_SDK_BUST="$REFRESH_SDK_BUST" \
    REFRESH_CMAKE_BUST="$REFRESH_CMAKE_BUST" \
    REFRESH_GCC_BUST="$REFRESH_GCC_BUST" \
    "$W55BUILD" || BUILD_EXIT_CODE=$?
fi

# ---- 빌드 후 처리 -----------------------------------------------------------

if [ "$BUILD_EXIT_CODE" -eq 0 ]; then
  if [ "$OPT_QUIET" -eq 0 ]; then
    echo ""
    echo "✓ 빌드 성공!"
    echo ""

    # 산출물 정보 표시
    if [ -d "$OUT_DIR" ]; then
      echo "📦 산출물 위치: $OUT_DIR"

      # .uf2 파일 찾기
      UF2_FILES=$(find "$OUT_DIR" -name "*.uf2" 2>/dev/null || true)
      if [ -n "$UF2_FILES" ]; then
        echo ""
        echo "생성된 파일:"
        while IFS= read -r uf2_file; do
          if [ -f "$uf2_file" ]; then
            file_size=$(du -h "$uf2_file" | cut -f1)
            file_name=$(basename "$uf2_file")
            echo "   → $file_name  ($file_size)"
          fi
        done <<< "$UF2_FILES"
      fi
    fi

    echo ""
  fi
  exit 0
else
  if [ "$OPT_QUIET" -eq 0 ]; then
    echo "" >&2
    echo "✗ 빌드 실패 (exit code: $BUILD_EXIT_CODE)" >&2
    echo "" >&2
  fi
  exit "$BUILD_EXIT_CODE"
fi
