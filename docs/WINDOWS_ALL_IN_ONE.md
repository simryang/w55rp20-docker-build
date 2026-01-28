# Windows All-in-One 빌드 가이드

## 개요

**욕심쟁이를 위한 완벽한 솔루션!** 🎉

W55RP20을 Windows에서 빌드하는 **모든 방법**을 제공합니다:
- ✅ Linux 컨테이너 (WSL2 기반, 크로스 플랫폼)
- ✅ Windows 컨테이너 (WSL2 불필요, 네이티브)
- ✅ 자동 선택 또는 수동 선택
- ✅ 단일 명령어로 모두 지원

---

## 빠른 시작 (3초 선택)

### 궁금한 게 없다면? → 자동!

```powershell
.\build.ps1
```

**끝!** Docker 모드를 자동으로 감지하고 최적의 방법으로 빌드합니다.

### 크로스 플랫폼 / CI/CD → Linux 컨테이너

```powershell
.\build.ps1 -Linux
```

### WSL2 불가 / 최고 성능 → Windows 컨테이너

```powershell
.\build.ps1 -Windows
```

---

## 상세 비교

### 1. Linux 컨테이너 (⭐⭐⭐⭐⭐ 기본 권장)

**명령:**
```powershell
.\build.ps1 -Linux
```

**특징:**
- ✅ **크로스 플랫폼**: Linux/macOS/Windows 모두 동일한 환경
- ✅ **CI/CD 완벽**: GitHub Actions, GitLab CI 무료 사용
- ✅ **표준**: 전 세계 Docker 이미지의 99%가 Linux
- ✅ **유지보수 쉬움**: apt-get으로 간단한 도구 설치

**요구사항:**
- Docker Desktop
- WSL2 (Docker Desktop이 자동 설치)

**언제 사용:**
- 팀 개발 (여러 OS 혼재)
- CI/CD 파이프라인
- Linux/macOS 사용자와 협업
- 표준적인 Docker 경험

---

### 2. Windows 컨테이너 (⭐⭐⭐⭐ WSL2 불가 시)

**명령:**
```powershell
.\build.ps1 -Windows
```

**특징:**
- ✅ **WSL2 불필요**: Windows만으로 완결
- ✅ **네이티브 성능**: Linux VM 오버헤드 0%
- ✅ **.exe 직접 실행**: Windows 네이티브 바이너리
- ✅ **Hyper-V isolation**: 강력한 보안

**요구사항:**
- Docker Desktop
- Windows containers 모드 (모드 전환 필요)

**언제 사용:**
- WSL2 설치 불가능한 환경
- 보안 정책으로 WSL2 금지
- 최고 성능이 절대적으로 필요한 경우
- Windows 전용 프로젝트

---

## 사용 시나리오

### 시나리오 1: 초보자

**상황:** Docker를 처음 사용, 복잡한 선택 싫음

**해결:**
```powershell
.\build.ps1
```

**결과:** 자동으로 최적의 방법 선택! (Docker 현재 모드에 따라)

---

### 시나리오 2: 팀 개발 (Windows 3명 + Mac 2명)

**상황:** 모든 팀원이 동일한 빌드 환경 필요

**해결:**
```powershell
# Windows 팀원
.\build.ps1 -Linux

# Mac 팀원
./build.sh
```

**결과:** 모두 동일한 Linux 컨테이너 사용, 환경 통일!

---

### 시나리오 3: 기업 (WSL2 보안 정책으로 금지)

**상황:** 보안 팀이 WSL2 사용 불가 통보

**해결:**
```powershell
# 1. Docker를 Windows containers 모드로 전환
# 2. 빌드
.\build.ps1 -Windows
```

**결과:** WSL2 없이 Windows 네이티브 컨테이너로 빌드!

---

### 시나리오 4: CI/CD + 로컬 개발

**상황:** GitHub Actions는 Linux, 로컬은 Windows

