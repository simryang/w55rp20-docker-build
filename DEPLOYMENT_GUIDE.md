# Windows 테스터 배포 가이드 (개발자용)

## 개요

이 문서는 **Linux 개발 환경에서 작성한 Windows 지원 기능**을 Windows 테스터에게 전달하는 방법을 설명합니다.

---

## 현재 상태

### ✅ 완료된 작업

```bash
# 커밋 확인
git log --oneline -10
```

**커밋 내역:**
1. `fd00c78` - Windows 테스트 가이드 추가
2. `5083dd3` - Windows 지원 문서 추가
3. `1c62e73` - 통합 진입점 (대화형 모드)
4. `26f6ba1` - Windows 컨테이너 래퍼
5. `d434a42` - Linux 컨테이너 Windows 래퍼
6. `0802bde` - Windows 컨테이너 지원

**총 추가 파일:**
- 5개 PowerShell 스크립트 (.ps1)
- 2개 Bash 스크립트 (.sh)
- 2개 Dockerfile (Linux + Windows)
- 7개 문서 (.md)
- 2개 테스트 가이드

---

## 배포 전략

### 전략 1: GitHub 공개 저장소 (권장)

**장점:**
- ✅ 가장 간단한 배포
- ✅ 테스터가 쉽게 접근 가능
- ✅ Issue/PR로 피드백 수집 용이
- ✅ 버전 관리 자동

**단점:**
- ❌ 공개 저장소 필요

---

### 전략 2: GitHub Private 저장소

**장점:**
- ✅ 비공개 유지
- ✅ 협업자 초대로 접근 제어
- ✅ GitHub 기능 모두 사용 가능

**단점:**
- ❌ Private 저장소 필요 (무료는 제한적)

---

### 전략 3: ZIP 파일 전달

**장점:**
- ✅ 저장소 불필요
- ✅ 이메일/클라우드로 간단 전달

**단점:**
- ❌ 버전 관리 어려움
- ❌ 업데이트 시 재전달 필요
- ❌ 피드백 수집 수동

---

## 실행: GitHub 공개 저장소 (권장)

### Step 1: 저장소 준비

#### Option A: 새 저장소 생성

```bash
# 1. GitHub에서 새 저장소 생성
# https://github.com/new
# Repository name: w55rp20-docker-build
# Public
# No README, .gitignore, license (이미 있음)

# 2. 원격 저장소 추가
git remote add origin https://github.com/YOUR_USERNAME/w55rp20-docker-build.git

# 3. Push
git push -u origin master
```

#### Option B: 기존 저장소에 브랜치

```bash
# 1. 새 브랜치 생성
git checkout -b windows-support

# 2. Push
git push -u origin windows-support
```

---

### Step 2: 저장소 확인

```bash
# GitHub에서 확인
# https://github.com/YOUR_USERNAME/w55rp20-docker-build

# 체크리스트:
# [ ] 모든 파일이 업로드되었는가?
# [ ] README.md가 보이는가?
# [ ] WINDOWS_TESTING_GUIDE.md가 있는가?
```

---

### Step 3: 테스터에게 전달

#### 방법 1: 저장소 링크 + 가이드 (권장)

**이메일/메시지 템플릿:**

```
제목: W55RP20 Windows 빌드 시스템 테스트 요청

안녕하세요,

W55RP20 펌웨어의 Windows 빌드 시스템을 개발했습니다.
Windows 환경에서 테스트를 부탁드립니다.

📦 저장소:
https://github.com/YOUR_USERNAME/w55rp20-docker-build

📖 테스트 가이드:
https://github.com/YOUR_USERNAME/w55rp20-docker-build/blob/master/WINDOWS_TESTING_GUIDE.md

✅ 빠른 체크리스트:
https://github.com/YOUR_USERNAME/w55rp20-docker-build/blob/master/TESTING_CHECKLIST.md

⏱️ 예상 시간: 2-3시간 (최초 이미지 빌드 포함)

🎯 핵심 테스트:
1. 대화형 모드 (.\build.ps1 -Interactive)
2. 자동 모드 (.\build.ps1)
3. 에러 처리 확인

💬 피드백:
- GitHub Issues: https://github.com/YOUR_USERNAME/w55rp20-docker-build/issues
- 또는 이메일: your-email@example.com

감사합니다!
```

