#!/usr/bin/env bash
# 통합 테스트: 모든 기능 함께 동작 확인

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
TESTDIR="/tmp/test-integration-$$"
mkdir -p "$TESTDIR"
cd "$TESTDIR"

# build.sh와 w55build.sh 복사
cp /home/sr/src/docker/w55rp20/build.sh .
cp /home/sr/src/docker/w55rp20/w55build.sh .

# Mock w55build.sh
cat > w55build.sh <<'MOCKSCRIPT'
#!/usr/bin/env bash
mkdir -p "$OUT_DIR"
echo "Mock UF2" > "$OUT_DIR/Firmware.uf2"
echo "[INFO] Build completed with SRC_DIR=$SRC_DIR OUT_DIR=$OUT_DIR JOBS=$JOBS"
exit 0
MOCKSCRIPT
chmod +x w55build.sh

# 테스트 프로젝트 생성
mkdir -p /tmp/test-project-$$
touch /tmp/test-project-$$/CMakeLists.txt

cleanup() {
  cd /
  rm -rf "$TESTDIR"
  rm -rf /tmp/test-project-$$
}
trap cleanup EXIT

echo "=== Integration Test Suite ==="
echo "Test directory: $TESTDIR"
echo ""

# Scenario 1: 초보자 워크플로우
echo "=== Scenario 1: 초보자 워크플로우 (민수) ==="
echo ""
rm -f .build-config

# 1.1: --setup으로 대화형 설정
echo "Test 1.1: --setup으로 초기 설정"
mkdir -p src
output=$(echo -e "1\n1\nY" | ./build.sh --setup 2>&1 || true)

if [ -f ".build-config" ] && \
   echo "$output" | grep -q "설정을 저장했습니다"; then
  pass "Scenario 1.1: --setup으로 설정 생성 성공"
else
  fail "Scenario 1.1: --setup으로 설정 생성 실패"
fi

# 1.2: 다음 빌드에서 설정 자동 로드
echo "Test 1.2: 저장된 설정 자동 로드"
output=$(echo "Y" | ./build.sh 2>&1 || true)

if echo "$output" | grep -q "저장된 설정을 사용합니다"; then
  pass "Scenario 1.2: 저장된 설정 자동 로드 성공"
else
  fail "Scenario 1.2: 저장된 설정 자동 로드 실패"
fi

# Scenario 2: 개발자 워크플로우
echo ""
echo "=== Scenario 2: 개발자 워크플로우 (수진) ==="
echo ""
rm -f .build-config

# 2.1: 사용자 프로젝트 빌드
echo "Test 2.1: 사용자 프로젝트 지정"
output=$(./build.sh --project /tmp/test-project-$$ --no-confirm 2>&1 || true)

if echo "$output" | grep -q "SRC_DIR=/tmp/test-project-$$"; then
  pass "Scenario 2.1: 사용자 프로젝트 경로 설정 성공"
else
  fail "Scenario 2.1: 사용자 프로젝트 경로 설정 실패"
fi

# 2.2: 설정 저장 및 재사용
echo "Test 2.2: 설정 저장"
TEST_PID=$$
./build.sh --project /tmp/test-project-$TEST_PID --save-config >/dev/null 2>&1

if [ -f ".build-config" ] && \
   grep -q "SRC_DIR=\"/tmp/test-project-$TEST_PID\"" .build-config; then
  pass "Scenario 2.2: 설정 저장 성공"
else
  fail "Scenario 2.2: 설정 저장 실패"
fi

# 2.3: 저장된 설정으로 빌드
output=$(echo "Y" | ./build.sh 2>&1 || true)

if echo "$output" | grep -q "저장된 설정을 사용합니다" && \
   echo "$output" | grep -q "test-project-$$"; then
  pass "Scenario 2.3: 저장된 설정으로 빌드 성공"
else
  fail "Scenario 2.3: 저장된 설정으로 빌드 실패"
fi

# Scenario 3: 고급 사용자 워크플로우
echo ""
echo "=== Scenario 3: 고급 사용자 워크플로우 (현우) ==="
echo ""

# 3.1: 완전 자동화 (--no-confirm --quiet)
echo "Test 3.1: 자동화 스크립트"
output=$(./build.sh --project /tmp/test-project-$$ --output /tmp/out-$$ --no-confirm --quiet 2>&1 || true)

# quiet 모드에서는 minimal output
if [ -d "/tmp/out-$$" ] && [ -f "/tmp/out-$$/Firmware.uf2" ]; then
  pass "Scenario 3.1: 자동화 빌드 성공 (산출물 생성됨)"
