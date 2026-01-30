# DockerHub + GitHub 배포 전략

## 개요

**ZIP 파일 배포의 문제점:**
- ✅ 실제로는 143KB로 작음
- ❌ 하지만 테스터가 20분 이미지 빌드 필요
- ❌ 버전 관리 어려움

**DockerHub + GitHub 배포의 장점:**
- ✅ 테스터는 `git clone` 후 바로 실행
- ✅ 이미지는 DockerHub에서 자동 다운로드 (빌드 불필요!)
- ✅ GitHub Issues로 피드백 수집
- ✅ 버전 관리 자동
- ✅ 전문적인 배포

---

## 배포 전략

### 1단계: Linux 이미지 DockerHub 배포

**현재 상태:**
- ✅ Linux 이미지 빌드됨 (w55rp20:auto, 2.44GB)
- ❌ Windows 이미지 없음 (Linux에서 빌드 불가)

**배포 계획:**
```
DockerHub:
  - YOUR_USERNAME/w55rp20:linux (Linux 컨테이너용)
  - YOUR_USERNAME/w55rp20:windows (나중에 Windows에서 빌드)
  - YOUR_USERNAME/w55rp20:latest → linux로 alias
```

---

### 2단계: GitHub 저장소 배포

**옵션 A: 새 공개 저장소 (권장)**
```
Repository name: w55rp20-docker-build
Description: W55RP20 firmware build system with Docker (Linux + Windows containers)
Public
```

**옵션 B: 기존 저장소에 브랜치**
```
Branch: windows-support
```

---

## 실행 방법

### Step 1: DockerHub 로그인 및 준비

```bash
# DockerHub 로그인
docker login
# Username: YOUR_USERNAME
# Password: [토큰 또는 비밀번호]

# 또는 토큰 사용 (권장)
echo "YOUR_PERSONAL_ACCESS_TOKEN" | docker login -u YOUR_USERNAME --password-stdin
```

**DockerHub Personal Access Token 생성:**
1. https://hub.docker.com/ 로그인
2. Account Settings → Security → New Access Token
3. Description: "w55rp20-deployment"
4. Permissions: Read, Write, Delete
5. Generate → 토큰 복사

---

### Step 2: Linux 이미지 태깅 및 Push

```bash
# 현재 이미지 확인
docker images | grep w55rp20
# w55rp20  auto  7ad6b3e18948  11 days ago  2.44GB

# DockerHub용 태그 생성
docker tag w55rp20:auto YOUR_USERNAME/w55rp20:linux
docker tag w55rp20:auto YOUR_USERNAME/w55rp20:latest
docker tag w55rp20:auto YOUR_USERNAME/w55rp20:1.2.0

# DockerHub에 Push (시간 소요: 10-20분, 2.44GB)
docker push YOUR_USERNAME/w55rp20:linux
docker push YOUR_USERNAME/w55rp20:latest
docker push YOUR_USERNAME/w55rp20:1.2.0

# Push 완료 확인
# https://hub.docker.com/r/YOUR_USERNAME/w55rp20/tags
```

---

### Step 3: GitHub 저장소 생성 및 Push

#### A. GitHub 저장소 생성 (웹사이트)

```
1. https://github.com/new
2. Repository name: w55rp20-docker-build
3. Description: W55RP20 firmware build system with Docker (All-in-One: Linux + Windows containers)
4. Public
5. ❌ README, .gitignore, license 체크 해제 (이미 있음)
6. Create repository
```

#### B. Git 설정 및 Push

```bash
cd /home/sr/src/docker/w55rp20

# 원격 저장소 추가
git remote add origin https://github.com/YOUR_USERNAME/w55rp20-docker-build.git

# 또는 SSH (권장)
git remote add origin git@github.com:YOUR_USERNAME/w55rp20-docker-build.git

# Push (모든 커밋)
git push -u origin master

# GitHub에서 확인
# https://github.com/YOUR_USERNAME/w55rp20-docker-build
```

---

### Step 4: README 업데이트 (DockerHub 이미지 사용)

```bash
# README.md 수정 필요:
# 1. DockerHub 이미지 pull 안내 추가
# 2. 빌드 없이 바로 실행하는 방법 강조
# 3. 이미지 빌드는 선택사항으로 변경
```

**추가할 내용:**
```markdown
## 빠른 시작 (Windows)

### 준비물
- Docker Desktop 설치 및 실행 중
- Git for Windows 설치

### 실행 (이미지 빌드 불필요!)

```powershell
# 1. 저장소 클론
git clone https://github.com/YOUR_USERNAME/w55rp20-docker-build.git
cd w55rp20-docker-build

# 2. 대화형 모드 실행
.\build.ps1 -Interactive

# 또는 자동 모드
.\build.ps1
```

**이미지는 자동으로 DockerHub에서 다운로드됩니다!** (20분 빌드 불필요)

### 이미지 직접 빌드 (선택사항)

DockerHub 이미지 대신 직접 빌드하려면:

```powershell
.\build.ps1 -Interactive -BuildImage
```
```

