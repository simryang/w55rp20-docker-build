# 용어 사전

> W55RP20-S2E 프로젝트 용어 정리

작성일: 2026-01-21
버전: 1.0

---

## 목차

- [A](#a) | [B](#b) | [C](#c) | [D](#d) | [E](#e) | [F](#f) | [G](#g) | [H](#h)
- [I](#i) | [J](#j) | [K](#k) | [L](#l) | [M](#m) | [N](#n) | [O](#o) | [P](#p)
- [R](#r) | [S](#s) | [T](#t) | [U](#u) | [V](#v) | [W](#w)

---

## A

### AMD64
x86-64 아키텍처의 다른 이름. Intel 64와 호환.
- **예시**: `PLATFORM=linux/amd64`
- **관련**: ARM64, PLATFORM

### APT
Debian/Ubuntu의 패키지 관리자.
- **예시**: `apt install docker`
- **문서**: [INSTALL_LINUX.md](INSTALL_LINUX.md)

### ARM64
ARM 아키텍처의 64비트 버전. Apple Silicon(M1/M2)에서 사용.
- **예시**: Raspberry Pi 4, M1 Mac
- **관련**: AMD64, PLATFORM

### AUTO_BUILD_IMAGE
Docker 이미지가 없을 때 자동으로 빌드할지 결정하는 옵션.
- **기본값**: 1 (자동 빌드)
- **예시**: `AUTO_BUILD_IMAGE=0 ./build.sh`
- **문서**: [README.md](../README.md#자동-빌드)

### AWS IoT SDK
Amazon Web Services의 IoT 디바이스용 SDK. W55RP20-S2E에서 사용.
- **위치**: `libraries/aws-iot-device-sdk-embedded-C/`
- **문서**: [ARCHITECTURE.md](ARCHITECTURE.md)

---

## B

### BEGINNER_GUIDE.md
입문자를 위한 위키 수준의 가이드 문서.
- **대상**: Docker를 처음 사용하는 사용자
- **문서**: [BEGINNER_GUIDE.md](BEGINNER_GUIDE.md)

### BOOTSEL
RP2040/RP2350의 부트로더 모드. USB 드라이브로 마운트됨.
- **사용법**: BOOTSEL 버튼 누른 상태로 전원 연결
- **목적**: uf2 파일 업로드

### BUILD_LOGS.md
실제 빌드 로그 예제 모음.
- **포함**: 정상 빌드, 에러 케이스
- **문서**: [BUILD_LOGS.md](BUILD_LOGS.md)

### build.sh
초보자용 빌드 래퍼 스크립트.
- **특징**: 기본값 제공, 간단한 사용
- **예시**: `./build.sh`
- **관련**: w55build.sh

### build.config
로컬 빌드 설정 파일. git에 커밋되지 않음.
- **예시**:
  ```bash
  JOBS=16
  TMPFS_SIZE=24g
  ```
- **문서**: [README.md](../README.md#설정-파일)

---

## C

### ccache
컴파일러 캐시. 이전 컴파일 결과를 재사용하여 빌드 속도 향상.
- **히트율**: 첫 빌드 0%, 이후 ~95%
- **위치**: `/root/.ccache-w55rp20`
- **명령어**: `ccache -s` (통계 확인)

### CI/CD
Continuous Integration/Continuous Deployment. 자동 빌드 및 배포.
- **예시**: GitHub Actions
- **문서**: [EXAMPLES.md](EXAMPLES.md#예제-5-cicd---github-actions)

### CMAKE
크로스 플랫폼 빌드 시스템 생성 도구.
- **파일**: `CMakeLists.txt`
- **사용**: Pico SDK에서 사용

### CLEAN
빌드 전 기존 빌드 파일 삭제 옵션.
- **예시**: `./build.sh --clean`
- **효과**: `build/` 디렉토리 삭제 후 재빌드

### Container
Docker 컨테이너. 격리된 실행 환경.
- **생명주기**: 빌드 시작 → 실행 → 종료
- **명령어**: `docker ps` (실행 중인 컨테이너 목록)

---

## D

### Docker
컨테이너 기반 가상화 플랫폼.
- **용도**: 일관된 빌드 환경 제공
- **설치**: [INSTALL_LINUX.md](INSTALL_LINUX.md)

### Docker Desktop
macOS와 Windows용 Docker GUI 애플리케이션.
- **설치**: [INSTALL_MAC.md](INSTALL_MAC.md), [INSTALL_WINDOWS.md](INSTALL_WINDOWS.md)

### Docker Hub
Docker 이미지 저장소.
- **URL**: https://hub.docker.com/
- **참고**: 이 프로젝트는 로컬 빌드 사용

### Dockerfile
Docker 이미지 빌드 명세서.
- **위치**: 프로젝트 루트
- **포함**: Ubuntu 22.04 + ARM GCC + Pico SDK

### docker-build.sh
Docker 컨테이너 내부에서 실행되는 빌드 스크립트.
- **위치**: `/usr/local/bin/docker-build.sh`
- **호출**: Docker ENTRYPOINT

---

## E

### ENTRYPOINT
Docker 컨테이너 시작 시 실행되는 명령어.
- **파일**: `entrypoint.sh`
- **역할**: 환경 설정, git safe.directory 추가

### EXAMPLES.md
실전 예제 모음 문서.
- **포함**: 5개 예제 (기본 빌드, 설정 변경, 기능 추가 등)
- **문서**: [EXAMPLES.md](EXAMPLES.md)

---

## F

### FreeRTOS
실시간 운영체제(RTOS). W55RP20-S2E에서 사용.
- **위치**: `libraries/FreeRTOS-Kernel/`
- **용도**: 멀티태스킹

---

## G

### GCC
GNU Compiler Collection. C/C++ 컴파일러.
- **ARM용**: `arm-none-eabi-gcc`
- **버전**: 14.2.1
- **위치**: `/opt/toolchain/bin/`

### Git
분산 버전 관리 시스템.
- **명령어**: `git clone`, `git pull`
- **문제**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md#e002-git-ownership-오류)

### GitHub Actions
GitHub의 CI/CD 플랫폼.
- **설정**: `.github/workflows/`
- **예시**: [EXAMPLES.md](EXAMPLES.md#예제-5-cicd---github-actions)

### GLOSSARY.md
이 문서. 용어 사전.

### GPIO
General Purpose Input/Output. 범용 입출력 핀.
- **예시**: LED, 버튼 제어
- **문서**: [EXAMPLES.md](EXAMPLES.md#예제-3-기능-추가---led-상태-표시)

---

## H

### Homebrew
macOS용 패키지 관리자.
- **설치**: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- **문서**: [INSTALL_MAC.md](INSTALL_MAC.md)

---

## I

### IMAGE
Docker 이미지 이름.
- **기본값**: `w55rp20:auto`
- **예시**: `IMAGE=my-image ./build.sh`

### INSTALL_LINUX.md
Linux 설치 가이드.
- **대상**: Ubuntu, Debian, Fedora, Arch
- **문서**: [INSTALL_LINUX.md](INSTALL_LINUX.md)

### INSTALL_MAC.md
macOS 설치 가이드.
- **대상**: Intel Mac, Apple Silicon (M1/M2/M3)
- **문서**: [INSTALL_MAC.md](INSTALL_MAC.md)

### INSTALL_RASPBERRY_PI.md
Raspberry Pi 설치 가이드.
- **대상**: Pi 3/4/5
- **특징**: 메모리 최적화, Swap 설정
- **문서**: [INSTALL_RASPBERRY_PI.md](INSTALL_RASPBERRY_PI.md)

### INSTALL_WINDOWS.md
Windows 설치 가이드.
- **요구사항**: WSL 2
- **문서**: [INSTALL_WINDOWS.md](INSTALL_WINDOWS.md)

---

## J

### JOBS
병렬 빌드 작업 수.
- **기본값**: CPU 코어 수
- **예시**: `JOBS=8 ./build.sh`
- **권장**: CPU 코어 수와 동일

---

## L

### LED
Light-Emitting Diode. 발광 다이오드.
- **온보드**: GPIO 25
- **예시**: [EXAMPLES.md](EXAMPLES.md#예제-3-기능-추가---led-상태-표시)

---

## M

### mbedtls
암호화 라이브러리. TLS/SSL 지원.
- **위치**: `libraries/mbedtls/`
- **용도**: HTTPS, 보안 통신

### Minicom
Linux 시리얼 통신 터미널 프로그램.
- **사용법**: `minicom -D /dev/ttyACM0 -b 115200`
- **종료**: Ctrl+A, X

---

## O

### OUT_DIR
빌드 산출물 출력 디렉토리.
- **기본값**: `./out`
- **예시**: `OUT_DIR=/custom/path ./build.sh`

### overlay2
Docker 스토리지 드라이버. 권장 드라이버.
- **확인**: `docker info | grep "Storage Driver"`

---

## P

### Pico SDK
Raspberry Pi Pico용 소프트웨어 개발 키트.
- **위치**: `/opt/pico-sdk` (Docker 내부)
- **버전**: 2.1.0
- **GitHub**: https://github.com/raspberrypi/pico-sdk

### PLATFORM
Docker 이미지 플랫폼 아키텍처.
- **기본값**: `linux/amd64`
- **예시**: `PLATFORM=linux/arm64`

---

## R

### README.md
프로젝트 메인 문서. 빠른 시작 가이드.
- **포함**: 설치, 빌드, 사용법
- **문서**: [README.md](../README.md)

### REFRESH
Docker 캐시 무효화 옵션.
- **값**: apt, sdk, cmake, gcc, toolchain, all
- **예시**: `REFRESH="toolchain" ./build.sh`
- **문서**: [README.md](../README.md#refresh-옵션)

### REPO_URL
소스 코드 저장소 URL.
- **기본값**: https://github.com/WIZnet-ioNIC/W55RP20-S2E.git
- **변경**: `w55build.sh` 편집

### RP2040
Raspberry Pi Foundation의 마이크로컨트롤러.
- **사양**: Dual ARM Cortex-M0+, 264KB RAM
- **사용**: Raspberry Pi Pico

### RP2350
RP2040의 후속 모델 (2023).
- **개선**: ARM Cortex-M33, 520KB RAM

---

## S

### SDK
Software Development Kit. 소프트웨어 개발 키트.
- **예시**: Pico SDK, AWS IoT SDK

### SSH
Secure Shell. 원격 접속 프로토콜.
- **사용**: Raspberry Pi 원격 빌드
- **명령어**: `ssh pi@192.168.0.100`

### Submodule
Git 서브모듈. 외부 저장소를 포함.
- **예시**: FreeRTOS, Pico SDK
- **업데이트**: `git submodule update --init --recursive`

### Swap
스왑 메모리. 디스크를 RAM처럼 사용.
- **용도**: 메모리 부족 시 사용
- **권장**: Raspberry Pi에서 필요
- **문서**: [INSTALL_RASPBERRY_PI.md](INSTALL_RASPBERRY_PI.md#swap-설정)

---

## T

### tmpfs
메모리 기반 임시 파일 시스템.
- **용도**: 빌드 속도 향상
- **크기**: TMPFS_SIZE 옵션으로 설정
- **위치**: `/work/src/build` (Docker 내부)

### TMPFS_SIZE
tmpfs 크기 설정.
- **기본값**: 24g
- **예시**: `TMPFS_SIZE=16g ./build.sh`
- **0**: tmpfs 비활성화 (메모리 절약)

### TROUBLESHOOTING.md
문제 해결 가이드.
- **포함**: 에러 카탈로그, 해결 방법
- **문서**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## U

### UART
Universal Asynchronous Receiver-Transmitter. 직렬 통신 인터페이스.
- **기본 속도**: 115200 bps
- **예시**: [EXAMPLES.md](EXAMPLES.md#예제-2-설정-변경---uart-속도-수정)

### Ubuntu
Debian 기반 Linux 배포판.
- **권장 버전**: 22.04 LTS
- **문서**: [INSTALL_LINUX.md](INSTALL_LINUX.md)

### uf2
USB Flashing Format. RP2040/RP2350용 펌웨어 파일 형식.
- **사용법**: BOOTSEL 모드에서 드래그 앤 드롭
- **위치**: `out/App.uf2`

### UPDATE_REPO
소스 업데이트 여부.
- **기본값**: 0 (업데이트 안 함)
- **1**: `git pull` 실행

---

## V

### VERBOSE
상세 로그 출력 옵션.
- **예시**: `./build.sh --verbose`
- **효과**: 모든 변수 및 명령어 출력

### VS Code
Visual Studio Code. 마이크로소프트의 텍스트 에디터.
- **확장**: WSL, Remote-SSH
- **문서**: [INSTALL_WINDOWS.md](INSTALL_WINDOWS.md#vs-code)

---

## W

### W55RP20
WIZnet의 Ethernet + RP2040 통합 칩.
- **특징**: Hardwired TCP/IP (W5500) + RP2040

### W55RP20-S2E
W55RP20 기반 Serial-to-Ethernet 변환기 프로젝트.
- **저장소**: https://github.com/WIZnet-ioNIC/W55RP20-S2E

### w55build.sh
실제 빌드 로직을 포함하는 스크립트.
- **특징**: 모든 옵션 노출, 정밀 제어
- **호출**: build.sh가 내부적으로 호출

### WIZnet
Ethernet 칩 제조사.
- **제품**: W5500, W5100S, W55RP20
- **웹사이트**: https://www.wiznet.io/

### WSL
Windows Subsystem for Linux. Windows에서 Linux 실행.
- **버전**: WSL 2 권장
- **문서**: [INSTALL_WINDOWS.md](INSTALL_WINDOWS.md)

---

## 기타

### .build-config
build.config의 다른 이름. 둘 다 사용 가능.

### .gitignore
Git이 무시할 파일 목록.
- **포함**: `out/`, `build/`, `build.config`

### ccache 히트율
캐시에서 재사용된 컴파일 비율.
- **첫 빌드**: 0%
- **이후**: ~95%

---

## 약어

| 약어 | 의미 | 설명 |
|------|------|------|
| API | Application Programming Interface | 애플리케이션 인터페이스 |
| ARM | Advanced RISC Machines | RISC 기반 프로세서 아키텍처 |
| AWS | Amazon Web Services | 아마존 클라우드 서비스 |
| CICD | Continuous Integration/Deployment | 지속적 통합/배포 |
| CLI | Command Line Interface | 명령줄 인터페이스 |
| CPU | Central Processing Unit | 중앙처리장치 |
| GPIO | General Purpose Input/Output | 범용 입출력 |
| GUI | Graphical User Interface | 그래픽 사용자 인터페이스 |
| I/O | Input/Output | 입출력 |
| IoT | Internet of Things | 사물인터넷 |
| LED | Light-Emitting Diode | 발광 다이오드 |
| LTS | Long Term Support | 장기 지원 버전 |
| OOM | Out Of Memory | 메모리 부족 |
| OS | Operating System | 운영체제 |
| RAM | Random Access Memory | 램 |
| RISC | Reduced Instruction Set Computer | 축소 명령 집합 컴퓨터 |
| RTOS | Real-Time Operating System | 실시간 운영체제 |
| SDK | Software Development Kit | 소프트웨어 개발 키트 |
| SSH | Secure Shell | 보안 셸 |
| SSL | Secure Sockets Layer | 보안 소켓 계층 |
| TLS | Transport Layer Security | 전송 계층 보안 |
| UART | Universal Asynchronous Receiver-Transmitter | 범용 비동기 송수신기 |
| UF2 | USB Flashing Format | USB 플래싱 형식 |
| URL | Uniform Resource Locator | 통합 자원 위치 지정자 |
| USB | Universal Serial Bus | 범용 직렬 버스 |
| WSL | Windows Subsystem for Linux | Linux용 Windows 하위 시스템 |

---

## 관련 문서

- [README.md](../README.md) - 프로젝트 개요
- [BEGINNER_GUIDE.md](BEGINNER_GUIDE.md) - 초보자 가이드
- [ARCHITECTURE.md](ARCHITECTURE.md) - 내부 구조
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - 문제 해결
- [EXAMPLES.md](EXAMPLES.md) - 실전 예제

---

**검토**: 사용자
**버전**: 1.0
**최종 수정**: 2026-01-21

**피드백**: 누락된 용어가 있거나 설명이 불명확하면 GitHub Issues에 알려주세요!
