param(
  [Parameter(Mandatory = $true)]
  [string]$BaseUrl,

  [Parameter(Mandatory = $true)]
  [string]$Phone,

  [Parameter(Mandatory = $true)]
  [string]$InitialPassword,

  [Parameter(Mandatory = $true)]
  [string]$NewPassword
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

$loginUrl = Join-ApiUrl $BaseUrl "/users/login"
$resetUrl = Join-ApiUrl $BaseUrl "/users/reset-password"

Write-Host "1) POST /users/login (existing password)"
$loginBefore = Invoke-JsonPost -Url $loginUrl -Body @{
  phone = $Phone
  password = $InitialPassword
}
if ($loginBefore.ok) {
  Write-Host "   OK"
} else {
  Write-Host "   Failed with status $($loginBefore.status): $($loginBefore.error)"
  Write-Host "   Continuing (common if account is legacy without password hash)."
}

Write-Host "2) POST /users/reset-password"
$reset = Invoke-JsonPost -Url $resetUrl -Body @{
  phone = $Phone
  newPassword = $NewPassword
}
if (-not $reset.ok) {
  throw "Reset password failed with status $($reset.status): $($reset.error)"
}
Write-Host "   OK"

Write-Host "3) POST /users/login (new password)"
$loginAfter = Invoke-JsonPost -Url $loginUrl -Body @{
  phone = $Phone
  password = $NewPassword
}
if (-not $loginAfter.ok) {
  throw "Login with new password failed with status $($loginAfter.status): $($loginAfter.error)"
}
Write-Host "   OK"

Write-Host ""
Write-Host "User password flow verification passed." -ForegroundColor Green