---

### Step 5: build.ps1 수정 (DockerHub 이미지 우선)

**현재 동작:**
1. 이미지 확인 (w55rp20:auto)
2. 없으면 빌드

**개선 동작:**
1. 이미지 확인 (w55rp20:auto)
2. 없으면 **DockerHub에서 pull** (YOUR_USERNAME/w55rp20:linux)
3. `-BuildImage` 플래그 있으면 직접 빌드

**수정 필요 부분:**
```powershell
# build.ps1 (현재)
if (!(docker images -q $IMAGE 2>$null)) {
    Write-Host "[INFO] 이미지($IMAGE) 없음"
    Write-Host "[INFO] 이미지 빌드 실행 (PLATFORM=$PLATFORM)"
    # ... 빌드 ...
}

# build.ps1 (개선)
if (!(docker images -q $IMAGE 2>$null)) {
    Write-Host "[INFO] 이미지($IMAGE) 없음"

    if ($BuildImage) {
        Write-Host "[INFO] 이미지 빌드 실행 (PLATFORM=$PLATFORM)"
        # ... 빌드 ...
    } else {
        Write-Host "[INFO] DockerHub에서 이미지 다운로드 중..."
        $DOCKER_HUB_IMAGE = "YOUR_USERNAME/w55rp20:linux"
        docker pull $DOCKER_HUB_IMAGE
        docker tag $DOCKER_HUB_IMAGE $IMAGE
        Write-Host "[SUCCESS] 이미지 다운로드 완료"
    }
}
```

---

### Step 6: 테스터 초대 메시지 (간소화)

**이메일/메시지 템플릿:**

```
제목: W55RP20 Windows 빌드 시스템 테스트 요청

안녕하세요,

W55RP20 펌웨어의 Windows 빌드 시스템을 개발했습니다.
GitHub + DockerHub 기반으로 매우 간단하게 테스트할 수 있습니다.

📦 저장소:
https://github.com/YOUR_USERNAME/w55rp20-docker-build

🚀 빠른 시작 (3분):

1. Git Bash 또는 PowerShell에서:
   git clone https://github.com/YOUR_USERNAME/w55rp20-docker-build.git
   cd w55rp20-docker-build

2. 대화형 모드 실행:
   .\build.ps1 -Interactive

3. 메뉴에서 [1] 선택
   → 이미지 자동 다운로드 (최초 1회, 약 5분)
   → 빌드 자동 실행 (약 50초)

✅ 장점:
  - 20분 이미지 빌드 불필요! (DockerHub에서 자동 다운로드)
  - git clone 후 바로 실행 가능
  - GitHub Issues로 쉽게 피드백 가능

📖 상세 가이드:
https://github.com/YOUR_USERNAME/w55rp20-docker-build/blob/master/WINDOWS_TESTING_GUIDE.md

💬 피드백:
GitHub Issues로 제출:
https://github.com/YOUR_USERNAME/w55rp20-docker-build/issues

⏱️ 예상 시간:
  - 환경 준비: 30분 (Docker Desktop 설치)
  - 최초 실행: 5분 (이미지 다운로드) + 50초 (빌드)
  - 이후 실행: 12초 (ccache)

감사합니다!
```

---

## Windows 이미지 처리 방법

**문제:** Windows 컨테이너 이미지는 Linux에서 빌드 불가

**옵션 1: 테스터가 직접 빌드 (현재 구현)**
```powershell
.\build.ps1 -Windows
# → 최초 30-40분 빌드
# → DockerHub에 없으므로 로컬 빌드 필요
```

**옵션 2: Windows 환경에서 빌드 후 DockerHub에 Push**
```
1. Windows 테스터 중 한 명이 이미지 빌드
2. DockerHub에 Push:
   docker tag w55rp20:windows-auto YOUR_USERNAME/w55rp20:windows
   docker push YOUR_USERNAME/w55rp20:windows
3. 이후 테스터는 자동 다운로드 가능
```

**옵션 3: GitHub Actions with Windows Runner (고급)**
```yaml
# .github/workflows/build-windows-image.yml
name: Build Windows Container Image

on:
  push:
    branches: [ master ]

jobs:
  build-windows:
    runs-on: windows-2022
    steps:
      - uses: actions/checkout@v3
      - name: Build Windows container image
        run: docker build -f Dockerfile.windows -t ${{ secrets.DOCKERHUB_USERNAME }}/w55rp20:windows .
      - name: Push to DockerHub
        run: |
          echo "${{ secrets.DOCKERHUB_TOKEN }}" | docker login -u ${{ secrets.DOCKERHUB_USERNAME }} --password-stdin
          docker push ${{ secrets.DOCKERHUB_USERNAME }}/w55rp20:windows
```

**권장:** 옵션 1 (테스터 직접 빌드) → 나중에 옵션 2

---

## 체크리스트

### 배포 전 (로컬 작업)

