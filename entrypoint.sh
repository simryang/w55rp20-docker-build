#!/usr/bin/env bash
set -euo pipefail

# 이 이미지는 두 가지 방식으로 사용합니다.
# 1) 기본(원샷): entrypoint가 소스 확보 -> configure/build -> 산출물 복사까지 수행
# 2) 런너: docker run 이미지 <커맨드...> 형태로 인자를 주면 그 커맨드를 그대로 실행
#    (호스트에서 소스를 마운트해서 빌드할 때 w55build.sh가 이 모드로 사용)
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

# ---- Configurable knobs ----
REPO_URL="${REPO_URL:-https://github.com/WIZnet-ioNIC/W55RP20-S2E.git}"
REPO_REF="${REPO_REF:-main}"          # tag/commit도 가능
SRC_DIR="${SRC_DIR:-/work/src}"       # 여기에 소스가 있어야 빌드
OUT_DIR="${OUT_DIR:-/work/out}"       # 산출물 복사 위치
PICO_SDK_TAG="${PICO_SDK_TAG:-2.2.0}" # 레포 내부 submodule pico-sdk를 강제할 태그

# ---- Helpers ----
is_mountpoint() {
  # /proc/self/mountinfo로 mountpoint 여부 판정
  local p="$1"
  local esc
  esc="$(python3 - <<'PY'\nimport sys\np=sys.argv[1]\nprint(p.replace('\\\\','\\\\\\\\').replace(' ','\\\\040'))\nPY\n"$p")"
  grep -q " ${esc} " /proc/self/mountinfo
}

log() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*" >&2; }
err() { echo "[ERROR] $*" >&2; }

mkdir -p "$SRC_DIR" "$OUT_DIR"

log "REPO_URL=$REPO_URL"
log "REPO_REF=$REPO_REF"
log "SRC_DIR=$SRC_DIR"
log "OUT_DIR=$OUT_DIR"
log "PICO_SDK_PATH=${PICO_SDK_PATH:-}"
log "PICO_TOOLCHAIN_PATH=${PICO_TOOLCHAIN_PATH:-}"
log "PICO_SDK_TAG(for submodule)=$PICO_SDK_TAG"

# ---- Acquire source ----
if [ -f "$SRC_DIR/CMakeLists.txt" ]; then
  log "Source detected (CMakeLists.txt exists). Will build using mounted/existing source."
else
  # SRC_DIR에 소스가 없으면 clone한다.
  # 중요한 규칙: mountpoint라도 rm -rf 절대 안 함.
  if [ -d "$SRC_DIR/.git" ]; then
    log "Git repo exists but CMakeLists.txt missing. Will not delete. Printing top files:"
    (cd "$SRC_DIR" && ls -la | head -n 100) || true
    err "SRC_DIR looks inconsistent. If you mounted the wrong folder, mount the W55RP20-S2E repo root to /work/src."
    exit 2
  fi

  log "No source present. Cloning into SRC_DIR..."
  # SRC_DIR이 비어있으면 mountpoint여도 clone은 가능
  git clone --recurse-submodules "$REPO_URL" "$SRC_DIR"
fi

cd "$SRC_DIR"

# ---- Git safe.directory (Docker mount ownership 이슈 회피) ----
# Git 2.35.2+ 보안 패치로 ownership 체크 강화됨
# 컨테이너 내부(root)에서 호스트 마운트(user) 디렉토리 접근 시 필요
git config --global --add safe.directory "$SRC_DIR"

# ---- Checkout desired ref ----
# UPDATE_REPO=1 일 때만 fetch/checkout 수행 (기본값 0)
UPDATE_REPO="${UPDATE_REPO:-0}"
if [ "$UPDATE_REPO" = "1" ]; then
  log "UPDATE_REPO=1: Fetching + checkout $REPO_REF ..."
  git fetch --all --tags || true
  git checkout "$REPO_REF" || true
  git submodule update --init --recursive
else
  log "UPDATE_REPO=0: Skipping git fetch/checkout (using existing source)"
fi

# ---- Enforce repo's internal pico-sdk to 2.2.0 if present ----
if [ -d "libraries/pico-sdk/.git" ]; then
  log "Pinning submodule libraries/pico-sdk to ${PICO_SDK_TAG} ..."
  pushd libraries/pico-sdk >/dev/null
  git fetch --tags || true
  if git rev-parse -q --verify "refs/tags/${PICO_SDK_TAG}" >/dev/null; then
    git checkout "${PICO_SDK_TAG}"
  else
    warn "Tag ${PICO_SDK_TAG} not found in submodule; leaving current revision."
  fi
  git submodule update --init --recursive
  popd >/dev/null
else
  warn "Expected libraries/pico-sdk submodule not found. Proceeding anyway."
fi

# ---- Apply patches if repo has patches/ directory ----
if [ -d "patches" ]; then
  # 패치가 pico-sdk에 적용되어야 하는 경우가 많아서 submodule 위치에 적용 우선 시도
  if [ -d "libraries/pico-sdk/.git" ]; then
    pushd libraries/pico-sdk >/dev/null
    for p in ../../patches/*.patch; do
      [ -f "$p" ] || continue
      log "Trying patch: $p"
      if git apply --check "$p" >/dev/null 2>&1; then
        git apply "$p"
        log "Applied: $p"
      else
        log "Skip (already applied or not applicable): $p"
      fi
    done
    popd >/dev/null
  else
    warn "patches/ exists but libraries/pico-sdk not found. Skipping patch apply."
  fi
else
  log "No patches/ directory. Skipping patch apply."
fi

# ---- Build ----
log "Configuring (Ninja) ..."
rm -rf build
cmake -S . -B build -G Ninja \
  -DPICO_SDK_PATH="/opt/pico-sdk" \
  -DPICO_TOOLCHAIN_PATH="/opt/toolchain"

log "Building ..."
cmake --build build

# ---- Collect artifacts ----
log "Collecting artifacts (*.uf2, *.elf, *.bin) under build/ ..."
mapfile -t ARTIFACTS < <(find build -type f \( -name "*.uf2" -o -name "*.elf" -o -name "*.bin" \) -print || true)

if [ "${#ARTIFACTS[@]}" -eq 0 ]; then
  err "No artifacts found under build/. Dumping tree (top 200 files):"
  find build -type f | head -n 200 || true
  exit 3
fi

for f in "${ARTIFACTS[@]}"; do
  cp -f "$f" "$OUT_DIR/"
done

echo "=== OUTPUTS ==="
ls -al "$OUT_DIR"

