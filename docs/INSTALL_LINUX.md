# Linux 설치 가이드

> W55RP20-S2E 빌드 시스템 Linux 설치

작성일: 2026-01-21
버전: 1.0

---

## 지원 배포판

### 완전 지원
- **Ubuntu** 20.04 LTS, 22.04 LTS, 24.04 LTS
- **Debian** 11 (Bullseye), 12 (Bookworm)
- **Linux Mint** 20+

### 테스트됨 ️
- **Fedora** 36+
- **Arch Linux** (최신)
- **openSUSE** Leap 15.4+

### 이론상 가능 ℹ️
- Docker가 실행되는 모든 Linux 배포판

---

## 목차

1. [빠른 설치](#빠른-설치)
2. [Ubuntu/Debian 상세 설치](#ubuntudebian-상세-설치)
3. [Fedora 설치](#fedora-설치)
4. [Arch Linux 설치](#arch-linux-설치)
5. [문제 해결](#문제-해결)

---

## 빠른 설치

### Ubuntu 22.04 LTS (권장)

```bash
# 1. 시스템 업데이트
sudo apt update
sudo apt upgrade -y

# 2. Docker 설치
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 3. 사용자를 docker 그룹에 추가
sudo usermod -aG docker $USER

# 4. 로그아웃 후 재로그인
logout

# (재로그인 후)
# 5. Docker 확인
docker --version
docker ps

# 6. 프로젝트 클론
git clone https://github.com/WIZnet-ioNIC/W55RP20-S2E.git
cd W55RP20-S2E

# 7. 빌드
./build.sh

# 완료!
```

---

## Ubuntu/Debian 상세 설치

### 1.1 시스템 요구사항

| 항목 | 최소 | 권장 |
|------|------|------|
| CPU | 2 cores | 4+ cores |
| RAM | 4 GB | 8+ GB |
| 디스크 | 10 GB 여유 | 20+ GB 여유 |
| OS | Ubuntu 20.04 | Ubuntu 22.04 LTS |

**확인**:
```bash
# CPU 코어 수
nproc
# 출력: 8

# 메모리
free -h
# Mem: 15Gi

# 디스크 여유 공간
df -h ~
# /home  100G  50G  50G  50%

# OS 버전
lsb_release -a
# Ubuntu 22.04.3 LTS
```

---

### 1.2 Docker 설치 (공식 방법)

**이전 버전 제거** (필요시):
```bash
sudo apt remove docker docker-engine docker.io containerd runc
```

**필수 패키지 설치**:
```bash
sudo apt update
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```

**Docker GPG 키 추가**:
```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

**Docker 저장소 추가**:
```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

**Docker 설치**:
```bash
sudo apt update
sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
```

**설치 확인**:
```bash
docker --version
# Docker version 24.0.7, build...

sudo docker run hello-world
# Hello from Docker!
```

---

### 1.3 사용자 권한 설정

**docker 그룹 추가**:
```bash
# 현재 사용자 추가
sudo usermod -aG docker $USER

# 확인 (아직 적용 안 됨)
groups
# user sudo  ← docker 없음

# 새 셸 시작 (임시)
newgrp docker

# 확인
groups
# user sudo docker  ← docker 추가됨!

# 영구 적용: 로그아웃 후 재로그인
```

**테스트** (sudo 없이):
```bash
docker ps
# CONTAINER ID   IMAGE   COMMAND   ...
# (빈 목록, 정상)

# 에러 없으면 성공!
```

---

### 1.4 Docker 자동 시작

```bash
# 부팅 시 자동 시작
sudo systemctl enable docker

# 즉시 시작
sudo systemctl start docker

# 상태 확인
sudo systemctl status docker
# ● docker.service - Docker Application Container Engine
#    Loaded: loaded
#    Active: active (running)
```

---

### 1.5 추가 도구 설치 (선택)

```bash
# Git (대부분 이미 설치됨)
sudo apt install -y git

# 빌드 도구 (선택)
sudo apt install -y \
    build-essential \
    cmake \
    ccache

# 시리얼 통신 도구
sudo apt install -y \
    minicom \
    screen \
    picocom

# Markdown 뷰어 (선택)
sudo apt install -y glow
```

---

### 1.6 프로젝트 설정

```bash
# 작업 디렉토리 생성
mkdir -p ~/projects
cd ~/projects

# 프로젝트 클론
git clone https://github.com/WIZnet-ioNIC/W55RP20-S2E.git
cd W55RP20-S2E

# 파일 확인
ls -la
# -rwxr-xr-x build.sh
# -rw-r--r-- Dockerfile
# ...

# 첫 빌드
./build.sh
```

---

## Fedora 설치

### 2.1 Docker 설치

```bash
# 이전 버전 제거 (필요시)
sudo dnf remove docker \
    docker-client \
    docker-client-latest \
    docker-common

# Docker 저장소 추가
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager \
    --add-repo \
    https://download.docker.com/linux/fedora/docker-ce.repo

# Docker 설치
sudo dnf install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io

# 시작 및 활성화
sudo systemctl start docker
sudo systemctl enable docker

# 사용자 그룹 추가
sudo usermod -aG docker $USER

# 재로그인 필요
logout
```

---

### 2.2 SELinux 설정

Fedora는 SELinux가 활성화되어 있어 추가 설정 필요:

```bash
# 현재 모드 확인
getenforce
# Enforcing

# Docker 볼륨 마운트 허용
sudo setsebool -P container_manage_cgroup on

# 또는 Permissive 모드 (권장하지 않음)
sudo setenforce 0
```

---

## Arch Linux 설치

### 3.1 Docker 설치

```bash
# Docker 설치
sudo pacman -S docker

# 시작 및 활성화
sudo systemctl start docker
sudo systemctl enable docker

# 사용자 그룹 추가
sudo usermod -aG docker $USER

# 재로그인
logout
```

---

### 3.2 추가 패키지

```bash
# Git 및 빌드 도구
sudo pacman -S git base-devel

# 시리얼 통신
sudo pacman -S minicom screen

# Markdown 뷰어
yay -S glow  # AUR 사용
```

---

## 문제 해결

### Docker 권한 오류

**증상**:
```
permission denied while trying to connect to Docker daemon
```

**해결**:
```bash
# 그룹 확인
groups
# docker가 없으면 추가
sudo usermod -aG docker $USER

# 재로그인 필요!
logout
```

---

### Docker daemon 미실행

**증상**:
```
Cannot connect to the Docker daemon
```

**해결**:
```bash
# Ubuntu/Debian
sudo systemctl start docker
sudo systemctl enable docker

# Arch
sudo systemctl start docker.service
sudo systemctl enable docker.service
```

---

### 네트워크 문제

**증상**:
```
docker: Error response from daemon: Get "https://registry-1.docker.io/v2/": dial tcp: lookup registry-1.docker.io
```

**해결**:
```bash
# DNS 확인
cat /etc/resolv.conf

# Google DNS 사용
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}
EOF

# Docker 재시작
sudo systemctl restart docker
```

---

### 디스크 공간 부족

**확인**:
```bash
df -h
docker system df
```

**정리**:
```bash
# Docker 정리
docker system prune -a

# 로그 정리
sudo journalctl --vacuum-time=3d
```

---

## 최적화

### ccache 설정

```bash
# ccache 설치
sudo apt install ccache  # Ubuntu/Debian
sudo dnf install ccache  # Fedora
sudo pacman -S ccache    # Arch

# 크기 설정
ccache -M 5G
```

---

### tmpfs 크기 조정

```bash
# 가용 RAM 확인
free -h

# build.config 생성
cat > build.config <<EOF
TMPFS_SIZE=$(( $(free -g | awk '/^Mem:/{print $7}') / 2 ))g
JOBS=$(nproc)
EOF
```

---

## 다음 단계

1. Docker 설치 완료
2. 프로젝트 클론
3. → [README.md](../README.md) - 빌드 시작
4. → [BEGINNER_GUIDE.md](BEGINNER_GUIDE.md) - 상세 가이드

---

**검토**: 사용자
**버전**: 1.0
**최종 수정**: 2026-01-21
