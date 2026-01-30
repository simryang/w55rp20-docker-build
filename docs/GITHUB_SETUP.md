# GitHub 저장소 생성 및 Push

## 1단계: 웹 브라우저에서 저장소 생성

### 방법 1: 빠른 링크 (권장)
브라우저에서 다음 URL 접속:
```
https://github.com/new
```

### 방법 2: GitHub 홈페이지
```
1. https://github.com 접속
2. 로그인
3. 우측 상단 "+" 클릭 → "New repository"
```

---

## 2단계: 저장소 설정

다음과 같이 입력:

```
Repository name: w55rp20-docker-build

Description:
W55RP20 firmware build system with Docker (All-in-One: Linux + Windows containers)

Public ✅ (선택)

❌ Add a README file (체크 해제)
❌ Add .gitignore (체크 해제)
❌ Choose a license (체크 해제)
```

**중요**: README, .gitignore, license는 **체크하지 마세요!** (이미 있습니다)

---

## 3단계: Create repository 클릭

"Create repository" 버튼 클릭

---

## 4단계: 터미널로 돌아와서 Push

저장소 생성 완료 후, 다음 명령 실행:

```bash
cd /home/sr/src/docker/w55rp20
git push -u origin master
```

**예상 출력:**
```
Enumerating objects: 123, done.
Counting objects: 100% (123/123), done.
Delta compression using up to 16 threads
Compressing objects: 100% (89/89), done.
Writing objects: 100% (123/123), 456.78 KiB | 12.34 MiB/s, done.
Total 123 (delta 45), reused 0 (delta 0)
remote: Resolving deltas: 100% (45/45), done.
To github.com:simryang/w55rp20-docker-build.git
 * [new branch]      master -> master
Branch 'master' set up to track remote branch 'master' from 'origin'.
```

---

## 5단계: 확인

Push 완료 후 브라우저에서 확인:
```
https://github.com/simryang/w55rp20-docker-build
```

**확인 사항:**
- ✅ README.md가 정상 표시
- ✅ "Windows 빠른 시작" 섹션 보임
- ✅ 모든 파일 업로드됨
- ✅ 커밋 내역 9개 확인

---

## 완료!

이제 테스터에게 전달할 수 있습니다:

**저장소 URL:**
https://github.com/simryang/w55rp20-docker-build

**DockerHub 이미지:**
https://hub.docker.com/r/simryang/w55rp20

**테스터 초대 메시지:**
`TESTER_INVITATION.md` 파일 참고
