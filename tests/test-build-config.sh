#!/usr/bin/env bash
# 테스트: .build-config 저장/로드

set -euo pipefail

TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

# 테스트 헬퍼
pass() {
  ((TEST_COUNT++)) || true
  ((PASS_COUNT++)) || true
  echo "✓ $1"
}

fail() {
  ((TEST_COUNT++)) || true
  ((FAIL_COUNT++)) || true
  echo "✗ $1" >&2
}

# 테스트 환경 준비
TESTDIR="/tmp/test-build-config-$$"
mkdir -p "$TESTDIR"
cd "$TESTDIR"

# build.sh 복사
cp /home/sr/src/docker/w55rp20/build.sh .
cp /home/sr/src/docker/w55rp20/w55build.sh .

cleanup() {
  cd /
  rm -rf "$TESTDIR"
}
trap cleanup EXIT

echo "=== .build-config Test Suite ==="
echo "Test directory: $TESTDIR"
echo ""

# Test 1: --save-config creates .build-config file
rm -f .build-config
if ./build.sh --save-config >/dev/null 2>&1; then
  if [ -f ".build-config" ]; then
    pass "Test 1.1: --save-config creates .build-config file"
  else
    fail "Test 1.1: .build-config file not created"
  fi
else
  fail "Test 1.1: --save-config failed to execute"
fi

# Test 2: .build-config contains expected variables
if grep -q "SRC_DIR=" .build-config && \
   grep -q "OUT_DIR=" .build-config && \
   grep -q "JOBS=" .build-config && \
   grep -q "BUILD_TYPE=" .build-config; then
  pass "Test 2.1: .build-config contains required variables"
else
  fail "Test 2.1: .build-config missing required variables"
fi

# Test 3: --save-config with options
rm -f .build-config
./build.sh --project /tmp/myproject --output /tmp/myout --jobs 8 --debug --save-config >/dev/null 2>&1
if grep -q 'SRC_DIR="/tmp/myproject"' .build-config && \
   grep -q 'OUT_DIR="/tmp/myout"' .build-config && \
   grep -q 'JOBS=8' .build-config && \
   grep -q 'BUILD_TYPE="Debug"' .build-config; then
  pass "Test 3.1: --save-config preserves CLI options"
else
  fail "Test 3.1: --save-config did not preserve CLI options correctly"
fi

# Test 4: --show-config displays configuration
rm -f .build-config
if ./build.sh --show-config 2>&1 | grep -q "No .build-config file found"; then
  pass "Test 4.1: --show-config detects missing .build-config"
else
  fail "Test 4.1: --show-config did not detect missing .build-config"
fi

./build.sh --project /tmp/test --save-config >/dev/null 2>&1
if [ -f ".build-config" ]; then
  show_output=$(./build.sh --show-config 2>&1)
  if echo "$show_output" | grep -q "SRC_DIR="; then
    pass "Test 4.2: --show-config displays existing .build-config"
  else
    fail "Test 4.2: --show-config did not display .build-config (output: $show_output)"
  fi
else
  fail "Test 4.2: .build-config was not created"
fi

# Test 5: Config loading priority (CLI > .build-config)
# Create .build-config with specific values
cat > .build-config <<EOF
SRC_DIR="/tmp/config-src"
OUT_DIR="/tmp/config-out"
JOBS=4
BUILD_TYPE="Release"
EOF

# Create a mock w55build.sh that echoes variables
cat > w55build.sh <<'MOCKSCRIPT'
#!/usr/bin/env bash
echo "SRC_DIR=$SRC_DIR"
echo "OUT_DIR=$OUT_DIR"
echo "JOBS=$JOBS"
echo "BUILD_TYPE=$BUILD_TYPE"
exit 0
MOCKSCRIPT
chmod +x w55build.sh

# Test: .build-config values are loaded
output=$(./build.sh --no-confirm 2>&1 || true)
if echo "$output" | grep -q 'SRC_DIR=/tmp/config-src' && \
   echo "$output" | grep -q 'OUT_DIR=/tmp/config-out' && \
   echo "$output" | grep -q 'JOBS=4' && \
   echo "$output" | grep -q 'BUILD_TYPE=Release'; then
  pass "Test 5.1: .build-config values are loaded"
else
  fail "Test 5.1: .build-config values not loaded correctly"
fi

# Test: CLI options override .build-config
output=$(./build.sh --project /tmp/cli-src --output /tmp/cli-out --jobs 16 --debug --no-confirm 2>&1 || true)
if echo "$output" | grep -q 'SRC_DIR=/tmp/cli-src' && \
   echo "$output" | grep -q 'OUT_DIR=/tmp/cli-out' && \
   echo "$output" | grep -q 'JOBS=16' && \
   echo "$output" | grep -q 'BUILD_TYPE=Debug'; then
  pass "Test 5.2: CLI options override .build-config"
else
  fail "Test 5.2: CLI options did not override .build-config"
fi

# Test 6: build.config priority (lower than .build-config)
cat > build.config <<EOF
JOBS=32
TMPFS_SIZE="32g"
EOF

output=$(./build.sh --no-confirm 2>&1 || true)
# JOBS should be from .build-config (4), not build.config (32)
if echo "$output" | grep -q 'JOBS=4'; then
  pass "Test 6.1: .build-config overrides build.config"
else
  fail "Test 6.1: .build-config did not override build.config"
fi

# TMPFS_SIZE should be from build.config (not in .build-config)
if echo "$output" | grep -q 'TMPFS_SIZE=32g'; then
  pass "Test 6.2: build.config provides values not in .build-config"
else
  fail "Test 6.2: build.config values not loaded"
fi

# Test 7: Generated timestamp in .build-config
rm -f .build-config
./build.sh --save-config >/dev/null 2>&1
if grep -q "Generated:" .build-config; then
  pass "Test 7.1: .build-config includes generation timestamp"
else
  fail "Test 7.1: .build-config missing timestamp"
fi

echo ""
echo "=== Test Results ==="
echo "Total:  $TEST_COUNT"
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"
echo ""

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
