# Windows 설치 가이드

> W55RP20-S2E 빌드 시스템 Windows 설치

작성일: 2026-01-21
버전: 1.0

---

## 지원 버전

### 완전 지원
- **Windows 11** (21H2+)
- **Windows 10** (20H1+)
  - Home, Pro, Enterprise

### 필수 요구사항
- WSL 2 (Windows Subsystem for Linux 2)
- Docker Desktop

---

## 목차

1. [빠른 설치](#빠른-설치)
2. [WSL 2 설치](#wsl-2-설치)
3. [Docker Desktop 설치](#docker-desktop-설치)
4. [Linux 배포판 선택](#linux-배포판-선택)
5. [문제 해결](#문제-해결)

---

## 빠른 설치

### Windows 11 (권장)

**PowerShell (관리자 권한)**:
```powershell
# 1. WSL 설치 (재부팅 필요)
wsl --install

# 재부팅
Restart-Computer

# (재부팅 후)
# 2. Ubuntu 설정
# - 사용자 이름 입력
# - 비밀번호 입력

# 3. Docker Desktop 설치
# https://www.docker.com/products/docker-desktop 에서 다운로드
# 설치 후 재시작

# 4. WSL 2 백엔드 활성화
# Docker Desktop → Settings → General
# [] Use the WSL 2 based engine

# 5. Ubuntu에서 작업
wsl

# 6. 프로젝트 클론
git clone https://github.com/WIZnet-ioNIC/W55RP20-S2E.git
cd W55RP20-S2E

# 7. 빌드
./build.sh

# 완료!
```

---

## WSL 2 설치

### 2.1 시스템 요구사항

| 항목 | 요구사항 |
|------|----------|
| OS | Windows 10 (2004+) 또는 Windows 11 |
| CPU | 가상화 지원 (대부분의 현대 CPU) |
| RAM | 8 GB 이상 권장 |
| 디스크 | 20 GB 여유 공간 |

---

### 2.2 가상화 확인

**작업 관리자** (Ctrl+Shift+Esc):
- 성능 탭 → CPU
- "가상화: 사용" 확인

**비활성화되어 있으면**:
1. BIOS/UEFI 진입 (재부팅 시 Del/F2)
2. Virtualization Technology 활성화
3. Intel: VT-x, AMD: AMD-V

---

### 2.3 WSL 자동 설치 (Windows 11)

**PowerShell (관리자)**:
```powershell
# 한 번에 설치
wsl --install

# 출력:
# 설치 중: 가상 머신 플랫폼
# 설치 중: Linux용 Windows 하위 시스템
# Ubuntu를 다운로드하는 중...

# 재부팅
Restart-Computer
```

재부팅 후 자동으로 Ubuntu 설정 시작:
```
Enter new UNIX username: yourname
New password: ****
Retype new password: ****
```

---

### 2.4 WSL 수동 설치 (Windows 10)

**1단계: Windows 기능 활성화**

PowerShell (관리자):
```powershell
# Linux용 Windows 하위 시스템
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# 가상 머신 플랫폼
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# 재부팅
Restart-Computer
```

**2단계: Linux 커널 업데이트**

1. https://aka.ms/wsl2kernel 다운로드
2. wsl_update_x64.msi 설치
3. 재부팅

**3단계: WSL 2 기본값 설정**

PowerShell:
```powershell
wsl --set-default-version 2
```

**4단계: Ubuntu 설치**

Microsoft Store에서:
1. "Ubuntu" 검색
2. Ubuntu 22.04 LTS 설치
3. 실행 → 사용자 설정

---

### 2.5 WSL 확인

```powershell
# WSL 버전 확인
wsl --list --verbose

# 출력:
#   NAME      STATE     VERSION
# * Ubuntu    Running   2        ← 버전 2 확인
```

---

## Docker Desktop 설치

### 3.1 다운로드 및 설치

1. https://www.docker.com/products/docker-desktop
2. "Download for Windows" 클릭
3. Docker Desktop Installer.exe 실행
4. 설치 옵션:
   - [] Use WSL 2 instead of Hyper-V
   - [] Add shortcut to desktop

5. 설치 완료 후 재시작

---

### 3.2 Docker Desktop 설정

**Settings → General**:
```
[] Use the WSL 2 based engine
[] Start Docker Desktop when you log in
```

**Settings → Resources → WSL Integration**:
```
[] Enable integration with my default WSL distro
[] Ubuntu-22.04
```

**Apply & Restart**

---

### 3.3 Docker 확인

**WSL 터미널**:
```bash
# Docker 버전
docker --version
# Docker version 24.0.7

# 테스트
docker run hello-world
# Hello from Docker!
```

---

## Linux 배포판 선택

### 4.1 Ubuntu (권장)

**장점**:
- 가장 많은 사용자
- 풍부한 문서
- 안정적

**설치**:
```powershell
wsl --install -d Ubuntu-22.04
```

---

### 4.2 Debian

**장점**:
- 매우 안정적
- Ubuntu와 유사

**설치**:
```powershell
wsl --install -d Debian
```

---

### 4.3 여러 배포판 사용

```powershell
# 설치된 배포판 목록
wsl --list

# 특정 배포판 실행
wsl -d Ubuntu-22.04
wsl -d Debian

# 기본 배포판 변경
wsl --set-default Ubuntu-22.04
```

---

## 프로젝트 설정

### 5.1 WSL 파일 시스템

**Windows에서 WSL 접근**:
```
파일 탐색기 주소창:
\\wsl$\Ubuntu-22.04\home\yourname\
```

**WSL에서 Windows 접근**:
```bash
# Windows C 드라이브
cd /mnt/c/Users/YourName/

# 하지만 성능을 위해 WSL 내부 사용 권장:
cd ~
```

---

### 5.2 권장 작업 위치

**성능 우선** (권장):
```bash
# WSL 내부 (~10배 빠름)
cd ~
mkdir projects
cd projects
git clone https://github.com/WIZnet-ioNIC/W55RP20-S2E.git
```

**Windows 접근 우선**:
```bash
# Windows 드라이브 (느림)
cd /mnt/c/Users/YourName/projects
git clone https://github.com/WIZnet-ioNIC/W55RP20-S2E.git
```

---

### 5.3 빌드

```bash
cd ~/projects/W55RP20-S2E
./build.sh

# Windows에서 결과 확인:
# \\wsl$\Ubuntu-22.04\home\yourname\projects\W55RP20-S2E\out\
```

---

## 추가 도구

### 6.1 Windows Terminal (권장)

**Microsoft Store**:
1. "Windows Terminal" 검색
2. 설치

**장점**:
- 탭 지원
- 테마 커스터마이징
- 복사/붙여넣기 가능

**설정**:
```json
// Settings → Startup → Default profile
"Ubuntu-22.04"
```

---

### 6.2 VS Code

**WSL 통합**:
```bash
# WSL 내부에서
cd ~/projects/W55RP20-S2E
code .

# 자동으로 VS Code가 열리고 WSL 연결됨
```

**확장 설치**:
- WSL (필수)
- C/C++
- CMake Tools

---

### 6.3 Git 설정

**Windows와 WSL의 Git 차이**:
- Windows: `git` (Windows용)
- WSL: `git` (Linux용)

**WSL에서만 사용 권장**:
```bash
# WSL 내부
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# 줄 끝 처리 (중요!)
git config --global core.autocrlf input
```

---

## 문제 해결

### WSL 2 설치 실패

**오류: "가상화가 지원되지 않습니다"**

해결:
1. BIOS에서 Virtualization 활성화
2. Hyper-V 비활성화 (충돌 시)
   ```powershell
   Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
   ```

---

### Docker Desktop 시작 안 됨

**오류: "Docker Desktop stopped"**

해결:
```powershell
# WSL 재시작
wsl --shutdown
# Docker Desktop 재시작
```

---

### WSL 디스크 공간 부족

**확인**:
```bash
df -h
```

**정리**:
```bash
# Docker 정리
docker system prune -a

# WSL 디스크 압축 (PowerShell)
wsl --shutdown
Optimize-VHD -Path $env:LOCALAPPDATA\Docker\wsl\data\ext4.vhdx -Mode Full
```

---

### 파일 권한 문제

**증상**: Windows에서 만든 파일이 실행 안 됨

**해결**:
```bash
# 실행 권한 추가
chmod +x build.sh

# 또는 WSL 내부에서 파일 생성
```

---

## 성능 최적화

### WSL 메모리 제한

**.wslconfig** (C:\Users\YourName\.wslconfig):
```ini
[wsl2]
memory=8GB
processors=4
swap=2GB
```

적용:
```powershell
wsl --shutdown
wsl
```

---

### Docker 리소스

Docker Desktop → Settings → Resources:
```
Memory: 6 GB
CPUs: 4
```

---

## Windows 특화 팁

### 시작 메뉴에 빌드 추가

**build.bat** 생성:
```batch
@echo off
wsl -d Ubuntu-22.04 -e bash -c "cd ~/projects/W55RP20-S2E && ./build.sh"
pause
```

바로가기를 시작 메뉴에 고정

---

### 파일 탐색기 통합

**out 폴더 빠른 접근**:
1. 파일 탐색기 주소창:
   ```
   \\wsl$\Ubuntu-22.04\home\yourname\projects\W55RP20-S2E\out
   ```
2. 네트워크 드라이브 연결 (선택)

---

## 다음 단계

1. WSL 2 설치 완료
2. Docker Desktop 설치 완료
3. → [README.md](../README.md) - 빌드 시작
4. → [BEGINNER_GUIDE.md](BEGINNER_GUIDE.md) - 상세 가이드

---

**검토**: 사용자
**버전**: 1.0
**최종 수정**: 2026-01-21
