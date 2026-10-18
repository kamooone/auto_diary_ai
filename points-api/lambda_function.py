"""ポイントのAPI(手順3: モック)

  GET  /me          ログイン中のアカウントの、ポイントとトークンの残高を返す
                    (初めてのアカウントは、残高0で作る)
  POST /dev/grant   動作確認用: ポイントを足す(本番では無効にする)

API Gateway(HTTP API)の「JWTオーソライザー」が、先にログインの確認をする。
このLambdaに届くのは、確認が済んだリクエストだけ。
誰のリクエストかは、確認済みのトークンの中の `sub`(アカウント固有のID)で分かる。
"""
import json
import os
import time

import boto3

TABLE_NAME = os.environ["TABLE_NAME"]

# 動作確認用の口を使えるか(環境変数で切り替える。本番では false にする)
ENABLE_DEV_GRANT = os.environ.get("ENABLE_DEV_GRANT") == "true"

# 動作確認用に、1回で足せるポイントの上限
DEV_GRANT_MAX = 100

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


def to_balance(item):
    return {
        "points": int(item["points"]["N"]),
        "tokens": int(item["tokens"]["N"]),
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
    return to_balance(result["Attributes"])


def dev_grant(account_id, body):
    if not ENABLE_DEV_GRANT:
        return response(404, {"error": "not_found"})

    try:
        amount = int(json.loads(body or "{}").get("amount", 0))
    except (ValueError, TypeError):
        return response(400, {"error": "amount must be an integer"})

    if not 1 <= amount <= DEV_GRANT_MAX:
        return response(400, {"error": f"amount must be 1..{DEV_GRANT_MAX}"})

    # ADD は、読み取りと加算を1回で行う(同時に呼ばれても、数が狂わない)
    result = dynamodb.update_item(
        TableName=TABLE_NAME,
        Key={"accountId": {"S": account_id}},
        UpdateExpression=(
            "ADD points :amount "
            "SET tokens = if_not_exists(tokens, :zero), "
            "createdAt = if_not_exists(createdAt, :now)"
        ),
        ExpressionAttributeValues={
            ":amount": {"N": str(amount)},
            ":zero": {"N": "0"},
            ":now": {"N": str(int(time.time()))},
        },
        ReturnValues="ALL_NEW",
    )
    return response(200, to_balance(result["Attributes"]))


def lambda_handler(event, context):
    try:
        account_id = account_id_of(event)
        route = event["routeKey"]

        if route == "GET /me":
            return response(200, get_or_create(account_id))

        if route == "POST /dev/grant":
            return dev_grant(account_id, event.get("body"))

        return response(404, {"error": "not_found"})

    except Exception as e:
        print(f"error: {e!r}")
        return response(500, {"error": "internal_error"})
