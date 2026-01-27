# 문제 해결 가이드

> W55RP20-S2E 빌드 시스템 에러 및 해결 방법

작성일: 2026-01-21
버전: 1.0

---

## 목차

1. [빠른 진단](#빠른-진단)
2. [Docker 관련](#docker-관련)
3. [빌드 관련](#빌드-관련)
4. [네트워크 관련](#네트워크-관련)
5. [권한 관련](#권한-관련)
6. [디스크 공간 관련](#디스크-공간-관련)
7. [성능 관련](#성능-관련)
8. [기타](#기타)
9. [에러 인덱스](#에러-인덱스)

---

## 빠른 진단

### 증상별 빠른 찾기

| 증상 | 가능한 원인 | 바로가기 |
|------|-------------|----------|
| `Directory does not contain` | 서브모듈 미초기화 | [→](#b000-서브모듈-미초기화-오류) |
| `permission denied` | Docker 권한 | [→](#e001-docker-권한-오류) |
| `No space left` | 디스크 공간 부족 | [→](#e006-디스크-공간-부족) |
| `Connection timeout` | 네트워크 문제 | [→](#e004-네트워크-타임아웃) |
| `dubious ownership` | Git ownership | [→](#e002-git-ownership-오류) |
| `Image not found` | Docker 이미지 없음 | [→](#e003-docker-이미지-없음) |
| `ftp_getc` 컴파일 오류 | 소스 코드 버그 | [→](#b001-1-ftpclient-컴파일-오류-ftp_getc) |
| 빌드가 느림 | 성능 설정 | [→](#p001-빌드-속도-느림) |
| `undefined reference` | 링크 에러 | [→](#b002-링크-에러) |

### 3단계 진단 플로우

```
1. Docker가 실행 중인가?
   ├─ NO → docker ps 실행 → 에러 확인
   └─ YES → 2단계

2. 디스크 공간이 충분한가? (최소 5GB)
   ├─ NO → docker system prune
   └─ YES → 3단계

3. 네트워크 연결이 정상인가?
   ├─ NO → 프록시 설정 확인
   └─ YES → 에러 메시지로 검색
```

---

## Docker 관련

### E001: Docker 권한 오류

**난이도**: (쉬움)

**증상**:
```
Got permission denied while trying to connect to the Docker daemon socket
at unix:///var/run/docker.sock: Get "http://%2Fvar%2Frun%2Fdocker.sock/...":
dial unix /var/run/docker.sock: connect: permission denied
```

**원인**:
현재 사용자가 `docker` 그룹에 속하지 않아서 Docker daemon에 접근할 수 없습니다.

**해결 방법 1: sudo 사용** (즉시 해결)
```bash
sudo ./build.sh
```

**해결 방법 2: docker 그룹 추가** (권장, 영구 해결)
```bash
# 1. 현재 사용자를 docker 그룹에 추가
sudo usermod -aG docker $USER

# 2. 그룹 변경 적용 (둘 중 하나)
# 방법 A: 새 셸 시작
newgrp docker

# 방법 B: 로그아웃 후 재로그인
logout
# (다시 로그인)

# 3. 확인
groups
# 출력에 'docker'가 있어야 함

# 4. 테스트
docker ps
./build.sh
```

**예방**:
- Docker 설치 시 자동으로 docker 그룹에 추가되지 않을 수 있습니다
- 설치 후 반드시 그룹 추가를 확인하세요

**관련 문서**: [INSTALL_LINUX.md](INSTALL_LINUX.md#docker-설치)

---

### E002: Git ownership 오류

**난이도**: (쉬움)
**상태**: v1.1.0에서 자동 수정됨

**증상**:
```
fatal: detected dubious ownership in repository at '/work/src'
To add an exception for this directory, call:
    git config --global --add safe.directory /work/src
```

**원인**:
Docker 컨테이너 내부와 호스트 간의 파일 소유권 불일치

**해결**:
v1.1.0 이상에서는 자동으로 처리됩니다. 문제가 계속되면:

```bash
# 수동 수정
git config --global --add safe.directory '*'

# 또는 빌드 스크립트 재실행
./build.sh
```

**예방**:
- 최신 버전 사용 (v1.1.0+)
- UPDATE_REPO=0 사용 시 git 작업 최소화

**관련 커밋**: d4aa905

---

### E003: Docker 이미지 없음

**난이도**: (쉬움)

**증상**:
```
Unable to find image 'w55rp20:auto' locally
docker: Error response from daemon: pull access denied for w55rp20
```

**원인**:
- AUTO_BUILD_IMAGE=0으로 설정되어 자동 빌드가 비활성화됨
- 또는 이미지가 삭제됨

**해결**:
```bash
# 방법 1: AUTO_BUILD_IMAGE=1로 실행 (기본값)
./build.sh

# 방법 2: 명시적으로 이미지 빌드
AUTO_BUILD_IMAGE=1 ./build.sh

# 방법 3: w55build.sh로 직접 빌드
AUTO_BUILD_IMAGE=1 ./w55build.sh
```

**확인**:
```bash
# 이미지 존재 확인
docker images | grep w55rp20

# 예상 출력:
# w55rp20  auto  abc12345  2 days ago  2.1GB
```

**예방**:
- build.config에 `AUTO_BUILD_IMAGE=1` 설정
- REFRESH 옵션 사용 시 AUTO_BUILD_IMAGE=0 설정하지 않기

---

### E004: Docker daemon 미실행

**난이도**: (쉬움)

**증상**:
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock.
Is the docker daemon running?
```

**원인**:
Docker daemon(dockerd)이 실행되지 않음

**해결**:
```bash
# Ubuntu/Debian (systemd)
sudo systemctl start docker
sudo systemctl enable docker  # 부팅 시 자동 시작

# 상태 확인
sudo systemctl status docker

# 로그 확인 (문제 있을 시)
journalctl -u docker -n 50
```

**macOS**:
```bash
# Docker Desktop 실행
open -a Docker
```

**Windows (WSL2)**:
```powershell
# Docker Desktop 실행
Start-Process "Docker Desktop"
```

**예방**:
- `systemctl enable docker`로 자동 시작 설정
- Docker Desktop 자동 시작 옵션 활성화

---

## 빌드 관련

### B000: 서브모듈 미초기화 오류

**난이도**: ⭐ (쉬움)

**증상**:
```
CMake Error at FreeRTOS_Kernel_import.cmake:58 (message):
  Directory '/work/src/libraries/FreeRTOS-Kernel' does not contain an RP2040
  port here: portable/ThirdParty/GCC/RP2040
```

또는:
```
fatal: not a git repository (or any parent up to mount point /)
```

**원인**:
- `git clone` 시 `--recursive` 옵션 누락
- Git 서브모듈이 초기화되지 않음
- W55RP20-S2E는 5개의 서브모듈 사용:
  - FreeRTOS-Kernel
  - aws-iot-device-sdk-embedded-C
  - ioLibrary_Driver
  - mbedtls
  - pico-sdk

**해결**:

**방법 1: 서브모듈 수동 초기화** (권장)
```bash
# 소스 디렉토리로 이동
cd /path/to/W55RP20-S2E

# 서브모듈 상태 확인 (- 기호는 미초기화)
git submodule status

# 서브모듈 초기화 및 업데이트
git submodule update --init --recursive

# 다시 빌드
cd /path/to/build-system
./build.sh
```

**방법 2: UPDATE_REPO 사용**
```bash
# 빌드 시스템이 자동으로 서브모듈 업데이트
UPDATE_REPO=1 ./build.sh
```

**방법 3: 처음부터 다시 클론** (확실함)
```bash
# 기존 소스 삭제
rm -rf /path/to/W55RP20-S2E

# --recursive로 다시 클론
git clone --recursive https://github.com/WIZnet-ioNIC/W55RP20-S2E.git

./build.sh
```

**검증**:
```bash
cd /path/to/W55RP20-S2E
git submodule status
# 정상: 공백으로 시작 (예: dbf70559b27d39c1...)
# 오류: - 기호로 시작 (예: -dbf70559b27d39c1...)
```

**예방**:
- 항상 `git clone --recursive`로 클론
- 또는 `.build-config`에 UPDATE_REPO=1 설정

---

### B001: 컴파일 에러

**난이도**: ⭐⭐(어려움)

**증상**:
```
/work/src/main/App/main.c:123:5: error: 'foo' undeclared (first use in this function)
     foo();
     ^~~
```

**원인**:
- 소스 코드 오류
- 헤더 파일 누락
- 타입 불일치

**해결**:

1. **에러 메시지 분석**:
   ```bash
   # 에러 로그 저장
   ./build.sh 2>&1 | tee build-error.log

   # 에러만 추출
   grep "error:" build-error.log
   ```

2. **파일 및 줄 번호 확인**:
   - 에러 메시지: `/work/src/main/App/main.c:123`
   - 실제 파일: `main/App/main.c` 123줄

3. **일반적인 수정**:
   ```c
   // 함수 선언 추가
   void foo(void);

   // 또는 헤더 포함
   #include "foo.h"
   ```

4. **재빌드**:
   ```bash
   ./build.sh
   ```

**디버깅 팁**:
```bash
# VERBOSE 모드로 상세 로그
./build.sh --verbose 2>&1 | tee verbose.log

# 특정 파일만 다시 컴파일 (Docker 내부)
sudo docker run --rm -it -v $(pwd):/work w55rp20:auto bash
cd /work/src/build
make main/App/main.c.obj VERBOSE=1
```

---

### B001-1: FTPClient 컴파일 오류 (ftp_getc)

**난이도**: ⭐⭐ (어려움)

**증상**:
```
ftpc.c:579:30: error: implicit declaration of function 'ftp_getc';
did you mean 'fgetc'? [-Wimplicit-function-declaration]
  579 |                 gMsgBuf[i] = ftp_getc();
      |                              ^~~~~~~~
      |                              fgetc
```

**원인**:
- W55RP20-S2E 프로젝트에서 `ftp_getc()` 함수가 선언되지 않음
- `libraries/ioLibrary_Driver/Internet/FTPClient/ftpc.h`에서 함수 정의 누락
- 프로젝트 소스 코드 자체의 문제 (빌드 시스템 문제 아님)

**해결**:

**방법 1: 프로젝트에 함수 구현 추가**

`ftpc.h`에 함수 선언 추가가 필요합니다. 이것은 프로젝트 메인테이너에게 문의해야 할 사항입니다.

**방법 2: FTPClient 기능 비활성화** (임시 해결)

프로젝트의 CMakeLists.txt에서 FTPClient 빌드를 비활성화:
```bash
# libraries/CMakeLists.txt 편집
# FTPCLIENT 관련 부분 주석 처리 또는 제거
```

**방법 3: 다른 브랜치/태그 사용**

안정적인 릴리스 태그 사용:
```bash
cd /path/to/W55RP20-S2E
git fetch --tags
git tag  # 사용 가능한 태그 확인
git checkout v1.0.0  # 예시: 안정 버전
git submodule update --init --recursive
cd /path/to/build-system
./build.sh
```

**참고**:
- 이것은 소스 코드 버그입니다
- 프로젝트 이슈 트래커에 보고 필요: https://github.com/WIZnet-ioNIC/W55RP20-S2E/issues
- FTPClient 기능을 사용하지 않는다면 비활성화 권장

---

### B002: 링크 에러

**난이도**: ⭐⭐(어려움)

**증상**:
```
/opt/toolchain/bin/../lib/gcc/arm-none-eabi/14.2.1/../../../../arm-none-eabi/bin/ld:
CMakeFiles/App.elf.dir/main.c.obj: in function `main':
main.c:(.text.main+0x12): undefined reference to `missing_function'
collect2: error: ld returned 1 exit status
```

**원인**:
- 함수 구현 누락
- 라이브러리 링크 누락
- 링커 스크립트 오류

**해결**:

1. **undefined reference to 'xxx'**:
   ```c
   // 함수 구현 추가
   void missing_function(void) {
       // 구현
   }
   ```

2. **라이브러리 링크 추가** (CMakeLists.txt):
   ```cmake
   target_link_libraries(App
       pico_stdlib
       hardware_gpio
       missing_lib  # 추가
   )
   ```

3. **링커 스크립트 확인**:
   ```bash
   # 링커 스크립트 위치 확인
   find . -name "*.ld"

   # 링커 옵션 확인
   grep -r "LDFLAGS" CMakeLists.txt
   ```

**디버깅**:
```bash
# 심볼 확인
arm-none-eabi-nm out/App.elf | grep missing_function

# 라이브러리 확인
arm-none-eabi-objdump -t out/App.elf | grep missing_function
```

---

### B003: CMake 설정 오류

**난이도**: ⭐(중간)

**증상**:
```
CMake Error at CMakeLists.txt:15 (project):
  No CMAKE_C_COMPILER could be found.
```

**원인**:
- 컴파일러 경로 문제
- SDK 경로 문제
- Docker 이미지 손상

**해결**:
```bash
# 1. Docker 이미지 재빌드
REFRESH="toolchain" ./build.sh

# 2. 또는 전체 재빌드
REFRESH="all" ./build.sh

# 3. 빌드 디렉토리 클리어
./build.sh --clean
```

**수동 확인**:
```bash
# Docker 내부에서 확인
sudo docker run --rm -it w55rp20:auto bash

# 컴파일러 확인
which arm-none-eabi-gcc
arm-none-eabi-gcc --version

# SDK 확인
echo $PICO_SDK_PATH
ls -la $PICO_SDK_PATH
```

---

### B004: 빌드 디렉토리 오염

**난이도**: (쉬움)

**증상**:
```
CMake Error: The current CMakeCache.txt directory ... is different than the directory ... where CMakeCache.txt was created.
```

**원인**:
이전 빌드 설정이 남아있음

**해결**:
```bash
# 방법 1: --clean 옵션
./build.sh --clean

# 방법 2: CLEAN=1 환경 변수
CLEAN=1 ./build.sh

# 방법 3: 수동 삭제
rm -rf build/
./build.sh
```

**예방**:
- 빌드 옵션 변경 시 --clean 사용
- REFRESH 옵션 변경 시 --clean 사용

---

## 네트워크 관련

### N001: 네트워크 타임아웃

**난이도**: ⭐(중간)

**증상**:
```
fatal: unable to access 'https://github.com/WIZnet-ioNIC/W55RP20-S2E.git/':
Failed to connect to github.com port 443: Connection timed out
```

**원인**:
- 네트워크 연결 불안정
- 방화벽 차단
- DNS 문제
- GitHub 장애

**해결**:

1. **네트워크 확인**:
   ```bash
   # 인터넷 연결 확인
   ping -c 3 8.8.8.8

   # DNS 확인
   ping -c 3 github.com

   # GitHub 연결 확인
   curl -I https://github.com
   ```

2. **재시도**:
   ```bash
   # 단순 재시도
   ./build.sh

   # 타임아웃 늘리기
   git config --global http.timeout 300
   ./build.sh
   ```

3. **프록시 설정** (필요시):
   ```bash
   # HTTP 프록시
   export HTTP_PROXY=http://proxy.example.com:8080
   export HTTPS_PROXY=http://proxy.example.com:8080

   # Git 프록시
   git config --global http.proxy http://proxy.example.com:8080

   ./build.sh
   ```

4. **대체 저장소** (긴급):
   ```bash
   # w55build.sh 편집
   # REPO_URL을 mirror로 변경
   REPO_URL="https://mirror.example.com/W55RP20-S2E.git"
   ```

**예방**:
- 안정적인 네트워크 환경에서 빌드
- 소스를 미리 다운로드해두기

---

### N002: 서브모듈 클론 실패

**난이도**: ⭐(중간)

**증상**:
```
Cloning into '/root/W55RP20-S2E/libraries/pico-sdk'...
error: RPC failed; curl 56 GnuTLS recv error (-54): Error in the pull function.
fatal: the remote end hung up unexpectedly
```

**원인**:
- 대용량 저장소 클론 시 네트워크 불안정
- Git buffer 크기 부족

**해결**:
```bash
# 1. Git buffer 크기 증가
git config --global http.postBuffer 524288000  # 500MB

# 2. shallow clone 사용 (빠르지만 히스토리 제한)
git config --global submodule.recurse true
git config --global submodule.shallow true

# 3. 재시도
./build.sh

# 4. 수동 서브모듈 업데이트 (필요시)
cd /root/W55RP20-S2E
git submodule update --init --recursive --depth 1
```

**예방**:
- 안정적인 네트워크 환경
- 첫 빌드는 여유있는 시간에

---

## 권한 관련

### P001: 출력 디렉토리 권한 오류

**난이도**: (쉬움)

**증상**:
```
mkdir: cannot create directory './out': Permission denied
```

**원인**:
out 디렉토리에 쓰기 권한 없음

**해결**:
```bash
# 1. 권한 확인
ls -la out/

# 2. 권한 수정
sudo chown -R $USER:$USER out/

# 3. 또는 삭제 후 재생성
rm -rf out/
./build.sh
```

**예방**:
- 처음부터 sudo 없이 실행
- OUT_DIR을 사용자 소유 디렉토리로 설정

---

### P002: ccache 디렉토리 권한

**난이도**: (쉬움)

**증상**:
```
ccache: error: Failed to create directory /root/.ccache-w55rp20: Permission denied
```

**원인**:
ccache 디렉토리 권한 문제

**해결**:
```bash
# 1. ccache 디렉토리 생성 및 권한 설정
sudo mkdir -p /root/.ccache-w55rp20
sudo chown -R $USER:$USER /root/.ccache-w55rp20

# 2. 또는 사용자 홈으로 변경
# build.config 또는 w55build.sh 편집
CCACHE_DIR_HOST="$HOME/.ccache-w55rp20"
```

**예방**:
- 첫 빌드 시 sudo 사용
- 또는 CCACHE_DIR_HOST를 홈 디렉토리로 설정

---

## 디스크 공간 관련

### D001: 디스크 공간 부족

**난이도**: ⭐(중간)

**증상**:
```
Error: No space left on device
docker: Error response from daemon: mkdir /var/lib/docker/overlay2/...: no space left on device.
```

**원인**:
- Docker 이미지/컨테이너 누적
- 빌드 아티팩트 누적
- 로그 파일 누적

**진단**:
```bash
# 1. 디스크 사용량 확인
df -h

# 2. Docker 사용량 확인
docker system df

# 출력 예:
# TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
# Images          5         1         5.2GB     4.1GB (79%)
# Containers      0         0         0B        0B
# Local Volumes   3         0         1.2GB     1.2GB (100%)
# Build Cache     0         0         0B        0B

# 3. 큰 파일 찾기
du -sh /var/lib/docker/*
```

**해결**:

1. **Docker 정리** (권장):
   ```bash
   # 사용하지 않는 모든 것 제거
   docker system prune -a

   # 확인 프롬프트:
   # WARNING! This will remove:
   #   - all stopped containers
   #   - all networks not used by at least one container
   #   - all images without at least one container associated to them
   #   - all build cache
   # Are you sure you want to continue? [y/N] y
   ```

2. **선택적 정리**:
   ```bash
   # 중지된 컨테이너만
   docker container prune

   # 사용하지 않는 이미지만
   docker image prune -a

   # 사용하지 않는 볼륨만
   docker volume prune
   ```

3. **빌드 캐시 정리**:
   ```bash
   # ccache 정리
   rm -rf ~/.ccache-w55rp20
   # 또는
   ccache -C
   ```

4. **로그 정리**:
   ```bash
   # Docker 로그
   sudo sh -c 'truncate -s 0 /var/lib/docker/containers/*/*-json.log'

   # 시스템 로그
   sudo journalctl --vacuum-time=3d
   ```

**필요 공간**:
- Docker 이미지: ~2GB
- 소스 + 빌드: ~1GB
- ccache: ~0.5GB
- **최소 권장**: 5GB
- **권장**: 10GB 이상

**예방**:
- 주기적으로 `docker system prune` 실행
- 빌드 후 out/ 디렉토리 백업 후 삭제
- 로그 로테이션 설정

---

### D002: tmpfs 크기 부족

**난이도**: ⭐(중간)

**증상**:
```
c++: fatal error: error writing to /tmp/ccXXXXXX.o: No space left on device
```

**원인**:
tmpfs 크기가 빌드에 부족

**진단**:
```bash
# 빌드 로그에서 tmpfs 사용량 확인
grep "TMPFS" build.log

# 출력 예:
# TMPFS_PEAK_GiB=0.16  # 실제 사용량
# tmpfs  24G  162M  24G  1%  # 할당량
```

**해결**:
```bash
# 1. TMPFS_SIZE 증가
./build.sh --tmpfs 32g

# 2. build.config에 설정
echo "TMPFS_SIZE=32g" >> build.config

# 3. 또는 환경 변수
TMPFS_SIZE=32g ./build.sh
```

**권장 크기**:
- 최소: 4GB
- 권장: 8GB
- 여유: 16GB+

**RAM 부족 시**:
```bash
# tmpfs 사용 안 함 (디스크 사용, 느림)
TMPFS_SIZE=0 ./build.sh
```

---

## 성능 관련

### P001: 빌드 속도 느림

**난이도**: ⭐(중간)

**증상**:
- 첫 빌드가 5분 이상 소요
- 두 번째 빌드도 1분 이상 소요

**원인**:
- JOBS 설정이 낮음
- ccache 비활성화
- tmpfs 미사용
- 저사양 시스템

**진단**:
```bash
# 1. CPU 코어 수 확인
nproc
# 출력: 8

# 2. 현재 JOBS 설정 확인
./build.sh --show-config | grep JOBS
# 출력: JOBS=4  # 너무 낮음!

# 3. ccache 확인
ccache -s
# Hits: 2300/2421 (95%)  # 정상
# Hits: 0/2421 (0%)      # 문제!

# 4. 빌드 시간 확인
grep "Elapsed" build.log
# Elapsed time: 0:43.98  # 정상 (첫 빌드)
# Elapsed time: 5:23.12  # 느림!
```

**해결**:

1. **JOBS 최적화**:
   ```bash
   # CPU 코어 수 = JOBS
   JOBS=$(nproc) ./build.sh

   # 또는 build.config
   echo "JOBS=$(nproc)" >> build.config
   ```

2. **ccache 활성화 확인**:
   ```bash
   # ccache 통계
   ccache -s

   # ccache 정리 (문제 시)
   ccache -C

   # 재빌드
   ./build.sh
   ```

3. **tmpfs 사용**:
   ```bash
   # RAM의 50% 정도 할당
   FREE_RAM=$(free -g | awk '/^Mem:/{print $7}')
   TMPFS_SIZE=$((FREE_RAM / 2))g

   ./build.sh --tmpfs ${TMPFS_SIZE}
   ```

4. **SSD 사용**:
   - HDD보다 SSD에서 2-3배 빠름
   - 프로젝트를 SSD로 이동

**성능 벤치마크**:
| 환경 | JOBS | tmpfs | ccache | 첫 빌드 | 두 번째 |
|------|------|-------|--------|---------|---------|
| 최적 | 16 | 24GB | warm | 0:44 | 0:05 |
| 중간 | 8 | 8GB | warm | 1:20 | 0:10 |
| 최소 | 4 | 0 | cold | 5:00 | 4:50 |

---

### P002: 메모리 부족

**난이도**: ⭐(중간)

**증상**:
```
c++: fatal error: Killed signal terminated program cc1plus
```

**원인**:
- RAM 부족
- JOBS가 너무 높음
- tmpfs가 너무 큼

**진단**:
```bash
# 메모리 확인
free -h

# 출력 예:
#               total        used        free      shared  buff/cache   available
# Mem:           7.7Gi       2.0Gi       1.2Gi       500Mi       4.5Gi       4.8Gi
# Swap:          2.0Gi       0.0Ki       2.0Gi

# 빌드 중 모니터링
watch -n 1 free -h
```

**해결**:
```bash
# 1. JOBS 줄이기
JOBS=4 ./build.sh

# 2. tmpfs 줄이기 또는 비활성화
TMPFS_SIZE=4g ./build.sh
# 또는
TMPFS_SIZE=0 ./build.sh

# 3. swap 추가 (긴급)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

**권장 RAM**:
- 최소: 4GB
- 권장: 8GB
- 최적: 16GB+

---

## 기타

### M001: Python 버전 문제

**난이도**: (쉬움)

**증상**:
```
CMake Error: Could not find Python3
```

**원인**:
Docker 이미지 내부 Python 문제 (드물음)

**해결**:
```bash
# Docker 이미지 재빌드
REFRESH="all" ./build.sh

# 또는 이미지 삭제 후 재생성
docker rmi w55rp20:auto
./build.sh
```

---

### M002: 한글 경로 문제

**난이도**: ⭐(중간)

**증상**:
```
Error: Invalid path '한글경로/...'
```

**원인**:
일부 도구가 ASCII가 아닌 경로를 지원하지 않음

**해결**:
```bash
# 프로젝트를 영문 경로로 이동
mv ~/문서/프로젝트 ~/projects/w55rp20
cd ~/projects/w55rp20
./build.sh
```

**예방**:
- 프로젝트 경로에 ASCII만 사용
- 공백도 피하는 것이 좋음

---

### M003: 특정 파일 재컴파일

**난이도**: ⭐⭐(어려움)

**증상**:
특정 파일만 수정했는데 전체 재빌드하고 싶지 않음

**해결**:
```bash
# Docker 컨테이너 진입
sudo docker run --rm -it \
  -v /root/W55RP20-S2E:/work/src \
  -v ./out:/work/out \
  --tmpfs /work/src/build:rw,exec,size=8g \
  w55rp20:auto bash

# 빌드 디렉토리로 이동
cd /work/src/build

# 특정 타겟만 빌드
make main/App/main.c.obj

# 또는 전체 재링크
make App.elf

# 종료
exit
```

**일반 사용자**:
```bash
# 그냥 재빌드 (ccache가 대부분 처리)
./build.sh
# → 5-10초면 완료
```

---

### M004: 빌드 산출물 확인

**난이도**: (쉬움)

**증상**:
빌드는 성공했는데 uf2 파일이 어디 있는지 모르겠음

**해결**:
```bash
# 산출물 확인
ls -lh out/

# 주요 파일:
# App.uf2 - 애플리케이션 펌웨어
# Boot.uf2 - 부트로더

# 파일 정보
file out/App.uf2
# 출력: out/App.uf2: data

# 크기 확인
du -sh out/*.uf2
# 출력:
# 624K    out/App.uf2
# 624K    out/App_linker.uf2
# 120K    out/Boot.uf2
```

**사용 방법**:
1. RP2040 보드를 BOOTSEL 모드로 부팅
2. 드라이브로 마운트됨 (RPI-RP2)
3. uf2 파일을 드래그 앤 드롭
4. 자동으로 재부팅 및 실행

---

## 에러 인덱스

### 알파벳 순

- **C**
  - `c++: fatal error: Killed` → [P002](#p002-메모리-부족)
  - `CMake Error: No CMAKE_C_COMPILER` → [B003](#b003-cmake-설정-오류)
  - `Cannot connect to the Docker daemon` → [E004](#e004-docker-daemon-미실행)
  - `Connection timeout` → [N001](#n001-네트워크-타임아웃)

- **E**
  - `error: xxx undeclared` → [B001](#b001-컴파일-에러)
  - `Error: No space left` → [D001](#d001-디스크-공간-부족)

- **F**
  - `fatal: detected dubious ownership` → [E002](#e002-git-ownership-오류)
  - `fatal: unable to access` → [N001](#n001-네트워크-타임아웃)

- **G**
  - `Got permission denied` → [E001](#e001-docker-권한-오류)

- **M**
  - `mkdir: cannot create directory` → [P001](#p001-출력-디렉토리-권한-오류)

- **N**
  - `No space left on device` → [D001](#d001-디스크-공간-부족)

- **P**
  - `Permission denied` → [E001](#e001-docker-권한-오류) 또는 [P001](#p001-출력-디렉토리-권한-오류)

- **R**
  - `RPC failed` → [N002](#n002-서브모듈-클론-실패)

- **U**
  - `Unable to find image` → [E003](#e003-docker-이미지-없음)
  - `undefined reference to` → [B002](#b002-링크-에러)

---

## 추가 도움말

### 도움 받기

1. **로그 수집**:
   ```bash
   ./build.sh --verbose 2>&1 | tee build-error.log
   ```

2. **시스템 정보 수집**:
   ```bash
   # 시스템 정보
   uname -a > system-info.txt
   docker --version >> system-info.txt
   docker images | grep w55rp20 >> system-info.txt
   free -h >> system-info.txt
   df -h >> system-info.txt
   ```

3. **이슈 리포트**:
   - GitHub Issues: https://github.com/WIZnet-ioNIC/W55RP20-S2E/issues
   - 포함 내용:
     - 에러 메시지
     - build-error.log
     - system-info.txt
     - 실행한 명령어

### 관련 문서

- [README.md](../README.md): 빠른 시작
- [BEGINNER_GUIDE.md](BEGINNER_GUIDE.md): 초보자 가이드
- [BUILD_LOGS.md](BUILD_LOGS.md): 정상 빌드 로그 예제
- [ARCHITECTURE.md](ARCHITECTURE.md): 내부 구조 (고급)

### 디버깅 체크리스트

빌드 실패 시 순서대로 확인:

- [ ] Docker가 실행 중인가? (`docker ps`)
- [ ] 디스크 공간이 충분한가? (`df -h`, 최소 5GB)
- [ ] 네트워크 연결이 정상인가? (`ping github.com`)
- [ ] Docker 권한이 있는가? (`docker ps` 또는 `sudo`)
- [ ] 최신 버전을 사용하는가? (`git pull`)
- [ ] 빌드 디렉토리를 정리했는가? (`./build.sh --clean`)
- [ ] 에러 메시지를 읽어봤는가? (전체 로그 확인)

---

**검토**: 사용자
**버전**: 1.0
**최종 수정**: 2026-01-21

**피드백**:
문제가 해결되지 않았거나 새로운 에러를 발견하면 GitHub Issues에 리포트해주세요.
