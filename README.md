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
.\build.ps1 -Interactive
```

**화면에 메뉴 나오면 `1` 입력 후 Enter**

---

### 3️⃣ 완료!

**산출물 위치:** `.\out\*.uf2`

**소요 시간:**
- 최초 실행: 약 6분 (이미지 다운로드 5분 + 빌드 50초)
- 이후 실행: 약 12초 (캐시 사용)

---

## 💡 다음 빌드부터는

**같은 프로젝트 재빌드:**
```powershell
.\build.ps1
```

**사용자 프로젝트 빌드:**
```powershell
.\build.ps1 -Project "C:\your\project\path"
```

**디버그 빌드:**
```powershell
.\build.ps1 -BuildType Debug
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

### Q: Docker Desktop 설치 중 "WSL 2 installation is incomplete" 에러
**A:** 정상입니다. Docker Desktop이 자동으로 WSL2를 설치합니다.
- 안내에 따라 재부팅
- Docker Desktop 다시 실행
- 문제 지속 시: [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) 참고

### Q: 첫 실행이 느린데 정상인가요?
**A:** 네! 최초 1회는 Docker 이미지를 다운로드합니다 (약 5분).
- 2.44GB 이미지 다운로드
- 이후 실행은 12초로 빠릅니다

### Q: 빌드된 파일은 어떻게 W55RP20에 올리나요?
**A:**
1. W55RP20 보드의 BOOTSEL 버튼을 누른 채로 USB 연결
2. Windows가 'RPI-RP2' 드라이브로 인식
3. `.\out\*.uf2` 파일을 드라이브에 복사
4. 자동으로 재부팅 및 펌웨어 업로드 완료!

### Q: Git Bash vs PowerShell?
**A:** 둘 다 가능합니다.
- **PowerShell** (권장): Windows 기본 제공
- **Git Bash**: Git for Windows 설치 시 포함

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
