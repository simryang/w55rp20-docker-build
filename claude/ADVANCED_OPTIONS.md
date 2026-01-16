# 고급 옵션 상세 가이드

**작성:** 2026-01-16 16:30 KST

---

## 개요

일반 사용자는 대화형 모드(`./build.sh`)만 사용하면 됩니다.
고급 사용자를 위한 CLI 옵션을 상세히 설명합니다.

---

## 옵션 전체 목록

```bash
./build.sh [OPTIONS]

프로젝트 선택:
  --project PATH        프로젝트 디렉토리 지정
  --official            공식 W55RP20-S2E 사용 (기본값)

산출물:
  --output PATH         산출물 디렉토리 지정 (기본: ./out)

빌드 옵션:
  --clean               산출물 정리 후 빌드
  --debug               디버그 빌드 (BUILD_TYPE=Debug)
  --jobs N              병렬 작업 수 지정
  --refresh WHAT        캐시 무효화 (apt/sdk/cmake/gcc/toolchain/all)

편의 기능:
  --no-confirm          확인 없이 즉시 실행
  --quiet               최소 출력 (에러만)
  --verbose             상세 출력 (디버깅용)

설정 관리:
  --setup               설정 초기화 및 재설정
  --show-config         현재 설정 표시
  --save-config         현재 옵션을 .build-config에 저장

도움말:
  --help, -h            이 도움말 표시
  --version             버전 정보
```

---

## 프로젝트 선택 옵션

### `--project PATH`

**목적:** 빌드할 프로젝트 디렉토리를 지정합니다.

**사용 시나리오:**
- 여러 프로젝트를 관리하는 경우
- 프로젝트가 다른 위치에 있는 경우
- CI/CD 파이프라인에서 사용

**예시:**

```bash
# 절대 경로
./build.sh --project /home/user/my-w55rp20-project

# 홈 디렉토리 (~)
./build.sh --project ~/workspace/w55-firmware

# 상대 경로 (현재 디렉토리 기준)
./build.sh --project ../my-project

# 다른 옵션과 조합
./build.sh --project ~/proj-A --output ./artifacts/proj-A
```

**검증:**
- CMakeLists.txt 파일 존재 확인
- 디렉토리 읽기 권한 확인
- Git 저장소 여부 확인 (경고만, 필수 아님)

**에러 처리:**
```bash
$ ./build.sh --project /invalid/path
❌ 프로젝트를 찾을 수 없습니다: /invalid/path
💡 CMakeLists.txt가 있는 디렉토리를 지정하세요
```

---

### `--official`

**목적:** 공식 W55RP20-S2E 프로젝트를 명시적으로 지정합니다.

**사용 시나리오:**
- 스크립트에서 명확성을 위해
- .build-config에 다른 프로젝트가 저장되어 있지만 공식 예제로 되돌리고 싶을 때

**예시:**

```bash
# 공식 프로젝트로 빌드 (./src에 자동 클론)
./build.sh --official

# .build-config 무시하고 공식 프로젝트 사용
./build.sh --official --no-confirm
```

**동작:**
- `./src/` 디렉토리에 W55RP20-S2E 클론
- 이미 존재하면 재사용
- `--project`와 동시 사용 시 에러

---

## 산출물 옵션

### `--output PATH`

**목적:** 빌드 산출물(.uf2, .elf 등)을 저장할 디렉토리를 지정합니다.

**사용 시나리오:**
- 여러 빌드를 구분해서 보관
- 네트워크 드라이브에 직접 저장
- CI/CD artifact 디렉토리 지정

**예시:**

```bash
# 기본 사용
./build.sh --output ./build-artifacts

# 날짜별 디렉토리
./build.sh --output ./artifacts/$(date +%Y%m%d)

# 프로젝트별 디렉토리
./build.sh --project ~/proj-A --output ./artifacts/proj-A
./build.sh --project ~/proj-B --output ./artifacts/proj-B

# 절대 경로
./build.sh --output /mnt/shared/builds

# 프로젝트 디렉토리 내부
./build.sh --project ~/my-proj --output ~/my-proj/build
```

