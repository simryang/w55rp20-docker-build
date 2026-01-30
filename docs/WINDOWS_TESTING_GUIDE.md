# Windows 테스터 가이드

## 개요

이 문서는 **Windows 환경에서 W55RP20 빌드 시스템을 테스트**하기 위한 가이드입니다.

**테스트 목표:**
- ✅ Linux 컨테이너 (WSL2 기반) 정상 작동 확인
- ✅ Windows 컨테이너 (네이티브) 정상 작동 확인
- ✅ 대화형 모드 UX 검증
- ✅ 문서 정확성 확인
- ✅ 에러 메시지 적절성 확인

**예상 시간:** 2-3시간 (최초 이미지 빌드 포함)

---

## 사전 준비

### 시스템 요구사항

- **OS**: Windows 10/11 (64-bit)
- **메모리**: 8GB 이상 (16GB 권장)
- **디스크**: 20GB 여유 공간
- **네트워크**: 안정적인 인터넷 (이미지 다운로드)

### 필수 소프트웨어

1. **Git for Windows**
   - 다운로드: https://git-scm.com/download/win
   - 설치 시 기본 옵션 사용

2. **Docker Desktop**
   - 다운로드: https://www.docker.com/products/docker-desktop
   - 설치 시 "Use WSL 2 instead of Hyper-V" 체크 (권장)
   - 설치 후 재부팅 필요할 수 있음

3. **PowerShell** (이미 설치되어 있음)
   - Windows 10/11 기본 포함

---

## 1단계: 저장소 클론

### PowerShell 실행

```powershell
# Windows 키 누르고 "PowerShell" 입력 후 실행
```

### 프로젝트 디렉토리로 이동

```powershell
# 홈 디렉토리로 이동
cd ~

# 또는 원하는 위치 (예: C:\Projects)
cd C:\Projects
```

### Git Clone

```powershell
# 저장소 클론 (URL은 실제 저장소 주소로 변경)
git clone https://github.com/YOUR_USERNAME/w55rp20-docker-build.git

# 디렉토리 이동
cd w55rp20-docker-build

# 파일 확인
ls

# 예상 출력:
#   Dockerfile
#   Dockerfile.windows
#   build.ps1
#   build-windows.ps1
#   build-native-windows.ps1
#   README.md
#   docs/
#   ...
```

---

## 2단계: Docker Desktop 확인

### Docker Desktop 실행

1. 시작 메뉴에서 "Docker Desktop" 실행
2. 시스템 트레이에 Docker 아이콘 나타날 때까지 대기 (약 1분)
3. 아이콘이 **초록색**이면 준비 완료

### Docker 상태 확인

```powershell
# Docker 버전 확인
docker --version
# 예상 출력: Docker version 24.x.x

# Docker 실행 확인
docker info
# 정상이면 시스템 정보 출력
# OSType: linux 또는 OSType: windows
```

**⚠️ 에러 발생 시:**
- Docker Desktop이 실행되지 않음 → Docker Desktop 재실행
- 권한 에러 → PowerShell을 관리자 권한으로 실행

---

## 3단계: 테스트 시나리오

### 📋 테스트 체크리스트

각 테스트 후 ✅ 또는 ❌ 표시:

```
[ ] 테스트 1: 대화형 모드 (Linux 컨테이너)
[ ] 테스트 2: 자동 모드 (현재 Docker 모드)
[ ] 테스트 3: 명시적 선택 (Linux 컨테이너)
[ ] 테스트 4: Windows 컨테이너 (모드 전환 필요)
[ ] 테스트 5: 모드 불일치 에러 처리
[ ] 테스트 6: Git Bash 호환성
[ ] 테스트 7: 도움말 및 버전 정보
```

---

### 테스트 1: 대화형 모드 (Linux 컨테이너) ⭐ 최우선

**목적:** 사용자 친화적인 대화형 인터페이스 검증

