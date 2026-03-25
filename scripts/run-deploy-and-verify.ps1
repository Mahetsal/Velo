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
  [string]$Email = "",

  [Parameter(Mandatory = $false)]
  [string]$Phone = "",

  [Parameter(Mandatory = $false)]
  [string]$UserPoolId = "",

  [Parameter(Mandatory = $false)]
  [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

Write-Host "Deploying lambda..."
powershell -ExecutionPolicy Bypass -File ".\infra\lambda\deploy.ps1" `
  -FunctionName $FunctionName `
  -Region $Region `
  -Publish
if ($LASTEXITCODE -ne 0) {
  throw "Lambda deploy failed."
}

Write-Host "Running Cognito auth verification..."
powershell -ExecutionPolicy Bypass -File ".\infra\lambda\verify-auth.ps1" `
  -BaseUrl $BaseUrl `
  -Username $Username `
  -Password $Password `
  -Email $Email `
  -Phone $Phone `
  -UserPoolId $UserPoolId `
  -Region $Region
if ($LASTEXITCODE -ne 0) {
  throw "Auth verification failed."
}

if ($Phone -and $Password) {
  $newPassword = "$Password-reset"
  Write-Host "Running user password login/reset verification..."
  powershell -ExecutionPolicy Bypass -File ".\infra\lambda\verify-user-password.ps1" `
    -BaseUrl $BaseUrl `
    -Phone $Phone `
    -InitialPassword $Password `
    -NewPassword $newPassword
  if ($LASTEXITCODE -ne 0) {
    throw "User password verification failed."
  }
}

Write-Host ""
Write-Host "Deploy + verification workflow completed."
