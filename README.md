# W55RP20-S2E Docker Build System

Raspberry Pi Pico 기반 W55RP20 마이크로컨트롤러용 Docker 빌드 환경.

## 빠른 시작

```bash
# 1. 처음 사용 (이미지 자동 빌드 + 소스 클론 + 빌드)
./build.sh

# 2. 산출물 확인
ls -l ~/W55RP20-S2E-out/
```

끝! 이게 전부입니다.

---

## 요구사항

- **Docker** (필수)
- **Git** (필수)
- **16GB+ RAM** 권장 (tmpfs 빌드)
- **Linux** (Ubuntu 20.04+, Debian 등)

---

## 주요 기능

### ✨ 자동화
- 이미지 없으면 자동 빌드
- 소스 없으면 자동 클론
- RAM 빌드 (빠름)
- ccache 지원

### 🎯 선택적 캐시 무효화 (REFRESH)
외부 리소스 업데이트 시:

```bash
REFRESH="apt" ./build.sh         # apt 패키지 업데이트
REFRESH="sdk" ./build.sh         # Pico SDK 재다운로드
REFRESH="toolchain" ./build.sh   # CMake + GCC 재설치
REFRESH="all" ./build.sh         # 전체 재빌드
```

### ⚙️ 로컬 설정 (선택)
고성능/저사양 환경 맞춤:

```bash
cp build.config.example build.config
vim build.config  # JOBS, TMPFS_SIZE 조정
./build.sh        # 설정 자동 로드
```

---

## 상황별 사용법

### 기본 빌드
```bash
./build.sh
```

### 산출물 정리 후 빌드
```bash
CLEAN=1 ./build.sh
```

### 소스 코드 최신으로 갱신
```bash
UPDATE_REPO=1 ./build.sh
```

### 특정 브랜치/태그 빌드
```bash
REPO_REF=v1.2.3 ./build.sh
```

### 디버그 빌드
```bash
BUILD_TYPE=Debug ./build.sh
```

### 저사양 환경 (라즈베리파이 등)
```bash
JOBS=4 TMPFS_SIZE=2g ./build.sh
```

### 디버깅 (상세 출력)
```bash
VERBOSE=1 ./build.sh
```

---

## 폴더 구조

```
.
├── build.sh              # 초보자용 실행 스크립트
├── w55build.sh           # 고급 사용자용 (상세 제어)
├── docker-build.sh       # 컨테이너 내부 빌드 로직
├── Dockerfile            # 빌드 환경 정의
├── entrypoint.sh         # 컨테이너 진입점
├── build.config.example  # 설정 예시
└── claude/               # AI 협업 문서 (개발자용)
```

---

## 문제 해결

### Docker 권한 오류
```bash
# 방법 1: sudo 없이 docker 실행 (권장)
sudo usermod -aG docker $USER
# 로그아웃 후 재로그인

# 방법 2: 임시 (매번 sudo 필요)
# 코드는 이미 sudo 포함
```

### 디스크 공간 부족
```bash
# Docker 정리
sudo docker system prune -a

# ccache 정리
rm -rf ~/.ccache-w55rp20/*
```

### 메모리 부족
```bash
# tmpfs 크기 줄이기
TMPFS_SIZE=8g ./build.sh
```

### 빌드 실패 시
```bash
# 상세 로그 확인
VERBOSE=1 ./build.sh

# 완전 재빌드
sudo docker buildx build --no-cache -t w55rp20:auto --load .
CLEAN=1 ./build.sh
```

---

## 고급 사용

### w55build.sh 직접 사용
```bash
# 모든 변수 직접 지정
IMAGE=custom:tag \
JOBS=32 \
TMPFS_SIZE=48g \
AUTO_BUILD_IMAGE=0 \
./w55build.sh
```

### 컨테이너 내부 진입
```bash
sudo docker run --rm -it --entrypoint bash w55rp20:auto
```

### 산출물 위치 변경
```bash
OUT_DIR=/path/to/output ./w55build.sh
```

---

## 성능 팁

### 1. ccache 활용
자동 활성화됨. 두 번째 빌드부터 빠름.

### 2. 병렬도 조정
```bash
# CPU 코어 수 확인
nproc

# 코어 수만큼 설정
JOBS=$(nproc) ./build.sh
```

### 3. tmpfs 크기 최적화
```bash
# 메모리 확인
free -h

# 메모리의 50% 정도 권장
TMPFS_SIZE=24g ./build.sh  # 48GB RAM 시스템
```

---

## 개발자 가이드

### AI 협업
- `claude/README.md` - 빠른 컨텍스트
- `claude/DESIGN.md` - 설계 결정
- `claude/GPT_INSTRUCTIONS.md` - GPT/Gemini 가이드

### 코드 수정 시
1. 변경 전 `VERBOSE=1` 테스트
2. Git 커밋 (상세한 메시지)
3. `claude/` 문서 업데이트 (필요 시)

---

## 라이선스 & 기여

프로젝트 소스: https://github.com/WIZnet-ioNIC/W55RP20-S2E

---

## 변경 이력

최근 개선사항은 `git log` 참조
