# 설계 논의 이력

이 문서는 주요 설계 결정 과정과 고민을 시간순으로 기록합니다.

---

## 2026-01-16 15:40 KST - 사용자 프로젝트 빌드 지원 및 멀티플랫폼 전략

### 배경

빌드 검증 완료 후, 다음 단계로 "사용자가 수정한 소스를 빌드하는 방법"에 대한 논의 시작.

### 현재 상태

**동작하는 것:**
- 자동 빌드: `./build.sh` → W55RP20-S2E 자동 클론 → 빌드
- 수동 지정: `SRC_DIR=~/my-project ./build.sh`

**문제점:**
- 기본 소스 위치: `~/W55RP20-S2E` (프로젝트 외부)
- 산출물 위치: `./out/` (프로젝트 내부)
- 불일치로 인한 혼란
- 사용자 워크플로우가 명확하지 않음

### 사용자 요구사항

#### 1. Linux
1.1. Docker 옵션으로 프로젝트 디렉토리 지정
   - 사용자 프로젝트를 W55RP20-S2E와 동일한 환경으로 빌드

1.2. 처음부터 시작하는 사용자
   - 원하는 경로 입력받기
   - 해당 경로에 W55RP20-S2E 클론
   - Docker와 자동 연결

#### 2. Mac
2.1. Linux와 동일한 경험 제공

#### 3. Windows 11
3.1. VSCode/AI IDE가 쉽게 접근할 수 있는 환경
3.2. 가능하면 VSCode/AI IDE 확장 형태로 제공

### 설계 방향

#### Phase 1: Linux/Mac 개선 (즉시 구현 가능)

**옵션 검토:**

**옵션 A: SRC_DIR을 프로젝트 내부로**
```bash
SRC_DIR="${SRC_DIR:-$PWD/src}"  # 변경
OUT_DIR="${OUT_DIR:-$PWD/out}"  # 현재
```
- 장점: 일관성, 직관성, 단순성
- 단점: git 저장소 안에 또 다른 git 저장소

**옵션 B: 문서화만 강화**
- 장점: 코드 변경 없음
- 단점: 근본 해결 안 됨

**옵션 C: 자동 감지**
```bash
if [ -d "./src/.git" ]; then
  SRC_DIR="$PWD/src"
else
  SRC_DIR="$HOME/W55RP20-S2E"
fi
```
- 장점: 자동화
- 단점: "마법 같은" 동작, 명시적이지 않음

**옵션 D: 완전 분리**
- 빌드 시스템과 프로젝트를 별도 디렉토리로
- 장점: 재사용성
- 단점: 복잡도 증가

**제안된 개선사항:**

1. **대화형 모드**
   ```bash
   ./build.sh
   # → 질문: 자동 클론? 기존 프로젝트?
   # → 경로 입력
   ```

2. **위치 인자 지원**
   ```bash
   ./build.sh /path/to/project
   ```

3. **설정 기억 (.build-config)**
   ```bash
   # 첫 빌드 시 자동 생성
   SRC_DIR=/path/to/project
   OUT_DIR=./out
   ```

#### Phase 2: Windows + IDE 통합

**즉시 가능:**

1. **VSCode Dev Container**
   ```
   .devcontainer/
   ├── devcontainer.json
   └── Dockerfile

   .vscode/
   ├── tasks.json        # Build, Flash
   ├── launch.json       # Debug
   └── extensions.json   # Recommended
   ```

2. **Windows 지원**
   - WSL2 + Docker Desktop (권장)
   - PowerShell 래퍼 (build.ps1)

**장기 목표:**

3. **VSCode Extension**
   - 명령: W55RP20: Build, Flash, Debug
   - 프로젝트 초기화 자동화
   - Marketplace 배포

#### Phase 3: AI IDE 통합

1. **Context Files**
   - `.cursorrules`
   - `.windsurfrules`
   - 프로젝트 컨텍스트, 빌드 명령, 아키텍처 정보

