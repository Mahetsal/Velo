param(
  [Parameter(Mandatory = $true)]
  [string]$BucketName,

  [Parameter(Mandatory = $false)]
  [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceRoot = Split-Path -Parent $ScriptRoot
$LogoSource = Join-Path $WorkspaceRoot "velo_logo.png"
$AssetsDir = Join-Path $ScriptRoot "assets"
$ApkDir = Join-Path $ScriptRoot "apks"

if (-not (Test-Path $AssetsDir)) {
  New-Item -ItemType Directory -Path $AssetsDir | Out-Null
}

if (-not (Test-Path $ApkDir)) {
  New-Item -ItemType Directory -Path $ApkDir | Out-Null
}

if (Test-Path $LogoSource) {
  Copy-Item -Path $LogoSource -Destination (Join-Path $AssetsDir "velo_logo.png") -Force
} else {
  Write-Warning "Logo not found at $LogoSource. Add assets/velo_logo.png manually."
}

Write-Host "Creating bucket if missing..."
try {
  if ($Region -eq "us-east-1") {
    aws s3api create-bucket --bucket $BucketName 2>$null | Out-Null
  } else {
    aws s3api create-bucket --bucket $BucketName --region $Region --create-bucket-configuration LocationConstraint=$Region 2>$null | Out-Null
  }
} catch {
  Write-Host "Bucket likely already exists, continuing..."
}

$Policy = @{
  Version = "2012-10-17"
  Statement = @(
    @{
      Sid = "PublicReadGetObject"
      Effect = "Allow"
      Principal = "*"
      Action = "s3:GetObject"
      Resource = "arn:aws:s3:::$BucketName/*"
    }
  )
} | ConvertTo-Json -Depth 5 -Compress

Write-Host "Disabling block public access..."
aws s3api put-public-access-block `
  --bucket $BucketName `
  --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false | Out-Null

Write-Host "Applying bucket policy..."
aws s3api put-bucket-policy --bucket $BucketName --policy $Policy | Out-Null

Write-Host "Configuring static website hosting..."
aws s3 website "s3://$BucketName/" --index-document index.html --error-document index.html | Out-Null

Write-Host "Uploading site..."
aws s3 sync $ScriptRoot "s3://$BucketName/" --delete --exclude "deploy.ps1" --exclude "README.md" | Out-Null

Write-Host "Verifying public access status..."
$PublicBlock = aws s3api get-public-access-block --bucket $BucketName | ConvertFrom-Json
$PolicyStatus = aws s3api get-bucket-policy-status --bucket $BucketName | ConvertFrom-Json

Write-Host "Bucket policy public:" $PolicyStatus.PolicyStatus.IsPublic
Write-Host "BlockPublicAcls:" $PublicBlock.PublicAccessBlockConfiguration.BlockPublicAcls
Write-Host "IgnorePublicAcls:" $PublicBlock.PublicAccessBlockConfiguration.IgnorePublicAcls
Write-Host "BlockPublicPolicy:" $PublicBlock.PublicAccessBlockConfiguration.BlockPublicPolicy
Write-Host "RestrictPublicBuckets:" $PublicBlock.PublicAccessBlockConfiguration.RestrictPublicBuckets

try {
  $AccountId = (aws sts get-caller-identity | ConvertFrom-Json).Account
  $AccountPublicBlock = aws s3control get-public-access-block --account-id $AccountId 2>$null | ConvertFrom-Json
  if ($AccountPublicBlock.PublicAccessBlockConfiguration.BlockPublicPolicy -or $AccountPublicBlock.PublicAccessBlockConfiguration.RestrictPublicBuckets) {
    Write-Warning "Account-level S3 Public Access Block may still prevent public bucket access. Disable account-level block settings in AWS if the site still appears private."
  }
} catch {
  Write-Host "Could not verify account-level public access block. Ensure account-level S3 block settings are disabled if access is still denied."
}

Write-Host ""
Write-Host "Site deployed successfully." -ForegroundColor Green
Write-Host "Website URL:"
Write-Host "http://$BucketName.s3-website-$Region.amazonaws.com"
