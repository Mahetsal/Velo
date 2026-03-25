# Lambda Deploy and Auth Verification

Use this when production is still returning old routes (for example `404` on `POST /auth/sign-in`).

## Prerequisites

- AWS CLI installed and authenticated (`aws configure` or SSO profile).
- Correct AWS region and Lambda function name.
- `infra/lambda/handler.py` has the latest code.

## 1) Deploy latest handler code

From repo root:

```powershell
powershell -ExecutionPolicy Bypass -File .\infra\lambda\deploy.ps1 `
  -FunctionName "<YOUR_LAMBDA_FUNCTION_NAME>" `
  -Region "us-east-1" `
  -Publish
```

## 2) Get your live endpoint base URL

### Lambda Function URL

```powershell
aws lambda get-function-url-config `
  --function-name "<YOUR_LAMBDA_FUNCTION_NAME>" `
  --region "us-east-1"
```

Use the returned `FunctionUrl` value as `BaseUrl`.

### API Gateway HTTP API

```powershell
aws apigatewayv2 get-apis --region "us-east-1"
```

Base URL is usually:

`https://<api-id>.execute-api.<region>.amazonaws.com`

If your API uses a stage/base path, include it in `BaseUrl` (for example `/prod`).

## 3) Run auth verification

```powershell
powershell -ExecutionPolicy Bypass -File .\infra\lambda\verify-auth.ps1 `
  -BaseUrl "<LIVE_BASE_URL>" `
  -Username "deploy_test_user@example.com" `
  -Password "YourStrongPassword123!" `
  -Email "deploy_test_user@example.com" `
  -Phone "+15550001234" `
  -UserPoolId "us-east-1_XXXXXXXXX"
```

This checks:

- `POST /auth/sign-up`
- `POST /auth/sign-in`
- `POST /auth/refresh`
- `GET /auth/me`

## 4) Verify phone+password user login/reset flow

```powershell
powershell -ExecutionPolicy Bypass -File .\infra\lambda\verify-user-password.ps1 `
  -BaseUrl "<LIVE_BASE_URL>" `
  -Phone "+9627XXXXXXXX" `
  -InitialPassword "OldOrExpectedPassword123!" `
  -NewPassword "NewPassword123!"
```

This checks:

- `POST /users/login`
- `POST /users/reset-password`
- `POST /users/login` (with updated password)

## One-command deploy + verify

```powershell
powershell -ExecutionPolicy Bypass -File .\infra\lambda\deploy-and-verify.ps1 `
  -FunctionName "<YOUR_LAMBDA_FUNCTION_NAME>" `
  -Region "us-east-1" `
  -BaseUrl "<LIVE_BASE_URL>" `
  -Username "deploy_test_user@example.com" `
  -Password "YourStrongPassword123!" `
  -Email "deploy_test_user@example.com" `
  -Phone "+15550001234" `
  -UserPoolId "us-east-1_XXXXXXXXX"
```

## Notes

- `sign-up` may fail if user already exists; script continues in that case.
- `sign-in`, `refresh`, and `me` are required to pass.
- Legacy users with no stored password hash can use `POST /users/reset-password` to initialize credentials.
- If API Gateway prepends stage/base path segments, `handler.py` now normalizes those prefixes to avoid false `404` route misses.

