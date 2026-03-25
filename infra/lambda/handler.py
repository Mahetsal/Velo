import json
import os
import base64
import hashlib
import hmac
import secrets
from decimal import Decimal
from urllib.parse import unquote
import uuid

import boto3
from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource("dynamodb")
USERS_TABLE = os.environ.get("USERS_TABLE", "velo-users")
DRIVERS_TABLE = os.environ.get("DRIVERS_TABLE", "velo-drivers")
TRIPS_TABLE = os.environ.get("TRIPS_TABLE", "velo-trips")
PROMOS_TABLE = os.environ.get("PROMOS_TABLE", "velo-promos")
SETTINGS_TABLE = os.environ.get("SETTINGS_TABLE", "velo-settings")
UPLOAD_BUCKET = os.environ.get("UPLOAD_BUCKET", "")
COGNITO_CLIENT_ID = os.environ.get("COGNITO_USER_POOL_CLIENT_ID", "")
COGNITO_USER_POOL_ID = os.environ.get("COGNITO_USER_POOL_ID", "")
s3_client = boto3.client("s3")
cognito = boto3.client("cognito-idp")


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type,Authorization",
        },
        "body": json.dumps(body),
    }


def _authorization_token(event):
    headers = event.get("headers", {}) or {}
    auth_header = headers.get("authorization") or headers.get("Authorization") or ""
    if not auth_header.startswith("Bearer "):
        return None
    return auth_header.replace("Bearer ", "", 1).strip()


def _get_auth_context(event):
    token = _authorization_token(event)
    if not token:
        return None
    try:
        user = cognito.get_user(AccessToken=token)
        username = user.get("Username")
        attrs = {a["Name"]: a["Value"] for a in user.get("UserAttributes", [])}
        groups = []
        if COGNITO_USER_POOL_ID and username:
            try:
                group_result = cognito.admin_list_groups_for_user(
                    UserPoolId=COGNITO_USER_POOL_ID,
                    Username=username,
                )
                groups = [g.get("GroupName", "") for g in group_result.get("Groups", [])]
            except ClientError:
                groups = []
        return {
            "username": username,
            "attributes": attrs,
            "groups": groups,
            "accessToken": token,
        }
    except ClientError:
        return None


def _require_auth(event):
    if not COGNITO_CLIENT_ID:
        return {"username": "public", "groups": ["admin"]}, None
    ctx = _get_auth_context(event)
    if not ctx:
        return None, _response(401, {"error": "Unauthorized"})
    return ctx, None


def _require_admin(event):
    if not COGNITO_CLIENT_ID:
        return {"username": "public", "groups": ["admin"]}, None
    ctx, err = _require_auth(event)
    if err:
        return None, err
    if "admin" not in ctx.get("groups", []):
        return None, _response(403, {"error": "Admin role required"})
    return ctx, None


def _json_body(event):
    body = event.get("body")
    if not body:
        return {}
    try:
        return json.loads(body, parse_float=Decimal)
    except json.JSONDecodeError:
        return {}


def _path_parts(event):
    raw_path = (event.get("rawPath") or "").strip()
    parts = [p for p in raw_path.split("/") if p]
    if not parts:
        return parts

    # Some API Gateway configurations prepend stage/base path segments.
    stage = (event.get("requestContext", {}).get("stage") or "").strip()
    base_path = (os.environ.get("API_BASE_PATH") or "").strip().strip("/")

    if stage and parts and parts[0] == stage:
        parts = parts[1:]
    if base_path:
        base_segments = [p for p in base_path.split("/") if p]
        if parts[: len(base_segments)] == base_segments:
            parts = parts[len(base_segments) :]
    return parts