**명령:**
```powershell
.\build.ps1 -Interactive
```

**예상 동작:**

1. **배너 표시**
   ```
   ╔══════════════════════════════════════════════════════════════╗
   ║  W55RP20 통합 빌드 시스템 v1.2.0-unified                    ║
   ╚══════════════════════════════════════════════════════════════╝
   ```

2. **Docker 상태 확인**
   ```
   [INFO] Docker Desktop 상태 확인 중...
   [SUCCESS] Docker Desktop 실행 중 (현재 모드: linux containers)
   ```

3. **대화형 메뉴 표시**
   - [1] Linux 컨테이너 - 장점/단점/시간/용량 정보 표시
   - [2] Windows 컨테이너 - 장점/단점/시간/용량 정보 표시
   - [3] 자동 선택
   - 💡 추천 표시

4. **선택 프롬프트**
   ```
   선택하세요 [1-3] (기본값: 3): _
   ```

**테스트 절차:**

```powershell
# 1 입력 후 Enter
1

# 빌드 진행 관찰
# - 소스 클론 (최초 1회)
# - Docker 이미지 빌드 (최초 1회, 약 20분)
# - 펌웨어 빌드 (약 50초)
```

**성공 기준:**

- ✅ 메뉴가 정확하게 표시됨
- ✅ 시간/용량 정보가 명확함
- ✅ 빌드가 정상 완료됨
- ✅ 완료 메시지에 다음 사용법 안내가 포함됨
- ✅ `.\out\` 폴더에 `*.uf2` 파일 생성됨

**실제 확인:**

```powershell
# 산출물 확인
ls .\out\

# 예상 파일:
#   App.uf2
#   Boot.uf2
#   App_linker.uf2
#   SPI_Mode_Master.uf2
```

**기록할 사항:**
- [ ] 메뉴 표시 정상 여부
- [ ] 시간/용량 정보 정확성
- [ ] 빌드 시간 (분:초): __________
- [ ] 에러 발생 여부: __________
- [ ] 완료 메시지 유용성 (1-5점): __________

---

### 테스트 2: 자동 모드

**목적:** 빠른 빌드 (선택 없이)

**명령:**
```powershell
.\build.ps1
```

**예상 동작:**
- 대화형 메뉴 없이 바로 빌드 시작
- 현재 Docker 모드 자동 감지

**성공 기준:**
- ✅ 자동으로 빌드 시작
- ✅ 빌드 정상 완료

**기록할 사항:**
- [ ] 자동 감지 정상 여부
- [ ] 빌드 시간 (이미지 재사용): __________

---

### 테스트 3: 명시적 선택 (Linux 컨테이너)

**목적:** 명시적 플래그 동작 확인

**명령:**
```powershell
.\build.ps1 -Linux
```

**예상 동작:**
- 대화형 메뉴 없이 바로 Linux 컨테이너 빌드

**성공 기준:**
- ✅ 빌드 정상 완료

---

### 테스트 4: Windows 컨테이너 ⭐ 중요

**목적:** Windows 네이티브 컨테이너 검증

**⚠️ 주의:** Docker 모드 전환 필요!

**절차:**

1. **Docker 모드 전환**
   ```
   시스템 트레이 → Docker 아이콘 우클릭
   → "Switch to Windows containers..." 선택
   → "Switch" 버튼 클릭
   → 전환 완료 대기 (약 1분)
   ```

2. **확인**
   ```powershell
   docker info
   # OSType: windows 확인
   ```

3. **빌드 실행**
   ```powershell
   .\build.ps1 -Interactive
   # [2] Windows 컨테이너 선택
   ```

**예상 동작:**
- Windows 컨테이너 이미지 빌드 (최초 1회, 약 30-40분)
- 빌드 완료

**성공 기준:**
- ✅ 이미지 빌드 완료
- ✅ 빌드 정상 완료
- ✅ 산출물 생성

**⚠️ Windows 컨테이너 이슈:**
- Dockerfile.windows 문법 오류 가능
- PowerShell 스크립트 인코딩 문제 가능
- Nano Server 호환성 문제 가능

**기록할 사항:**
- [ ] 이미지 빌드 성공 여부
- [ ] 이미지 빌드 시간: __________
- [ ] 펌웨어 빌드 성공 여부
- [ ] 펌웨어 빌드 시간: __________
- [ ] 에러 발생 시 전체 에러 메시지:
  ```


  ```

---

### 테스트 5: 모드 불일치 에러 처리

**목적:** 친절한 에러 메시지 검증

**절차:**

1. **Docker를 Linux 모드로 유지**
   ```powershell
   docker info
   # OSType: linux 확인
   ```

2. **Windows 컨테이너 요청**
   ```powershell
   .\build.ps1 -Windows
   ```

**예상 동작:**
```
[WARN] Docker 모드 불일치!

  요청: windows 컨테이너
  현재: linux 컨테이너

