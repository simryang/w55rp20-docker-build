# 세션 요약 (2026-01-16)

## 완료된 작업

### 1. 선택적 Docker 캐시 무효화 (REFRESH)
- 커밋: eb8051a
- 기능: apt/sdk/cmake/gcc/toolchain/all 선택적 refresh
- 구현: build.sh → REFRESH_*_BUST 변수 → w55build.sh → Docker ARG

### 2. heredoc 제거 (docker-build.sh 분리)
- 커밋: eb8051a
- 문제: 70줄 heredoc, shellcheck 불가, 디버깅 어려움
- 해결: 독립 스크립트로 분리, tmpfs 모니터링 개선

### 3. 로컬 설정 파일 (build.config)
- 커밋: f746218
- 기능: JOBS, TMPFS_SIZE 등 환경별 조정
- .gitignore 추가, git diff 깔끔

### 4. AUTO_BUILD_IMAGE=1 기본값
- 커밋: f746218, 461b282
- 변경: 0 → 1 (초보자 친화)
- build.sh와 w55build.sh 일관성 확보

### 5. REFRESH + AUTO_BUILD_IMAGE=0 Warning
- 커밋: f746218
- 모순 감지 → 명확한 안내 메시지

### 6. Git ownership 오류 수정 (1차)
- 커밋: ef45961
- 문제: Docker mount ownership 불일치
- 해결: entrypoint.sh에 git config --global --add safe.directory
- 한계: w55build.sh가 docker-build.sh 직접 호출 시 미적용

### 7. VERBOSE 모드 추가
- 커밋: 461b282
- 기능: VERBOSE=1 시 모든 변수/명령어 출력
- 디버깅 용이

### 8. AI 협업 문서화
- 커밋: 301a5c7
- claude/ 폴더 생성
- 5개 문서: README, DESIGN, VARIABLES, ISSUES, GPT_INSTRUCTIONS

### 9. SESSION_SUMMARY.md 추가
- 커밋: 7dd3e29
- 목적: Auto-compact 대비 컨텍스트 복구
- 전체 세션 이력, 기술 결정, 커밋 목록

### 10. README.md 작성
- 커밋: e3f59af
- 사용자 대상 종합 문서
- 빠른 시작, 기능 설명, 문제 해결, 성능 팁

### 11. Git ownership 완전 수정 (2차)
- 커밋: d4aa905
- 근본 원인 분석: w55build.sh → docker-build.sh 경로에서 safe.directory 미설정
- 해결:
  1. docker-build.sh: git safe.directory 설정 추가 (빌드 진입점)
  2. entrypoint.sh: UPDATE_REPO=0일 때 git fetch 건너뛰기
  3. w55build.sh: UPDATE_REPO 환경 변수 컨테이너 전달
- 결과: "dubious ownership" 오류 완전 해결, 빌드 검증 완료

## 핵심 설계 결정

### Option C: toolchain = cmake + gcc (별칭)
- 사용자 편의 + 세밀 제어 둘 다 지원
- `REFRESH="toolchain"` → cmake+gcc
- `REFRESH="cmake"` → cmake만 (가능)

### build.sh = 초보자용, w55build.sh = 고급용
- build.sh: 기본값 제공, "그냥 실행하면 됨"
- w55build.sh: 상세 제어, 모든 옵션 지정 가능

### 명시적 지정 존중 + Warning
- 강제 변경 ❌
- 모순 시 warning ✅
- 사용자 의도 우선

## 현재 상태

### 동작 확인
- ✅ Git ownership 완전 해결 (빌드 검증 완료)
- ✅ AUTO_BUILD_IMAGE 일관성
- ✅ VERBOSE 모드 동작
- ✅ UPDATE_REPO 환경 변수 전달
- ✅ 전체 빌드 프로세스 정상 동작
- ⏳ Docker 권한 (사용자 환경, sudo 필요)

