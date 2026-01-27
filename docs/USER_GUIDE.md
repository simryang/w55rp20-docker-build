# W55RP20-S2E 빌드 시스템 사용 설명서

## 목차

1. [개요](#개요)
2. [빌드 산출물](#빌드-산출물)
3. [방법 1: Docker 직접 사용](#방법-1-docker-직접-사용)
4. [방법 2: build.sh 사용 (권장)](#방법-2-buildsh-사용-간편-권장)
5. [고급 사용법](#고급-사용법)
6. [문제 해결](#문제-해결)
7. [부록: 스크립트 구조](#부록-스크립트-구조)

---

## 개요

이 빌드 시스템의 목표는 **W55RP20 마이크로컨트롤러용 펌웨어 파일(.uf2, .bin, .elf)을 빌드**하는 것입니다.

### 빌드 환경
- Docker 컨테이너 기반 (호스트 환경에 영향 없음)
- ARM GNU Toolchain 14.2
- CMake 3.28.3
- Raspberry Pi Pico SDK 2.2.0

### 요구사항
- Docker 설치 및 실행 중
- Git
- 16GB+ RAM 권장 (tmpfs 빌드 사용 시)

---

## 빌드 산출물

빌드가 완료되면 `./out/` 디렉토리에 다음 파일들이 생성됩니다:

### 주요 펌웨어 파일

| 파일 | 용도 | 크기 |
|------|------|------|
| `App.uf2` | 메인 애플리케이션 펌웨어 (플래시 권장) | ~622KB |
| `Boot.uf2` | 부트로더 펌웨어 | ~118KB |
| `App.bin` | 바이너리 포맷 | ~311KB |
| `App.elf` | 디버깅용 (심볼 포함) | ~1.7MB |
| `App.hex` | Intel HEX 포맷 | ~874KB |

### UF2 파일 사용법

**1. BOOTSEL 모드 진입:**
- W55RP20 보드의 BOOTSEL 버튼을 누른 상태로 USB 연결
- 또는 BOOTSEL 버튼을 누른 상태로 리셋

**2. 펌웨어 복사:**
```bash
# 보드가 USB 드라이브로 마운트됨 (예: /media/RPI-RP2)
cp ./out/App.uf2 /media/RPI-RP2/
```

**3. 자동 재부팅 및 실행**
- 파일 복사가 완료되면 보드가 자동으로 재부팅되어 펌웨어 실행

---

## 방법 1: Docker 직접 사용

**Docker를 직접 사용하는 기본적인 방법입니다.** 빌드 스크립트 없이 순수하게 Docker 명령만으로 빌드할 수 있습니다. 각 단계를 직접 제어할 수 있어 투명하고 유연합니다.

### 1단계: Docker 이미지 빌드

```bash
sudo docker buildx build \
  --platform linux/amd64 \
  -t w55rp20:auto \
  --load \
  .
```

**선택적 캐시 무효화:**
```bash
# apt 패키지 재설치
sudo docker buildx build \
  --platform linux/amd64 \
  --build-arg REFRESH_APT=1 \
  -t w55rp20:auto \
  --load \
  .

# Pico SDK 재다운로드
sudo docker buildx build \
  --platform linux/amd64 \
  --build-arg REFRESH_SDK=1 \
  -t w55rp20:auto \
  --load \
  .

# CMake 재설치
sudo docker buildx build \
  --platform linux/amd64 \
  --build-arg REFRESH_CMAKE=1 \
  -t w55rp20:auto \
  --load \
  .

# ARM GCC 재설치
sudo docker buildx build \
  --platform linux/amd64 \
  --build-arg REFRESH_GCC=1 \
  -t w55rp20:auto \
  --load \
  .

# 전체 재빌드 (캐시 무시)
sudo docker buildx build \
  --no-cache \
  --platform linux/amd64 \
  -t w55rp20:auto \
  --load \
  .
```

### 2단계: 소스 코드 준비

**방법 A: 기존 소스 사용**
```bash
# 소스 코드가 이미 있는 경우
ls ~/W55RP20-S2E/CMakeLists.txt  # 확인
```

**방법 B: 소스 클론**
```bash
git clone --recurse-submodules \
  https://github.com/WIZnet-ioNIC/W55RP20-S2E.git \
  ~/W55RP20-S2E
```

### 3단계: 빌드 실행

```bash
# 출력 디렉토리 생성
mkdir -p ./out

# Docker 컨테이너 실행 (빌드)
sudo docker run --rm -t \
  -v ~/W55RP20-S2E:/work/src \
  -v "$PWD/out":/work/out \
  -v ~/.ccache-w55rp20:/work/.ccache \
  --tmpfs /work/src/build:rw,exec,size=24g \
  -e CCACHE_DIR=/work/.ccache \
  -e JOBS=16 \
  -e BUILD_TYPE=Release \
  w55rp20:auto \
  /usr/local/bin/docker-build.sh
```

**옵션 설명:**
- `-v ~/W55RP20-S2E:/work/src` - 소스 코드 마운트
- `-v "$PWD/out":/work/out` - 산출물 디렉토리 마운트
- `-v ~/.ccache-w55rp20:/work/.ccache` - ccache 디렉토리 마운트
- `--tmpfs /work/src/build:rw,exec,size=24g` - 빌드용 tmpfs (메모리 디스크)
- `-e JOBS=16` - 병렬 빌드 작업 수
- `-e BUILD_TYPE=Release` - 빌드 타입 (Release/Debug)

### 4단계: 산출물 확인

```bash
ls -lh ./out/*.uf2
```

---

## 방법 2: build.sh 사용 (권장)

빌드 스크립트를 사용하는 방법입니다. 모든 설정을 자동으로 처리합니다.

### 기본 빌드

```bash
./build.sh
```

**동작:**
1. Docker 이미지가 없으면 자동 빌드
2. 소스 코드가 없으면 자동 클론 (`~/W55RP20-S2E`)
3. 빌드 실행 (tmpfs 사용, ccache 활성화)
4. 산출물을 `./out/`에 복사

### 주요 옵션

#### 산출물 정리 후 빌드
```bash
CLEAN=1 ./build.sh
```

#### 소스 코드 최신화
```bash
UPDATE_REPO=1 ./build.sh
```

#### 특정 브랜치/태그 빌드
```bash
REPO_REF=v1.2.3 ./build.sh
```

#### 디버그 빌드
```bash
BUILD_TYPE=Debug ./build.sh
```

#### 병렬 빌드 조정
```bash
# CPU 코어 수에 맞게 조정 (기본값: 16)
JOBS=8 ./build.sh
```

#### 메모리 제한 환경
```bash
# tmpfs 크기 조정 (기본값: 24g)
TMPFS_SIZE=8g ./build.sh
```

#### 상세 로그 출력
```bash
VERBOSE=1 ./build.sh
```

### 캐시 무효화 (REFRESH)

외부 리소스가 업데이트되었을 때 사용합니다.

```bash
# apt 패키지만 재설치
REFRESH="apt" ./build.sh

# Pico SDK 재다운로드
REFRESH="sdk" ./build.sh

# CMake 재설치
REFRESH="cmake" ./build.sh

# ARM GCC 재설치
REFRESH="gcc" ./build.sh

# CMake + GCC 모두 재설치
REFRESH="toolchain" ./build.sh

# 전체 재빌드 (모든 캐시 무효화)
REFRESH="all" ./build.sh
```

### 로컬 설정 파일 사용

환경별로 고정된 설정을 사용하려면:

```bash
# 설정 파일 생성
cp build.config.example build.config

# 편집
vim build.config
```

**build.config 예시:**
```bash
JOBS=32
TMPFS_SIZE=48g
BUILD_TYPE=Debug
```

설정 파일이 있으면 자동으로 로드됩니다:
```bash
./build.sh  # build.config 자동 적용
```

---

## 고급 사용법

### w55build.sh 직접 사용

더 세밀한 제어가 필요한 경우:

```bash
IMAGE=w55rp20:custom \
SRC_DIR=/custom/path/to/source \
OUT_DIR=/custom/path/to/output \
JOBS=32 \
TMPFS_SIZE=48g \
AUTO_BUILD_IMAGE=0 \
./w55build.sh
```

### 컨테이너 내부 진입 (디버깅)

```bash
sudo docker run --rm -it --entrypoint bash w55rp20:auto
```

**컨테이너 내부에서:**
```bash
# 툴체인 확인
arm-none-eabi-gcc --version
cmake --version

# 환경 변수 확인
echo $PICO_SDK_PATH
echo $PICO_TOOLCHAIN_PATH

# 수동 빌드 테스트
cd /opt/pico-sdk
ls -la
```

### 다중 프로젝트 빌드

여러 프로젝트를 동시에 빌드하는 경우:

```bash
# 프로젝트 1
SRC_DIR=~/project1 OUT_DIR=~/project1/out ./w55build.sh

# 프로젝트 2
SRC_DIR=~/project2 OUT_DIR=~/project2/out ./w55build.sh
```

### ccache 상태 확인

```bash
# ccache 통계
ccache -s

# ccache 정리
ccache -C
```

---

## 문제 해결

### Docker 권한 오류

**증상:**
```
permission denied while trying to connect to the Docker daemon socket
```

**해결:**
```bash
# 방법 1: Docker 그룹 추가 (권장)
sudo usermod -aG docker $USER
# 로그아웃 후 재로그인

# 방법 2: sudo 사용
sudo docker info  # 동작 확인
```

### Git ownership 오류

**증상:**
```
fatal: detected dubious ownership in repository at '/work/src'
```

**해결:**
- 최신 버전 사용 (커밋 d4aa905 이후)
- 이미 수정되어 자동으로 처리됨

### 메모리 부족

**증상:**
- 빌드 중 멈춤 또는 "Out of memory" 오류

**해결:**
```bash
# tmpfs 크기 줄이기
TMPFS_SIZE=8g ./build.sh

# 병렬 작업 수 줄이기
JOBS=4 ./build.sh

# 또는 둘 다
JOBS=4 TMPFS_SIZE=8g ./build.sh
```

### 디스크 공간 부족

**해결:**
```bash
# Docker 이미지/컨테이너 정리
sudo docker system prune -a

# ccache 정리
rm -rf ~/.ccache-w55rp20/*

# 산출물 정리
rm -rf ./out/*
```

### 빌드 실패

**1단계: 상세 로그 확인**
```bash
VERBOSE=1 ./build.sh
```

**2단계: 완전 재빌드**
```bash
# 이미지 재빌드
sudo docker buildx build --no-cache -t w55rp20:auto --load .

# 산출물 정리 후 빌드
CLEAN=1 ./build.sh
```

**3단계: 환경 확인**
```bash
# Docker 상태
sudo docker info

# 디스크 공간
df -h

# 메모리
free -h

# 소스 코드
ls -la ~/W55RP20-S2E/
```

---

## 부록: 스크립트 구조

### 전체 구조

```
프로젝트 루트
├── build.sh           # 사용자 진입점 (초보자 친화)
├── w55build.sh        # 빌드 로직 (고급 사용자용)
├── docker-build.sh    # 컨테이너 내부 빌드 스크립트
├── entrypoint.sh      # 컨테이너 진입점
├── Dockerfile         # 빌드 환경 정의
└── build.config       # 로컬 설정 (선택, gitignore됨)
```

### 데이터 흐름

```
사용자
  ↓
build.sh (기본값 설정)
  ↓
w55build.sh (Docker 관리)
  ↓
Docker 컨테이너
  ↓
docker-build.sh (실제 빌드)
  ↓
산출물 (./out/)
```

---

### 1. build.sh

**역할:** 사용자 진입점, 기본값 제공

**특징:**
- 입문자용 ("그냥 실행하면 됨")
- 합리적인 기본값 설정
- build.config 자동 로드
- REFRESH 문자열 파싱 (예: "apt", "sdk", "toolchain")
- w55build.sh 호출

**주요 변수:**
```bash
JOBS=16              # 병렬 빌드 작업 수 (nproc 자동)
TMPFS_SIZE=24g       # tmpfs 크기 (실제 메모리 점유 아님)
IMAGE=w55rp20:auto   # Docker 이미지 이름
AUTO_BUILD_IMAGE=1   # 이미지 자동 빌드 여부
UPDATE_REPO=0        # 소스 자동 업데이트 여부
CLEAN=0              # 산출물 정리 여부
BUILD_TYPE=Release   # 빌드 타입
VERBOSE=0            # 상세 로그 출력 여부
```

**REFRESH 처리:**
- `REFRESH="apt"` → `REFRESH_APT_BUST=1`
- `REFRESH="sdk"` → `REFRESH_SDK_BUST=1`
- `REFRESH="cmake"` → `REFRESH_CMAKE_BUST=1`
- `REFRESH="gcc"` → `REFRESH_GCC_BUST=1`
- `REFRESH="toolchain"` → `REFRESH_CMAKE_BUST=1` + `REFRESH_GCC_BUST=1`
- `REFRESH="all"` → 모든 BUST 변수 = 1

**실행 흐름:**
1. build.config 로드 (있으면)
2. 기본값 설정
3. REFRESH 파싱
4. w55build.sh 호출 (모든 변수 전달)

---

### 2. w55build.sh

**역할:** 실제 빌드 로직, Docker 관리

**특징:**
- 고급 사용자용 (모든 옵션 직접 지정 가능)
- Docker 이미지 존재 확인
- 필요 시 이미지 자동 빌드
- 소스 디렉토리 확인
- Docker 컨테이너 실행

**주요 디렉토리:**
```bash
SRC_DIR=$HOME/W55RP20-S2E        # 소스 코드 위치
OUT_DIR=$PWD/out                  # 산출물 위치
CCACHE_DIR_HOST=~/.ccache-w55rp20 # ccache 위치
```

**Docker 이미지 관리:**
```bash
# 이미지 존재 확인
docker image inspect "$IMAGE"

# 없거나 REFRESH 지정 시
if [ NEED_IMAGE_BUILD = 1 ]; then
  if [ AUTO_BUILD_IMAGE = 1 ]; then
    # 자동 빌드
    docker buildx build \
      --build-arg REFRESH_APT=$REFRESH_APT_BUST \
      --build-arg REFRESH_SDK=$REFRESH_SDK_BUST \
      ...
  else
    # 오류
    die "이미지 없음. AUTO_BUILD_IMAGE=1 필요"
  fi
fi
```

**Docker 실행:**
```bash
docker run --rm -t \
  -v "$SRC_DIR":/work/src \
  -v "$OUT_DIR":/work/out \
  -v "$CCACHE_DIR_HOST":/work/.ccache \
  --tmpfs /work/src/build:rw,exec,size="$TMPFS_SIZE" \
  -e JOBS="$JOBS" \
  -e BUILD_TYPE="$BUILD_TYPE" \
  -e UPDATE_REPO="$UPDATE_REPO" \
  "$IMAGE" /usr/local/bin/docker-build.sh
```

**주의사항:**
- tmpfs는 `rw,exec` 필요 (pioasm 등 바이너리 실행)
- REFRESH 지정 시 AUTO_BUILD_IMAGE=0이면 경고

---

### 3. docker-build.sh

**역할:** 컨테이너 내부 빌드 실행

**위치:** 컨테이너 내 `/usr/local/bin/docker-build.sh`

**특징:**
- Git safe.directory 설정 (Docker mount ownership 해결)
- 필수 툴 확인 (cmake, ninja, gcc, python, srec_cat)
- ccache 자동 활성화
- tmpfs 사용량 모니터링
- 산출물 자동 수집

**실행 흐름:**
1. Git safe.directory 설정
   ```bash
   git config --global --add safe.directory /work/src
   ```

2. 필수 툴 확인
   ```bash
   need cmake
   need ninja
   need arm-none-eabi-gcc
   need srec_cat
   ```

3. tmpfs 모니터링 시작 (백그라운드)
   ```bash
   monitor_tmpfs &
   ```

4. CMake configure
   ```bash
   cmake -S /work/src -B /work/src/build -G Ninja \
     -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
     -DPICO_SDK_PATH=/opt/pico-sdk \
     -DPICO_TOOLCHAIN_PATH=/opt/toolchain \
     -DCMAKE_C_COMPILER_LAUNCHER=ccache \
     -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
   ```

5. 빌드
   ```bash
   cmake --build /work/src/build -- -j "$JOBS"
   ```

6. 산출물 수집
   ```bash
   find /work/src/build -type f \
     \( -name "*.uf2" -o -name "*.elf" -o -name "*.bin" -o -name "*.hex" \) \
     -exec cp -f {} /work/out/ \;
   ```

7. tmpfs 사용량 출력
   ```bash
   df -h /work/src/build
   du -sh /work/src/build
   echo "TMPFS_PEAK_GiB=..."
   ```

---

### 4. entrypoint.sh

**역할:** 컨테이너 진입점 (원샷 빌드용)

**위치:** 컨테이너 내 `/usr/local/bin/entrypoint.sh`

**특징:**
- 인자가 있으면 그대로 실행 (`exec "$@"`)
- 인자가 없으면 소스 클론 → 빌드 → 산출물 복사
- UPDATE_REPO=0일 때 git fetch 건너뛰기

**사용 사례:**

**케이스 1: w55build.sh에서 호출 (docker-build.sh 직접 실행)**
```bash
docker run ... w55rp20:auto /usr/local/bin/docker-build.sh
# → entrypoint.sh가 인자를 받아서 docker-build.sh 실행
```

**케이스 2: 원샷 빌드 (인자 없음)**
```bash
docker run ... w55rp20:auto
# → entrypoint.sh가 전체 프로세스 수행
#    (소스 클론 → 빌드 → 산출물 복사)
```

**Git 처리:**
```bash
# 마운트된 소스가 있으면
if [ -f "$SRC_DIR/CMakeLists.txt" ]; then
  log "소스 감지됨. 기존 소스 사용"
else
  # 소스 클론
  git clone --recurse-submodules "$REPO_URL" "$SRC_DIR"
fi

# Git safe.directory 설정
git config --global --add safe.directory "$SRC_DIR"

# UPDATE_REPO 확인
if [ "$UPDATE_REPO" = "1" ]; then
  git fetch --all --tags
  git checkout "$REPO_REF"
  git submodule update --init --recursive
else
  log "UPDATE_REPO=0: git fetch 건너뜀"
fi
```

**Pico SDK 버전 고정:**
```bash
if [ -d "libraries/pico-sdk/.git" ]; then
  cd libraries/pico-sdk
  git fetch --tags
  git checkout "${PICO_SDK_TAG}"  # 2.2.0
  git submodule update --init --recursive
fi
```

---

### 5. Dockerfile

**역할:** 빌드 환경 정의

**기본 이미지:** `ubuntu:22.04`

**ARG 변수 (캐시 제어):**
```dockerfile
ARG REFRESH_APT=0     # apt 패키지 재설치
ARG REFRESH_SDK=0     # Pico SDK 재다운로드
ARG REFRESH_CMAKE=0   # CMake 재설치
ARG REFRESH_GCC=0     # ARM GCC 재설치
```

**빌드 단계:**

1. **기본 패키지 설치**
   ```dockerfile
   RUN echo "REFRESH_APT=$REFRESH_APT" && \
       apt-get update && apt-get install -y \
       cmake ninja-build gcc g++ ccache git curl \
       python3 libusb-1.0-0-dev astyle srecord ...
   ```

2. **CMake 3.28.3 설치 (arch-aware)**
   ```dockerfile
   RUN echo "REFRESH_CMAKE=$REFRESH_CMAKE" && \
       case "$TARGETARCH" in \
         amd64) CMAKE_ARCH="x86_64" ;; \
         arm64) CMAKE_ARCH="aarch64" ;; \
       esac; \
       curl -fsSL -o /tmp/cmake.tar.gz \
         "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-${CMAKE_ARCH}.tar.gz"
   ```

3. **ARM GNU Toolchain 14.2 설치 (arch-aware)**
   ```dockerfile
   RUN echo "REFRESH_GCC=$REFRESH_GCC" && \
       case "$TARGETARCH" in \
         amd64) HOST_ARCH="x86_64" ;; \
         arm64) HOST_ARCH="aarch64" ;; \
       esac; \
       curl -fsSL -o /tmp/armgnu.tar.xz \
         "https://developer.arm.com/.../arm-gnu-toolchain-${ARM_GNU_TOOLCHAIN_VERSION}-${HOST_ARCH}-arm-none-eabi.tar.xz"
   ```

4. **Pico SDK 2.2.0 설치**
   ```dockerfile
   RUN echo "REFRESH_SDK=$REFRESH_SDK" && \
       git clone --depth 1 --branch "${PICO_SDK_REF}" \
       https://github.com/raspberrypi/pico-sdk.git /opt/pico-sdk && \
       cd /opt/pico-sdk && \
       git submodule update --init --recursive
   ```

5. **picotool 설치**
   ```dockerfile
   RUN git clone https://github.com/raspberrypi/picotool.git /opt/picotool && \
       cd /opt/picotool && \
       cmake -S . -B build -G Ninja && \
       cmake --build build && \
       cmake --install build
   ```

6. **스크립트 복사**
   ```dockerfile
   COPY entrypoint.sh /usr/local/bin/entrypoint.sh
   COPY docker-build.sh /usr/local/bin/docker-build.sh
   RUN chmod +x /usr/local/bin/*.sh
   ```

**환경 변수:**
```dockerfile
ENV PICO_SDK_PATH=/opt/pico-sdk
ENV PICO_TOOLCHAIN_PATH=/opt/toolchain
ENV PATH="/opt/toolchain/bin:/usr/local/bin:${PATH}"
```

**진입점:**
```dockerfile
WORKDIR /work
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
```

**캐시 전략:**
- 각 RUN 단계마다 `echo "REFRESH_XXX=$REFRESH_XXX"` 포함
- ARG 값이 바뀌면 해당 레이어부터 재실행
- 변경되지 않은 레이어는 캐시 재사용

---

### 6. build.config (선택)

**역할:** 로컬 환경별 설정

**위치:** 프로젝트 루트 (gitignore됨)

**생성:**
```bash
cp build.config.example build.config
vim build.config
```

**예시:**
```bash
# 고성능 워크스테이션
JOBS=32
TMPFS_SIZE=48g
BUILD_TYPE=Release

# 저사양 환경 (라즈베리파이 등)
# JOBS=4
# TMPFS_SIZE=4g
```

**적용:**
- build.sh가 자동으로 source
- 명령줄 인자가 우선순위 높음

---

## 요약

### 빠른 참조

| 목적 | 명령 |
|------|------|
| 기본 빌드 | `./build.sh` |
| 정리 후 빌드 | `CLEAN=1 ./build.sh` |
| 디버그 빌드 | `BUILD_TYPE=Debug ./build.sh` |
| 전체 재빌드 | `REFRESH="all" ./build.sh` |
| 상세 로그 | `VERBOSE=1 ./build.sh` |
| 저사양 환경 | `JOBS=4 TMPFS_SIZE=8g ./build.sh` |

### 스크립트 역할

| 스크립트 | 역할 | 대상 |
|----------|------|------|
| build.sh | 진입점, 기본값 | 초보자 |
| w55build.sh | Docker 관리 | 고급 사용자 |
| docker-build.sh | 실제 빌드 | 컨테이너 내부 |
| entrypoint.sh | 진입점 | 컨테이너 |
| Dockerfile | 환경 정의 | Docker 빌드 |

### 산출물 위치

```
./out/
├── App.uf2          ← 주요 펌웨어 (플래시 권장)
├── Boot.uf2         ← 부트로더
├── App.bin
├── App.elf          ← 디버깅용
└── App.hex
```

---

## 관련 문서

### 필수 가이드
- **[README.md](../README.md)** - 프로젝트 개요 및 빠른 시작
- **[BEGINNER_GUIDE.md](BEGINNER_GUIDE.md)** - 입문자 가이드
- **[QUICKREF.md](QUICKREF.md)** - 1페이지 빠른 참조

### 문제 해결
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - 에러 해결 가이드
- **[BUILD_LOGS.md](BUILD_LOGS.md)** - 빌드 로그 예제

### 실전 활용
- **[EXAMPLES.md](EXAMPLES.md)** - 5가지 실전 예제

### 플랫폼별 설치
- **[INSTALL_LINUX.md](INSTALL_LINUX.md)** - Linux
- **[INSTALL_MAC.md](INSTALL_MAC.md)** - macOS
- **[INSTALL_WINDOWS.md](INSTALL_WINDOWS.md)** - Windows/WSL2
- **[INSTALL_RASPBERRY_PI.md](INSTALL_RASPBERRY_PI.md)** - Raspberry Pi

### 참고 자료
- **[GLOSSARY.md](GLOSSARY.md)** - 용어 사전
- **[CHANGELOG.md](CHANGELOG.md)** - 변경 이력
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - 내부 아키텍처 (개발자용)

---

**문서 버전:** 2026-01-21
**작성자:** Community contribution
