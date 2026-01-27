# W55RP20 빌드 시스템 입문 가이드

> Docker 경험이 없어도 괜찮습니다. 이 가이드로 W55RP20 펌웨어를 빌드할 수 있습니다.

## 목차

1. [Docker가 뭔가요? 왜 필요한가요?](#1-docker가-뭔가요-왜-필요한가요)
2. [사전 준비사항](#2-사전-준비사항)
3. [첫 빌드 (완전 처음부터)](#3-첫-빌드-완전-처음부터)
4. [무슨 일이 일어나는지 이해하기](#4-무슨-일이-일어나는지-이해하기)
5. [자주 발생하는 문제와 해결법](#5-자주-발생하는-문제와-해결법)
6. [이제 내 프로젝트 빌드하기](#6-이제-내-프로젝트-빌드하기)
7. [고급 기능 사용하기](#7-고급-기능-사용하기)
8. [개념 정리](#8-개념-정리)

---

## 1. Docker가 뭔가요? 왜 필요한가요?

### 비유로 이해하기

Docker는 **"이사갈 때 쓰는 컨테이너 박스"**와 비슷합니다.

**Docker 없이 빌드한다면:**
```
내 컴퓨터에 직접 설치:
├── ARM GCC 컴파일러 (300MB)
├── CMake 빌드 도구
├── Pico SDK (200MB)
├── Python 라이브러리들
└── 기타 의존성 패키지들 (100개+)

문제점:
 내 시스템이 "오염"됨
 다른 프로젝트와 버전 충돌 가능
 삭제하기 어려움
 다른 컴퓨터에서 재현 불가능
```

**Docker로 빌드한다면:**
```
Docker 컨테이너 안에만 설치:
┌─────────────────────────────┐
│ 격리된 빌드 환경 (컨테이너) │
├─────────────────────────────┤
│ ARM GCC 컴파일러         │
│ CMake 빌드 도구          │
│ Pico SDK                 │
│ Python 라이브러리들      │
└─────────────────────────────┘
        ↓
   내 컴퓨터는 깨끗

장점:
내 시스템 오염 없음
버전 충돌 없음
필요 없으면 이미지만 삭제
어디서나 동일하게 동작
```

### 실제 동작 방식

1. **Docker 이미지**: 빌드 도구들이 설치된 "템플릿"
2. **Docker 컨테이너**: 이미지를 실행한 "실제 환경"
3. **build.sh**: 이미지를 만들고 컨테이너를 실행하는 "자동화 스크립트"

```
┌──────────────┐
│  build.sh    │ ← 사용자가 실행
└──────┬───────┘
       ↓
┌──────────────┐
│ Docker 이미지 │ ← 첫 실행 시 자동 생성 (20분)
│ (템플릿)      │   이후에는 재사용 (0분)
└──────┬───────┘
       ↓
┌──────────────┐
│Docker 컨테이너│ ← 실제 빌드 실행 (2~3분)
└──────┬───────┘
       ↓
┌──────────────┐
│ out/ 폴더    │ ← 빌드 결과물 (.uf2 파일)
└──────────────┘
```

---

## 2. 사전 준비사항

### 2.1 시스템 요구사항

**최소 요구사항:**
- Linux (Ubuntu 20.04+, Debian, Fedora 등)
- RAM: 8GB 이상
- 디스크: 10GB 여유 공간
- 인터넷 연결 (첫 실행 시)

**권장 사양:**
- RAM: 16GB 이상
- SSD 저장장치
- 멀티코어 CPU (빌드 속도 향상)

### 2.2 Docker 설치 확인

터미널을 열고 다음 명령어를 실행하세요:

```bash
docker --version
```

**성공하면:**
```
Docker version 24.0.7, build afdd53b
```
이런 메시지가 나옵니다. → **Docker가 설치되어 있습니다!**

**실패하면:**
```
bash: docker: command not found
```
이런 메시지가 나옵니다. → **Docker를 설치해야 합니다.**

#### Docker 설치 방법 (Ubuntu/Debian)

```bash
# 1. 기존 Docker 제거 (있다면)
sudo apt remove docker docker-engine docker.io containerd runc

# 2. Docker 공식 저장소 추가
sudo apt update
sudo apt install ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 3. Docker 설치
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 4. Docker 서비스 시작
sudo systemctl start docker
sudo systemctl enable docker

# 5. sudo 없이 Docker 사용 (선택사항, 권장)
sudo usermod -aG docker $USER

# 6. 로그아웃 후 재로그인 (usermod 적용)
# 또는 현재 세션에서만: newgrp docker

# 7. 설치 확인
docker run hello-world
```

**"Hello from Docker!"** 메시지가 나오면 성공!

### 2.3 Git 설치 확인

```bash
git --version
```

**없다면 설치:**
```bash
sudo apt install git
```

---

## 3. 첫 빌드 (완전 처음부터)

### 3.1 프로젝트 다운로드

```bash
# 원하는 위치로 이동 (예: 홈 디렉토리)
cd ~

# 프로젝트 클론
git clone https://github.com/WIZnet-ioNIC/W55RP20-S2E.git
cd W55RP20-S2E

# 또는 이 빌드 시스템만 클론한다면:
# git clone <your-repo-url>
# cd <your-repo-directory>
```

### 3.2 대화형 설정 (초보자 권장)

```bash
./build.sh --setup
```

**화면에 나타나는 것:**
```
╔════════════════════════════════════════════╗
║   W55RP20 빌드 시스템 대화형 설정 v1.1.0  ║
╚════════════════════════════════════════════╝

어떤 프로젝트를 빌드하시겠습니까?

1) 공식 W55RP20-S2E 예제 빌드 (기본값)
2) 내가 만든 W55RP20 프로젝트 빌드

선택 [1/2]:
```

**처음이라면 `1`을 선택하세요.**

그 다음:
```
빌드 산출물을 어디에 저장하시겠습니까?
기본값: /home/your-username/W55RP20-S2E/out

경로를 입력하세요 (기본값 사용하려면 Enter):
```

**그냥 Enter를 누르세요** (기본값 사용).

마지막 확인:
```
다음 설정으로 진행하시겠습니까?

프로젝트:    ./src (공식 예제)
산출물 위치: ./out
빌드 타입:   Release
병렬 작업:   8

설정을 저장하고 빌드를 시작하시겠습니까? [y/N]:
```

**`y`를 입력하고 Enter를 누르세요.**

### 3.3 첫 빌드 실행

이제 **20~25분** 기다려야 합니다. 왜냐하면:

```
[1/6] Docker 이미지 빌드 중...        (~15분)
  - Ubuntu 다운로드 (500MB)
  - ARM GCC 설치 (300MB)
  - Pico SDK 다운로드 (200MB)
  - 기타 도구 설치

[2/6] 소스 코드 클론 중...             (~2분)
  - GitHub에서 소스 다운로드

[3/6] CMake 설정 중...                 (~1분)
  - 빌드 설정 생성

[4/6] 펌웨어 빌드 중...                (~2~3분)
  - 실제 컴파일 작업

[5/6] 산출물 복사 중...                (~10초)
  - .uf2 파일 생성

[6/6] 완료!
```

**커피 한 잔 하고 오세요!** 

### 3.4 빌드 성공 확인

빌드가 끝나면:

```bash
ls -l ./out/
```

**다음과 같은 파일들이 보입니다:**
```
-rw-r--r-- 1 user user 524288 Jan 20 10:30 App.uf2
-rw-r--r-- 1 user user 131072 Jan 20 10:30 Boot.uf2
```

**축하합니다!** 첫 빌드 성공!

---

## 4. 무슨 일이 일어나는지 이해하기

### 4.1 디렉토리 구조 확인

빌드 후 프로젝트 구조:

```
W55RP20-S2E/
├── build.sh           ← 여러분이 실행한 스크립트
├── w55build.sh        ← 내부에서 호출되는 스크립트
├── Dockerfile         ← Docker 이미지 레시피
├── .build-config      ← 저장된 설정 (자동 생성됨)
├── src/               ← 소스 코드 (자동 클론됨)
│   ├── App/
│   ├── Boot/
│   └── CMakeLists.txt
└── out/               ← 빌드 결과물
    ├── App.uf2
    └── Boot.uf2
```

### 4.2 .uf2 파일이란?

**UF2 (USB Flashing Format)**는 마이크로컨트롤러에 펌웨어를 업로드하는 파일 형식입니다.

**사용 방법:**
1. W55RP20 보드를 BOOTSEL 모드로 연결
2. USB 드라이브처럼 인식됨
3. `.uf2` 파일을 드래그 앤 드롭
4. 자동으로 펌웨어 업로드 및 재부팅

### 4.3 두 번째 빌드는 왜 빠른가요?

**첫 빌드:**
```
Docker 이미지 생성: 15분 (GCC, SDK 등 다운로드/설치)
+ 소스 빌드: 3분
= 총 18~25분
```

**두 번째 빌드 이후:**
```
Docker 이미지 재사용: 0분 (이미 있음!)
+ 소스 빌드: 2~3분 (ccache 덕분에 더 빠름)
= 총 2~3분
```

Docker 이미지는 한 번 만들어지면 계속 재사용됩니다!

---

## 5. 자주 발생하는 문제와 해결법

### 5.1 권한 오류

**문제:**
```
Got permission denied while trying to connect to the Docker daemon socket
```

**원인:** Docker를 사용할 권한이 없습니다.

**해결책 1 (권장):**
```bash
# Docker 그룹에 사용자 추가
sudo usermod -aG docker $USER

# 로그아웃 후 재로그인
# 또는:
newgrp docker

# 확인
docker ps
```

**해결책 2 (임시):**
```bash
# 매번 sudo 사용
sudo ./build.sh
```

### 5.2 Docker 서비스 미실행

**문제:**
```
Cannot connect to the Docker daemon. Is the docker daemon running?
```

**해결책:**
```bash
# Docker 서비스 시작
sudo systemctl start docker

# 부팅 시 자동 시작 설정
sudo systemctl enable docker

# 상태 확인
sudo systemctl status docker
```

### 5.3 디스크 공간 부족

**문제:**
```
no space left on device
```

**해결책:**
```bash
# 사용하지 않는 Docker 이미지/컨테이너 정리
docker system prune -a

# 확인 프롬프트가 나오면 'y' 입력

# ccache 정리 (필요 시)
rm -rf ~/.ccache-w55rp20/*
```

**공간 확인:**
```bash
df -h
docker system df
```

### 5.4 메모리 부족

**문제:**
빌드 중 시스템이 느려지거나 멈춤

**해결책:**
```bash
# 병렬 작업 수 줄이기
./build.sh --jobs 4

# tmpfs 크기 줄이기
TMPFS_SIZE=4g ./build.sh
```

### 5.5 빌드 실패

**문제:**
```
Build failed with exit code 2
```

**해결책:**

**1단계: 상세 로그 확인**
```bash
./build.sh --verbose
```

**2단계: 완전 재빌드**
```bash
./build.sh --clean --refresh all
```

**3단계: Docker 이미지 재생성**
```bash
docker rmi w55rp20:auto
./build.sh
```

### 5.6 소스 코드 업데이트 오류

**문제:**
```
fatal: detected dubious ownership in repository
```

**해결책:**
```bash
# src/ 디렉토리 삭제 후 재클론
rm -rf src/
./build.sh
```

또는:
```bash
# Git 설정 추가
git config --global --add safe.directory /workspace
```

---

## 6. 이제 내 프로젝트 빌드하기

### 6.1 내 프로젝트 준비하기

**프로젝트 구조 확인:**
```
my-w55rp20-project/
├── CMakeLists.txt    ← 필수!
├── main.c
├── config.h
└── ...
```

**중요:** `CMakeLists.txt` 파일이 필요합니다.

### 6.2 대화형 모드로 설정

```bash
cd /path/to/W55RP20-S2E  # 빌드 시스템 위치
./build.sh --setup
```

**선택:**
```
어떤 프로젝트를 빌드하시겠습니까?

1) 공식 W55RP20-S2E 예제 빌드 (기본값)
2) 내가 만든 W55RP20 프로젝트 빌드

선택 [1/2]: 2  ← 여기서 2 선택
```

**프로젝트 경로 입력:**
```
프로젝트 디렉토리 경로를 입력하세요:
/home/user/my-w55rp20-project  ← 내 프로젝트 경로
```

스크립트가 자동으로 검증:
```
 디렉토리 존재 확인
 CMakeLists.txt 확인
```

**설정 저장 후 빌드:**
```
설정을 저장하고 빌드를 시작하시겠습니까? [y/N]: y
```

### 6.3 CLI로 직접 지정

설정 저장 없이 바로 빌드:

```bash
./build.sh --project ~/my-w55rp20-project
```

특정 산출물 위치:

```bash
./build.sh --project ~/my-project --output ~/artifacts
```

### 6.4 여러 프로젝트 빌드하기

**방법 1: 반복 실행**
```bash
./build.sh --project ~/project-A
./build.sh --project ~/project-B
./build.sh --project ~/project-C
```

**방법 2: 자동화 스크립트**
```bash
#!/bin/bash
PROJECTS=(
  ~/project-A
  ~/project-B
  ~/project-C
)

for proj in "${PROJECTS[@]}"; do
  echo "Building $proj..."
  ./build.sh --project "$proj" --no-confirm --quiet
done
```

---

## 7. 고급 기능 사용하기

### 7.1 디버그 빌드

릴리스 빌드 (기본값):
- 최적화됨
- 디버그 심볼 없음
- 작은 크기

디버그 빌드:
```bash
./build.sh --debug
```

차이점:
- 최적화 안 됨 (`-O0`)
- 디버그 심볼 포함 (`-g`)
- 큰 크기
- GDB 디버깅 가능

### 7.2 선택적 캐시 무효화

**문제 상황:**
- Pico SDK 최신 버전 필요
- ARM GCC 버전 변경
- apt 패키지 업데이트

**해결책:**
```bash
# SDK만 재다운로드
./build.sh --refresh sdk

# 컴파일러만 재설치
./build.sh --refresh gcc

# CMake만 재설치
./build.sh --refresh cmake

# 툴체인 전체 (cmake + gcc)
./build.sh --refresh toolchain

# 시스템 패키지만
./build.sh --refresh apt

# 전부 다
./build.sh --refresh all
```

### 7.3 빌드 정리

**소스는 유지, 빌드 산출물만 삭제:**
```bash
./build.sh --clean
```

**처음부터 시작:**
```bash
rm -rf src/ out/ .build-config
./build.sh
```

### 7.4 설정 관리

**현재 설정 확인:**
```bash
./build.sh --show-config
```

**설정 변경 후 저장:**
```bash
./build.sh --project ~/new-project --jobs 16 --save-config
```

**설정 초기화:**
```bash
rm .build-config
./build.sh --setup
```

### 7.5 CI/CD 통합

**GitHub Actions 예시:**
```yaml
name: Build W55RP20

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build firmware
        run: |
          ./build.sh --project ./my-project --no-confirm --quiet

      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: firmware
          path: out/*.uf2
```

**Jenkins 예시:**
```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh './build.sh --project ./firmware --no-confirm'
            }
        }
        stage('Archive') {
            steps {
                archiveArtifacts artifacts: 'out/*.uf2'
            }
        }
    }
}
```

---

## 8. 개념 정리

### 8.1 주요 파일 역할

| 파일 | 역할 | 수정 가능? |
|------|------|-----------|
| `build.sh` | 초보자용 래퍼 스크립트 | (고급 사용자) |
| `w55build.sh` | 실제 빌드 로직 |  (건드리지 마세요) |
| `Dockerfile` | Docker 이미지 레시피 |  (건드리지 마세요) |
| `.build-config` | 저장된 설정 | (자동 생성, 수동 편집 가능) |
| `build.config.example` | 설정 예시 | (참고용) |
| `out/` | 빌드 산출물 |  (자동 생성) |

### 8.2 설정 우선순위

여러 곳에서 설정을 지정할 수 있습니다. 우선순위는:

```
1. CLI 옵션          (가장 높음)
   ./build.sh --jobs 16

2. 환경 변수
   JOBS=8 ./build.sh

3. .build-config     (--setup으로 저장)
   JOBS=4

4. build.config      (수동 설정)
   JOBS=2

5. 기본값            (가장 낮음)
   JOBS=$(nproc)
```

**예시:**
```bash
# .build-config에 JOBS=4가 저장되어 있지만
# CLI 옵션이 우선
./build.sh --jobs 16  # ← 실제로는 16개 작업 사용
```

### 8.3 Docker 명령어 참고

**이미지 목록:**
```bash
docker images
```

**실행 중인 컨테이너:**
```bash
docker ps
```

**모든 컨테이너 (중지된 것 포함):**
```bash
docker ps -a
```

**이미지 삭제:**
```bash
docker rmi w55rp20:auto
```

**컨테이너 내부 접속:**
```bash
docker run --rm -it --entrypoint bash w55rp20:auto
```

**로그 확인:**
```bash
docker logs <container-id>
```

### 8.4 성능 최적화 팁

**1. 병렬 작업 수 조정**
```bash
# CPU 코어 수 확인
nproc

# 코어 수만큼 설정 (권장)
./build.sh --jobs $(nproc)

# 여유 있게 (코어 수 - 1)
./build.sh --jobs $(($(nproc) - 1))
```

**2. tmpfs 크기 최적화**
```bash
# 메모리 확인
free -h

# 메모리의 50% 정도 (권장)
# 48GB RAM 시스템이라면:
TMPFS_SIZE=24g ./build.sh
```

**3. ccache 활용**
자동으로 활성화됩니다. 두 번째 빌드부터 빠름!

**캐시 정보:**
```bash
docker run --rm -v ~/.ccache-w55rp20:/root/.ccache w55rp20:auto ccache -s
```

### 8.5 트러블슈팅 체크리스트

빌드 실패 시 순서대로 확인:

- [ ] Docker 서비스 실행 중? (`sudo systemctl status docker`)
- [ ] 디스크 공간 충분? (`df -h`)
- [ ] 메모리 충분? (`free -h`)
- [ ] Docker 권한 있음? (`docker ps`)
- [ ] 인터넷 연결됨? (`ping google.com`)
- [ ] CMakeLists.txt 존재? (`ls -l CMakeLists.txt`)
- [ ] 상세 로그 확인? (`./build.sh --verbose`)

---

## 마치며

### 다음 단계

이제 여러분은:
- Docker 기본 개념 이해
- W55RP20 펌웨어 빌드 가능
- 내 프로젝트 빌드 가능
- 문제 발생 시 해결 가능

### 더 알아보기

**기본 문서:**
- **[README.md](../README.md)** - 빠른 레퍼런스
- **[QUICKREF.md](QUICKREF.md)** - 1페이지 치트시트
- **[USER_GUIDE.md](USER_GUIDE.md)** - 상세 매뉴얼

**실전 가이드:**
- **[BUILD_LOGS.md](BUILD_LOGS.md)** - 실제 빌드 로그 예제
- **[EXAMPLES.md](EXAMPLES.md)** - 5가지 실전 예제
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - 문제 해결 가이드

**플랫폼별 설치:**
- **[INSTALL_LINUX.md](INSTALL_LINUX.md)** - Linux 설치 가이드
- **[INSTALL_MAC.md](INSTALL_MAC.md)** - macOS 설치 가이드
- **[INSTALL_WINDOWS.md](INSTALL_WINDOWS.md)** - Windows/WSL2 설치 가이드
- **[INSTALL_RASPBERRY_PI.md](INSTALL_RASPBERRY_PI.md)** - Raspberry Pi 설치 가이드

**참고 자료:**
- **[GLOSSARY.md](GLOSSARY.md)** - 용어 사전
- **[CHANGELOG.md](CHANGELOG.md)** - 변경 이력
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - 내부 구조 (개발자용)

### 도움 받기

문제가 생기면:

1. **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - 에러별 해결 방법 확인
2. **[BUILD_LOGS.md](BUILD_LOGS.md)** - 정상 로그와 비교
3. `./build.sh --help` 확인
4. 이 가이드 다시 읽기
5. GitHub Issues에 질문 올리기

### 기여하기

이 프로젝트를 개선하고 싶다면:
- 버그 리포트
- 문서 개선 제안
- Pull Request

**즐거운 개발 되세요!** 