### Git 커밋 이력
```
35abbe7 - Reorder USER_GUIDE.md: Docker first, build.sh second
486e725 - Add comprehensive user guide (USER_GUIDE.md)
13c7089 - Change OUT_DIR default to project-local directory
ad65175 - Update documentation with git ownership complete fix
d4aa905 - Fix Docker mount git ownership issue (완전 수정)
3e69bf5 - Update SESSION_SUMMARY.md with README.md completion
e3f59af - Add comprehensive README.md for user documentation
7dd3e29 - Add session summary for context recovery
301a5c7 - Add documentation for AI assistants
461b282 - Fix AUTO_BUILD_IMAGE default and add VERBOSE mode
ef45961 - Fix git ownership error in Docker container (1차 수정)
f746218 - Add local config support and improve AUTO_BUILD_IMAGE default
eb8051a - Add selective Docker cache refresh and refactor build scripts
```

## 완료된 작업 (계속)

### 12. OUT_DIR을 프로젝트 내부로 변경
- 커밋: 13c7089
- 변경: `$HOME/W55RP20-S2E-out` → `$PWD/out`
- 이유: 프로젝트 구조 일관성, 산출물 관리 용이
- .gitignore에 out/ 추가

### 13. 종합 사용 설명서 작성
- 커밋: 486e725
- USER_GUIDE.md (840줄) 추가
- 내용: Docker 직접 사용, build.sh 사용, 고급 사용법, 문제 해결, 스크립트 구조 부록

### 14. 문서 구조 재정리
- 커밋: 35abbe7
- USER_GUIDE.md 순서 변경
- 방법 1: Docker 직접 사용 (기본, 투명)
- 방법 2: build.sh 사용 (간편, 권장)
- 이유: 기본 원리를 먼저 보여주는 교육적 순서

## 진행 중인 논의

### 사용자 프로젝트 빌드 지원 및 멀티플랫폼 전략 (2026-01-16 15:40)
- 문서: claude/DESIGN_DISCUSSIONS.md
- 목표: 사용자가 수정한 소스를 빌드하는 명확한 워크플로우 제공
- 플랫폼:
  1. Linux: 프로젝트 경로 지정, 대화형 모드
  2. Mac: Linux와 동일한 경험
  3. Windows: VSCode/AI IDE 통합, Dev Container
- Phase 1: build.sh 개선 (위치 인자, .build-config, 대화형 모드)
- Phase 2: VSCode 템플릿, Windows 지원
- Phase 3: VSCode Extension, AI IDE 통합 (MCP)
- 상태: 설계 논의 완료, 구현 우선순위 결정 대기

## 다음 단계

### 즉시 구현 가능
1. build.sh 개선 (위치 인자, .build-config, 대화형 모드)
2. VSCode Dev Container 템플릿
3. USER_GUIDE.md에 사용자 프로젝트 빌드 섹션 추가

### 향후 고려사항
1. Docker 권한 이슈 (sudo 없이 실행)
2. 성능 측정 (빌드 시간, tmpfs 사용량)
3. CI/CD 통합
4. 다중 플랫폼 테스트 (라즈베리파이)

## 사용자 요구사항

- "그냥 실행하면 됨" (초보자)
- JOBS/TMPFS_SIZE 옵션 안 주고 싶음 → build.config
- 불특정 다수 공개 예정
- 향후 라즈베리파이 데비안 타겟 추가

## 중요한 파일

- README.md: 사용자 대상 종합 문서 (빠른 시작, 사용법, 문제 해결)
- build.sh: 초보자용 래퍼, 기본값 제공
- w55build.sh: 실제 빌드 로직
- docker-build.sh: 컨테이너 내부 빌드
- Dockerfile: 빌드 환경
- entrypoint.sh: 컨테이너 진입점 (git safe.directory 설정)
- build.config.example: 설정 예시
- claude/: AI 협업 문서 (README, DESIGN, VARIABLES, ISSUES, GPT_INSTRUCTIONS, SESSION_SUMMARY)

## 완료된 작업 (v1.1.0 - 2026-01-19)