**자동 생성:**
- 디렉토리가 없으면 자동 생성
- 부모 디렉토리가 없으면 에러

**권한 확인:**
```bash
$ ./build.sh --output /root/out
❌ 산출물 디렉토리를 생성할 수 없습니다: /root/out
💡 쓰기 권한이 있는 경로를 지정하세요
```

---

## 빌드 옵션

### `--clean`

**목적:** 빌드 전에 이전 산출물을 정리합니다.

**사용 시나리오:**
- 완전히 깨끗한 빌드 필요
- 이전 빌드 산출물 때문에 혼란
- CI/CD에서 재현 가능한 빌드

**예시:**

```bash
# 정리 후 빌드
./build.sh --clean

# 프로젝트 지정 + 정리
./build.sh --project ~/my-proj --clean

# 자동화 스크립트
./build.sh --project ~/proj --clean --no-confirm
```

**동작:**
```bash
# 다음 파일들을 삭제:
rm -f $OUT_DIR/*.uf2
rm -f $OUT_DIR/*.elf
rm -f $OUT_DIR/*.bin
rm -f $OUT_DIR/*.hex
```

**주의:**
- Docker 빌드 캐시는 유지 (속도 유지)
- 소스 코드는 삭제 안 됨 (안전)
- 전체 재빌드: `--refresh all --clean`

---

### `--debug`

**목적:** 디버그 빌드를 생성합니다 (BUILD_TYPE=Debug).

**사용 시나리오:**
- GDB 디버깅 필요
- 최적화 없는 빌드 필요
- 스택 트레이스 확인

**예시:**

```bash
# 디버그 빌드
./build.sh --debug

# 디버그 빌드 + 정리
./build.sh --debug --clean

# 디버그 빌드 + 프로젝트 지정
./build.sh --project ~/my-proj --debug --output ./debug-build
```

**차이점:**

| 옵션 | Release (기본) | Debug (--debug) |
|------|----------------|-----------------|
| 최적화 | -O3 | -O0 |
| 디버그 심볼 | 제한적 | 전체 |
| 파일 크기 | 작음 | 큼 |
| 실행 속도 | 빠름 | 느림 |
| 디버깅 | 어려움 | 쉬움 |

**산출물 예시:**
```
Release: App.elf (1.7 MB)
Debug:   App.elf (3.5 MB)  ← 더 큼
```

---

### `--jobs N`

**목적:** 병렬 빌드 작업 수를 지정합니다.

**사용 시나리오:**
- 고성능 서버에서 빌드
- 저사양 환경 (라즈베리파이)
- CI/CD 리소스 제한

**예시:**

```bash
# 고성능 서버 (32코어)
./build.sh --jobs 32

# 저사양 환경 (4코어)
./build.sh --jobs 4

# 단일 코어 (디버깅용)
./build.sh --jobs 1

# 자동 (CPU 코어 수)
./build.sh  # 기본값
```

**자동 감지:**
```bash
# 기본값: $(nproc) 사용
# 16코어 시스템 → JOBS=16
```

**메모리 고려:**
```bash
# 각 작업당 약 200-500MB 메모리 사용
# 16GB RAM → --jobs 16-20 권장
# 8GB RAM  → --jobs 8-12 권장
# 4GB RAM  → --jobs 4-6 권장

# 저사양 환경
./build.sh --jobs 4 --tmpfs-size 4g
```

**빌드 시간:**
```
JOBS=1   → 약 10분
JOBS=4   → 약 3분
JOBS=16  → 약 1.5분
JOBS=32  → 약 1분 (과다하면 오버헤드)
```

---

### `--refresh WHAT`

**목적:** Docker 이미지 캐시를 선택적으로 무효화합니다.

