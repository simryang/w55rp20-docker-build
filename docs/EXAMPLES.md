# 실전 예제

> W55RP20-S2E 빌드 시스템 사용 예제 모음

작성일: 2026-01-21
버전: 1.0

---

## 목차

1. [예제 1: 첫 빌드 - 기본 펌웨어](#예제-1-첫-빌드---기본-펌웨어)
2. [예제 2: 설정 변경 - UART 속도 수정](#예제-2-설정-변경---uart-속도-수정)
3. [예제 3: 기능 추가 - LED 상태 표시](#예제-3-기능-추가---led-상태-표시)
4. [예제 4: 멀티 프로젝트 - 여러 설정 빌드](#예제-4-멀티-프로젝트---여러-설정-빌드)
5. [예제 5: CI/CD - GitHub Actions](#예제-5-cicd---github-actions)

---

## 예제 1: 첫 빌드 - 기본 펌웨어

### 학습 목표
- 빌드 시스템의 기본 사용법 이해
- 펌웨어 업로드 방법 습득
- 기본 동작 확인

### 난이도
(초급)

### 소요 시간
- 첫 빌드: 20-25분
- 펌웨어 업로드: 1분

---

### 1.1 준비사항

**필요한 것**:
- Linux 시스템 (Ubuntu 20.04+ 권장)
- Docker 설치됨
- 인터넷 연결
- W55RP20-S2E 보드 (선택사항, 테스트용)

**확인**:
```bash
# Docker 실행 확인
docker ps

# 디스크 공간 확인 (최소 5GB)
df -h .
```

---

### 1.2 소스 받기

```bash
# 프로젝트 클론
git clone https://github.com/WIZnet-ioNIC/W55RP20-S2E.git
cd W55RP20-S2E

# 파일 확인
ls -la
# 출력:
# -rwxr-xr-x  1 user user  build.sh
# -rwxr-xr-x  1 user user  w55build.sh
# -rw-r--r--  1 user user  Dockerfile
# drwxr-xr-x  2 user user  main/
# ...
```

---

### 1.3 첫 빌드 실행

```bash
# 기본 빌드 (가장 간단)
./build.sh

# 진행 과정:
# 1. Docker 이미지 빌드 (~10분)
# 2. 소스 클론 (~2분)
# 3. 컴파일 (~1분)
# 4. 산출물 생성 (~5초)
```

**실제 출력**:
```
[INFO] ===== build.sh v1.1.0 =====
[INFO] SRC_DIR=
[INFO] OUT_DIR=./out
[INFO] JOBS=16
계속하시겠습니까? [Y/n]: y
 시작합니다!

[INFO] Docker 이미지 빌드 중...
Step 1/25 : FROM ubuntu:22.04
...
Step 25/25 : CMD ["/bin/bash"]
Successfully built abc12345
Successfully tagged w55rp20:auto

[INFO] 소스 클론 중...
Cloning into '/root/W55RP20-S2E'...
remote: Enumerating objects: 2043, done.
...

[INFO] 빌드 시작...
[1/2706] Building C object ...
...
[2706/2706] Linking ASM_ASM executable App/App.elf

 빌드 성공!

 산출물 위치: ./out

생성된 파일:
   → App.uf2  (624K)
   → App_linker.uf2  (624K)
   → Boot.uf2  (120K)
```

---

### 1.4 산출물 확인

```bash
# 빌드 결과 확인
ls -lh out/

# 출력:
# -rw-r--r-- 1 user user 624K  App.uf2          ← 메인 펌웨어
# -rw-r--r-- 1 user user 624K  App_linker.uf2   ← 링커 포함 버전
# -rw-r--r-- 1 user user 120K  Boot.uf2         ← 부트로더

# 파일 타입 확인
file out/App.uf2
# 출력: out/App.uf2: data
```

**파일 설명**:
- `App.uf2`: W55RP20-S2E 애플리케이션 펌웨어
- `App_linker.uf2`: 링커 스크립트 포함 버전 (디버깅용)
- `Boot.uf2`: 부트로더 (일반적으로 사용 안 함)

---

### 1.5 펌웨어 업로드

**하드웨어가 있는 경우**:

```bash
# 1. W55RP20 보드를 BOOTSEL 모드로 부팅
#    - BOOTSEL 버튼을 누른 상태로 USB 연결
#    - 또는 BOOTSEL 누른 상태로 리셋

# 2. 드라이브 마운트 확인
ls /media/$USER/
# 출력: RPI-RP2

# 3. uf2 파일 복사
cp out/App.uf2 /media/$USER/RPI-RP2/

# 4. 자동으로 재부팅됨
#    LED가 깜빡이기 시작하면 성공
```

**하드웨어가 없는 경우**:
```bash
# 빌드만 확인
echo "빌드 성공! 산출물: out/App.uf2"

# 다음 예제로 진행
```

---

### 1.6 동작 확인

**예상 동작**:
1. 보드 부팅
2. LED 깜빡임 (하트비트)
3. Ethernet 링크업 (연결 시)
4. Serial 포트 대기

**시리얼 모니터**:
```bash
# 시리얼 포트 찾기
ls /dev/ttyACM*
# 출력: /dev/ttyACM0

# 연결 (minicom 또는 screen)
sudo minicom -D /dev/ttyACM0 -b 115200

# 출력 예:
# W55RP20-S2E v1.0
# MAC: 00:08:DC:XX:XX:XX
# IP: 192.168.0.100
# Ready.
```

---

### 1.7 배운 내용

완료한 작업:
- [x] Docker 기반 빌드 시스템 사용
- [x] 소스 코드 자동 클론
- [x] 펌웨어 컴파일
- [x] uf2 파일 생성
- [x] 보드 업로드 (선택)

**핵심 포인트**:
- `./build.sh` 한 번으로 모든 것 완료
- 첫 빌드는 시간이 오래 걸림 (Docker 이미지 빌드)
- 다음 빌드부터는 빠름 (캐시 활용)

---

## 예제 2: 설정 변경 - UART 속도 수정

### 학습 목표
- 설정 파일 이해 및 수정
- 증분 빌드 활용
- 설정 변경 테스트

### 난이도
⭐(중급)

### 소요 시간
- 코드 수정: 5분
- 재빌드: 10초 (ccache 활용)

---

### 2.1 시나리오

기본 UART 속도(115200bps)를 921600bps로 변경하여 더 빠른 데이터 전송

---

### 2.2 설정 파일 찾기

```bash
# 설정 파일 위치 확인
find . -name "*config*" -o -name "*Config*"

# 주요 설정 파일
# - port/app/ConfigData.h (런타임 설정)
# - main/App/main.c (초기화 코드)
```

---

### 2.3 코드 수정

**port/app/ConfigData.h** 수정:

```c
// 원본 (115200 bps)
#define DEFAULT_UART_BAUDRATE   115200

// 수정 (921600 bps)
#define DEFAULT_UART_BAUDRATE   921600
```

**전체 예제**:
```c
/* port/app/ConfigData.h */
#ifndef CONFIGDATA_H
#define CONFIGDATA_H

// UART Configuration
#define DEFAULT_UART_BAUDRATE   921600  // ← 수정됨
#define DEFAULT_UART_DATABITS   8
#define DEFAULT_UART_STOPBITS   1
#define DEFAULT_UART_PARITY     0       // None

// Ethernet Configuration
#define DEFAULT_IP_ADDR         {192, 168, 0, 100}
#define DEFAULT_SUBNET_MASK     {255, 255, 255, 0}
#define DEFAULT_GATEWAY         {192, 168, 0, 1}

#endif // CONFIGDATA_H
```

---

### 2.4 증분 빌드

```bash
# 수정 파일만 재컴파일
./build.sh

# 출력:
# [INFO] ccache 활성화
# [1/2706] Checking files...
# [2/2706] Building C object port/app/ConfigData.c.obj  ← 이 파일만 재컴파일
# [3/2706] Building C object main/App/main.c.obj
# ...
# [2706/2706] Linking ...
#  빌드 성공! (10초 소요)
```

**시간 비교**:
- 첫 빌드: 2분 30초
- 증분 빌드: **10초** ← ccache 덕분!

---

### 2.5 변경 확인

**빌드 전후 비교**:
```bash
# 이전 펌웨어 백업
cp out/App.uf2 out/App.uf2.backup

# 재빌드
./build.sh

# 파일 크기 비교 (거의 동일)
ls -lh out/App.uf2*
# -rw-r--r-- 1 user user 624K  App.uf2
# -rw-r--r-- 1 user user 624K  App.uf2.backup

# 바이너리 차이 확인
diff <(hexdump -C out/App.uf2) <(hexdump -C out/App.uf2.backup) | head
# 몇 바이트 차이 확인됨
```

---

### 2.6 펌웨어 업로드 및 테스트

```bash
# 업로드
cp out/App.uf2 /media/$USER/RPI-RP2/

# 시리얼 연결 (새 속도로)
sudo minicom -D /dev/ttyACM0 -b 921600

# 테스트
echo "Hello 921600!" > /dev/ttyACM0

# Ethernet으로 데이터 전송 시 UART로 출력됨
```

**성능 비교**:
- 115200 bps: 최대 14.4 KB/s
- 921600 bps: 최대 115.2 KB/s ← **8배 빠름!**

---

### 2.7 여러 설정 관리

**.build-config 활용**:

```bash
# 설정 파일 생성
cat > .build-config <<EOF
# 고속 UART 빌드
PROJECT_DIR=/root/W55RP20-S2E
OUT_DIR=./out-highspeed
JOBS=16
EOF

# 빌드
./build.sh
# → ./out-highspeed/App.uf2 생성

# 기본 설정으로 복귀
rm .build-config
./build.sh
# → ./out/App.uf2 생성
```

---

### 2.8 배운 내용

완료한 작업:
- [x] 설정 파일 수정
- [x] 증분 빌드로 빠른 재컴파일
- [x] 설정 변경 테스트
- [x] 여러 빌드 설정 관리

**핵심 포인트**:
- ccache 덕분에 수정한 파일만 재컴파일
- 증분 빌드는 10초 이내
- .build-config로 여러 설정 관리 가능

---

## 예제 3: 기능 추가 - LED 상태 표시

### 학습 목표
- 새 기능 추가
- GPIO 제어 이해
- 디버깅 방법

### 난이도
⭐⭐(고급)

### 소요 시간
- 코드 작성: 30분
- 빌드 및 테스트: 10분

---

### 3.1 시나리오

Ethernet 연결 상태를 LED로 표시:
- 연결됨: LED 켜짐
- 연결 안 됨: LED 깜빡임
- 데이터 전송 중: 빠르게 깜빡임

---

### 3.2 GPIO 핀 확인

**회로도 확인** (W55RP20-S2E):
```
GPIO 25: 온보드 LED (Built-in LED)
```

---

### 3.3 코드 작성

**main/App/led_status.h** (신규 파일):

```c
#ifndef LED_STATUS_H
#define LED_STATUS_H

#include "pico/stdlib.h"

// LED 핀 정의
#define LED_PIN 25

// LED 상태
typedef enum {
    LED_STATE_OFF,           // 꺼짐
    LED_STATE_ON,            // 켜짐
    LED_STATE_BLINK_SLOW,    // 느리게 깜빡임 (1Hz)
    LED_STATE_BLINK_FAST     // 빠르게 깜빡임 (10Hz)
} led_state_t;

// 함수 선언
void led_init(void);
void led_set_state(led_state_t state);
void led_task(void);  // 주기적 호출 필요

#endif // LED_STATUS_H
```

**main/App/led_status.c** (신규 파일):

```c
#include "led_status.h"
#include "pico/time.h"

static led_state_t current_state = LED_STATE_OFF;
static absolute_time_t last_toggle = {0};

void led_init(void)
{
    gpio_init(LED_PIN);
    gpio_set_dir(LED_PIN, GPIO_OUT);
    gpio_put(LED_PIN, 0);
}

void led_set_state(led_state_t state)
{
    current_state = state;

    // 즉시 적용
    if (state == LED_STATE_ON) {
        gpio_put(LED_PIN, 1);
    } else if (state == LED_STATE_OFF) {
        gpio_put(LED_PIN, 0);
    }
}

void led_task(void)
{
    absolute_time_t now = get_absolute_time();

    switch (current_state) {
        case LED_STATE_OFF:
            gpio_put(LED_PIN, 0);
            break;

        case LED_STATE_ON:
            gpio_put(LED_PIN, 1);
            break;

        case LED_STATE_BLINK_SLOW:
            // 1Hz = 500ms ON, 500ms OFF
            if (absolute_time_diff_us(last_toggle, now) > 500000) {
                gpio_put(LED_PIN, !gpio_get(LED_PIN));
                last_toggle = now;
            }
            break;

        case LED_STATE_BLINK_FAST:
            // 10Hz = 50ms ON, 50ms OFF
            if (absolute_time_diff_us(last_toggle, now) > 50000) {
                gpio_put(LED_PIN, !gpio_get(LED_PIN));
                last_toggle = now;
            }
            break;
    }
}
```

**main/App/main.c** 수정:

```c
#include "led_status.h"  // 추가

int main(void)
{
    // 기존 초기화 코드
    stdio_init_all();

    // LED 초기화 추가
    led_init();
    led_set_state(LED_STATE_BLINK_SLOW);  // 시작 시 깜빡임

    // 네트워크 초기화
    network_init();

    // 메인 루프
    while (1) {
        // 네트워크 처리
        network_task();

        // LED 업데이트 추가
        led_task();

        // Ethernet 링크 상태 확인
        if (is_ethernet_link_up()) {
            if (is_data_transferring()) {
                led_set_state(LED_STATE_BLINK_FAST);  // 데이터 전송 중
            } else {
                led_set_state(LED_STATE_ON);  // 연결됨
            }
        } else {
            led_set_state(LED_STATE_BLINK_SLOW);  // 연결 안 됨
        }

        tight_loop_contents();
    }

    return 0;
}
```

---

### 3.4 CMakeLists.txt 수정

**main/App/CMakeLists.txt**:

```cmake
# 기존 소스 목록
set(APP_SOURCES
    main.c
    network.c
    uart.c
    led_status.c  # ← 추가
)

add_executable(App
    ${APP_SOURCES}
)

target_link_libraries(App
    pico_stdlib
    hardware_gpio  # ← 추가 (이미 있을 수 있음)
    # ... 기타 라이브러리
)
```

---

### 3.5 빌드

```bash
# 전체 빌드 (새 파일 추가됨)
./build.sh

# 출력:
# [1/2708] Building C object main/App/led_status.c.obj  ← 새 파일
# [2/2708] Building C object main/App/main.c.obj        ← 수정된 파일
# ...
# [2708/2708] Linking ...
#  빌드 성공!
```

---

### 3.6 디버깅

**VERBOSE 모드로 빌드**:

```bash
./build.sh --verbose 2>&1 | tee build-debug.log

# 특정 경고 확인
grep -i "warning" build-debug.log

# LED 관련 심볼 확인
arm-none-eabi-nm out/App.elf | grep led
# 출력:
# 00012340 T led_init
# 00012350 T led_set_state
# 00012360 T led_task
```

**컴파일 에러 예제**:

```
error: 'is_data_transferring' undeclared
```

**수정**:
```c
// 함수가 없으면 추가
bool is_data_transferring(void) {
    // TODO: 실제 구현
    return false;
}
```

---

### 3.7 테스트

```bash
# 펌웨어 업로드
cp out/App.uf2 /media/$USER/RPI-RP2/

# 동작 확인:
# 1. 보드 부팅 → LED 깜빡임 (느림)
# 2. Ethernet 연결 → LED 켜짐
# 3. 데이터 전송 → LED 빠르게 깜빡임
```

**시리얼 로그**:
```
W55RP20-S2E v1.0
LED: Initialized
LED: Blink slow (no link)
...
Ethernet: Link UP
LED: ON (connected)
...
Data: 1024 bytes received
LED: Blink fast (transferring)
```

---

### 3.8 배운 내용

완료한 작업:
- [x] 새 소스 파일 추가
- [x] GPIO 제어
- [x] CMakeLists.txt 수정
- [x] 디버깅 방법
- [x] 실제 하드웨어 테스트

**핵심 포인트**:
- 새 파일 추가 시 CMakeLists.txt 수정 필수
- VERBOSE 모드로 디버깅
- 심볼 테이블로 함수 확인 가능

---

## 예제 4: 멀티 프로젝트 - 여러 설정 빌드

### 학습 목표
- 여러 프로젝트 동시 관리
- 빌드 자동화
- 설정별 펌웨어 생성

### 난이도
⭐⭐(고급)

### 소요 시간
- 스크립트 작성: 20분
- 빌드: 1분 (병렬 빌드)

---

### 4.1 시나리오

3가지 설정으로 펌웨어 빌드:
1. **Standard**: 기본 설정 (115200 bps)
2. **HighSpeed**: 고속 UART (921600 bps)
3. **LowPower**: 저전력 모드

---

### 4.2 프로젝트 구조

```
projects/
├── standard/
│   ├── ConfigData.h
│   └── .build-config
├── highspeed/
│   ├── ConfigData.h
│   └── .build-config
├── lowpower/
│   ├── ConfigData.h
│   └── .build-config
└── build-all.sh
```

---

### 4.3 설정 파일 준비

**projects/standard/ConfigData.h**:
```c
#define DEFAULT_UART_BAUDRATE   115200
#define SLEEP_MODE_ENABLED      0
```

**projects/highspeed/ConfigData.h**:
```c
#define DEFAULT_UART_BAUDRATE   921600
#define SLEEP_MODE_ENABLED      0
```

**projects/lowpower/ConfigData.h**:
```c
#define DEFAULT_UART_BAUDRATE   115200
#define SLEEP_MODE_ENABLED      1
```

---

### 4.4 빌드 설정

**projects/standard/.build-config**:
```bash
PROJECT_DIR=/root/W55RP20-S2E
OUT_DIR=./out-standard
JOBS=16
```

**projects/highspeed/.build-config**:
```bash
PROJECT_DIR=/root/W55RP20-S2E
OUT_DIR=./out-highspeed
JOBS=16
```

**projects/lowpower/.build-config**:
```bash
PROJECT_DIR=/root/W55RP20-S2E
OUT_DIR=./out-lowpower
JOBS=16
```

---

### 4.5 자동 빌드 스크립트

**projects/build-all.sh**:

```bash
#!/bin/bash
set -e

PROJECTS=("standard" "highspeed" "lowpower")
BUILD_ROOT=$(pwd)

echo "=== Multi-Project Build ==="
echo "Projects: ${PROJECTS[@]}"
echo "=========================="

for project in "${PROJECTS[@]}"; do
    echo ""
    echo "[${project}] Starting..."

    # 설정 파일 복사
    cp projects/${project}/ConfigData.h port/app/ConfigData.h

    # 빌드 설정 복사
    cp projects/${project}/.build-config .build-config

    # 빌드
    ./build.sh

    # 결과 복사
    mkdir -p dist/${project}
    cp out-${project}/App.uf2 dist/${project}/W55RP20_${project}.uf2

    echo "[${project}] Done!"
done

echo ""
echo "=== Build Summary ==="
ls -lh dist/*/
echo "====================="
```

---

### 4.6 실행

```bash
# 실행 권한 추가
chmod +x projects/build-all.sh

# 전체 빌드
./projects/build-all.sh

# 출력:
# === Multi-Project Build ===
# Projects: standard highspeed lowpower
# ==========================
#
# [standard] Starting...
#  빌드 성공!
# [standard] Done!
#
# [highspeed] Starting...
#  빌드 성공!
# [highspeed] Done!
#
# [lowpower] Starting...
#  빌드 성공!
# [lowpower] Done!
#
# === Build Summary ===
# dist/standard/W55RP20_standard.uf2   (624K)
# dist/highspeed/W55RP20_highspeed.uf2 (624K)
# dist/lowpower/W55RP20_lowpower.uf2   (618K)
# =====================
```

---

### 4.7 병렬 빌드 (고급)

**projects/build-all-parallel.sh**:

```bash
#!/bin/bash

PROJECTS=("standard" "highspeed" "lowpower")

build_project() {
    local project=$1
    echo "[${project}] Building..."

    # 임시 디렉토리 사용
    TEMP_DIR=$(mktemp -d)
    cd $TEMP_DIR

    # 소스 복사
    cp -r /original/W55RP20-S2E .
    cd W55RP20-S2E

    # 설정 적용
    cp projects/${project}/ConfigData.h port/app/
    cp projects/${project}/.build-config .

    # 빌드
    ./build.sh > /tmp/build-${project}.log 2>&1

    # 결과 복사
    mkdir -p /original/dist/${project}
    cp out/App.uf2 /original/dist/${project}/W55RP20_${project}.uf2

    # 정리
    cd /
    rm -rf $TEMP_DIR

    echo "[${project}] Done!"
}

# 병렬 실행
for project in "${PROJECTS[@]}"; do
    build_project $project &
done

# 모든 작업 대기
wait

echo "All builds completed!"
```

**시간 비교**:
- 순차 빌드: 30초 × 3 = **90초**
- 병렬 빌드: **40초** (2배 빠름!)

---

### 4.8 배운 내용

완료한 작업:
- [x] 여러 설정 관리
- [x] 자동 빌드 스크립트
- [x] 병렬 빌드로 시간 단축
- [x] 릴리스 파일 정리

**핵심 포인트**:
- .build-config로 설정 분리
- bash 스크립트로 자동화
- 병렬 빌드로 효율 향상

---

## 예제 5: CI/CD - GitHub Actions

### 학습 목표
- 자동 빌드 파이프라인 구축
- GitHub Actions 활용
- 릴리스 자동화

### 난이도
⭐⭐⭐(전문가)

### 소요 시간
- 워크플로우 작성: 30분
- 테스트: 10분

---

### 5.1 시나리오

GitHub에 push 할 때마다:
1. 자동으로 빌드
2. 테스트 실행
3. 릴리스 파일 생성
4. 태그 시 GitHub Release 생성

---

### 5.2 워크플로우 파일

**.github/workflows/build.yml**:

```yaml
name: Build Firmware

on:
  push:
    branches: [ main, develop ]
    tags: [ 'v*' ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout
      uses: actions/checkout@v3
      with:
        submodules: recursive

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2

    - name: Build firmware
      run: |
        chmod +x build.sh
        ./build.sh

    - name: Check artifacts
      run: |
        ls -lh out/
        test -f out/App.uf2 || exit 1

    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: firmware
        path: |
          out/App.uf2
          out/App_linker.uf2
          out/Boot.uf2

    - name: Create Release
      if: startsWith(github.ref, 'refs/tags/')
      uses: softprops/action-gh-release@v1
      with:
        files: |
          out/App.uf2
          out/App_linker.uf2
          out/Boot.uf2
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

### 5.3 멀티 빌드 워크플로우

**.github/workflows/build-matrix.yml**:

```yaml
name: Build Matrix

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        config: [standard, highspeed, lowpower]

    steps:
    - name: Checkout
      uses: actions/checkout@v3
      with:
        submodules: recursive

    - name: Build ${{ matrix.config }}
      run: |
        cp projects/${{ matrix.config }}/ConfigData.h port/app/
        cp projects/${{ matrix.config }}/.build-config .
        ./build.sh

    - name: Upload ${{ matrix.config }}
      uses: actions/upload-artifact@v3
      with:
        name: firmware-${{ matrix.config }}
        path: out/App.uf2
```

---

### 5.4 테스트 추가

**.github/workflows/test.yml**:

```yaml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout
      uses: actions/checkout@v3
      with:
        submodules: recursive

    - name: Build
      run: ./build.sh

    - name: Unit Tests
      run: |
        # Docker 내부에서 테스트 실행
        sudo docker run --rm \
          -v $(pwd):/work \
          w55rp20:auto \
          bash -c "cd /work && make test"

    - name: Static Analysis
      run: |
        # cppcheck 실행
        find main -name "*.c" -o -name "*.h" | \
          xargs cppcheck --error-exitcode=1

    - name: Code Format Check
      run: |
        # clang-format 확인
        find main -name "*.c" -o -name "*.h" | \
          xargs clang-format --dry-run --Werror
```

---

### 5.5 캐시 최적화

**ccache 활용**:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout
      uses: actions/checkout@v3

    - name: Cache ccache
      uses: actions/cache@v3
      with:
        path: ~/.ccache
        key: ccache-${{ runner.os }}-${{ github.sha }}
        restore-keys: |
          ccache-${{ runner.os }}-

    - name: Cache Docker layers
      uses: actions/cache@v3
      with:
        path: /tmp/.buildx-cache
        key: buildx-${{ runner.os }}-${{ github.sha }}
        restore-keys: |
          buildx-${{ runner.os }}-

    - name: Build
      run: ./build.sh
```

**빌드 시간**:
- 캐시 없음: 2분 30초
- 캐시 있음: **30초** (5배 빠름!)

---

### 5.6 릴리스 자동화

**태그 생성 시 자동 릴리스**:

```bash
# 로컬에서 태그 생성
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin v1.2.0

# GitHub Actions가 자동으로:
# 1. 빌드
# 2. 테스트
# 3. GitHub Release 생성
# 4. uf2 파일 첨부
```

**릴리스 페이지**:
```
Release v1.2.0

Assets:
- App.uf2 (624 KB)
- App_linker.uf2 (624 KB)
- Boot.uf2 (120 KB)
- Source code (zip)
- Source code (tar.gz)
```

---

### 5.7 배포 모니터링

**Slack 알림**:

```yaml
- name: Notify Slack
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: 'Build ${{ job.status }}'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

**이메일 알림**:
- GitHub Settings → Notifications
- Email notifications 활성화

---

### 5.8 배운 내용

완료한 작업:
- [x] GitHub Actions 워크플로우
- [x] 자동 빌드 및 테스트
- [x] 멀티 빌드 매트릭스
- [x] 릴리스 자동화
- [x] 캐시 최적화

**핵심 포인트**:
- CI/CD로 빌드 자동화
- 매 커밋마다 테스트
- 릴리스 프로세스 간소화

---

## 추가 자료

### 관련 문서
- [README.md](../README.md): 빠른 시작
- [BUILD_LOGS.md](BUILD_LOGS.md): 빌드 로그 분석
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md): 문제 해결
- [ARCHITECTURE.md](ARCHITECTURE.md): 내부 구조

### 참고 링크
- W55RP20 Datasheet: https://docs.wiznet.io/
- Pico SDK: https://github.com/raspberrypi/pico-sdk
- GitHub Actions: https://docs.github.com/actions

### 다음 단계

예제를 완료했다면:
1. 실제 프로젝트에 적용
2. 커스터마이징
3. 커뮤니티 공유

---

**검토**: 사용자
**버전**: 1.0
**최종 수정**: 2026-01-21

**피드백**:
더 많은 예제가 필요하거나 질문이 있으면 GitHub Issues에 남겨주세요!