### 15. v1.1.0 기능 구현 및 테스트
- 완료일: 2026-01-19
- 구현 내용:
  - ✅ CLI 옵션 파싱 (--project, --output, --clean, --debug, --jobs, --refresh 등)
  - ✅ .build-config 자동 저장/로드
  - ✅ Interactive mode (--setup) - 대화형 프로젝트 설정
  - ✅ Progress display - 빌드 전/후 상태 및 산출물 정보
  - ✅ 도움말 (--help, --version, --show-config)
- 테스트:
  - ✅ test-cli-options.sh (19 tests)
  - ✅ test-build-config.sh (10 tests)
  - ✅ test-interactive-mode.sh (16 tests)
  - ✅ test-progress-display.sh (15 tests)
  - ✅ test-integration.sh (14 tests)
  - **총 74개 테스트 모두 통과**
- Git 태그: v1.1.0

### 16. 문서 개선 (2026-01-20)
- README.md 업데이트:
  - 시간 추정 추가 (첫 실행: 20~25분, 이후: 2~3분)
  - FAQ 섹션 추가 (10개 질문)
  - v1.1.0 기능 설명
- build.sh 배포 방식 분석:
  - 3가지 옵션 비교 (현재/Docker Hub/문서만)
  - 8가지 사용 사례 평가
  - 결론: 현재 방식(Option 1) 유지 권장 (36/40점)

### 17. BEGINNER_GUIDE.md 추가 (2026-01-20)
- 완전 초보자 대상 위키 수준 가이드
- 내용:
  1. Docker 개념 설명 (비유와 그림)
  2. 사전 준비사항 (Docker 설치 가이드)
  3. 첫 빌드 단계별 가이드
  4. 무슨 일이 일어나는지 이해하기
  5. 자주 발생하는 문제와 해결법
  6. 내 프로젝트 빌드하기
  7. 고급 기능 사용하기
  8. 개념 정리
- 목적: "미쳐버린 도커 배포가 두렵지 않은" 문서
- README.md에 링크 추가 (문서 섹션 최상단)

### 18. ARCHITECTURE.md 추가 (2026-01-20)
- 내부 구조를 완전히 파고들고 싶은 개발자 대상 (1361줄, 37KB)
- 내용:
  1. 전체 아키텍처 (컴포넌트 다이어그램, 데이터 흐름)
  2. 실행 흐름 상세 분석 (build.sh → w55build.sh → docker)
  3. 스크립트 구조 (함수 목록, 변수 스코프)
  4. Docker 레이어 아키텍처 (Dockerfile 분석, 캐시 전략)
  5. 변수와 환경 전파 (우선순위, 전파 경로)
  6. 캐시 전략 (Docker Layer Cache, ccache, tmpfs)
  7. 에러 핸들링 (종류별 처리, Exit Code)
  8. 확장 및 커스터마이징 (새 옵션, REFRESH 타겟, 빌드 타입)
  9. 디버깅 가이드 (VERBOSE, 컨테이너 내부, 로그 분석)
  10. 기여 가이드 (코드 스타일, 테스트, 커밋 메시지)
- 목적: "웹검색 없이 자급자족" 수준의 내부 문서
- README.md 문서 섹션을 "사용자/개발자"로 분류

### 19. IMPLEMENTATION_LOG.md 추가 (2026-01-21)
- v1.1.0 개발 과정 상세 기록
- 내용:
  1. 초기 상태 확인 및 문제 파악
  2. 설계 고민 및 UX 개선
  3. v1.1.0 구현 (CLI 옵션, .build-config, Interactive mode, Progress display)
  4. 테스트 과정 (74개 테스트 모두 통과)
  5. 문서화 작업
  6. 배포 방식 분석
  7. 문서화 마스터 플랜
  8. 주요 의사결정 (toolchain 옵션, 역할 분리, OUT_DIR 위치 등)
  9. 발생한 문제와 해결 (Git ownership, Docker 권한)
  10. 성과 및 지표
  11. 교훈 (기술적, UX, 협업)
- 파일: claude/IMPLEMENTATION_LOG.md (1000+ 줄)

