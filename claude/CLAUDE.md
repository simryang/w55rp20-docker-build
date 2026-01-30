# W55RP20 Docker Build System

> **프로젝트 메모리**: 이 파일은 Claude Code가 프로젝트를 이해하고 작업 컨텍스트를 유지하기 위한 파일입니다.

## 프로젝트 개요

**목적:** WIZnet W55RP20 마이크로컨트롤러를 위한 Docker 기반 크로스컴파일 빌드 시스템

**핵심 가치:**
- 초보자도 쉽게 사용 (3단계 빠른 시작)
- Windows/Linux/macOS 모두 지원
- Docker로 환경 통일 (의존성 문제 해결)
- 빠른 빌드 (ccache 캐싱: 첫 실행 20분 → 이후 12초)

**버전:** v1.2.0-unified (2026-01-29 기준)

---

## 기술 스택

| 구성 요소 | 버전/기술 |
|---------|----------|
| **컨테이너** | Docker (Ubuntu 22.04 / Windows Nano Server) |
| **빌드 시스템** | CMake 3.28 + Ninja |
| **컴파일러** | ARM GNU Toolchain 14.2 |
| **SDK** | Raspberry Pi Pico SDK 2.2.0 |
| **캐싱** | ccache (tmpfs 기반) |
| **언어** | Bash, PowerShell, Python |
| **CI/CD** | GitHub Actions |

---

## 디렉토리 구조

```
w55rp20/
├── build.sh                    # Bash 빌드 스크립트 (v1.1.0, 727줄)
├── build.ps1                   # PowerShell 빌드 스크립트 (v1.2.0, 483줄)
├── build-unified.sh            # 통합 빌드 (Linux+Windows)
├── w55build.sh                 # 간편 래퍼
├── Dockerfile                  # Linux 컨테이너 (115줄)
├── Dockerfile.windows          # Windows 컨테이너
├── entrypoint.sh               # Docker 진입점
├── docker-build.sh             # 컨테이너 내부 빌드 로직
├── build.config.example        # 설정 예제
├── docs/                       # 사용자 문서 (18개)
├── claude/                     # 개발자/AI 문서 (9개)
├── tests/                      # 테스트 스크립트 (5개)
└── .claude/                    # Claude Code 설정
    ├── hooks/                  # 자동화 Hook
    ├── session-history/        # 세션 히스토리
    └── settings.local.json     # 프로젝트 설정
```

---

## 주요 명령어

### 빌드 (Bash - Linux/macOS)

```bash
# 기본 빌드 (W55RP20-S2E 공식 예제)
./build.sh

# 사용자 프로젝트 빌드
./build.sh --project ~/my-w55rp20-project

# 디버그 빌드
./build.sh --debug

# 빌드 정리
./build.sh --clean

# SDK 캐시 갱신
REFRESH="sdk" ./build.sh

# 전체 재설치
REFRESH="all" ./build.sh

# 상세 로그
VERBOSE=1 ./build.sh
```

### 빌드 (PowerShell - Windows)

```powershell
# 기본 빌드
.\build.ps1

# 대화형 모드 (초보자용)
.\build.ps1 -Interactive

# 사용자 프로젝트
.\build.ps1 -Project "C:\path\to\project"

# 디버그 빌드
.\build.ps1 -BuildType Debug

# 도움말
.\build.ps1 -Help
```

### 테스트

```bash
# 전체 테스트 실행
for test in tests/test-*.sh; do $test; done

# 개별 테스트
./tests/test-cli-options.sh         # CLI 옵션 테스트
./tests/test-integration.sh         # 통합 테스트
```

### Docker 직접 사용

```bash
# DockerHub 이미지 사용 (빠름: 5분)
docker pull simryang/w55rp20:latest

# 로컬 빌드 (느림: 20분)
docker build -f Dockerfile -t w55rp20:latest .

# 수동 빌드 실행
docker run --rm -v $(pwd):/workspace w55rp20:latest
```

---

## 개발 워크플로우

### 1. 코드 작성/수정

- 스크립트 수정 시 **shellcheck** 검사
- PowerShell 수정 시 **PSScriptAnalyzer** 검사
- 문서 수정 시 **docs-validation.py** 검사

### 2. 테스트

```bash
# 전체 테스트 (필수)
for test in tests/test-*.sh; do echo "Running: $test"; $test; done

# 빌드 테스트
./build.sh --project examples/test-project
```

### 3. Git 커밋

```bash
git add <files>
git commit -m "feat: Add feature description"
# 또는
git commit -m "fix: Fix bug description"
# 또는
git commit -m "docs: Update documentation"
```

**주의:**
- ❌ Co-Authored-By 추가 금지 (AI 기여자 정보 제외)
- ✅ 간결하고 명확한 커밋 메시지

