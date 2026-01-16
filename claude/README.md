# W55RP20-S2E Docker Build System

## 빠른 컨텍스트

### 프로젝트 구조
```
.
├── README.md          # 사용자 대상 문서 (빠른 시작)
├── USER_GUIDE.md      # 상세 사용 설명서 (840줄)
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

### 진행 중인 논의

- **사용자 프로젝트 빌드 지원** (2026-01-16)
  - 문서: `claude/DESIGN_DISCUSSIONS.md`
  - 목표: 멀티플랫폼 개발 워크플로우 (Linux/Mac/Windows)
  - 상태: 설계 완료, 구현 우선순위 결정 대기

### 다음 작업

- build.sh 개선 (위치 인자, 대화형 모드, .build-config)
- VSCode Dev Container 템플릿
- 이슈 확인: `claude/ISSUES.md`
