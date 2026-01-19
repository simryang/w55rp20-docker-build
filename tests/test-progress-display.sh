#!/usr/bin/env bash
# 테스트: Progress display

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
TESTDIR="/tmp/test-progress-$$"
mkdir -p "$TESTDIR"
cd "$TESTDIR"

# build.sh 복사
cp /home/sr/src/docker/w55rp20/build.sh .

# Mock w55build.sh (빌드 성공 시뮬레이션)
cat > w55build.sh <<'MOCKSCRIPT'
#!/usr/bin/env bash
# Mock build that creates output files
mkdir -p "$OUT_DIR"
echo "Mock firmware" > "$OUT_DIR/App.uf2"
echo "Mock boot" > "$OUT_DIR/Boot.uf2"
echo "[MOCK] Build completed successfully"
exit 0
MOCKSCRIPT
chmod +x w55build.sh

cleanup() {
  cd /
  rm -rf "$TESTDIR"
}
trap cleanup EXIT

echo "=== Progress Display Test Suite ==="
echo "Test directory: $TESTDIR"
echo ""

# Test 1: Confirmation prompt (without --no-confirm)
echo "Test 1: 확인 프롬프트 표시"
rm -f .build-config

output=$(echo "Y" | ./build.sh --official --no-confirm 2>&1 || true)

# --no-confirm을 사용했으므로 확인 프롬프트가 없어야 함
if echo "$output" | grep -q "계속하시겠습니까?"; then
  fail "Test 1.1: --no-confirm인데 확인 프롬프트가 표시됨"
else
  pass "Test 1.1: --no-confirm 시 확인 프롬프트 생략"
fi

# Test 2: 저장된 설정 사용 메시지
echo ""
echo "Test 2: 저장된 설정 사용 메시지"
rm -f .build-config

# .build-config 생성
cat > .build-config <<EOF
SRC_DIR="./src"
OUT_DIR="./out"
JOBS=16
BUILD_TYPE="Release"
EOF

mkdir -p src

output=$(echo "Y" | ./build.sh 2>&1 || true)

if echo "$output" | grep -q "저장된 설정을 사용합니다"; then
  pass "Test 2.1: 저장된 설정 사용 메시지 표시"
else
  fail "Test 2.1: 저장된 설정 사용 메시지 없음"
fi

if echo "$output" | grep -q "다른 설정을 사용하려면: ./build.sh --setup"; then
  pass "Test 2.2: --setup 안내 메시지 표시"
else
  fail "Test 2.2: --setup 안내 메시지 없음"
fi

# Test 3: CLI 옵션 사용 시 저장된 설정 메시지 생략
echo ""
echo "Test 3: CLI 옵션 사용 시 저장된 설정 메시지 생략"

output=$(./build.sh --project ./src --no-confirm 2>&1 || true)

if echo "$output" | grep -q "저장된 설정을 사용합니다"; then
  fail "Test 3.1: CLI 옵션 사용했는데 저장된 설정 메시지 표시됨"
else
  pass "Test 3.1: CLI 옵션 사용 시 저장된 설정 메시지 생략"
fi

# Test 4: 빌드 성공 메시지
echo ""
echo "Test 4: 빌드 성공 메시지"

output=$(./build.sh --official --no-confirm 2>&1 || true)

if echo "$output" | grep -q "빌드 성공"; then
  pass "Test 4.1: 빌드 성공 메시지 표시"
else
  fail "Test 4.1: 빌드 성공 메시지 없음"
fi

if echo "$output" | grep -q "산출물 위치:"; then
  pass "Test 4.2: 산출물 위치 표시"
else
  fail "Test 4.2: 산출물 위치 표시 없음"
fi

if echo "$output" | grep -q "생성된 파일:"; then
  pass "Test 4.3: 생성된 파일 목록 표시"
else
  fail "Test 4.3: 생성된 파일 목록 표시 없음"
fi

if echo "$output" | grep -q "App.uf2"; then
  pass "Test 4.4: .uf2 파일 정보 표시"
else
  fail "Test 4.4: .uf2 파일 정보 표시 없음"
fi

# Test 5: 빌드 실패 메시지
echo ""
echo "Test 5: 빌드 실패 메시지"

# Mock w55build.sh를 실패하도록 변경
cat > w55build.sh <<'FAILSCRIPT'
#!/usr/bin/env bash
echo "[MOCK] Build failed" >&2
exit 1
FAILSCRIPT
chmod +x w55build.sh

output=$(./build.sh --official --no-confirm 2>&1 || true)

if echo "$output" | grep -q "빌드 실패"; then
  pass "Test 5.1: 빌드 실패 메시지 표시"
else
  fail "Test 5.1: 빌드 실패 메시지 없음"
fi

if echo "$output" | grep -q "exit code:"; then
  pass "Test 5.2: Exit code 표시"
else
  fail "Test 5.2: Exit code 표시 없음"
fi

# w55build.sh 복구
cat > w55build.sh <<'MOCKSCRIPT'
#!/usr/bin/env bash
mkdir -p "$OUT_DIR"
echo "Mock firmware" > "$OUT_DIR/App.uf2"
echo "[MOCK] Build completed successfully"
exit 0
MOCKSCRIPT
chmod +x w55build.sh

# Test 6: --quiet 모드
echo ""
echo "Test 6: --quiet 모드"

output=$(./build.sh --official --no-confirm --quiet 2>&1 || true)

# --quiet에서는 대부분의 메시지가 생략되어야 함
if echo "$output" | grep -q "저장된 설정을 사용합니다"; then
  fail "Test 6.1: --quiet인데 저장된 설정 메시지 표시됨"
else
  pass "Test 6.1: --quiet 시 저장된 설정 메시지 생략"
fi

if echo "$output" | grep -q "계속하시겠습니까?"; then
  fail "Test 6.2: --quiet인데 확인 프롬프트 표시됨"
else
  pass "Test 6.2: --quiet 시 확인 프롬프트 생략"
fi

if echo "$output" | grep -q "빌드 성공"; then
  fail "Test 6.3: --quiet인데 빌드 성공 메시지 표시됨"
else
  pass "Test 6.3: --quiet 시 빌드 성공 메시지 생략"
fi

# Test 7: 확인 프롬프트에서 취소 (n 입력)
echo ""
echo "Test 7: 확인 프롬프트 취소"
rm -f .build-config

output=$(echo "n" | ./build.sh --official 2>&1 || true)

if echo "$output" | grep -q "취소되었습니다"; then
  pass "Test 7.1: 취소 메시지 표시"
else
  fail "Test 7.1: 취소 메시지 없음"
fi

# 빌드가 실행되지 않아야 함
if echo "$output" | grep -q "Build completed"; then
  fail "Test 7.2: 취소했는데 빌드가 실행됨"
else
  pass "Test 7.2: 취소 시 빌드 실행 안 됨"
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
