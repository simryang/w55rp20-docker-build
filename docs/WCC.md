---
## Metadata

**Title (EN)**: W55RP20 Docker Build System - 3-Minute Firmware Build Solution

**Summary (EN)**: Docker-based all-in-one build system for WIZnet W55RP20. Build RP2040 Ethernet firmware in 3 steps without complex environment setup. 12-second builds with ccache. Cross-platform support for Windows/Linux/macOS.

**Hardware**:
- W55RP20 Board (RP2040 + Ethernet)
- PC: Windows 10/11, Linux, or macOS
- RAM: 8GB minimum, 16GB recommended
- Disk: 10GB free space

**Software**:
- Docker Desktop (Windows/Linux/macOS)
- Git
- PowerShell (Windows) or Bash (Linux/macOS)

**Repository**: https://github.com/simryang/w55rp20-docker-build

**Keywords**: W55RP20, Docker, RP2040, Ethernet, Embedded Build, Firmware Development, Cross-Platform, CMake, ARM Toolchain, Pico SDK, WIZnet

---

# W55RP20 Docker Build System - Build Firmware in 3 Minutes

## What is W55RP20 Docker Build System?

The **W55RP20 Docker Build System** is an all-in-one solution for building WIZnet W55RP20 (RP2040 + Ethernet) firmware without complex environment setup.

Traditional embedded development requires manual installation of compilers, SDKs, and build tools—a time-consuming process that varies across operating systems. This Docker-based system eliminates these hassles, enabling anyone to build firmware in just **3 simple steps**.

### Why Do You Need This?

**Before (Traditional Method):**
- ❌ 1-2 hours of manual environment setup
- ❌ Different setup for each OS (Windows/Linux/macOS)
- ❌ Version conflicts and dependency issues
- ❌ "Works on my machine" syndrome

**After (Docker Build System):**
- ✅ **6 minutes** first build (includes image download)
- ✅ **12 seconds** subsequent builds with ccache
- ✅ Same setup across all operating systems
- ✅ Zero dependency conflicts
- ✅ Just run one script!

---

## Key Features

### ⚡ Ultra-Fast Builds
- First run: ~6 minutes (image download + build)
- Subsequent runs: **12 seconds** using ccache
- Parallel compilation with 16 jobs

### 🎯 Beginner-Friendly
- No Docker or Linux knowledge required
- Interactive mode with clear guidance
- Automatic environment setup

### 🔄 True Cross-Platform
- Windows 10/11 with PowerShell
- Linux (Ubuntu, Debian, etc.)
- macOS (Intel & Apple Silicon)

### 📦 Pre-Built Docker Image
- 2.44GB image ready on DockerHub
- No need to build Docker image locally
- Download once, use forever

---

## Quick Start: 3 Steps to Build

### Step 1: Clone Repository

Open PowerShell (Windows) or Terminal (Linux/macOS):

```powershell
git clone https://github.com/simryang/w55rp20-docker-build.git
cd w55rp20-docker-build
```

### Step 2: Run Interactive Build

**Windows:**
```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1 -Interactive
```

**Linux/macOS:**
```bash
./build.sh
```

![Build Command](docs/build_command_1.png)
*Docker Desktop verification and build start*

### Step 3: Select Options

**Choose container type:** Enter `1` (Linux container recommended)

![Container Selection](docs/build_command_2.png)
*Interactive menu for container selection*

**Confirm build:** Press `y` or just Enter

The rest is **fully automatic**!

---

## Build Process Visualization

### Automatic Image Download & Build

![Build Progress](docs/build_command_3.png)
*Script automatically downloads Docker image (first time only) and builds firmware*

### System Resource Usage

#### Before Build
![CPU Before Build](docs/cpu_before_build.png)
*System at idle state*

#### During Initialization
![CPU Build Start](docs/cpu_build_1.png)
*Docker container starting*

#### During Compilation
![CPU During Build](docs/cpu_build_2.png)
*Multi-core CPU utilization with parallel build*

**Resource Characteristics:**
- **CPU**: All cores utilized (16 parallel jobs)
- **Memory**: Builds in RAM using tmpfs (protects SSD lifespan)
- **Disk**: Minimal I/O with build cache

---

## Build Results

### Success Message

![Build Success](docs/build_success.png)
*Build completion message with artifact location*

### Generated Files

![Build Output](docs/build_out_result.png)
*Firmware files in `out` directory*

**Output Files:**
- `*.uf2` - W55RP20 firmware (drag-and-drop to board)
- `*.elf` - Debugging executable
- `*.bin` - Binary firmware image
- `*.hex` - HEX format firmware