def _get_table(entity):
    if entity == "users":
        return dynamodb.Table(USERS_TABLE), "phone"
    if entity == "drivers":
        return dynamodb.Table(DRIVERS_TABLE), "phoneNumber"
    if entity == "trips":
        return dynamodb.Table(TRIPS_TABLE), None
    if entity == "promos":
        return dynamodb.Table(PROMOS_TABLE), None
    if entity == "settings":
        return dynamodb.Table(SETTINGS_TABLE), None
    return None, None


def _query_by_index(table, index_name, key_name, value):
    result = table.query(
        IndexName=index_name,
        KeyConditionExpression=Key(key_name).eq(value),
        Limit=1,
    )
    items = result.get("Items", [])
    return items[0] if items else None


def _scan_all_items(table):
    items = []
    result = table.scan()
    items.extend(result.get("Items", []))
    while "LastEvaluatedKey" in result:
        result = table.scan(ExclusiveStartKey=result["LastEvaluatedKey"])
        items.extend(result.get("Items", []))
    return items


def _normalize_user_item(item):
    merged = dict(item or {})
    merged.setdefault("name", "")
    merged.setdefault("email", "")
    merged.setdefault("phone", "")
    merged.setdefault("blockStatus", "no")
    merged.setdefault("activeStatus", "active")
    merged.setdefault("walletBalance", "0")
    merged.setdefault("walletTransactions", [])
    merged.setdefault("usedPromoCodes", [])
    merged.setdefault("passwordHash", "")
    merged.setdefault("passwordSalt", "")
    return merged


def _public_user_item(item):
    if not item:
        return item
    safe = dict(item)
    safe.pop("passwordHash", None)
    safe.pop("passwordSalt", None)
    return safe


def _hash_password(password, salt_b64=None):
    if not password:
        return "", ""
    if salt_b64:
        salt = base64.b64decode(salt_b64.encode("utf-8"))
    else:
        salt = secrets.token_bytes(16)
        salt_b64 = base64.b64encode(salt).decode("utf-8")
    digest = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt,
        120000,
    )
    digest_b64 = base64.b64encode(digest).decode("utf-8")
    return digest_b64, salt_b64


def _verify_password(password, expected_hash, salt_b64):
    if not password or not expected_hash or not salt_b64:
        return False
    candidate_hash, _ = _hash_password(password, salt_b64)
    return hmac.compare_digest(candidate_hash, expected_hash)


def _normalize_driver_item(item):
    merged = dict(item or {})
    merged.setdefault("firstName", "")
    merged.setdefault("secondName", "")
    merged.setdefault("email", "")
    merged.setdefault("phoneNumber", merged.get("phone", ""))
    merged.setdefault("blockStatus", "no")
    merged.setdefault("activeStatus", "active")
    merged.setdefault("approvalStatus", "pending")
    merged.setdefault("earnings", "0")
    merged.setdefault("driverRattings", "0")
    merged.setdefault("walletBalance", "0")
    merged.setdefault("walletTransactions", [])
    merged.setdefault(
        "vehicleInfo",
        {
            "type": "",
            "brand": "",
            "color": "",
            "productionYear": "",
            "vehiclePicture": "",
            "registrationPlateNumber": "",
            "registrationCertificateFrontImage": "",
            "registrationCertificateBackImage": "",
        },
    )
    merged.setdefault(
        "monthlySubscription",
        {
            "isActive": False,
            "plan": "monthly",
            "status": "inactive",
            "paymentMethod": "",
            "startDate": "",
            "lastPaymentDate": "",
            "nextDueDate": "",
        },
    )
    return merged


def _normalize_promo_item(item):
    merged = dict(item or {})
    merged.setdefault("code", "")
    merged.setdefault("description", "")
    merged.setdefault("discountType", "percent")
    merged.setdefault("discountValue", "0")
    merged.setdefault("maxDiscountAmount", "0")
    merged.setdefault("minTripAmount", "0")
    merged.setdefault("validFrom", "")
    merged.setdefault("validTill", "")
    merged.setdefault("usageLimit", 0)
    merged.setdefault("usedCount", 0)
    merged.setdefault("isActive", True)
    merged.setdefault("scope", "rider")
    merged.setdefault("usedByUsers", [])
    merged.setdefault("targetType", "all")
    merged.setdefault("eligibleUserIds", [])
    merged.setdefault("auditTrail", [])
    merged.setdefault("deleted", False)
    return merged


