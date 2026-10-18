"""ポイントのAPI(手順5: アプリとの紐づけまで)

  ログインが必要なもの(API GatewayのJWTオーソライザーが、先に確認する)
    GET    /me                  ポイントとトークンの残高(初めてなら残高0で作る)
    POST   /exchange            ポイントをトークンに交換する
    POST   /dev/grant           動作確認用: ポイントを足す(本番では無効にする)
    POST   /pairing/lookup      紐づけコードから、どの端末かを確認する
    POST   /pairing/confirm     紐づけコードを確定し、端末とアカウントを結ぶ
    GET    /devices             紐づけ済みの端末の一覧
    DELETE /devices/{deviceId}  端末の紐づけを解除する

  ログインなしで呼ぶもの(アプリが呼ぶ。オーソライザーを付けない)
    POST   /pairing/start       紐づけコードを発行する
    POST   /pairing/claim       紐づけが済んだら、端末用のトークンを1回だけ渡す

誰のリクエストかは、確認済みのトークンの中の `sub`(アカウント固有のID)で分かる。

残高(accountsテーブル)の更新と、履歴(ledgerテーブル)への記録は、
DynamoDBのトランザクションで、同時に行う(片方だけ成功することがない)。
"""
import hashlib
import hmac
import json
import os
import re
import secrets
import time
import uuid

import boto3
from botocore.exceptions import ClientError

TABLE_NAME = os.environ["TABLE_NAME"]
LEDGER_TABLE_NAME = os.environ["LEDGER_TABLE_NAME"]
PAIRING_TABLE_NAME = os.environ["PAIRING_TABLE_NAME"]
DEVICES_TABLE_NAME = os.environ["DEVICES_TABLE_NAME"]

# 動作確認用の口を使えるか(環境変数で切り替える。本番では false にする)
ENABLE_DEV_GRANT = os.environ.get("ENABLE_DEV_GRANT") == "true"

# 動作確認用に、1回で足せるポイントの上限
DEV_GRANT_MAX = 100_000

# 交換のルール(変えるときは、ここだけ直す)
TOKENS_PER_POINT = 1  # 1ポイントあたりのトークン数
MIN_EXCHANGE_POINTS = 10_000  # 1回の交換で、最低限使うポイント数

# 紐づけのルール(変えるときは、ここだけ直す)
MAX_DEVICES = 3  # 1アカウントに紐づけられる端末の数
PAIRING_CODE_TTL_SECONDS = 600  # 紐づけコードの有効期間(10分)
MAX_LABEL_LENGTH = 20

dynamodb = boto3.client("dynamodb")


def response(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, ensure_ascii=False),
    }


def account_id_of(event):
    # API Gatewayが確認済みのトークンから取り出した、アカウント固有のID
    claims = event["requestContext"]["authorizer"]["jwt"]["claims"]
    return claims["sub"]


def parse_body(body):
    try:
        data = json.loads(body or "{}")
    except ValueError:
        return {}
    return data if isinstance(data, dict) else {}


def to_int(value):
    # True/Falseや小数は、整数として受け付けない
    if isinstance(value, bool) or not isinstance(value, int):
        return None
    return value


def balance_of(item):
    return {
        "points": int(item["points"]["N"]),
        "tokens": int(item["tokens"]["N"]),
        "exchange": {
            "minPoints": MIN_EXCHANGE_POINTS,
            "tokensPerPoint": TOKENS_PER_POINT,
        },
    }


def get_or_create(account_id):
    """残高を返す。アカウントの行がなければ、残高0で作る(1回の呼び出しで行う)"""
    result = dynamodb.update_item(
        TableName=TABLE_NAME,
        Key={"accountId": {"S": account_id}},
        UpdateExpression=(
            "SET points = if_not_exists(points, :zero), "
            "tokens = if_not_exists(tokens, :zero), "
            "createdAt = if_not_exists(createdAt, :now)"
        ),
        ExpressionAttributeValues={
            ":zero": {"N": "0"},
            ":now": {"N": str(int(time.time()))},
        },
        ReturnValues="ALL_NEW",
    )
    return balance_of(result["Attributes"])


