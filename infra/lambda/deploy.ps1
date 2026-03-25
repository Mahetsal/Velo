param(
  [Parameter(Mandatory = $true)]
  [string]$FunctionName,

  [Parameter(Mandatory = $false)]
  [string]$Region = "us-east-1",

  [Parameter(Mandatory = $false)]
  [string]$HandlerFile = "handler.py",

  [Parameter(Mandatory = $false)]
  [switch]$Publish
)

$ErrorActionPreference = "Stop"

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ZipPath = Join-Path $ScriptRoot "lambda.zip"
$HandlerPath = Join-Path $ScriptRoot $HandlerFile

if (-not (Test-Path $HandlerPath)) {
  throw "Handler file not found: $HandlerPath"
}

Write-Host "Packaging Lambda artifact..."
if (Test-Path $ZipPath) {
  Remove-Item -Path $ZipPath -Force
}

Compress-Archive -Path $HandlerPath -DestinationPath $ZipPath -Force

Write-Host "Updating Lambda function code..."
$publishFlag = if ($Publish) { "--publish" } else { "" }
$updateResult = aws lambda update-function-code `
  --function-name $FunctionName `
  --zip-file "fileb://$ZipPath" `
  --region $Region `
  $publishFlag | ConvertFrom-Json

Write-Host "Waiting for update to complete..."
aws lambda wait function-updated `
  --function-name $FunctionName `
  --region $Region

$cfg = aws lambda get-function-configuration `
  --function-name $FunctionName `
  --region $Region | ConvertFrom-Json

Write-Host ""
Write-Host "Lambda deployed." -ForegroundColor Green
Write-Host "Function:" $cfg.FunctionName
Write-Host "LastModified:" $cfg.LastModified
Write-Host "Version:" $cfg.Version
Write-Host "LastUpdateStatus:" $cfg.LastUpdateStatus
Write-Host "CodeSha256:" $cfg.CodeSha256