---

## How to Upload Firmware to W55RP20

### Simple 3-Step Upload

1. **Enter BOOTSEL mode**
   - Hold BOOTSEL button on W55RP20 board
   - Connect USB cable
   - Release button when PC detects RPI-RP2 drive

2. **Copy firmware**
   - Drag `*.uf2` file from `out` folder
   - Drop to RPI-RP2 drive

3. **Automatic flash**
   - Board reboots automatically
   - Firmware flashes in seconds
   - Ready to run!

---

## Build Time Comparison

| Task | Traditional | Docker System |
|------|-------------|---------------|
| Environment Setup | 1-2 hours | Automatic |
| First Build | 3-5 min | 6 min |
| Second Build | 3-5 min | **12 sec** ⚡ |
| OS Compatibility | Manual per OS | Universal |

**Time Saved**: From hours of setup to minutes of work!

---

## Common Use Cases

### 1. Individual Developers
- Skip environment setup headaches
- Focus on code, not configuration
- Quick iteration with 12-second builds

### 2. Team Development
- Everyone uses identical environment
- No "works on my machine" issues
- Easy onboarding for new members

### 3. Education & Workshops
- Students build firmware instantly
- No time wasted on setup
- More time for learning

### 4. CI/CD Pipelines
- Integrate with GitHub Actions
- Automated firmware builds
- Consistent results every time

---

## Build Your Own Project

Want to build your own W55RP20 project? Just specify the path:

**Windows:**
```powershell
.\build.ps1 -Project "C:\Users\yourname\my-w55rp20-project"
```

**Linux/macOS:**
```bash
./build.sh --project /path/to/your/project
```

### Debug Build Option

```powershell
.\build.ps1 -BuildType Debug
```

---

## Frequently Asked Questions (FAQ)

### Q: Do I need to install ARM compiler or SDK?
**A:** No! Everything is included in the Docker image.

### Q: How much disk space is needed?
**A:** About 10GB total (2.5GB Docker image + build cache).

### Q: Can I use this offline after initial download?
**A:** Yes! Once the Docker image is downloaded, you can build offline.

### Q: What if I get PowerShell execution policy error?
**A:** Use `powershell -ExecutionPolicy Bypass` as shown in the guide.

### Q: Does this work on Apple Silicon Macs?
**A:** Yes! Docker handles the architecture automatically.

---

## Technical Stack

| Component | Version |
|-----------|---------|
| Container OS | Ubuntu 22.04 |
| Build System | CMake 3.28 + Ninja |
| Compiler | ARM GNU Toolchain 14.2 |
| SDK | Raspberry Pi Pico SDK 2.2.0 |
| Cache | ccache (tmpfs-based) |

---

## Get Started Now!

Ready to build W55RP20 firmware in 3 minutes?

1. **Install Docker Desktop**: https://www.docker.com/products/docker-desktop
2. **Clone Repository**: https://github.com/simryang/w55rp20-docker-build
3. **Run Build Script**: One command to build!

### Resources

- **GitHub**: https://github.com/simryang/w55rp20-docker-build
- **DockerHub**: https://hub.docker.com/r/simryang/w55rp20
- **W55RP20 Product**: https://www.wiznet.io/product-item/w55rp20/
- **Documentation**: Full user guide in repository

---

## Conclusion

The W55RP20 Docker Build System transforms embedded development:

- ⚡ **12-second builds** instead of minutes
- 🌍 **One solution** for all operating systems
- 🎯 **Zero setup** for new developers
- 🚀 **Production-ready** for teams and CI/CD

Stop wasting time on environment setup. Start building firmware today!

---

**License**: MIT License - Free to use, modify, and distribute

**Author**: simryang
**Version**: v1.2.0-unified
**Last Updated**: January 2026

**Tags**: #W55RP20 #Docker #Embedded #RP2040 #Ethernet #WIZnet #Firmware #Build #Automation #CrossPlatform

---
---
---

# W55RP20 Docker 빌드 시스템으로 3분 안에 펌웨어 빌드하기

## W55RP20 Docker 빌드 시스템이란?

**W55RP20 Docker 빌드 시스템**은 복잡한 환경 설정 없이 WIZnet W55RP20(RP2040 + Ethernet) 펌웨어를 빌드할 수 있는 올인원 솔루션입니다.