def read_balance(account_id):
    # 更新した直後の値を確実に読むため、強い整合性で読む
    result = dynamodb.get_item(
        TableName=TABLE_NAME,
        Key={"accountId": {"S": account_id}},
        ConsistentRead=True,
    )
    return balance_of(result["Item"])


def change_balance(
    account_id,
    *,
    update_expression,
    values,
    condition=None,
    kind,
    points_delta,
    tokens_delta,
    request_id=None,
):
    """残高の更新と、履歴の記録を、トランザクションで同時に行う

    request_id(同じ操作を示すID)を付けると、通信の失敗などで同じリクエストが
    2回届いても、1回しか実行されない(DynamoDBが、約10分間、重複を見分ける)
    """
    now = int(time.time())

    # DynamoDBは、式の中で使っていない値が渡されると、エラーにする。
    # そのため、式に出てくる値だけを渡す。
    all_values = {
        ":zero": {"N": "0"},
        ":now": {"N": str(now)},
        **values,
    }
    expressions = update_expression + " " + (condition or "")
    used_values = {k: v for k, v in all_values.items() if k in expressions}

    update = {
        "TableName": TABLE_NAME,
        "Key": {"accountId": {"S": account_id}},
        "UpdateExpression": update_expression,
        "ExpressionAttributeValues": used_values,
    }
    if condition:
        update["ConditionExpression"] = condition

    ledger = {
        "TableName": LEDGER_TABLE_NAME,
        "Item": {
            "accountId": {"S": account_id},
            # 時刻の順に並ぶ、重複しない並べ替え用のキー
            "entryId": {"S": f"{int(time.time() * 1000):013d}#{uuid.uuid4().hex}"},
            "type": {"S": kind},
            "pointsDelta": {"N": str(points_delta)},
            "tokensDelta": {"N": str(tokens_delta)},
            "createdAt": {"N": str(now)},
        },
    }

    args = {"TransactItems": [{"Update": update}, {"Put": ledger}]}
    if request_id:
        args["ClientRequestToken"] = request_id

    dynamodb.transact_write_items(**args)


def valid_request_id(value):
    # DynamoDBの制限: 1〜36文字
    if isinstance(value, str) and 1 <= len(value) <= 36:
        return value
    return None


def exchange(account_id, body):
    data = parse_body(body)
    points = to_int(data.get("points"))

    if points is None or points <= 0:
        return response(400, {"error": "invalid_points"})

    if points < MIN_EXCHANGE_POINTS:
        return response(400, {
            "error": "below_minimum",
            "minPoints": MIN_EXCHANGE_POINTS,
        })

    tokens = points * TOKENS_PER_POINT

    try:
        change_balance(
            account_id,
            # ポイントが足りないときは、条件が満たされず、何も変わらない
            condition="points >= :points",
            update_expression=(
                "SET points = points - :points, "
                "tokens = if_not_exists(tokens, :zero) + :tokens"
            ),
            values={
                ":points": {"N": str(points)},
                ":tokens": {"N": str(tokens)},
            },
            kind="exchange",
            points_delta=-points,
            tokens_delta=tokens,
            request_id=valid_request_id(data.get("requestId")),
        )
    except ClientError as e:
        code = e.response["Error"]["Code"]

        if code == "TransactionCanceledException":
            reasons = e.response.get("CancellationReasons", [])
            if any(r.get("Code") == "ConditionalCheckFailed" for r in reasons):
                return response(400, {"error": "insufficient_points"})
        if code == "IdempotentParameterMismatchException":
            return response(409, {"error": "request_id_conflict"})
        raise

    return response(200, read_balance(account_id))


def dev_grant(account_id, body):
    if not ENABLE_DEV_GRANT:
        return response(404, {"error": "not_found"})

    data = parse_body(body)
    amount = to_int(data.get("amount"))

    if amount is None or not 1 <= amount <= DEV_GRANT_MAX:
        return response(400, {"error": f"amount must be 1..{DEV_GRANT_MAX}"})

    change_balance(
        account_id,
        update_expression=(
            "ADD points :amount "
            "SET tokens = if_not_exists(tokens, :zero), "
            "createdAt = if_not_exists(createdAt, :now)"
        ),
        values={":amount": {"N": str(amount)}},
        kind="dev_grant",
        points_delta=amount,
        tokens_delta=0,
    )
    return response(200, read_balance(account_id))


