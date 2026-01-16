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

## 새 세션 시작 시

1. `claude/SESSION_SUMMARY.md` 읽기 (이 파일)
2. `claude/README.md` 읽기
3. `git log --oneline -10` 확인
4. 작업 시작
