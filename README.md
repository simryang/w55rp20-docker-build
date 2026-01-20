# W55RP20-S2E Docker Build System v1.1.0

Raspberry Pi Pico 기반 W55RP20 마이크로컨트롤러용 Docker 빌드 환경.

## 빠른 시작

```bash
# 1. 처음 사용 (대화형 설정)
./build.sh --setup

# 2. 또는 기본 빌드 (이미지 자동 빌드 + 소스 클론 + 빌드)
./build.sh

# 3. 산출물 확인
ls -l ./out/
```

끝! 이게 전부입니다.

**⏱️ 소요 시간:**
- **첫 실행:** 약 20~25분 (Docker 이미지 빌드 포함)
- **이후 빌드:** 약 2~3분 (이미지 재사용)

### v1.1.0 새로운 기능

- **대화형 모드**: `--setup`으로 초보자 친화적 설정
- **CLI 옵션**: `--project`, `--output`, `--clean` 등 명령줄 옵션 지원
- **자동 설정 저장**: `.build-config`로 설정 자동 저장/로드
- **진행 상태 표시**: 빌드 전/후 상태 및 산출물 정보 표시
- **도움말**: `--help`, `--version` 명령 지원

---

## 요구사항

- **Docker** (필수)
- **Git** (필수)
- **16GB+ RAM** 권장 (tmpfs 빌드)
- **Linux** (Ubuntu 20.04+, Debian 등)

---

## 주요 기능

### ✨ 자동화
- 이미지 없으면 자동 빌드
- 소스 없으면 자동 클론
- RAM 빌드 (빠름)
- ccache 지원

### 🎯 선택적 캐시 무효화 (REFRESH)
외부 리소스 업데이트 시:

```bash
REFRESH="apt" ./build.sh         # apt 패키지 업데이트
REFRESH="sdk" ./build.sh         # Pico SDK 재다운로드
REFRESH="toolchain" ./build.sh   # CMake + GCC 재설치
REFRESH="all" ./build.sh         # 전체 재빌드
```

### ⚙️ 로컬 설정 (선택)
고성능/저사양 환경 맞춤:

```bash
cp build.config.example build.config
vim build.config  # JOBS, TMPFS_SIZE 조정
./build.sh        # 설정 자동 로드
```

---

## 상황별 사용법

### CLI 옵션 사용 (v1.1.0 권장)

#### 기본 빌드
```bash
./build.sh                        # 공식 예제 빌드
```

#### 대화형 설정
```bash
./build.sh --setup                # 프로젝트/산출물 경로 대화형 설정
```

#### 사용자 프로젝트 빌드
```bash
./build.sh --project ~/my-w55rp20-project
./build.sh --project ~/my-project --output ./artifacts
```

#### 빌드 옵션
```bash
./build.sh --clean                # 정리 후 빌드
./build.sh --debug                # 디버그 빌드
./build.sh --jobs 8               # 병렬 작업 8개
./build.sh --refresh sdk          # SDK 재다운로드 후 빌드
```

#### 자동화 (CI/CD)
```bash
./build.sh --project ~/proj --no-confirm --quiet
```

#### 도움말
```bash
./build.sh --help                 # 전체 옵션 보기
./build.sh --version              # 버전 정보
./build.sh --show-config          # 현재 설정 확인
```

### 환경 변수 사용 (레거시 방식)

#### 산출물 정리 후 빌드
```bash
CLEAN=1 ./build.sh
```

#### 소스 코드 최신으로 갱신
```bash
UPDATE_REPO=1 ./build.sh
```

#### 특정 브랜치/태그 빌드
```bash
REPO_REF=v1.2.3 ./build.sh
```

#### 저사양 환경 (라즈베리파이 등)
```bash
JOBS=4 TMPFS_SIZE=2g ./build.sh
```

#### 디버깅 (상세 출력)
```bash
VERBOSE=1 ./build.sh
```

**참고**: CLI 옵션과 환경 변수를 함께 사용 가능합니다.
우선순위: **CLI 옵션 > 환경 변수 > .build-config > build.config > 기본값**

---

## 폴더 구조

