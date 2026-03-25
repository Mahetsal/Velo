# Velo APK S3 Static Site

Modern static download portal for your Velo Android apps, ready to deploy to an S3 static website.

## Included

- Branded page with your `velo_logo.png`
- Personalized cards for:
  - Velo User App
  - Velo Driver App
  - Velo Admin App
- Config-driven app manifest in `apps.json`
- One-command deployment script: `deploy.ps1`

## 1) Add APK files

Place your APK files here:

- `s3-apk-site/apks/velo-users.apk`
- `s3-apk-site/apks/velo-drivers.apk`
- `s3-apk-site/apks/velo-admin.apk`

If your file names are different, update `s3-apk-site/apps.json`.

## 2) Update metadata

Edit `s3-apk-site/apps.json` and set the latest:

- `version`
- `buildDate`
- `apkPath`

## 3) Deploy to S3

Prerequisites:

- AWS CLI installed and configured (`aws configure`)
- IAM permissions for S3 bucket create/update and policy updates

Run in PowerShell:

```powershell
cd .\s3-apk-site
.\deploy.ps1 -BucketName "your-unique-velo-apk-bucket" -Region "us-east-1"
```

The script will:

- Copy `../velo_logo.png` into `assets/velo_logo.png`
- Create bucket (if needed)
- Enable static website hosting
- Apply public read policy for APK downloads
- Upload site files
- Print bucket public-access verification output

## 4) Verify bucket is public

After deploy, confirm:

- `Bucket policy public: True`
- `BlockPublicAcls: False`
- `IgnorePublicAcls: False`
- `BlockPublicPolicy: False`
- `RestrictPublicBuckets: False`

If it still is not public, check **account-level** S3 Public Access Block in AWS account settings and disable:

- `BlockPublicPolicy`
- `RestrictPublicBuckets`

## Optional custom domain

For HTTPS + custom domain, place CloudFront in front of this bucket and point Route 53 DNS to it.
