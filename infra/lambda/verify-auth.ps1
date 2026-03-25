param(
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

function Join-ApiUrl {
  param([string]$Base, [string]$Path)
  $b = $Base.TrimEnd("/")
  $p = $Path.TrimStart("/")
  return "$b/$p"
}

function Invoke-JsonPost {
  param([string]$Url, [hashtable]$Body, [hashtable]$Headers = @{})
  $json = $Body | ConvertTo-Json -Depth 10
  try {
    $resp = Invoke-RestMethod -Method Post -Uri $Url -ContentType "application/json" -Body $json -Headers $Headers
    return @{
      ok = $true
      body = $resp
    }
  } catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $responseText = ""
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
      $responseText = $_.ErrorDetails.Message
    }
    return @{
      ok = $false
      status = $statusCode
      error = $responseText
    }
  }
}

function Invoke-JsonGet {
  param([string]$Url, [hashtable]$Headers = @{})
  try {
    $resp = Invoke-RestMethod -Method Get -Uri $Url -Headers $Headers
    return @{
      ok = $true
      body = $resp
    }
  } catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $responseText = ""
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
      $responseText = $_.ErrorDetails.Message
    }
    return @{
      ok = $false
      status = $statusCode
      error = $responseText
    }
  }
}

$signUpUrl = Join-ApiUrl $BaseUrl "/auth/sign-up"
$signInUrl = Join-ApiUrl $BaseUrl "/auth/sign-in"
$refreshUrl = Join-ApiUrl $BaseUrl "/auth/refresh"
$meUrl = Join-ApiUrl $BaseUrl "/auth/me"

Write-Host "1) POST /auth/sign-up"
$signUpBody = @{
  username = $Username
  password = $Password
}
if ($Email) { $signUpBody.email = $Email }
if ($Phone) { $signUpBody.phone = $Phone }
$signup = Invoke-JsonPost -Url $signUpUrl -Body $signUpBody
if ($signup.ok) {
  Write-Host "   OK"
} else {
  Write-Host "   Failed with status $($signup.status): $($signup.error)"
  Write-Host "   Continuing (user may already exist)."
}

if ($UserPoolId) {
  Write-Host "   Ensuring test user is confirmed..."
  aws cognito-idp admin-confirm-sign-up --user-pool-id $UserPoolId --username $Username --region $Region | Out-Null
  if ($LASTEXITCODE -eq 0) {
    Write-Host "   Confirmed"
  } else {
    Write-Host "   Confirm failed."
  }
}

Write-Host "2) POST /auth/sign-in"
$signin = Invoke-JsonPost -Url $signInUrl -Body @{
  username = $Username
  password = $Password
}
if (-not $signin.ok) {
  throw "Sign-in failed with status $($signin.status): $($signin.error)"
}
Write-Host "   OK"

$auth = $signin.body.auth
$accessToken = $auth.AccessToken
$refreshToken = $auth.RefreshToken

if (-not $accessToken) {
  throw "Sign-in succeeded but AccessToken missing."
}
if (-not $refreshToken) {
  Write-Warning "RefreshToken missing. Refresh check may fail depending on Cognito config."
}

Write-Host "3) POST /auth/refresh"
$refresh = Invoke-JsonPost -Url $refreshUrl -Body @{
  refreshToken = $refreshToken
}
if (-not $refresh.ok) {
  throw "Refresh failed with status $($refresh.status): $($refresh.error)"
}
Write-Host "   OK"

Write-Host "4) GET /auth/me"
$me = Invoke-JsonGet -Url $meUrl -Headers @{
  Authorization = "Bearer $accessToken"
}
if (-not $me.ok) {
  throw "Me failed with status $($me.status): $($me.error)"
}
Write-Host "   OK"

Write-Host ""
Write-Host "Auth verification passed." -ForegroundColor Green