```
.
├── build.sh              # 초보자용 실행 스크립트 (v1.1.0: CLI 옵션 지원)
├── w55build.sh           # 고급 사용자용 (상세 제어)
├── docker-build.sh       # 컨테이너 내부 빌드 로직
├── Dockerfile            # 빌드 환경 정의
├── entrypoint.sh         # 컨테이너 진입점
├── .build-config         # 자동 생성 설정 (gitignore)
├── build.config.example  # 사용자 설정 예시
├── out/                  # 빌드 산출물 (gitignore)
├── tests/                # 테스트 스위트
│   ├── test-cli-options.sh
│   ├── test-build-config.sh
│   ├── test-interactive-mode.sh
│   ├── test-progress-display.sh
│   └── test-integration.sh
└── claude/               # AI 협업 문서 (개발자용)
    ├── README.md
    ├── UX_DESIGN.md
    ├── ADVANCED_OPTIONS.md
    └── ...
```

---

## 문제 해결

### Docker 권한 오류
```bash
# 방법 1: sudo 없이 docker 실행 (권장)
sudo usermod -aG docker $USER
# 로그아웃 후 재로그인

# 방법 2: 임시 (매번 sudo 필요)
# 코드는 이미 sudo 포함
```

### 디스크 공간 부족
```bash
# Docker 정리
sudo docker system prune -a

# ccache 정리
rm -rf ~/.ccache-w55rp20/*
```

### 메모리 부족
```bash
# tmpfs 크기 줄이기
TMPFS_SIZE=8g ./build.sh
```

### 빌드 실패 시
```bash
# 상세 로그 확인
VERBOSE=1 ./build.sh

# 완전 재빌드
sudo docker buildx build --no-cache -t w55rp20:auto --load .
CLEAN=1 ./build.sh
```

---

## 고급 사용

### w55build.sh 직접 사용
```bash
# 모든 변수 직접 지정
IMAGE=custom:tag \
JOBS=32 \
TMPFS_SIZE=48g \
AUTO_BUILD_IMAGE=0 \
./w55build.sh
```

### 컨테이너 내부 진입
```bash
sudo docker run --rm -it --entrypoint bash w55rp20:auto
```

### 산출물 위치 변경
```bash
OUT_DIR=/path/to/output ./w55build.sh
```

---

## 성능 팁

### 1. ccache 활용
자동 활성화됨. 두 번째 빌드부터 빠름.

### 2. 병렬도 조정
```bash
# CPU 코어 수 확인
nproc

# 코어 수만큼 설정
JOBS=$(nproc) ./build.sh
```

### 3. tmpfs 크기 최적화
```bash
# 메모리 확인
free -h

# 메모리의 50% 정도 권장
TMPFS_SIZE=24g ./build.sh  # 48GB RAM 시스템
```

---

## 문서

### 사용자 문서

- **[BEGINNER_GUIDE.md](BEGINNER_GUIDE.md)** - 🌟 Docker 처음이라면 여기부터! 🌟
  - Docker 개념 설명 (비유와 그림으로)
  - 완전 초보자 단계별 가이드
  - 문제 해결 체크리스트
  - 내 프로젝트 빌드하기

- **[USER_GUIDE.md](USER_GUIDE.md)** - 상세 사용 설명서 (840줄)
  - Docker 직접 사용법
  - build.sh 상세 옵션
  - 스크립트 아키텍처

### 개발자 문서

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - 🔧 내부를 파고들고 싶다면! 🔧
  - 전체 아키텍처 다이어그램
  - 스크립트 실행 흐름 상세 분석
  - Docker 레이어 구조
  - 변수 전파 메커니즘
  - 캐시 전략 (Docker + ccache)
  - 확장/커스터마이징 가이드
  - 디버깅 가이드
  - 기여 가이드

- **[claude/ADVANCED_OPTIONS.md](claude/ADVANCED_OPTIONS.md)** - 고급 옵션 전체 설명
  - 모든 CLI 옵션 상세 설명
  - 실제 사용 시나리오 (CI/CD, 멀티 프로젝트 등)
  - 옵션 우선순위 및 충돌 처리

- **[claude/UX_DESIGN.md](claude/UX_DESIGN.md)** - UX 설계 문서
  - 3가지 사용자 페르소나 (초보자/개발자/고급)
  - 대화형 플로우 설계
  - UX 원칙 및 성공 지표

