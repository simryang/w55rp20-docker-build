# W55RP20 Docker 빌드 시스템으로 3분 안에 펌웨어 빌드하기

## 프로젝트 개요

WIZnet W55RP20은 Ethernet 기능이 내장된 RP2040 기반 마이크로컨트롤러입니다. 하지만 개발 환경 설정이 복잡하고 OS마다 다른 설정이 필요해 초보자들이 어려움을 겪곤 합니다.

이 프로젝트는 **Docker를 활용한 올인원 빌드 시스템**으로, 복잡한 개발 환경 설정 없이 단 3단계만으로 W55RP20 펌웨어를 빌드할 수 있게 해줍니다.

### 주요 특징

- ⚡ **초고속 빌드**: 첫 실행 6분 → 이후 12초 (ccache 활용)
- 🎯 **초보자 친화적**: Docker, Linux 지식 불필요
- 🔄 **크로스 플랫폼**: Windows, Linux, macOS 모두 지원
- 📦 **사전 빌드된 이미지**: DockerHub에서 즉시 다운로드
- 🤖 **완전 자동화**: 대화형 모드로 쉽게 선택

### 기술 스택

| 구성 요소 | 버전 |
|---------|------|
| Docker | Desktop for Windows/Linux/Mac |
| 컨테이너 OS | Ubuntu 22.04 |
| 빌드 시스템 | CMake 3.28 + Ninja |
| 컴파일러 | ARM GNU Toolchain 14.2 |
| SDK | Raspberry Pi Pico SDK 2.2.0 |
| 캐싱 | ccache (tmpfs 기반) |

---

## 하드웨어 및 소프트웨어 요구사항

### 하드웨어
- **PC**: Windows 10/11, Linux, 또는 macOS
- **메모리**: 8GB 이상 (16GB 권장)
- **디스크**: 10GB 여유 공간
- **네트워크**: 인터넷 연결 (이미지 다운로드용)

### 소프트웨어
1. **Docker Desktop** (필수)
   - Windows: https://www.docker.com/products/docker-desktop
   - Linux: `sudo apt install docker.io`
   - macOS: https://www.docker.com/products/docker-desktop

2. **Git** (필수)
   - Windows: https://git-scm.com/download/win
   - Linux: `sudo apt install git`
   - macOS: Xcode Command Line Tools

---

## 빠른 시작 가이드

### 1단계: 프로젝트 클론

Windows PowerShell을 열고 다음 명령을 실행하세요:

```powershell
git clone https://github.com/simryang/w55rp20-docker-build.git
cd w55rp20-docker-build
```

### 2단계: 빌드 스크립트 실행

