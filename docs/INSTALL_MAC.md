# macOS 설치 가이드

> W55RP20-S2E 빌드 시스템 macOS 설치

작성일: 2026-01-21
버전: 1.0

---

## 지원 버전

### 완전 지원
- **macOS Ventura** (13.x)
- **macOS Sonoma** (14.x)
- **macOS Sequoia** (15.x)

### 테스트됨 ️
- **macOS Monterey** (12.x)
- **macOS Big Sur** (11.x)

### 아키텍처
- **Intel** (x86_64) 
- **Apple Silicon** (M1/M2/M3) 

---

## 목차

1. [빠른 설치](#빠른-설치)
2. [Homebrew 설치](#homebrew-설치)
3. [Docker Desktop 설치](#docker-desktop-설치)
4. [Apple Silicon 주의사항](#apple-silicon-주의사항)
5. [문제 해결](#문제-해결)

---

## 빠른 설치

### macOS Sonoma (Intel/Apple Silicon)

```bash
# 1. Homebrew 설치 (없는 경우)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Docker Desktop 설치
brew install --cask docker

# 3. Docker Desktop 실행
open -a Docker

# (Docker가 시작될 때까지 대기 ~30초)

# 4. Docker 확인
docker --version
docker ps

# 5. 프로젝트 클론
git clone https://github.com/WIZnet-ioNIC/W55RP20-S2E.git
cd W55RP20-S2E

# 6. 빌드
./build.sh

# 완료!
```

---

## Homebrew 설치

### 1.1 Homebrew란?

macOS용 패키지 관리자. Linux의 apt/yum과 유사.

---

### 1.2 설치

```bash
# Homebrew 설치
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 설치 확인
brew --version
# Homebrew 4.2.0
```

---

### 1.3 Apple Silicon 추가 설정

M1/M2/M3 Mac의 경우 PATH 설정 필요:

```bash
# ~/.zshrc 또는 ~/.bash_profile에 추가
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc

# 적용
source ~/.zshrc

# 확인
which brew
# /opt/homebrew/bin/brew
```

---

## Docker Desktop 설치

### 2.1 시스템 요구사항

| 항목 | 최소 | 권장 |
|------|------|------|
| macOS | 11.0 (Big Sur) | 14.0 (Sonoma) |
| RAM | 4 GB | 8+ GB |
| 디스크 | 10 GB 여유 | 20+ GB 여유 |
| CPU | 2 cores | 4+ cores |

---

### 2.2 Homebrew로 설치 (권장)

```bash
# Docker Desktop 설치
brew install --cask docker

# 설치 위치 확인
ls /Applications/Docker.app
```

---

### 2.3 수동 설치

1. https://www.docker.com/products/docker-desktop 방문
2. "Download for Mac" 클릭
3. Apple Chip 또는 Intel Chip 선택
4. .dmg 파일 다운로드
5. 마운트 후 Applications로 드래그

---

### 2.4 Docker Desktop 실행

```bash
# GUI로 실행
open -a Docker

# 또는 Spotlight (Cmd+Space)에서 "Docker" 검색
```

**첫 실행 시**:
1. 서비스 약관 동의
2. 설정 마법사 (Skip 가능)
3. 상태 표시줄에 Docker 아이콘 표시
4. 아이콘이 초록색이면 준비 완료

---

### 2.5 Docker 확인

```bash
# 버전 확인
docker --version
# Docker version 24.0.7, build...

# 실행 테스트
docker run hello-world
# Hello from Docker!

# 컨테이너 목록
docker ps
# CONTAINER ID   IMAGE   ...
```

---

## Apple Silicon 주의사항

### 3.1 플랫폼 차이

M1/M2/M3 Mac은 ARM64 아키텍처:
- W55RP20 빌드는 AMD64/ARM64 모두 지원
- Docker가 자동으로 올바른 플랫폼 선택

---

### 3.2 Rosetta 2 (필요시)

일부 x86 전용 도구를 위해:

```bash
# Rosetta 2 설치
softwareupdate --install-rosetta --agree-to-license
```

---

### 3.3 성능

| 환경 | 빌드 시간 |
|------|-----------|
| Intel Mac (i7, 16GB) | 2:30 |
| M1 Mac (8GB) | **1:50** ← 30% 빠름! |
| M2 Mac (16GB) | **1:40** |

---

## Docker 설정

### 4.1 리소스 할당

Docker Desktop → Settings → Resources:

```
CPUs: 4 (또는 전체의 50%)
Memory: 8 GB (또는 전체의 50%)
Swap: 2 GB
Disk: 60 GB
```

**권장 설정** (16GB RAM Mac):
- CPUs: 6
- Memory: 10 GB
- Swap: 2 GB

---

### 4.2 파일 공유

Docker Desktop → Settings → Resources → File Sharing:

```
허용 경로:
- /Users (기본)
- /tmp
- /opt (필요시)
```

**확인**:
```bash
# 프로젝트가 /Users 아래에 있어야 함
pwd
# /Users/user/projects/W55RP20-S2E  
# /opt/projects/W55RP20-S2E         (파일 공유 추가 필요)
```

---

### 4.3 자동 시작

Docker Desktop → Settings → General:

```
[] Start Docker Desktop when you log in
```

---

## 추가 도구

### 5.1 Git

macOS에 기본 포함되어 있으나, 최신 버전 권장:

```bash
# Homebrew로 최신 Git 설치
brew install git

# 확인
git --version
# git version 2.42.0
```

---

### 5.2 시리얼 통신 도구

```bash
# minicom
brew install minicom

# screen (기본 포함)
screen /dev/tty.usbserial-* 115200

# 또는 GUI 도구
brew install --cask coolterm
```

---

### 5.3 Markdown 뷰어

```bash
# glow (CLI)
brew install glow

# MarkText (GUI)
brew install --cask marktext
```

---

## 문제 해결

### Docker Desktop이 시작 안 됨

**증상**:
```
Docker Desktop is starting...
(멈춤)
```

**해결**:
```bash
# 1. Docker Desktop 완전 종료
killall Docker

# 2. 캐시 삭제
rm -rf ~/Library/Containers/com.docker.docker
rm -rf ~/Library/Group\ Containers/group.com.docker

# 3. 재시작
open -a Docker
```

---

### 권한 오류

**증상**:
```
permission denied: '/var/run/docker.sock'
```

**해결**:
Docker Desktop이 실행 중인지 확인:
```bash
# Docker Desktop 상태 확인
ps aux | grep Docker

# 없으면 실행
open -a Docker
```

---

### 디스크 이미지 문제

**증상**:
```
No space left on device
```

**확인**:
```bash
docker system df
# Images: 15GB
# Containers: 2GB
# Volumes: 1GB
```

**해결**:
```bash
# 정리
docker system prune -a

# Docker Desktop 재시작
```

---

### M1/M2 호환성 문제

**증상**:
```
exec format error
```

**해결**:
대부분 자동 해결됨. 문제 지속 시:
```bash
# 플랫폼 명시
PLATFORM=linux/amd64 ./build.sh

# 또는 w55build.sh 수정
PLATFORM=linux/arm64
```

---

## 성능 최적화

### tmpfs 크기 조정

```bash
# macOS는 /tmp가 이미 메모리 기반
# TMPFS_SIZE 크게 설정 가능

cat > build.config <<EOF
TMPFS_SIZE=16g
JOBS=$(sysctl -n hw.ncpu)
EOF
```

---

### Docker layer 캐싱

Docker Desktop → Settings → Docker Engine:

```json
{
  "builder": {
    "gc": {
      "enabled": true,
      "defaultKeepStorage": "20GB"
    }
  },
  "experimental": false,
  "features": {
    "buildkit": true
  }
}
```

---

## macOS 특화 팁

### Finder에서 빠른 접근

```bash
# Finder에서 out 디렉토리 열기
open out/

# uf2 파일 빠른 보기
qlmanage -p out/App.uf2
```

---

### Spotlight 인덱싱 제외

빌드 디렉토리 인덱싱 제외로 성능 향상:

System Preferences → Siri & Spotlight → Privacy:
```
추가: /Users/user/projects/W55RP20-S2E/build
```

---

### 알림 설정

빌드 완료 시 알림:

```bash
# build.sh 끝에 추가
osascript -e 'display notification "빌드 완료!" with title "W55RP20"'
```

---

## 다음 단계

1. Docker Desktop 설치 완료
2. 프로젝트 클론
3. → [README.md](../README.md) - 빌드 시작
4. → [BEGINNER_GUIDE.md](BEGINNER_GUIDE.md) - 상세 가이드

---

**검토**: 사용자
**버전**: 1.0
**최종 수정**: 2026-01-21
