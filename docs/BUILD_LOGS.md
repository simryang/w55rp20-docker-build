# 빌드 로그 실제 예제

> 실제 빌드 실행 시 출력되는 로그 모음

작성일: 2026-01-21
목적: 실제 빌드 과정을 보여주고, 정상/비정상 케이스를 구분

---

## 목차

1. [첫 빌드 (Clean Build)](#1-첫-빌드-clean-build)
2. [두 번째 빌드 (ccache warm)](#2-두-번째-빌드-ccache-warm)
3. [에러 케이스](#3-에러-케이스)
4. [로그 분석 가이드](#4-로그-분석-가이드)

---

## 1. 첫 빌드 (Clean Build)

### 환경
- 날짜: 2026-01-21 07:48:36 KST
- 시스템: Linux, 16 CPU cores
- Docker 이미지: w55rp20:auto (이미 존재)
- 소스: 없음 (클론부터 시작)
- ccache: cold (첫 실행)

### 실행 명령
```bash
sudo ./build.sh --verbose
```

### 1.1 빌드 시작 및 설정

```
[INFO] ===== build.sh v1.1.0 =====
[INFO] SRC_DIR=
[INFO] OUT_DIR=./out
[INFO] JOBS=16
[INFO] TMPFS_SIZE=24g
[INFO] IMAGE=w55rp20:auto
[INFO] PLATFORM=linux/amd64
[INFO] AUTO_BUILD_IMAGE=1
[INFO] UPDATE_REPO=0
[INFO] CLEAN=0
[INFO] BUILD_TYPE=Release
[INFO] VERBOSE=1
[INFO] ===============================
[INFO] REFRESH options (CSV): apt,sdk,cmake,gcc,toolchain,all
[INFO] REFRESH: APT=0 SDK=0 CMAKE=0 GCC=0
계속하시겠습니까? [Y/n]: y
 시작합니다!
```

**설명**:
- JOBS=16: 16개 병렬 작업
- TMPFS_SIZE=24g: 24GB tmpfs 사용
- UPDATE_REPO=0: 소스 업데이트 안 함 (첫 빌드는 클론)
- VERBOSE=1: 상세 로그 출력

### 1.2 소스 클론 (약 30초)

```
[INFO] 소스 없음 -> 클론: /root/W55RP20-S2E
'/root/W55RP20-S2E'에 복제합니다...
remote: Enumerating objects: 2043, done.
remote: Counting objects: 100% (428/428), done.
remote: Compressing objects: 100% (246/246), done.
remote: Total 2043 (delta 238), reused 305 (delta 156), pack-reused 1615 (from 1)
오브젝트를 받는 중: 100% (2043/2043), 650.83 KiB | 21.69 MiB/s, 완료.
델타를 알아내는 중: 100% (1067/1067), 완료.
```

**서브모듈 클론** (약 1분):
```
'libraries/FreeRTOS-Kernel' 경로에 대해 'libraries/FreeRTOS-Kernel' (https://github.com/FreeRTOS/FreeRTOS-Kernel.git) 하위 모듈 등록
'libraries/pico-sdk' 경로에 대해 'libraries/pico-sdk' (https://github.com/raspberrypi/pico-sdk.git) 하위 모듈 등록
...

'/root/W55RP20-S2E/libraries/FreeRTOS-Kernel'에 복제합니다...
remote: Enumerating objects: 177531, done.
오브젝트를 받는 중: 100% (177531/177531), 122.37 MiB | 21.66 MiB/s, 완료.

'/root/W55RP20-S2E/libraries/mbedtls'에 복제합니다...
remote: Enumerating objects: 277804, done.
오브젝트를 받는 중: 100% (277804/277804), 137.51 MiB | 21.43 MiB/s, 완료.
```

**서브모듈 체크아웃**:
```
하위 모듈 경로 'libraries/FreeRTOS-Kernel': 'dbf70559b27d39c1fdb68dfb9a32140b6a6777a0' 체크아웃
하위 모듈 경로 'libraries/pico-sdk': '2.1.0' 체크아웃
```

**총 다운로드 크기**: 약 400MB
**소요 시간**: 1~2분 (네트워크 속도에 따라)

### 1.3 Docker 실행 준비

```
[INFO] ===== SETTINGS =====
[INFO] IMAGE=w55rp20:auto
[INFO] PLATFORM=linux/amd64
[INFO] SRC_DIR=/root/W55RP20-S2E
[INFO] OUT_DIR=./out
[INFO] CCACHE_DIR_HOST=/root/.ccache-w55rp20
[INFO] TMPFS_SIZE=24g
[INFO] JOBS=16
[INFO] BUILD_TYPE=Release
[INFO] AUTO_BUILD_IMAGE=1
[INFO] UPDATE_REPO=0
[INFO] CLEAN=0

[INFO] ===== Docker run command =====
[INFO] sudo docker run --rm -t \
[INFO]   -v "/root/W55RP20-S2E":/work/src \
[INFO]   -v "./out":/work/out \
[INFO]   -v "/root/.ccache-w55rp20":/work/.ccache \
[INFO]   --tmpfs /work/src/build:rw,exec,size="24g" \
[INFO]   -e CCACHE_DIR=/work/.ccache \
[INFO]   -e JOBS="16" \
[INFO]   -e BUILD_TYPE="Release" \
[INFO]   -e UPDATE_REPO="0" \
[INFO]   "w55rp20:auto" /usr/local/bin/docker-build.sh
```

**설명**:
- `-v "/root/W55RP20-S2E":/work/src`: 소스 마운트
- `-v "./out":/work/out`: 출력 디렉토리 마운트
- `-v "/root/.ccache-w55rp20":/work/.ccache`: ccache 마운트
- `--tmpfs /work/src/build:rw,exec,size="24g"`: 24GB tmpfs (빌드 속도 향상)

### 1.4 Docker 내부 빌드 시작

```
[INTERNAL] PATH=/opt/toolchain/bin:/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
[INTERNAL] python=/usr/bin/python
[INTERNAL] python3=/usr/bin/python3
[INTERNAL] ccache found -> enabled
```

**SDK 및 컴파일러 확인**:
```
PICO_SDK_PATH is /opt/pico-sdk
Defaulting platform (PICO_PLATFORM) to 'rp2040' since not specified.
Using board configuration from /opt/pico-sdk/src/boards/include/boards/pico.h

Defaulting compiler (PICO_COMPILER) to 'pico_arm_cortex_m0plus_gcc' since not specified.
Defaulting PICO_GCC_TRIPLE to 'arm-none-eabi'

-- The C compiler identification is GNU 14.2.1
-- The CXX compiler identification is GNU 14.2.1
```

### 1.5 CMake 설정 (약 1초)

```
-- Detecting C compiler ABI info - done
-- Detecting CXX compiler ABI info - done
-- Found Python3: /usr/bin/python3.10 (found version "3.10.12")

-- BOARD_NAME = W55RP20_S2E
-- WIZNET_CHIP = W5500
-- WIZNET_DIR = /work/src/libraries/ioLibrary_Driver
-- AWS_SDK_DIR = /work/src/libraries/aws-iot-device-sdk-embedded-C
-- MBEDTLS_DIR = /work/src/libraries/mbedtls

Build type is Release
Using picotool from /usr/local/bin/picotool

-- Configuring done (0.9s)
-- Generating done (0.2s)
-- Build files have been written to: /work/src/build
```

**주요 설정**:
- 보드: W55RP20_S2E
- 칩: W5500
- 빌드 타입: Release
- Python: 3.10.12
- GCC: 14.2.1

### 1.6 컴파일 (약 40초)

**총 타겟 수**: 2706개

```
[5/2706] Run html_to_c_header.py before build
HTML to C Header Converter
==================================================
HTML file size: 13865 bytes
Array size (including null terminator): 13866 bytes
[SUCCESS] C header file generated successfully: port/app/html_file/Web_page.h

[48/2706] Performing configure step for 'pioasmBuild'
-- The CXX compiler identification is GNU 11.4.0
-- Configuring done (0.3s)
-- Generating done (0.0s)

[415/2706] Performing build step for 'pioasmBuild'
[1/12] Building CXX object CMakeFiles/pioasm.dir/hex_output.cpp.o
[2/12] Building CXX object CMakeFiles/pioasm.dir/json_output.cpp.o
...
[12/12] Linking CXX executable pioasm
```

**주요 단계**:
1. HTML을 C 헤더로 변환
2. pioasm 빌드 (PIO 어셈블러)
3. FreeRTOS 컴파일
4. mbedtls 컴파일
5. AWS IoT SDK 컴파일
6. WIZnet 드라이버 컴파일
7. 애플리케이션 컴파일

**컴파일 진행**:
```
[100/2706] Building C object ...
[500/2706] Building C object ...
[1000/2706] Building C object ...
[1500/2706] Building C object ...
[2000/2706] Building C object ...
[2500/2706] Building C object ...
```

### 1.7 링킹 및 산출물 생성

```
[2690/2706] Linking ASM_ASM executable App/App.elf
[2691/2706] Building BIN file Boot/Boot.bin
[2692/2706] Building HEX file Boot/Boot.hex
[2693/2706] Building UF2 file Boot/Boot.uf2
[2694/2706] Building BIN file App/App.bin
[2695/2706] Building HEX file App/App.hex
[2696/2706] Building UF2 file App/App.uf2

[2700/2706] Linking ASM_ASM executable App/App_linker.elf
[2701/2706] Building BIN file App/App_linker.bin
[2702/2706] Building HEX file App/App_linker.hex
[2703/2706] Building UF2 file App/App_linker.uf2

Step 1: Converting HEX to BIN
Step 2: Converting BIN to UF2
```

### 1.8 포맷팅 (clang-format)

```
Formatting all source files (.c, .h) in /work/src/
Found 118 files to format

Formatting: main.h
Formatting: ConfigData.h
...
Formatting completed! Total files processed: 118
```

### 1.9 산출물 확인

```
[INTERNAL] === OUTPUTS ===
total 8280
-rwxr-xr-x 1 root root  318092 Jan 20 22:51 App.bin
-rwxr-xr-x 1 root root 1762680 Jan 20 22:51 App.elf
-rw-r--r-- 1 root root  894787 Jan 20 22:51 App.hex
-rw-r--r-- 1 root root  636416 Jan 20 22:51 App.uf2
-rwxr-xr-x 1 root root  317840 Jan 20 22:51 App_linker.bin
-rwxr-xr-x 1 root root 1768628 Jan 20 22:51 App_linker.elf
-rw-r--r-- 1 root root  894070 Jan 20 22:51 App_linker.hex
-rw-r--r-- 1 root root  635904 Jan 20 22:51 App_linker.uf2
-rwxr-xr-x 1 root root   60128 Jan 20 22:51 Boot.bin
-rwxr-xr-x 1 root root  837676 Jan 20 22:51 Boot.elf
-rw-r--r-- 1 root root  169187 Jan 20 22:51 Boot.hex
-rw-r--r-- 1 root root  120320 Jan 20 22:51 Boot.uf2
```

**주요 산출물**:
- `App.uf2` (636KB): 애플리케이션 펌웨어
- `App_linker.uf2` (636KB): 링커 포함 버전
- `Boot.uf2` (120KB): 부트로더

### 1.10 ccache 통계

```
[INTERNAL] === CCACHE STATS ===
Summary:
  Hits:               0 / 2421 (0.00 %)
    Direct:           0 / 2421 (0.00 %)
    Preprocessed:     0 / 2421 (0.00 %)
  Misses:          2421
    Direct:        2421
    Preprocessed:  2421
Primary storage:
  Hits:               0 / 4842 (0.00 %)
  Misses:          4842
  Cache size (GB): 0.05 / 5.00 (0.92 %)
```

**해석**:
- 첫 빌드이므로 히트율 0%
- 2421개 컴파일 결과 캐시됨
- 캐시 크기: 50MB / 5GB

### 1.11 tmpfs 사용량

```
=== TMPFS DF ===
Filesystem      Size  Used Avail Use% Mounted on
tmpfs            24G  162M   24G   1% /work/src/build

=== TMPFS DU ===
162M	/work/src/build
```

**해석**:
- 할당: 24GB
- 사용: 162MB
- 여유: 충분함

### 1.12 시간 통계

**Docker 내부 빌드**:
```
Command being timed: "sudo docker run --rm -t ... w55rp20:auto /usr/local/bin/docker-build.sh"
User time (seconds): 0.14
System time (seconds): 0.33
Elapsed (wall clock) time (h:mm:ss or m:ss): 0:43.98
```

**전체 빌드 (build.sh)**:
```
Command being timed: "env SRC_DIR= OUT_DIR=./out ... ./w55build.sh"
User time (seconds): 100.47
System time (seconds): 16.22
Elapsed (wall clock) time (h:mm:ss or m:ss): 2:29.63
```

**시간 분석**:
- 소스 클론: ~1:30
- Docker 내부 빌드: 0:44
- 총 시간: 2:30

### 1.13 빌드 완료

```
[INFO] 빌드 완료. 산출물: ./out

 빌드 성공!

 산출물 위치: ./out

생성된 파일:
   → App.uf2  (624K)
   → App_linker.uf2  (624K)
   → Boot.uf2  (120K)
```

---

## 2. 두 번째 빌드 (ccache warm)

>  **TODO**: ccache가 warm 상태일 때의 빌드 로그

### 예상 특징
- 소스 클론: 건너뜀 (UPDATE_REPO=0)
- ccache 히트율: ~90-95%
- 컴파일 시간: ~5초 (vs 첫 빌드 40초)
- 총 빌드 시간: ~10초 (vs 첫 빌드 2:30)

### 실행 명령
```bash
sudo ./build.sh --verbose
```

### 예상 ccache 통계
```
Summary:
  Hits:            2300 / 2421 (95.00 %)
  Misses:           121
  Cache size (GB): 0.05 / 5.00 (0.92 %)
```

---

## 3. 에러 케이스

### 3.1 Docker 권한 없음

**증상**:
```bash
$ ./build.sh
Got permission denied while trying to connect to the Docker daemon socket
```

**원인**: 현재 사용자가 docker 그룹에 없음

**해결**:
```bash
# 방법 1: sudo 사용
sudo ./build.sh

# 방법 2: docker 그룹 추가
sudo usermod -aG docker $USER
newgrp docker  # 또는 로그아웃 후 재로그인
```

**관련 문서**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md#docker-권한-오류)

---

### 3.2 디스크 공간 부족

>  **TODO**: 실제 에러 로그 캡처 필요

**예상 증상**:
```
Error: No space left on device
docker: Error response from daemon: mkdir /var/lib/docker/overlay2/...
```

**원인**:
- Docker 이미지 크기: ~2GB
- 소스 및 빌드 아티팩트: ~1GB
- 최소 필요 공간: 5GB

**확인**:
```bash
df -h
docker system df
```

**해결**:
```bash
# Docker 정리
docker system prune -a

# 또는 특정 이미지만 삭제
docker rmi w55rp20:auto
```

---

### 3.3 Git Ownership 오류

>  **TODO**: 실제 에러 로그 캡처 필요 (이미 해결됨)

**증상**:
```
fatal: detected dubious ownership in repository at '/workspace'
```

**원인**: Docker mount로 인한 ownership 불일치

**해결**: docker-build.sh에서 자동 처리됨
```bash
git config --global --add safe.directory /work/src
```

**상태**: v1.1.0에서 완전 해결됨

---

### 3.4 네트워크 타임아웃

>  **TODO**: 실제 에러 로그 캡처 필요

**예상 증상**:
```
fatal: unable to access 'https://github.com/...':
Failed to connect to github.com port 443: Connection timed out
```

**원인**:
- 네트워크 연결 불안정
- 방화벽 차단
- DNS 문제

**해결**:
```bash
# 재시도
./build.sh

# 프록시 설정 (필요시)
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080
```

---

## 4. 로그 분석 가이드

### 4.1 주요 단계 식별

빌드 로그에서 주요 단계를 식별하는 방법:

```bash
# 주요 정보 메시지
grep "^\[INFO\]" build.log

# 에러 메시지
grep -i "error\|fatal\|failed" build.log

# 경고 메시지
grep -i "warning" build.log

# 시간 정보
grep "Elapsed" build.log
```

### 4.2 빌드 진행률 추정

```bash
# 컴파일 진행률 (예: [1234/2706])
grep "^\[.*/.*/\]" build.log | tail -1

# 예상 진행률 계산
# 현재/전체 = 1234/2706 = 45.6%
```

### 4.3 성능 분석

**시간 분석**:
```bash
# 전체 빌드 시간
grep "Elapsed (wall clock)" build.log

# Docker 내부 빌드 시간 (첫 번째 Elapsed)
# 전체 빌드 시간 (두 번째 Elapsed)
```

**메모리 사용**:
```bash
# tmpfs 사용량
grep "tmpfs" build.log -A 2

# 최대 메모리
grep "Maximum resident set size" build.log
```

**ccache 효율**:
```bash
# ccache 통계
sed -n '/CCACHE STATS/,/Use the -v/p' build.log
```

### 4.4 에러 디버깅

**컴파일 에러**:
```bash
# 컴파일 에러 찾기
grep "error:" build.log

# 경고 찾기
grep "warning:" build.log

# 컨텍스트 포함 (앞뒤 5줄)
grep -C 5 "error:" build.log
```

**링크 에러**:
```bash
# undefined reference
grep "undefined reference" build.log

# cannot find
grep "cannot find" build.log
```

### 4.5 로그 레벨 이해

| 태그 | 의미 | 중요도 |
|------|------|--------|
| `[INFO]` | 정보성 메시지 | 낮음 |
| `[INTERNAL]` | 내부 디버그 정보 | 낮음 |
| `warning:` | 경고 (빌드는 계속) | 중간 |
| `error:` | 에러 (빌드 실패) | 높음 |
| `fatal:` | 치명적 에러 | 매우 높음 |

### 4.6 일반적인 패턴

**정상 빌드**:
```
[INFO] starting build at ...
[INFO] 이미지 존재: w55rp20:auto
[INFO] 소스 없음 -> 클론: ...
...
[2706/2706] Linking ...
 빌드 성공!
```

**실패한 빌드**:
```
[INFO] starting build at ...
...
[1234/2706] Building C object ...
error: ... undefined reference to ...
make: *** [CMakeFiles/...] Error 1
 빌드 실패!
```

### 4.7 로그 저장 및 공유

**전체 로그 저장**:
```bash
./build.sh 2>&1 | tee build-$(date +%Y%m%d-%H%M%S).log
```

**에러만 저장**:
```bash
./build.sh 2>&1 | tee >(grep -i error > error.log)
```

**로그 압축**:
```bash
gzip build.log
# 결과: build.log.gz (1.1MB → ~200KB)
```

---

## 5. 빌드 시간 참고표

| 빌드 유형 | 소스 클론 | 컴파일 | 총 시간 | ccache 히트율 |
|-----------|-----------|--------|---------|---------------|
| 첫 빌드 (cold) | 1:30 | 0:44 | 2:30 | 0% |
| 두 번째 (warm) | 0:00 | 0:05 | 0:10 | ~95% |
| REFRESH="toolchain" | 0:00 | 0:44 | 0:50 | 0% |
| CLEAN=1 | 0:00 | 0:44 | 0:50 | 0% |

**환경**:
- CPU: 16 cores
- RAM: 24GB tmpfs
- 네트워크: ~20 MB/s

---

## 6. 추가 자료

### 관련 문서
- [README.md](../README.md): 빠른 시작
- [BEGINNER_GUIDE.md](BEGINNER_GUIDE.md): 초보자 가이드
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md): 문제 해결 (TODO)
- [ARCHITECTURE.md](ARCHITECTURE.md): 내부 구조

### 로그 파일 위치
- 실제 빌드 로그: `build.log` (프로젝트 루트)
- Docker 로그: `docker logs <container-id>`
- ccache 통계: `ccache -s`

### 로그 분석 도구
```bash
# 빌드 시간 추세
grep "Elapsed" build-*.log | awk '{print $NF}'

# 에러 발생 빈도
find . -name "build-*.log" -exec grep -c "error:" {} \;

# ccache 효율 추세
find . -name "build-*.log" -exec sed -n '/Hits:/p' {} \;
```

---

**검토**: 사용자
**버전**: 1.0 (첫 빌드 로그만 포함)
**최종 수정**: 2026-01-21

**TODO**:
- [ ] 두 번째 빌드 로그 추가 (ccache warm)
- [ ] 에러 케이스 실제 로그 캡처
- [ ] 다양한 환경 (macOS, Windows WSL) 로그 추가
- [ ] 성능 벤치마크 데이터 추가