해결 방법 (Windows containers로 전환):
  1. 시스템 트레이의 Docker 아이콘 우클릭
  2. 'Switch to Windows containers...' 선택
  3. 전환 완료 후 이 스크립트 재실행

또는:
  현재 모드(linux)로 빌드하려면: .\build.ps1 -Linux

그대로 종료하시겠습니까? [Y/n]: _
```

**성공 기준:**
- ✅ 모드 불일치 감지
- ✅ 명확한 해결 방법 제시
- ✅ 대안 제시 (현재 모드로 빌드)

**기록할 사항:**
- [ ] 에러 메시지 명확성 (1-5점): __________
- [ ] 해결 방법 유용성 (1-5점): __________

---

### 테스트 6: Git Bash 호환성

**목적:** Git Bash 사용자 지원 확인

**절차:**

1. **Git Bash 실행**
   ```
   시작 메뉴 → "Git Bash" 검색 → 실행
   ```

2. **프로젝트 디렉토리 이동**
   ```bash
   cd ~/w55rp20-docker-build
   # 또는 cd /c/Projects/w55rp20-docker-build
   ```

3. **빌드 실행**
   ```bash
   ./build-windows.sh
   ```

**예상 동작:**
- MSYS_NO_PATHCONV=1 자동 설정 메시지
- 빌드 정상 진행

**성공 기준:**
- ✅ 경로 변환 문제 없음
- ✅ 빌드 정상 완료

**기록할 사항:**
- [ ] Git Bash 실행 정상 여부
- [ ] 경로 처리 정상 여부
- [ ] 에러 발생 시 메시지:
  ```


  ```

---

### 테스트 7: 도움말 및 버전

**목적:** 문서화 품질 확인

**명령:**
```powershell
# 도움말
.\build.ps1 -Help

# 버전 정보
.\build.ps1 --version  # (미구현 시 스킵 가능)
```

**성공 기준:**
- ✅ 도움말이 명확하고 유용함
- ✅ 모든 옵션이 설명되어 있음

---

## 4단계: 고급 테스트 (선택)

### 테스트 8: 사용자 프로젝트 빌드

**절차:**

1. **테스트 프로젝트 클론**
   ```powershell
   cd ~
   git clone --recurse-submodules https://github.com/WIZnet-ioNIC/W55RP20-S2E.git W55RP20-S2E-test
   ```

2. **사용자 프로젝트로 빌드**
   ```powershell
   cd w55rp20-docker-build
   .\build.ps1 -Linux -Project "$HOME\W55RP20-S2E-test"
   ```

**성공 기준:**
- ✅ 외부 프로젝트 빌드 성공

---

### 테스트 9: 디버그 빌드

**명령:**
```powershell
.\build.ps1 -Linux -BuildType Debug -Verbose
```

**성공 기준:**
- ✅ Debug 모드 빌드 성공
- ✅ Verbose 출력 유용함

---

### 테스트 10: Clean 빌드

**명령:**
```powershell
.\build.ps1 -Linux -Clean
```

**성공 기준:**
- ✅ 기존 산출물 삭제 후 재빌드

---

## 5단계: 문서 검증

### 체크리스트

```
[ ] docs/WINDOWS_ALL_IN_ONE.md - 내용 정확성
[ ] docs/WINDOWS_CONTAINER_COMPARISON.md - 비교표 정확성
[ ] docs/WINDOWS_QUICK_START.md - 설치 가이드 유효성
[ ] docs/INTERACTIVE_MODE_DEMO.md - 실제 화면과 일치성
```

**검증 방법:**
1. 각 문서를 읽으며 실제 동작과 비교
2. 불일치/오류 발견 시 기록

---

## 6단계: 피드백 제출

### 피드백 양식

```markdown
# Windows 테스트 피드백

