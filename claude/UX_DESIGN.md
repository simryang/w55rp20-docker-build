# UX-Driven Design: W55RP20 빌드 시스템

**설계 날짜:** 2026-01-16 16:10 KST
**원칙:** 기술이 아닌 사용자 경험 중심

---

## UX 목표

1. **Zero Friction**: 첫 실행이 5초 안에 성공
2. **Self-Explaining**: 읽고 이해하는 게 아니라 보면 알게
3. **Forgiving**: 실수해도 쉽게 복구
4. **Progressive**: 필요할 때만 복잡도 노출
5. **Predictable**: 예상대로 동작

---

## 사용자 페르소나

### 페르소나 1: 민수 (완전 초보자)
- **목표**: W55RP20 펌웨어 빌드해보고 싶음
- **지식**: Docker 들어봤음, Git 써봤음
- **기대**: "그냥 실행하면 된다고 했는데요?"
- **좌절 포인트**: 옵션 10개, 에러 메시지 알아볼 수 없음

### 페르소나 2: 수진 (일반 개발자)
- **목표**: 내 프로젝트 수정하고 빠르게 빌드
- **지식**: C/C++, 임베디드 개발 경험 있음
- **기대**: VSCode에서 F5 누르면 빌드
- **좌절 포인트**: 경로 설정 복잡, 이전 설정 기억 안 됨

### 페르소나 3: 현우 (고급 사용자)
- **목표**: 여러 브랜치, 여러 프로젝트 빌드 자동화
- **지식**: Docker, CI/CD, Shell script
- **기대**: 스크립트로 제어 가능
- **좌절 포인트**: 유연성 부족, 커스터마이징 제한

---

## UX Flow: 민수의 첫 빌드 (완전 초보자)

### 시나리오: "그냥 한번 해보고 싶어요"

```
$ ./build.sh
```

**출력:**
```
╔═══════════════════════════════════════════════════════╗
║         W55RP20 펌웨어 빌드 시스템 v1.0              ║
╚═══════════════════════════════════════════════════════╝

🎯 목표: W55RP20 펌웨어(.uf2)를 빌드합니다

📋 빌드할 프로젝트를 선택하세요:

  1) 공식 예제 프로젝트 (추천)
     → WIZnet 공식 W55RP20-S2E 프로젝트를 자동으로 다운로드
     → 처음 사용하시거나 테스트용으로 좋습니다

  2) 내 프로젝트
     → 이미 작성한 프로젝트 코드를 빌드합니다
     → 프로젝트 폴더 경로를 입력해야 합니다

선택 [1-2] (기본값: 1): █
```

**민수가 Enter만 누름**

```
✓ 공식 예제 프로젝트 선택됨

📦 다운로드 위치:
   ./src/  (현재 디렉토리 안)

⚙️  설정 확인:
   • 프로젝트: ./src/ (공식 W55RP20-S2E)
   • 산출물:   ./out/
   • 병렬작업: 16개
   • 빌드타입: Release

계속하시겠습니까? [Y/n]: █
```

**민수가 Enter만 누름**

```
✓ 시작합니다!

[1/4] 🐳 Docker 이미지 확인 중...
      → w55rp20:auto 이미지가 없습니다
      → 자동으로 빌드합니다 (처음 한번만, 약 5분 소요)

      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100%

✓ Docker 이미지 준비 완료

[2/4] 📥 소스 코드 다운로드 중...
      → https://github.com/WIZnet-ioNIC/W55RP20-S2E.git
      → ./src/ 에 저장

      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100%

✓ 소스 코드 준비 완료

[3/4] 🔨 빌드 시작... (약 2분 소요)

      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100%

✓ 빌드 성공!

[4/4] 📋 산출물 복사 중...
      → ./out/App.uf2      (622 KB) ✓
      → ./out/Boot.uf2     (118 KB) ✓
      → ./out/App.elf      (1.7 MB) ✓

✓ 완료!

╔═══════════════════════════════════════════════════════╗
║                  🎉 빌드 성공!                        ║
╚═══════════════════════════════════════════════════════╝

📦 산출물 위치: ./out/

🚀 다음 단계:
   1. W55RP20 보드의 BOOTSEL 버튼을 누른 채로 USB 연결
   2. 파일 복사: cp ./out/App.uf2 /media/RPI-RP2/
   3. 보드가 자동으로 재부팅됩니다!

💾 이 설정을 저장했습니다 (.build-config)
   다음부터는 ./build.sh만 실행하면 같은 설정으로 빌드합니다.

💡 도움말: ./build.sh --help
```