전통적인 임베디드 개발은 컴파일러, SDK, 빌드 도구를 수동으로 설치해야 하며, 운영체제마다 다른 설정이 필요합니다. 이 Docker 기반 시스템은 이러한 번거로움을 없애고, 누구나 **단 3단계**로 펌웨어를 빌드할 수 있게 해줍니다.

### 왜 필요한가요?

**이전 방식 (전통적 방법):**
- ❌ 1-2시간의 수동 환경 설정
- ❌ OS별로 다른 설정 필요 (Windows/Linux/macOS)
- ❌ 버전 충돌 및 의존성 문제
- ❌ "내 컴퓨터에서는 되는데..." 문제

**지금 (Docker 빌드 시스템):**
- ✅ **6분** 첫 빌드 (이미지 다운로드 포함)
- ✅ **12초** 이후 빌드 (ccache 사용)
- ✅ 모든 OS에서 동일한 환경
- ✅ 의존성 충돌 제로
- ✅ 스크립트 하나로 끝!

---

## 주요 특징

### ⚡ 초고속 빌드
- 첫 실행: 약 6분 (이미지 다운로드 + 빌드)
- 이후 실행: **12초** (ccache 활용)
- 16개 작업 병렬 컴파일

### 🎯 초보자 친화적
- Docker, Linux 지식 불필요
- 대화형 모드로 명확한 가이드
- 자동 환경 설정

### 🔄 진정한 크로스 플랫폼
- Windows 10/11 (PowerShell)
- Linux (Ubuntu, Debian 등)
- macOS (Intel & Apple Silicon)

### 📦 사전 빌드된 Docker 이미지
- DockerHub에 2.44GB 이미지 준비
- 로컬 빌드 불필요
- 한 번 다운로드, 영구 사용

---

## 빠른 시작: 3단계로 빌드하기

### 1단계: 저장소 클론

PowerShell(Windows) 또는 터미널(Linux/macOS)을 열고:

```powershell
git clone https://github.com/simryang/w55rp20-docker-build.git
cd w55rp20-docker-build
```

### 2단계: 대화형 빌드 실행

**Windows:**
```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1 -Interactive
```

**Linux/macOS:**
```bash
./build.sh
```

![빌드 명령](docs/build_command_1.png)
*Docker Desktop 확인 및 빌드 시작*

### 3단계: 옵션 선택

**컨테이너 타입 선택:** `1` 입력 (Linux 컨테이너 권장)

![컨테이너 선택](docs/build_command_2.png)
*대화형 메뉴로 컨테이너 선택*

**빌드 확인:** `y` 입력 또는 그냥 Enter

나머지는 **완전 자동**으로 진행됩니다!

---

## 빌드 과정 시각화

### 자동 이미지 다운로드 및 빌드

![빌드 진행](docs/build_command_3.png)
*스크립트가 자동으로 Docker 이미지 다운로드(최초 1회) 및 펌웨어 빌드*

### 시스템 리소스 사용량

#### 빌드 전
![빌드 전 CPU](docs/cpu_before_build.png)
*시스템 유휴 상태*

#### 초기화 중
![빌드 시작](docs/cpu_build_1.png)
*Docker 컨테이너 시작*

#### 컴파일 중
![빌드 진행 중](docs/cpu_build_2.png)
*병렬 빌드로 멀티코어 CPU 활용*

**리소스 특징:**
- **CPU**: 모든 코어 활용 (16개 병렬 작업)
- **메모리**: tmpfs로 RAM에서 빌드 (SSD 수명 보호)
- **디스크**: 빌드 캐시로 I/O 최소화

---

## 빌드 결과물

### 성공 메시지

![빌드 성공](docs/build_success.png)
*빌드 완료 메시지와 산출물 위치 안내*

### 생성된 파일

![빌드 산출물](docs/build_out_result.png)
*`out` 디렉토리의 펌웨어 파일*

**산출 파일:**
- `*.uf2` - W55RP20 펌웨어 (보드에 드래그앤드롭)
- `*.elf` - 디버깅용 실행 파일
- `*.bin` - 바이너리 펌웨어 이미지
- `*.hex` - HEX 포맷 펌웨어

---

## W55RP20에 펌웨어 업로드하기

### 간단한 3단계 업로드

1. **BOOTSEL 모드 진입**
   - W55RP20 보드의 BOOTSEL 버튼 누른 상태 유지
   - USB 케이블 연결
   - PC가 RPI-RP2 드라이브로 인식하면 버튼 해제

2. **펌웨어 복사**
   - `out` 폴더에서 `*.uf2` 파일 선택
   - RPI-RP2 드라이브로 드래그앤드롭

