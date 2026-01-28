# 대화형 모드 시연

## 개요

**욕심쟁이의 완벽한 UX!** 🎉

`.\build.ps1 -Interactive` 실행 시 **실제로 보게 되는 화면**입니다.

---

## 실행: `.\build.ps1 -Interactive`

### 1. 초기 화면

```
╔══════════════════════════════════════════════════════════════╗
║  W55RP20 통합 빌드 시스템 v1.2.0-unified                    ║
║  Linux 컨테이너 + Windows 컨테이너 All-in-One              ║
╚══════════════════════════════════════════════════════════════╝

[INFO] Docker Desktop 상태 확인 중...
[SUCCESS] Docker Desktop 실행 중 (현재 모드: linux containers)
```

---

### 2. 대화형 선택 메뉴

```
═══════════════════════════════════════════════════════════════
  컨테이너 타입을 선택하세요
═══════════════════════════════════════════════════════════════

  [1] Linux 컨테이너 (크로스 플랫폼)

      장점:
        ✅ Linux/macOS/Windows 모두 사용 가능
        ✅ 팀 개발 최적 (환경 통일)
        ✅ CI/CD 완벽 호환 (GitHub Actions 등)
        ✅ 표준적 (전 세계 Docker의 99%)

      단점:
        ⚠️  WSL2 필요 (Docker Desktop이 자동 설치)
        ⚠️  약간의 성능 오버헤드 (6%, 실용적 수준)

      시간/용량:
        ⏱️  최초 빌드: 약 20분 (이미지 생성)
        ⏱️  이후 빌드: 약 50초 → 12초 (ccache)
        💾 이미지 크기: 2GB
        💾 디스크 여유: 5GB 권장

  [2] Windows 컨테이너 (네이티브)

      장점:
        ✅ WSL2 불필요!
        ✅ Windows 네이티브 성능 (오버헤드 0%)
        ✅ .exe 직접 실행
        ✅ Hyper-V 격리 (보안)

      단점:
        ⚠️  Windows 전용 (Linux/macOS 불가)
        ⚠️  CI/CD 제한적 (Windows runner 비용)
        ⚠️  Docker 모드 전환 필요

      시간/용량:
        ⏱️  최초 빌드: 약 30-40분 (대용량 다운로드)
        ⏱️  이후 빌드: 약 47초 → 11초 (ccache)
        💾 이미지 크기: 2.5GB
        💾 디스크 여유: 6GB 권장

  [3] 자동 선택 (현재 Docker 모드: linux)

      현재 Docker 모드를 자동으로 사용합니다.

═══════════════════════════════════════════════════════════════

💡 추천: [1] Linux 컨테이너 (현재 모드와 일치)

선택하세요 [1-3] (기본값: 3): _
```

---

### 3. 사용자 선택: `1` 입력

```
선택하세요 [1-3] (기본값: 3): 1
[INFO] Linux 컨테이너를 선택했습니다

[INFO] 빌드 준비 중...

[SUCCESS] Linux 컨테이너 빌드 시작 (WSL2 기반)

특징:
  ✅ 크로스 플랫폼 (Linux/macOS/Windows)
  ✅ CI/CD 완벽 호환
  ✅ 표준 Docker 경험

[INFO] Docker 이미지 확인 중...
```

---

### 4-A. 최초 실행 (이미지 없음)

```
[INFO] 이미지(w55rp20:auto) 없음
[INFO] 이미지 빌드 실행 (PLATFORM=linux/amd64)

===== Docker build command =====
docker buildx build --platform linux/amd64 -t w55rp20:auto --load --progress=plain -f Dockerfile .
=================================

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 3.21kB done
#1 DONE 0.0s

#2 [internal] load .dockerignore
#2 transferring context: 2B done
#2 DONE 0.0s

... (약 20분 진행) ...

#15 exporting to image
#15 exporting layers done
#15 writing image sha256:abc123... done
#15 naming to docker.io/library/w55rp20:auto done
#15 DONE 2.1s

[SUCCESS] 이미지 빌드 완료
```

