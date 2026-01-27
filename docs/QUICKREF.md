# W55RP20 빌드 시스템 빠른 참조

> 1페이지 치트시트 - 인쇄해서 책상에 붙여두세요!

버전: 1.0 | 작성일: 2026-01-21

---

## 빠른 시작

```bash
git clone https://github.com/WIZnet-ioNIC/W55RP20-S2E.git
cd W55RP20-S2E
./build.sh
```

---

## 자주 쓰는 명령어

| 작업 | 명령어 |
|------|--------|
| **기본 빌드** | `./build.sh` |
| **정리 후 빌드** | `./build.sh --clean` |
| **디버그 빌드** | `./build.sh --debug` |
| **상세 로그** | `./build.sh --verbose` |
| **도움말** | `./build.sh --help` |
| **설정 확인** | `./build.sh --show-config` |

---

## 주요 옵션

```bash
./build.sh \
  --project /path/to/source \    # 소스 경로
  --output /path/to/out \        # 출력 경로
  --jobs 8 \                     # 병렬 작업 수
  --tmpfs 16g \                  # tmpfs 크기
  --refresh toolchain \          # 캐시 무효화
  --clean                        # 빌드 전 정리
```

---

## 환경 변수

```bash
JOBS=16 ./build.sh              # 병렬 작업 수
TMPFS_SIZE=24g ./build.sh       # tmpfs 크기
REFRESH="all" ./build.sh        # 전체 재빌드
BUILD_TYPE=Debug ./build.sh     # 디버그 빌드
VERBOSE=1 ./build.sh            # 상세 로그
```

---

## 빌드 시간

| 상황 | 시간 |
|------|------|
| 첫 빌드 (Docker 이미지 생성) | **20-25분** |
| 두 번째 빌드 (ccache 활용) | **10초** |
| REFRESH="all" | 2-3분 |
| --clean 후 빌드 | 1분 |

---

## REFRESH 옵션

| 값 | 효과 | 시간 |
|----|------|------|
| `apt` | apt 패키지만 재설치 | +2분 |
| `sdk` | Pico SDK만 재클론 | +1분 |
| `cmake` | CMake만 재설치 | +30초 |
| `gcc` | ARM GCC만 재설치 | +1분 |
| `toolchain` | cmake + gcc | +2분 |
| `all` | 전체 재빌드 | +10분 |

---

## 출력 파일

```
out/
├── App.uf2          ← 메인 펌웨어 (이걸 사용)
├── App_linker.uf2   ← 링커 포함 버전
├── Boot.uf2         ← 부트로더
├── App.bin          ← 바이너리
├── App.elf          ← 디버깅용
└── App.hex          ← HEX 형식
```

**보드 업로드**: BOOTSEL 모드 → `App.uf2` 복사

---

## 문제 해결 (3단계)

### 1. Docker 실행 중?
```bash
docker ps  # 에러 없으면 OK
```

### 2. 디스크 공간 충분?
```bash
df -h .    # 최소 5GB 필요
```

### 3. 권한 있음?
```bash
groups     # 'docker' 있어야 함
```

---

## 흔한 에러

| 에러 | 해결 |
|------|------|
| `permission denied` | `sudo usermod -aG docker $USER` 후 `newgrp docker` |
| `No space left` | `docker system prune -a` |
| `Connection timeout` | 네트워크 확인, 재시도 |
| `dubious ownership` | v1.1.0에서 자동 해결됨 |

---

## 설정 파일

**build.config** (선택사항):
```bash
JOBS=16
TMPFS_SIZE=24g
OUT_DIR=./out
BUILD_TYPE=Release
```

---

## Docker 명령어

```bash
# 이미지 확인
docker images | grep w55rp20

# 컨테이너 확인
docker ps -a

# 정리
docker system prune -a

# ccache 통계
ccache -s
```

---

## 성능 튜닝

| 환경 | JOBS | TMPFS_SIZE | 빌드 시간 |
|------|------|------------|-----------|
| 데스크톱 (16 cores) | 16 | 24g | 2:30 / 0:10 |
| 노트북 (8 cores) | 8 | 16g | 4:00 / 0:15 |
| 라즈베리파이 4 | 2-4 | 0-4g | 8:00 / 0:30 |

---

## 문서 찾기

| 질문 | 문서 |
|------|------|
| 처음 사용인데? | [BEGINNER_GUIDE.md](BEGINNER_GUIDE.md) |
| 상세 매뉴얼은? | [USER_GUIDE.md](USER_GUIDE.md) |
| 에러가 났는데? | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) |
| 예제가 필요해? | [EXAMPLES.md](EXAMPLES.md) |
| 설치가 안 돼? | [INSTALL_*.md](INSTALL_LINUX.md) |
| 용어가 뭐야? | [GLOSSARY.md](GLOSSARY.md) |
| 빌드 로그는? | [BUILD_LOGS.md](BUILD_LOGS.md) |
| 변경 사항은? | [CHANGELOG.md](CHANGELOG.md) |

---

## 팁

**첫 빌드는 오래 걸립니다** (20분) - Docker 이미지 빌드 때문
**두 번째부터 빠릅니다** (10초) - ccache 덕분
**tmpfs 사용 권장** - SSD보다 10배 빠름
**JOBS = CPU 코어 수** - 최대 성능
**--verbose로 디버깅** - 문제 발생 시
**build.config 활용** - 매번 옵션 입력 불필요

---

## 지원

- 문서: [README.md](../README.md)
- 이슈: https://github.com/WIZnet-ioNIC/W55RP20-S2E/issues
- 질문: GitHub Discussions

---

**이 페이지를 인쇄하여 책상에 붙여두세요!** 
