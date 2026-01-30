# W55RP20 Docker Build System v1.2.0

WIZnet W55RP20 펌웨어 Docker 빌드 시스템 - **Windows 초보자 친화적!**

---

## 🚀 빠른 시작 (Windows)

### 1️⃣ 준비물 설치

**필수 프로그램 2개만 설치:**

1. **Docker Desktop**: https://www.docker.com/products/docker-desktop
   - 다운로드 → 설치 → 재부팅
   - 설치 후 Docker Desktop 실행 (시스템 트레이 확인)

2. **Git for Windows**: https://git-scm.com/download/win
   - 다운로드 → 설치 (기본 옵션 그대로)

---

### 2️⃣ 빌드 실행 (Copy & Paste)

**PowerShell 또는 Git Bash 열고 아래 명령어 복사 후 실행:**

```powershell
git clone https://github.com/simryang/w55rp20-docker-build.git
cd w55rp20-docker-build
powershell -ExecutionPolicy Bypass -File .\build.ps1 -Interactive
```

> **💡 참고:** `powershell -ExecutionPolicy Bypass`는 스크립트 실행 권한 문제를 우회합니다.
> 또는 PowerShell을 관리자 권한으로 열고 `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` 실행 후 `.\build.ps1 -Interactive`로 간단히 실행 가능합니다.

**대화형 모드 진행 방법:**

1. **컨테이너 타입 선택** 화면이 나오면:
   - Linux 컨테이너 (권장): `1` 입력 → Enter
   - Windows 컨테이너: `2` 입력 → Enter
   - 자동 선택: `3` 입력 → Enter (또는 그냥 Enter)

2. **빌드 설정 확인** 화면이 나오면:
   - 계속 진행: `y` 입력 → Enter (또는 그냥 Enter)
   - 취소: `n` 입력 → Enter

**예시 (Linux 컨테이너 선택):**
```
선택하세요 [1-3] (기본값: 3): 1          ← 1 입력 후 Enter
계속하시겠습니까? [Y/n]: y                ← y 입력 후 Enter (또는 그냥 Enter)
```

**이후 자동 진행:**
- Docker 이미지 다운로드 (최초 1회, 약 5분)
- 프로젝트 클론 및 빌드 (약 50초)
- 완료 메시지 및 산출물 위치 안내

---

### 3️⃣ 완료!

**산출물 위치:** `.\out\*.uf2`

**소요 시간:**
- 최초 실행: 약 6분 (이미지 다운로드 5분 + 빌드 50초)
- 이후 실행: 약 12초 (캐시 사용)

---

## 💡 다음 빌드부터는

### 간단 실행

**같은 프로젝트 재빌드 (자동 모드):**
```powershell
.\build.ps1
```

**대화형 모드 (옵션 선택):**
```powershell
.\build.ps1 -Interactive
```

### 주요 옵션

**컨테이너 타입 지정:**
```powershell
.\build.ps1 -Linux          # Linux 컨테이너 강제 사용 (권장)
.\build.ps1 -Windows        # Windows 컨테이너 강제 사용
.\build.ps1 -Auto           # 현재 Docker 모드에 따라 자동 선택
```

**프로젝트 경로 지정:**
```powershell
.\build.ps1 -Project "C:\Users\yourname\my-w55rp20-project"
```

**빌드 타입:**
```powershell
.\build.ps1 -BuildType Debug    # 디버그 빌드 (디버깅 심볼 포함)
.\build.ps1 -BuildType Release  # 릴리즈 빌드 (최적화, 기본값)
```

**산출물 경로:**
```powershell
.\build.ps1 -Output "D:\build-output"  # 기본값: .\out
```

**기타 옵션:**
```powershell
.\build.ps1 -Clean          # 이전 빌드 산출물 삭제 후 빌드
.\build.ps1 -UpdateRepo     # Git 레포지토리 업데이트
.\build.ps1 -NoConfirm      # 확인 없이 즉시 실행
.\build.ps1 -Verbose        # 상세 출력
.\build.ps1 -Jobs 8         # 병렬 작업 수 지정 (기본값: 16)
```

### 옵션 조합 예시

```powershell
# 사용자 프로젝트를 디버그 모드로 빌드
.\build.ps1 -Linux -Project "C:\my-project" -BuildType Debug

# 정리 후 릴리즈 빌드, 확인 없이 실행
.\build.ps1 -Clean -NoConfirm

# 커스텀 산출물 경로, 상세 로그
.\build.ps1 -Output "D:\builds" -Verbose
```

**도움말:**
```powershell
.\build.ps1 -Help
```

---

## 📖 상세 문서