3. **자동 플래시**
   - 보드가 자동으로 재부팅
   - 몇 초 안에 펌웨어 플래시 완료
   - 바로 실행!

---

## 빌드 시간 비교

| 작업 | 기존 방식 | Docker 시스템 |
|------|----------|--------------|
| 환경 설정 | 1-2시간 | 자동 |
| 첫 빌드 | 3-5분 | 6분 |
| 두 번째 빌드 | 3-5분 | **12초** ⚡ |
| OS 호환성 | OS별 수동 설정 | 통일 |

**절약된 시간**: 시간 단위 설정에서 분 단위 작업으로!

---

## 일반적인 사용 사례

### 1. 개인 개발자
- 환경 설정 문제 건너뛰기
- 코드에만 집중, 설정은 잊기
- 12초 빌드로 빠른 반복

### 2. 팀 개발
- 모두가 동일한 환경 사용
- "내 컴퓨터에서는 되는데" 문제 제거
- 신규 팀원 온보딩 간편화

### 3. 교육 및 워크숍
- 학생들이 즉시 펌웨어 빌드
- 설정에 시간 낭비 없음
- 학습에 더 많은 시간 투자

### 4. CI/CD 파이프라인
- GitHub Actions 통합
- 자동화된 펌웨어 빌드
- 매번 일관된 결과

---

## 나만의 프로젝트 빌드하기

자신의 W55RP20 프로젝트를 빌드하고 싶으신가요? 경로만 지정하세요:

**Windows:**
```powershell
.\build.ps1 -Project "C:\Users\yourname\my-w55rp20-project"
```

**Linux/macOS:**
```bash
./build.sh --project /path/to/your/project
```

### 디버그 빌드 옵션

```powershell
.\build.ps1 -BuildType Debug
```

---

## 자주 묻는 질문 (FAQ)

### Q: ARM 컴파일러나 SDK를 설치해야 하나요?
**A:** 아니요! 모든 것이 Docker 이미지에 포함되어 있습니다.

### Q: 얼마나 많은 디스크 공간이 필요한가요?
**A:** 총 약 10GB (Docker 이미지 2.5GB + 빌드 캐시).

### Q: 최초 다운로드 후 오프라인에서 사용할 수 있나요?
**A:** 네! Docker 이미지를 다운로드하면 오프라인 빌드 가능합니다.

### Q: PowerShell 실행 정책 오류가 발생하면?
**A:** 가이드처럼 `powershell -ExecutionPolicy Bypass`를 사용하세요.

### Q: Apple Silicon Mac에서 작동하나요?
**A:** 네! Docker가 자동으로 아키텍처를 처리합니다.

---

## 기술 스택

| 구성 요소 | 버전 |
|---------|------|
| 컨테이너 OS | Ubuntu 22.04 |
| 빌드 시스템 | CMake 3.28 + Ninja |
| 컴파일러 | ARM GNU Toolchain 14.2 |
| SDK | Raspberry Pi Pico SDK 2.2.0 |
| 캐시 | ccache (tmpfs 기반) |

---

## 지금 바로 시작하세요!

3분 안에 W55RP20 펌웨어를 빌드할 준비가 되셨나요?

1. **Docker Desktop 설치**: https://www.docker.com/products/docker-desktop
2. **저장소 클론**: https://github.com/simryang/w55rp20-docker-build
3. **빌드 스크립트 실행**: 한 줄 명령으로 빌드!

### 리소스

- **GitHub**: https://github.com/simryang/w55rp20-docker-build
- **DockerHub**: https://hub.docker.com/r/simryang/w55rp20
- **W55RP20 제품**: https://www.wiznet.io/product-item/w55rp20/
- **문서**: 저장소의 전체 사용자 가이드

---

## 결론

W55RP20 Docker 빌드 시스템이 임베디드 개발을 변화시킵니다:

- ⚡ 수분이 아닌 **12초 빌드**
- 🌍 모든 OS에 **하나의 솔루션**
- 🎯 신규 개발자를 위한 **제로 설정**
- 🚀 팀 및 CI/CD를 위한 **프로덕션 준비 완료**

환경 설정에 시간 낭비하지 마세요. 오늘 바로 펌웨어를 빌드하세요!

---

**라이선스**: MIT License - 자유롭게 사용, 수정, 배포 가능

**작성자**: simryang
**버전**: v1.2.0-unified
**최종 업데이트**: 2026년 1월

**태그**: #W55RP20 #Docker #임베디드 #RP2040 #Ethernet #WIZnet #펌웨어 #빌드 #자동화 #크로스플랫폼
