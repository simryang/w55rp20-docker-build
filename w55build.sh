#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# W55RP20-S2E RAM(tmpfs) Build Runner
# - Host: Ubuntu 20.04 (works on most Linux)
# - Requires: docker, git
# - Optional: /usr/bin/time (usually installed as "time" package)
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

# RAM disk size (tmpfs upper limit). It's NOT pre-allocated; it grows as used.
TMPFS_SIZE="${TMPFS_SIZE:-20g}"

# Build parallelism (Ninja -j)
JOBS="${JOBS:-12}"

# Build type (Release/Debug)
BUILD_TYPE="${BUILD_TYPE:-Release}"

# If 1, build docker image automatically when missing (Dockerfile needed)
AUTO_BUILD_IMAGE="${AUTO_BUILD_IMAGE:-0}"
DOCKERFILE_DIR="${DOCKERFILE_DIR:-$PWD}"   # directory containing Dockerfile

# If 1, do "git fetch + checkout + submodule update" before build
UPDATE_REPO="${UPDATE_REPO:-0}"

# If 1, delete host-side build cache directory (we use tmpfs so normally not needed)
CLEAN="${CLEAN:-0}"

# If 1, keep build artifacts inside OUT_DIR only; otherwise also copy build logs
COPY_LOGS="${COPY_LOGS:-1}"

# ---------------------------- Helpers ---------------------------------------
log(){ echo "[INFO] $*"; }
warn(){ echo "[WARN] $*" >&2; }
die(){ echo "[ERROR] $*" >&2; exit 1; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "필요한 커맨드가 없습니다: $1"; }

human_gib() {
  python3 - <<PY
import sys
b=int(sys.argv[1])
print(f"{b/1024**3:.2f}GiB")
PY
}

# ---------------------------- Preflight -------------------------------------
need_cmd docker
need_cmd git

if [ ! -x /usr/bin/time ]; then
  warn "/usr/bin/time 이 없습니다. RSS 피크 측정이 약해집니다."
  warn "설치: sudo apt-get update && sudo apt-get install -y time"
fi

# docker daemon reachable?
if ! sudo docker info >/dev/null 2>&1; then
  die "Docker 데몬 접근 실패. (권한/서비스 상태 확인 필요) sudo docker info 부터 확인하세요."
fi

# ---------------------------- Ensure image ----------------------------------
if ! sudo docker image inspect "$IMAGE" >/dev/null 2>&1; then
  if [ "$AUTO_BUILD_IMAGE" = "1" ]; then
    log "이미지($IMAGE) 없음 -> 자동 빌드 시도"
    [ -f "$DOCKERFILE_DIR/Dockerfile" ] || die "Dockerfile이 없습니다: $DOCKERFILE_DIR/Dockerfile"
    ( cd "$DOCKERFILE_DIR" && \
      sudo docker buildx build --platform "$PLATFORM" -t "$IMAGE" --load --progress=plain -f Dockerfile . )
  else
    die "이미지($IMAGE)가 없습니다. 먼저 빌드하거나 AUTO_BUILD_IMAGE=1로 실행하세요."
  fi
else
  log "이미지 존재: $IMAGE"
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
else
  # ensure desired ref if first clone but different default branch?
  ( cd "$SRC_DIR" && git rev-parse --verify "$REPO_REF" >/dev/null 2>&1 ) || true
fi

# ---------------------------- Ensure dirs -----------------------------------
mkdir -p "$OUT_DIR" "$CCACHE_DIR_HOST"