### Windows 사용자
- **[WINDOWS_ALL_IN_ONE.md](docs/WINDOWS_ALL_IN_ONE.md)** - 완벽 가이드 (모든 기능 설명)
- **[INTERACTIVE_MODE_DEMO.md](docs/INTERACTIVE_MODE_DEMO.md)** - 실제 화면 시연
- **[WINDOWS_TESTING_GUIDE.md](WINDOWS_TESTING_GUIDE.md)** - 테스트 가이드
- **[WINDOWS_CONTAINER_COMPARISON.md](docs/WINDOWS_CONTAINER_COMPARISON.md)** - Linux vs Windows 컨테이너 비교

### 문제 해결
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - 자주 발생하는 문제 해결

---

## 📺 실행 화면 예시

<details>
<summary>클릭하여 전체 실행 과정 보기</summary>

### 1단계: 스크립트 실행
```powershell
PS C:\> cd w55rp20-docker-build
PS C:\w55rp20-docker-build> powershell -ExecutionPolicy Bypass -File .\build.ps1 -Interactive

╔══════════════════════════════════════════════════════════════╗
║  W55RP20 통합 빌드 시스템 v1.2.0-unified                    ║
║  Linux 컨테이너 + Windows 컨테이너 All-in-One              ║
╚══════════════════════════════════════════════════════════════╝

[INFO] Docker Desktop 상태 확인 중...
[SUCCESS] Docker Desktop 실행 중 (현재 모드: linux containers)
```

### 2단계: 컨테이너 선택
```
═══════════════════════════════════════════════════════════════
  컨테이너 타입을 선택하세요
═══════════════════════════════════════════════════════════════

  [1] Linux 컨테이너 (크로스 플랫폼)

      장점:
        [O] Linux/macOS/Windows 모두 사용 가능
        [O] 팀 개발 최적 (환경 통일)
        [O] CI/CD 완벽 호환 (GitHub Actions 등)
        [O] 표준적 (전 세계 Docker의 99%)

      단점:
        [!] WSL2 필요 (Docker Desktop이 자동 설치)
        [!] 약간의 성능 오버헤드 (6%, 실용적 수준)

      시간/용량:
        [T] 최초 빌드: 약 20분 (이미지 생성)
        [T] 이후 빌드: 약 50초 → 12초 (ccache)
        [D] 이미지 크기: 2GB
        [D] 디스크 여유: 5GB 권장

  [2] Windows 컨테이너 (네이티브)
      ...

  [3] 자동 선택 (현재 Docker 모드: linux)

[i] 추천: [1] Linux 컨테이너 (현재 모드와 일치)

선택하세요 [1-3] (기본값: 3): 1                    ← 1 입력 후 Enter
[INFO] Linux 컨테이너를 선택했습니다
```

### 3단계: 빌드 설정 확인
```
[INFO] 빌드 준비 중...

[SUCCESS] Linux 컨테이너 빌드 시작 (WSL2 기반)

특징:
  [O] 크로스 플랫폼 (Linux/macOS/Windows)
  [O] CI/CD 완벽 호환
  [O] 표준 Docker 경험

[INFO] W55RP20 Build System for Windows v1.1.0-windows

[SUCCESS] Docker Desktop 실행 중
[INFO] 공식 프로젝트 사용 (클론 필요 시 자동)

빌드 설정:
  프로젝트: C:\Users\yourname\W55RP20-S2E
  산출물:   C:\w55rp20-docker-build\out
  빌드타입: Release
  병렬작업: 16

계속하시겠습니까? [Y/n]: y                          ← y 입력 또는 그냥 Enter
```

### 4단계: 자동 빌드 진행
```
[INFO] Docker 이미지 확인 중...
[INFO] 로컬 이미지(w55rp20:latest) 없음
[INFO] DockerHub에서 이미지 다운로드 중... (최초 1회, 약 5분)
  이미지: simryang/w55rp20:latest

latest: Pulling from simryang/w55rp20
abc123def456: Downloading [=>                ] 12.3MB/500MB
...
[SUCCESS] 이미지 다운로드 완료
[INFO] 이미지 준비 완료: w55rp20:latest

[INFO] 프로젝트 클론 중...
Cloning into 'C:\Users\yourname\W55RP20-S2E'...
[SUCCESS] 클론 완료

[INFO] 빌드 시작...
...
[SUCCESS] 빌드 완료!
```

