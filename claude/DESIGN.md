# 설계 결정 사항

## REFRESH 메커니즘

**문제:** Dockerfile 안 바뀌어도 외부 리소스는 업데이트됨 (apt, github)
**해결:** ARG 값 변경 → echo → 캐시 무효화

**구현:**
```
build.sh: REFRESH="apt" → REFRESH_APT_BUST="123456"
         ↓
w55build.sh: --build-arg REFRESH_APT=123456
         ↓
Dockerfile: ARG REFRESH_APT=123456
            RUN echo "REFRESH_APT=123456" && apt-get update
            (캐시 키 변경 → 재실행)
```

## 별칭 (Alias) 패턴

**toolchain = cmake + gcc**

**이유:**
- 사용자 편의: 대부분 함께 업데이트
- 세밀 제어: 개별 지정도 가능
- Option C (둘 다 지원) 채택

**구현:**
```bash
case "$token" in
  toolchain) REFRESH_CMAKE=1; REFRESH_GCC=1 ;;
esac
```

## Git Ownership 문제

**원인:** Git 2.35.2+ 보안 패치
**해결:** `git config --global --add safe.directory`
**위치:** entrypoint.sh (컨테이너 내부)

## 변수 전달 체계

**필수:** export + env로 명시적 전달
```bash
export VAR="value"
exec env VAR="$VAR" script.sh
```

**이유:** bash 서브프로세스는 자동 상속 안 됨