### 20. try.log 분석 및 정리 (2026-01-21)
- 54,981줄 (1.9MB) 로그 파일 분석
- 로그 특징:
  - 3번 반복되는 패턴 (세션 재시작)
  - 주요 내용: 빌드 시스템 개선, UX 설계, v1.1.0 구현, 문서화 마스터 플랜
  - 대부분 내용이 SESSION_SUMMARY.md와 DOCUMENTATION_MASTER_PLAN.md에 이미 반영됨
- 주제별 정리:
  - IMPLEMENTATION_LOG.md로 v1.1.0 구현 과정 상세 기록 생성
  - 기존 문서들과 중복되지 않는 내용 추출
  - 개발 과정의 타임라인 및 의사결정 과정 문서화

### 21. 문서 검증 시스템 개선 (2026-01-21)
- **bash → Python 전환** (docs-validation.sh → docs-validation.py)
  - 문제: bash 스크립트의 복잡한 문법 (`((PASSED_CHECKS++))`) 및 크로스 플랫폼 이슈
  - 해결: Python 3 기반으로 재작성
  - 장점:
    - 가독성 향상 (명확한 변수 증가: `passed_checks += 1`)
    - 크로스 플랫폼 호환성 (macOS/Linux 차이 해결)
    - 마크다운 링크 검증 강화 (정규식 처리 용이)
    - 에러 처리 개선 (try/except)
    - 유지보수성 향상
- **검증 항목** (8단계, 108개 검사):
  1. 필수 문서 존재 확인 (14개)
  2. claude 폴더 문서 확인 (11개)
  3. 마크다운 링크 검증 (25개)
  4. 문서 크기 확인 (14개)
  5. 코드 블록 검증 (14개)
  6. UTF-8 인코딩 확인 (14개)
  7. 필수 섹션 확인 (7개)
  8. 빌드 스크립트 확인 (9개)
- **결과**: 108/108 통과 (100%)

### 22. 문서 최종 완성 (2026-01-21)
- **README.md 개선**:
  - 목차 추가 (14개 섹션 앵커 링크)
  - 긴 문서 네비게이션 개선
- **실행 권한 수정**:
  - docker-build.sh 실행 권한 추가
  - entrypoint.sh 실행 권한 추가
- **CHANGELOG.md 업데이트**:
  - v1.2.0 개선 사항 반영
  - docs-validation.py 추가 기록
  - 최종 통계: 25개 문서, 13,059줄, 288KB
- **FINAL_SUMMARY.md 생성**:
  - 전체 프로젝트 완성 보고서
  - 문서 통계 및 구성
  - 주요 성과 (완전한 문서 시스템, 품질 보증, 사용성 개선)
  - 기술 세부사항 (검증 시스템, 검증 결과)
  - 목표 달성도 (10/10 100%)
  - 사용 시작 가이드 (초보자/경험자/개발자)
- **최종 통계**:
  - 총 25개 문서
  - 13,059줄
  - 288.2KB
  - 490개 코드 블록
  - 108개 검증 항목 100% 통과

### 23. 프로젝트 루트 정리 및 docs 폴더 구조화 (2026-01-21)
- **문서 정리**:
  - docs/ 폴더 생성
  - README.md 제외한 모든 .md 파일 (13개)을 docs/로 이동
  - 루트에는 README.md만 남겨 index 역할
- **링크 경로 수정**:
  - README.md: 모든 문서 링크를 docs/ 경로로 수정
  - docs/ 내 문서들: 상대 경로 조정
    - 같은 폴더 내 문서: 파일명만 (예: `QUICKREF.md`)
    - 루트 README.md: `../README.md`
    - claude 폴더: `../claude/`
  - GLOSSARY.md: README.md 링크 3개 수정
- **검증 스크립트 업데이트**:
  - docs-validation.py 경로 업데이트
  - validate_markdown_links() 함수 개선
    - 파일 디렉토리 기준 상대 경로 해석 추가
    - 깨진 링크 0개 달성
