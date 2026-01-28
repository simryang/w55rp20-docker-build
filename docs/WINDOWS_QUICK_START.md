# Windows 빠른 시작 가이드

## 개요

Windows에서 W55RP20 펌웨어를 빌드하는 **가장 쉬운 방법**입니다.

**핵심:**
- ✅ Docker만 설치하면 끝
- ✅ ARM GCC, CMake, Ninja 등 **수동 설치 불필요**
- ✅ 모든 도구가 Docker 이미지에 포함됨
- ✅ 원클릭 빌드

---

## 1. 요구사항

### 필수

- **Windows 10/11** (64-bit)
  - Home: WSL2 필수
  - Pro/Enterprise/Education: WSL2 권장

- **Docker Desktop for Windows**
  - 다운로드: https://www.docker.com/products/docker-desktop
  - WSL2 backend 사용

- **Git for Windows** (PowerShell 사용자는 선택)
  - 다운로드: https://git-scm.com/download/win

### 시스템 요구사항

- RAM: 8GB 이상 (16GB 권장)
- 디스크: 10GB 여유 공간
- CPU: 멀티코어 권장

---

## 2. 설치 (최초 1회)

### Step 1: Docker Desktop 설치

1. https://www.docker.com/products/docker-desktop 에서 다운로드
2. 설치 프로그램 실행
3. **중요:** "Use WSL 2 instead of Hyper-V" 체크 (권장)
4. 재부팅
5. Docker Desktop 실행

**확인:**
```powershell
# PowerShell에서 실행
docker --version
# Docker version 24.x.x

docker info
# 정상 출력되면 성공
```

### Step 2: 빌드 스크립트 다운로드

```powershell
# PowerShell에서 실행
cd ~
git clone https://github.com/yourusername/w55rp20-docker-build.git
cd w55rp20-docker-build
```

---

## 3. 빌드 방법

### PowerShell 사용자 (권장)

```powershell
# PowerShell에서 실행
.\build-windows.ps1
```

**첫 실행:**
- Docker 이미지 빌드 (약 20분)
- W55RP20-S2E 소스 클론
- 펌웨어 빌드 (약 1분)

**이후 실행:**
- 이미지 재사용 (빌드만, 약 1분)

### Git Bash 사용자

```bash
# Git Bash에서 실행
./build-windows.sh
```

---

## 4. 빌드 결과

### 산출물 위치

```
./out/
├── App.uf2           ← 메인 펌웨어 (이걸 사용!)
├── Boot.uf2          ← 부트로더
├── App_linker.uf2    ← 링커 버전
└── ...
```

### W55RP20에 업로드

1. W55RP20 보드의 **BOOTSEL 버튼을 누른 채로** USB 연결
2. Windows가 **RPI-RP2** 드라이브로 인식
3. `out\App.uf2` 파일을 드라이브에 복사
4. 자동으로 재부팅 및 펌웨어 업로드 완료

---

## 5. 고급 사용법

### 사용자 프로젝트 빌드

```powershell
# PowerShell
.\build-windows.ps1 -Project "C:\Users\myname\my-w55rp20-project"

# Git Bash
./build-windows.sh --project ~/my-w55rp20-project
```

### 디버그 빌드

```powershell
# PowerShell
.\build-windows.ps1 -BuildType Debug -Verbose

# Git Bash
./build-windows.sh --debug --verbose
```

### 정리 후 빌드

```powershell
# PowerShell
.\build-windows.ps1 -Clean

# Git Bash
./build-windows.sh --clean
```

### 도움말

```powershell
# PowerShell
.\build-windows.ps1 -Help

# Git Bash
./build-windows.sh --help
```

---

## 6. 문제 해결

### Q1: "Docker Desktop이 실행되지 않았습니다"

**원인:** Docker Desktop이 실행되지 않음

**해결:**
1. 시작 메뉴에서 "Docker Desktop" 실행
2. 시스템 트레이에 Docker 아이콘 확인
3. 아이콘이 초록색이 될 때까지 대기 (약 1분)
4. 다시 빌드 실행

---

### Q2: "WSL 2 installation is incomplete"

**원인:** WSL2가 설치되지 않음