**민수의 반응:** "오, 됐네!"

---

## UX Flow: 수진의 프로젝트 빌드 (일반 개발자)

### 시나리오: "내 프로젝트를 빌드하고 싶어요"

```
$ ./build.sh
```

**출력:**
```
╔═══════════════════════════════════════════════════════╗
║         W55RP20 펌웨어 빌드 시스템 v1.0              ║
╚═══════════════════════════════════════════════════════╝

🎯 목표: W55RP20 펌웨어(.uf2)를 빌드합니다

📋 빌드할 프로젝트를 선택하세요:

  1) 공식 예제 프로젝트 (추천)
  2) 내 프로젝트

선택 [1-2] (기본값: 1): 2█
```

**수진이 '2' 입력**

```
✓ 내 프로젝트 선택됨

📁 프로젝트 경로를 입력하세요:

   예시:
   • ~/my-w55rp20-project
   • /home/user/workspace/w55-firmware
   • ../my-project

   💡 팁: Tab 키로 자동완성 가능

프로젝트 경로: ~/projects/w55-sensor█
```

**수진이 경로 입력**

```
✓ 경로 확인 중... /home/sujin/projects/w55-sensor

   ✓ CMakeLists.txt 발견
   ✓ 유효한 W55RP20 프로젝트입니다

📦 산출물을 어디에 저장할까요?

  1) 현재 디렉토리 (./out/)  ← 추천
  2) 프로젝트 디렉토리 안 (~/projects/w55-sensor/build/)
  3) 직접 지정

선택 [1-3] (기본값: 1): █
```

**수진이 Enter만 누름**

```
✓ 산출물 위치: ./out/

⚙️  설정 확인:
   • 프로젝트: /home/sujin/projects/w55-sensor
   • 산출물:   ./out/
   • 병렬작업: 16개
   • 빌드타입: Release

계속하시겠습니까? [Y/n]: █
```

**수진이 Enter만 누름**

```
✓ 시작합니다!

[1/3] 🐳 Docker 이미지 확인 중...
✓ w55rp20:auto 이미지 사용 가능

[2/3] 🔨 빌드 시작...

      [빌드 진행 중...]

✓ 빌드 성공!

[3/3] 📋 산출물 복사 중...
      → ./out/MySensor.uf2  (645 KB) ✓

✓ 완료!

💾 설정을 저장했습니다 (.build-config)
   다음부터는 ./build.sh만 실행하면 됩니다.
```

**다음 날, 수진이 코드 수정 후 재빌드:**

```
$ ./build.sh
```

**출력:**
```
╔═══════════════════════════════════════════════════════╗
║         W55RP20 펌웨어 빌드 시스템 v1.0              ║
╚═══════════════════════════════════════════════════════╝

💾 저장된 설정을 사용합니다:
   • 프로젝트: /home/sujin/projects/w55-sensor
   • 산출물:   ./out/

다른 설정을 사용하려면: ./build.sh --setup

계속하시겠습니까? [Y/n]: █
```

**수진이 Enter만 누름 → 즉시 빌드 시작**

**수진의 반응:** "설정 기억해주네, 편하다!"

---

## UX Flow: 현우의 고급 사용 (고급 사용자)

### 시나리오: "여러 프로젝트를 스크립트로 빌드하고 싶어요"