---

#### 방법 2: 직접 초대 (Private 저장소)

```
GitHub 저장소 →
Settings →
Manage access →
Invite a collaborator →
테스터 GitHub 계정 입력
```

---

### Step 4: 테스터가 해야 할 일

테스터는 다음 문서를 순서대로 따라가면 됩니다:

```
1. WINDOWS_TESTING_GUIDE.md (상세 가이드)
   - 사전 준비
   - Git clone
   - Docker 확인
   - 10개 테스트 시나리오
   - 피드백 양식

2. TESTING_CHECKLIST.md (빠른 참조)
   - 핵심 테스트만 체크
```

---

## 실행: ZIP 파일 전달

### Step 1: ZIP 생성

```bash
cd /home/sr/src/docker/w55rp20

# 불필요한 파일 제외하고 압축
zip -r w55rp20-windows-$(date +%Y%m%d).zip \
  build.ps1 \
  build-windows.ps1 \
  build-windows.sh \
  build-native-windows.ps1 \
  build-unified.sh \
  build.sh \
  w55build.sh \
  Dockerfile \
  Dockerfile.windows \
  docker-build.sh \
  docker-build-windows.ps1 \
  entrypoint.sh \
  README.md \
  WINDOWS_TESTING_GUIDE.md \
  TESTING_CHECKLIST.md \
  docs/ \
  .gitignore \
  -x "*.log" "out/*" ".git/*" ".claude/*"

# 파일 확인
ls -lh w55rp20-windows-*.zip
```

---

### Step 2: 업로드

**옵션:**
- Google Drive
- Dropbox
- OneDrive
- 이메일 첨부 (크기 제한 주의)

---

### Step 3: 테스터에게 전달

```
제목: W55RP20 Windows 빌드 시스템 테스트 파일

안녕하세요,

첨부된 ZIP 파일을 다운로드하고 압축 해제 후,
WINDOWS_TESTING_GUIDE.md를 참고하여 테스트 부탁드립니다.

다운로드: [Google Drive 링크]

감사합니다!
```

---

## 피드백 수집 방법

### 방법 1: GitHub Issues (권장)

**테스터가 해야 할 일:**
```
1. 저장소 → Issues → New Issue
2. 제목: [Windows 테스트] 피드백
3. WINDOWS_TESTING_GUIDE.md의 피드백 양식 복사
4. 작성 후 Submit
```

**개발자가 해야 할 일:**
```
1. Issues 확인
2. 라벨 추가 (bug, enhancement, documentation 등)
3. 답변 및 수정
```

---

### 방법 2: 이메일

**테스터:**
- WINDOWS_TESTING_GUIDE.md의 피드백 양식을 .txt로 저장
- 이메일 첨부

**개발자:**
- 피드백 정리
- 수동으로 Issue 등록 (추적용)

---

### 방법 3: Google Forms (대규모)

```
1. Google Forms 생성
2. WINDOWS_TESTING_GUIDE.md의 피드백 항목을 질문으로 변환
3. 링크를 테스터에게 전달
4. 응답을 스프레드시트로 수집
```

---

## 테스터 관리

### 테스터 목록 (예시)

```markdown
| 이름 | OS | Docker 경험 | 상태 | 피드백 |
|-----|-------|----------|------|--------|
| 홍길동 | Win 11 Pro | 있음 | 진행 중 | - |
| 김철수 | Win 10 Home | 없음 | 대기 | - |
| 이영희 | Win 11 Home | 있음 | 완료 | Issue #1 |
```

---

### 진행 상황 추적

