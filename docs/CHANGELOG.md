# 변경 이력

> W55RP20-S2E 빌드 시스템 변경 사항

모든 주목할 만한 변경 사항이 이 파일에 기록됩니다.

형식: [Keep a Changelog](https://keepachangelog.com/ko/1.0.0/)
버전 관리: [Semantic Versioning](https://semver.org/lang/ko/)

---

## [Unreleased]

### 추가 예정
- VSCode Dev Container 템플릿
- Windows PowerShell 래퍼 (build.ps1)
- 멀티 플랫폼 자동 테스트

---

## [1.2.0] - 2026-01-21

### 추가
- **문서 시스템 대폭 강화** (Phase 1-4 완료)
  - BUILD_LOGS.md - 실제 빌드 로그 예제
  - TROUBLESHOOTING.md - 40+ 에러 해결 가이드
  - EXAMPLES.md - 5가지 실전 예제
  - INSTALL_LINUX.md - Linux 전용 설치 가이드
  - INSTALL_MAC.md - macOS 전용 설치 가이드
  - INSTALL_WINDOWS.md - Windows/WSL2 전용 설치 가이드
  - INSTALL_RASPBERRY_PI.md - Raspberry Pi 전용 설치 가이드
  - GLOSSARY.md - 100+ 용어 사전
  - QUICKREF.md - 1페이지 빠른 참조
  - CHANGELOG.md - 이 파일
- **문서 통합 및 크로스 레퍼런스**
  - 모든 문서 간 상호 링크 추가
  - docs-validation.py - Python 기반 문서 검증 스크립트 (108개 검사 항목)
- **claude 폴더 문서 추가**
  - IMPLEMENTATION_LOG.md - v1.1.0 구현 상세 로그

### 개선
- BEGINNER_GUIDE.md - 새 문서 링크 추가
- USER_GUIDE.md - 관련 문서 섹션 추가
- README.md - 문서 네비게이션 및 목차 추가
- docker-build.sh, entrypoint.sh - 실행 권한 추가

### 수정
- docs-validation.sh → docs-validation.py (bash → Python)
  - 더 나은 가독성과 유지보수성
  - 크로스 플랫폼 호환성 향상
  - 마크다운 링크 검증 강화

### 문서
- 총 25개 문서, 13,059줄, 288KB
- "웹 검색 없이 자급자족" 수준 달성
- 108개 검사 항목 모두 통과

---

## [1.1.0] - 2026-01-19

### 추가
- **CLI 옵션 파싱** (build.sh)
  - `--project PATH` - 빌드할 프로젝트 경로
  - `--output PATH` - 출력 디렉토리
  - `--clean` - 빌드 전 클린
  - `--debug` - 디버그 빌드
  - `--jobs N` - 병렬 작업 수
  - `--refresh TARGET` - 캐시 무효화 타겟
  - `--tmpfs SIZE` - tmpfs 크기
  - `--setup` - 대화형 설정
  - `--help` - 도움말
  - `--version` - 버전 정보
  - `--show-config` - 현재 설정 표시

- **.build-config 자동 저장/로드**
  - 첫 실행 시 옵션 자동 저장
  - 다음 실행 시 자동 로드
  - 명령줄 옵션으로 덮어쓰기 가능

- **Interactive Mode (--setup)**
  - 대화형 프로젝트 설정
  - 대화형 질문/응답 방식
  - 설정 자동 저장

- **Progress Display**
  - 빌드 전 설정 정보 표시
  - 빌드 후 산출물 목록 및 크기
  - 다음 단계 안내

### 테스트
- **74개 자동 테스트 추가**
  - test-cli-options.sh (19 tests)
  - test-build-config.sh (10 tests)
  - test-interactive-mode.sh (16 tests)
  - test-progress-display.sh (15 tests)
  - test-integration.sh (14 tests)
  - 모든 테스트 통과 확인

### 문서
- BEGINNER_GUIDE.md - 입문자 가이드
- ARCHITECTURE.md - 내부 아키텍처 문서
- UX_DESIGN.md - UX 설계 문서
- ADVANCED_OPTIONS.md - 고급 옵션 설명
- README.md 업데이트 (시간 추정, FAQ 추가)

### 개선
- build.sh 사용자 경험 대폭 개선
- 에러 메시지 명확화
- 진행 상황 실시간 표시

---

## [1.0.0] - 2026-01-16

### 추가
- **선택적 Docker 캐시 무효화 (REFRESH)**
  - apt, sdk, cmake, gcc, toolchain, all 옵션
  - 빌드 시간 최적화
  - 선택적 재빌드 가능

- **로컬 설정 파일 (build.config)**
  - JOBS, TMPFS_SIZE 등 환경별 조정
  - .gitignore 추가
  - git diff 깔끔하게 유지

- **VERBOSE 모드**
  - VERBOSE=1 시 모든 변수/명령어 출력
  - 디버깅 가능

- **개발자 문서화**
  - claude/ 폴더 생성
  - README.md, DESIGN.md, VARIABLES.md, ISSUES.md, GPT_INSTRUCTIONS.md
  - SESSION_SUMMARY.md - 세션별 작업 요약
  - DESIGN_DISCUSSIONS.md - 설계 논의 이력

- **사용자 문서**
  - README.md - 종합 문서
  - USER_GUIDE.md - 상세 사용 설명서 
### 수정
- **Git ownership 오류 완전 해결**
  - docker-build.sh에 git safe.directory 설정
  - entrypoint.sh UPDATE_REPO=0 처리
  - w55build.sh 환경 변수 전달
  - "dubious ownership" 오류 제거

- **AUTO_BUILD_IMAGE 기본값 변경**
  - 0 → 1 (입문자용)
  - build.sh와 w55build.sh 일관성 확보

- **OUT_DIR 기본값 변경**
  - `$HOME/W55RP20-S2E-out` → `$PWD/out`
  - 프로젝트 구조 일관성
  - .gitignore에 out/ 추가

### 개선
- **heredoc 제거**
  - 70줄 heredoc을 docker-build.sh로 분리
  - shellcheck 가능
  - 디버깅 가능
  - tmpfs 모니터링 개선

- **REFRESH + AUTO_BUILD_IMAGE=0 Warning**
  - 모순 감지 및 명확한 안내
  - 사용자 의도 존중

### 문서
- 전체 문서 구조화
- 사용자/개발자 문서 분리
- 크로스 레퍼런스 추가

---

## [0.9.0] - 2026-01-15

### 추가
- **Docker 기반 빌드 시스템**
  - Dockerfile - Ubuntu 22.04 + ARM GCC 14.2.1 + Pico SDK
  - w55build.sh - Docker 관리 및 빌드 스크립트
  - build.sh - 사용자용 래퍼 스크립트
  - docker-build.sh - 컨테이너 내부 빌드 스크립트
  - entrypoint.sh - 컨테이너 진입점

- **기본 기능**
  - 자동 소스 클론
  - ccache 지원
  - tmpfs 빌드 (성능 향상)
  - 멀티코어 병렬 빌드

### 초기 구현
- W55RP20-S2E 프로젝트 빌드 지원
- uf2 펌웨어 생성
- 기본 문서

---

## 버전 체계

### Major (X.0.0)
- 호환성을 깨는 변경
- 빌드 시스템 전면 개편

### Minor (x.X.0)
- 새 기능 추가 (하위 호환)
- 주요 개선 사항

### Patch (x.x.X)
- 버그 수정
- 문서 업데이트
- 사소한 개선

---

## 링크

- [1.2.0]: https://github.com/WIZnet-ioNIC/W55RP20-S2E/compare/v1.1.0...v1.2.0
- [1.1.0]: https://github.com/WIZnet-ioNIC/W55RP20-S2E/compare/v1.0.0...v1.1.0
- [1.0.0]: https://github.com/WIZnet-ioNIC/W55RP20-S2E/compare/v0.9.0...v1.0.0
- [0.9.0]: https://github.com/WIZnet-ioNIC/W55RP20-S2E/releases/tag/v0.9.0

---

## 기여자

이 프로젝트에 기여한 모든 분들께 감사드립니다.

- **주요 개발**: Community collaboration
- **문서화**: Community contribution
- **테스트**: 자동화 테스트 + 사용자 피드백

---

**검토**: 사용자
**최종 수정**: 2026-01-21
