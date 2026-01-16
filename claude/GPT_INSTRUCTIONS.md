# GPT/Gemini를 위한 지시사항

## 시작 전 필수 읽기

1. `claude/README.md` - 전체 구조 이해
2. `claude/DESIGN.md` - 설계 결정
3. `claude/VARIABLES.md` - 변수 체계
4. `claude/ISSUES.md` - 알려진 문제

## 작업 시 주의사항

### 절대 하지 말 것
- build.sh의 기본값 함부로 변경 (초보자 영향)
- heredoc 다시 사용 (docker-build.sh 유지)
- 강제 변경 (warning만, 사용자 지정 존중)
- REFRESH 메커니즘 변경 (동작 중)

### 권장 사항
- 변경 전 VERBOSE=1로 테스트
- 커밋 전 shellcheck 실행
- 설계 변경 시 DESIGN.md 업데이트
- 버그 발견 시 ISSUES.md 업데이트

## 파일별 역할

**건드려도 됨:**
- build.sh: 기본값, 주석
- w55build.sh: 로직 개선
- docker-build.sh: 빌드 로직
- build.config.example: 문서

**신중하게:**
- Dockerfile: 레이어 순서 중요
- entrypoint.sh: git config 유지

**건드리지 마:**
- .gitignore: build.config 필수

## 코딩 스타일

- Bash: `set -euo pipefail` 필수
- 변수: `"${VAR:-default}"` 형식
- 에러: `die()` 함수 사용
- 로그: `log()`, `warn()` 사용

## 테스트 필수 항목

```bash
# 기본
./build.sh

# VERBOSE
VERBOSE=1 ./build.sh

# REFRESH
REFRESH="apt" ./build.sh

# 조합
VERBOSE=1 REFRESH="toolchain" ./build.sh
```
