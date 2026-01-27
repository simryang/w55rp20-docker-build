# Raspberry Pi 설치 가이드

> W55RP20-S2E 빌드 시스템 Raspberry Pi 설치

작성일: 2026-01-21
버전: 1.0

---

## 지원 모델

### 완전 지원
- **Raspberry Pi 5** (8GB)
- **Raspberry Pi 4** (4GB/8GB)

### 테스트됨 ️
- **Raspberry Pi 4** (2GB) - swap 필수
- **Raspberry Pi 3 B+** - 느리지만 가능

### 권장하지 않음 
- Raspberry Pi Zero/1/2 - 메모리 부족

---

## 목차

1. [빠른 설치](#빠른-설치)
2. [메모리 최적화](#메모리-최적화)
3. [Swap 설정](#swap-설정)
4. [성능 튜닝](#성능-튜닝)
5. [문제 해결](#문제-해결)

---

## 빠른 설치

### Raspberry Pi OS (64-bit)

```bash
# 1. 시스템 업데이트
sudo apt update
sudo apt full-upgrade -y

# 2. Docker 설치
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 3. 사용자 그룹 추가
sudo usermod -aG docker $USER

# 4. 재로그인
logout

# (재로그인 후)
# 5. Docker 확인
docker --version

# 6. Swap 증가 (2GB RAM 이하)
sudo dphys-swapfile swapoff
sudo sed -i 's/CONF_SWAPSIZE=100/CONF_SWAPSIZE=2048/' /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon

# 7. 프로젝트 클론
git clone https://github.com/WIZnet-ioNIC/W55RP20-S2E.git
cd W55RP20-S2E

# 8. 빌드 (저사양 설정)
JOBS=2 TMPFS_SIZE=0 ./build.sh

# 완료! (시간이 오래 걸릴 수 있음)
```

---

## 시스템 요구사항

| 모델 | RAM | 빌드 시간 | 권장 Swap |
|------|-----|-----------|-----------|
| Pi 5 (8GB) | 8GB | **3분** | 0 GB |
| Pi 4 (8GB) | 8GB | 5분 | 0 GB |
| Pi 4 (4GB) | 4GB | 8분 | 2 GB |
| Pi 4 (2GB) | 2GB | 15분 | 4 GB ️ |
| Pi 3 B+ | 1GB | 30분+ | 불가능  |

---

## 메모리 최적화

### 2.1 현재 메모리 확인

```bash
# 총 메모리
free -h
#               total        used        free
# Mem:          3.7Gi       1.2Gi       2.0Gi

# Swap
#               total        used        free
# Swap:         2.0Gi       0.0Ki       2.0Gi
```

---

### 2.2 불필요한 서비스 중지

```bash
# GUI 중지 (SSH 사용 시)
sudo systemctl set-default multi-user.target

# 불필요한 서비스
sudo systemctl disable bluetooth
sudo systemctl disable avahi-daemon

# 재부팅
sudo reboot
```

---

### 2.3 메모리 확보

**빌드 전**:
```bash
# 캐시 정리
sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches

# 메모리 확인
free -h
```

---

## Swap 설정

### 3.1 기본 Swap 증가

```bash
# 현재 Swap 확인
free -h | grep Swap
# Swap:   100M

# Swap 비활성화
sudo dphys-swapfile swapoff

# 설정 변경
sudo nano /etc/dphys-swapfile
# CONF_SWAPSIZE=100 → CONF_SWAPSIZE=2048

# Swap 재생성
sudo dphys-swapfile setup
sudo dphys-swapfile swapon

# 확인
free -h | grep Swap
# Swap:   2.0G
```

---

### 3.2 수동 Swap 파일 (고급)

```bash
# 4GB Swap 파일 생성
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 영구 적용
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 확인
swapon --show
# /swapfile  file  4G
```

---

### 3.3 Swap 우선순위

```bash
# Swap 사용을 최소화 (성능)
sudo sysctl vm.swappiness=10

# 영구 적용
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
```

---

## 성능 튜닝

### 4.1 빌드 설정

**build.config** 생성:

```bash
cat > build.config <<EOF
# Raspberry Pi 4 (4GB) 최적 설정
JOBS=2                    # CPU 코어 수의 50%
TMPFS_SIZE=0              # tmpfs 비활성화 (메모리 절약)
AUTO_BUILD_IMAGE=1
UPDATE_REPO=0
EOF
```

**모델별 권장 설정**:

| 모델 | JOBS | TMPFS_SIZE | Swap |
|------|------|------------|------|
| Pi 5 (8GB) | 4 | 4g | 0 |
| Pi 4 (8GB) | 4 | 2g | 0 |
| Pi 4 (4GB) | 2 | 0 | 2GB |
| Pi 4 (2GB) | 1 | 0 | 4GB |

---

### 4.2 오버클러킹 (Pi 4)

**/boot/config.txt**:

```ini
# CPU 오버클럭 (주의: 발열 증가)
over_voltage=6
arm_freq=2000

# GPU 메모리 최소화 (헤드리스)
gpu_mem=16
```

**재부팅 후**:
```bash
vcgencmd measure_clock arm
# frequency(48)=2000000000  ← 2.0GHz
```

---

### 4.3 냉각

**필수**:
- 방열판 또는 팬 장착
- 오버클러킹 시 필수

**온도 모니터링**:
```bash
# 빌드 중 온도 확인
watch -n 1 'vcgencmd measure_temp'
# temp=65.0'C  ← 80도 이하 유지
```

---

## SD 카드 최적화

### 5.1 빠른 SD 카드 사용

**권장**:
- Class 10 이상
- A1/A2 (Application Performance Class)
- UHS-I 이상

**테스트**:
```bash
# 쓰기 속도 테스트
dd if=/dev/zero of=~/test.img bs=1M count=1024
# 1024 MB copied, 10 s, 102 MB/s

# 읽기 속도 테스트
dd if=~/test.img of=/dev/null bs=1M
# 1024 MB copied, 8 s, 128 MB/s
```

---

### 5.2 USB SSD 부팅 (권장)

Pi 4/5는 USB SSD 부팅 지원:

**장점**:
- 10배 빠른 I/O
- 빌드 시간 50% 단축

**설정**:
1. Raspberry Pi Imager 사용
2. USB SSD에 OS 설치
3. EEPROM 업데이트로 USB 부팅 활성화

---

## Docker 최적화

### 6.1 Docker 스토리지 드라이버

```bash
# 현재 드라이버 확인
docker info | grep "Storage Driver"
# Storage Driver: overlay2

# overlay2 권장 (기본값)
```

---

### 6.2 Docker 로그 크기 제한

**/etc/docker/daemon.json**:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

적용:
```bash
sudo systemctl restart docker
```

---

## 문제 해결

### 빌드 중 멈춤

**증상**: 빌드가 중간에 멈춤

**원인**: 메모리 부족

**해결**:
```bash
# Swap 확인
free -h

# Swap 증가
sudo dphys-swapfile swapoff
sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=4096/' /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon

# JOBS 줄이기
JOBS=1 ./build.sh
```

---

### "Killed" 에러

**증상**:
```
c++: fatal error: Killed signal terminated program cc1plus
```

**원인**: OOM (Out Of Memory)

**해결**:
1. Swap 증가 (위 참조)
2. TMPFS_SIZE=0 설정
3. JOBS=1 설정

---

### SD 카드 쓰기 에러

**증상**:
```
I/O error, dev mmcblk0
```

**원인**: SD 카드 손상 또는 불량

**해결**:
1. SD 카드 교체
2. USB SSD 사용 (권장)

---

## 원격 빌드

### 7.1 SSH 사용

**로컬 PC**:
```bash
# SSH 연결
ssh pi@192.168.0.100

# 빌드 (터미널 종료해도 계속됨)
cd W55RP20-S2E
nohup ./build.sh > build.log 2>&1 &

# 종료
exit

# 나중에 확인
ssh pi@192.168.0.100
tail -f ~/W55RP20-S2E/build.log
```

---

### 7.2 VS Code Remote SSH

**VS Code 확장 설치**:
- Remote - SSH

**연결**:
1. Ctrl+Shift+P → "Remote-SSH: Connect to Host"
2. `pi@192.168.0.100`
3. 비밀번호 입력
4. 프로젝트 열기

---

## 성능 비교

### 빌드 시간 (첫 빌드)

| 환경 | JOBS | tmpfs | Swap | 시간 |
|------|------|-------|------|------|
| **데스크톱** (Ryzen 7) | 16 | 24GB | 0 | 2:30 |
| **Pi 5** (8GB) | 4 | 4GB | 0 | **3:00** |
| **Pi 4** (8GB) | 4 | 2GB | 0 | 5:00 |
| **Pi 4** (4GB) | 2 | 0 | 2GB | 8:00 |
| **Pi 4** (2GB) | 1 | 0 | 4GB | 15:00 |
| **Pi 4 + SSD** (4GB) | 2 | 0 | 2GB | **4:00** ← 50% 빨라짐 |

---

## 활용 사례

### 전용 빌드 서버

**장점**:
- 24시간 가동
- 저전력 (~15W)
- 조용함

**설정**:
```bash
# 자동 빌드 스크립트
crontab -e

# 매일 새벽 3시 빌드
0 3 * * * cd ~/W55RP20-S2E && git pull && ./build.sh
```

---

### 팀 공유 빌더

**설정**:
1. Samba로 네트워크 공유
2. 팀원이 소스 업로드
3. 자동으로 빌드
4. 결과를 공유 폴더에

---

## 다음 단계

1. Docker 설치 완료
2. 메모리 최적화
3. → [README.md](../README.md) - 빌드 시작
4. → [BEGINNER_GUIDE.md](BEGINNER_GUIDE.md) - 상세 가이드

---

**검토**: 사용자
**버전**: 1.0
**최종 수정**: 2026-01-21

**참고**: Raspberry Pi에서의 빌드는 시간이 오래 걸릴 수 있지만, 저전력 전용 빌드 서버로 활용 가능합니다!
