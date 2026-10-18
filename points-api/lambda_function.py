"""ポイントのAPI(手順4: 交換まで)

  GET  /me          ログイン中のアカウントの、ポイントとトークンの残高を返す
                    (初めてのアカウントは、残高0で作る)
  POST /exchange    ポイントをトークンに交換する
  POST /dev/grant   動作確認用: ポイントを足す(本番では無効にする)

API Gateway(HTTP API)の「JWTオーソライザー」が、先にログインの確認をする。
このLambdaに届くのは、確認が済んだリクエストだけ。
誰のリクエストかは、確認済みのトークンの中の `sub`(アカウント固有のID)で分かる。

残高(accountsテーブル)の更新と、履歴(ledgerテーブル)への記録は、
DynamoDBのトランザクションで、同時に行う(片方だけ成功することがない)。
"""
import json
import os
import time
import uuid

import boto3
from botocore.exceptions import ClientError

TABLE_NAME = os.environ["TABLE_NAME"]
LEDGER_TABLE_NAME = os.environ["LEDGER_TABLE_NAME"]

# 動作確認用の口を使えるか(環境変数で切り替える。本番では false にする)
ENABLE_DEV_GRANT = os.environ.get("ENABLE_DEV_GRANT") == "true"

# 動作確認用に、1回で足せるポイントの上限
DEV_GRANT_MAX = 100_000

# 交換のルール(変えるときは、ここだけ直す)
TOKENS_PER_POINT = 1  # 1ポイントあたりのトークン数
MIN_EXCHANGE_POINTS = 10_000  # 1回の交換で、最低限使うポイント数

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

    update = {
        "TableName": TABLE_NAME,
        "Key": {"accountId": {"S": account_id}},
        "UpdateExpression": update_expression,
        "ExpressionAttributeValues": {
            ":zero": {"N": "0"},
            ":now": {"N": str(now)},
            **values,
        },
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


def lambda_handler(event, context):
    try:
        account_id = account_id_of(event)
        route = event["routeKey"]

        if route == "GET /me":
            return response(200, get_or_create(account_id))

        if route == "POST /exchange":
            return exchange(account_id, event.get("body"))

        if route == "POST /dev/grant":
            return dev_grant(account_id, event.get("body"))

        return response(404, {"error": "not_found"})

    except Exception as e:
        print(f"error: {e!r}")
        return response(500, {"error": "internal_error"})
