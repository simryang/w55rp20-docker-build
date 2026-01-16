#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# w55build.sh
# - 호스트에서 실행하는 "메인" 빌드 스크립트
# - Docker 이미지가 준비되어 있으면 재사용 (빠름)
# - REFRESH_*_BUST 가 들어오면, 필요한 레이어만 선택적으로 재빌드
# - 실제 CMake/Ninja 빌드는 컨테이너 내부 스크립트(/usr/local/bin/docker-build.sh)
#   로 넘긴다. (heredoc 지옥, $3 언바운드 같은 사고 예방)
###############################################################################

echo "[INFO] starting build at $(date)"

# ----------------------- User-configurable env vars -------------------------
IMAGE="${IMAGE:-w55rp20:auto}"
PLATFORM="${PLATFORM:-linux/amd64}"

REPO_URL="${REPO_URL:-https://github.com/WIZnet-ioNIC/W55RP20-S2E.git}"
REPO_REF="${REPO_REF:-main}"          # tag/commit 가능

SRC_DIR="${SRC_DIR:-$HOME/W55RP20-S2E}"
OUT_DIR="${OUT_DIR:-$HOME/W55RP20-S2E-out}"
CCACHE_DIR_HOST="${CCACHE_DIR_HOST:-$HOME/.ccache-w55rp20}"

# RAM disk size (tmpfs upper limit). It is NOT pre-allocated.
TMPFS_SIZE="${TMPFS_SIZE:-20g}"

# Build parallelism
JOBS="${JOBS:-16}"

# Release/Debug
BUILD_TYPE="${BUILD_TYPE:-Release}"

# If 1, build docker image automatically when needed
AUTO_BUILD_IMAGE="${AUTO_BUILD_IMAGE:-1}"  # build.sh와 일치 (초보자 친화)
DOCKERFILE_DIR="${DOCKERFILE_DIR:-$PWD}"   # directory containing Dockerfile

# Verbose mode (set VERBOSE=1 for detailed output)
VERBOSE="${VERBOSE:-0}"

# If 1, do "git fetch + checkout + submodule update" before build
UPDATE_REPO="${UPDATE_REPO:-0}"

# If 1, clean OUT_DIR artifacts
CLEAN="${CLEAN:-0}"

# ---------------------------- Helpers ---------------------------------------
log(){ echo "[INFO] $*"; }
warn(){ echo "[WARN] $*" >&2; }
die(){ echo "[ERROR] $*" >&2; exit 1; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "필요한 커맨드가 없습니다: $1"; }

# ---------------------------- Preflight -------------------------------------
need_cmd docker
need_cmd git

if ! sudo docker info >/dev/null 2>&1; then
  die "Docker 데몬 접근 실패. sudo docker info 부터 확인하세요. (권한/서비스)"
fi

# ---------------------------- Ensure image ----------------------------------
# 기본은 "이미지 있으면 재사용".
# 다만 REFRESH_*_BUST 가 하나라도 들어오면 이미지 재빌드가 필요할 수 있음.

NEED_IMAGE_BUILD=0
if ! sudo docker image inspect "$IMAGE" >/dev/null 2>&1; then
  NEED_IMAGE_BUILD=1
  log "이미지($IMAGE) 없음"
fi

if [ -n "${REFRESH_APT_BUST:-}${REFRESH_SDK_BUST:-}${REFRESH_CMAKE_BUST:-}${REFRESH_GCC_BUST:-}" ]; then
  NEED_IMAGE_BUILD=1
  log "REFRESH 지정됨 -> 이미지($IMAGE) 선택적 재빌드"
fi

if [ "$NEED_IMAGE_BUILD" = "0" ]; then
  log "이미지 존재: $IMAGE"
else
  if [ "$AUTO_BUILD_IMAGE" != "1" ]; then
    die "이미지 재빌드가 필요하지만 AUTO_BUILD_IMAGE=1 이 아닙니다. (REFRESH 지정 시 AUTO_BUILD_IMAGE=1 권장)"
  fi

  [ -f "$DOCKERFILE_DIR/Dockerfile" ] || die "Dockerfile이 없습니다: $DOCKERFILE_DIR/Dockerfile"
  [ -f "$DOCKERFILE_DIR/docker-build.sh" ] || die "docker-build.sh(컨테이너 내부 빌드 스크립트)가 없습니다: $DOCKERFILE_DIR/docker-build.sh"

  log "이미지 빌드 실행 (PLATFORM=$PLATFORM)"
  (
    cd "$DOCKERFILE_DIR"

    BUILD_CMD=(sudo docker buildx build \
      --platform "$PLATFORM" \
      -t "$IMAGE" \
      --load \
      --progress=plain)

    # build.sh 래퍼가 넣어주는 선택적 refresh 토큰 (없으면 캐시 재사용)
    if [ -n "${REFRESH_APT_BUST:-}" ]; then BUILD_CMD+=(--build-arg "REFRESH_APT=$REFRESH_APT_BUST"); fi
    if [ -n "${REFRESH_SDK_BUST:-}" ]; then BUILD_CMD+=(--build-arg "REFRESH_SDK=$REFRESH_SDK_BUST"); fi
    if [ -n "${REFRESH_CMAKE_BUST:-}" ]; then BUILD_CMD+=(--build-arg "REFRESH_CMAKE=$REFRESH_CMAKE_BUST"); fi
    if [ -n "${REFRESH_GCC_BUST:-}" ]; then BUILD_CMD+=(--build-arg "REFRESH_GCC=$REFRESH_GCC_BUST"); fi

    BUILD_CMD+=(-f Dockerfile .)

    if [ "$VERBOSE" = "1" ]; then
      log "===== Docker build command ====="
      printf '[INFO] %s\n' "${BUILD_CMD[*]}"
      log "================================="
    fi

    "${BUILD_CMD[@]}"
  )
