"""お問い合わせに開発者の返信が入ったら、その端末にプッシュ通知を送る

DynamoDB Streams(テーブル auto-diary-inquiries)をきっかけに動くLambda。
返信(from が "developer" の行が追加されたとき)だけを送る。コンソールで書いた返信も対象。

環境変数:
  PUSH_TOKEN_TABLE_NAME    : 宛先のテーブル(なければ auto-diary-push-tokens)
  FCM_PARAMETER_NAME       : サービスアカウントの鍵(JSON)を入れた Parameter Store の名前
                             (なければ /auto-diary/fcm-service-account。SecureString)

fcm_client.py と同じ場所に置く。
"""
import json
import os

import boto3

import fcm_client

PUSH_TOKEN_TABLE_NAME = os.environ.get(
    "PUSH_TOKEN_TABLE_NAME", "auto-diary-push-tokens"
)
FCM_PARAMETER_NAME = os.environ.get(
    "FCM_PARAMETER_NAME", "/auto-diary/fcm-service-account"
)

# 通知の文面。返信の本文は、ロック画面で他人に見られないよう、入れない
TITLE = "お問い合わせに返信が届きました"
BODY = "アプリを開いて、確認してください"

dynamodb = boto3.client("dynamodb")
ssm = boto3.client("ssm")

_service_account = None


def load_service_account():
    global _service_account

    if _service_account is None:
        value = ssm.get_parameter(Name=FCM_PARAMETER_NAME, WithDecryption=True)
        _service_account = json.loads(value["Parameter"]["Value"])

    return _service_account


def is_developer_reply(record):
    """返信の行が追加された記録か"""
    if record.get("eventName") != "INSERT":
        return False

    image = record.get("dynamodb", {}).get("NewImage", {})
    return image.get("from", {}).get("S") == "developer"


def notify(client_id):
    """端末に通知を送る。宛先がなければ何もしない。戻り値: 結果の文字列"""
    item = dynamodb.get_item(
        TableName=PUSH_TOKEN_TABLE_NAME,
        Key={"clientId": {"S": client_id}},
    ).get("Item")

    if not item:
        return "no_token"

    service_account = load_service_account()
    access_token = fcm_client.get_access_token(service_account)

    result = fcm_client.send_push(
        service_account["project_id"],
        access_token,
        item["token"]["S"],
        TITLE,
        BODY,
        {"type": "inquiry_reply"},
    )

    # アプリが消されたなどで、宛先が使えなくなっていたら消す
    if result == "unregistered":
        dynamodb.delete_item(
            TableName=PUSH_TOKEN_TABLE_NAME,
            Key={"clientId": {"S": client_id}},
        )

    return result


def lambda_handler(event, context):
    results = []

    for record in event.get("Records", []):
        if not is_developer_reply(record):
            continue

        client_id = record["dynamodb"]["NewImage"]["clientId"]["S"]

        # 1件の失敗で、ほかの通知や、再実行の繰り返しにならないよう、ここで止める
        # (通知の内容や宛先は、ログに出さない)
        try:
            results.append(notify(client_id))
        except Exception as e:
            print(f"push failed: {type(e).__name__}")
            results.append("error")

    print(json.dumps({"results": results}))
    return {"results": results}