### 4. 배포 (태그)

```bash
git tag -a v1.x.x -m "Release v1.x.x"
git push origin v1.x.x
```

---

## 코딩 규칙

### Bash 스크립트

- **들여쓰기:** 4칸 스페이스
- **함수:** `function_name() { ... }` 형식
- **변수:** `UPPER_CASE` (전역), `lower_case` (지역)
- **따옴표:** 변수 확장 시 항상 `"$var"` 사용
- **에러 처리:** `set -e` 사용, 필요시 `|| true`

### PowerShell

- **들여쓰기:** 4칸 스페이스
- **함수:** `PascalCase`
- **변수:** `$PascalCase`
- **파라미터:** `Param()` 블록 사용
- **에러 처리:** `-ErrorAction Stop`

### 문서

- **형식:** GitHub Flavored Markdown
- **줄 길이:** 최대 120자
- **섹션:** `##` 레벨부터 시작
- **코드 블록:** 언어 지정 필수

---

## 중요 파일

### 빌드 시스템

- `build.sh` - Bash 빌드 스크립트 (메인)
- `build.ps1` - PowerShell 빌드 스크립트 (Windows)
- `Dockerfile` - Linux 컨테이너 정의
- `entrypoint.sh` - Docker 진입점

### 문서

- `README.md` - 빠른 시작 가이드 (Windows 중심)
- `docs/USER_GUIDE.md` - 종합 사용자 매뉴얼 (840줄)
- `docs/ARCHITECTURE.md` - 시스템 아키텍처
- `claude/DESIGN.md` - 설계 결정사항
- `DEPLOYMENT_GUIDE.md` - 배포 가이드

### 설정

- `build.config.example` - 로컬 설정 예제
- `.claude/settings.local.json` - Claude Code 설정
- `.claude/preferences` - AI 기여 정책

---

## 알려진 이슈 및 해결 방법

### 1. Git 소유권 오류

**증상:** `fatal: detected dubious ownership`

**해결:**
```bash
git config --global --add safe.directory /workspace
```

빌드 스크립트가 자동으로 처리합니다.

### 2. Docker 권한 오류

**증상:** `permission denied while trying to connect to Docker`

**해결:**
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### 3. 빌드 속도 느림

**해결:** DockerHub 이미지 사용
```bash
docker pull simryang/w55rp20:latest
```

---

## 팀 협업

### 기여 방법

1. Issue 생성 또는 할당받기
2. Feature 브랜치 생성: `git checkout -b feature/my-feature`
3. 작업 수행 및 테스트
4. Pull Request 생성
5. 코드 리뷰 후 병합

### PR 체크리스트

- [ ] 테스트 통과 (`tests/` 전체 실행)
- [ ] 문서 업데이트 (필요시)
- [ ] shellcheck 통과 (Bash 스크립트)
- [ ] 커밋 메시지 규칙 준수
- [ ] AI 기여자 정보 제거 확인

---

## 유용한 정보

### 빌드 시간

- **첫 Docker 이미지 빌드:** ~20분
- **DockerHub 이미지 다운로드:** ~5분
- **첫 프로젝트 빌드:** ~3분
- **ccache 활성화 후:** ~12초 ⚡

### 용량

- Docker 이미지: ~2.5GB
- 빌드 산출물: ~50MB (.uf2 파일)
- ccache 캐시: ~500MB

### 지원 플랫폼

- ✅ Linux (x86_64, ARM64)
- ✅ macOS (Intel, Apple Silicon)
- ✅ Windows 11 (WSL2 또는 네이티브 컨테이너)

---

## 배포 상태

### DockerHub

- **이미지:** `simryang/w55rp20:latest` (Linux)
- **이미지:** `simryang/w55rp20:windows` (Windows, 보류)

### GitHub

- **저장소:** `github.com:simryang/w55rp20-docker-build.git`
- **릴리스:** v1.0.0, v1.1.0
- **Actions:** Windows 컨테이너 자동 빌드 (설정됨)

---

## 다음 단계 (로드맵)

### v1.3.0 (계획)
- [ ] Windows 네이티브 컨테이너 DockerHub 배포
- [ ] VSCode Dev Container 템플릿
- [ ] 멀티 프로젝트 빌드 지원

### v2.0.0 (미래)
- [ ] GUI 빌드 도구
- [ ] 원격 빌드 지원
- [ ] 빌드 캐시 클라우드 공유

---

## 긴급 연락처

- **프로젝트 관리자:** simryang
- **이슈 트래커:** GitHub Issues
- **문서 버그:** docs/README.md 참고

---

**최종 업데이트:** 2026-01-29
**작성자:** simryang with Claude Code assistance
