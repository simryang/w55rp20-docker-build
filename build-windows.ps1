# build-windows.ps1 - Windows PowerShell용 W55RP20 빌드 스크립트
# Docker Desktop for Windows 전용

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
$VERSION = "1.1.0-windows"

# ============================================================================
# 함수 정의
# ============================================================================

function Show-Help {
    Write-Host @"
W55RP20 Build System for Windows v$VERSION

Usage: .\build-windows.ps1 [OPTIONS]

OPTIONS:
  -Project PATH        프로젝트 디렉토리 (기본: 공식 W55RP20-S2E 클론)
  -Output PATH         빌드 산출물 디렉토리 (기본: .\out)
  -BuildType TYPE      빌드 타입 (Release|Debug, 기본: Release)
  -Jobs N              병렬 작업 수 (기본: 16)
  -Clean               산출물 정리 후 빌드
  -UpdateRepo          Git 레포 업데이트 (fetch/checkout/submodule)
  -NoConfirm           확인 없이 즉시 실행
  -Verbose             상세 출력
  -Help                이 도움말 표시

EXAMPLES:
  # 기본 빌드 (공식 프로젝트)
  .\build-windows.ps1

  # 사용자 프로젝트 빌드
  .\build-windows.ps1 -Project "C:\Users\myname\my-w55rp20-project"

  # 디버그 빌드
  .\build-windows.ps1 -BuildType Debug -Verbose

  # 정리 후 빌드
  .\build-windows.ps1 -Clean

REQUIREMENTS:
  - Docker Desktop for Windows (WSL2 backend)
  - Git for Windows

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

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Test-DockerDesktop {
    try {
        $null = docker info 2>&1
        return $true
    }
    catch {
        return $false
    }
}

function Resolve-WindowsPath {
    param([string]$Path)

    if ([string]::IsNullOrEmpty($Path)) {
        return $Path
    }

    # 상대 경로 → 절대 경로
    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        $Path = Join-Path $PWD $Path
    }

    # 정규화 (., .., 중복 슬래시 제거)
    return [System.IO.Path]::GetFullPath($Path)
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

Write-Info "W55RP20 Build System for Windows v$VERSION"
Write-Host ""

# Docker Desktop 확인
if (-not (Test-DockerDesktop)) {
    Write-Error-Custom "Docker Desktop이 실행되지 않았습니다"
    Write-Host ""
    Write-Host "해결 방법:" -ForegroundColor Yellow
    Write-Host "  1. Docker Desktop 설치: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    Write-Host "  2. Docker Desktop 실행" -ForegroundColor Yellow
    Write-Host "  3. WSL2 backend 활성화 (Settings > General > Use the WSL 2 based engine)" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Success "Docker Desktop 실행 중"

# ============================================================================
# 설정
# ============================================================================

$IMAGE = "w55rp20:latest"
$TMPFS_SIZE = "20g"

# 기본 디렉토리
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DEFAULT_SRC = "$env:USERPROFILE\W55RP20-S2E"
$DEFAULT_OUT = Join-Path $SCRIPT_DIR "out"
$DEFAULT_CCACHE = "$env:USERPROFILE\.ccache-w55rp20"

# 프로젝트 경로 결정
if ($Project) {
    $SRC_DIR = Resolve-WindowsPath $Project
    Write-Info "사용자 프로젝트: $SRC_DIR"
} else {
    $SRC_DIR = $DEFAULT_SRC
    Write-Info "공식 프로젝트 사용 (클론 필요 시 자동)"
}

# 산출물 경로
if ($Output) {
    $OUT_DIR = Resolve-WindowsPath $Output
} else {
    $OUT_DIR = $DEFAULT_OUT
}

$CCACHE_DIR = $DEFAULT_CCACHE

# 디렉토리 생성
New-Item -ItemType Directory -Force -Path $OUT_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $CCACHE_DIR | Out-Null

# ============================================================================
# 설정 확인
# ============================================================================

Write-Host ""
Write-Host "빌드 설정:" -ForegroundColor Cyan
Write-Host "  프로젝트: $SRC_DIR"
Write-Host "  산출물:   $OUT_DIR"
Write-Host "  빌드타입: $BuildType"
Write-Host "  병렬작업: $Jobs"
Write-Host "  정리:     $(if ($Clean) { 'Yes' } else { 'No' })"
Write-Host "  레포업데이트: $(if ($UpdateRepo) { 'Yes' } else { 'No' })"
Write-Host ""

# 확인 프롬프트
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
    Write-Host ""

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
# Docker 이미지 확인
# ============================================================================

Write-Info "Docker 이미지 확인 중..."

# 이미지 존재 확인 (에러 무시)
$savedErrorPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$null = docker image inspect $IMAGE 2>&1
$imageNeedsRebuild = $LASTEXITCODE -ne 0
$ErrorActionPreference = $savedErrorPreference

if ($imageNeedsRebuild) {
    Write-Info "로컬 이미지($IMAGE) 없음"
    Write-Host ""

    # DockerHub에서 이미지 다운로드 시도
    $DOCKERHUB_IMAGE = "simryang/w55rp20:latest"

    Write-Info "DockerHub에서 이미지 다운로드 중... (최초 1회, 약 5분)"
    Write-Host "  이미지: $DOCKERHUB_IMAGE" -ForegroundColor Cyan
    Write-Host ""

    # Pull 시도 (에러 허용)
    $ErrorActionPreference = "Continue"
    docker pull $DOCKERHUB_IMAGE
    $pullExitCode = $LASTEXITCODE
    $ErrorActionPreference = $savedErrorPreference

    if ($pullExitCode -eq 0) {
        # Pull 성공 - 로컬 태그로 재태깅
        Write-Success "이미지 다운로드 완료"
        docker tag $DOCKERHUB_IMAGE $IMAGE
        Write-Info "이미지 준비 완료: $IMAGE"
    } else {
        # Pull 실패 - 로컬 빌드
        Write-Warning "DockerHub 다운로드 실패, 로컬 빌드 시작..."
        Write-Info "Docker 이미지 빌드 중... (최초 1회, 약 20분 소요)"
        Write-Host ""

        Push-Location $SCRIPT_DIR

        docker buildx build `
            --platform linux/amd64 `
            -t $IMAGE `
            --load `
            --progress=plain `
            -f Dockerfile .

        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Docker 이미지 빌드 실패"
            Pop-Location
            exit 1
        }

        Pop-Location
        Write-Success "이미지 빌드 완료"
    }
} else {
    Write-Success "이미지 존재 (재사용)"
}

# ============================================================================
# 빌드 실행
# ============================================================================

Write-Host ""
Write-Info "빌드 시작..."
Write-Host ""

# Docker run 명령
$dockerArgs = @(
    "run", "--rm", "-t"
    "-v", "${SRC_DIR}:/work/src"
    "-v", "${OUT_DIR}:/work/out"
    "-v", "${CCACHE_DIR}:/work/.ccache"
    "--tmpfs", "/work/src/build:rw,exec,size=$TMPFS_SIZE"
    "-e", "CCACHE_DIR=/work/.ccache"
    "-e", "JOBS=$Jobs"
    "-e", "BUILD_TYPE=$BuildType"
    "-e", "UPDATE_REPO=$(if ($UpdateRepo) { '1' } else { '0' })"
    $IMAGE
    "/usr/local/bin/docker-build.sh"
)

if ($Verbose) {
    Write-Host "Docker 명령:" -ForegroundColor Yellow
    Write-Host "docker $($dockerArgs -join ' ')" -ForegroundColor Yellow
    Write-Host ""
}

# 실행
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

    # 산출물 목록
    Write-Host "생성된 파일:" -ForegroundColor Cyan

    $uf2Files = Get-ChildItem -Path $OUT_DIR -Filter "*.uf2" -ErrorAction SilentlyContinue

    if ($uf2Files) {
        foreach ($file in $uf2Files) {
            $size = "{0:N2} KB" -f ($file.Length / 1KB)
            Write-Host "  → $($file.Name)  ($size)" -ForegroundColor Green
        }
    } else {
        Write-Warning "산출물이 생성되지 않았습니다"
    }

    Write-Host ""
    Write-Host "산출물 위치: $OUT_DIR" -ForegroundColor Cyan
    Write-Host ""

    # 다음 단계 안내
    Write-Host "다음 단계:" -ForegroundColor Yellow
    Write-Host "  1. W55RP20 보드를 BOOTSEL 버튼을 누른 채로 USB 연결" -ForegroundColor Yellow
    Write-Host "  2. 'RPI-RP2' 드라이브로 인식됨" -ForegroundColor Yellow
    Write-Host "  3. $OUT_DIR\*.uf2 파일을 드라이브에 복사" -ForegroundColor Yellow
    Write-Host "  4. 자동으로 재부팅 및 펌웨어 업로드 완료" -ForegroundColor Yellow
    Write-Host ""

    exit 0
} else {
    Write-Error-Custom "빌드 실패 (exit code: $exitCode)"
    Write-Host ""
    exit $exitCode
}
