# syntax=docker/dockerfile:1
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# ===== Pins =====
ARG CMAKE_VERSION=3.28.3
ARG ARM_GNU_TOOLCHAIN_VERSION=14.2.rel1
ARG PICO_SDK_REF=2.2.0

# buildx가 주입하지만, legacy 대비 기본값도 둠
ARG TARGETARCH=amd64

# ===== Standard paths =====
ENV PICO_SDK_PATH=/opt/pico-sdk
ENV PICO_TOOLCHAIN_PATH=/opt/toolchain
ENV PATH="/opt/toolchain/bin:/usr/local/bin:${PATH}"

WORKDIR /opt

# ===== Base deps =====
RUN apt-get update && apt-get install -y --no-install-recommends \
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
RUN set -eux; \
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
RUN set -eux; \
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
RUN git clone https://github.com/raspberrypi/pico-sdk.git /opt/pico-sdk && \
    cd /opt/pico-sdk && \
    git fetch --tags && \
    git checkout "${PICO_SDK_REF}" && \
    git submodule update --init --recursive

# ===== picotool (optional but useful for UF2 load) =====
RUN git clone https://github.com/raspberrypi/picotool.git /opt/picotool && \
    cd /opt/picotool && \
    git submodule update --init --recursive && \
    cmake -S . -B build -G Ninja && \
    cmake --build build && \
    cmake --install build && \
    rm -rf /opt/picotool

# ===== Entrypoint =====
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

