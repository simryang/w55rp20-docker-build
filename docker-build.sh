#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# docker-build.sh (컨테이너 내부에서 실행)
# - /work/src : 호스트에서 마운트된 소스 루트
# - /work/out : 산출물(uf2/elf/bin 등) 복사 대상
# - /work/src/build : tmpfs 마운트 권장 (rw,exec)
# -----------------------------------------------------------------------------

: "${JOBS:=16}"
: "${BUILD_TYPE:=Release}"

log(){ echo "[INTERNAL] $*"; }
die(){ echo "[INTERNAL][ERROR] $*" >&2; exit 2; }

need(){ command -v "$1" >/dev/null 2>&1 || die "missing tool: $1"; }

log "PATH=$PATH"
log "python=$(command -v python || echo NO)"
log "python3=$(command -v python3 || echo NO)"

# 필수 툴 (프로젝트 CMake/파이썬 스크립트가 실제로 호출함)
need cmake
need ninja
need python
need python3
need arm-none-eabi-gcc
need srec_cat

# 선택 툴 (없어도 빌드는 되지만, restyle 타겟이 실패할 수 있음)
if ! command -v astyle >/dev/null 2>&1; then
  log "[WARN] astyle not found -> 'restyle' 타겟은 실패할 수 있음"
fi

# tmpfs 사용량 출력(성공/실패 상관없이)
trap 'echo "=== TMPFS DF ==="; df -h /work/src/build || true; echo "=== TMPFS DU ==="; du -sh /work/src/build || true' EXIT

# tmpfs peak 기록: 백그라운드 서브쉘이라 변수 공유 안되므로 파일로 기록
PEAK_FILE=/tmp/tmpfs_peak_$$
echo 0 > "$PEAK_FILE"

monitor_tmpfs() {
  while true; do
    # df 실패해도 죽지 않게 0 처리
    USED=$(df -B1 /work/src/build 2>/dev/null | awk 'NR==2{print $3}')
    USED=${USED:-0}
    CUR=$(cat "$PEAK_FILE" 2>/dev/null || echo 0)
    if [ "$USED" -gt "$CUR" ]; then
      echo "$USED" > "$PEAK_FILE"
    fi
    sleep 0.5
  done
}
monitor_tmpfs &
MPID=$!

# ccache (이미지에 있으면 자동 사용)
C_LAUNCHER=""
CXX_LAUNCHER=""
if command -v ccache >/dev/null 2>&1; then
  log "ccache found -> enabled"
  C_LAUNCHER="-DCMAKE_C_COMPILER_LAUNCHER=ccache"
  CXX_LAUNCHER="-DCMAKE_CXX_COMPILER_LAUNCHER=ccache"
  ccache -z >/dev/null 2>&1 || true
else
  log "[WARN] ccache not found (ok)"
fi

# configure
cmake -S /work/src -B /work/src/build -G Ninja \
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
  -DPICO_SDK_PATH=/opt/pico-sdk \
  -DPICO_TOOLCHAIN_PATH=/opt/toolchain \
  ${C_LAUNCHER} ${CXX_LAUNCHER}

# build
cmake --build /work/src/build -- -j "$JOBS"

# stop monitor
kill "$MPID" >/dev/null 2>&1 || true
PEAK=$(cat "$PEAK_FILE" 2>/dev/null || echo 0)
rm -f "$PEAK_FILE" || true

log "TMPFS_PEAK_BYTES=$PEAK"
python3 - <<PY
p=int("$PEAK")
print(f"TMPFS_PEAK_GiB={p/1024**3:.2f}")
PY

# collect artifacts
mkdir -p /work/out
find /work/src/build -type f \( -name "*.uf2" -o -name "*.elf" -o -name "*.bin" -o -name "*.hex" \) \
  -exec cp -f {} /work/out/ \;

log "=== OUTPUTS ==="
ls -al /work/out || true

if command -v ccache >/dev/null 2>&1; then
  log "=== CCACHE STATS ==="
  ccache -s || true
fi
