#!/usr/bin/env bash
# build-windows.sh - Git Bash용 W55RP20 빌드 스크립트 (Windows)
# Docker Desktop for Windows 전용

set -euo pipefail

VERSION="1.1.0-windows"

# ============================================================================
# Git Bash 환경 확인
# ============================================================================

if [ -z "${MSYSTEM:-}" ]; then
  echo "[ERROR] 이 스크립트는 Git Bash 전용입니다" >&2
  echo "[INFO] PowerShell 사용자: .\build-windows.ps1 실행" >&2
  exit 1
fi

# Path conversion 비활성화 (Docker 명령에서 자동 변환 방지)
export MSYS_NO_PATHCONV=1

echo "[INFO] Git Bash 환경 감지됨 (path conversion 비활성화)"

# ============================================================================
# 기본 설정
# ============================================================================

IMAGE="${IMAGE:-w55rp20:auto}"
TMPFS_SIZE="${TMPFS_SIZE:-20g}"
JOBS="${JOBS:-16}"
BUILD_TYPE="${BUILD_TYPE:-Release}"
CLEAN="${CLEAN:-0}"
UPDATE_REPO="${UPDATE_REPO:-0}"
VERBOSE="${VERBOSE:-0}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Windows 기본 경로
: "${SRC_DIR:=$HOME/W55RP20-S2E}"
: "${OUT_DIR:=$SCRIPT_DIR/out}"
: "${CCACHE_DIR:=$HOME/.ccache-w55rp20}"

# ============================================================================
# 함수
# ============================================================================

log() { echo "[INFO] $*"; }
success() { echo "[SUCCESS] $*"; }
warn() { echo "[WARN] $*" >&2; }
die() { echo "[ERROR] $*" >&2; exit 1; }

# Git Bash 경로를 Windows 경로로 변환
# Docker Desktop은 Windows 경로를 기대함
to_windows_path() {
  local path="$1"

  # 이미 절대 경로인지 확인
  if [[ "$path" =~ ^/[a-z]/ ]]; then
    # /c/Users/... → C:\Users\...
    local drive="${path:1:1}"
    local rest="${path:3}"
    echo "${drive^^}:/${rest//\//\\}"
  elif [[ "$path" =~ ^[A-Za-z]: ]]; then
    # 이미 Windows 경로
    echo "$path"
  else
    # 상대 경로 → 절대 경로 → Windows 경로
    local abs_path=$(cd "$path" 2>/dev/null && pwd || echo "$path")
    to_windows_path "$abs_path"
  fi
}

# 경로를 절대 경로로 변환 (Git Bash 형식 유지)
to_absolute_path() {
  local path="$1"

  if [[ -d "$path" ]]; then
    (cd "$path" && pwd)
  elif [[ -e "$path" ]]; then
    echo "$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"
  else
    # 디렉토리가 아직 없으면 상위 디렉토리 기준으로 변환
    local dir=$(dirname "$path")
    local name=$(basename "$path")
    if [[ -d "$dir" ]]; then
      echo "$(cd "$dir" && pwd)/$name"
    else
      # 상대 경로를 그대로 현재 디렉토리 기준으로
      echo "$PWD/$path"
    fi
  fi
}

show_help() {
  cat <<'EOF'
W55RP20 Build System for Windows (Git Bash) v1.1.0-windows

Usage: ./build-windows.sh [OPTIONS]

OPTIONS:
  --project PATH       프로젝트 디렉토리
  --output PATH        빌드 산출물 디렉토리 (기본: ./out)
  --debug              디버그 빌드
  --clean              산출물 정리 후 빌드
  --update-repo        Git 레포 업데이트
  --jobs N             병렬 작업 수 (기본: 16)
  --verbose            상세 출력
  --help               이 도움말 표시

ENVIRONMENT VARIABLES:
  SRC_DIR              프로젝트 디렉토리
  OUT_DIR              산출물 디렉토리
  BUILD_TYPE           빌드 타입 (Release|Debug)
  JOBS                 병렬 작업 수
  CLEAN                정리 여부 (0|1)
  UPDATE_REPO          레포 업데이트 (0|1)
  VERBOSE              상세 출력 (0|1)

EXAMPLES:
  # 기본 빌드
  ./build-windows.sh

  # 사용자 프로젝트 빌드
  ./build-windows.sh --project ~/my-w55rp20-project

  # 디버그 빌드
  ./build-windows.sh --debug --verbose

  # 환경 변수 사용
  SRC_DIR=~/my-project ./build-windows.sh

REQUIREMENTS:
  - Docker Desktop for Windows (WSL2 backend)
  - Git Bash (Git for Windows)

NOTES:
  - MSYS_NO_PATHCONV=1 자동 설정됨 (Docker 경로 처리)
  - Windows 경로 자동 변환 (C:\Users ↔ /c/Users)
  - PowerShell 사용자: .\build-windows.ps1 권장

EOF
}

# ============================================================================
# 옵션 파싱
# ============================================================================

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      SRC_DIR="$2"
      shift 2
      ;;
    --output)
      OUT_DIR="$2"
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
# 사전 검사
# ============================================================================

log "W55RP20 Build System for Windows (Git Bash) v$VERSION"
echo ""

# Docker Desktop 확인
if ! docker info >/dev/null 2>&1; then
  die "Docker Desktop이 실행되지 않았습니다. Docker Desktop을 설치하고 실행하세요."
