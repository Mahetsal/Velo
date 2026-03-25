import os

import boto3


dynamodb = boto3.resource("dynamodb")
USERS_TABLE = os.environ.get("USERS_TABLE", "velo-users")
DRIVERS_TABLE = os.environ.get("DRIVERS_TABLE", "velo-drivers")


def _scan_all(table):
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
    return merged


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


def backfill():
    users = dynamodb.Table(USERS_TABLE)
    drivers = dynamodb.Table(DRIVERS_TABLE)

    for item in _scan_all(users):
        users.put_item(Item=_normalize_user_item(item))

    for item in _scan_all(drivers):
        drivers.put_item(Item=_normalize_driver_item(item))

    print("Backfill completed.")


if __name__ == "__main__":
    backfill()