**현우의 빌드 스크립트:**
```bash
#!/bin/bash
# nightly-build.sh

projects=(
  "/workspace/project-A"
  "/workspace/project-B"
  "/workspace/project-C"
)

for proj in "${projects[@]}"; do
  ./build.sh --project "$proj" \
             --output "./artifacts/$(basename $proj)" \
             --no-confirm \
             --quiet
done
```

**실행:**
```
$ ./nightly-build.sh

[1/3] Building project-A... ✓
[2/3] Building project-B... ✓
[3/3] Building project-C... ✓

All builds successful!
Artifacts: ./artifacts/
```

**현우의 반응:** "자동화 쉽네!"

---

## 인터랙션 디자인 원칙

### 1. Progressive Disclosure (점진적 공개)

**나쁜 예:**
```
Usage: build.sh [--project PATH] [--output PATH] [--jobs N]
                [--tmpfs-size SIZE] [--build-type TYPE] [--clean]
                [--verbose] [--refresh WHAT] [--update-repo]
                [--no-image-build] [--platform ARCH] ...
```
→ 압도당함, 뭘 해야 할지 모름

**좋은 예:**
```
📋 빌드할 프로젝트를 선택하세요:
  1) 공식 예제 (추천)
  2) 내 프로젝트
```
→ 명확한 선택지, 하나씩 진행

### 2. Smart Defaults (똑똑한 기본값)

**원칙:**
- Enter만 눌러도 합리적인 결과
- 80%의 사용자는 기본값으로 충분
- 20%의 고급 사용자는 CLI 옵션 사용

**예시:**
```
선택 [1-2] (기본값: 1): █
→ 그냥 Enter → 1번 선택
```

### 3. Clear Feedback (명확한 피드백)

**원칙:**
- 무슨 일이 일어나고 있는지 보여줌
- 진행률 표시
- 성공/실패 명확히 표시
- 다음 단계 안내

**예시:**
```
[2/4] 📥 소스 코드 다운로드 중...
      → https://github.com/WIZnet-ioNIC/W55RP20-S2E.git
      → ./src/ 에 저장

      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100%

✓ 소스 코드 준비 완료
```

### 4. Forgiving Errors (용서하는 에러)

**나쁜 예:**
```
Error: Invalid path
Exit code: 1
```

**좋은 예:**
```
❌ 프로젝트를 찾을 수 없습니다: /invalid/path

💡 해결 방법:
   1. 경로를 확인하세요
      예: ~/my-project (상대경로는 안됩니다)

   2. CMakeLists.txt가 있는 디렉토리인지 확인하세요
      $ ls /your/path/CMakeLists.txt

   3. 다시 시도하기:
      $ ./build.sh --project /correct/path

   4. 공식 예제로 시작하기:
      $ ./build.sh

❓ 도움이 필요하신가요? ./build.sh --help
```

### 5. Consistent Language (일관된 언어)

**원칙:**
- 같은 개념은 항상 같은 용어
- 사용자 용어 사용 (기술 용어 최소화)

**예시:**
- ✓ "프로젝트" (일관성)
- ✗ "소스 디렉토리", "SRC_DIR", "작업 공간" (혼란)

---

## 메시지 디자인 가이드

### 정보 메시지
```
✓ 빌드 성공!
📦 산출물 위치: ./out/
```
- 아이콘 사용
- 짧고 명확
- 긍정적 톤

### 에러 메시지
```
❌ 빌드 실패
💡 해결 방법:
   [구체적인 단계]
```
- 문제 명확히 설명
- 해결 방법 제시
- 다음 행동 안내

### 경고 메시지
```
⚠️  Docker가 실행되지 않았습니다
💡 Docker Desktop을 시작해주세요
```
- 심각도 표시
- 행동 요청
- 방법 안내

### 진행 메시지
```
[2/4] 📥 다운로드 중...
      ━━━━━━━━━━━━━━━━━━━━━━━ 65%
```
- 전체 단계 중 현재 위치
- 진행률 시각화
- 예상 시간 (가능하면)