# ---------- 紐づけ(アプリとアカウントを結ぶ)

CODE_PATTERN = re.compile(r"^\d{6}$")


def sha256_hex(value):
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def clean_label(value):
    """端末の名前(例: Android)。画面に表示するので、長さと文字を制限する"""
    if not isinstance(value, str):
        return "アプリ"
    label = "".join(c for c in value if c.isprintable()).strip()
    return label[:MAX_LABEL_LENGTH] or "アプリ"


def error_code(e):
    return e.response["Error"]["Code"]


def read_pairing(code):
    """有効な(期限内の)紐づけコードの行を返す。なければ None"""
    if not isinstance(code, str) or not CODE_PATTERN.match(code):
        return None

    result = dynamodb.get_item(
        TableName=PAIRING_TABLE_NAME,
        Key={"code": {"S": code}},
        ConsistentRead=True,
    )
    item = result.get("Item")

    if not item or int(item["expiresAt"]["N"]) <= int(time.time()):
        return None
    return item


def pairing_start(body):
    """アプリが呼ぶ。紐づけコードと、アプリだけが持つ合言葉(claimSecret)を返す

    claimSecretは、あとで端末用のトークンを受け取るときに必要。
    コードを画面で見ただけの人が、横取りできないようにする。
    """
    label = clean_label(parse_body(body).get("label"))
    claim_secret = secrets.token_urlsafe(32)
    now = int(time.time())
    expires_at = now + PAIRING_CODE_TTL_SECONDS

    for _ in range(5):
        code = f"{secrets.randbelow(10**6):06d}"

        try:
            dynamodb.put_item(
                TableName=PAIRING_TABLE_NAME,
                Item={
                    "code": {"S": code},
                    "status": {"S": "pending"},
                    "claimSecretHash": {"S": sha256_hex(claim_secret)},
                    "label": {"S": label},
                    "expiresAt": {"N": str(expires_at)},
                },
                # 他の人が使用中のコードとは、重ならないようにする
                ConditionExpression="attribute_not_exists(code) OR expiresAt <= :now",
                ExpressionAttributeValues={":now": {"N": str(now)}},
            )
        except ClientError as e:
            if error_code(e) == "ConditionalCheckFailedException":
                continue
            raise

        return response(200, {
            "code": code,
            "claimSecret": claim_secret,
            "expiresAt": expires_at,
        })

    return response(503, {"error": "try_again"})


def pairing_lookup(body):
    """Webが呼ぶ。入力されたコードが、どの端末のものかを確認する(確定はしない)"""
    item = read_pairing(parse_body(body).get("code"))

    if not item or item["status"]["S"] != "pending":
        return response(404, {"error": "invalid_code"})

    return response(200, {"label": item["label"]["S"]})


def count_devices(account_id):
    result = dynamodb.query(
        TableName=DEVICES_TABLE_NAME,
        IndexName="accountId-index",
        KeyConditionExpression="accountId = :a",
        ExpressionAttributeValues={":a": {"S": account_id}},
        Select="COUNT",
    )
    return result["Count"]


def pairing_confirm(account_id, body):
    """Webが呼ぶ。ログイン中のアカウントと、コードの端末を結ぶ"""
    code = parse_body(body).get("code")

    if read_pairing(code) is None:
        return response(404, {"error": "invalid_code"})

    if count_devices(account_id) >= MAX_DEVICES:
        return response(409, {"error": "device_limit", "maxDevices": MAX_DEVICES})

    try:
        dynamodb.update_item(
            TableName=PAIRING_TABLE_NAME,
            Key={"code": {"S": code}},
            # 期限内で、まだ誰にも確定されていないコードだけが、対象
            ConditionExpression="#s = :pending AND expiresAt > :now",
            UpdateExpression="SET #s = :linked, accountId = :a",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={
                ":pending": {"S": "pending"},
                ":linked": {"S": "linked"},
                ":a": {"S": account_id},
                ":now": {"N": str(int(time.time()))},
            },
        )
    except ClientError as e:
        if error_code(e) == "ConditionalCheckFailedException":
            return response(404, {"error": "invalid_code"})
        raise

    return response(200, {"linked": True})