fi

success "Docker Desktop 실행 중"

# ============================================================================
# 경로 처리
# ============================================================================

# 절대 경로로 변환
SRC_DIR=$(to_absolute_path "$SRC_DIR")
OUT_DIR=$(to_absolute_path "$OUT_DIR")
CCACHE_DIR=$(to_absolute_path "$CCACHE_DIR")

# 디렉토리 생성
mkdir -p "$OUT_DIR"
mkdir -p "$CCACHE_DIR"

# ============================================================================
# 설정 출력
# ============================================================================

echo ""
log "빌드 설정:"
log "  프로젝트: $SRC_DIR"
log "  산출물:   $OUT_DIR"
log "  빌드타입: $BUILD_TYPE"
log "  병렬작업: $JOBS"
log "  정리:     $CLEAN"
log "  레포업데이트: $UPDATE_REPO"
echo ""

read -r -p "계속하시겠습니까? [Y/n]: " confirm
if [[ "$confirm" =~ ^[Nn]$ ]]; then
  echo "취소되었습니다."
  exit 0
fi

# ============================================================================
# 레포 클론/업데이트
# ============================================================================

if [[ ! -d "$SRC_DIR/.git" ]]; then
  log "소스 코드 없음 → 클론 중..."
  echo ""

  REPO_URL="https://github.com/WIZnet-ioNIC/W55RP20-S2E.git"
  git clone --recurse-submodules "$REPO_URL" "$SRC_DIR"

  success "클론 완료"
fi

if [[ "$UPDATE_REPO" = "1" ]]; then
  log "레포 업데이트 중..."
  (
    cd "$SRC_DIR"
    git fetch --all --tags
    git submodule update --init --recursive
  )
fi

# ============================================================================
# 산출물 정리
# ============================================================================

if [[ "$CLEAN" = "1" ]]; then
  log "산출물 정리 중..."
  rm -f "$OUT_DIR"/*.uf2 "$OUT_DIR"/*.elf "$OUT_DIR"/*.bin "$OUT_DIR"/*.hex 2>/dev/null || true
fi

# ============================================================================
# Docker 이미지 확인
# ============================================================================

log "Docker 이미지 확인 중..."

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  log "Docker 이미지 빌드 중... (최초 1회, 약 20분 소요)"
  echo ""

  (
    cd "$SCRIPT_DIR"
    docker buildx build \
      --platform linux/amd64 \
      -t "$IMAGE" \
      --load \
      --progress=plain \
      -f Dockerfile .
  )

  success "이미지 빌드 완료"
else
  success "이미지 존재 (재사용)"
fi

# ============================================================================
# 빌드 실행
# ============================================================================

echo ""
log "빌드 시작..."
echo ""

# Docker run (경로는 Git Bash 형식 그대로 사용 - Docker Desktop이 자동 변환)
START_TIME=$(date +%s)

if [[ "$VERBOSE" = "1" ]]; then
  log "Docker 명령:"
  echo "docker run --rm -t \\"
  echo "  -v \"$SRC_DIR:/work/src\" \\"
  echo "  -v \"$OUT_DIR:/work/out\" \\"
  echo "  -v \"$CCACHE_DIR:/work/.ccache\" \\"
  echo "  --tmpfs /work/src/build:rw,exec,size=$TMPFS_SIZE \\"
  echo "  -e CCACHE_DIR=/work/.ccache \\"
  echo "  -e JOBS=$JOBS \\"
  echo "  -e BUILD_TYPE=$BUILD_TYPE \\"
  echo "  -e UPDATE_REPO=$UPDATE_REPO \\"
  echo "  $IMAGE /usr/local/bin/docker-build.sh"
  echo ""
fi

docker run --rm -t \
  -v "$SRC_DIR:/work/src" \
  -v "$OUT_DIR:/work/out" \
  -v "$CCACHE_DIR:/work/.ccache" \
  --tmpfs /work/src/build:rw,exec,size="$TMPFS_SIZE" \
  -e CCACHE_DIR=/work/.ccache \
  -e JOBS="$JOBS" \
  -e BUILD_TYPE="$BUILD_TYPE" \
  -e UPDATE_REPO="$UPDATE_REPO" \
  "$IMAGE" /usr/local/bin/docker-build.sh

EXIT_CODE=$?
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

# ============================================================================
# 결과 출력
# ============================================================================

echo ""

if [[ $EXIT_CODE -eq 0 ]]; then
  success "빌드 성공! (소요 시간: ${ELAPSED}초)"
  echo ""

  # 산출물 목록
  echo "생성된 파일:"
  find "$OUT_DIR" -name "*.uf2" 2>/dev/null | while read -r file; do
    size=$(du -h "$file" | cut -f1)
    name=$(basename "$file")
    echo "  → $name  ($size)"
  done

  echo ""
  log "산출물 위치: $OUT_DIR"
  echo ""

  # 다음 단계 안내
  echo "다음 단계:"
  echo "  1. W55RP20 보드를 BOOTSEL 버튼을 누른 채로 USB 연결"
  echo "  2. 'RPI-RP2' 드라이브로 인식됨"
  echo "  3. $OUT_DIR/*.uf2 파일을 드라이브에 복사"
  echo "  4. 자동으로 재부팅 및 펌웨어 업로드 완료"
  echo ""

  exit 0
else
  die "빌드 실패 (exit code: $EXIT_CODE)"
fi