def _normalize_settings_item(item):
    merged = dict(item or {})
    merged.setdefault("title", "Terms and Conditions")
    merged.setdefault("content", "")
    merged.setdefault("version", "1.0")
    merged.setdefault("updatedAt", "")
    return merged


def _normalize_item(entity, item):
    if entity == "users":
        return _normalize_user_item(item)
    if entity == "drivers":
        return _normalize_driver_item(item)
    if entity == "promos":
        return _normalize_promo_item(item)
    if entity == "settings":
        return _normalize_settings_item(item)
    return item


def _append_promo_audit(promo_item, action, actor="admin", details=None):
    trail = list(promo_item.get("auditTrail", []))
    trail.insert(
        0,
        {
            "action": action,
            "actor": actor,
            "createdAt": __import__("datetime").datetime.utcnow().isoformat(),
            "details": details or {},
        },
    )
    promo_item["auditTrail"] = trail[:200]
    return promo_item


def _auth_signup(event):
    if not COGNITO_CLIENT_ID:
        return _response(500, {"error": "COGNITO_USER_POOL_CLIENT_ID is not configured"})
    data = _json_body(event)
    username = (data.get("username") or "").strip()
    password = (data.get("password") or "").strip()
    role = (data.get("role") or "user").strip()
    email = (data.get("email") or "").strip()
    phone = (data.get("phone") or "").strip()
    if not username or not password:
        return _response(400, {"error": "username and password are required"})
    if not email or not phone:
        return _response(400, {"error": "email and phone are required"})
    attrs = []
    if email:
        attrs.append({"Name": "email", "Value": email})
    attrs.append({"Name": "phone_number", "Value": phone})
    try:
        resp = cognito.sign_up(
            ClientId=COGNITO_CLIENT_ID,
            Username=username,
            Password=password,
            UserAttributes=attrs,
        )
        if COGNITO_USER_POOL_ID and role in {"user", "driver", "admin"}:
            try:
                cognito.admin_add_user_to_group(
                    UserPoolId=COGNITO_USER_POOL_ID,
                    Username=username,
                    GroupName=role,
                )
            except ClientError:
                pass
        return _response(
            200,
            {
                "ok": True,
                "username": username,
                "userConfirmed": resp.get("UserConfirmed", False),
                "codeDelivery": resp.get("CodeDeliveryDetails", {}),
            },
        )
    except ClientError as e:
        return _response(400, {"error": e.response.get("Error", {}).get("Message", "Signup failed")})


def _auth_signin(event):
    if not COGNITO_CLIENT_ID:
        return _response(500, {"error": "COGNITO_USER_POOL_CLIENT_ID is not configured"})
    data = _json_body(event)
    username = (data.get("username") or "").strip()
    password = (data.get("password") or "").strip()
    if not username or not password:
        return _response(400, {"error": "username and password are required"})
    try:
        resp = cognito.initiate_auth(
            ClientId=COGNITO_CLIENT_ID,
            AuthFlow="USER_PASSWORD_AUTH",
            AuthParameters={"USERNAME": username, "PASSWORD": password},
        )
        return _response(200, {"ok": True, "auth": resp.get("AuthenticationResult", {})})
    except ClientError as e:
        return _response(401, {"error": e.response.get("Error", {}).get("Message", "Signin failed")})