- **최종 구조**:
  ```
  루트 (깔끔!)
  ├── README.md (index)
  ├── docs/ (13개 문서)
  ├── claude/ (12개 문서)
  ├── *.sh (빌드 스크립트)
  ├── Dockerfile
  └── docs-validation.py
  ```
- **검증 결과**: 108/108 통과, 경고 0개

### 24. AI 스타일 이모지 제거 (2026-01-21)
- **목적**: 더 전문적인 문서 스타일
- **제거된 이모지**: ✨🎯⚙️📚🔧✅⭐🌟📖💬🐛📌📊🚀🎊🎉📋🆕
- **대상 파일**: README.md, docs/*.md (14개 파일)
- **결과**:
  - AI 냄새 제거
  - 전문적인 기술 문서 스타일
  - 검증 108/108 통과 유지

## 최근 Git 커밋 (v1.1.0+)
```
[HEAD] - Documentation v1.2.0 complete with Python validation system
[v1.1.0 tag] - Complete v1.1.0 implementation with all tests passing
```

## 현재 프로젝트 문서 현황 (v1.2.0)

### 사용자 문서 (14개)
```
├── README.md (554줄, 13.6KB)                 - 종합 가이드 (index 역할)
└── docs/                                     - 📚 모든 문서
    ├── BEGINNER_GUIDE.md (849줄, 18.3KB)     - 완전 초보자용
    ├── USER_GUIDE.md (867줄, 18.8KB)         - 상세 사용 설명서
    ├── ARCHITECTURE.md (1,361줄, 36.3KB)     - 내부 아키텍처
    ├── BUILD_LOGS.md (673줄, 15.7KB)         - 실제 빌드 로그
    ├── TROUBLESHOOTING.md (1,078줄, 21.3KB)  - 40+ 에러 해결
    ├── EXAMPLES.md (1,224줄, 22.3KB)         - 5가지 실전 예제
    ├── QUICKREF.md (202줄, 4.3KB)            - 1페이지 치트시트
    ├── GLOSSARY.md (494줄, 12.5KB)           - 100+ 용어 사전
    ├── CHANGELOG.md (228줄, 6.0KB)           - 변경 이력
    ├── INSTALL_LINUX.md (476줄, 7.2KB)       - Linux 설치
    ├── INSTALL_MAC.md (477줄, 6.9KB)         - macOS 설치
    ├── INSTALL_WINDOWS.md (507줄, 7.9KB)     - Windows/WSL2 설치
    └── INSTALL_RASPBERRY_PI.md (479줄, 7.7KB) - Raspberry Pi 설치
```

### 개발자 문서 (claude/ 폴더, 12개)
```
claude/
├── README.md                      - AI 협업 문서 메인 (3.4KB)
├── SESSION_SUMMARY.md             - 세션 요약 및 작업 이력 (이 파일)
├── IMPLEMENTATION_LOG.md          - v1.1.0 구현 상세 로그 (25KB)
├── DOCUMENTATION_MASTER_PLAN.md   - 문서화 마스터 플랜 (11KB)
├── FINAL_SUMMARY.md               - v1.2.0 프로젝트 완성 보고서 [NEW v1.2]
├── DESIGN.md                      - 초기 설계 (1.2KB)
├── DESIGN_DISCUSSIONS.md          - 설계 고민 기록 (6.1KB)
├── UX_DESIGN.md                   - UX 설계 (18KB)
├── ADVANCED_OPTIONS.md            - 고급 옵션 설명 (16KB)
├── VARIABLES.md                   - 변수 설명 (1.2KB)
├── ISSUES.md                      - 알려진 이슈 (1.4KB)
└── GPT_INSTRUCTIONS.md            - GPT용 지침 (1.3KB)
```

### 검증 스크립트
```
├── docs-validation.py             - Python 검증 스크립트 (108개 검사)
```

**전체 통계: 25개 문서, 13,059줄, 288.2KB, 검증 108/108 통과**

## 완료된 작업 (v1.2.1 - 2026-01-21)

### 25. AI 냄새 완전 제거 (2026-01-21)
- **목적**: 공개 문서의 AI 작성 흔적 제거
- **claude 폴더 정책**: AI 스타일 허용 (내부 문서), 공개 문서만 정리
- **제거 항목**:
  1. 이모지 전체 제거 (✨🎯⚙️📚 등)
  2. "~용" 표현 (예: "초보자용" → "입문자 가이드")
  3. "친화적" 표현 제거
  4. 메타 정보 노출 (예: "(832줄)" 제거)
  5. AI 특유 표현 ("완전히", "누구나", "쉽게", "빠르게")
  6. 기술 용어의 갑작스러운 사용 개선
  7. 저자 크레딧 제거 ("Claude", "AI Assistant")
- **AI_SMELL_GUIDE.md 생성**:
  - claude/AI_SMELL_GUIDE.md (460줄)
  - 12가지 AI 냄새 패턴
  - 감지 방법 및 검증 체크리스트
  - 전/후 비교 예시
- **최종 검증**: AI 냄새 측정 0

### 26. build.log 추가 (2026-01-21)
- **요청**: 빌드 로그 파일 생성
- **구현**:
  - build.sh: tee 명령으로 콘솔+파일 동시 출력
  - 파일: build.log
  - .gitignore에 build.log 추가
- **장점**: 빌드 실패 시 로그 분석 용이

### 27. 실제 빌드 테스트 및 디버깅 (2026-01-21)
- **빌드 시도**: 사용자 별도 디렉토리에서 빌드 (/home/sr/src/W55RP20-S2E)
- **에러 1: 서브모듈 미초기화**
  ```
  CMake Error: Directory '/work/src/libraries/FreeRTOS-Kernel' does not contain an RP2040 port
  ```
  - 원인: `git clone` 시 `--recurse-submodules` 누락
  - 해결: `git submodule update --init --recursive`
  - TROUBLESHOOTING.md에 B000 섹션 추가

- **에러 2: FTPClient 컴파일 오류**
  ```
  ftpc.c:579:30: error: implicit declaration of function 'ftp_getc'
  ```
  - 원인: `libraries/ioLibrary_Driver/Internet/FTPClient/ftpc.h` line 28 주석 처리
    ```c
    //#define ftp_getc()	Board_UARTGetCharBlocking()
    ```
  - 디버깅 과정:
    1. 공식 WIZnet 저장소와 비교 → 동일한 문제 확인
    2. W55RP20 프로젝트에서 `platform_uart_getc()` 함수 발견
    3. uartHandler.h에 함수 정의 확인
  - 해결 방법: line 28 주석 해제 후 수정
    ```c
    #define ftp_getc()	platform_uart_getc()
    ```
  - /tmp/fix-ftpc.sh 스크립트 생성
  - TROUBLESHOOTING.md에 B001-1 섹션 추가

### 28. Docker 권한 문제 해결 (2026-01-21)
- **문제**: Background task에서 Docker 데몬 접근 실패
- **원인**: sudo 타임스탬프 만료 (비대화형 세션에서 암호 입력 불가)
- **해결**:
  1. w55build.sh에서 `docker` → `sudo docker` 복구 (6곳)
  2. sudo 타임스탬프 갱신 필요
- **다음 단계**:
  ```bash
  # 1. Claude Code 종료
  # 2. sudo docker info 실행 (타임스탬프 갱신)
  # 3. Claude Code 재시작
  # 4. 빌드 실행
  ```

## 현재 상태 및 다음 단계

### 준비 완료
- ✅ w55build.sh sudo 권한 복구
- ✅ ftpc.h 수정 스크립트 생성 (/tmp/fix-ftpc.sh)
- ✅ 에러 해결 방법 문서화 (TROUBLESHOOTING.md)
- ✅ AI 냄새 완전 제거
- ✅ build.log 시스템 추가

### 다음 실행 명령
```bash
# 1. sudo 타임스탬프 갱신
sudo docker info

# 2. 소스 디렉토리 정리 (root 권한 필요)
sudo rm -rf /home/sr/W55RP20-S2E

# 3. 자동 빌드 (소스 클론 포함)
./build.sh

# 4. ftpc.h 수정
/tmp/fix-ftpc.sh

# 5. 재빌드
./build.sh
```

### 예상되는 결과
- W55RP20-S2E 소스 자동 클론 (--recurse-submodules 포함)
- Docker 이미지 자동 빌드 (첫 실행 시)
- ftpc.h 수정 후 컴파일 성공
- 산출물: out/*.uf2, out/*.elf, out/*.bin

### 미해결 이슈
- ftpc.h 주석 문제는 공식 WIZnet 저장소의 문제
- 임시 해결: /tmp/fix-ftpc.sh로 수동 수정
- 장기 해결: WIZnet에 PR 제출 고려

### 29. --project 옵션 테스트 및 Docker 권한 자동 해결 (2026-01-27)
- **테스트**: 별도 폴더에 W55RP20-S2E 클론 후 `--project` 옵션 테스트
  ```bash
  git clone --recurse-submodules https://github.com/WIZnet-ioNIC/W55RP20-S2E.git W55RP20-S2E-test
  ./build.sh --project /home/sr/src/W55RP20-S2E-test --no-confirm
  ```

- **발견한 문제들**:
  1. **확인 프롬프트 블록** (build.sh:614)
     - 문제: 비대화형 환경에서 `read -r -p` 블록
     - 해결: `--no-confirm` 옵션 사용

  2. **Docker 권한 문제의 근본 원인**
     - `docker` → docker 그룹 없으면 실패
     - `sudo docker` → 비대화형 환경에서 비밀번호 요구
     - **일반 사용자는 usermod 권한이 없음!**
     - "모든 유저가 usermod를 시전할 것 같어?"

  3. **올바른 해결: 자동 Docker 명령 선택** (w55build.sh:59-103)
     - 구현: DOCKER_CMD 변수로 자동 선택
       ```bash
       # 1단계: docker 시도
       if docker info → DOCKER_CMD="docker"

       # 2단계: sudo docker 시도 (비밀번호 없이)
       elif sudo -n docker info → DOCKER_CMD="sudo docker"
         + 경고: "docker 그룹 미설정. sudo 사용 중"

       # 3단계: 모두 실패 → 상세 진단
       else
         - Docker 데몬 상태 확인
         - docker 그룹 확인
         - 해결 방법 안내 (usermod / newgrp / systemctl)
       ```
     - 적용: 모든 docker 명령을 `$DOCKER_CMD`로 변경
       - 110줄: $DOCKER_CMD image inspect
       - 134줄: BUILD_CMD=($DOCKER_CMD buildx build...)
       - 231줄: $DOCKER_CMD run
       - 218줄: 로그 메시지도 동적 표시

- **빌드 테스트 결과**:
  - ✅ Exit status: 0 (성공)
  - ✅ 빌드 시간: 6.86초 (ccache warm)
  - ✅ 산출물: App.uf2 (628K), Boot.uf2 (120K), App_linker.uf2 (628K), SPI_Mode_Master.uf2 (44K)
  - ✅ 서브모듈: `--recurse-submodules`로 자동 초기화
  - ✅ --project 옵션 정상 동작
  - ✅ docker 그룹 환경에서 sudo 없이 동작 확인

- **사용자 경험 개선**:
  - docker 그룹 있음 → 바로 동작
  - sudo 가능 → 자동 sudo 사용 (경고 표시)
  - 모두 안됨 → 정확한 진단 및 해결법 제시
  - **"만든 놈 멍청이 아냐?" → "오, 알아서 되네!"**

## 새 세션 시작 시

1. `claude/SESSION_SUMMARY.md` 읽기 (이 파일)
2. `claude/README.md` 읽기
3. `git log --oneline -10` 확인
4. 필요시 `claude/IMPLEMENTATION_LOG.md` 읽기 (v1.1.0 상세 과정)
5. 작업 시작