### 5단계: 완료 및 다음 단계 안내
```
╔══════════════════════════════════════════════════════════════╗
║                   빌드 완료!                                 ║
╚══════════════════════════════════════════════════════════════╝

[>] 산출물 위치:
   C:\w55rp20-docker-build\out

[*] W55RP20에 펌웨어 업로드하는 방법:

   1. W55RP20 보드의 BOOTSEL 버튼을 누른 채로 USB 연결
   2. Windows가 'RPI-RP2' 드라이브로 인식
   3. C:\w55rp20-docker-build\out\*.uf2 파일을 드라이브에 복사
   4. 자동으로 재부팅 및 펌웨어 업로드 완료!

[>] 다음 빌드 방법:

   공식 프로젝트 재빌드:
     .\build.ps1 -Linux

   사용자 프로젝트 빌드:
     .\build.ps1 -Linux -Project "C:\Users\yourname\your-project"

[i] 팁: 이후 빌드는 훨씬 빠릅니다! (이미지 재사용)
```

</details>

---

## 🎯 주요 특징

### ✅ 초보자 친화적
- **딸깍 딸깍 3단계**로 끝
- Docker, Linux 몰라도 OK
- 자동으로 모든 것을 처리

### ✅ 빠른 빌드
- DockerHub 이미지 사전 제공 (이미지 빌드 불필요!)
- ccache 자동 사용 (2번째부터 12초)
- RAM 빌드로 SSD 보호

### ✅ 두 가지 옵션
- **Linux 컨테이너** (권장): 크로스 플랫폼, CI/CD 완벽 호환
- **Windows 컨테이너** (선택): WSL2 불필요, Windows 네이티브

### ✅ 완벽한 안내
- 대화형 모드: 장단점, 시간, 용량 정보 제공
- 완료 메시지: 다음 할 일 안내
- 에러 메시지: 해결 방법 제시

---

## ❓ 자주 묻는 질문 (FAQ)

### Q: PowerShell 스크립트 실행 시 "이 시스템에서 스크립트를 실행할 수 없습니다" 오류
**A:** PowerShell 실행 정책 때문입니다. 아래 방법 중 하나를 선택하세요.

**방법 1 (권장): 실행 시마다 우회**
```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1 -Interactive
```

**방법 2: 영구 설정 변경**
```powershell
# PowerShell을 관리자 권한으로 실행 후
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# 이후 간단히 실행 가능
.\build.ps1 -Interactive
```

### Q: Docker Desktop 설치 중 "WSL 2 installation is incomplete" 에러
**A:** 정상입니다. Docker Desktop이 자동으로 WSL2를 설치합니다.
- 안내에 따라 재부팅
- Docker Desktop 다시 실행
- 문제 지속 시: [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) 참고

### Q: 첫 실행이 느린데 정상인가요?
**A:** 네! 최초 1회는 Docker 이미지를 다운로드합니다 (약 5분).
- 2.44GB 이미지 다운로드
- 이후 실행은 12초로 빠릅니다
- 진행 상황이 화면에 표시됩니다

### Q: Interactive 모드에서 어떤 옵션을 선택해야 하나요?
**A:**
- **[1] Linux 컨테이너** (권장): 가장 안정적이고 빠름. 팀 개발, CI/CD에 적합
- **[2] Windows 컨테이너**: WSL2 없이 네이티브 실행. Windows 전용
- **[3] 자동 선택**: 현재 Docker 모드 사용 (기본값)

대부분의 경우 **1번 (Linux 컨테이너)**을 선택하세요.

### Q: 빌드된 파일은 어떻게 W55RP20에 올리나요?
**A:**
1. W55RP20 보드의 BOOTSEL 버튼을 누른 채로 USB 연결
2. Windows가 'RPI-RP2' 드라이브로 인식
3. `.\out\*.uf2` 파일을 드라이브에 복사
4. 자동으로 재부팅 및 펌웨어 업로드 완료!

### Q: Git Bash vs PowerShell?
**A:** 둘 다 가능합니다.
- **PowerShell** (권장): Windows 기본 제공, Interactive 모드 지원
- **Git Bash**: Git for Windows 설치 시 포함, Linux 스타일 명령어

### Q: Docker Desktop 라이선스 비용?
**A:** 개인 및 소규모 기업(직원 250명 미만, 매출 $10M 미만)은 무료입니다.

---

## 🐧 Linux / macOS 사용자

<details>
<summary>클릭하여 Linux/macOS 가이드 보기</summary>

### 빠른 시작 (Linux)

```bash
# 1. 처음 사용 (대화형 설정)
./build.sh --setup

# 2. 또는 기본 빌드
./build.sh

# 3. 산출물 확인
ls -l ./out/
```

**첫 실행:** 약 20분 (Docker 이미지 빌드)
**이후 빌드:** 약 2-3분 → 12초 (ccache)

### 요구사항 (Linux)
- Docker 설치 및 실행 중
- Git 설치
- 16GB+ RAM 권장

