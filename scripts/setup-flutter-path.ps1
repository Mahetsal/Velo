param(
  [Parameter(Mandatory = $false)]
  [string]$FlutterRoot = "$HOME\flutter"
)

$ErrorActionPreference = "Stop"

$flutterBin = Join-Path $FlutterRoot "bin"
$flutterBat = Join-Path $flutterBin "flutter.bat"

if (-not (Test-Path $flutterBat)) {
  throw "Flutter executable not found at '$flutterBat'. Install Flutter there or pass -FlutterRoot."
}

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not $userPath) { $userPath = "" }

$segments = $userPath.Split(";") | Where-Object { $_ -and $_.Trim() -ne "" }
if ($segments -notcontains $flutterBin) {
  $newUserPath = (($segments + $flutterBin) -join ";")
  [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
  Write-Host "Added '$flutterBin' to User PATH."
} else {
  Write-Host "Flutter bin already in User PATH."
}

if (($env:Path.Split(";")) -notcontains $flutterBin) {
  $env:Path = "$env:Path;$flutterBin"
  Write-Host "Added '$flutterBin' to current session PATH."
}

Write-Host "Running flutter --version..."
& $flutterBat --version

Write-Host ""
Write-Host "Done. Open a new terminal so PATH refreshes everywhere."