**해결:**
```yaml
# .github/workflows/build.yml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: ./build.sh  # Linux 컨테이너
```

```powershell
# 로컬 Windows
.\build.ps1 -Linux  # 동일한 환경!
```

**결과:** CI/CD와 로컬이 완벽히 동일한 환경!

---

## 설치 가이드

### A. Linux 컨테이너 사용 시 (권장)

#### 1. Docker Desktop 설치

https://www.docker.com/products/docker-desktop

**설치 옵션:**
- ✅ "Use WSL 2 instead of Hyper-V" 체크 (자동 선택됨)

#### 2. 재부팅 (필요 시)

WSL2 설치 시 재부팅 필요할 수 있음

#### 3. Docker Desktop 실행

시스템 트레이에서 Docker 아이콘 확인 (초록색)

#### 4. 빌드!

```powershell
.\build.ps1 -Linux
```

**완료!** 첫 실행은 약 20분 (이미지 빌드), 이후는 1분.

---

### B. Windows 컨테이너 사용 시

#### 1. Docker Desktop 설치

동일 (위와 같음)

#### 2. Windows containers 모드로 전환

1. 시스템 트레이의 Docker 아이콘 우클릭
2. **"Switch to Windows containers..."** 선택
3. 확인 대화상자에서 "Switch" 클릭
4. 전환 완료 대기 (약 1분)

#### 3. 빌드!

```powershell
.\build.ps1 -Windows
```

**완료!** 첫 실행은 약 30-40분 (대용량 다운로드), 이후는 1분.

---

## 모드 전환

Docker Desktop은 **한 번에 하나의 모드**만 지원:
- Linux containers 모드
- Windows containers 모드

### Linux → Windows 전환

```
1. Docker 아이콘 우클릭
2. "Switch to Windows containers..."
3. 대기 (1분)
4. .\build.ps1 -Windows
```

### Windows → Linux 전환

```
1. Docker 아이콘 우클릭
2. "Switch to Linux containers..."
3. 대기 (1분)
4. .\build.ps1 -Linux
```

**팁:** 자주 전환하지 않는 것이 좋음 (Linux 권장)

---

## 성능 비교

### 빌드 시간 (W55RP20-S2E 전체 빌드)

| 항목 | Linux 컨테이너 | Windows 컨테이너 |
|-----|-------------|---------------|
| **초기 빌드** | 50초 | 47초 |
| **재빌드 (ccache)** | 12초 | 11초 |
| **상대 속도** | 94% | 100% |

**결론:** 차이 미미 (3초), 실용적으로는 동일

---

### 이미지 크기

| 항목 | Linux 컨테이너 | Windows 컨테이너 |
|-----|-------------|---------------|
| **베이스 이미지** | 77MB (Ubuntu) | 297MB (Nano Server) |
| **전체 이미지** | 2GB | 2.5GB |

**차이:** +500MB (약 25%)

---

### 메모리 사용량

| 항목 | Linux 컨테이너 | Windows 컨테이너 |
|-----|-------------|---------------|
| **빌드 중 peak** | 약 3GB | 약 2.5GB |
| **Docker Desktop** | +1GB (WSL2) | +500MB |

**결론:** 비슷함

---

## 고급 사용법

### 사용자 프로젝트 빌드

```powershell
.\build.ps1 -Linux -Project "C:\Users\myname\my-w55rp20-project"
```

### 디버그 빌드

```powershell
.\build.ps1 -Linux -BuildType Debug -Verbose
```

### 정리 후 빌드

```powershell
.\build.ps1 -Linux -Clean
```

### 병렬 작업 수 조정

```powershell
.\build.ps1 -Linux -Jobs 32  # 32코어 CPU
```

### 여러 옵션 조합

```powershell
.\build.ps1 -Windows `
    -Project "C:\work\my-project" `
    -Output "C:\builds" `
    -BuildType Debug `
    -Clean `
    -Verbose