2. **MCP Server** (Model Context Protocol)
   - 빌드, 산출물 조회, 플래시 툴 제공
   - AI가 직접 빌드 시스템 제어

### 구현 우선순위

#### ✅ 즉시 구현 (Week 1-2)
1. build.sh 개선
   - 위치 인자 지원
   - .build-config 생성/로드
   - 대화형 모드 (선택적)
2. 문서 업데이트
3. VSCode 템플릿

#### 🔄 단기 목표 (Week 3-4)
4. Windows 지원 (build.ps1, WSL2 가이드)
5. Mac 테스트

#### 🎯 중기 목표 (Month 2-3)
6. Dev Container 완성
7. 프로젝트 템플릿 및 init 스크립트

#### 🚀 장기 목표 (Month 4+)
8. VSCode Extension
9. AI IDE 통합 (MCP Server)

### 지원할 워크플로우

**워크플로우 1: 빠른 테스트**
```bash
./build.sh
# → 자동 클론 → 빌드 → out/
```

**워크플로우 2: 로컬 개발** (새로 추가)
```bash
# 첫 빌드
./build.sh ~/my-project

# 소스 수정
cd ~/my-project
vim main.c

# 재빌드
cd ~/w55rp20-build
./build.sh  # 이전 경로 기억
```

**워크플로우 3: VSCode 개발** (Windows/Mac/Linux)
```bash
# VSCode에서 프로젝트 열기
code ~/my-project

# F5 또는 Ctrl+Shift+B
# → Dev Container에서 빌드
# → 산출물 자동 생성
```

**워크플로우 4: AI IDE 개발**
```bash
# Cursor/Windsurf에서 프로젝트 열기
# AI에게 요청: "빌드해줘"
# → MCP Server를 통해 빌드 실행
# → 결과 피드백
```

### 핵심 설계 원칙

1. **점진적 복잡도**
   - 기본: 간단함 (`./build.sh`)
   - 고급: 세밀한 제어 가능

2. **플랫폼 중립성**
   - Linux/Mac/Windows 동일한 경험
   - Docker 기반으로 일관성 보장

3. **IDE 친화적**
   - Dev Container 우선
   - 확장/플러그인으로 확장 가능

4. **투명성**
   - "마법"보다 명시적 동작
   - 사용자가 무슨 일이 일어나는지 이해 가능

5. **하위 호환성**
   - 기존 사용자에게 영향 없음
   - 새 기능은 opt-in

### 미결정 사항

1. **SRC_DIR 기본값**
   - `$PWD/src` vs `$HOME/W55RP20-S2E`
   - → 일단 현재 유지, 대화형 모드로 보완?

2. **설정 파일 위치**
   - `.build-config` (프로젝트 루트)
   - `~/.w55rp20-config` (전역)
   - → 둘 다 지원? 우선순위?

3. **VSCode Extension 범위**
   - 최소 기능 (빌드/플래시만)
   - 풀 기능 (디버깅, 프로젝트 관리)
   - → 최소부터 시작, 점진적 확장

### 다음 단계

사용자 피드백 대기:
- 어떤 Phase부터 시작?
- build.sh 개선 vs VSCode 템플릿 vs 문서
- 우선순위 조정 필요?

### 참고

- 관련 커밋: 486e725 (USER_GUIDE.md 추가)
- 관련 문서: USER_GUIDE.md, DESIGN.md
- 논의 시작: 빌드 검증 완료 직후

---

## 템플릿 (향후 논의용)

### YYYY-MM-DD HH:MM TZ - 제목

#### 배경
(왜 이 논의가 시작되었나?)

#### 현재 상태
(무엇이 문제인가?)

#### 요구사항/목표
(무엇을 달성하려고 하나?)

#### 설계 방향
(어떤 옵션들이 있나? 각각의 장단점은?)

#### 결정
(최종 결정은? 왜?)

#### 다음 단계
(구현 계획은?)

#### 참고
(관련 커밋, 문서, 이슈)

---
