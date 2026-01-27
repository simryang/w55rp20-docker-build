# W55RP20-S2E Docker Build System v1.1.0

WIZnet W55RP20-S2E Docker 빌드 시스템.

## 목차

- [빠른 시작](#빠른-시작)
- [요구사항](#요구사항)
- [주요 기능](#주요-기능)
- [상황별 사용법](#상황별-사용법)
- [폴더 구조](#폴더-구조)
- [문제 해결](#문제-해결)
- [고급 사용](#고급-사용)
- [성능 팁](#성능-팁)
- [문서](#문서)
- [개발자 가이드](#개발자-가이드)
- [자주 묻는 질문 (FAQ)](#자주-묻는-질문-faq)
- [문서 가이드](#-문서-가이드)
- [라이선스 & 기여](#라이선스--기여)
- [변경 이력](#변경-이력)

---

## 빠른 시작

```bash
# 1. 처음 사용 (대화형 설정)
./build.sh --setup

# 2. 또는 기본 빌드 (이미지 자동 빌드 + 소스 클론 + 빌드)
./build.sh

# 3. 산출물 확인
ls -l ./out/

# 빌드 로그는 build.log에 자동 저장됩니다
```

- **첫 실행:** 약 20~25분 (Docker 이미지 빌드 포함)
- **이후 빌드:** 약 2~3분 (이미지 재사용)

### v1.1.0 새로운 기능

- **대화형 모드**: `--setup`으로 입문자용 설정
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

### 자동화
- 이미지 없으면 자동 빌드
- 소스 없으면 자동 클론
- RAM 빌드 (빠름)
- 빌드 캐시 자동 활용 (ccache)

### 외부 리소스 업데이트
Docker 이미지는 한 번 받은 패키지와 SDK를 저장해서 재사용합니다.
보안 업데이트나 최신 버전이 필요할 때 특정 부분만 다시 받을 수 있습니다:

```bash
REFRESH="apt" ./build.sh         # apt 패키지 다시 설치
REFRESH="sdk" ./build.sh         # Pico SDK 최신 버전 받기
REFRESH="toolchain" ./build.sh   # CMake + GCC 다시 설치
REFRESH="all" ./build.sh         # 전체 다시 받기
```

### 로컬 설정 (선택)
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

외부 W55RP20 프로젝트를 빌드할 수 있습니다.

**준비:**
```bash
# 프로젝트 클론 (서브모듈 포함 필수!)
git clone --recurse-submodules https://github.com/yourname/your-w55rp20-project.git

# 서브모듈 확인
cd your-w55rp20-project
git submodule status
```

**빌드:**
```bash
# 기본
./build.sh --project ~/your-w55rp20-project

# 산출물 위치 지정
./build.sh --project ~/your-w55rp20-project --output ./my-output

# 자동 실행 (확인 없이)
./build.sh --project ~/your-w55rp20-project --no-confirm
```

**결과:**
```bash
# 산출물 확인
ls -lh ./out/
# App.uf2, Boot.uf2 등
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
├── build.sh              # 입문자용 실행 스크립트 (v1.1.0: CLI 옵션 지원)
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
└── docs/                 # 문서
```

---

## 문제 해결

### Docker 권한 오류

**빌드 시스템이 자동으로 진단 및 해결을 제안합니다.**

일반적인 경우:
```bash
# 빌드 실행 시 자동 진단
./build.sh

# 진단 결과에 따라 자동 해결 제안
# "자동으로 해결하시겠습니까? [Y/n]" 표시됨
```

수동 해결:
```bash
# docker 그룹 생성 (없는 경우)
sudo groupadd docker

# 사용자 추가
sudo usermod -aG docker $USER

# 적용 (아래 중 하나)
newgrp docker              # 현재 터미널에 즉시 적용
# 또는 완전 로그아웃 후 재로그인
# 또는 시스템 재부팅
```

**⚠️ Docker 재설치 시 주의 (docker.io → docker-ce 전환)**

`docker.io`를 제거하고 `docker-ce`를 설치한 경우:
- docker 그룹이 삭제될 수 있음
- 빌드 시스템이 자동으로 감지하고 해결 제안
- **여러 번의 재시도가 필요할 수 있음** (정상)
  - newgrp docker 재실행
  - 재로그인 1~2회
  - 시스템 재부팅

원인: systemd-logind와 NSS 그룹 캐싱
이는 시스템 동작이며, 재시도하면 해결됩니다.

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

### 서브모듈 미초기화 오류
```bash
# 증상: "Directory does not contain..." 또는 "No such file or directory"
# 원인: git clone 시 --recursive 옵션 누락

# 해결:
cd [소스 디렉토리]
git submodule update --init --recursive
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

- **[BEGINNER_GUIDE.md](docs/BEGINNER_GUIDE.md)** - Docker 입문 가이드
  - Docker 개념 설명
  - 단계별 빌드 가이드
  - 문제 해결 체크리스트
  - 프로젝트 빌드 방법

- **[USER_GUIDE.md](docs/USER_GUIDE.md)** - 사용 설명서
  - Docker 직접 사용법
  - build.sh 옵션
  - 스크립트 구조

### 개발자 문서

- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - 내부 구조 문서
  - 아키텍처 다이어그램
  - 실행 흐름 분석
  - Docker 레이어 구조
  - 변수 전파 메커니즘
  - 캐시 전략 (Docker + ccache)
  - 커스터마이징 가이드
  - 디버깅 가이드
  - 기여 가이드

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

### 코드 수정 시
1. 변경 전 `VERBOSE=1` 테스트
2. 테스트 스위트 실행
3. Git 커밋 (상세한 메시지)

---

## 자주 묻는 질문 (FAQ)

### Q1: 첫 실행이 너무 오래 걸려요 (20분+)
**A:** 정상입니다! 첫 실행 시 Docker 이미지를 빌드합니다.
- Ubuntu 다운로드 (500MB)
- ARM GCC 컴파일러 설치 (300MB)
- Pico SDK 다운로드 (200MB)
- 총 약 20~25분 소요

기다리면 됩니다. 이후 빌드는 2~3분만 소요됩니다.

### Q2: 이미지 빌드를 건너뛸 수 있나요?
**A:** 없습니다. Docker 이미지는 필수입니다.
하지만 한 번 만들어진 이미지는 계속 재사용되므로, 다음 빌드부터는 빠릅니다.

### Q3: 매번 `./build.sh`를 실행해야 하나요?
**A:** 아니요! `--setup`으로 설정을 저장하면:
```bash
./build.sh --setup          # 초기 설정
./build.sh                   # 이후 실행
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
- 시스템 오염 없음 (설치 파일들이 컨테이너 안에만)
- 버전 고정 (ARM GCC 14.2, CMake 3.28.3 등)
- 이식성 (어떤 Linux에서나 동일하게 동작)

### Q6: `build.sh`와 Docker 이미지의 관계는?
**A:**
- `build.sh`: 사용자가 실행하는 스크립트 (git에 있음)
- Docker 이미지: 빌드 도구들이 설치된 환경 (로컬에 생성됨)

```
git clone → build.sh 받음
./build.sh → Docker 이미지 빌드 (초기에만)
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
- 권한 문제: `sudo usermod -aG docker $USER` 후 `newgrp docker` 실행
- 메모리 부족: `--jobs 4` 옵션 사용

### Q10: 설정을 초기화하고 싶어요
**A:** `.build-config` 파일을 삭제하고 다시 설정하세요.
```bash
rm .build-config
./build.sh --setup
```

### Q11: docker.io를 docker-ce로 바꿨는데 권한 오류가 계속 나요
**A:** docker.io → docker-ce 전환 시 docker 그룹이 삭제되는 알려진 문제입니다.

빌드 시스템이 자동으로 감지하고 해결을 제안합니다:
```bash
./build.sh
# "자동으로 해결하시겠습니까?" 메시지 확인
```

**여러 번 재시도가 필요할 수 있습니다** (정상):
1. 자동 해결 실행
2. newgrp docker 또는 재로그인
3. 안되면 다시 재로그인
4. 여전히 안되면 시스템 재부팅

원인: systemd와 NSS의 그룹 정보 캐싱
이 빌드 환경 제작자도 동일한 상황을 겪었고, 여러 번의 재시도 끝에 해결했습니다.

---

## 문서 가이드

### 어떤 문서를 읽어야 할까요?

```
시작 단계에 따라 선택하세요:
```

#### 입문자 (Docker를 처음 사용)
```
1. BEGINNER_GUIDE.md  ← 시작 지점
   ↓
2. 설치 가이드 (플랫폼별)
   - INSTALL_LINUX.md
   - INSTALL_MAC.md
   - INSTALL_WINDOWS.md
   - INSTALL_RASPBERRY_PI.md
   ↓
3. README.md (이 파일)
   ↓
4. QUICKREF.md (치트시트)
```

#### 일반 사용자 (빌드 시스템 사용)
```
1. QUICKREF.md        ← 빠른 참조
   ↓
2. USER_GUIDE.md      ← 상세 매뉴얼
   ↓
3. EXAMPLES.md        ← 실전 예제
```

#### 문제 발생 시
```
1. TROUBLESHOOTING.md ← 에러 해결
   ↓
2. BUILD_LOGS.md      ← 정상 로그 비교
   ↓
3. GLOSSARY.md        ← 용어 확인
```

####  개발자 (내부 구조 이해)
```
ARCHITECTURE.md       ← 내부 구조
```

---

### 전체 문서 목록

#### 사용자 문서
| 문서 | 설명 | 대상 |
|------|------|------|
| **[README.md](README.md)** | 프로젝트 개요 및 빠른 시작 | 모든 사용자 |
| **[QUICKREF.md](docs/QUICKREF.md)** | 1페이지 치트시트 | 일반 사용자 |
| **[BEGINNER_GUIDE.md](docs/BEGINNER_GUIDE.md)** | 입문자 가이드  | 초보자 |
| **[USER_GUIDE.md](docs/USER_GUIDE.md)** | 상세 사용 설명서  | 일반 사용자 |

#### 실전 가이드
| 문서 | 설명 |
|------|------|
| **[BUILD_LOGS.md](docs/BUILD_LOGS.md)** | 실제 빌드 로그 예제 |
| **[EXAMPLES.md](docs/EXAMPLES.md)** | 5가지 실전 예제 |
| **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** | 40+ 에러 해결 가이드 |

#### 플랫폼별 설치
| 문서 | 플랫폼 |
|------|--------|
| **[INSTALL_LINUX.md](docs/INSTALL_LINUX.md)** | Ubuntu, Debian, Fedora, Arch |
| **[INSTALL_MAC.md](docs/INSTALL_MAC.md)** | macOS (Intel/Apple Silicon) |
| **[INSTALL_WINDOWS.md](docs/INSTALL_WINDOWS.md)** | Windows 10/11 (WSL2) |
| **[INSTALL_RASPBERRY_PI.md](docs/INSTALL_RASPBERRY_PI.md)** | Raspberry Pi 3/4/5 |

#### 개발자 문서
| 문서 | 설명 |
|------|------|
| **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** | 내부 아키텍처  |

#### 참고 자료
| 문서 | 설명 |
|------|------|
| **[GLOSSARY.md](docs/GLOSSARY.md)** | 100+ 용어 사전 |
| **[CHANGELOG.md](docs/CHANGELOG.md)** | 버전별 변경 이력 |

---

###  문서 검색 팁

**목적별 빠른 찾기**:
- 처음 사용: [BEGINNER_GUIDE.md](docs/BEGINNER_GUIDE.md)
- 빠른 참조: [QUICKREF.md](docs/QUICKREF.md)
- 에러 해결: [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- 예제 필요: [EXAMPLES.md](docs/EXAMPLES.md)
- 용어 모름: [GLOSSARY.md](docs/GLOSSARY.md)
- 설치 문제: [INSTALL_*.md](docs/INSTALL_LINUX.md)
- 내부 구조: [ARCHITECTURE.md](docs/ARCHITECTURE.md)

**키워드별 검색**:
```bash
# 모든 문서에서 검색
grep -r "키워드" *.md

# 특정 문서에서 검색
grep "키워드" TROUBLESHOOTING.md
```

---

## 라이선스 & 기여

프로젝트 소스: https://github.com/WIZnet-ioNIC/W55RP20-S2E

### 기여 방법
1. 이슈 리포트: [GitHub Issues](https://github.com/WIZnet-ioNIC/W55RP20-S2E/issues)
2. Pull Request 환영
3. 문서 개선 제안

---

## 변경 이력

**최신**: v1.2.0 (2026-01-21) - 문서 시스템 완성

자세한 변경 사항: [CHANGELOG.md](docs/CHANGELOG.md)