```bash
[ ] DockerHub 계정 확인
[ ] DockerHub Personal Access Token 생성
[ ] docker login 성공
[ ] Linux 이미지 태깅 (YOUR_USERNAME/w55rp20:linux)
[ ] GitHub 저장소 생성 (w55rp20-docker-build)
[ ] git remote add origin 완료
```

---

### 배포 (Push)

```bash
[ ] docker push YOUR_USERNAME/w55rp20:linux (10-20분 소요)
[ ] docker push YOUR_USERNAME/w55rp20:latest
[ ] docker push YOUR_USERNAME/w55rp20:1.2.0
[ ] git push origin master
[ ] DockerHub 저장소 public 확인
[ ] GitHub 저장소 public 확인
```

---

### 배포 후 (수정 작업)

```bash
[ ] README.md 업데이트 (DockerHub pull 안내)
[ ] build.ps1 수정 (DockerHub 우선)
[ ] build-windows.ps1 수정 (DockerHub 우선)
[ ] build-native-windows.ps1 수정 (DockerHub 우선)
[ ] 커밋 및 Push
[ ] 테스터 초대 메시지 발송
```

---

## 예상 테스터 경험

### 최초 실행

```powershell
PS C:\> git clone https://github.com/YOUR_USERNAME/w55rp20-docker-build.git
Cloning into 'w55rp20-docker-build'...
remote: Enumerating objects: 50, done.
remote: Total 50 (delta 0), reused 0 (delta 0), pack-reused 50
Receiving objects: 100% (50/50), 143 KiB, done.

PS C:\> cd w55rp20-docker-build

PS C:\w55rp20-docker-build> .\build.ps1 -Interactive

╔══════════════════════════════════════════════════════════════╗
║  W55RP20 통합 빌드 시스템 v1.2.0-unified                    ║
╚══════════════════════════════════════════════════════════════╝

[INFO] Docker Desktop 상태 확인 중...
[SUCCESS] Docker Desktop 실행 중 (현재 모드: linux containers)

선택하세요 [1-3] (기본값: 3): 1

[INFO] Linux 컨테이너를 선택했습니다
[INFO] 이미지(w55rp20:auto) 없음
[INFO] DockerHub에서 이미지 다운로드 중...

linux: Pulling from YOUR_USERNAME/w55rp20
Digest: sha256:abc123...
Status: Downloaded newer image for YOUR_USERNAME/w55rp20:linux

[SUCCESS] 이미지 다운로드 완료
[INFO] 빌드 시작...

... (빌드 진행) ...

🎉 빌드 완료! 🎉
```

**소요 시간:**
- 이미지 다운로드: 5분 (2.44GB, 최초 1회)
- 빌드: 50초 → 12초 (ccache)

**vs 기존 ZIP 방식:**
- 이미지 빌드: 20분 (매번)
- 빌드: 50초 → 12초 (ccache)

**시간 절약:** 15분! ⭐

---

## 비용 및 제한

### DockerHub Free Tier
- ✅ Public 저장소: 무제한
- ✅ Pull: 무제한 (인증된 사용자)
- ✅ Storage: 무제한 (public)
- ❌ Pull: 200/6시간 (미인증 사용자)

**해결:** 테스터에게 DockerHub 계정 생성 및 로그인 요청 (선택)

---

### GitHub Free
- ✅ Public 저장소: 무제한
- ✅ Issues/PRs: 무제한
- ✅ GitHub Actions: 2,000분/월 (Windows runner는 2배 계산)

---

## 요약

### 현재 방식 (ZIP)
```
테스터:
  1. ZIP 다운로드
  2. 압축 해제
  3. .\build.ps1 -Interactive
  4. 이미지 빌드 20분 대기 😴
  5. 펌웨어 빌드 50초
```

### 개선 방식 (DockerHub + GitHub)
```
테스터:
  1. git clone (143KB, 5초)
  2. .\build.ps1 -Interactive
  3. 이미지 다운로드 5분 대기 ☕
  4. 펌웨어 빌드 50초
```

**시간 절약: 15분! 🚀**

---

## 다음 단계

### 즉시 실행 가능 (DockerHub 계정 있으면)

```bash
# Step 1: DockerHub 로그인
docker login

# Step 2: 이미지 태깅
docker tag w55rp20:auto YOUR_USERNAME/w55rp20:linux
docker tag w55rp20:auto YOUR_USERNAME/w55rp20:latest

# Step 3: Push (10-20분)
docker push YOUR_USERNAME/w55rp20:linux
docker push YOUR_USERNAME/w55rp20:latest

# Step 4: GitHub 저장소 생성 (웹)
# https://github.com/new

# Step 5: Git Push
git remote add origin https://github.com/YOUR_USERNAME/w55rp20-docker-build.git
git push -u origin master

# Step 6: README 업데이트 (DockerHub 안내)
# Step 7: build.ps1 수정 (DockerHub 우선)
# Step 8: 커밋 및 Push
# Step 9: 테스터 초대!
```

---

**문서 작성:** 2026-01-28
**대상:** Linux → Windows 배포 (전문적인 방법)