---

## CLI 옵션 설계 (고급 사용자용)

### 기본 원칙
- 짧은 형태 없음 (혼란 방지)
- 자기 설명적 이름
- GNU 스타일

### 핵심 옵션
```bash
./build.sh [OPTIONS]

프로젝트 선택:
  --project PATH        프로젝트 디렉토리
  --official            공식 W55RP20-S2E 사용 (기본값)

산출물:
  --output PATH         산출물 디렉토리 (기본값: ./out)

빌드 옵션:
  --clean               정리 후 빌드
  --debug               디버그 빌드
  --jobs N              병렬 작업 수 (기본값: 자동)

편의 기능:
  --no-confirm          확인 없이 즉시 실행
  --quiet               최소 출력
  --verbose             상세 출력

설정 관리:
  --setup               설정 초기화 (다시 질문)
  --show-config         현재 설정 표시
  --save-config         현재 옵션을 기본값으로 저장

도움말:
  --help                도움말 표시
  --version             버전 정보
```

### 사용 예시
```bash
# 대화형 (초보자)
./build.sh

# 빠른 실행 (일반)
./build.sh --project ~/my-proj

# 자동화 (고급)
./build.sh --project ~/proj --no-confirm --quiet

# 설정 확인
./build.sh --show-config

# 설정 리셋
./build.sh --setup
```

---

## 설정 파일 설계 (.build-config)

### 목표
- 사용자가 읽고 이해 가능
- 수동 편집 가능
- 주석으로 설명

### 형식
```bash
# W55RP20 빌드 설정
# 이 파일을 직접 수정할 수 있습니다.
#
# 생성: 2026-01-16 16:30:00
# 마지막 사용: 2026-01-16 16:35:00

# 프로젝트 소스 디렉토리
# 예: /home/user/my-project
SRC_DIR="/home/user/projects/w55-sensor"

# 빌드 산출물 디렉토리
# 예: ./out, ~/builds
OUT_DIR="./out"

# 병렬 빌드 작업 수 (비워두면 자동)
# 예: 8, 16, 32
JOBS=""

# 빌드 타입 (Release 또는 Debug)
BUILD_TYPE="Release"

# tmpfs 크기 (비워두면 기본값 24g)
# 예: 8g, 16g, 48g
TMPFS_SIZE=""
```

### 특징
- 주석으로 설명
- 예시 포함
- 사람이 읽을 수 있는 형식
- Git에서 제외 (이미 .gitignore)

---

## 에러 복구 시나리오

### 시나리오 1: Docker가 없음

```
$ ./build.sh

❌ Docker가 설치되지 않았습니다

💡 해결 방법:

   Ubuntu/Debian:
   $ sudo apt-get update
   $ sudo apt-get install docker.io docker-compose

   macOS:
   1. Docker Desktop 다운로드
      → https://www.docker.com/products/docker-desktop
   2. 설치 후 실행

   Windows:
   1. Docker Desktop 다운로드
      → https://www.docker.com/products/docker-desktop
   2. WSL2 활성화 필요

   설치 후: ./build.sh 를 다시 실행하세요

❓ 더 자세한 도움말: ./build.sh --help
```

### 시나리오 2: Docker가 실행 안 됨

```
$ ./build.sh

❌ Docker가 실행되지 않았습니다

💡 해결 방법:

   Linux:
   $ sudo systemctl start docker

   macOS/Windows:
   Docker Desktop을 시작하세요
   (트레이에서 고래 아이콘 확인)

   그래도 안 되면:
   $ docker info  # 상태 확인

   준비되면: ./build.sh 를 다시 실행하세요
```

### 시나리오 3: 권한 문제

