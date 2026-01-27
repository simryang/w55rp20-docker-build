# W55RP20-S2E Docker Build System

## 빠른 컨텍스트

### 프로젝트 구조 (v1.2.0)
```
.
├── README.md               # 사용자 대상 종합 문서 (index 역할)
├── docs/                   # 📚 모든 문서 (13개)
│   ├── BEGINNER_GUIDE.md       # 완전 초보자 가이드 (849줄)
│   ├── USER_GUIDE.md           # 상세 사용 설명서 (867줄)
│   ├── ARCHITECTURE.md         # 내부 아키텍처 (1,361줄)
│   ├── BUILD_LOGS.md           # 실제 빌드 로그 예제 (673줄)
│   ├── TROUBLESHOOTING.md      # 40+ 에러 해결 가이드 (1,078줄)
│   ├── EXAMPLES.md             # 5가지 실전 예제 (1,224줄)
│   ├── QUICKREF.md             # 1페이지 치트시트 (202줄)
│   ├── GLOSSARY.md             # 100+ 용어 사전 (494줄)
│   ├── CHANGELOG.md            # 변경 이력 (228줄)
│   ├── INSTALL_LINUX.md        # Linux 설치 가이드 (476줄)
│   ├── INSTALL_MAC.md          # macOS 설치 가이드 (477줄)
│   ├── INSTALL_WINDOWS.md      # Windows/WSL2 설치 가이드 (507줄)
│   └── INSTALL_RASPBERRY_PI.md # Raspberry Pi 설치 가이드 (479줄)
├── docs-validation.py      # Python 문서 검증 (108개 검사)
├── build.sh                # 초보자용 래퍼 (기본값 제공)
├── w55build.sh             # 실제 빌드 로직 (상세 제어)
├── docker-build.sh         # 컨테이너 내부 빌드 스크립트
├── Dockerfile              # 빌드 환경 정의
├── entrypoint.sh           # 컨테이너 진입점
├── build.config            # 로컬 설정 (gitignore)
├── out/                    # 빌드 산출물 (gitignore)
└── claude/                 # AI 협업 문서
    ├── README.md                    # 이 파일 (빠른 컨텍스트)
    ├── SESSION_SUMMARY.md           # 세션별 작업 요약 (작업 #25까지)
    ├── IMPLEMENTATION_LOG.md        # v1.1.0 구현 상세 로그
    ├── DOCUMENTATION_MASTER_PLAN.md # 문서화 마스터 플랜
    ├── FINAL_SUMMARY.md             # v1.2.0 프로젝트 완성 보고서
    ├── AI_SMELL_GUIDE.md            # AI 냄새 제거 가이드 [NEW]
    ├── DESIGN.md                    # 초기 설계
    ├── DESIGN_DISCUSSIONS.md        # 설계 논의 이력
    ├── UX_DESIGN.md                 # UX 설계 (3 페르소나)
    ├── ADVANCED_OPTIONS.md          # 고급 옵션 설명
    ├── VARIABLES.md                 # 변수 설명
    ├── ISSUES.md                    # 알려진 이슈
    └── GPT_INSTRUCTIONS.md          # GPT용 지침

총 25개 문서, 13,059줄, 288.2KB, 검증 108/108 통과
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

### v1.2.0 완료 (2026-01-21)

**문서 시스템 대폭 강화:**
- ✅ 9개 새 문서 추가
  - BUILD_LOGS.md - 실제 빌드 로그 예제
  - TROUBLESHOOTING.md - 40+ 에러 해결 가이드
  - EXAMPLES.md - 5가지 실전 예제
  - INSTALL_*.md (4개) - 플랫폼별 설치 가이드
  - GLOSSARY.md - 100+ 용어 사전
  - QUICKREF.md - 1페이지 치트시트
  - CHANGELOG.md - 변경 이력
- ✅ Python 문서 검증 시스템
  - docs-validation.py (bash → Python 전환)
  - 108개 검사 항목 (100% 통과)
  - 마크다운 링크 검증 강화
- ✅ 문서 통합 및 개선
  - README.md 목차 추가
  - 모든 문서 간 크로스 레퍼런스
  - 실행 권한 수정 (docker-build.sh, entrypoint.sh)
- ✅ 프로젝트 완성 보고서 (FINAL_SUMMARY.md)

**최종 통계:**
- 25개 문서, 13,059줄, 288.2KB
- 490개 코드 블록
- 검증 108/108 통과 (100%)
- "웹 검색 없이 자급자족" 수준 달성

### 완료된 주요 마일스톤

1. **v0.9.0** - Docker 기반 빌드 시스템 기본 구현
2. **v1.0.0** - 캐시 무효화, 로컬 설정, Git ownership 수정
3. **v1.1.0** - CLI 옵션, Interactive mode, 74개 테스트 통과
4. **v1.2.0** - 완전한 문서 시스템 (25개 문서, 108개 검증 통과)

### 다음 작업 (v1.3.0+)

- VSCode Dev Container 템플릿 작성
- Windows PowerShell 래퍼 (build.ps1)
- 멀티 플랫폼 자동 테스트
- 실제 사용자 피드백 수집
- 이슈 확인: `claude/ISSUES.md`

### 프로젝트 현황 (2026-01-21)

**상태**: ✅ v1.2.0 완성
- 완전한 문서 시스템 구축 완료
- "웹 검색 없이 자급자족" 수준 달성
- 모든 검증 통과 (108/108)
- 프로덕션 준비 완료