def _auth_refresh(event):
    if not COGNITO_CLIENT_ID:
        return _response(500, {"error": "COGNITO_USER_POOL_CLIENT_ID is not configured"})
    data = _json_body(event)
    refresh_token = (data.get("refreshToken") or "").strip()
    if not refresh_token:
        return _response(400, {"error": "refreshToken is required"})
    try:
        resp = cognito.initiate_auth(
            ClientId=COGNITO_CLIENT_ID,
            AuthFlow="REFRESH_TOKEN_AUTH",
            AuthParameters={"REFRESH_TOKEN": refresh_token},
        )
        return _response(200, {"ok": True, "auth": resp.get("AuthenticationResult", {})})
    except ClientError as e:
        return _response(401, {"error": e.response.get("Error", {}).get("Message", "Refresh failed")})


def _auth_me(event):
    ctx, err = _require_auth(event)
    if err:
        return err
    return _response(200, {"ok": True, "user": ctx})


def lambda_handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "")

    if method == "OPTIONS":
        return _response(200, {"ok": True})

    parts = _path_parts(event)
    # Expected paths:
    # /users
    # /users/{id}
    # /users/by-email/{email}
    # /users/by-phone/{phone}
    # /drivers
    # /drivers/{id}
    # /drivers/by-email/{email}
    # /drivers/by-phone/{phone}
    if not parts:
        return _response(200, {"service": "velo-api", "ok": True})

    if parts[0] == "auth":
        if method == "POST" and len(parts) == 2 and parts[1] == "sign-up":
            return _auth_signup(event)
        if method == "POST" and len(parts) == 2 and parts[1] == "sign-in":
            return _auth_signin(event)
        if method == "POST" and len(parts) == 2 and parts[1] == "refresh":
            return _auth_refresh(event)
        if method == "GET" and len(parts) == 2 and parts[1] == "me":
            return _auth_me(event)
        return _response(404, {"error": "Not found"})

    if parts[0] == "uploads" and method == "POST" and len(parts) == 2 and parts[1] == "presign":
        _, auth_err = _require_auth(event)
        if auth_err:
            return auth_err
        if not UPLOAD_BUCKET:
            return _response(500, {"error": "UPLOAD_BUCKET is not configured"})
        data = _json_body(event)
        filename = data.get("filename", "upload.bin")
        folder = data.get("folder", "uploads")
        object_key = f"{folder}/{uuid.uuid4()}-{filename}"
        content_type = data.get("contentType", "application/octet-stream")
        upload_url = s3_client.generate_presigned_url(
            "put_object",
            Params={
                "Bucket": UPLOAD_BUCKET,
                "Key": object_key,
                "ContentType": content_type,
            },
            ExpiresIn=900,
        )
        public_url = f"https://{UPLOAD_BUCKET}.s3.amazonaws.com/{object_key}"
        return _response(
            200,
            {
                "uploadUrl": upload_url,
                "publicUrl": public_url,
                "objectKey": object_key,
            },
        )

    entity = parts[0]
    table, phone_key = _get_table(entity)
    if table is None:
        return _response(404, {"error": "Not found"})

    if method == "GET" and len(parts) == 1:
        if entity in {"promos", "settings"}:
            _, auth_err = _require_auth(event)
            if auth_err:
                return auth_err
            return _response(200, {"items": _scan_all_items(table)})
        ctx, auth_err = _require_admin(event)
        if auth_err:
            return auth_err
        _ = ctx
        items = _scan_all_items(table)
        if entity == "users":
            items = [_public_user_item(i) for i in items]
        return _response(200, {"items": items})

    if method == "POST" and entity == "users" and len(parts) == 2 and parts[1] == "login":
        data = _json_body(event)
        phone = (data.get("phone") or "").strip()
        password = (data.get("password") or "").strip()
        if not phone or not password:
            return _response(400, {"error": "phone and password are required"})
        item = _query_by_index(table, "phone-index", "phone", phone)
        if not item:
            return _response(401, {"error": "Invalid credentials"})
        if not _verify_password(
            password,
            (item.get("passwordHash") or "").strip(),
            (item.get("passwordSalt") or "").strip(),
        ):
            return _response(401, {"error": "Invalid credentials"})
        return _response(200, {"ok": True, "item": _public_user_item(item)})

    if method == "POST" and entity == "users" and len(parts) == 2 and parts[1] == "reset-password":
        data = _json_body(event)
        phone = (data.get("phone") or "").strip()
        new_password = (data.get("newPassword") or "").strip()
        if not phone or not new_password:
            return _response(400, {"error": "phone and newPassword are required"})
        if len(new_password) < 6:
            return _response(400, {"error": "Password must be at least 6 characters"})
        item = _query_by_index(table, "phone-index", "phone", phone)
        if not item:
            return _response(404, {"error": "Account not found"})
        pwd_hash, pwd_salt = _hash_password(new_password)
        item["passwordHash"] = pwd_hash
        item["passwordSalt"] = pwd_salt
        item = _normalize_user_item(item)
        table.put_item(Item=item)
        return _response(200, {"ok": True, "message": "Password reset successful"})

    if method == "POST" and len(parts) == 1:
        if entity in {"promos", "settings"}:
            _, auth_err = _require_admin(event)
        else:
            _, auth_err = _require_auth(event)
        if auth_err:
            return auth_err
        data = _json_body(event)
        if entity == "users":
            plain_password = (data.pop("password", "") or "").strip()
            if plain_password:
                pwd_hash, pwd_salt = _hash_password(plain_password)
                data["passwordHash"] = pwd_hash
                data["passwordSalt"] = pwd_salt
        item_id = data.get("id") or str(uuid.uuid4())
        data["id"] = item_id
        data = _normalize_item(entity, data)
        if not item_id:
            return _response(400, {"error": "id is required"})
        if entity == "promos":
            data = _append_promo_audit(data, "create", "admin", {"code": data.get("code", "")})
        table.put_item(Item=data)
        return _response(200, {"ok": True, "id": item_id})

    if method == "PUT" and len(parts) == 2:
        if entity in {"promos", "settings"}:
            _, auth_err = _require_admin(event)
        else:
            _, auth_err = _require_auth(event)
        if auth_err:
            return auth_err
        item_id = unquote(parts[1])
        existing = table.get_item(Key={"id": item_id}).get("Item")
        if not existing:
            return _response(404, {"error": "Not found"})
        data = _json_body(event)
        if entity == "users":
            plain_password = (data.pop("password", "") or "").strip()
            if plain_password:
                pwd_hash, pwd_salt = _hash_password(plain_password)
                data["passwordHash"] = pwd_hash
                data["passwordSalt"] = pwd_salt
        merged = {**existing, **data, "id": item_id}
        merged = _normalize_item(entity, merged)
        if entity == "promos":
            merged = _append_promo_audit(
                merged,
                "update",
                "admin",
                {
                    "fields": list(data.keys()),
                },
            )
        table.put_item(Item=merged)
        return _response(200, {"ok": True, "id": item_id})

    if method == "DELETE" and len(parts) == 2:
        if entity in {"promos", "settings"}:
            _, auth_err = _require_admin(event)
        else:
            _, auth_err = _require_auth(event)
        if auth_err:
            return auth_err
        item_id = unquote(parts[1])
        if entity == "promos":
            existing = table.get_item(Key={"id": item_id}).get("Item")
            if existing:
                existing = _normalize_promo_item(existing)
                existing["isActive"] = False
                existing["deleted"] = True
                existing = _append_promo_audit(existing, "delete", "admin")
                table.put_item(Item=existing)
            else:
                table.delete_item(Key={"id": item_id})
        else:
            table.delete_item(Key={"id": item_id})
        return _response(200, {"ok": True, "id": item_id})

    if method == "GET" and len(parts) == 2:
        item_id = unquote(parts[1])
        item = table.get_item(Key={"id": item_id}).get("Item")
        if entity == "users" and item:
            item = _public_user_item(item)
        return _response(200, {"exists": item is not None, "item": item})

    if method == "GET" and len(parts) == 3 and parts[1] == "by-email":
        email = unquote(parts[2])
        item = _query_by_index(table, "email-index", "email", email)
        if entity == "users" and item:
            item = _public_user_item(item)
        return _response(200, {"exists": item is not None, "item": item})

    if method == "GET" and len(parts) == 3 and parts[1] == "by-phone":
        phone = unquote(parts[2])
        item = _query_by_index(table, "phone-index", phone_key, phone)
        if entity == "users" and item:
            item = _public_user_item(item)
        return _response(200, {"exists": item is not None, "item": item})

    if method == "GET" and entity == "promos" and len(parts) == 3 and parts[1] == "by-code":
        _, auth_err = _require_auth(event)
        if auth_err:
            return auth_err
        code = unquote(parts[2]).upper()
        items = _scan_all_items(table)
        match = None
        for promo in items:
            if (promo.get("code", "") or "").upper() == code:
                match = promo
                break
        return _response(200, {"exists": match is not None, "item": match})

    if method == "POST" and entity == "promos" and len(parts) == 2 and parts[1] == "consume":
        _, auth_err = _require_auth(event)
        if auth_err:
            return auth_err
        data = _json_body(event)
        code = (data.get("code") or "").upper().strip()
        user_id = (data.get("userId") or "").strip()
        if not code or not user_id:
            return _response(400, {"error": "code and userId are required"})

        promos_table = dynamodb.Table(PROMOS_TABLE)
        users_table = dynamodb.Table(USERS_TABLE)
        promos = _scan_all_items(promos_table)
        promo = None
        for p in promos:
            if (p.get("code", "") or "").upper() == code:
                promo = p
                break
        if promo is None:
            return _response(404, {"error": "Promo not found"})

        if promo.get("isActive") is not True:
            return _response(400, {"error": "Promo inactive"})

        valid_till = (promo.get("validTill") or "").strip()
        if valid_till:
            from datetime import datetime

            try:
                if datetime.utcnow() > datetime.fromisoformat(valid_till.replace("Z", "+00:00")).replace(tzinfo=None):
                    return _response(400, {"error": "Promo expired"})
            except Exception:
                pass

        user_item = users_table.get_item(Key={"id": user_id}).get("Item")
        if not user_item:
            return _response(404, {"error": "User not found"})
        user_item = _normalize_user_item(user_item)
        used_codes = [str(c).upper() for c in user_item.get("usedPromoCodes", [])]
        if code in used_codes:
            return _response(400, {"error": "Promo already used by this user"})

        used_codes.append(code)
        user_item["usedPromoCodes"] = used_codes
        users_table.put_item(Item=user_item)

        used_by_users = [str(x) for x in promo.get("usedByUsers", [])]
        if user_id not in used_by_users:
            used_by_users.append(user_id)
        promo["usedByUsers"] = used_by_users
        promo["usedCount"] = int(promo.get("usedCount", 0) or 0) + 1
        promo = _append_promo_audit(
            promo,
            "consume",
            "system",
            {"userId": user_id, "code": code},
        )
        promo = _normalize_promo_item(promo)
        promos_table.put_item(Item=promo)
        return _response(200, {"ok": True, "code": code, "userId": user_id})

    if method == "GET" and entity == "trips" and len(parts) == 3 and parts[1] == "by-user":
        user_id = unquote(parts[2])
        result = table.query(
            IndexName="userID-index",
            KeyConditionExpression=Key("userID").eq(user_id),
        )
        return _response(200, {"items": result.get("Items", [])})

    if method == "GET" and entity == "trips" and len(parts) == 3 and parts[1] == "by-driver":
        driver_id = unquote(parts[2])
        result = table.query(
            IndexName="driverId-index",
            KeyConditionExpression=Key("driverId").eq(driver_id),
        )
        return _response(200, {"items": result.get("Items", [])})

    return _response(404, {"error": "Not found"})
