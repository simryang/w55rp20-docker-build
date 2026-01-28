#!/usr/bin/env bash
# build-unified.sh - W55RP20 통합 빌드 시스템 (All-in-One)
# Linux 컨테이너 + Windows 컨테이너 자동 선택 또는 사용자 지정

set -euo pipefail

VERSION="1.2.0-unified"

# ============================================================================
# 함수
# ============================================================================

show_help() {
  cat <<'EOF'
╔══════════════════════════════════════════════════════════════╗
║  W55RP20 통합 빌드 시스템 v1.2.0-unified                     ║
║  Linux 컨테이너 + Windows 컨테이너 All-in-One              ║
╚══════════════════════════════════════════════════════════════╝

Usage: ./build-unified.sh [OPTIONS]

컨테이너 선택:
  --linux              Linux 컨테이너 사용 (WSL2 기반, 크로스 플랫폼)
  --windows            Windows 컨테이너 사용 (WSL2 불필요, 네이티브)
  --auto               자동 선택 (기본값, Docker 모드에 따라)

빌드 옵션:
  --project PATH       프로젝트 디렉토리
  --output PATH        빌드 산출물 디렉토리 (기본: ./out)
  --debug              디버그 빌드
  --clean              산출물 정리 후 빌드
  --update-repo        Git 레포 업데이트
  --jobs N             병렬 작업 수 (기본: 16)
  --verbose            상세 출력
  --help               이 도움말 표시

컨테이너 비교:

  ┌─────────────────┬──────────────────┬──────────────────┐
  │ 항목            │ Linux 컨테이너   │ Windows 컨테이너 │
  ├─────────────────┼──────────────────┼──────────────────┤
  │ WSL2 필요       │ ✅ 필요          │ ❌ 불필요        │
  │ 이미지 크기     │ 2GB              │ 2-2.5GB          │
  │ 성능            │ 94%              │ 100%             │
  │ 크로스 플랫폼   │ ✅ Linux/Mac/Win │ ❌ Windows만     │
  │ CI/CD           │ ✅ 완벽          │ ⚠️  제한적       │
  │ 권장            │ ⭐⭐⭐⭐⭐      │ ⭐⭐⭐⭐        │
  └─────────────────┴──────────────────┴──────────────────┘

EXAMPLES:
  # 자동 선택 (Docker 모드에 따라)
  ./build-unified.sh

  # Linux 컨테이너 강제 사용
  ./build-unified.sh --linux

  # Windows 컨테이너 강제 사용
  ./build-unified.sh --windows

  # 사용자 프로젝트 빌드
  ./build-unified.sh --project ~/my-project

MORE INFO:
  docs/WINDOWS_CONTAINER_COMPARISON.md

EOF
}

log() { echo "[INFO] $*"; }
success() { echo "[SUCCESS] $*"; }
warn() { echo "[WARN] $*" >&2; }
die() { echo "[ERROR] $*" >&2; exit 1; }

get_docker_mode() {
  if ! docker info >/dev/null 2>&1; then
    echo "error"
    return
  fi

  local info=$(docker info 2>&1)
  if echo "$info" | grep -q "OSType: windows"; then
    echo "windows"
  elif echo "$info" | grep -q "OSType: linux"; then
    echo "linux"
  else
    echo "unknown"
  fi
}

show_banner() {
  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  W55RP20 통합 빌드 시스템 v$VERSION                    ║"
  echo "║  Linux 컨테이너 + Windows 컨테이너 All-in-One              ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo ""
}

# ============================================================================
# 옵션 파싱
# ============================================================================

CONTAINER_TYPE=""
PROJECT=""
OUTPUT=""
BUILD_TYPE="Release"
JOBS="16"
CLEAN=0
UPDATE_REPO=0
VERBOSE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --linux)
      CONTAINER_TYPE="linux"
      shift
      ;;
    --windows)
      CONTAINER_TYPE="windows"
      shift
      ;;
    --auto)
      CONTAINER_TYPE="auto"
      shift
      ;;
    --project)
      PROJECT="$2"
      shift 2
      ;;
    --output)
      OUTPUT="$2"
      shift 2
      ;;
    --debug)
      BUILD_TYPE="Debug"
      shift
      ;;
    --clean)
      CLEAN=1
      shift
      ;;
    --update-repo)
      UPDATE_REPO=1
      shift
      ;;
    --jobs)
      JOBS="$2"
      shift 2
      ;;
    --verbose)
      VERBOSE=1
      shift
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

# ============================================================================
# 초기화
# ============================================================================

show_banner

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================================
# Docker 상태 확인
# ============================================================================

log "Docker Desktop 상태 확인 중..."

DOCKER_MODE=$(get_docker_mode)