def pairing_claim(body):
    """アプリが呼ぶ。紐づけが済んでいれば、端末用のトークンを1回だけ渡す

    トークンは `<端末ID>.<秘密の文字列>` の形。サーバーには、秘密の文字列の
    ハッシュだけを保存する(漏れても、元のトークンは分からない)。
    """
    data = parse_body(body)
    claim_secret = data.get("claimSecret")
    item = read_pairing(data.get("code"))

    if (
        item is None
        or not isinstance(claim_secret, str)
        or not hmac.compare_digest(
            item["claimSecretHash"]["S"], sha256_hex(claim_secret)
        )
    ):
        return response(404, {"status": "expired"})

    if item["status"]["S"] == "pending":
        return response(202, {"status": "pending"})

    # 確定済み。コードを使い切りにして(削除して)、端末を登録する
    try:
        dynamodb.delete_item(
            TableName=PAIRING_TABLE_NAME,
            Key={"code": item["code"]},
            ConditionExpression="claimSecretHash = :h AND #s = :linked",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={
                ":h": {"S": sha256_hex(claim_secret)},
                ":linked": {"S": "linked"},
            },
        )
    except ClientError as e:
        if error_code(e) == "ConditionalCheckFailedException":
            return response(404, {"status": "expired"})
        raise

    device_id = uuid.uuid4().hex
    device_secret = secrets.token_urlsafe(32)

    dynamodb.put_item(
        TableName=DEVICES_TABLE_NAME,
        Item={
            "deviceId": {"S": device_id},
            "accountId": item["accountId"],
            "tokenHash": {"S": sha256_hex(device_secret)},
            "label": item["label"],
            "createdAt": {"N": str(int(time.time()))},
        },
    )

    return response(200, {
        "status": "linked",
        "deviceToken": f"{device_id}.{device_secret}",
    })


def list_devices(account_id):
    result = dynamodb.query(
        TableName=DEVICES_TABLE_NAME,
        IndexName="accountId-index",
        KeyConditionExpression="accountId = :a",
        ExpressionAttributeValues={":a": {"S": account_id}},
    )
    devices = sorted(
        (
            {
                "deviceId": item["deviceId"]["S"],
                "label": item["label"]["S"],
                "createdAt": int(item["createdAt"]["N"]),
            }
            for item in result["Items"]
        ),
        key=lambda d: d["createdAt"],
    )
    return response(200, {"devices": devices, "maxDevices": MAX_DEVICES})


def delete_device(account_id, device_id):
    if not isinstance(device_id, str) or not re.match(r"^[0-9a-f]{32}$", device_id):
        return response(404, {"error": "not_found"})

    try:
        dynamodb.delete_item(
            TableName=DEVICES_TABLE_NAME,
            Key={"deviceId": {"S": device_id}},
            # 自分の端末だけを、解除できる
            ConditionExpression="accountId = :a",
            ExpressionAttributeValues={":a": {"S": account_id}},
        )
    except ClientError as e:
        if error_code(e) == "ConditionalCheckFailedException":
            return response(404, {"error": "not_found"})
        raise

    return response(200, {"deleted": True})


def lambda_handler(event, context):
    try:
        route = event["routeKey"]

        # ログインなしで呼ばれるもの(アプリから)
        if route == "POST /pairing/start":
            return pairing_start(event.get("body"))
        if route == "POST /pairing/claim":
            return pairing_claim(event.get("body"))

        # ここから先は、ログインが必要。オーソライザーが付いていないと、
        # account_id_of が失敗して、エラーになる(何も実行されない)
        account_id = account_id_of(event)

        if route == "GET /me":
            return response(200, get_or_create(account_id))

        if route == "POST /exchange":
            return exchange(account_id, event.get("body"))

        if route == "POST /dev/grant":
            return dev_grant(account_id, event.get("body"))

        if route == "POST /pairing/lookup":
            return pairing_lookup(event.get("body"))

        if route == "POST /pairing/confirm":
            return pairing_confirm(account_id, event.get("body"))

        if route == "GET /devices":
            return list_devices(account_id)

        if route == "DELETE /devices/{deviceId}":
            device_id = (event.get("pathParameters") or {}).get("deviceId")
            return delete_device(account_id, device_id)

        return response(404, {"error": "not_found"})

    except Exception as e:
        print(f"error: {e!r}")
        return response(500, {"error": "internal_error"})