# optional cleanup (mostly for OUT_DIR)
if [ "$CLEAN" = "1" ]; then
  log "CLEAN=1 -> OUT_DIR 정리(기존 산출물 삭제)"
  rm -f "$OUT_DIR"/*.uf2 "$OUT_DIR"/*.elf "$OUT_DIR"/*.bin 2>/dev/null || true
  rm -f "$OUT_DIR"/build-*.log 2>/dev/null || true
fi

# ---------------------------- Build runner ----------------------------------
log "===== SETTINGS ====="
log "IMAGE=$IMAGE"
log "PLATFORM=$PLATFORM"
log "SRC_DIR=$SRC_DIR"
log "OUT_DIR=$OUT_DIR"
log "CCACHE_DIR_HOST=$CCACHE_DIR_HOST"
log "TMPFS_SIZE=$TMPFS_SIZE"
log "JOBS=$JOBS"
log "BUILD_TYPE=$BUILD_TYPE"
log "===================="

TIME_PREFIX=()
if [ -x /usr/bin/time ]; then
  TIME_PREFIX=(/usr/bin/time -v)
fi

# Run container:
# - Source mounted read-write (so submodule updates possible; change to :ro if you want)
# - OUT and CCACHE persist on host
# - /work/build is tmpfs (RAM disk)
# - We measure tmpfs used peak by polling df
"${TIME_PREFIX[@]}" sudo docker run --rm -t \
  -v "$SRC_DIR":/work/src \
  -v "$OUT_DIR":/work/out \
  -v "$CCACHE_DIR_HOST":/work/.ccache \
  --tmpfs /work/src/build:rw,exec,size="$TMPFS_SIZE" \
  -e CCACHE_DIR=/work/.ccache \
  --entrypoint bash \
  "$IMAGE" -lc '
    set -euo pipefail

    echo "[INFO] PATH=$PATH"
    echo -n "[INFO] which python: "; command -v python || true
    echo -n "[INFO] which python3: "; command -v python3 || true

need() { command -v "$1" >/dev/null 2>&1 || { echo "[ERROR] missing tool: $1"; exit 2; }; }
need cmake
need ninja
need python
need python3
need arm-none-eabi-gcc
need arm-none-eabi-objcopy
need picotool
need astyle
need srec_cat


    # Always dump tmpfs usage on exit (success/fail) so you can see if it was full
    trap '"'"'echo "=== TMPFS DF ==="; df -h /work/src/build || true; echo "=== TMPFS DU ==="; du -sh /work/src/build || true'"'"' EXIT
# tmpfs usage monitor (peak) - write peak to a file (subshell-safe)
PEAK_FILE=/tmp/tmpfs_peak_bytes
echo 0 > "$PEAK_FILE"
monitor() {
  local peak=0
  while true; do
    local used
    used=$(df -B1 /work/src/build | awk 'NR==2{print $3}')
    if [ "$used" -gt "$peak" ]; then
      peak="$used"
      echo "$peak" > "$PEAK_FILE"
    fi
    sleep 0.5
  done
}
monitor &
MPID=$!

    # Decide whether ccache is available in the image
    C_LAUNCHER=""
    CXX_LAUNCHER=""
    if command -v ccache >/dev/null 2>&1; then
      echo "[INFO] ccache found -> enabled"
      C_LAUNCHER="-DCMAKE_C_COMPILER_LAUNCHER=ccache"
      CXX_LAUNCHER="-DCMAKE_CXX_COMPILER_LAUNCHER=ccache"
      ccache -z >/dev/null 2>&1 || true
    else
      echo "[WARN] ccache not found in image. continuing without ccache"
    fi

    # Configure
    cmake -S /work/src -B /work/src/build -G Ninja \
      -DCMAKE_BUILD_TYPE='"$BUILD_TYPE"' \
      -DPICO_SDK_PATH=/opt/pico-sdk \
      -DPICO_TOOLCHAIN_PATH=/opt/toolchain \
      ${C_LAUNCHER} ${CXX_LAUNCHER}

    # Build (limit jobs to avoid crazy RSS peaks)
    cmake --build /work/src/build -- -j '"$JOBS"'

    # Stop monitor
    kill $MPID >/dev/null 2>&1 || true
    PEAK=$(cat "$PEAK_FILE" 2>/dev/null || echo 0)

    echo "TMPFS_PEAK_BYTES=$PEAK"
    python3 - <<PY
p=int("$PEAK")
print(f"TMPFS_PEAK_GiB={p/1024**3:.2f}")
PY

    # Collect artifacts
    find /work/src/build -type f \( -name "*.uf2" -o -name "*.elf" -o -name "*.bin" \) -exec cp -f {} /work/out/ \;

    echo "=== OUTPUTS ==="
    ls -al /work/out

    if command -v ccache >/dev/null 2>&1; then
      echo "=== CCACHE STATS ==="
      ccache -s || true
    fi
  '

log "완료. 결과물 디렉토리: $OUT_DIR"
echo "[INFO] finished build at $(date)"