```markdown
# 테스트 진행 현황

## 완료 (3/5)
- [x] 홍길동 - 모든 테스트 통과
- [x] 이영희 - 테스트 1-3 통과, 테스트 4 스킵
- [x] 박민수 - Git Bash 에러 발견 (Issue #2)

## 진행 중 (1/5)
- [ ] 김철수 - Docker 설치 중

## 대기 (1/5)
- [ ] 최정희 - 아직 시작 안함
```

---

## 긴급 수정 시나리오

### 상황: 치명적 버그 발견

**예:** PowerShell 스크립트 문법 오류

**대응:**

```bash
# 1. 수정
vim build.ps1

# 2. 커밋
git add build.ps1
git commit -m "Fix: PowerShell syntax error in build.ps1

Issue: #XX
Reported by: @tester-name"

# 3. Push
git push origin master

# 4. 테스터에게 알림
# GitHub: Issue에 코멘트
# 이메일: "긴급 업데이트: git pull origin master 실행 후 재테스트 부탁드립니다"
```

---

## 체크리스트 (개발자)

### 배포 전

```
[ ] 모든 커밋 완료
[ ] git log로 커밋 내역 확인
[ ] 로컬에서 마지막 테스트
[ ] README.md 업데이트 (Windows 섹션)
[ ] WINDOWS_TESTING_GUIDE.md 최종 검토
[ ] .gitignore 확인 (민감 정보 제외)
```

---

### 배포 후

```
[ ] GitHub 저장소 접근 가능 확인
[ ] README.md가 정상 렌더링되는지 확인
[ ] 테스터에게 메시지 전달
[ ] 피드백 수집 채널 확인 (Issues 활성화 등)
```

---

### 피드백 수집 중

```
[ ] 매일 Issues 확인
[ ] 48시간 이내 응답
[ ] 재현 가능한 버그는 즉시 수정
[ ] 문서 오류는 즉시 수정
[ ] 개선 제안은 backlog에 추가
```

---

## 예상 피드백 및 대응

### 예상 1: "Docker Desktop 설치가 너무 어렵다"

**대응:**
- WINDOWS_TESTING_GUIDE.md의 사전 준비 섹션 강화
- 스크린샷 추가
- 비디오 가이드 제작 고려

---

### 예상 2: "빌드가 너무 오래 걸린다"

**대응:**
- 정상입니다 (최초 이미지 빌드 20분)
- 문서에 명시되어 있음
- "이후 빌드는 빠릅니다" 강조

---

### 예상 3: "Windows 컨테이너가 안된다"

**대응:**
- Dockerfile.windows 버그 가능성 높음
- Windows 환경에서 직접 테스트 필요
- 긴급 수정 또는 "experimental" 라벨 추가

---

### 예상 4: "Git Bash에서 경로 오류"

**대응:**
- MSYS_NO_PATHCONV=1 자동 설정 확인
- build-windows.sh 디버깅
- Git Bash 버전 확인

---

## 요약

### 최소 배포 (30분)

```bash
# 1. GitHub에 Push
git push origin master

# 2. 테스터에게 링크 전달
# 저장소: https://github.com/YOUR_USERNAME/w55rp20-docker-build
# 가이드: WINDOWS_TESTING_GUIDE.md

# 끝!
```

---

### 권장 배포 (1시간)

```bash
# 1. 최종 검토
cat WINDOWS_TESTING_GUIDE.md
cat TESTING_CHECKLIST.md

# 2. README.md 업데이트
vim README.md
# Windows 섹션 추가:
# - 빠른 시작
# - build.ps1 -Interactive
# - 문서 링크

# 3. 커밋 및 Push
git add README.md
git commit -m "docs: Add Windows quick start section"
git push origin master

# 4. 테스터 목록 정리
# - 이름, 연락처, OS 정보

# 5. 맞춤형 메시지 작성 및 전달

# 6. 피드백 수집 준비
# - Issues 활성화
# - Notification 설정
```

---

**문서 작성:** 2026-01-28
**대상:** Linux 개발자 → Windows 테스터 배포