---

### 4-B. 이미지 있는 경우

```
[SUCCESS] 이미지 존재: w55rp20:auto
```

---

### 5. 빌드 진행

```
[INFO] 소스 없음 -> 클론: /home/user/W55RP20-S2E
Cloning into '/home/user/W55RP20-S2E'...
remote: Enumerating objects: 1234, done.
remote: Counting objects: 100% (1234/1234), done.
remote: Compressing objects: 100% (789/789), done.
remote: Total 1234 (delta 445), reused 1234 (delta 445)
Receiving objects: 100% (1234/1234), 2.34 MiB | 5.67 MiB/s, done.
Resolving deltas: 100% (445/445), done.
Submodule 'pico-sdk' (https://github.com/raspberrypi/pico-sdk.git) registered for path 'pico-sdk'
...

[INFO] ===== SETTINGS =====
[INFO] IMAGE=w55rp20:auto
[INFO] PLATFORM=linux/amd64
[INFO] SRC_DIR=/home/user/W55RP20-S2E
[INFO] OUT_DIR=/path/to/out
[INFO] JOBS=16
[INFO] BUILD_TYPE=Release
[INFO] ====================

[INFO] 빌드 로그를 build.log 에 저장합니다.

[INTERNAL] PATH=/opt/toolchain/bin:/usr/local/bin:...
[INTERNAL] python=/usr/bin/python
[INTERNAL] python3=/usr/bin/python3
[INTERNAL] ccache found -> enabled

-- The C compiler identification is GNU 14.2.0
-- The CXX compiler identification is GNU 14.2.0
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Check for working C compiler: /opt/toolchain/bin/arm-none-eabi-gcc - skipped
-- Detecting C compile features
-- Detecting C compile features - done
...

-- Build files have been written to: /work/src/build

[1/127] Building C object CMakeFiles/App.dir/src/main.c.obj
[2/127] Building C object CMakeFiles/App.dir/src/config.c.obj
...
[127/127] Linking CXX executable App.elf

=== TMPFS DF ===
Filesystem      Size  Used Avail Use% Mounted on
tmpfs            20G  3.2G   17G  16% /work/src/build

=== TMPFS DU ===
3.2G    /work/src/build

[INTERNAL] TMPFS_PEAK_BYTES=3421234567
TMPFS_PEAK_GiB=3.19

[INTERNAL] === OUTPUTS ===
total 1832
-rw-r--r-- 1 root root  628K Jan 28 12:34 App.uf2
-rw-r--r-- 1 root root  120K Jan 28 12:34 Boot.uf2
-rw-r--r-- 1 root root  628K Jan 28 12:34 App_linker.uf2
-rw-r--r-- 1 root root   44K Jan 28 12:34 SPI_Mode_Master.uf2

[INTERNAL] === CCACHE STATS ===
cache directory                     /work/.ccache
primary config                      /work/.ccache/ccache.conf
secondary config      (readonly)    /etc/ccache.conf
stats updated                       Tue Jan 28 12:34:56 2026
cache hit (direct)                    1234
cache hit (preprocessed)               567
cache miss                             89
cache hit rate                        95.3 %
...

[INFO] 빌드 완료. 산출물: /path/to/out
```

---

### 6. 빌드 완료 메시지 🎉

