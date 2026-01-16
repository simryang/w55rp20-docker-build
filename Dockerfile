# syntax=docker/dockerfile:1
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# ===== Pins =====
ARG CMAKE_VERSION=3.28.3
ARG ARM_GNU_TOOLCHAIN_VERSION=14.2.rel1
ARG PICO_SDK_REF=2.2.0

# Cache-bust switches (build.sh의 REFRESH=...에서 주입)
# - 기본값(0)일 때는 캐시를 최대한 재사용
# - 값이 바뀌면 "해당 RUN 단계"부터 재실행되어, 원하는 부분만 refresh 가능
# - REFRESH="toolchain"은 build.sh에서 CMAKE+GCC로 변환되어 들어옴 (별칭)
ARG REFRESH_APT=0
ARG REFRESH_SDK=0
ARG REFRESH_CMAKE=0
ARG REFRESH_GCC=0

# buildx가 주입하지만, legacy 대비 기본값도 둠
ARG TARGETARCH=amd64

# ===== Standard paths =====
ENV PICO_SDK_PATH=/opt/pico-sdk
ENV PICO_TOOLCHAIN_PATH=/opt/toolchain
ENV PATH="/opt/toolchain/bin:/usr/local/bin:${PATH}"

WORKDIR /opt

# ===== Base deps =====
# NOTE: REFRESH_APT 값이 바뀌면 이 레이어부터 캐시가 무효화됩니다.
RUN echo "REFRESH_APT=$REFRESH_APT" && \
    apt-get update && apt-get install -y --no-install-recommends \
    astyle \
    srecord \
    file \
    time \
    ca-certificates \
    ccache \
    curl \
    git \
    unzip \
    xz-utils \
    tar \
    python3 \
    python-is-python3 \
    ninja-build \
    build-essential \
    pkg-config \
    libusb-1.0-0-dev \
    udev \
    gdb-multiarch \
    openocd \
    rsync \
    && rm -rf /var/lib/apt/lists/*

# ===== CMake >= 3.28 (arch-aware) =====
RUN echo "REFRESH_CMAKE=$REFRESH_CMAKE" && \
    set -eux; \
    case "$TARGETARCH" in \
      amd64) CMAKE_ARCH="x86_64" ;; \
      arm64) CMAKE_ARCH="aarch64" ;; \
      *) echo "Unsupported TARGETARCH=$TARGETARCH"; exit 1 ;; \
    esac; \
    mkdir -p /opt/cmake; \
    curl -fsSL -o /tmp/cmake.tar.gz \
      "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-${CMAKE_ARCH}.tar.gz"; \
    tar -xzf /tmp/cmake.tar.gz -C /opt/cmake --strip-components=1; \
    rm -f /tmp/cmake.tar.gz; \
    ln -sf /opt/cmake/bin/cmake /usr/local/bin/cmake; \
    ln -sf /opt/cmake/bin/ctest /usr/local/bin/ctest; \
    ln -sf /opt/cmake/bin/cpack /usr/local/bin/cpack

# ===== Arm GNU Toolchain 14.2.rel1 (arch-aware) =====
RUN echo "REFRESH_GCC=$REFRESH_GCC" && \
    set -eux; \
    case "$TARGETARCH" in \
      amd64) HOST_ARCH="x86_64" ;; \
      arm64) HOST_ARCH="aarch64" ;; \
      *) echo "Unsupported TARGETARCH=$TARGETARCH"; exit 1 ;; \
    esac; \
    curl -fsSL -o /tmp/armgnu.tar.xz \
      "https://developer.arm.com/-/media/Files/downloads/gnu/${ARM_GNU_TOOLCHAIN_VERSION}/binrel/arm-gnu-toolchain-${ARM_GNU_TOOLCHAIN_VERSION}-${HOST_ARCH}-arm-none-eabi.tar.xz"; \
    tar -xJf /tmp/armgnu.tar.xz -C /opt; \
    rm -f /tmp/armgnu.tar.xz; \
    TOOLCHAIN_DIR="$(ls -d /opt/arm-gnu-toolchain-* | head -n 1)"; \
    mkdir -p /opt/toolchain; \
    cp -a "${TOOLCHAIN_DIR}/." /opt/toolchain; \
    rm -rf "${TOOLCHAIN_DIR}"

# ===== Pico SDK (tool-side reference install; also used by cmake import patterns) =====
RUN echo "REFRESH_SDK=$REFRESH_SDK" && \
    git clone --depth 1 --branch "${PICO_SDK_REF}" https://github.com/raspberrypi/pico-sdk.git /opt/pico-sdk && \
    cd /opt/pico-sdk && \
    git submodule update --init --recursive

# ===== picotool (optional but useful for UF2 load) =====
RUN echo "REFRESH_SDK=$REFRESH_SDK" && \
    git clone https://github.com/raspberrypi/picotool.git /opt/picotool && \
    cd /opt/picotool && \
    git submodule update --init --recursive && \
    cmake -S . -B build -G Ninja && \
    cmake --build build && \
    cmake --install build && \
    rm -rf /opt/picotool

# ===== Entrypoint & Build runner =====
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker-build.sh /usr/local/bin/docker-build.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/docker-build.sh

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

