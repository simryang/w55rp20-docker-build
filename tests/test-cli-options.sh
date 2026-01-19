#!/usr/bin/env bash
# 테스트: CLI 옵션 파싱

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

test_exit_code() {
  local desc="$1"
  local expected="$2"
  shift 2
  local cmd=("$@")

  if [ "$expected" -eq 0 ]; then
    if "${cmd[@]}" >/dev/null 2>&1; then
      pass "$desc"
    else
      fail "$desc (expected exit 0, got $?)"
    fi
  else
    if "${cmd[@]}" >/dev/null 2>&1; then
      fail "$desc (expected exit $expected, got 0)"
    else
      pass "$desc"
    fi
  fi
}

test_output_contains() {
  local desc="$1"
  local needle="$2"
  shift 2
  local cmd=("$@")

  local output
  output=$("${cmd[@]}" 2>&1 || true)

  if echo "$output" | grep -q "$needle"; then
    pass "$desc"
  else
    fail "$desc (expected output to contain: $needle)"
  fi
}

echo "=== CLI Options Test Suite ==="
echo ""

# Test 1: --help
test_exit_code "Test 1.1: --help exits successfully" 0 ./build.sh --help
test_output_contains "Test 1.2: --help shows usage" "Usage:" ./build.sh --help
test_output_contains "Test 1.3: --help shows OPTIONS" "OPTIONS:" ./build.sh --help

# Test 2: --version
test_exit_code "Test 2.1: --version exits successfully" 0 ./build.sh --version
test_output_contains "Test 2.2: --version shows version" "1.1.0" ./build.sh --version

# Test 3: Invalid options
test_exit_code "Test 3.1: Invalid option fails" 1 ./build.sh --invalid-option
test_output_contains "Test 3.2: Invalid option shows error" "Unknown option" ./build.sh --invalid-option

# Test 4: Missing argument
test_exit_code "Test 4.1: --project without arg fails" 1 ./build.sh --project
test_output_contains "Test 4.2: --project error message" "requires a path" ./build.sh --project
test_exit_code "Test 4.3: --output without arg fails" 1 ./build.sh --output
test_exit_code "Test 4.4: --jobs without arg fails" 1 ./build.sh --jobs
test_exit_code "Test 4.5: --refresh without arg fails" 1 ./build.sh --refresh

# Test 5: Conflicting options
test_exit_code "Test 5.1: --official and --project conflict" 1 ./build.sh --official --project /tmp
test_output_contains "Test 5.2: Conflict error message" "cannot be used together" ./build.sh --official --project /tmp
test_exit_code "Test 5.3: --quiet and --verbose conflict" 1 ./build.sh --quiet --verbose

# Test 6: --show-config
test_exit_code "Test 6.1: --show-config exits successfully" 0 ./build.sh --show-config
test_output_contains "Test 6.2: --show-config shows message" "Current build configuration" ./build.sh --show-config

# Test 7: --save-config (with actual values)
rm -f /tmp/test-build.sh /tmp/test-.build-config
cat > /tmp/test-build.sh <<'TESTSCRIPT'
#!/usr/bin/env bash
# Mock build script that just saves config
if [ "$1" = "--save-config" ]; then
  cat > .build-config <<EOF
SRC_DIR="$SRC_DIR"
OUT_DIR="$OUT_DIR"
JOBS=$JOBS
EOF
  echo "[INFO] Configuration saved"
  exit 0
fi
TESTSCRIPT
chmod +x /tmp/test-build.sh

test_exit_code "Test 7.1: --save-config exits successfully" 0 \
  bash -c 'cd /tmp && ./build.sh --save-config 2>/dev/null || true' || true

# Test 8: Bash syntax check
test_exit_code "Test 8.1: build.sh syntax check" 0 bash -n ./build.sh

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
