param(
    [string]$ProjectRoot = "C:\Users\Lenovo\Desktop\Velo\uber-clone-template",
    [string]$OutputDir = "C:\Users\Lenovo\Desktop\Velo-APKs"
)

$ErrorActionPreference = "Stop"

function Resolve-Flutter {
    $candidates = @(
        "C:\Users\Lenovo\.puro\envs\velo\flutter\bin\flutter.bat",
        "C:\Users\Lenovo\flutter\bin\flutter.bat"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    throw "Flutter SDK not found. Add flutter to PATH or update candidates in scripts/build-all-apks.ps1."
}

function Invoke-Flutter {
    param(
        [string]$FlutterPath,
        [string]$WorkingDirectory,
        [string[]]$Arguments
    )

    Push-Location $WorkingDirectory
    try {
        & $FlutterPath @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter command failed in ${WorkingDirectory}: flutter $($Arguments -join ' ')"
        }
    }
    finally {
        Pop-Location
    }
}

function Build-App {
    param(
        [string]$FlutterPath,
        [string]$AppDir,
        [string]$OutputName
    )

    Write-Host "=== Building $OutputName from $AppDir ===" -ForegroundColor Cyan
    Invoke-Flutter -FlutterPath $FlutterPath -WorkingDirectory $AppDir -Arguments @("pub", "get")
    Invoke-Flutter -FlutterPath $FlutterPath -WorkingDirectory $AppDir -Arguments @("build", "apk", "--release", "--android-skip-build-dependency-validation")

    $apkPath = Join-Path $AppDir "build\app\outputs\flutter-apk\app-release.apk"
    if (-not (Test-Path $apkPath)) {
        throw "Expected APK not found: $apkPath"
    }

    $destination = Join-Path $OutputDir $OutputName
    Copy-Item -Path $apkPath -Destination $destination -Force
    Write-Host "Copied: $destination" -ForegroundColor Green
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$flutterPath = Resolve-Flutter
Write-Host "Using Flutter: $flutterPath" -ForegroundColor Yellow
& $flutterPath --version

$apps = @(
    @{ Dir = (Join-Path $ProjectRoot "uber_users_app"); Name = "Velo-User-release.apk" },
    @{ Dir = (Join-Path $ProjectRoot "uber_drivers_app"); Name = "Velo-Driver-release.apk" },
    @{ Dir = (Join-Path $ProjectRoot "uber_admin_panel"); Name = "Velo-Admin-release.apk" }
)

$failed = @()
foreach ($app in $apps) {
    try {
        Build-App -FlutterPath $flutterPath -AppDir $app.Dir -OutputName $app.Name
    }
    catch {
        Write-Host "FAILED: $($app.Name) -> $($_.Exception.Message)" -ForegroundColor Red
        $failed += $app.Name
    }
}

Write-Host ""
Write-Host "=== Build summary ===" -ForegroundColor Cyan
if ($failed.Count -eq 0) {
    Write-Host "All APKs built successfully in $OutputDir" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "Some APK builds failed: $($failed -join ', ')" -ForegroundColor Red
    Write-Host "Check terminal output above for exact compiler errors." -ForegroundColor Yellow
    exit 1
}