**사용 시나리오:**
- 외부 패키지/SDK 업데이트
- 빌드 환경 문제 해결
- 새 버전 테스트

**옵션:**

```bash
# apt 패키지만 재설치
./build.sh --refresh apt

# Pico SDK만 재다운로드
./build.sh --refresh sdk

# CMake만 재설치
./build.sh --refresh cmake

# ARM GCC 툴체인만 재설치
./build.sh --refresh gcc

# CMake + GCC (별칭)
./build.sh --refresh toolchain

# 전체 재빌드 (모든 캐시 무효화)
./build.sh --refresh all
```

**예시 시나리오:**

**케이스 1: Pico SDK 업데이트**
```bash
# Pico SDK 2.2.0 → 2.3.0 출시
./build.sh --refresh sdk
```

**케이스 2: 시스템 패키지 업데이트**
```bash
# Ubuntu 패키지 업데이트 후
./build.sh --refresh apt
```

**케이스 3: 툴체인 업데이트**
```bash
# ARM GCC 14.2 → 14.3 출시
./build.sh --refresh gcc
```

**케이스 4: 전체 문제 해결**
```bash
# 원인 불명 빌드 실패 시
./build.sh --refresh all --clean
```

**빌드 시간:**
```
refresh apt       → +2분 (apt-get update/install)
refresh sdk       → +3분 (git clone + submodules)
refresh cmake     → +1분 (다운로드 + 설치)
refresh gcc       → +2분 (다운로드 + 압축해제)
refresh toolchain → +3분 (cmake + gcc)
refresh all       → +10분 (전체 재빌드)
```

---

## 편의 기능

### `--no-confirm`

**목적:** 확인 프롬프트를 건너뛰고 즉시 실행합니다.

**사용 시나리오:**
- 자동화 스크립트
- CI/CD 파이프라인
- 반복 빌드

**예시:**

```bash
# 일반 사용 (확인 요청)
./build.sh --project ~/proj
# 계속하시겠습니까? [Y/n]: █

# 자동 실행 (확인 없음)
./build.sh --project ~/proj --no-confirm
# → 즉시 빌드 시작

# 자동화 스크립트
for proj in project-{A,B,C}; do
  ./build.sh --project ~/$proj --no-confirm --quiet
done

# CI/CD
./build.sh --project $CI_PROJECT_DIR --no-confirm --output $CI_ARTIFACTS_DIR
```

**건너뛰는 확인:**
- 프로젝트 선택 확인
- 설정 확인 프롬프트
- "계속하시겠습니까?" 질문

**여전히 표시되는 것:**
- 진행 상황 메시지
- 에러 메시지
- 최종 성공/실패 메시지

---

### `--quiet`

**목적:** 최소한의 출력만 표시합니다 (에러만).

**사용 시나리오:**
- 로그 파일 크기 최소화
- CI/CD 로그 정리
- 자동화 스크립트

**예시:**

```bash
# 일반 출력
./build.sh
# [1/4] Docker 이미지 확인...
# [2/4] 소스 다운로드...
# ...

# 최소 출력
./build.sh --quiet
# [빌드 성공 시 출력 없음]
# [실패 시만 에러 메시지]

# 자동화 + 로그
./build.sh --project ~/proj --no-confirm --quiet > build.log 2>&1

# 성공/실패 확인
if ./build.sh --quiet --no-confirm; then
  echo "Build OK"
else
  echo "Build FAILED"
fi
```

**출력 비교:**

**일반 모드:**
```
[1/4] 🐳 Docker 이미지 확인 중...
✓ w55rp20:auto 사용 가능
[2/4] 🔨 빌드 시작...
      ━━━━━━━━━━━━━━━━━━ 100%
✓ 빌드 성공!
[3/4] 📋 산출물 복사 중...
✓ 완료!
```

**Quiet 모드:**
```
[성공 시 출력 없음]

[실패 시만]
❌ 빌드 실패: make error
```

---

### `--verbose`

**목적:** 상세한 디버깅 정보를 출력합니다.

