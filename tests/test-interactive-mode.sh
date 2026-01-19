#!/usr/bin/env bash
# 테스트: Interactive mode (--setup)

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
TESTDIR="/tmp/test-interactive-$$"
mkdir -p "$TESTDIR"
cd "$TESTDIR"

# build.sh와 w55build.sh 복사
cp /home/sr/src/docker/w55rp20/build.sh .
cp /home/sr/src/docker/w55rp20/w55build.sh .

# Mock w55build.sh (실제 빌드 안 함)
cat > w55build.sh <<'MOCKSCRIPT'
#!/usr/bin/env bash
echo "[MOCK] Build would run with:"
echo "  SRC_DIR=$SRC_DIR"
echo "  OUT_DIR=$OUT_DIR"
echo "  JOBS=$JOBS"
exit 0
MOCKSCRIPT
chmod +x w55build.sh

cleanup() {
  cd /
  rm -rf "$TESTDIR"
}
trap cleanup EXIT

echo "=== Interactive Mode Test Suite ==="
echo "Test directory: $TESTDIR"
echo ""

# Test 1: --setup with official project (option 1)
echo "Test 1: --setup 공식 프로젝트 선택"
rm -f .build-config
mkdir -p src

# 입력 시뮬레이션: 1 (공식), 1 (./out/), Y (확인)
output=$(echo -e "1\n1\nY" | ./build.sh --setup 2>&1 || true)

if echo "$output" | grep -q "공식 예제 프로젝트 선택됨"; then
  pass "Test 1.1: 공식 프로젝트 선택 메시지 표시"
else
  fail "Test 1.1: 공식 프로젝트 선택 메시지 없음"
fi

if [ -f ".build-config" ]; then
  pass "Test 1.2: .build-config 파일 생성됨"
else
  fail "Test 1.2: .build-config 파일이 생성되지 않음"
fi

if grep -q 'SRC_DIR="./src"' .build-config; then
  pass "Test 1.3: SRC_DIR이 ./src로 설정됨"
else
  fail "Test 1.3: SRC_DIR이 올바르게 설정되지 않음"
fi

# Test 2: --setup with custom project (option 2)
echo ""
echo "Test 2: --setup 사용자 프로젝트 선택"
rm -f .build-config
mkdir -p /tmp/test-w55-project
touch /tmp/test-w55-project/CMakeLists.txt

# 입력 시뮬레이션: 2 (내 프로젝트), /tmp/test-w55-project, 1 (./out/), Y (확인)
output=$(echo -e "2\n/tmp/test-w55-project\n1\nY" | ./build.sh --setup 2>&1 || true)

if echo "$output" | grep -q "내 프로젝트 선택됨"; then
  pass "Test 2.1: 내 프로젝트 선택 메시지 표시"
else
  fail "Test 2.1: 내 프로젝트 선택 메시지 없음"
fi

if echo "$output" | grep -q "CMakeLists.txt 발견"; then
  pass "Test 2.2: CMakeLists.txt 검증 성공"
else
  fail "Test 2.2: CMakeLists.txt 검증 실패"
fi

if grep -q 'SRC_DIR="/tmp/test-w55-project"' .build-config; then
  pass "Test 2.3: 사용자 프로젝트 경로가 저장됨"
else
  fail "Test 2.3: 사용자 프로젝트 경로가 저장되지 않음"
fi

# Test 3: --setup with non-existent directory
echo ""
echo "Test 3: --setup 존재하지 않는 디렉토리"
rm -f .build-config

# 입력 시뮬레이션: 2 (내 프로젝트), /tmp/non-existent-dir
output=$(echo -e "2\n/tmp/non-existent-dir-$$$$" | ./build.sh --setup 2>&1 || true)

if echo "$output" | grep -q "디렉토리가 존재하지 않습니다"; then
  pass "Test 3.1: 존재하지 않는 디렉토리 오류 처리"
else
  fail "Test 3.1: 존재하지 않는 디렉토리 오류 처리 실패"
fi

# Test 4: --setup with directory without CMakeLists.txt (warning)
echo ""
echo "Test 4: --setup CMakeLists.txt 없는 디렉토리"
rm -f .build-config
mkdir -p /tmp/test-no-cmake
rm -f /tmp/test-no-cmake/CMakeLists.txt

# 입력 시뮬레이션: 2 (내 프로젝트), /tmp/test-no-cmake, n (취소)
output=$(echo -e "2\n/tmp/test-no-cmake\nn" | ./build.sh --setup 2>&1 || true)

if echo "$output" | grep -q "CMakeLists.txt를 찾을 수 없습니다"; then
  pass "Test 4.1: CMakeLists.txt 없음 경고 표시"
else
  fail "Test 4.1: CMakeLists.txt 없음 경고 없음"
fi

if echo "$output" | grep -q "취소되었습니다"; then
  pass "Test 4.2: 사용자 취소 처리"
else
  fail "Test 4.2: 사용자 취소 처리 실패"
fi

# Test 5: --setup cancel at final confirmation
echo ""
echo "Test 5: --setup 최종 확인에서 취소"
rm -f .build-config
mkdir -p src

# 입력 시뮬레이션: 1 (공식), 1 (./out/), n (취소)
output=$(echo -e "1\n1\nn" | ./build.sh --setup 2>&1 || true)

if echo "$output" | grep -q "취소되었습니다"; then
  pass "Test 5.1: 최종 확인 취소 처리"
else
  fail "Test 5.1: 최종 확인 취소 처리 실패"
fi

if [ ! -f ".build-config" ]; then
  pass "Test 5.2: 취소 시 .build-config 생성 안 됨"
else
  # 이미 이전 테스트에서 생성되었을 수 있으므로, 확인 필요
  # 하지만 우리가 rm -f로 지웠으므로 없어야 함
  fail "Test 5.2: 취소 시 .build-config가 생성됨 (버그)"
fi

# Test 6: --setup output path options
echo ""
echo "Test 6: --setup 산출물 경로 선택"
rm -f .build-config
mkdir -p src

# 입력 시뮬레이션: 1 (공식), 3 (직접 지정), /tmp/custom-output, Y (확인)
output=$(echo -e "1\n3\n/tmp/custom-output\nY" | ./build.sh --setup 2>&1 || true)

if grep -q 'OUT_DIR="/tmp/custom-output"' .build-config; then
  pass "Test 6.1: 사용자 지정 산출물 경로 저장됨"
else
  fail "Test 6.1: 사용자 지정 산출물 경로가 저장되지 않음"
fi

# Test 7: --setup UI elements
echo ""
echo "Test 7: --setup UI 요소 확인"
rm -f .build-config

output=$(echo -e "1\n1\nY" | ./build.sh --setup 2>&1 || true)

if echo "$output" | grep -q "W55RP20 펌웨어 빌드 시스템"; then
  pass "Test 7.1: 헤더 표시"
else
  fail "Test 7.1: 헤더 표시 안 됨"
fi

if echo "$output" | grep -q "빌드할 프로젝트를 선택하세요"; then
  pass "Test 7.2: 프로젝트 선택 프롬프트 표시"
else
  fail "Test 7.2: 프로젝트 선택 프롬프트 없음"
fi

if echo "$output" | grep -q "설정 확인:"; then
  pass "Test 7.3: 설정 요약 표시"
else
  fail "Test 7.3: 설정 요약 표시 안 됨"
fi

if echo "$output" | grep -q "설정을 저장했습니다"; then
  pass "Test 7.4: 설정 저장 확인 메시지"
else
  fail "Test 7.4: 설정 저장 확인 메시지 없음"
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
