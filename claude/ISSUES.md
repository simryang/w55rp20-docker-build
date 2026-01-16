# 알려진 이슈 및 해결 방법

## ✅ 해결됨

### Git ownership 오류
**증상:** `fatal: detected dubious ownership`
**해결:** entrypoint.sh에 safe.directory 추가 (ef45961)

### AUTO_BUILD_IMAGE 불일치
**증상:** build.sh와 w55build.sh 기본값 다름
**해결:** 둘 다 1로 통일 (461b282)

### heredoc 디버깅 불가
**증상:** 70줄 heredoc, shellcheck 불가
**해결:** docker-build.sh 분리 (eb8051a)

## ⚠️ 알려진 제약

### Docker 권한 필요
- 모든 docker 명령에 sudo 필요
- 해결: Docker 그룹 추가 또는 rootless Docker

### tmpfs 크기
- 기본 24g는 실제 메모리 소비 아님 (limit)
- 저사양 환경: build.config에서 조정

### REFRESH는 수동
- Dockerfile 변경은 자동 감지
- 외부 리소스 변경은 REFRESH 필요

## 🔍 디버깅 체크리스트

1. `VERBOSE=1 ./build.sh`
2. Docker 데몬 확인: `sudo docker info`
3. 권한 확인: `ls -la $HOME/W55RP20-S2E`
4. 디스크 공간: `df -h`
5. 메모리: `free -h`