**Windows의 경우:**

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1 -Interactive
```

![빌드 명령 1](docs/build_command_1.png)
*그림 1: 빌드 스크립트 실행 - Docker Desktop 확인*

**대화형 메뉴가 나타나면:**

1. 컨테이너 타입 선택: `1` 입력 → Enter (Linux 컨테이너 권장)
2. 빌드 확인: `y` 입력 → Enter (또는 그냥 Enter)

![빌드 명령 2](docs/build_command_2.png)
*그림 2: 컨테이너 타입 선택 - Linux 컨테이너 선택*

### 3단계: 자동 빌드 대기

스크립트가 자동으로 다음 작업을 수행합니다:

1. **Docker 이미지 다운로드** (최초 1회, 약 5분)
   - DockerHub에서 2.44GB 이미지 pull
   - 이후 실행 시 재사용으로 시간 절약

2. **프로젝트 클론** (최초 1회)
   - W55RP20-S2E 공식 예제 자동 클론
   - Git submodule 자동 업데이트

3. **펌웨어 빌드** (약 50초 → 이후 12초)
   - ARM GCC로 컴파일
   - ccache로 증분 빌드 최적화

![빌드 명령 3](docs/build_command_3.png)
*그림 3: 빌드 진행 - 자동으로 이미지 다운로드 및 빌드*

---

## 시스템 리소스 사용량

### 빌드 전

![빌드 전 CPU/메모리](docs/cpu_before_build.png)
*그림 4: 빌드 실행 전 시스템 리소스 (거의 idle 상태)*

### 빌드 시작 직후

![빌드 시작 직후](docs/cpu_build_1.png)
*그림 5: Docker 컨테이너 시작 및 초기화 (CPU 사용량 증가)*

### 빌드 실행 중

![빌드 실행 중](docs/cpu_build_2.png)
*그림 6: 실제 컴파일 진행 중 (멀티코어 활용으로 CPU 사용률 상승)*

**리소스 사용 특징:**
- **CPU**: 병렬 빌드(16 jobs)로 멀티코어 최대 활용
- **메모리**: tmpfs 사용으로 RAM에서 빌드 (SSD 수명 보호)
- **디스크**: 빌드 캐시로 두 번째부터 디스크 I/O 최소화

---

## 빌드 완료 및 결과물

### 빌드 성공

![빌드 성공](docs/build_success.png)
*그림 7: 빌드 성공 메시지 - 산출물 위치 및 다음 단계 안내*

### 빌드 결과물

빌드가 완료되면 `out` 디렉토리에 펌웨어 파일이 생성됩니다:

![빌드 결과물](docs/build_out_result.png)
*그림 8: 빌드 산출물 - *.uf2 파일 확인*

**생성되는 파일들:**
- `*.uf2`: W55RP20 펌웨어 이미지 (USB 드래그앤드롭용)
- `*.elf`: 디버깅용 실행 파일
- `*.bin`: 바이너리 펌웨어 이미지
- `*.hex`: HEX 포맷 펌웨어

---

## W55RP20 보드에 펌웨어 업로드하기

### 1. BOOTSEL 모드 진입

1. W55RP20 보드의 **BOOTSEL 버튼**을 누른 상태 유지
2. USB 케이블을 PC에 연결
3. Windows가 **RPI-RP2** 드라이브로 인식하면 버튼 해제

### 2. 펌웨어 복사

탐색기에서 `out` 폴더를 열고:
- `*.uf2` 파일을 **RPI-RP2** 드라이브로 드래그앤드롭

### 3. 자동 업로드

- 파일 복사가 완료되면 보드가 자동으로 재부팅
- 펌웨어가 자동으로 플래시됨
- 몇 초 후 새 펌웨어로 실행 시작!

---

## 다양한 빌드 옵션

### 사용자 프로젝트 빌드

자신의 W55RP20 프로젝트를 빌드하려면:

```powershell
.\build.ps1 -Project "C:\Users\yourname\my-w55rp20-project"
```

### 디버그 빌드

디버깅 심볼이 포함된 빌드:

```powershell
.\build.ps1 -BuildType Debug
```

### 정리 후 빌드

이전 빌드 산출물을 삭제하고 새로 빌드:

```powershell
.\build.ps1 -Clean
```

### 옵션 조합

여러 옵션을 함께 사용:

```powershell
.\build.ps1 -Linux -Project "C:\my-project" -BuildType Debug -Verbose
```

---

## 빌드 시간 비교

### 기존 환경 vs Docker 시스템

| 작업 | 기존 방식 | Docker 시스템 |
|------|----------|--------------|
| **환경 설정** | 1-2시간 (수동) | 자동 (불필요) |
| **첫 빌드** | 3-5분 | 6분 (이미지 DL 5분 + 빌드 1분) |
| **두 번째 빌드** | 3-5분 | **12초** ⚡ |
| **정리 후 빌드** | 3-5분 | 50초 |
| **OS 의존성** | 높음 (OS별 설정) | 없음 (Docker 통일) |

### ccache 효과

ccache를 사용한 증분 빌드의 효과:

```
첫 번째 빌드:  ████████████████████████ 50초
두 번째 빌드:  ██ 12초 (76% 시간 절감!)
```

---

## 문제 해결

### PowerShell 실행 권한 오류

**증상:**
```
이 시스템에서 스크립트를 실행할 수 없습니다
```

**해결:**
```powershell
# 방법 1: 실행 시마다 우회
powershell -ExecutionPolicy Bypass -File .\build.ps1 -Interactive

# 방법 2: 영구 설정 (관리자 권한 PowerShell)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Docker Desktop 미실행

**증상:**
```
Error response from daemon: ...
```

**해결:**
1. Docker Desktop 실행 확인 (시스템 트레이)
2. Docker가 완전히 시작될 때까지 대기 (30초~1분)
3. 스크립트 재실행

### WSL2 설치 안내

**증상:**
```
WSL 2 installation is incomplete
```

**해결:**
1. Docker Desktop 안내에 따라 재부팅
2. Docker Desktop 다시 실행
3. WSL2가 자동으로 설치됨

---

## Linux/macOS 사용자

### 빠른 시작 (Bash)

```bash
# 1. 클론
git clone https://github.com/simryang/w55rp20-docker-build.git
cd w55rp20-docker-build

# 2. 빌드
./build.sh

# 3. 결과 확인
ls -l out/
```

### 대화형 설정 (최초 1회)

