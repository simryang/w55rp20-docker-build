# docker-build-windows.ps1
# Windows 컨테이너 내부에서 실행되는 빌드 스크립트

$ErrorActionPreference = "Stop"

# 환경 변수 기본값
$JOBS = if ($env:JOBS) { $env:JOBS } else { "16" }
$BUILD_TYPE = if ($env:BUILD_TYPE) { $env:BUILD_TYPE } else { "Release" }

Write-Host "[INFO] W55RP20 Build (Windows Container)"
Write-Host "[INFO] JOBS=$JOBS"
Write-Host "[INFO] BUILD_TYPE=$BUILD_TYPE"
Write-Host "[INFO] PICO_SDK_PATH=$env:PICO_SDK_PATH"

# 경로 확인
if (-not (Test-Path "C:\work\src")) {
    Write-Error "Source directory not mounted at C:\work\src"
    exit 1
}

# Git safe.directory (볼륨 마운트 이슈 회피)
if (Test-Path "C:\work\src\.git") {
    git config --global --add safe.directory C:\work\src
}

# 빌드 디렉토리 생성
$BUILD_DIR = "C:\work\src\build"
if (Test-Path $BUILD_DIR) {
    Write-Host "[INFO] Cleaning existing build directory..."
    Remove-Item -Recurse -Force $BUILD_DIR
}
New-Item -ItemType Directory -Path $BUILD_DIR | Out-Null

# CMake 설정
Write-Host "[INFO] Running CMake configure..."
Set-Location $BUILD_DIR

cmake -G Ninja `
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE `
    -DPICO_SDK_PATH=$env:PICO_SDK_PATH `
    -DPICO_TOOLCHAIN_PATH=$env:PICO_TOOLCHAIN_PATH `
    C:\work\src

if ($LASTEXITCODE -ne 0) {
    Write-Error "CMake configure failed"
    exit $LASTEXITCODE
}

# Ninja 빌드
Write-Host "[INFO] Running Ninja build (parallel jobs: $JOBS)..."
ninja -j $JOBS

if ($LASTEXITCODE -ne 0) {
    Write-Error "Ninja build failed"
    exit $LASTEXITCODE
}

# 산출물 복사
Write-Host "[INFO] Collecting build artifacts..."
$OUT_DIR = "C:\work\out"
New-Item -ItemType Directory -Path $OUT_DIR -Force | Out-Null

$artifacts = Get-ChildItem -Path $BUILD_DIR -Recurse -Include "*.uf2","*.elf","*.bin","*.hex"

if ($artifacts) {
    foreach ($file in $artifacts) {
        Copy-Item $file.FullName -Destination $OUT_DIR -Force
        Write-Host "  → $($file.Name)"
    }
} else {
    Write-Warning "No artifacts found"
}

# 빌드 정보
Write-Host ""
Write-Host "=== Build Summary ==="
Write-Host "Build Type: $BUILD_TYPE"
Write-Host "Parallel Jobs: $JOBS"
Write-Host "Output Directory: $OUT_DIR"

$outputFiles = Get-ChildItem -Path $OUT_DIR -File
Write-Host "Generated Files: $($outputFiles.Count)"
foreach ($file in $outputFiles) {
    $sizeKB = [math]::Round($file.Length / 1KB, 2)
    Write-Host "  $($file.Name) ($sizeKB KB)"
}

Write-Host ""
Write-Host "[SUCCESS] Build completed successfully!"
exit 0
