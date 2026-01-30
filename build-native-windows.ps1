# build-native-windows.ps1
# Windows Native Container 빌드 스크립트 (WSL2 불필요!)

param(
    [string]$Project = "",
    [string]$Output = "",
    [string]$BuildType = "Release",
    [int]$Jobs = 16,
    [switch]$Clean,
    [switch]$UpdateRepo,
    [switch]$NoConfirm,
    [switch]$Verbose,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$VERSION = "1.1.0-native-windows"

# ============================================================================
# 함수
# ============================================================================

function Show-Help {
    Write-Host @"
W55RP20 Native Windows Container Build System v$VERSION

WSL2 불필요! Windows 네이티브 컨테이너 사용

Usage: .\build-native-windows.ps1 [OPTIONS]

OPTIONS:
  -Project PATH        프로젝트 디렉토리
  -Output PATH         빌드 산출물 디렉토리 (기본: .\out)
  -BuildType TYPE      빌드 타입 (Release|Debug, 기본: Release)
  -Jobs N              병렬 작업 수 (기본: 16)
  -Clean               산출물 정리 후 빌드
  -UpdateRepo          Git 레포 업데이트
  -NoConfirm           확인 없이 즉시 실행
  -Verbose             상세 출력
  -Help                이 도움말 표시

REQUIREMENTS:
  - Docker Desktop for Windows
  - Windows containers mode (Linux containers 아님!)

SETUP (최초 1회):
  1. Docker Desktop 실행
  2. 시스템 트레이 Docker 아이콘 우클릭
  3. "Switch to Windows containers..." 선택
  4. 이 스크립트 실행

ADVANTAGES:
  [O] WSL2 불필요
  [O] Linux VM 없음
  [O] Windows 네이티브 성능
  [O] 직접 .exe 실행

DISADVANTAGES:
  [X] 이미지 크기 큼 (약 2GB)
  [X] 첫 빌드 느림 (다운로드 시간)

EXAMPLES:
  # 기본 빌드
  .\build-native-windows.ps1

  # 사용자 프로젝트
  .\build-native-windows.ps1 -Project "C:\Users\me\my-project"

  # 상세 출력
  .\build-native-windows.ps1 -Verbose

"@
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Test-DockerWindows {
    try {
        $info = docker info 2>&1 | Out-String
        if ($info -match "OSType:\s*windows") {
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

# ============================================================================
# 도움말
# ============================================================================

if ($Help) {
    Show-Help
    exit 0
}

# ============================================================================
# 사전 검사
# ============================================================================

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  W55RP20 Native Windows Container Build v$VERSION  ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Docker Desktop 확인
Write-Info "Checking Docker Desktop..."

try {
    $null = docker info 2>&1
}
catch {
    Write-Error-Custom "Docker Desktop이 실행되지 않았습니다"
    Write-Host ""
    Write-Host "해결 방법:" -ForegroundColor Yellow
    Write-Host "  1. Docker Desktop 설치: https://www.docker.com/products/docker-desktop"
    Write-Host "  2. Docker Desktop 실행"
    Write-Host ""
    exit 1
}

# Windows 컨테이너 모드 확인
if (-not (Test-DockerWindows)) {
    Write-Error-Custom "Docker가 Linux containers 모드로 실행 중입니다"
    Write-Host ""
    Write-Host "해결 방법 (Windows containers로 전환):" -ForegroundColor Yellow
    Write-Host "  1. 시스템 트레이의 Docker 아이콘 우클릭" -ForegroundColor Yellow
    Write-Host "  2. 'Switch to Windows containers...' 선택" -ForegroundColor Yellow
    Write-Host "  3. 확인 대화상자에서 'Switch' 클릭" -ForegroundColor Yellow
    Write-Host "  4. 전환 완료 후 이 스크립트 재실행" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "참고:" -ForegroundColor Cyan
    Write-Host "  - WSL2 기반 빌드를 원하시면: .\build-windows.ps1 사용" -ForegroundColor Cyan
    Write-Host "  - Windows 네이티브 빌드를 원하시면: 위 단계 수행 후 재실행" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

Write-Success "Docker Desktop (Windows containers mode) 실행 중"

# ============================================================================
# 설정
# ============================================================================

$IMAGE = "w55rp20-windows:latest"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DEFAULT_SRC = "$env:USERPROFILE\W55RP20-S2E"
$DEFAULT_OUT = Join-Path $SCRIPT_DIR "out"

if ($Project) {
    $SRC_DIR = [System.IO.Path]::GetFullPath($Project)
    Write-Info "사용자 프로젝트: $SRC_DIR"
} else {
    $SRC_DIR = $DEFAULT_SRC
    Write-Info "공식 프로젝트 사용"
}

if ($Output) {
    $OUT_DIR = [System.IO.Path]::GetFullPath($Output)
} else {
    $OUT_DIR = $DEFAULT_OUT
}

New-Item -ItemType Directory -Force -Path $OUT_DIR | Out-Null

# ============================================================================
# 설정 출력
# ============================================================================

Write-Host ""
Write-Host "빌드 설정:" -ForegroundColor Cyan
Write-Host "  프로젝트: $SRC_DIR"
Write-Host "  산출물:   $OUT_DIR"
Write-Host "  빌드타입: $BuildType"
Write-Host "  병렬작업: $Jobs"
Write-Host ""

if (-not $NoConfirm) {
    $response = Read-Host "계속하시겠습니까? [Y/n]"
    if ($response -match '^[Nn]$') {
        Write-Host "취소되었습니다."
        exit 0
    }
}

# ============================================================================
# 레포 클론/업데이트
# ============================================================================

if (-not (Test-Path "$SRC_DIR\.git")) {
    Write-Info "소스 코드 없음 → 클론 중..."
    $REPO_URL = "https://github.com/WIZnet-ioNIC/W55RP20-S2E.git"
    git clone --recurse-submodules $REPO_URL $SRC_DIR

    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Git 클론 실패"
        exit 1
    }
    Write-Success "클론 완료"
}

if ($UpdateRepo) {
    Write-Info "레포 업데이트 중..."
    Push-Location $SRC_DIR
    git fetch --all --tags
    git submodule update --init --recursive
    Pop-Location
}

# ============================================================================
# 산출물 정리
# ============================================================================

if ($Clean) {
    Write-Info "산출물 정리 중..."
    Remove-Item "$OUT_DIR\*.uf2" -ErrorAction SilentlyContinue
    Remove-Item "$OUT_DIR\*.elf" -ErrorAction SilentlyContinue
    Remove-Item "$OUT_DIR\*.bin" -ErrorAction SilentlyContinue
    Remove-Item "$OUT_DIR\*.hex" -ErrorAction SilentlyContinue
}

# ============================================================================
# Docker 이미지 확인/빌드
# ============================================================================

Write-Info "Docker 이미지 확인 중..."

$null = docker image inspect $IMAGE 2>&1
$imageNeedsRebuild = $LASTEXITCODE -ne 0

if ($imageNeedsRebuild) {
    Write-Info "로컬 이미지($IMAGE) 없음"
    Write-Host ""

    # TODO: DockerHub에서 Windows 이미지 다운로드 (향후 지원)
    # $DOCKERHUB_IMAGE = "simryang/w55rp20:windows"
    # docker pull $DOCKERHUB_IMAGE
    # if ($LASTEXITCODE -eq 0) {
    #     docker tag $DOCKERHUB_IMAGE $IMAGE
    # }

    # 현재: Windows 이미지는 로컬 빌드 필요
    Write-Info "Windows 컨테이너 이미지 빌드 중..."
    Write-Warning-Custom "최초 1회, 약 30-40분 소요 (대용량 다운로드)"
    Write-Host ""
    Write-Host "빌드 내용:" -ForegroundColor Cyan
    Write-Host "  - Nano Server base image (297MB)"
    Write-Host "  - Git for Windows"
    Write-Host "  - Python 3.12"
    Write-Host "  - CMake 3.31"
    Write-Host "  - Ninja 1.13"
    Write-Host "  - ARM GCC 14.2"
    Write-Host "  - Pico SDK 2.2.0"
    Write-Host ""

    Push-Location $SCRIPT_DIR

    docker build `
        -f Dockerfile.windows `
        -t $IMAGE `
        --isolation=hyperv `
        .

    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "이미지 빌드 실패"
        Pop-Location
        exit 1
    }

    Pop-Location
    Write-Success "이미지 빌드 완료"
} else {
    Write-Success "이미지 존재 (재사용)"
}

# ============================================================================
# 빌드 실행
# ============================================================================

Write-Host ""
Write-Info "빌드 시작..."
Write-Host ""

$dockerArgs = @(
    "run", "--rm"
    "--isolation=hyperv"
    "-v", "${SRC_DIR}:C:\work\src"
    "-v", "${OUT_DIR}:C:\work\out"
    "-e", "JOBS=$Jobs"
    "-e", "BUILD_TYPE=$BuildType"
    $IMAGE
)

if ($Verbose) {
    Write-Host "Docker 명령:" -ForegroundColor Yellow
    Write-Host "docker $($dockerArgs -join ' ')" -ForegroundColor Yellow
    Write-Host ""
}

$startTime = Get-Date

& docker $dockerArgs

$exitCode = $LASTEXITCODE
$elapsed = (Get-Date) - $startTime

# ============================================================================
# 결과 출력
# ============================================================================

Write-Host ""

if ($exitCode -eq 0) {
    Write-Success "빌드 성공! (소요 시간: $($elapsed.ToString('mm\:ss')))"
    Write-Host ""

    Write-Host "생성된 파일:" -ForegroundColor Cyan
    $uf2Files = Get-ChildItem -Path $OUT_DIR -Filter "*.uf2" -ErrorAction SilentlyContinue

    if ($uf2Files) {
        foreach ($file in $uf2Files) {
            $size = "{0:N2} KB" -f ($file.Length / 1KB)
            Write-Host "  → $($file.Name)  ($size)" -ForegroundColor Green
        }
    } else {
        Write-Warning-Custom "산출물이 생성되지 않았습니다"
    }

    Write-Host ""
    Write-Host "산출물 위치: $OUT_DIR" -ForegroundColor Cyan
    Write-Host ""

    exit 0
} else {
    Write-Error-Custom "빌드 실패 (exit code: $exitCode)"
    Write-Host ""
    exit $exitCode
}