---

## 개발자 가이드

### 테스트
```bash
# 전체 테스트 실행
./tests/test-cli-options.sh
./tests/test-build-config.sh
./tests/test-interactive-mode.sh
./tests/test-progress-display.sh
./tests/test-integration.sh
```

### AI 협업
- `claude/README.md` - 빠른 컨텍스트
- `claude/DESIGN.md` - 설계 결정
- `claude/GPT_INSTRUCTIONS.md` - GPT/Gemini 가이드

### 코드 수정 시
1. 변경 전 `VERBOSE=1` 테스트
2. 테스트 스위트 실행
3. Git 커밋 (상세한 메시지)
4. `claude/` 문서 업데이트 (필요 시)

---

## 자주 묻는 질문 (FAQ)

### Q1: 첫 실행이 너무 오래 걸려요 (20분+)
**A:** 정상입니다! 첫 실행 시 Docker 이미지를 빌드합니다.
- Ubuntu 다운로드 (500MB)
- ARM GCC 컴파일러 설치 (300MB)
- Pico SDK 다운로드 (200MB)
- 총 약 20~25분 소요

**한 번만** 기다리면 됩니다. 이후 빌드는 2~3분만 소요됩니다.

### Q2: 이미지 빌드를 건너뛸 수 있나요?
**A:** 없습니다. Docker 이미지는 필수입니다.
하지만 한 번 만들어진 이미지는 계속 재사용되므로, 다음 빌드부터는 빠릅니다.

### Q3: 매번 `./build.sh`를 실행해야 하나요?
**A:** 아니요! `--setup`으로 설정을 저장하면:
```bash
./build.sh --setup          # 한 번만 설정
./build.sh                   # 이후 간단하게
```
`.build-config`에 설정이 저장되어 자동으로 로드됩니다.

### Q4: 빌드 결과물은 어디에 있나요?
**A:** `./out/` 디렉토리에 생성됩니다.
```bash
ls -l ./out/
# App.uf2, Boot.uf2 등의 파일 확인
```

### Q5: Docker가 뭔가요? 왜 필요한가요?
**A:** Docker는 "격리된 빌드 환경"을 제공합니다.
- ✅ 시스템 오염 없음 (설치 파일들이 컨테이너 안에만)
- ✅ 버전 고정 (ARM GCC 14.2, CMake 3.28.3 등)
- ✅ 이식성 (어떤 Linux에서나 동일하게 동작)

### Q6: `build.sh`와 Docker 이미지의 관계는?
**A:**
- `build.sh`: 사용자가 실행하는 스크립트 (git에 있음)
- Docker 이미지: 빌드 도구들이 설치된 환경 (로컬에 생성됨)

```
git clone → build.sh 받음
./build.sh → Docker 이미지 빌드 (한 번만)
./build.sh → 이미지 사용해서 빌드 (계속 재사용)
```

### Q7: 여러 프로젝트를 빌드할 수 있나요?
**A:** 네! `--project` 옵션을 사용하세요.
```bash
./build.sh --project ~/project-A
./build.sh --project ~/project-B
./build.sh --project ~/project-C
```

### Q8: Windows에서도 사용할 수 있나요?
**A:** WSL (Windows Subsystem for Linux) 또는 Git Bash에서 가능합니다.
```bash
# WSL에서
wsl
./build.sh

# Git Bash에서
bash build.sh
```

### Q9: 빌드가 실패해요!
**A:** 상세 로그를 확인하세요:
```bash
./build.sh --verbose
```

자주 발생하는 문제:
- Docker 미실행: `sudo systemctl start docker`
- 권한 문제: `sudo usermod -aG docker $USER` (재로그인 필요)
- 메모리 부족: `--jobs 4` 옵션 사용

### Q10: 설정을 초기화하고 싶어요
**A:** `.build-config` 파일을 삭제하고 다시 설정하세요.
```bash
rm .build-config
./build.sh --setup
```

---

## 라이선스 & 기여

프로젝트 소스: https://github.com/WIZnet-ioNIC/W55RP20-S2E

---

## 변경 이력

최근 개선사항은 `git log` 참조
