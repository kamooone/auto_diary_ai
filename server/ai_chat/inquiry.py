"""お問い合わせ(アプリ内のフォーム)

  POST /inquiries : 端末から問い合わせを送る
  GET  /inquiries : その端末の、送った内容と、開発者からの返信を、古い順に返す
  POST /push-token: 返信の通知を送る宛先(FCMのトークン)を登録する

保存先は DynamoDB のテーブル(環境変数 INQUIRY_TABLE_NAME。なければ auto-diary-inquiries)。
  パーティションキー clientId (S) : 端末の匿名のID
  ソートキー        sk (S)       : "<日時(UTC・ミリ秒)>#<乱数>"。日時順に並ぶ
返信は、開発者が inquiry_admin.py で書き込む(from が "developer" の行)。

宛先は、別のテーブル(環境変数 PUSH_TOKEN_TABLE_NAME。なければ auto-diary-push-tokens。
パーティションキー clientId (S))に置く。返信の通知は、inquiry_push_lambda.py(別のLambda)が送る。

ai_chat_lambda.py と同じ場所に置く。端末のIDの確認などは、ai_chat_lambda.py 側で済ませて渡す。
"""
import json
import os
import re
import secrets
from datetime import datetime, timedelta, timezone

INQUIRY_TABLE_NAME = os.environ.get("INQUIRY_TABLE_NAME", "auto-diary-inquiries")

PUSH_TOKEN_TABLE_NAME = os.environ.get(
    "PUSH_TOKEN_TABLE_NAME", "auto-diary-push-tokens"
)

CATEGORIES = ("bug", "request", "other")

# FCMのトークンとして受け付ける形(英数字と ":" "_" "-" ".")と長さ
PUSH_TOKEN_PATTERN = re.compile(r"^[A-Za-z0-9:_.\-]{20,4096}$")

# 本文の最大文字数
MAX_MESSAGE_LENGTH = 1000

# 同じ端末から、24時間に送れる件数(連投・荒らしの対策)
MAX_PER_DAY = 5

# 端末ごとに、保存できる件数(送った分と返信の合計)
MAX_MESSAGES_PER_CLIENT = 200

# 返す件数の上限(新しいものから)
MAX_RETURNED = 100

# 端末・アプリの情報の最大文字数
MAX_INFO_LENGTH = 100


class InquiryError(Exception):
    """アプリに返すエラー(ステータスと、エラーの名前)"""

    def __init__(self, status, error):
        super().__init__(error)
        self.status = status
        self.error = error


def make_sort_key(now=None):
    now = (now or datetime.now(timezone.utc)).astimezone(timezone.utc)
    return f"{now.strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3]}Z#{secrets.token_hex(3)}"


def clean_text(value, limit):
    return value.strip()[:limit] if isinstance(value, str) else ""


def validate_inquiry(body):
    """送られた本文を確認して、保存する値を返す。正しくなければ InquiryError"""
    if not isinstance(body, dict):
        raise InquiryError(400, "invalid_body")

    message = body.get("message")

    if not isinstance(message, str) or not message.strip():
        raise InquiryError(400, "message_required")

    message = message.strip()

    if len(message) > MAX_MESSAGE_LENGTH:
        raise InquiryError(400, "message_too_long")

    category = body.get("category")

    if category not in CATEGORIES:
        raise InquiryError(400, "invalid_category")

    return {
        "message": message,
        "category": category,
        "appVersion": clean_text(body.get("appVersion"), MAX_INFO_LENGTH),
        "platform": clean_text(body.get("platform"), MAX_INFO_LENGTH),
    }


def query_messages(dynamodb, client_id, since=None, limit=None, descending=False):
    """端末の行を、ソートキーの順に取得する"""
    values = {":c": {"S": client_id}}
    condition = "clientId = :c"

    if since is not None:
        condition += " AND sk > :since"
        values[":since"] = {"S": since}

    params = {
        "TableName": INQUIRY_TABLE_NAME,
        "KeyConditionExpression": condition,
        "ExpressionAttributeValues": values,
        "ScanIndexForward": not descending,
        "ConsistentRead": True,
    }

    if limit is not None:
        params["Limit"] = limit

    return dynamodb.query(**params).get("Items", [])