**해결:**
```powershell
# PowerShell (관리자 권한)
wsl --install
```

재부팅 후 Docker Desktop 재실행

---

### Q3: 빌드가 느림

**원인:** 첫 빌드는 Docker 이미지 생성으로 약 20분 소요

**해결:**
- 정상입니다! 이후 빌드는 약 1분
- SSD 사용 권장
- ccache가 자동으로 빌드 캐싱

---

### Q4: "이미지를 찾을 수 없습니다"

**원인:** Docker 이미지가 빌드되지 않음

**해결:**
```powershell
# 수동 이미지 빌드
docker buildx build -t w55rp20:auto --load -f Dockerfile .
```

---

### Q5: Git Bash에서 경로 오류

**원인:** MSYS path conversion

**해결:**
스크립트가 자동으로 `MSYS_NO_PATHCONV=1` 설정함.
문제 지속 시:

```bash
export MSYS_NO_PATHCONV=1
./build-windows.sh
```

---

## 7. 성능 비교

### 빌드 시간 (W55RP20-S2E 전체 빌드)

| 환경 | 초기 빌드 | 재빌드 (캐시) |
|-----|---------|------------|
| **Docker (Windows)** | 55초 | 12초 |
| **Windows 네이티브** | 45초 | 8초 |
| **차이** | +10초 | +4초 |

**결론:** Docker 오버헤드는 약 10초 (실용적 수준)

---

## 8. 장단점 비교

### Docker 방식 (본 가이드)

**장점:**
- ✅ 설치 간단 (Docker Desktop만)
- ✅ 도구 버전 고정 (팀 협업 유리)
- ✅ 환경 오염 없음 (호스트 깨끗)
- ✅ Linux/macOS와 동일한 환경
- ✅ CI/CD와 일관성

**단점:**
- ❌ Docker Desktop 필요 (약 2GB)
- ❌ 약간의 성능 오버헤드 (10초)
- ❌ 디버깅 복잡 (컨테이너 내부)

### Windows 네이티브 방식

**장점:**
- ✅ 최고 성능 (네이티브)
- ✅ Visual Studio Code 디버깅 가능
- ✅ 도구 직접 제어

**단점:**
- ❌ 수동 설치 복잡 (ARM GCC, CMake, Ninja, ...)
- ❌ 버전 관리 어려움
- ❌ 환경 오염 (PATH, 환경변수)
- ❌ 팀원마다 환경 다름

---

## 9. 권장 사항

### 일반 사용자 → Docker (본 가이드)
- 설치 간단
- 안정적
- 팀 협업 유리

### 고급 사용자 → 선택
- 최고 성능 필요 → Windows 네이티브
- 디버깅 필요 → Windows 네이티브 + VS Code
- CI/CD → Docker (필수)

---

## 10. 다음 단계

### 개발 워크플로우

1. **소스 수정** (Windows 에디터 사용)
   ```
   C:\Users\myname\W55RP20-S2E\src\main.c
   ```

2. **빌드** (Docker)
   ```powershell
   .\build-windows.ps1
   ```

3. **업로드** (UF2 파일 복사)
   ```
   .\out\App.uf2 → RPI-RP2 드라이브
   ```

4. **테스트** (시리얼 모니터)
   - Tera Term, PuTTY 등
   - 115200 baud

### 추가 학습 자료

- **W55RP20 공식 문서**
  - https://github.com/WIZnet-ioNIC/W55RP20-S2E

- **Raspberry Pi Pico SDK**
  - https://www.raspberrypi.com/documentation/microcontrollers/

- **Docker Desktop 문서**
  - https://docs.docker.com/desktop/

---

## 11. 요약

```powershell
# Windows 빠른 시작 (3단계)

# 1. Docker Desktop 설치
# https://www.docker.com/products/docker-desktop

# 2. 빌드 스크립트 다운로드
git clone <repository-url>
cd w55rp20-docker-build

# 3. 빌드!
.\build-windows.ps1

# 끝! 산출물은 .\out\ 폴더에 있습니다.
```

---

**문서 작성:** 2026-01-28
**대상:** Windows 10/11 사용자
**난이도:** 초급