```
╔══════════════════════════════════════════════════════════════╗
║                  🎉 빌드 완료! 🎉                           ║
╚══════════════════════════════════════════════════════════════╝

📦 산출물 위치:
   C:\Users\myname\projects\w55rp20\out

📌 W55RP20에 펌웨어 업로드하는 방법:

   1. W55RP20 보드의 BOOTSEL 버튼을 누른 채로 USB 연결
   2. Windows가 'RPI-RP2' 드라이브로 인식
   3. C:\Users\myname\projects\w55rp20\out\*.uf2 파일을 드라이브에 복사
   4. 자동으로 재부팅 및 펌웨어 업로드 완료!

🚀 다음 빌드 방법:

   공식 프로젝트 재빌드:
     .\build.ps1 -Linux

   사용자 프로젝트 빌드:
     .\build.ps1 -Linux -Project "C:\Users\yourname\your-w55rp20-project"

   디버그 빌드:
     .\build.ps1 -Linux -BuildType Debug

   정리 후 빌드:
     .\build.ps1 -Linux -Clean

💡 팁: 이후 빌드는 훨씬 빠릅니다! (이미지 재사용)

📖 더 많은 정보:
   .\build.ps1 -Help
   docs\WINDOWS_ALL_IN_ONE.md
```

---

## 다양한 시나리오

### 시나리오 1: Enter만 누름 (기본값)

```
선택하세요 [1-3] (기본값: 3): ⏎
[INFO] 자동 선택합니다 (현재 모드: linux)
```

→ 현재 Docker 모드로 자동 빌드

---

### 시나리오 2: Windows 컨테이너 선택 (모드 불일치)

```
선택하세요 [1-3] (기본값: 3): 2
[INFO] Windows 컨테이너를 선택했습니다

[WARN] Docker 모드 불일치!

  요청: windows 컨테이너
  현재: linux 컨테이너

해결 방법 (Windows containers로 전환):
  1. 시스템 트레이의 Docker 아이콘 우클릭
  2. 'Switch to Windows containers...' 선택
  3. 전환 완료 후 이 스크립트 재실행

또는:
  현재 모드(linux)로 빌드하려면: .\build.ps1 -Linux

종료하시겠습니까? [Y/n]: _
```

**친절한 안내!**

---

### 시나리오 3: 사용자 프로젝트 빌드

```powershell
.\build.ps1 -Interactive -Project "C:\Users\myname\my-w55rp20-project"
```

→ 대화형 선택 + 사용자 프로젝트 지정

---

## 비대화형 모드 비교

### 기존 (자동)

```powershell
.\build.ps1
```

**출력:**
```
[INFO] Docker Desktop 상태 확인 중...
[SUCCESS] Docker Desktop 실행 중 (현재 모드: linux containers)
[INFO] 자동 선택: linux 컨테이너 (Docker 현재 모드)
[INFO] 빌드 준비 중...
...
```

→ 바로 빌드 시작 (선택 없음)

---

### 명시적 선택

```powershell
.\build.ps1 -Linux
```

**출력:**
```
[INFO] Docker Desktop 상태 확인 중...
[SUCCESS] Docker Desktop 실행 중 (현재 모드: linux containers)
[INFO] 사용자 선택: Linux 컨테이너
[INFO] 빌드 준비 중...
...
```

→ 바로 빌드 시작 (사용자 선택 존중)

---

## 핵심 가치

### 1. 정보 제공
- ✅ **장단점 명시**: 사용자가 스스로 판단
- ✅ **시간/용량 명시**: 예상 가능
- ✅ **추천 표시**: 현재 모드와 일치하는 옵션

### 2. 유연성
- ✅ **대화형 모드**: 초보자용
- ✅ **자동 모드**: 빠른 빌드
- ✅ **명시적 선택**: 전문가용

### 3. 친절한 안내
- ✅ **완료 메시지**: 다음 할 일
- ✅ **에러 처리**: 해결 방법 제시
- ✅ **팁 제공**: 더 나은 사용법

---

## 요약

### 초보자
```powershell
.\build.ps1 -Interactive
```
→ 모든 것을 친절하게 안내받으며 선택

### 일반 사용자
```powershell
.\build.ps1
```
→ 자동으로 최적의 방법 선택

### 전문가
```powershell
.\build.ps1 -Linux -Project "..." -BuildType Debug -Verbose
```
→ 모든 것을 직접 제어

**모두를 위한 완벽한 UX!** 🎉

---

**문서 작성:** 2026-01-28
**대상:** 모든 사용자 레벨