def to_message(item):
    """DynamoDBの行を、アプリに返す形にする"""
    sender = item.get("from", {}).get("S", "user")

    return {
        "id": item["sk"]["S"],
        "from": "developer" if sender == "developer" else "user",
        "category": item.get("category", {}).get("S"),
        "message": item.get("message", {}).get("S", ""),
        "createdAt": item.get("createdAt", {}).get("S", ""),
    }


def send_inquiry(dynamodb, client_id, body, now=None):
    """問い合わせを保存する。送った行を返す"""
    now = (now or datetime.now(timezone.utc)).astimezone(timezone.utc)
    inquiry = validate_inquiry(body)

    # 1日の件数の上限
    since = make_sort_key(now - timedelta(hours=24))
    recent = query_messages(dynamodb, client_id, since=since)
    sent = [e for e in recent if e.get("from", {}).get("S") == "user"]

    if len(sent) >= MAX_PER_DAY:
        raise InquiryError(429, "too_many_inquiries")

    # 端末ごとの保存件数の上限
    total = query_messages(dynamodb, client_id, limit=MAX_MESSAGES_PER_CLIENT)

    if len(total) >= MAX_MESSAGES_PER_CLIENT:
        raise InquiryError(429, "too_many_inquiries")

    item = {
        "clientId": {"S": client_id},
        "sk": {"S": make_sort_key(now)},
        "from": {"S": "user"},
        "category": {"S": inquiry["category"]},
        "message": {"S": inquiry["message"]},
        "createdAt": {"S": now.isoformat()},
    }

    for name in ("appVersion", "platform"):
        if inquiry[name]:
            item[name] = {"S": inquiry[name]}

    dynamodb.put_item(TableName=INQUIRY_TABLE_NAME, Item=item)

    return to_message(item)


def list_messages(dynamodb, client_id):
    """端末の送った内容と返信を、古い順に返す(多いときは、新しい方の最大100件)"""
    items = query_messages(
        dynamodb, client_id, limit=MAX_RETURNED, descending=True
    )
    return [to_message(e) for e in reversed(items)]


def register_push_token(dynamodb, client_id, body, now=None):
    """返信の通知の宛先を登録する(同じ端末は上書き)

    一度も問い合わせを送っていない端末は、受け付けない(宛先を、むやみに溜めないため)。
    """
    token = body.get("token") if isinstance(body, dict) else None

    if not isinstance(token, str) or not PUSH_TOKEN_PATTERN.match(token):
        raise InquiryError(400, "invalid_token")

    if not query_messages(dynamodb, client_id, limit=1):
        raise InquiryError(403, "no_inquiry")

    now = (now or datetime.now(timezone.utc)).astimezone(timezone.utc)

    dynamodb.put_item(
        TableName=PUSH_TOKEN_TABLE_NAME,
        Item={
            "clientId": {"S": client_id},
            "token": {"S": token},
            "updatedAt": {"S": now.isoformat()},
        },
    )


def handle_push_token(dynamodb, client_id, body_text):
    """POST /push-token を処理して、(ステータス, 本文のdict)を返す"""
    try:
        try:
            body = json.loads(body_text or "{}")
        except json.JSONDecodeError:
            raise InquiryError(400, "invalid_body")

        register_push_token(dynamodb, client_id, body)
        return 200, {"ok": True}
    except InquiryError as e:
        return e.status, {"error": e.error}


def handle(method, dynamodb, client_id, body_text):
    """リクエストを処理して、(ステータス, 本文のdict)を返す"""
    try:
        if method == "POST":
            try:
                body = json.loads(body_text or "{}")
            except json.JSONDecodeError:
                raise InquiryError(400, "invalid_body")

            return 200, {"message": send_inquiry(dynamodb, client_id, body)}

        return 200, {"messages": list_messages(dynamodb, client_id)}
    except InquiryError as e:
        return e.status, {"error": e.error}