fi

# ---------------------------- Ensure repo -----------------------------------
if [ ! -d "$SRC_DIR/.git" ]; then
  log "소스 없음 -> 클론: $SRC_DIR"
  git clone --recurse-submodules "$REPO_URL" "$SRC_DIR"
fi

if [ "$UPDATE_REPO" = "1" ]; then
  log "레포 업데이트(fetch/checkout/submodule)..."
  ( cd "$SRC_DIR" && \
    git fetch --all --tags && \
    git checkout "$REPO_REF" && \
    git submodule update --init --recursive )
fi

mkdir -p "$OUT_DIR" "$CCACHE_DIR_HOST"

if [ "$CLEAN" = "1" ]; then
  log "CLEAN=1 -> OUT_DIR 정리(기존 산출물 삭제)"
  rm -f "$OUT_DIR"/*.uf2 "$OUT_DIR"/*.elf "$OUT_DIR"/*.bin "$OUT_DIR"/*.hex 2>/dev/null || true
fi

log "===== SETTINGS ====="
log "IMAGE=$IMAGE"
log "PLATFORM=$PLATFORM"
log "SRC_DIR=$SRC_DIR"
log "OUT_DIR=$OUT_DIR"
log "CCACHE_DIR_HOST=$CCACHE_DIR_HOST"
log "TMPFS_SIZE=$TMPFS_SIZE"
log "JOBS=$JOBS"
log "BUILD_TYPE=$BUILD_TYPE"
log "AUTO_BUILD_IMAGE=$AUTO_BUILD_IMAGE"
log "UPDATE_REPO=$UPDATE_REPO"
log "CLEAN=$CLEAN"

if [ "$VERBOSE" = "1" ]; then
  log "===== VERBOSE INFO ====="
  log "REFRESH_APT_BUST=${REFRESH_APT_BUST:-<not set>}"
  log "REFRESH_SDK_BUST=${REFRESH_SDK_BUST:-<not set>}"
  log "REFRESH_CMAKE_BUST=${REFRESH_CMAKE_BUST:-<not set>}"
  log "REFRESH_GCC_BUST=${REFRESH_GCC_BUST:-<not set>}"
  log "REPO_URL=$REPO_URL"
  log "REPO_REF=$REPO_REF"
  log "DOCKERFILE_DIR=$DOCKERFILE_DIR"
  log "========================"
fi

log "===================="

TIME_PREFIX=()
if [ -x /usr/bin/time ]; then
  TIME_PREFIX=(/usr/bin/time -v)
fi

# ---------------------------- Build (docker run) ----------------------------
# 주의:
# - tmpfs는 rw,exec 필요 (pioasm 같은 바이너리 실행 때문에)
# - 컨테이너 내부 스크립트가 /work/src/build 를 사용함

if [ "$VERBOSE" = "1" ]; then
  log "===== Docker run command ====="
  log "sudo docker run --rm -t \\"
  log "  -v \"$SRC_DIR\":/work/src \\"
  log "  -v \"$OUT_DIR\":/work/out \\"
  log "  -v \"$CCACHE_DIR_HOST\":/work/.ccache \\"
  log "  --tmpfs /work/src/build:rw,exec,size=\"$TMPFS_SIZE\" \\"
  log "  -e CCACHE_DIR=/work/.ccache \\"
  log "  -e JOBS=\"$JOBS\" \\"
  log "  -e BUILD_TYPE=\"$BUILD_TYPE\" \\"
  log "  \"$IMAGE\" /usr/local/bin/docker-build.sh"
  log "=============================="
fi

"${TIME_PREFIX[@]}" sudo docker run --rm -t \
  -v "$SRC_DIR":/work/src \
  -v "$OUT_DIR":/work/out \
  -v "$CCACHE_DIR_HOST":/work/.ccache \
  --tmpfs /work/src/build:rw,exec,size="$TMPFS_SIZE" \
  -e CCACHE_DIR=/work/.ccache \
  -e JOBS="$JOBS" \
  -e BUILD_TYPE="$BUILD_TYPE" \
  "$IMAGE" /usr/local/bin/docker-build.sh

log "빌드 완료. 산출물: $OUT_DIR"