**사용 시나리오:**
- 빌드 문제 디버깅
- 내부 동작 이해
- 이슈 리포팅

**예시:**

```bash
# 상세 출력
./build.sh --verbose

# 문제 해결
./build.sh --project ~/prob-proj --verbose > debug.log 2>&1

# refresh와 함께 (문제 진단)
./build.sh --refresh all --verbose
```

**추가 출력:**
```
[VERBOSE] SRC_DIR=/home/user/project
[VERBOSE] OUT_DIR=./out
[VERBOSE] JOBS=16
[VERBOSE] TMPFS_SIZE=24g
[VERBOSE] Docker command:
  sudo docker run --rm -t \
    -v /home/user/project:/work/src \
    -v /home/user/w55rp20/out:/work/out \
    --tmpfs /work/src/build:rw,exec,size=24g \
    ...
[VERBOSE] Build started at: 2026-01-16 16:40:00
[VERBOSE] ccache stats: 45% hit rate
[VERBOSE] tmpfs peak usage: 2.3 GiB
[VERBOSE] Build completed at: 2026-01-16 16:42:15
[VERBOSE] Total time: 135 seconds
```

---

## 설정 관리

### `--setup`

**목적:** 저장된 설정을 무시하고 처음부터 다시 설정합니다.

**사용 시나리오:**
- 다른 프로젝트로 전환
- 설정 잘못됨
- 처음부터 다시 시작

**예시:**

```bash
# 현재 상태
$ cat .build-config
SRC_DIR="/home/user/old-project"

# 설정 초기화
$ ./build.sh --setup

📋 빌드할 프로젝트를 선택하세요:
  1) 공식 예제
  2) 내 프로젝트

선택: 2
프로젝트 경로: /home/user/new-project█

✓ 새 설정이 저장되었습니다
```

**동작:**
1. .build-config 무시
2. 대화형 모드로 새 설정 입력
3. 새 설정을 .build-config에 저장

---

### `--show-config`

**목적:** 현재 저장된 설정을 표시합니다.

**사용 시나리오:**
- 현재 설정 확인
- 문제 진단
- 문서화

**예시:**

```bash
$ ./build.sh --show-config

현재 빌드 설정:

프로젝트:
  SRC_DIR = /home/user/my-w55rp20-project

산출물:
  OUT_DIR = ./out

빌드 옵션:
  JOBS = 16
  BUILD_TYPE = Release
  TMPFS_SIZE = 24g

설정 파일: .build-config
마지막 사용: 2026-01-16 16:35:00

변경하려면: ./build.sh --setup
```

---

### `--save-config`

**목적:** 현재 명령줄 옵션을 .build-config에 저장합니다.

**사용 시나리오:**
- 실험 후 설정 저장
- 일회성 빌드를 기본값으로

**예시:**

```bash
# 여러 옵션 실험
./build.sh --project ~/proj-A --output ~/artifacts --jobs 32

# 마음에 들면 저장
./build.sh --project ~/proj-A --output ~/artifacts --jobs 32 --save-config

# 다음부터는 간단히
./build.sh  # 저장된 설정 사용
```

---

## 옵션 조합 예시

### 시나리오 1: 일상 개발 워크플로우

```bash
# 첫 빌드
./build.sh --project ~/my-project

# 코드 수정...

# 재빌드 (설정 기억됨)
./build.sh

# 정리 후 재빌드
./build.sh --clean

# 디버그 빌드
./build.sh --debug
```

### 시나리오 2: CI/CD 파이프라인

```bash
#!/bin/bash
# .gitlab-ci.yml

build:
  script:
    - git clone $REPO_URL project
    - ./build.sh \
        --project ./project \
        --output $CI_ARTIFACTS_DIR \
        --no-confirm \
        --quiet \
        --jobs 8
```

### 시나리오 3: Nightly 빌드

