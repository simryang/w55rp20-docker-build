# W55RP20-S2E Docker Build System

## 빠른 컨텍스트

### 프로젝트 구조
```
.
├── README.md          # 사용자 대상 문서 (빠른 시작)
├── BEGINNER_GUIDE.md  # 완전 초보자 가이드 (832줄, Docker 개념부터)
├── USER_GUIDE.md      # 상세 사용 설명서 (840줄)
├── ARCHITECTURE.md    # 내부 아키텍처 문서 (1361줄, 개발자용)
├── build.sh           # 초보자용 래퍼 (기본값 제공)
├── w55build.sh        # 실제 빌드 로직 (상세 제어)
├── docker-build.sh    # 컨테이너 내부 빌드 스크립트
├── Dockerfile         # 빌드 환경 정의
├── entrypoint.sh      # 컨테이너 진입점
├── build.config       # 로컬 설정 (gitignore)
├── out/               # 빌드 산출물 (gitignore)
└── claude/            # AI 협업 문서
    ├── README.md
    ├── DESIGN.md
    ├── DESIGN_DISCUSSIONS.md  # 설계 논의 이력
    ├── VARIABLES.md
    ├── ISSUES.md
    ├── SESSION_SUMMARY.md
    └── GPT_INSTRUCTIONS.md
```

### 핵심 개념

**철학:**
- build.sh = "그냥 실행하면 됨" (초보자용)
- w55build.sh = "정밀 제어" (고급 사용자용)

**데이터 흐름:**
```
사용자 → build.sh → w55build.sh → Docker
         (기본값)  (변수 전달)    (실행)
```

### 주요 기능

1. **선택적 캐시 무효화 (REFRESH)**
   - `REFRESH="apt"` → apt 패키지만 재설치
   - `REFRESH="sdk"` → pico-sdk만 재클론
   - `REFRESH="cmake"` → CMake만
   - `REFRESH="gcc"` → ARM GCC만
   - `REFRESH="toolchain"` → cmake+gcc (별칭)

2. **로컬 설정 (build.config)**
   - JOBS, TMPFS_SIZE 등 환경별 조정
   - gitignore되어 git diff 깔끔

3. **VERBOSE 모드**
   - `VERBOSE=1` → 모든 변수/명령어 출력

### 최근 해결한 이슈

- Git ownership 오류 (Docker mount) → safe.directory 완전 수정 (빌드 검증 완료)
- AUTO_BUILD_IMAGE 기본값 불일치 → 1로 통일
- heredoc 지옥 → docker-build.sh 분리
- UPDATE_REPO 환경 변수 전달 → 불필요한 git fetch 방지

### v1.1.0 완료 (2026-01-19)

**구현 완료:**
- ✅ CLI 옵션 파싱 (--project, --output, --clean, --debug 등)
- ✅ .build-config 자동 저장/로드
- ✅ Interactive mode (--setup)
- ✅ Progress display (빌드 전/후 상태 표시)
- ✅ 도움말 (--help, --version, --show-config)

**테스트 완료:**
- ✅ test-cli-options.sh (19 tests)
- ✅ test-build-config.sh (10 tests)
- ✅ test-interactive-mode.sh (16 tests)
- ✅ test-progress-display.sh (15 tests)
- ✅ test-integration.sh (14 tests)
- **총 74개 테스트 모두 통과**

**문서 업데이트:**
- ✅ README.md - v1.1.0 기능 추가, 시간 추정, FAQ
- ✅ BEGINNER_GUIDE.md - 완전 초보자용 위키 수준 가이드 (NEW!)
- ✅ UX_DESIGN.md - 3가지 페르소나 플로우
- ✅ ADVANCED_OPTIONS.md - 전체 옵션 상세 설명

### 진행 중인 논의

- **사용자 프로젝트 빌드 지원** (2026-01-16)
  - 문서: `claude/DESIGN_DISCUSSIONS.md`
  - 목표: 멀티플랫폼 개발 워크플로우 (Linux/Mac/Windows)
  - 상태: v1.1.0에서 CLI 옵션으로 기본 지원 완료
  - 다음: VSCode Dev Container 템플릿

### 다음 작업

- VSCode Dev Container 템플릿 작성
- Windows PowerShell 래퍼 (build.ps1)
- 실제 사용자 피드백 수집
- 이슈 확인: `claude/ISSUES.md`