### 상세 문서 (Linux)
- **[INSTALL_LINUX.md](docs/INSTALL_LINUX.md)** - Linux 설치 가이드
- **[INSTALL_MAC.md](docs/INSTALL_MAC.md)** - macOS 설치 가이드
- **[USER_GUIDE.md](docs/USER_GUIDE.md)** - 사용자 가이드
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - 아키텍처 문서

### CLI 옵션 (Linux)

```bash
# 사용자 프로젝트 빌드
./build.sh --project /path/to/your/project

# 산출물 경로 지정
./build.sh --output /custom/output/path

# 디버그 빌드
./build.sh --debug

# 정리 후 빌드
./build.sh --clean

# 도움말
./build.sh --help
```

### 외부 리소스 업데이트

```bash
REFRESH="apt" ./build.sh         # apt 패키지 재설치
REFRESH="sdk" ./build.sh         # Pico SDK 최신 버전
REFRESH="toolchain" ./build.sh   # CMake + GCC 재설치
REFRESH="all" ./build.sh         # 전체 재설치
```

### 로컬 설정 (고급)

```bash
cp build.config.example build.config
vim build.config  # JOBS, TMPFS_SIZE 조정
./build.sh        # 설정 자동 로드
```

</details>

---

## 📚 전체 문서 목록

### 설치 가이드
| 문서 | 대상 |
|------|------|
| **[INSTALL_WINDOWS.md](docs/INSTALL_WINDOWS.md)** | Windows 10/11 |
| **[INSTALL_LINUX.md](docs/INSTALL_LINUX.md)** | Ubuntu, Debian 등 |
| **[INSTALL_MAC.md](docs/INSTALL_MAC.md)** | macOS |
| **[INSTALL_RASPBERRY_PI.md](docs/INSTALL_RASPBERRY_PI.md)** | Raspberry Pi |

### 사용 가이드
| 문서 | 내용 |
|------|------|
| **[USER_GUIDE.md](docs/USER_GUIDE.md)** | 상세 사용 가이드 |
| **[BEGINNER_GUIDE.md](docs/BEGINNER_GUIDE.md)** | 초보자 가이드 |
| **[EXAMPLES.md](docs/EXAMPLES.md)** | 예제 모음 |
| **[QUICKREF.md](docs/QUICKREF.md)** | 빠른 참조 |

### Windows 전용
| 문서 | 내용 |
|------|------|
| **[WINDOWS_ALL_IN_ONE.md](docs/WINDOWS_ALL_IN_ONE.md)** | Windows 완벽 가이드 |
| **[WINDOWS_QUICK_START.md](docs/WINDOWS_QUICK_START.md)** | Windows 빠른 시작 |
| **[WINDOWS_SUPPORT.md](docs/WINDOWS_SUPPORT.md)** | Windows 지원 개요 |
| **[WINDOWS_CONTAINER_COMPARISON.md](docs/WINDOWS_CONTAINER_COMPARISON.md)** | 컨테이너 비교 |
| **[INTERACTIVE_MODE_DEMO.md](docs/INTERACTIVE_MODE_DEMO.md)** | 대화형 모드 시연 |
| **[WINDOWS_TESTING_GUIDE.md](WINDOWS_TESTING_GUIDE.md)** | 테스트 가이드 |

### 개발자 문서
| 문서 | 내용 |
|------|------|
| **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** | 시스템 아키텍처 |
| **[BUILD_LOGS.md](docs/BUILD_LOGS.md)** | 빌드 로그 분석 |
| **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** | 문제 해결 |
| **[GLOSSARY.md](docs/GLOSSARY.md)** | 용어 사전 |
| **[CHANGELOG.md](docs/CHANGELOG.md)** | 변경 이력 |

---

## 🔗 링크

- **GitHub 저장소**: https://github.com/simryang/w55rp20-docker-build
- **DockerHub 이미지**: https://hub.docker.com/r/simryang/w55rp20
- **Issues**: https://github.com/simryang/w55rp20-docker-build/issues

---

## 🎯 버전 정보

**현재 버전:** v1.2.0-unified

**주요 변경사항:**
- ✅ Windows All-in-One 지원 (Linux + Windows 컨테이너)
- ✅ 대화형 모드 (장단점, 시간, 용량 정보 제공)
- ✅ DockerHub 이미지 제공 (20분 빌드 → 5분 다운로드)
- ✅ 완료 메시지 개선 (다음 할 일 안내)
- ✅ 초보자 친화적 문서

**이전 버전:** v1.1.0 - CLI 옵션 및 대화형 설정

---

## 📄 라이선스

MIT License

---

## 🙏 기여

Pull Request 환영합니다!

**피드백:**
- GitHub Issues: https://github.com/simryang/w55rp20-docker-build/issues

---

**개발:** WIZnet W55RP20 커뮤니티
**유지보수:** simryang
