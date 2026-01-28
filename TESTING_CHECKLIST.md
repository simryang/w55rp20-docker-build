# Windows 테스트 체크리스트 (빠른 참조)

## 사전 준비 ✅

```
[ ] Windows 10/11 64-bit
[ ] 8GB+ RAM (16GB 권장)
[ ] 20GB 여유 디스크
[ ] Git for Windows 설치됨
[ ] Docker Desktop 설치 및 실행 중
```

---

## 핵심 테스트 (필수) ⭐

### 1️⃣ 대화형 모드 (Linux 컨테이너)

```powershell
.\build.ps1 -Interactive
# [1] 선택
```

**체크:**
```
[ ] 메뉴 정상 표시
[ ] 시간/용량 정보 명확
[ ] 빌드 성공
[ ] .\out\*.uf2 파일 생성
[ ] 완료 메시지 유용함
```

**빌드 시간:** __________ (최초)

---

### 2️⃣ 자동 모드

```powershell
.\build.ps1
```

**체크:**
```
[ ] 자동 감지 정상
[ ] 빌드 성공
```

**빌드 시간:** __________ (재사용)

---

### 3️⃣ 모드 불일치 처리

```powershell
# Docker Linux 모드 상태에서
.\build.ps1 -Windows
```

**체크:**
```
[ ] 모드 불일치 감지
[ ] 명확한 에러 메시지
[ ] 해결 방법 제시
```

---

## 추가 테스트 (선택) 🔧

### 4️⃣ Windows 컨테이너

```powershell
# 1. Docker 모드 전환 (시스템 트레이)
# 2. 빌드
.\build.ps1 -Windows
```

**체크:**
```
[ ] 모드 전환 성공
[ ] 이미지 빌드 성공 (30-40분)
[ ] 펌웨어 빌드 성공
```

**⚠️ 에러 발생 시 전체 로그 복사 필요!**

---

### 5️⃣ Git Bash

```bash
# Git Bash에서
./build-windows.sh
```

**체크:**
```
[ ] MSYS_NO_PATHCONV=1 자동 설정
[ ] 빌드 성공
```

---

### 6️⃣ 사용자 프로젝트

```powershell
.\build.ps1 -Linux -Project "$HOME\W55RP20-S2E-test"
```

**체크:**
```
[ ] 외부 프로젝트 빌드 성공
```

---

## 문서 검증 📖

```
[ ] WINDOWS_ALL_IN_ONE.md - 정확성
[ ] WINDOWS_CONTAINER_COMPARISON.md - 비교표
[ ] INTERACTIVE_MODE_DEMO.md - 실제 화면 일치
```

---

## 피드백 양식 (간단 버전)

```
테스트 환경:
- Windows: __________
- Docker Desktop: __________

핵심 테스트:
  1. 대화형 모드: ✅ / ❌
  2. 자동 모드: ✅ / ❌
  3. 모드 불일치: ✅ / ❌

발견한 문제:
1.
2.
3.

전체 평가 (1-5점): _____

추가 의견:


```

---

## 제출 방법

GitHub Issue 또는 이메일로 제출

**감사합니다!** 🙏