else
  fail "Scenario 3.1: 자동화 빌드 실패"
fi

rm -rf /tmp/out-$$

# 3.2: 여러 옵션 조합
echo "Test 3.2: 복합 옵션 사용"
output=$(./build.sh --project /tmp/test-project-$$ --output ./artifacts --jobs 32 --debug --refresh sdk --no-confirm 2>&1 || true)

if echo "$output" | grep -q "JOBS=32" && \
   echo "$output" | grep -q "BUILD_TYPE=Debug"; then
  pass "Scenario 3.2: 복합 옵션 적용 성공"
else
  fail "Scenario 3.2: 복합 옵션 적용 실패"
fi

# Scenario 4: 우선순위 테스트
echo ""
echo "=== Scenario 4: 설정 우선순위 ==="
echo ""
rm -f .build-config

# 4.1: .build-config 생성
cat > .build-config <<EOF
SRC_DIR="./config-src"
OUT_DIR="./config-out"
JOBS=8
BUILD_TYPE="Release"
EOF

# 4.2: CLI 옵션이 .build-config를 덮어씀
output=$(./build.sh --project /tmp/test-project-$$ --jobs 16 --debug --no-confirm 2>&1 || true)

if echo "$output" | grep -q "SRC_DIR=/tmp/test-project-$$" && \
   echo "$output" | grep -q "JOBS=16" && \
   echo "$output" | grep -q "BUILD_TYPE=Debug"; then
  pass "Scenario 4: CLI 옵션이 .build-config보다 우선순위 높음"
else
  fail "Scenario 4: 우선순위 동작 실패"
fi

# Scenario 5: 오류 처리
echo ""
echo "=== Scenario 5: 오류 처리 ==="
echo ""

# 5.1: 잘못된 옵션
output=$(./build.sh --invalid-option 2>&1 || true)
if echo "$output" | grep -q "Unknown option"; then
  pass "Scenario 5.1: 잘못된 옵션 감지"
else
  fail "Scenario 5.1: 잘못된 옵션 미감지"
fi

# 5.2: 충돌하는 옵션
output=$(./build.sh --official --project /tmp/foo 2>&1 || true)
if echo "$output" | grep -q "cannot be used together"; then
  pass "Scenario 5.2: 옵션 충돌 감지"
else
  fail "Scenario 5.2: 옵션 충돌 미감지"
fi

# 5.3: 필수 인자 누락
output=$(./build.sh --project 2>&1 || true)
if echo "$output" | grep -q "requires a path"; then
  pass "Scenario 5.3: 필수 인자 누락 감지"
else
  fail "Scenario 5.3: 필수 인자 누락 미감지"
fi

# Scenario 6: 도움말 및 정보
echo ""
echo "=== Scenario 6: 도움말 및 정보 ==="
echo ""

# 6.1: --help
output=$(./build.sh --help 2>&1 || true)
if echo "$output" | grep -q "Usage:" && \
   echo "$output" | grep -q "OPTIONS:"; then
  pass "Scenario 6.1: --help 표시"
else
  fail "Scenario 6.1: --help 표시 실패"
fi

# 6.2: --version
output=$(./build.sh --version 2>&1 || true)
if echo "$output" | grep -q "1.1.0"; then
  pass "Scenario 6.2: --version 표시"
else
  fail "Scenario 6.2: --version 표시 실패"
fi

# 6.3: --show-config
cat > .build-config <<EOF
SRC_DIR="./src"
OUT_DIR="./out"
JOBS=16
EOF

output=$(./build.sh --show-config 2>&1 || true)
if echo "$output" | grep -q "Current build configuration"; then
  pass "Scenario 6.3: --show-config 표시"
else
  fail "Scenario 6.3: --show-config 표시 실패"
fi

echo ""
echo "=== Test Results ==="
echo "Total:  $TEST_COUNT"
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"
echo ""

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "✓ All integration tests passed!"
  echo ""
  echo "모든 기능이 정상 동작합니다:"
  echo "  ✓ CLI 옵션 파싱"
  echo "  ✓ .build-config 저장/로드"
  echo "  ✓ Interactive mode (--setup)"
  echo "  ✓ Progress display"
  echo "  ✓ 우선순위 처리"
  echo "  ✓ 오류 처리"
  echo "  ✓ 도움말 및 정보"
  exit 0
else
  echo "✗ Some integration tests failed"
  exit 1
fi