```bash
#!/bin/bash
# nightly-build.sh

DATE=$(date +%Y%m%d)
PROJECTS=(
  "/workspace/project-A"
  "/workspace/project-B"
  "/workspace/project-C"
)

for proj in "${PROJECTS[@]}"; do
  name=$(basename "$proj")

  ./build.sh \
    --project "$proj" \
    --output "./artifacts/$DATE/$name" \
    --clean \
    --no-confirm \
    --quiet

  if [ $? -eq 0 ]; then
    echo "✓ $name"
  else
    echo "✗ $name" >&2
  fi
done
```

### 시나리오 4: 멀티 브랜치 테스트

```bash
#!/bin/bash
# test-branches.sh

PROJECT=/workspace/my-project
BRANCHES=(main develop feature-A feature-B)

for branch in "${BRANCHES[@]}"; do
  echo "Testing branch: $branch"

  (cd "$PROJECT" && git checkout "$branch")

  ./build.sh \
    --project "$PROJECT" \
    --output "./test-builds/$branch" \
    --no-confirm \
    --clean
done
```

### 시나리오 5: 완전 재빌드 (문제 해결)

```bash
# 모든 캐시 무효화 + 정리
./build.sh \
  --refresh all \
  --clean \
  --verbose \
  > full-rebuild.log 2>&1

# 로그 확인
less full-rebuild.log
```

### 시나리오 6: 릴리스 빌드

```bash
#!/bin/bash
# release.sh

VERSION=$(git describe --tags)
DATE=$(date +%Y%m%d)

./build.sh \
  --project . \
  --output "./release/$VERSION" \
  --clean \
  --jobs 32 \
  --no-confirm

# 산출물 압축
tar -czf "release-$VERSION-$DATE.tar.gz" "./release/$VERSION"
```

---

## 우선순위 규칙

### 옵션 우선순위

```
CLI 옵션 > 환경 변수 > .build-config > 기본값
```

**예시:**

```bash
# .build-config
SRC_DIR=/old/project

# 환경 변수
export SRC_DIR=/env/project

# CLI 옵션
./build.sh --project /cli/project

# 결과: /cli/project 사용 (CLI 최우선)
```

### 옵션 충돌

```bash
# 충돌 1: --official vs --project
./build.sh --official --project ~/proj
# → 에러: 동시 사용 불가

# 충돌 2: --quiet vs --verbose
./build.sh --quiet --verbose
# → 에러: 동시 사용 불가

# 정상: 마지막 옵션 우선
./build.sh --jobs 8 --jobs 16
# → JOBS=16 사용
```

---

## 환경 변수 (레거시 지원)

기존 사용자를 위해 환경 변수도 계속 지원:

```bash
# 옵션 방식 (권장)
./build.sh --project ~/proj --jobs 32

# 환경 변수 방식 (기존)
SRC_DIR=~/proj JOBS=32 ./build.sh

# 둘 다 동일한 결과
```

**변수 매핑:**

| CLI 옵션 | 환경 변수 |
|----------|-----------|
| --project PATH | SRC_DIR=PATH |
| --output PATH | OUT_DIR=PATH |
| --jobs N | JOBS=N |
| --debug | BUILD_TYPE=Debug |
| --clean | CLEAN=1 |
| --verbose | VERBOSE=1 |
| --refresh WHAT | REFRESH=WHAT |

---

## 요약

### 초보자
```bash
./build.sh  # 이것만 알면 됨
```

### 일반 사용자
```bash
./build.sh --project ~/my-proj  # 처음 한번
./build.sh                       # 그 다음부터
```

### 고급 사용자
```bash
./build.sh --project ~/proj --output ./out --jobs 32 --no-confirm --quiet
```

### 자동화
```bash
for p in proj-{A,B,C}; do
  ./build.sh --project ~/$p --output ./artifacts/$p --no-confirm --quiet
done
```

---

## 다음 단계

이 설계로 구현을 진행할까요?
아니면 옵션을 더 추가/제거/수정할까요?