```bash
./build.sh --setup
```

---

## 프로젝트 구조

```
w55rp20-docker-build/
├── build.sh              # Linux/macOS 빌드 스크립트
├── build.ps1             # Windows 통합 빌드 스크립트
├── Dockerfile            # Linux 컨테이너 정의
├── entrypoint.sh         # Docker 진입점
├── docker-build.sh       # 컨테이너 내부 빌드 로직
├── docs/                 # 문서 및 이미지
├── tests/                # 테스트 스크립트
│   └── validate-powershell.sh  # PowerShell 검증 도구
└── out/                  # 빌드 산출물 (자동 생성)
    └── *.uf2
```

---

## 고급 기능

### 멀티 프로젝트 빌드

여러 프로젝트를 연속으로 빌드:

```powershell
.\build.ps1 -Project "C:\project1"
.\build.ps1 -Project "C:\project2"
.\build.ps1 -Project "C:\project3"
```

### CI/CD 통합

GitHub Actions 예시:

```yaml
name: W55RP20 Build

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build firmware
        run: ./build.sh --no-confirm
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: firmware
          path: out/*.uf2
```

### 로컬 설정 커스터마이징

```bash
# Linux/macOS
cp build.config.example build.config
vim build.config

# 설정 예시
JOBS=8              # 병렬 작업 수
TMPFS_SIZE="10g"    # RAM 빌드 크기
```

---

## 성능 최적화 팁

### 1. 병렬 작업 수 조정

CPU 코어 수에 맞게 조정:

```powershell
.\build.ps1 -Jobs 8  # 8코어 시스템
```

### 2. Docker 메모리 할당

Docker Desktop 설정에서:
- Settings → Resources → Memory
- 최소 4GB, 권장 8GB 할당

### 3. ccache 크기 확인

```bash
# 컨테이너 내부에서
ccache -s  # 통계 확인
ccache -M 2G  # 최대 크기 설정
```

---

## 응용 사례

### 1. 팀 개발 환경 통일

모든 팀원이 동일한 Docker 이미지 사용:
- OS 차이로 인한 빌드 오류 제거
- "내 컴퓨터에서는 되는데..." 문제 해결

### 2. 자동화된 테스트 파이프라인

```bash
#!/bin/bash
# test-pipeline.sh

# 빌드
./build.sh --no-confirm || exit 1

# 테스트 (펌웨어 검증)
python3 tests/verify_firmware.py out/*.uf2

# 성공 시 배포
echo "Build and test passed!"
```

### 3. 교육용 환경

학생들에게 복잡한 환경 설정 없이:
1. Docker Desktop 설치
2. 스크립트 실행
3. 즉시 개발 시작!

---

## 결론

W55RP20 Docker 빌드 시스템은 복잡한 임베디드 개발 환경을 **단 3단계**로 단순화했습니다:

1. ✅ **Docker Desktop 설치** (한 번만)
2. ✅ **스크립트 실행** (복사-붙여넣기)
3. ✅ **펌웨어 빌드** (자동)

**주요 장점:**
- ⚡ 12초 빌드 속도 (ccache 활용)
- 🌍 크로스 플랫폼 (Windows/Linux/macOS)
- 🎯 초보자 친화적 (대화형 모드)
- 🔄 CI/CD 완벽 호환

이제 환경 설정에 시간 낭비하지 말고, **개발에만 집중**하세요!

---

## 참고 자료

### 공식 문서
- **GitHub 저장소**: https://github.com/simryang/w55rp20-docker-build
- **DockerHub 이미지**: https://hub.docker.com/r/simryang/w55rp20
- **사용자 가이드**: [USER_GUIDE.md](docs/USER_GUIDE.md)
- **문제 해결 가이드**: [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

### WIZnet 리소스
- **W55RP20 제품 페이지**: https://www.wiznet.io/product-item/w55rp20/
- **W55RP20-S2E 저장소**: https://github.com/Wiznet/W55RP20-S2E
- **Pico SDK**: https://github.com/raspberrypi/pico-sdk

### 커뮤니티
- **Issues**: https://github.com/simryang/w55rp20-docker-build/issues
- **WIZnet Maker**: https://maker.wiznet.io/

---

## 라이선스

MIT License - 자유롭게 사용, 수정, 배포 가능합니다.

---

**작성자**: simryang
**버전**: v1.2.0-unified
**최종 업데이트**: 2026-01-30

**Tags**: #W55RP20 #Docker #Embedded #Build #Automation #WIZnet #RP2040 #Ethernet