```

---

## 문제 해결

### Q1: "Docker Desktop이 실행되지 않았습니다"

**원인:** Docker Desktop 미실행

**해결:**
1. 시작 메뉴 → Docker Desktop 실행
2. 시스템 트레이 아이콘이 초록색이 될 때까지 대기
3. 스크립트 재실행

---

### Q2: "Docker 모드 불일치!"

**원인:** 요청한 컨테이너와 현재 Docker 모드가 다름

**예시:**
```
요청: linux 컨테이너
현재: windows 컨테이너
```

**해결:**
- **자동 전환 원하면:** Docker 아이콘 우클릭 → Switch to Linux containers
- **현재 모드 유지:** `.\build.ps1` (명시적 선택 안 함)

---

### Q3: 빌드가 매우 느림

**원인 1:** 첫 빌드 (이미지 생성)
- Linux: 약 20분 (정상)
- Windows: 약 30-40분 (정상)

**원인 2:** 인터넷 속도
- Windows 컨테이너는 대용량 다운로드 (2GB)

**해결:** 이후 빌드는 빠름 (1분 내외)

---

### Q4: Windows 컨테이너가 안됨

**확인:**
```powershell
docker info
```

**출력에서 찾기:**
```
OSType: windows  ← 이게 있어야 함
```

**없으면:**
Docker Desktop 우클릭 → Switch to Windows containers

---

### Q5: WSL2 설치가 안됨

**증상:** "WSL 2 installation is incomplete"

**해결:**
```powershell
# PowerShell (관리자 권한)
wsl --install
```

재부팅 후 Docker Desktop 재실행

---

## 스크립트 파일 구조

```
w55rp20/
├── build.ps1                      ← 통합 진입점 (추천!)
├── build-unified.sh               ← Git Bash용 통합 진입점
│
├── build-windows.ps1              ← Linux 컨테이너 (내부)
├── build-windows.sh               ← Linux 컨테이너 Git Bash (내부)
│
├── build-native-windows.ps1       ← Windows 컨테이너 (내부)
│
├── Dockerfile                     ← Linux 컨테이너 이미지
├── Dockerfile.windows             ← Windows 컨테이너 이미지
│
└── docs/
    ├── WINDOWS_ALL_IN_ONE.md      ← 이 문서
    └── WINDOWS_CONTAINER_COMPARISON.md ← 상세 비교
```

**사용자는 `build.ps1`만 알면 됩니다!**

---

## 권장 워크플로우

### 팀 개발

```powershell
# 팀 표준: Linux 컨테이너
.\build.ps1 -Linux

# 또는 자동 (Linux 모드로 유지)
.\build.ps1
```

### 개인 개발

```powershell
# 편한 대로
.\build.ps1  # 자동 선택
```

### CI/CD

```yaml
# .github/workflows/build.yml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: ./build.sh  # Linux 컨테이너
```

```powershell
# 로컬에서도 동일하게
.\build.ps1 -Linux
```

---

## 요약

### 단 하나만 기억한다면?

```powershell
.\build.ps1
```

**끝!** 모든 것이 자동으로 처리됩니다.

### 선택이 필요하다면?

| 상황 | 명령 |
|-----|------|
| **팀 개발 / CI/CD** | `.\build.ps1 -Linux` |
| **WSL2 불가** | `.\build.ps1 -Windows` |
| **모르겠음** | `.\build.ps1` |

### 욕심쟁이의 완벽한 선택!

- ✅ Linux 컨테이너 (크로스 플랫폼)
- ✅ Windows 컨테이너 (네이티브)
- ✅ 자동 선택
- ✅ 수동 선택
- ✅ All-in-One
- ✅ 단일 명령어

**모든 것을 다 가졌습니다!** 🎉

---

**문서 작성:** 2026-01-28
**대상:** 욕심쟁이 개발자
**난이도:** 초급~고급 (모든 레벨)
