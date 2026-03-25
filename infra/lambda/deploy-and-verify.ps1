param(
  [Parameter(Mandatory = $true)]
  [string]$FunctionName,

  [Parameter(Mandatory = $true)]
  [string]$BaseUrl,

  [Parameter(Mandatory = $true)]
  [string]$Username,

  [Parameter(Mandatory = $true)]
  [string]$Password,

  [Parameter(Mandatory = $false)]
  [string]$Region = "us-east-1",

  [Parameter(Mandatory = $false)]
  [string]$Email = "",

  [Parameter(Mandatory = $false)]
  [string]$Phone = "",

  [Parameter(Mandatory = $false)]
  [string]$UserPoolId = ""
)

$ErrorActionPreference = "Stop"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Deploying Lambda code..."
powershell -ExecutionPolicy Bypass -File (Join-Path $ScriptRoot "deploy.ps1") `
  -FunctionName $FunctionName `
  -Region $Region `
  -Publish

Write-Host ""
Write-Host "Running auth verification..."
powershell -ExecutionPolicy Bypass -File (Join-Path $ScriptRoot "verify-auth.ps1") `
  -BaseUrl $BaseUrl `
  -Username $Username `
  -Password $Password `
  -Email $Email `
  -Phone $Phone `
  -UserPoolId $UserPoolId `
  -Region $Region

