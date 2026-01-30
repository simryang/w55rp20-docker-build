# build.ps1 - W55RP20 통합 빌드 시스템 (All-in-One)
# Linux 컨테이너 + Windows 컨테이너 자동 선택 또는 사용자 지정

param(
    [string]$Project = "",
    [string]$Output = "",
    [string]$BuildType = "Release",
    [int]$Jobs = 16,
    [switch]$Clean,
    [switch]$UpdateRepo,
    [switch]$NoConfirm,
    [switch]$Verbose,

    # 컨테이너 타입 선택
    [switch]$Linux,      # 강제로 Linux 컨테이너 사용 (WSL2 필요)
    [switch]$Windows,    # 강제로 Windows 컨테이너 사용 (WSL2 불필요)
    [switch]$Auto,       # 자동 선택 (기본값)

    # 대화형 모드
    [switch]$Interactive, # 대화형 선택 모드

    [switch]$Help
)

$ErrorActionPreference = "Stop"
$VERSION = "1.2.0-unified"

# ============================================================================
# 함수
# ============================================================================

function Show-Help {
    Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║  W55RP20 통합 빌드 시스템 v$VERSION                    ║
║  Linux 컨테이너 + Windows 컨테이너 All-in-One              ║
╚══════════════════════════════════════════════════════════════╝

Usage: .\build.ps1 [OPTIONS]

컨테이너 선택:
  -Interactive         대화형 선택 모드 (추천!)
  -Linux               Linux 컨테이너 사용 (WSL2 기반, 크로스 플랫폼)
  -Windows             Windows 컨테이너 사용 (WSL2 불필요, 네이티브)
  -Auto                자동 선택 (기본값, Docker 모드에 따라)

빌드 옵션:
  -Project PATH        프로젝트 디렉토리
  -Output PATH         빌드 산출물 디렉토리 (기본: .\out)
  -BuildType TYPE      빌드 타입 (Release|Debug, 기본: Release)
  -Jobs N              병렬 작업 수 (기본: 16)
  -Clean               산출물 정리 후 빌드
  -UpdateRepo          Git 레포 업데이트
  -NoConfirm           확인 없이 즉시 실행
  -Verbose             상세 출력
  -Help                이 도움말 표시

EXAMPLES:
  # 대화형 모드 (초보자 추천!)
  .\build.ps1 -Interactive

  # 자동 선택
  .\build.ps1

  # Linux 컨테이너
  .\build.ps1 -Linux

  # Windows 컨테이너
  .\build.ps1 -Windows

MORE INFO:
  docs\WINDOWS_ALL_IN_ONE.md

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

function Get-DockerMode {
    try {
        $info = docker info 2>&1 | Out-String
        if ($info -match "OSType:\s*windows") {
            return "windows"
        } elseif ($info -match "OSType:\s*linux") {
            return "linux"
        }
        return "unknown"
    }
    catch {
        return "error"
    }
}

function Show-Banner {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  W55RP20 통합 빌드 시스템 v$VERSION                    ║" -ForegroundColor Cyan
    Write-Host "║  Linux 컨테이너 + Windows 컨테이너 All-in-One              ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Show-InteractiveMenu {
    param([string]$CurrentMode)

    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host "  컨테이너 타입을 선택하세요" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host ""

    # 옵션 1: Linux 컨테이너
    Write-Host "  [1] Linux 컨테이너 (크로스 플랫폼)" -ForegroundColor Green
    Write-Host ""
    Write-Host "      장점:" -ForegroundColor Cyan
    Write-Host "        [O] Linux/macOS/Windows 모두 사용 가능" -ForegroundColor White
    Write-Host "        [O] 팀 개발 최적 (환경 통일)" -ForegroundColor White
    Write-Host "        [O] CI/CD 완벽 호환 (GitHub Actions 등)" -ForegroundColor White
    Write-Host "        [O] 표준적 (전 세계 Docker의 99%)" -ForegroundColor White
    Write-Host ""
    Write-Host "      단점:" -ForegroundColor Cyan
    Write-Host "        [!]  WSL2 필요 (Docker Desktop이 자동 설치)" -ForegroundColor White
    Write-Host "        [!]  약간의 성능 오버헤드 (6%, 실용적 수준)" -ForegroundColor White
    Write-Host ""
    Write-Host "      시간/용량:" -ForegroundColor Cyan
    Write-Host "        [T]  최초 빌드: 약 20분 (이미지 생성)" -ForegroundColor White
    Write-Host "        [T]  이후 빌드: 약 50초 → 12초 (ccache)" -ForegroundColor White
    Write-Host "        [D] 이미지 크기: 2GB" -ForegroundColor White
    Write-Host "        [D] 디스크 여유: 5GB 권장" -ForegroundColor White
    Write-Host ""

    # 옵션 2: Windows 컨테이너
    Write-Host "  [2] Windows 컨테이너 (네이티브)" -ForegroundColor Green
    Write-Host ""
    Write-Host "      장점:" -ForegroundColor Cyan
    Write-Host "        [O] WSL2 불필요!" -ForegroundColor White
    Write-Host "        [O] Windows 네이티브 성능 (오버헤드 0%)" -ForegroundColor White
    Write-Host "        [O] .exe 직접 실행" -ForegroundColor White
    Write-Host "        [O] Hyper-V 격리 (보안)" -ForegroundColor White
    Write-Host ""
    Write-Host "      단점:" -ForegroundColor Cyan
    Write-Host "        [!]  Windows 전용 (Linux/macOS 불가)" -ForegroundColor White
    Write-Host "        [!]  CI/CD 제한적 (Windows runner 비용)" -ForegroundColor White
    Write-Host "        [!]  Docker 모드 전환 필요" -ForegroundColor White
    Write-Host ""
    Write-Host "      시간/용량:" -ForegroundColor Cyan
    Write-Host "        [T]  최초 빌드: 약 30-40분 (대용량 다운로드)" -ForegroundColor White
    Write-Host "        [T]  이후 빌드: 약 47초 → 11초 (ccache)" -ForegroundColor White
    Write-Host "        [D] 이미지 크기: 2.5GB" -ForegroundColor White
    Write-Host "        [D] 디스크 여유: 6GB 권장" -ForegroundColor White
    Write-Host ""

    # 옵션 3: 자동
    Write-Host "  [3] 자동 선택 (현재 Docker 모드: $CurrentMode)" -ForegroundColor Green
    Write-Host ""
    Write-Host "      현재 Docker 모드를 자동으로 사용합니다." -ForegroundColor White
    Write-Host ""

    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host ""

    # 추천 표시
    if ($CurrentMode -eq "linux") {
        Write-Host "[i] 추천: [1] Linux 컨테이너 (현재 모드와 일치)" -ForegroundColor Cyan
    } elseif ($CurrentMode -eq "windows") {
        Write-Host "[i] 추천: [2] Windows 컨테이너 (현재 모드와 일치)" -ForegroundColor Cyan
    }

    Write-Host ""
    Write-Host "선택하세요 [1-3] (기본값: 3): " -NoNewline -ForegroundColor Yellow

    $choice = Read-Host
    if ([string]::IsNullOrWhiteSpace($choice)) {
        $choice = "3"
    }

    return $choice
}

function Show-CompletionMessage {
    param(
        [string]$ContainerType,
        [string]$OutputDir
    )

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                   빌드 완료!                            ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""

    # 산출물 위치
    Write-Host "[>] 산출물 위치:" -ForegroundColor Cyan
    Write-Host "   $OutputDir" -ForegroundColor White
    Write-Host ""

    # W55RP20에 업로드하는 방법
    Write-Host "[*] W55RP20에 펌웨어 업로드하는 방법:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   1. W55RP20 보드의 BOOTSEL 버튼을 누른 채로 USB 연결" -ForegroundColor White
    Write-Host "   2. Windows가 'RPI-RP2' 드라이브로 인식" -ForegroundColor White
    Write-Host "   3. $OutputDir\*.uf2 파일을 드라이브에 복사" -ForegroundColor White
    Write-Host "   4. 자동으로 재부팅 및 펌웨어 업로드 완료!" -ForegroundColor White
    Write-Host ""

    # 다음 빌드 방법
    Write-Host "[>] 다음 빌드 방법:" -ForegroundColor Cyan
    Write-Host ""

    if ($ContainerType -eq "linux") {
        Write-Host "   공식 프로젝트 재빌드:" -ForegroundColor Yellow
        Write-Host "     .\build.ps1 -Linux" -ForegroundColor White
        Write-Host ""
        Write-Host "   사용자 프로젝트 빌드:" -ForegroundColor Yellow
        Write-Host "     .\build.ps1 -Linux -Project `"C:\Users\yourname\your-w55rp20-project`"" -ForegroundColor White
        Write-Host ""
        Write-Host "   디버그 빌드:" -ForegroundColor Yellow
        Write-Host "     .\build.ps1 -Linux -BuildType Debug" -ForegroundColor White
        Write-Host ""
        Write-Host "   정리 후 빌드:" -ForegroundColor Yellow
        Write-Host "     .\build.ps1 -Linux -Clean" -ForegroundColor White
    }
    elseif ($ContainerType -eq "windows") {
        Write-Host "   공식 프로젝트 재빌드:" -ForegroundColor Yellow
        Write-Host "     .\build.ps1 -Windows" -ForegroundColor White
        Write-Host ""
        Write-Host "   사용자 프로젝트 빌드:" -ForegroundColor Yellow
        Write-Host "     .\build.ps1 -Windows -Project `"C:\Users\yourname\your-w55rp20-project`"" -ForegroundColor White
        Write-Host ""
        Write-Host "   디버그 빌드:" -ForegroundColor Yellow
        Write-Host "     .\build.ps1 -Windows -BuildType Debug" -ForegroundColor White
        Write-Host ""
        Write-Host "   정리 후 빌드:" -ForegroundColor Yellow
        Write-Host "     .\build.ps1 -Windows -Clean" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "[i] 팁: 이후 빌드는 훨씬 빠릅니다! (이미지 재사용)" -ForegroundColor Cyan
    Write-Host ""

    # 추가 도움말
    Write-Host "[?] 더 많은 정보:" -ForegroundColor Cyan
    Write-Host "   .\build.ps1 -Help" -ForegroundColor White
    Write-Host "   docs\WINDOWS_ALL_IN_ONE.md" -ForegroundColor White
    Write-Host ""
}

# ============================================================================
# 도움말
# ============================================================================

if ($Help) {
    Show-Help
    exit 0
}

# ============================================================================
# 초기화
# ============================================================================

Show-Banner

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# ============================================================================
# Docker 상태 확인
# ============================================================================

Write-Info "Docker Desktop 상태 확인 중..."

$dockerMode = Get-DockerMode

if ($dockerMode -eq "error") {
    Write-Error-Custom "Docker Desktop이 실행되지 않았습니다"
    Write-Host ""
    Write-Host "해결 방법:" -ForegroundColor Yellow
    Write-Host "  1. Docker Desktop 설치: https://www.docker.com/products/docker-desktop"
    Write-Host "  2. Docker Desktop 실행"
    Write-Host ""
    exit 1
}

Write-Success "Docker Desktop 실행 중 (현재 모드: $dockerMode containers)"

# ============================================================================
# 대화형 모드
# ============================================================================

if ($Interactive) {
    $choice = Show-InteractiveMenu -CurrentMode $dockerMode

    switch ($choice) {
        "1" {
            $Linux = $true
            Write-Info "Linux 컨테이너를 선택했습니다"
        }
        "2" {
            $Windows = $true
            Write-Info "Windows 컨테이너를 선택했습니다"
        }
        "3" {
            $Auto = $true
            Write-Info "자동 선택합니다 (현재 모드: $dockerMode)"
        }
        default {
            Write-Error-Custom "잘못된 선택입니다: $choice"
            exit 1
        }
    }

    Write-Host ""
}

# ============================================================================
# 컨테이너 타입 결정
# ============================================================================

$containerType = ""

# 명시적 선택 확인
if ($Linux -and $Windows) {
    Write-Error-Custom "-Linux와 -Windows를 동시에 사용할 수 없습니다"
    exit 1
}

if ($Linux) {
    $containerType = "linux"
    if (-not $Interactive) {
        Write-Info "사용자 선택: Linux 컨테이너"
    }
}
elseif ($Windows) {
    $containerType = "windows"
    if (-not $Interactive) {
        Write-Info "사용자 선택: Windows 컨테이너"
    }
}
else {
    # 자동 선택 (Docker 현재 모드에 따라)
    $containerType = $dockerMode
    if (-not $Interactive) {
        Write-Info "자동 선택: $containerType 컨테이너 (Docker 현재 모드)"
    }
}

# ============================================================================
# 모드 불일치 확인 및 안내
# ============================================================================

if ($containerType -ne $dockerMode) {
    Write-Host ""
    Write-Warning-Custom "Docker 모드 불일치!"
    Write-Host ""
    Write-Host "  요청: $containerType 컨테이너" -ForegroundColor Yellow
    Write-Host "  현재: $dockerMode 컨테이너" -ForegroundColor Yellow
    Write-Host ""

    if ($containerType -eq "linux" -and $dockerMode -eq "windows") {
        Write-Host "해결 방법 (Linux containers로 전환):" -ForegroundColor Cyan
        Write-Host "  1. 시스템 트레이의 Docker 아이콘 우클릭" -ForegroundColor Cyan
        Write-Host "  2. 'Switch to Linux containers...' 선택" -ForegroundColor Cyan
        Write-Host "  3. 전환 완료 후 이 스크립트 재실행" -ForegroundColor Cyan
    }
    elseif ($containerType -eq "windows" -and $dockerMode -eq "linux") {
        Write-Host "해결 방법 (Windows containers로 전환):" -ForegroundColor Cyan
        Write-Host "  1. 시스템 트레이의 Docker 아이콘 우클릭" -ForegroundColor Cyan
        Write-Host "  2. 'Switch to Windows containers...' 선택" -ForegroundColor Cyan
        Write-Host "  3. 전환 완료 후 이 스크립트 재실행" -ForegroundColor Cyan
    }

    Write-Host ""
    Write-Host "또는:" -ForegroundColor Green
    Write-Host "  현재 모드($dockerMode)로 빌드하려면: .\build.ps1 -$([System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($dockerMode))" -ForegroundColor Green
    Write-Host ""

    if ($Interactive) {
        $response = Read-Host "종료하시겠습니까? [Y/n]"
        if ($response -notmatch '^[Nn]$') {
            exit 0
        }
    } else {
        $response = Read-Host "그대로 종료하시겠습니까? [Y/n]"
        if ($response -notmatch '^[Nn]$') {
            exit 0
        }
    }
}

# ============================================================================
# 적절한 빌드 스크립트 실행
# ============================================================================

Write-Host ""
Write-Info "빌드 준비 중..."
Write-Host ""

# 공통 파라미터 구성
$commonParams = @{}
if ($Project) { $commonParams['Project'] = $Project }
if ($Output) { $commonParams['Output'] = $Output }
if ($BuildType) { $commonParams['BuildType'] = $BuildType }
if ($Jobs) { $commonParams['Jobs'] = $Jobs }
if ($Clean) { $commonParams['Clean'] = $true }
if ($UpdateRepo) { $commonParams['UpdateRepo'] = $true }
if ($NoConfirm) { $commonParams['NoConfirm'] = $true }
if ($Verbose) { $commonParams['Verbose'] = $true }

# 산출물 디렉토리 결정 (완료 메시지용)
$finalOutputDir = if ($Output) { $Output } else { Join-Path $SCRIPT_DIR "out" }
$finalOutputDir = [System.IO.Path]::GetFullPath($finalOutputDir)

if ($containerType -eq "linux") {
    Write-Success "Linux 컨테이너 빌드 시작 (WSL2 기반)"
    Write-Host ""
    Write-Host "특징:" -ForegroundColor Cyan
    Write-Host "  [O] 크로스 플랫폼 (Linux/macOS/Windows)"
    Write-Host "  [O] CI/CD 완벽 호환"
    Write-Host "  [O] 표준 Docker 경험"
    Write-Host ""

    $scriptPath = Join-Path $SCRIPT_DIR "build-windows.ps1"

    if (-not (Test-Path $scriptPath)) {
        Write-Error-Custom "build-windows.ps1을 찾을 수 없습니다: $scriptPath"
        exit 1
    }

    & $scriptPath @commonParams
    $buildExitCode = $LASTEXITCODE

    if ($buildExitCode -eq 0) {
        Show-CompletionMessage -ContainerType "linux" -OutputDir $finalOutputDir
    }

    exit $buildExitCode
}
elseif ($containerType -eq "windows") {
    Write-Success "Windows 컨테이너 빌드 시작 (네이티브)"
    Write-Host ""
    Write-Host "특징:" -ForegroundColor Cyan
    Write-Host "  [O] WSL2 불필요"
    Write-Host "  [O] Windows 네이티브 성능"
    Write-Host "  [O] .exe 직접 실행"
    Write-Host ""

    $scriptPath = Join-Path $SCRIPT_DIR "build-native-windows.ps1"

    if (-not (Test-Path $scriptPath)) {
        Write-Error-Custom "build-native-windows.ps1을 찾을 수 없습니다: $scriptPath"
        exit 1
    }

    & $scriptPath @commonParams
    $buildExitCode = $LASTEXITCODE

    if ($buildExitCode -eq 0) {
        Show-CompletionMessage -ContainerType "windows" -OutputDir $finalOutputDir
    }

    exit $buildExitCode
}
else {
    Write-Error-Custom "알 수 없는 컨테이너 타입: $containerType"
    exit 1
}