if [[ "$DOCKER_MODE" == "error" ]]; then
  die "Docker Desktop이 실행되지 않았습니다"
fi

success "Docker Desktop 실행 중 (현재 모드: $DOCKER_MODE containers)"

# ============================================================================
# 컨테이너 타입 결정
# ============================================================================

if [[ -z "$CONTAINER_TYPE" || "$CONTAINER_TYPE" == "auto" ]]; then
  CONTAINER_TYPE="$DOCKER_MODE"
  log "자동 선택: $CONTAINER_TYPE 컨테이너 (Docker 현재 모드)"
else
  log "사용자 선택: $CONTAINER_TYPE 컨테이너"
fi

# ============================================================================
# 모드 불일치 확인
# ============================================================================

if [[ "$CONTAINER_TYPE" != "$DOCKER_MODE" ]]; then
  echo ""
  warn "Docker 모드 불일치!"
  echo ""
  echo "  요청: $CONTAINER_TYPE 컨테이너"
  echo "  현재: $DOCKER_MODE 컨테이너"
  echo ""

  if [[ "$CONTAINER_TYPE" == "linux" && "$DOCKER_MODE" == "windows" ]]; then
    echo "해결 방법 (Linux containers로 전환):"
    echo "  1. 시스템 트레이의 Docker 아이콘 우클릭"
    echo "  2. 'Switch to Linux containers...' 선택"
    echo "  3. 전환 완료 후 이 스크립트 재실행"
  elif [[ "$CONTAINER_TYPE" == "windows" && "$DOCKER_MODE" == "linux" ]]; then
    echo "해결 방법 (Windows containers로 전환):"
    echo "  1. 시스템 트레이의 Docker 아이콘 우클릭"
    echo "  2. 'Switch to Windows containers...' 선택"
    echo "  3. 전환 완료 후 이 스크립트 재실행"
  fi

  echo ""
  echo "또는: 현재 모드($DOCKER_MODE)로 빌드하려면"
  echo "  ./build-unified.sh --$DOCKER_MODE"
  echo ""

  read -r -p "그대로 종료하시겠습니까? [Y/n]: " response
  if [[ ! "$response" =~ ^[Nn]$ ]]; then
    exit 0
  fi
fi

# ============================================================================
# 적절한 빌드 스크립트 실행
# ============================================================================

echo ""
log "빌드 준비 중..."
echo ""

# 공통 파라미터 구성
COMMON_ARGS=()
[[ -n "$PROJECT" ]] && COMMON_ARGS+=(--project "$PROJECT")
[[ -n "$OUTPUT" ]] && COMMON_ARGS+=(--output "$OUTPUT")
[[ "$BUILD_TYPE" == "Debug" ]] && COMMON_ARGS+=(--debug)
[[ "$CLEAN" == "1" ]] && COMMON_ARGS+=(--clean)
[[ "$UPDATE_REPO" == "1" ]] && COMMON_ARGS+=(--update-repo)
[[ -n "$JOBS" ]] && COMMON_ARGS+=(--jobs "$JOBS")
[[ "$VERBOSE" == "1" ]] && COMMON_ARGS+=(--verbose)

if [[ "$CONTAINER_TYPE" == "linux" ]]; then
  success "Linux 컨테이너 빌드 시작 (WSL2 기반)"
  echo ""
  echo "특징:"
  echo "  ✅ 크로스 플랫폼 (Linux/macOS/Windows)"
  echo "  ✅ CI/CD 완벽 호환"
  echo "  ✅ 표준 Docker 경험"
  echo ""

  SCRIPT_PATH="$SCRIPT_DIR/build-windows.sh"

  if [[ ! -f "$SCRIPT_PATH" ]]; then
    die "build-windows.sh를 찾을 수 없습니다: $SCRIPT_PATH"
  fi

  exec "$SCRIPT_PATH" "${COMMON_ARGS[@]}"

elif [[ "$CONTAINER_TYPE" == "windows" ]]; then
  success "Windows 컨테이너 빌드 시작 (네이티브)"
  echo ""
  echo "특징:"
  echo "  ✅ WSL2 불필요"
  echo "  ✅ Windows 네이티브 성능"
  echo "  ✅ .exe 직접 실행"
  echo ""

  # Windows 컨테이너는 PowerShell 스크립트만 지원
  warn "Windows 컨테이너는 PowerShell 전용입니다"
  echo ""
  echo "다음 명령을 PowerShell에서 실행하세요:"
  echo "  .\\build.ps1 -Windows ${COMMON_ARGS[@]}"
  echo ""

  exit 1

else
  die "알 수 없는 컨테이너 타입: $CONTAINER_TYPE"
fi
