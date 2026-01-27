# W55RP20 빌드 시스템 아키텍처

> 내부 구조를 이해하고, 수정하고, 확장하려는 개발자를 위한 문서

## 목차

1. [전체 아키텍처](#1-전체-아키텍처)
2. [실행 흐름 상세 분석](#2-실행-흐름-상세-분석)
3. [스크립트 구조](#3-스크립트-구조)
4. [Docker 레이어 아키텍처](#4-docker-레이어-아키텍처)
5. [변수와 환경 전파](#5-변수와-환경-전파)
6. [캐시 전략](#6-캐시-전략)
7. [에러 핸들링](#7-에러-핸들링)
8. [확장 및 커스터마이징](#8-확장-및-커스터마이징)
9. [디버깅 가이드](#9-디버깅-가이드)
10. [기여 가이드](#10-기여-가이드)

---

## 1. 전체 아키텍처

### 1.1 컴포넌트 다이어그램

```
┌─────────────────────────────────────────────────────────────┐
│                          호스트 시스템                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────┐                                            │
│  │  build.sh   │ ← 사용자 인터페이스                        │
│  │             │   - CLI 파싱                               │
│  └──────┬──────┘   - .build-config 관리                     │
│         │          - 대화형 모드                             │
│         ↓                                                     │
│  ┌─────────────┐                                            │
│  │ w55build.sh │ ← 빌드 오케스트레이터                      │
│  │             │   - 변수 검증                              │
│  └──────┬──────┘   - Docker 이미지 관리                     │
│         │          - 컨테이너 실행                           │
│         │                                                     │
│         ↓                                                     │
│  ┌──────────────────────────────────────┐                   │
│  │         Docker Engine                │                   │
│  ├──────────────────────────────────────┤                   │
│  │                                       │                   │
│  │  ┌────────────────────────────────┐  │                   │
│  │  │    Docker 이미지 (w55rp20:auto) │  │                   │
│  │  ├────────────────────────────────┤  │                   │
│  │  │ Layer 1: Ubuntu 22.04          │  │                   │
│  │  │ Layer 2: apt packages          │  │ ← Dockerfile에서  │
│  │  │ Layer 3: ARM GCC 14.2          │  │   빌드됨          │
│  │  │ Layer 4: CMake 3.28.3          │  │                   │
│  │  │ Layer 5: Pico SDK              │  │                   │
│  │  │ Layer 6: ccache                │  │                   │
│  │  └──────────┬─────────────────────┘  │                   │
│  │             ↓                         │                   │
│  │  ┌────────────────────────────────┐  │                   │
│  │  │    실행 중인 컨테이너           │  │                   │
│  │  ├────────────────────────────────┤  │                   │
│  │  │ entrypoint.sh                  │  │ ← 초기화          │
│  │  │   ↓                            │  │                   │
│  │  │ docker-build.sh                │  │ ← 실제 빌드       │
│  │  │   ├── git clone/fetch          │  │                   │
│  │  │   ├── cmake -B build           │  │                   │
│  │  │   ├── make -j$JOBS             │  │                   │
│  │  │   └── cp *.uf2 → /out          │  │                   │
│  │  └────────────────────────────────┘  │                   │
│  │                                       │                   │
│  └───────────────────────────────────────┘                   │
│         ↑                        ↓                           │
│  ┌──────────────┐         ┌──────────────┐                  │
│  │ 호스트 볼륨  │         │ 호스트 볼륨  │                  │
│  │ ~/.ccache-   │         │ ./out/       │                  │
│  │ w55rp20/     │         │ (산출물)     │                  │
│  └──────────────┘         └──────────────┘                  │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 데이터 흐름

```
사용자 입력
    ↓
[build.sh: CLI 파싱 + .build-config 로드]
    ↓
변수 설정 (SRC_DIR, OUT_DIR, JOBS, BUILD_TYPE 등)
    ↓
[w55build.sh: 변수 검증]
    ↓
Docker 이미지 존재 확인
    ├─ 없음 → docker buildx build (15~20분)
    └─ 있음 → 재사용 (0초)
    ↓
[Docker 컨테이너 실행]
    ↓
Mount:
  - 소스: $SRC_DIR → /workspace
  - 산출물: $OUT_DIR → /out
  - ccache: ~/.ccache-w55rp20 → /root/.ccache
  - tmpfs: /tmp/build (RAM 빌드)
    ↓
[entrypoint.sh: 환경 초기화]
  - Git safe.directory 설정
  - 환경 변수 출력 (VERBOSE)
    ↓
[docker-build.sh: 빌드 실행]
  1. 소스 준비
     - /workspace 존재하면 사용
     - 없으면 git clone
  2. CMake 설정
     - cmake -B /tmp/build -S /workspace
     - BUILD_TYPE, CMAKE_C_FLAGS 적용
  3. 빌드
     - make -j$JOBS -C /tmp/build
     - ccache로 캐시 활용
  4. 산출물 복사
     - cp /tmp/build/**/*.uf2 /out/
    ↓
[호스트: ./out/에 .uf2 파일 생성]
```

---

## 2. 실행 흐름 상세 분석

### 2.1 build.sh 실행 흐름

```bash
#!/usr/bin/env bash
# build.sh

main() {
    # 1. 버전 정보
    SCRIPT_VERSION="1.1.0"

    # 2. 기본값 설정
    DEFAULT_SRC_DIR="./src"
    DEFAULT_OUT_DIR="./out"
    DEFAULT_BUILD_TYPE="Release"
    DEFAULT_JOBS=$(nproc)

    # 3. CLI 파싱
    parse_cli_options "$@"
    # - --project, --output, --clean, --debug 등 파싱
    # - 충돌 감지 (--official vs --project)
    # - 도움말/버전 표시 시 종료

    # 4. .build-config 로드 (저장된 설정)
    if [ -f ".build-config" ]; then
        source ".build-config"
    fi

    # 5. CLI 옵션으로 덮어쓰기 (우선순위 높음)
    apply_cli_overrides

    # 6. Interactive mode (--setup)
    if [ "$INTERACTIVE_MODE" = "1" ]; then
        run_interactive_setup
        # - 프로젝트 선택 (공식/사용자)
        # - 산출물 경로 지정
        # - 설정 요약 표시
        # - 확인 후 .build-config 저장
    fi

    # 7. 설정 저장 (--save-config)
    if [ "$SAVE_CONFIG" = "1" ]; then
        save_build_config
        exit 0
    fi

    # 8. 설정 표시 (--show-config)
    if [ "$SHOW_CONFIG" = "1" ]; then
        show_current_config
        exit 0
    fi

    # 9. 빌드 전 확인 프롬프트
    if [ "$NO_CONFIRM" != "1" ] && [ "$QUIET" != "1" ]; then
        show_build_summary
        read -p "Continue? [y/N]: " confirm
        [ "$confirm" != "y" ] && exit 0
    fi

    # 10. w55build.sh 호출
    export SRC_DIR OUT_DIR JOBS BUILD_TYPE CLEAN UPDATE_REPO VERBOSE
    export REFRESH  # REFRESH="sdk" 등

    exec ./w55build.sh
}
```

**함수 목록:**
- `parse_cli_options()` - getopt-style 파싱
- `load_build_config()` - .build-config 읽기
- `save_build_config()` - .build-config 쓰기
- `run_interactive_setup()` - 대화형 모드
- `validate_project_dir()` - CMakeLists.txt 확인
- `show_build_summary()` - 빌드 전 요약
- `show_success_message()` - 빌드 후 산출물 표시

### 2.2 w55build.sh 실행 흐름

```bash
#!/usr/bin/env bash
# w55build.sh

main() {
    # 1. 변수 기본값 (build.config 로드 포함)
    if [ -f "build.config" ]; then
        source "build.config"
    fi

    IMAGE="${IMAGE:-w55rp20:auto}"
    JOBS="${JOBS:-$(nproc)}"
    TMPFS_SIZE="${TMPFS_SIZE:-16g}"
    AUTO_BUILD_IMAGE="${AUTO_BUILD_IMAGE:-1}"

    # 2. REFRESH 변수 → Docker ARG 변환
    # REFRESH="sdk" → REFRESH_SDK_BUST="$(date +%s)"
    convert_refresh_to_build_args

    # 3. VERBOSE 모드
    if [ "$VERBOSE" = "1" ]; then
        echo "=== Variables ==="
        env | grep -E '^(IMAGE|JOBS|SRC_DIR|OUT_DIR)' | sort
    fi

    # 4. Docker 이미지 빌드 (필요 시)
    if [ "$AUTO_BUILD_IMAGE" = "1" ]; then
        if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
            echo "Building Docker image $IMAGE..."
            docker buildx build \
                --build-arg REFRESH_APT_BUST="$REFRESH_APT_BUST" \
                --build-arg REFRESH_SDK_BUST="$REFRESH_SDK_BUST" \
                --build-arg REFRESH_CMAKE_BUST="$REFRESH_CMAKE_BUST" \
                --build-arg REFRESH_GCC_BUST="$REFRESH_GCC_BUST" \
                -t "$IMAGE" --load .
        fi
    fi

    # 5. 디렉토리 준비
    mkdir -p "$OUT_DIR"
    mkdir -p ~/.ccache-w55rp20

    # 6. Docker 실행
    docker run --rm \
        -v "$SRC_DIR:/workspace:rw" \
        -v "$OUT_DIR:/out:rw" \
        -v ~/.ccache-w55rp20:/root/.ccache:rw \
        --tmpfs /tmp/build:rw,exec,size=$TMPFS_SIZE \
        -e JOBS="$JOBS" \
        -e BUILD_TYPE="$BUILD_TYPE" \
        -e UPDATE_REPO="$UPDATE_REPO" \
        -e CLEAN="$CLEAN" \
        -e VERBOSE="$VERBOSE" \
        "$IMAGE"
}
```

**핵심 로직:**
- `convert_refresh_to_build_args()` - REFRESH 변수를 Docker ARG로 변환
- `check_docker_permission()` - Docker 권한 확인
- 볼륨 마운트:
  - `$SRC_DIR:/workspace` - 소스 코드
  - `$OUT_DIR:/out` - 산출물
  - `~/.ccache-w55rp20:/root/.ccache` - 컴파일 캐시
  - `tmpfs /tmp/build` - RAM 빌드 (속도 향상)

### 2.3 Docker 컨테이너 내부 (entrypoint.sh → docker-build.sh)

```bash
# entrypoint.sh (컨테이너 초기화)
#!/bin/bash

# Git safe.directory 설정 (mount ownership 문제 해결)
git config --global --add safe.directory /workspace

# 환경 변수 출력 (VERBOSE=1)
if [ "$VERBOSE" = "1" ]; then
    echo "=== Container Environment ==="
    env | sort
fi

# docker-build.sh 실행
exec /usr/local/bin/docker-build.sh
```

```bash
# docker-build.sh (실제 빌드)
#!/bin/bash

set -euo pipefail

# 1. Git safe.directory (중복 설정, 보험)
git config --global --add safe.directory /workspace

# 2. 소스 준비
if [ -d "/workspace/.git" ]; then
    cd /workspace
    if [ "${UPDATE_REPO:-0}" = "1" ]; then
        git fetch origin
        git reset --hard origin/HEAD
    fi
else
    # 소스 없으면 클론
    git clone --depth 1 https://github.com/WIZnet-ioNIC/W55RP20-S2E.git /workspace
    cd /workspace
fi

# 3. 정리 (CLEAN=1)
if [ "${CLEAN:-0}" = "1" ]; then
    rm -rf /tmp/build
fi

# 4. CMake 설정
CMAKE_FLAGS="-DCMAKE_BUILD_TYPE=${BUILD_TYPE:-Release}"
if [ "${VERBOSE:-0}" = "1" ]; then
    CMAKE_FLAGS="$CMAKE_FLAGS -DCMAKE_VERBOSE_MAKEFILE=ON"
fi

cmake -B /tmp/build -S /workspace $CMAKE_FLAGS

# 5. 빌드
make -j${JOBS:-8} -C /tmp/build

# 6. 산출물 복사
find /tmp/build -name "*.uf2" -exec cp {} /out/ \;

# 7. tmpfs 사용량 출력
if [ "${VERBOSE:-0}" = "1" ]; then
    df -h /tmp/build
fi

echo "Build completed successfully!"
```

---

## 3. 스크립트 구조

### 3.1 파일별 책임

| 파일 | 줄 수 | 책임 | 실행 위치 |
|------|-------|------|----------|
| **build.sh** | 721 | 사용자 인터페이스<br>CLI 파싱<br>.build-config 관리<br>대화형 모드 | 호스트 |
| **w55build.sh** | 473 | 빌드 오케스트레이션<br>Docker 관리<br>변수 검증<br>볼륨 마운트 | 호스트 |
| **Dockerfile** | 87 | 이미지 정의<br>툴체인 설치<br>레이어 구성 | Docker 빌드 |
| **entrypoint.sh** | 25 | 컨테이너 초기화<br>환경 설정<br>Git 설정 | 컨테이너 |
| **docker-build.sh** | 156 | 실제 빌드<br>소스 클론/업데이트<br>CMake + Make<br>산출물 복사 | 컨테이너 |

### 3.2 함수 목록 (build.sh)

```bash
# CLI 관련
parse_cli_options()         # getopt-style 파싱, 충돌 감지
show_help()                 # --help 표시
show_version()              # --version 표시

# 설정 관련
load_build_config()         # .build-config 읽기
save_build_config()         # .build-config 쓰기
show_current_config()       # --show-config 표시
apply_cli_overrides()       # CLI 옵션 우선 적용

# Interactive 모드
run_interactive_setup()     # 대화형 설정 진행
prompt_project_type()       # 1) 공식 / 2) 사용자 프로젝트
prompt_project_path()       # 프로젝트 경로 입력
validate_project_dir()      # CMakeLists.txt 확인
prompt_output_dir()         # 산출물 경로 입력
show_config_summary()       # 설정 요약 표시
confirm_and_save()          # 확인 후 저장

# 진행 상태 표시
show_build_summary()        # 빌드 전 요약
show_saved_config_notice()  # 저장된 설정 사용 안내
show_success_message()      # 빌드 성공 메시지
show_output_files()         # 산출물 파일 목록
show_uf2_info()             # .uf2 파일 사용법
```

### 3.3 함수 목록 (w55build.sh)

```bash
# Docker 관련
check_docker_permission()   # Docker 권한 확인
ensure_image_exists()       # 이미지 빌드/확인

# REFRESH 관련
convert_refresh_to_build_args()  # REFRESH="sdk" → ARG 변환
parse_refresh_targets()          # 쉼표 분리 파싱

# 디렉토리 관련
prepare_directories()       # out/, ccache/ 생성
validate_source_dir()       # SRC_DIR 검증

# 실행
run_docker_build()          # docker run 명령 실행
```

### 3.4 변수 스코프

```bash
# 전역 (export되어 w55build.sh → docker로 전파)
SRC_DIR          # 소스 코드 경로
OUT_DIR          # 산출물 경로
JOBS             # 병렬 작업 수
BUILD_TYPE       # Release/Debug
CLEAN            # 정리 플래그
UPDATE_REPO      # 소스 업데이트 플래그
VERBOSE          # 상세 출력 플래그
REFRESH          # 캐시 무효화 대상

# 로컬 (w55build.sh 내부)
IMAGE            # Docker 이미지 이름
TMPFS_SIZE       # tmpfs 크기
AUTO_BUILD_IMAGE # 자동 이미지 빌드 플래그

# Docker ARG (Dockerfile)
REFRESH_APT_BUST
REFRESH_SDK_BUST
REFRESH_CMAKE_BUST
REFRESH_GCC_BUST
```

---

## 4. Docker 레이어 아키텍처

### 4.1 Dockerfile 분석

```dockerfile
FROM ubuntu:22.04

# Layer 1: Base image
# - 크기: ~77MB
# - 캐시: 항상 재사용 (변경 없음)

# Layer 2: apt 패키지
ARG REFRESH_APT_BUST=1
RUN apt-get update && \
    apt-get install -y \
        git cmake ninja-build gcc g++ \
        python3 python3-pip \
        ccache \
    && rm -rf /var/lib/apt/lists/*
# - 크기: ~500MB
# - 캐시: REFRESH_APT_BUST 변경 시에만 재빌드

# Layer 3: ARM GCC 툴체인
ARG REFRESH_GCC_BUST=1
RUN wget -q https://developer.arm.com/.../gcc-arm-none-eabi-14.2.rel1-x86_64-linux.tar.bz2 && \
    tar -xf gcc-arm-none-eabi-14.2.rel1-x86_64-linux.tar.bz2 -C /opt && \
    rm gcc-arm-none-eabi-14.2.rel1-x86_64-linux.tar.bz2
ENV PATH="/opt/gcc-arm-none-eabi-14.2.rel1/bin:$PATH"
# - 크기: ~300MB
# - 캐시: REFRESH_GCC_BUST 변경 시에만 재빌드

# Layer 4: CMake (최신 버전)
ARG REFRESH_CMAKE_BUST=1
RUN wget -q https://github.com/Kitware/CMake/releases/download/v3.28.3/cmake-3.28.3-linux-x86_64.tar.gz && \
    tar -xzf cmake-3.28.3-linux-x86_64.tar.gz -C /opt && \
    rm cmake-3.28.3-linux-x86_64.tar.gz
ENV PATH="/opt/cmake-3.28.3-linux-x86_64/bin:$PATH"
# - 크기: ~50MB
# - 캐시: REFRESH_CMAKE_BUST 변경 시에만 재빌드

# Layer 5: Pico SDK
ARG REFRESH_SDK_BUST=1
RUN git clone --depth 1 https://github.com/raspberrypi/pico-sdk.git /pico-sdk && \
    cd /pico-sdk && \
    git submodule update --init
ENV PICO_SDK_PATH=/pico-sdk
# - 크기: ~200MB
# - 캐시: REFRESH_SDK_BUST 변경 시에만 재빌드

# Layer 6: ccache 설정
RUN mkdir -p /root/.ccache && \
    ccache --set-config=max_size=2G && \
    ccache --set-config=compression=true
# - 크기: ~1MB
# - 캐시: 항상 재사용

# Layer 7: 스크립트 복사
COPY docker-build.sh /usr/local/bin/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /usr/local/bin/docker-build.sh /entrypoint.sh
# - 크기: ~10KB
# - 캐시: 스크립트 변경 시에만 재빌드

ENTRYPOINT ["/entrypoint.sh"]
```

### 4.2 레이어 크기 및 캐시 전략

```
┌────────────────────────────────────────────────┐
│ Layer 7: entrypoint.sh + docker-build.sh       │  10KB
│ (캐시: 스크립트 변경 시에만 무효화)            │
├────────────────────────────────────────────────┤
│ Layer 6: ccache 설정                           │  1MB
│ (캐시: 항상 재사용)                            │
├────────────────────────────────────────────────┤
│ Layer 5: Pico SDK                              │  200MB
│ ARG REFRESH_SDK_BUST                           │
│ (캐시: REFRESH="sdk" 시 무효화)                │
├────────────────────────────────────────────────┤
│ Layer 4: CMake 3.28.3                          │  50MB
│ ARG REFRESH_CMAKE_BUST                         │
│ (캐시: REFRESH="cmake" 시 무효화)              │
├────────────────────────────────────────────────┤
│ Layer 3: ARM GCC 14.2                          │  300MB
│ ARG REFRESH_GCC_BUST                           │
│ (캐시: REFRESH="gcc" 시 무효화)                │
├────────────────────────────────────────────────┤
│ Layer 2: apt packages                          │  500MB
│ ARG REFRESH_APT_BUST                           │
│ (캐시: REFRESH="apt" 시 무효화)                │
├────────────────────────────────────────────────┤
│ Layer 1: ubuntu:22.04                          │  77MB
│ (캐시: 항상 재사용)                            │
└────────────────────────────────────────────────┘
         총 크기: ~1.1GB
```

**선택적 캐시 무효화 예시:**
```bash
# SDK만 재다운로드
REFRESH="sdk" ./build.sh
# → Layer 5~7 재빌드 (250MB, ~3분)
# → Layer 1~4 재사용 (850MB, 0초)

# 툴체인 전체 재설치
REFRESH="toolchain" ./build.sh  # toolchain = cmake + gcc
# → Layer 3~7 재빌드 (560MB, ~8분)
# → Layer 1~2 재사용 (577MB, 0초)

# 전체 재빌드
REFRESH="all" ./build.sh
# → Layer 1~7 재빌드 (1.1GB, ~15분)
```

---

## 5. 변수와 환경 전파

### 5.1 설정 우선순위 (높음 → 낮음)

```
1. CLI 옵션              (build.sh --jobs 16)
   ↓
2. 환경 변수             (JOBS=8 ./build.sh)
   ↓
3. .build-config         (build.sh --save-config로 저장)
   ↓
4. build.config          (사용자가 직접 작성)
   ↓
5. 스크립트 기본값       (nproc, ./out 등)
```

### 5.2 변수 전파 경로

```
사용자 입력
    ↓
build.sh (CLI 파싱)
    ├─ SRC_DIR="./src"
    ├─ OUT_DIR="./out"
    ├─ JOBS=16
    ├─ BUILD_TYPE="Release"
    ├─ CLEAN=0
    ├─ UPDATE_REPO=0
    └─ VERBOSE=0
    ↓
.build-config 로드 (존재 시)
    ├─ SRC_DIR="/home/user/my-project"  ← 덮어쓰기
    └─ OUT_DIR="./artifacts"            ← 덮어쓰기
    ↓
CLI 옵션으로 다시 덮어쓰기 (우선순위 최고)
    ↓
export 변수들
    ↓
w55build.sh
    ├─ 변수 검증
    ├─ build.config 로드 (낮은 우선순위)
    └─ Docker ARG 생성 (REFRESH)
    ↓
docker run -e JOBS -e BUILD_TYPE ...
    ↓
컨테이너 환경 변수
    ↓
entrypoint.sh (환경 출력)
    ↓
docker-build.sh (사용)
```

### 5.3 모든 변수 목록

#### 사용자 설정 가능 변수

```bash
# 프로젝트 설정
SRC_DIR          # 소스 코드 위치 (기본: ./src)
OUT_DIR          # 산출물 위치 (기본: ./out)

# 빌드 설정
JOBS             # 병렬 작업 수 (기본: nproc)
BUILD_TYPE       # Release/Debug (기본: Release)
TMPFS_SIZE       # tmpfs 크기 (기본: 16g)

# 동작 제어
CLEAN            # 빌드 전 정리 (0/1)
UPDATE_REPO      # 소스 업데이트 (0/1)
VERBOSE          # 상세 출력 (0/1)
REFRESH          # 캐시 무효화 (apt/sdk/cmake/gcc/toolchain/all)

# Docker 설정
IMAGE            # 이미지 이름 (기본: w55rp20:auto)
AUTO_BUILD_IMAGE # 자동 이미지 빌드 (0/1, 기본: 1)

# build.sh 전용
NO_CONFIRM       # 확인 프롬프트 생략 (0/1)
QUIET            # 메시지 최소화 (0/1)
INTERACTIVE_MODE # 대화형 모드 (0/1)
SAVE_CONFIG      # 설정 저장 (0/1)
SHOW_CONFIG      # 설정 표시 (0/1)
```

#### 내부 변수 (사용자 수정 불필요)

```bash
# Dockerfile ARG (REFRESH에서 생성)
REFRESH_APT_BUST      # apt 레이어 무효화
REFRESH_SDK_BUST      # SDK 레이어 무효화
REFRESH_CMAKE_BUST    # CMake 레이어 무효화
REFRESH_GCC_BUST      # GCC 레이어 무효화

# 경로 (컨테이너 내부)
PICO_SDK_PATH         # /pico-sdk
WORKSPACE             # /workspace (소스)
BUILD_DIR             # /tmp/build (tmpfs)
OUT_MOUNT             # /out (산출물)

# 버전 정보
SCRIPT_VERSION        # build.sh 버전 (1.1.0)
```

---

## 6. 캐시 전략

### 6.1 Docker Layer Cache

**작동 원리:**
```
빌드 시:
  1. 각 RUN 명령어 → 레이어 생성
  2. 레이어 ID = 명령어 해시 + 이전 레이어 ID
  3. 동일한 명령어 → 동일한 레이어 → 캐시 재사용

캐시 무효화:
  1. 명령어 변경 → 해당 레이어부터 재빌드
  2. ARG 변경 → ARG 사용하는 레이어부터 재빌드
  3. --no-cache → 전체 재빌드
```

**예시:**
```dockerfile
# 항상 캐시 재사용 (변경 없음)
FROM ubuntu:22.04

# ARG로 선택적 무효화
ARG REFRESH_SDK_BUST=1
RUN git clone https://github.com/raspberrypi/pico-sdk.git
```

```bash
# SDK만 무효화
REFRESH="sdk" ./build.sh
# → REFRESH_SDK_BUST=$(date +%s) → 새로운 값 → 레이어 재빌드
```

### 6.2 ccache (컴파일 캐시)

**작동 원리:**
```
첫 빌드:
  gcc -c main.c -o main.o
    ↓
  ccache: main.c 내용 해시 → 저장
    ↓
  ~/.ccache-w55rp20/해시값/main.o 저장

두 번째 빌드:
  gcc -c main.c -o main.o
    ↓
  ccache: main.c 해시 확인
    ↓
  캐시 히트! → 컴파일 생략, 저장된 .o 반환
    ↓
  10초 → 1초 (10배 빠름)
```

**설정:**
```bash
# 볼륨 마운트 (w55build.sh)
-v ~/.ccache-w55rp20:/root/.ccache

# ccache 설정 (Dockerfile)
ccache --set-config=max_size=2G
ccache --set-config=compression=true

# 통계 확인
docker run --rm -v ~/.ccache-w55rp20:/root/.ccache w55rp20:auto ccache -s
```

**효과:**
```
첫 빌드:     120초 (ccache miss)
두 번째:      15초 (ccache hit)
파일 1개 수정: 20초 (부분 hit)
```

### 6.3 tmpfs (RAM 빌드)

**작동 원리:**
```
일반 빌드 (SSD):
  cmake → 파일 쓰기 (디스크 I/O)
  make → 오브젝트 파일 생성 (디스크 I/O)
  총 시간: 120초

tmpfs 빌드 (RAM):
  cmake → 파일 쓰기 (메모리, 매우 빠름)
  make → 오브젝트 파일 생성 (메모리, 매우 빠름)
  총 시간: 80초 (1.5배 빠름)
```

**설정:**
```bash
# w55build.sh
--tmpfs /tmp/build:rw,exec,size=$TMPFS_SIZE

# 크기 조정
TMPFS_SIZE=8g ./build.sh   # 저사양
TMPFS_SIZE=32g ./build.sh  # 고사양
```

**장점:**
- 빌드 속도 1.5~2배 향상
- SSD 수명 연장 (쓰기 감소)

**단점:**
- 메모리 사용 (빌드 중 8~16GB)
- 빌드 산출물은 `/out`으로 복사 필요

---

## 7. 에러 핸들링

### 7.1 에러 종류별 처리

#### 호스트 (build.sh, w55build.sh)

```bash
# Docker 권한 오류
if ! docker ps >/dev/null 2>&1; then
    echo "ERROR: Docker permission denied"
    echo "Run: sudo usermod -aG docker $USER"
    exit 1
fi

# Docker 서비스 미실행
if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker daemon not running"
    echo "Run: sudo systemctl start docker"
    exit 1
fi

# 프로젝트 디렉토리 없음
if [ ! -d "$SRC_DIR" ]; then
    echo "ERROR: Project directory not found: $SRC_DIR"
    exit 1
fi

# CMakeLists.txt 없음
if [ ! -f "$SRC_DIR/CMakeLists.txt" ]; then
    echo "WARNING: No CMakeLists.txt in $SRC_DIR"
    read -p "Continue anyway? [y/N]: " confirm
    [ "$confirm" != "y" ] && exit 1
fi
```

#### 컨테이너 (docker-build.sh)

```bash
# set -euo pipefail
# - e: 에러 시 즉시 종료
# - u: 미정의 변수 사용 시 에러
# - o pipefail: 파이프 중 하나라도 실패하면 에러

# Git 클론 실패
if ! git clone --depth 1 "$REPO_URL" /workspace; then
    echo "ERROR: Failed to clone repository"
    exit 1
fi

# CMake 실패
if ! cmake -B /tmp/build -S /workspace; then
    echo "ERROR: CMake configuration failed"
    exit 1
fi

# 빌드 실패
if ! make -j$JOBS -C /tmp/build; then
    echo "ERROR: Build failed"
    exit 1
fi

# 산출물 없음
if ! ls /tmp/build/**/*.uf2 >/dev/null 2>&1; then
    echo "WARNING: No .uf2 files generated"
fi
```

### 7.2 Exit Code

```
0   - 성공
1   - 일반 오류
2   - CLI 파싱 오류 (잘못된 옵션)
126 - 권한 오류
127 - 명령어 없음
130 - Ctrl+C (사용자 중단)
```

### 7.3 에러 메시지 형식

```bash
# 형식: [LEVEL] 메시지
echo "ERROR: Docker permission denied"      # 치명적
echo "WARNING: No CMakeLists.txt found"     # 경고
echo "INFO: Using cached image"             # 정보
```

---

## 8. 확장 및 커스터마이징

### 8.1 새로운 CLI 옵션 추가

**예시: `--dry-run` 옵션 추가**

```bash
# build.sh

# 1. 변수 추가 (main 함수 시작 부분)
DRY_RUN=0

# 2. CLI 파싱에 추가
parse_cli_options() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            # ... 기존 옵션들
        esac
    done
}

# 3. 도움말에 추가
show_help() {
    cat <<EOF
  --dry-run              Show what would be done without executing
EOF
}

# 4. w55build.sh로 전달
export DRY_RUN

# 5. w55build.sh에서 사용
# w55build.sh
if [ "$DRY_RUN" = "1" ]; then
    echo "Would run: docker run ..."
    exit 0
fi
```

### 8.2 새로운 REFRESH 타겟 추가

**예시: Python 패키지 캐시 무효화**

```dockerfile
# Dockerfile

# 새 레이어 추가
ARG REFRESH_PYTHON_BUST=1
RUN pip3 install --upgrade pip && \
    pip3 install pyserial requests
```

```bash
# w55build.sh

convert_refresh_to_build_args() {
    case "$target" in
        python)
            REFRESH_PYTHON_BUST=$(date +%s)
            ;;
        # ... 기존 타겟들
    esac
}
```

```bash
# 사용
REFRESH="python" ./build.sh
```

### 8.3 새로운 빌드 타입 추가

**예시: MinSizeRel (크기 최적화 빌드)**

```bash
# build.sh

# CLI 파싱
case "$1" in
    --minsize)
        BUILD_TYPE="MinSizeRel"
        shift
        ;;
esac

# 도움말
--minsize              Minimum size release build
```

```bash
# docker-build.sh

# CMAKE_FLAGS는 이미 BUILD_TYPE 사용
cmake -B /tmp/build -S /workspace \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE
```

### 8.4 커스텀 Docker 이미지

**시나리오: ARM GCC 버전 변경**

```dockerfile
# Dockerfile

# 기존
RUN wget https://.../gcc-arm-none-eabi-14.2.rel1-x86_64-linux.tar.bz2

# 새 버전
RUN wget https://.../gcc-arm-none-eabi-15.0.rel1-x86_64-linux.tar.bz2 && \
    tar -xf gcc-arm-none-eabi-15.0.rel1-x86_64-linux.tar.bz2 -C /opt
ENV PATH="/opt/gcc-arm-none-eabi-15.0.rel1/bin:$PATH"
```

```bash
# 이미지 재빌드
docker buildx build --no-cache -t w55rp20:gcc15 .

# 사용
IMAGE=w55rp20:gcc15 ./w55build.sh
```

### 8.5 빌드 스크립트 커스터마이징

**시나리오: 빌드 전/후 훅**

```bash
# docker-build.sh

# 빌드 전 훅
if [ -f /workspace/.pre-build.sh ]; then
    echo "Running pre-build hook..."
    bash /workspace/.pre-build.sh
fi

# 빌드
make -j$JOBS -C /tmp/build

# 빌드 후 훅
if [ -f /workspace/.post-build.sh ]; then
    echo "Running post-build hook..."
    bash /workspace/.post-build.sh
fi
```

**사용자 프로젝트에서:**
```bash
# my-project/.pre-build.sh
#!/bin/bash
echo "Generating version header..."
git describe --tags > version.txt

# my-project/.post-build.sh
#!/bin/bash
echo "Signing firmware..."
sign-tool /tmp/build/App.uf2
```

---

## 9. 디버깅 가이드

### 9.1 VERBOSE 모드 활용

```bash
VERBOSE=1 ./build.sh
```

**출력:**
```
=== build.sh variables ===
SRC_DIR=./src
OUT_DIR=./out
JOBS=16
BUILD_TYPE=Release
...

=== w55build.sh variables ===
IMAGE=w55rp20:auto
TMPFS_SIZE=16g
...

=== Docker command ===
docker run --rm \
  -v /home/user/project:/workspace:rw \
  ...

=== Container environment ===
JOBS=16
BUILD_TYPE=Release
...

=== CMake output ===
-- The C compiler identification is GNU 14.2.0
...

=== Build output ===
[ 10%] Building C object ...
...

=== tmpfs usage ===
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           16G   2.1G   14G  14% /tmp/build
```

### 9.2 컨테이너 내부 디버깅

**대화형 쉘 진입:**
```bash
docker run --rm -it \
  -v $(pwd)/src:/workspace:rw \
  -v $(pwd)/out:/out:rw \
  --tmpfs /tmp/build:rw,exec,size=16g \
  --entrypoint bash \
  w55rp20:auto
```

**컨테이너 내부에서:**
```bash
# 환경 확인
env | sort
which arm-none-eabi-gcc
cmake --version
git --version

# 수동 빌드
cd /workspace
cmake -B /tmp/build -S .
make -j8 -C /tmp/build

# 산출물 확인
ls -lh /tmp/build/**/*.uf2
```

### 9.3 로그 분석

**빌드 로그 저장:**
```bash
./build.sh 2>&1 | tee build.log
```

**에러 추출:**
```bash
grep -i error build.log
grep -i warning build.log
grep "\|failed\|error" build.log
```

**타이밍 분석:**
```bash
# 각 단계 시간 측정
time docker buildx build -t w55rp20:auto .
time ./build.sh
```

### 9.4 Docker 이미지 분석

**레이어 확인:**
```bash
docker history w55rp20:auto
```

**크기 확인:**
```bash
docker images w55rp20:auto
```

**특정 레이어 검사:**
```bash
docker run --rm w55rp20:auto ls -lh /opt
docker run --rm w55rp20:auto du -sh /pico-sdk
```

### 9.5 빌드 실패 디버깅 체크리스트

```
□ VERBOSE=1로 상세 로그 확인
□ Docker 서비스 실행 중? (systemctl status docker)
□ 디스크 공간 충분? (df -h)
□ 메모리 충분? (free -h)
□ Docker 권한 있음? (docker ps)
□ 이미지 존재? (docker images | grep w55rp20)
□ 소스 코드 존재? (ls -l $SRC_DIR)
□ CMakeLists.txt 있음? (ls $SRC_DIR/CMakeLists.txt)
□ 인터넷 연결됨? (ping google.com)
□ ccache 정상? (docker run --rm -v ~/.ccache-w55rp20:/root/.ccache w55rp20:auto ccache -s)
□ 컨테이너 내부 확인? (docker run -it --entrypoint bash w55rp20:auto)
```

---

## 10. 기여 가이드

### 10.1 코드 스타일

**Bash 스타일:**
```bash
# 1. 함수명: snake_case
function build_project() {
    # ...
}

# 2. 변수명: UPPER_CASE (전역), lower_case (로컬)
GLOBAL_VAR="value"
local local_var="value"

# 3. 들여쓰기: 2 스페이스
if [ condition ]; then
  echo "indented"
fi

# 4. 중괄호 변수
echo "${VAR}"  # 
echo "$VAR"    # △ (간단한 경우 OK)

# 5. 에러 핸들링
set -euo pipefail

# 6. 주석
# 단일 줄 주석
: '
여러 줄 주석
'
```

**Dockerfile 스타일:**
```dockerfile
# 1. 각 레이어는 논리적 단위
RUN apt-get update && \
    apt-get install -y pkg1 pkg2 && \
    rm -rf /var/lib/apt/lists/*

# 2. ARG는 사용 직전에 선언
ARG REFRESH_SDK_BUST=1
RUN git clone ...

# 3. 환경 변수는 명확하게
ENV PATH="/opt/tool/bin:$PATH"

# 4. 라벨 추가
LABEL maintainer="your-email@example.com"
LABEL version="1.1.0"
```

### 10.2 테스트

**기능 추가 시 테스트 작성:**
```bash
# tests/test-new-feature.sh
#!/usr/bin/env bash
set -euo pipefail

# 1. 기본 동작
./build.sh --new-option
assert_success

# 2. 에러 케이스
./build.sh --new-option invalid-value
assert_failure

# 3. 통합 테스트
./build.sh --new-option value1 --other-option value2
assert_output_contains "expected text"
```

**실행:**
```bash
./tests/test-new-feature.sh
```

### 10.3 커밋 메시지

**형식:**
```
<type>: <subject>

<body>

```

**type:**
- `feat`: 새 기능
- `fix`: 버그 수정
- `docs`: 문서 변경
- `refactor`: 리팩토링
- `test`: 테스트 추가
- `chore`: 빌드/도구 변경

**예시:**
```
feat: Add --dry-run option for preview mode

- Add DRY_RUN variable to build.sh
- Show docker command without executing
- Update help text with new option

```

### 10.4 문서 업데이트

**변경 시 업데이트할 문서:**
```
변경 종류               업데이트 문서
──────────────────────────────────────────
새 CLI 옵션        → README.md
                   → claude/ADVANCED_OPTIONS.md
                   → build.sh --help

새 REFRESH 타겟    → README.md
                   → ARCHITECTURE.md

새 빌드 타입       → README.md
                   → BEGINNER_GUIDE.md

Dockerfile 변경    → ARCHITECTURE.md

버전 업데이트      → build.sh (SCRIPT_VERSION)
                   → README.md

버그 수정          → claude/ISSUES.md (해결 표시)
```

### 10.5 Pull Request 체크리스트

```
□ 코드 스타일 준수
□ shellcheck 통과 (./build.sh, ./w55build.sh)
□ 테스트 추가/수정
□ 모든 테스트 통과 (tests/*.sh)
□ 문서 업데이트
□ CHANGELOG 업데이트 (해당 시)
□ 커밋 메시지 명확
```

---

## 부록

### A. 전체 빌드 타임라인

```
첫 실행 (이미지 없음):
  0:00 - build.sh 시작
  0:01 - Docker 이미지 빌드 시작
  0:03 - Ubuntu 다운로드
  0:05 - apt 패키지 설치
  0:08 - ARM GCC 다운로드
  0:12 - CMake 다운로드
  0:15 - Pico SDK 클론
  0:20 - 이미지 빌드 완료
  0:20 - 컨테이너 시작
  0:21 - 소스 클론
  0:23 - CMake 설정
  0:24 - 빌드 시작
  0:27 - 빌드 완료
  0:27 - 산출물 복사
  0:28 - 완료!
  총: 28분

두 번째 실행 (이미지 있음, ccache warm):
  0:00 - build.sh 시작
  0:01 - 이미지 확인 (재사용)
  0:01 - 컨테이너 시작
  0:02 - 소스 업데이트 (git fetch)
  0:03 - CMake 설정
  0:03 - 빌드 시작 (ccache hit)
  0:05 - 빌드 완료
  0:05 - 산출물 복사
  0:06 - 완료!
  총: 2분
```

### B. 파일 크기 참고

```
스크립트:
  build.sh          ~25KB
  w55build.sh       ~15KB
  docker-build.sh   ~5KB
  entrypoint.sh     ~1KB
  Dockerfile        ~3KB

Docker 이미지:
  w55rp20:auto      ~1.1GB

빌드 산출물:
  App.uf2           ~512KB
  Boot.uf2          ~128KB

ccache (저장소):
  첫 빌드 후        ~200MB
  최대 크기         ~2GB
```

### C. 관련 링크

- **Pico SDK**: https://github.com/raspberrypi/pico-sdk
- **ARM GCC**: https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm
- **CMake**: https://cmake.org/
- **Docker**: https://docs.docker.com/
- **ccache**: https://ccache.dev/

---

## 라이선스

프로젝트 소스: https://github.com/WIZnet-ioNIC/W55RP20-S2E