```
$ ./build.sh

❌ Docker 권한이 없습니다

💡 해결 방법:

   방법 1 - Docker 그룹 추가 (권장):
   $ sudo usermod -aG docker $USER

   ⚠️  로그아웃 후 다시 로그인 필요!

   방법 2 - sudo 사용 (임시):
   $ sudo ./build.sh

   검증:
   $ docker run hello-world
   (동작하면 OK)
```

### 시나리오 4: 잘못된 프로젝트 경로

```
$ ./build.sh --project /wrong/path

❌ 프로젝트를 찾을 수 없습니다: /wrong/path

💡 확인사항:

   1. 경로가 존재하나요?
      $ ls /wrong/path

   2. CMakeLists.txt가 있나요?
      $ ls /wrong/path/CMakeLists.txt

   3. 상대경로는 절대경로로 변환하세요:
      ✗ ../my-project
      ✓ /home/user/my-project

   다시 시도:
   $ ./build.sh --project /correct/path

   또는 대화형 모드:
   $ ./build.sh
```

---

## 성공 지표 (UX Metrics)

### 1. Time to First Success (첫 성공까지 시간)
- **목표:** < 5분 (완전 초보자)
- **측정:** 첫 `./build.sh` 실행 → 빌드 성공

### 2. Retry Rate (재시도율)
- **목표:** < 10%
- **측정:** 실패 후 재실행 비율

### 3. Help Requests (도움말 요청)
- **목표:** < 20%
- **측정:** `--help` 사용률

### 4. Configuration Errors (설정 오류)
- **목표:** < 5%
- **측정:** 잘못된 경로/옵션 입력

### 5. Setup Resets (설정 리셋)
- **목표:** < 15%
- **측정:** `--setup` 재실행 빈도

---

## 구현 우선순위

### Phase 1: MVP (Minimum Viable Product)
1. ✅ 대화형 프로젝트 선택 (공식/내 프로젝트)
2. ✅ 자동 클론 (./src/)
3. ✅ .build-config 저장/로드
4. ✅ 기본 진행 메시지

### Phase 2: Polish (다듬기)
5. 📊 진행률 바 (progress bar)
6. 🎨 아이콘과 색상
7. 💡 상황별 도움말
8. ⚠️  에러 복구 가이드

### Phase 3: Advanced (고급)
9. 🚀 `--no-confirm` 자동화 모드
10. 📋 `--show-config` 설정 확인
11. 🔄 `--setup` 설정 초기화
12. 📊 빌드 시간 표시

---

## 테스트 시나리오

### Test 1: 완전 초보자
```
조건: Docker 설치됨, 프로젝트 없음
실행: ./build.sh
기대: Enter만 눌러서 성공
시간: < 5분 (이미지 빌드 포함)
```

### Test 2: 잘못된 입력
```
조건: 잘못된 경로 입력
실행: ./build.sh --project /invalid
기대: 명확한 에러 + 해결 방법
재시도: 쉽게 가능
```

### Test 3: 재빌드
```
조건: 이미 빌드 완료
실행: ./build.sh
기대: 이전 설정 자동 사용, 즉시 시작
시간: < 5초 (빌드 시작까지)
```

### Test 4: 여러 프로젝트
```
조건: 프로젝트 A로 빌드 완료
실행: ./build.sh --project ~/project-B
기대: 설정 변경됨, B 빌드 성공
다음: ./build.sh → B 사용 (마지막 설정)
```

---

## 요약: UX 핵심

### 사용자 입장에서
```
초보자: "명령어 하나면 된다고? 정말 되네!"
개발자: "설정 기억해주네, 편하다!"
고급자: "스크립트로 제어 가능하네, 좋아!"
```

### 설계 핵심
1. **대화형이 기본**, CLI 옵션은 부가
2. **Enter만 눌러도** 합리적 결과
3. **실패해도** 쉽게 복구
4. **진행 상황** 명확히 표시
5. **도움말**은 필요한 시점에

### 다음 단계
이 UX 설계를 기반으로 실제 구현?
아니면 더 다듬을 부분이 있나요?