## 테스트 환경
- Windows 버전: (예: Windows 11 Pro 23H2)
- Docker Desktop 버전: (예: 4.25.0)
- 테스트 날짜: YYYY-MM-DD

## 테스트 결과

### 테스트 1: 대화형 모드 (Linux 컨테이너)
- 결과: ✅ 성공 / ❌ 실패
- 빌드 시간: XX분 XX초
- 메뉴 UX: X/5점
- 발견한 문제:
  - (있다면 기록)

### 테스트 2: 자동 모드
- 결과: ✅ / ❌
- 빌드 시간: XX초
- 발견한 문제:

... (각 테스트별로 기록)

## 전체 평가

### 장점
1.
2.
3.

### 개선 필요
1.
2.
3.

### 발견한 버그
1.
2.

### 문서 개선 제안
1.
2.

## 추가 의견
(자유롭게 작성)

```

### 제출 방법

**옵션 1: GitHub Issue**
```
저장소 → Issues → New Issue
제목: [Windows 테스트] 피드백
내용: 위 양식 복사하여 작성
```

**옵션 2: 이메일**
```
수신: [개발자 이메일]
제목: W55RP20 Windows 테스트 피드백
첨부: 위 양식을 .txt 또는 .md 파일로
```

**옵션 3: Pull Request**
```
저장소 Fork →
TESTING_RESULTS/[your-name]-YYYY-MM-DD.md 생성 →
Pull Request 제출
```

---

## 문제 해결

### 자주 발생하는 문제

#### Q1: "Docker Desktop이 실행되지 않았습니다"

**원인:** Docker Desktop 미실행

**해결:**
1. 시작 메뉴 → Docker Desktop 실행
2. 시스템 트레이 아이콘이 초록색이 될 때까지 대기
3. 스크립트 재실행

---

#### Q2: "WSL 2 installation is incomplete"

**원인:** WSL2 미설치

**해결:**
```powershell
# PowerShell (관리자 권한)
wsl --install
```
재부팅 후 Docker Desktop 재실행

---

#### Q3: PowerShell 실행 정책 에러

**에러:**
```
.\build.ps1 cannot be loaded because running scripts is disabled on this system
```

**해결:**
```powershell
# PowerShell (관리자 권한)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

#### Q4: Git Bash에서 경로 에러

**에러:**
```
C:/Program Files/Git/c/Users/... : No such file or directory
```

**해결:**
```bash
export MSYS_NO_PATHCONV=1
./build-windows.sh
```

스크립트가 자동으로 설정하므로 이 에러는 발생하지 않아야 함!

---

## 연락처

**질문/문제 발생 시:**
- GitHub Issues: [저장소 URL]/issues
- 이메일: [개발자 이메일]

**긴급한 경우:**
- [Slack/Discord 채널]

---

## 감사합니다!

테스트에 참여해주셔서 감사합니다. 여러분의 피드백이 프로젝트를 더 좋게 만듭니다! 🙏

---

**문서 버전:** 1.0
**최종 업데이트:** 2026-01-28
