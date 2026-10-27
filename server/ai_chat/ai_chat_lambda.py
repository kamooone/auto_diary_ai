import json
import boto3
import urllib.request
import urllib.error
import base64
import socket
import traceback
import os
import re
import hashlib
import hmac
import time
from datetime import datetime, timedelta, timezone

from botocore.exceptions import ClientError


secrets_manager = boto3.client("secretsmanager")
s3 = boto3.client("s3")
dynamodb = boto3.client("dynamodb")

OPENAI_SECRET_NAME = "auto-diary-ai/openai-api-key"
GEMINI_SECRET_NAME = "auto-diary/gemini-api-key"
BUCKET_NAME = "auto-diary-ai-images"

# APIキーは、Secrets Managerのシークレットごとに分けて保存している
#   OPENAI_SECRET_NAME : 有料プランで使う(キー名 OPENAI_API_KEY)
#   GEMINI_SECRET_NAME : 無料プランで使う(キー名 GEMINI_API_KEY)
# シークレットの値は、JSON({"GEMINI_API_KEY": "..."})でも、キーだけの文字列でもよい
OPENAI_MODEL = "gpt-4o-mini"

# 無料プランのモデル。混んでいて使えないときは、後ろのモデルに順に切り替える
# (モデル名は、提供が終わると使えなくなる。使えるモデルは、AI Studioで確認する)
GEMINI_MODELS = [
    "gemini-3.8-flash",
    "gemini-flash-latest",
    "gemini-flash-lite-latest",
]

# 次のモデルを試す、Geminiのステータス
#   404: そのモデルは使えない / 429: 混んでいる・無料枠の制限
#   500・503・504: Google側の一時的な障害
# (400・401・403は、キーやリクエストの問題で、モデルを変えても直らないため試さない)
GEMINI_RETRY_STATUSES = {404, 429, 500, 503, 504}

# 考える量を減らして、速くする(日記の文章づくりに、深い思考は要らない)
# 3系のモデルの指定。合わないモデルが400を返したときは、指定なしでやり直す
GEMINI_THINKING_CONFIG = {"thinkingLevel": "low"}

# 1つのモデルを待つ最長の時間(秒)
# 写真が多い日記は、10秒では足りず、時間切れになった
GEMINI_ATTEMPT_TIMEOUT = 25

# API Gatewayの統合タイムアウト(29秒)に間に合わせるため、Geminiに使える時間(秒)
# (Geminiを呼ぶ前の処理と、回答を返す処理の分を引いてある)
GEMINI_TOTAL_BUDGET = 26

# 次のモデルを試すには、残りの時間がこれ以上必要(秒)
MIN_REMAINING_SECONDS = 12

# Lambdaの残り時間から、回答を受け取ったあとの記録などの分として引く時間(秒)
RESERVED_SECONDS = 3

# 受け付けるプラン。これ以外(未指定を含む)は、無料プランとして扱う
PAID = "paid"
FREE = "free"

# 有料プランを受け付けるか(環境変数 PAID_ENABLED が "true" のときだけ)
# アプリ内課金を始めるまでは、アプリが「有料」と申告しても、無料として扱う
PAID_ENABLED = os.environ.get("PAID_ENABLED", "false").lower() == "true"

# 使用量と、アカウントのトークン残高を保存するテーブル
#   USAGE_TABLE_NAME    : 月ごとの使用量(キー usageKey = "<端末のID>#<年-月>")
#   ACCOUNTS_TABLE_NAME : ポイントAPIのアカウント(残高 tokens)
#   DEVICES_TABLE_NAME  : ポイントAPIの、紐づけ済みの端末
USAGE_TABLE_NAME = os.environ.get("USAGE_TABLE_NAME", "auto-diary-ai-usage")
ACCOUNTS_TABLE_NAME = os.environ.get(
    "ACCOUNTS_TABLE_NAME", "auto-diary-points-accounts"
)
DEVICES_TABLE_NAME = os.environ.get(
    "DEVICES_TABLE_NAME", "auto-diary-points-devices"
)

# 毎月使えるトークン数(プランごと。仮の値。変えるときはここだけ直す)
# アカウントのトークンは、この枠を使い切ったあとに減る(使える量が増えるだけ)
MONTHLY_LIMIT_TOKENS = {FREE: 3_000, PAID: 500_000}

# 月の区切りは、日本時間
JST = timezone(timedelta(hours=9))

# 端末を識別する匿名のID(アプリのインストールごとに1つ)
CLIENT_ID_PATTERN = re.compile(r"^[A-Za-z0-9_-]{8,64}$")

# 使用量の行は、月が替わって2か月たったら、DynamoDBが自動で削除する
USAGE_ROW_TTL_SECONDS = 62 * 24 * 60 * 60

# AIの提供元が返したエラーを、アプリには429で返さない
# (アプリは、429を「今月の使用量の上限に達した」として扱うため)
UPSTREAM_ERROR_STATUS = 502


class UpstreamError(Exception):
    def __init__(self, provider, status, details):
        super().__init__(f"{provider} API request failed")
        self.provider = provider
        self.status = status
        self.details = details


def get_api_key(secret_name, key_name):
    response = secrets_manager.get_secret_value(SecretId=secret_name)
    value = response["SecretString"].strip()

    try:
        secret = json.loads(value)
    except ValueError:
        # JSONではなく、キーだけを保存している場合
        return value

    if not isinstance(secret, dict):
        return value

    if key_name in secret:
        return secret[key_name]

    # キー名が違っても、値が1つだけなら、それをAPIキーとして使う
    if len(secret) == 1:
        return next(iter(secret.values()))

    # 値(APIキー)は出さずに、キー名だけをエラーに含める
    raise KeyError(f"{key_name} not found in {secret_name} (keys: {list(secret)})")


def post_json(provider, url, headers, body, timeout=None):
    request = urllib.request.Request(
        url,
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json", **headers},
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return json.loads(response.read())
    except urllib.error.HTTPError as e:
        raise UpstreamError(
            provider, e.code, e.read().decode("utf-8")
        ) from e


def ask_openai(api_key, message, images):
    """有料プラン: GPT。(回答, 消費したトークン数)を返す"""
    content = [{"type": "input_text", "text": message}]

    for image in images:
        content.append({
            "type": "input_image",
            "image_url": (
                f"data:{image['content_type']};base64,{image['base64']}"
            ),
        })

    data = post_json(
        "OpenAI",
        "https://api.openai.com/v1/responses",
        {"Authorization": f"Bearer {api_key}"},
        {
            "model": OPENAI_MODEL,
            "input": [{"role": "user", "content": content}],
        },
    )

    answer = data["output"][0]["content"][0]["text"]
    tokens = data.get("usage", {}).get("total_tokens", 0)

    return answer, tokens


def ask_gemini(api_key, message, images, context=None):
    """無料プラン: Gemini。(回答, 消費したトークン数)を返す

    モデルが使えないとき(混んでいる、提供が終わったなど)は、
    GEMINI_MODELSの順に別のモデルへ切り替える
    """
    parts = [{"text": message}]

    for image in images:
        parts.append({
            "inline_data": {
                "mime_type": image["content_type"],
                "data": image["base64"],
            }
        })

    last_error = None
    started = time.monotonic()

    def seconds_left():
        left = GEMINI_TOTAL_BUDGET - (time.monotonic() - started)

        if context is not None:
            lambda_left = context.get_remaining_time_in_millis() / 1000
            left = min(left, lambda_left - RESERVED_SECONDS)

        return left

    for model in GEMINI_MODELS:

        # 時間が足りなければ、次のモデルは試さない
        if last_error is not None and seconds_left() < MIN_REMAINING_SECONDS:
            break

        attempt_started = time.monotonic()

        def request(with_thinking):
            body = {"contents": [{"role": "user", "parts": parts}]}

            if with_thinking:
                body["generationConfig"] = {
                    "thinkingConfig": GEMINI_THINKING_CONFIG
                }

            return post_json(
                "Gemini",
                (
                    "https://generativelanguage.googleapis.com/v1beta/models/"
                    f"{model}:generateContent"
                ),
                # URLにキーを付けると、ログに残るため、ヘッダーで渡す
                {"x-goog-api-key": api_key},
                body,
                timeout=max(1, min(GEMINI_ATTEMPT_TIMEOUT, seconds_left())),
            )

        try:
            try:
                data = request(True)
            except UpstreamError as e:
                if e.status != 400:
                    raise

                # このモデルは思考の指定に対応していないため、指定なしでやり直す
                print(json.dumps({
                    "provider": "Gemini", "model": model, "status": 400,
                    "details": str(e.details)[:300],
                    "action": "retry_without_thinking",
                }, ensure_ascii=False))
                data = request(False)
        except UpstreamError as e:
            if e.status not in GEMINI_RETRY_STATUSES:
                raise

            print(json.dumps({
                "provider": "Gemini", "model": model, "status": e.status,
                # Googleが返した理由(長いものは切る)。キーは含まれない
                "details": str(e.details)[:300],
                "seconds": round(time.monotonic() - attempt_started, 1),
                "action": "switch_model",
            }, ensure_ascii=False))
            last_error = e
            continue
        except (socket.timeout, TimeoutError, urllib.error.URLError) as e:
            # 応答が遅い、または接続できないときも、次のモデルを試す
            print(json.dumps({
                "provider": "Gemini", "model": model, "error": str(e),
                "seconds": round(time.monotonic() - attempt_started, 1),
                "action": "switch_model",
            }, ensure_ascii=False))
            last_error = UpstreamError("Gemini", 0, str(e))
            continue

        candidates = data.get("candidates") or []

        if not candidates:
            # 安全性の判定などで、回答が返らなかった場合
            raise UpstreamError(
                "Gemini", 200, json.dumps(data, ensure_ascii=False)
            )

        answer = "".join(
            part.get("text", "")
            for part in candidates[0].get("content", {}).get("parts", [])
        )
        usage = data.get("usageMetadata", {})
        tokens = usage.get("totalTokenCount", 0)

        # 入力・出力・思考の内訳(見積もりの係数を決めるために残す)
        print(json.dumps({
            "provider": "Gemini", "model": model,
            "prompt": usage.get("promptTokenCount", 0),
            "output": usage.get("candidatesTokenCount", 0),
            "thoughts": usage.get("thoughtsTokenCount", 0),
            "total": tokens,
            "seconds": round(time.monotonic() - attempt_started, 1),
        }))

        return answer, tokens

    # すべてのモデルが使えなかった
    raise last_error


class InvalidDeviceToken(Exception):
    """紐づけが解除された(または偽の)端末用トークン"""


def header_of(event, name):
    headers = event.get("headers") or {}
    for key, value in headers.items():
        if key.lower() == name:
            return value
    return None


def month_window(now=None):
    """今月のキー("2026-10")と、リセットされる日時(来月1日0時、日本時間)"""
    now = (now or datetime.now(JST)).astimezone(JST)
    first = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    next_first = (first + timedelta(days=32)).replace(day=1)
    return first.strftime("%Y-%m"), next_first.isoformat()


def sha256_hex(value):
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def account_of_device_token(token):
    """端末用のトークンから、アカウントのIDを返す

    トークンがない場合はNone(アカウントなしで使う)。
    あるのに正しくない場合(紐づけを解除したなど)は、InvalidDeviceTokenにする。
    """
    if not token:
        return None

    device_id, dot, secret = token.partition(".")

    if not dot or not device_id or not secret:
        raise InvalidDeviceToken()

    result = dynamodb.get_item(
        TableName=DEVICES_TABLE_NAME,
        Key={"deviceId": {"S": device_id}},
    )
    item = result.get("Item")

    if item is None or not hmac.compare_digest(
        item["tokenHash"]["S"], sha256_hex(secret)
    ):
        raise InvalidDeviceToken()

    return item["accountId"]["S"]


def read_used_tokens(usage_key):
    """今月に使った量を返す: (毎月の枠から使った量, アカウントのトークンから使った量)"""
    result = dynamodb.get_item(
        TableName=USAGE_TABLE_NAME,
        Key={"usageKey": {"S": usage_key}},
        ConsistentRead=True,
    )
    item = result.get("Item")

    if not item:
        return 0, 0

    return (
        int(item["usedTokens"]["N"]),
        int(item.get("balanceUsedTokens", {"N": "0"})["N"]),
    )


def read_token_balance(account_id):
    if account_id is None:
        return 0

    result = dynamodb.get_item(
        TableName=ACCOUNTS_TABLE_NAME,
        Key={"accountId": {"S": account_id}},
        ConsistentRead=True,
    )
    item = result.get("Item")
    return int(item["tokens"]["N"]) if item else 0


def usage_payload(plan, used, balance_used, balance, resets_at):
    """アプリに返す使用量

    今月の使用量 = 毎月の枠の中で使った量 + アカウントのトークンから使った量
    使える量の合計 = 毎月の枠 + 今月の初めのトークン残高
                  (= 毎月の枠 + 今のトークン残高 + 今月にトークンから使った量)
    月の途中で分母が縮まないため、「54,000 / 60,000」のように見える。
    """
    limit = MONTHLY_LIMIT_TOKENS[plan]

    return {
        "plan": plan,
        "usage": {
            "usedTokens": min(used, limit) + balance_used,
            "limitTokens": limit + balance + balance_used,
            "resetsAt": resets_at,
        },
        "tokenBalance": balance,
    }


def requested_plan(value):
    """アプリが申告したプランを、受け付けるプランにする"""
    return PAID if PAID_ENABLED and value == PAID else FREE


def is_exceeded(plan, used, balance):
    return MONTHLY_LIMIT_TOKENS[plan] - used + balance <= 0


def record_usage(usage_key, plan, account_id, tokens, used, balance):
    """使ったトークンを、毎月の枠 → アカウントのトークンの順に減らす

    戻り値: (毎月の枠で使った量, アカウントのトークンから減らした量)
    """
    if tokens <= 0:
        return 0, 0

    from_allowance = min(tokens, max(0, MONTHLY_LIMIT_TOKENS[plan] - used))
    from_balance = min(tokens - from_allowance, balance)

    if from_balance > 0 and account_id is not None:
        try:
            dynamodb.update_item(
                TableName=ACCOUNTS_TABLE_NAME,
                Key={"accountId": {"S": account_id}},
                UpdateExpression="SET tokens = tokens - :n",
                # 同時に使われても、残高がマイナスにならない
                ConditionExpression="tokens >= :n",
                ExpressionAttributeValues={":n": {"N": str(from_balance)}},
            )
        except ClientError as e:
            if e.response["Error"]["Code"] != "ConditionalCheckFailedException":
                raise
            # 同時に使われて、残高が足りなくなった。AIはすでに使ったため、
            # 減らせなかった分は、ログに残す
            print(json.dumps({
                "warning": "balance_changed", "fromBalance": from_balance,
            }))
            from_balance = 0

    if from_allowance > 0 or from_balance > 0:
        dynamodb.update_item(
            TableName=USAGE_TABLE_NAME,
            Key={"usageKey": {"S": usage_key}},
            UpdateExpression=(
                "ADD usedTokens :a, balanceUsedTokens :b SET expiresAt = :ttl"
            ),
            ExpressionAttributeValues={
                ":a": {"N": str(from_allowance)},
                ":b": {"N": str(from_balance)},
                ":ttl": {"N": str(int(time.time()) + USAGE_ROW_TTL_SECONDS)},
            },
        )

    return from_allowance, from_balance


def response(status, body):
    return {
        "statusCode": status,
        "body": json.dumps(body, ensure_ascii=False),
    }


def read_state(event, plan):
    """端末のID・アカウント・今月の使用量・トークン残高をまとめて取得する

    戻り値: dict。端末のIDがないとき・トークンが正しくないときは、
    (エラーのレスポンス, None)で返す
    """
    client_id = header_of(event, "x-client-id")

    if not client_id or not CLIENT_ID_PATTERN.match(client_id):
        return response(400, {"error": "client_id_required"}), None

    try:
        account_id = account_of_device_token(
            header_of(event, "x-device-token")
        )
    except InvalidDeviceToken:
        return response(401, {"error": "invalid_device_token"}), None

    month, resets_at = month_window()
    usage_key = f"{client_id}#{month}"
    used, balance_used = read_used_tokens(usage_key)

    return None, {
        "usage_key": usage_key,
        "account_id": account_id,
        "resets_at": resets_at,
        "used": used,
        "balance_used": balance_used,
        "balance": read_token_balance(account_id),
    }


def delete_uploaded_images(images):
    """AIを使わずに終わるとき、アプリがアップロードした画像をS3から消す"""
    if not isinstance(images, list):
        return

    for image in images:
        s3_key = image.get("s3_key") if isinstance(image, dict) else None

        if not s3_key:
            continue

        try:
            s3.delete_object(Bucket=BUCKET_NAME, Key=s3_key)
        except Exception:
            traceback.print_exc()


def is_plan_usage_request(event):
    """GET /plan/usage か(HTTP APIとREST APIの、どちらの形式でも判定する)"""
    if event.get("routeKey") == "GET /plan/usage":
        return True

    # REST API(プロキシ統合): httpMethod と resource で分かる
    return (
        event.get("httpMethod") == "GET"
        and event.get("resource") == "/plan/usage"
    )


def plan_usage(event):
    """GET /plan/usage: 今月の使用量。プランは、クエリ(?plan=paid)で受け取る"""
    params = event.get("queryStringParameters") or {}
    plan = requested_plan(params.get("plan"))

    error, state = read_state(event, plan)

    if error is not None:
        return error

    return response(200, usage_payload(
        plan, state["used"], state["balance_used"], state["balance"],
        state["resets_at"],
    ))


def lambda_handler(event, context):

    image_keys = []

    try:
        if is_plan_usage_request(event):
            return plan_usage(event)

        body = json.loads(event.get("body", "{}"))

        message = body.get("message", "")

        if not message:
            return response(400, {"error": "message is required"})

        # アプリから受け取ったプラン
        # (注意: アプリが申告した値のため、課金の確認をするまでは信用できない。
        #  課金を実装したら、購入の確認結果から決める)
        plan = requested_plan(body.get("plan"))

        error, state = read_state(event, plan)

        if error is not None:
            return error

        # 上限に達している場合は、AIを呼ばずに断る
        if is_exceeded(plan, state["used"], state["balance"]):
            delete_uploaded_images(body.get("images"))

            return response(429, {
                "error": "usage_limit_exceeded",
                **usage_payload(
                    plan, state["used"], state["balance_used"],
                    state["balance"], state["resets_at"],
                ),
            })

        images = body.get("images", [])

        if not isinstance(images, list):
            return response(400, {"error": "images must be a list"})

        for image in images:

            s3_key = image.get("s3_key")
            content_type = image.get("content_type")

            if not s3_key:
                return response(400, {"error": "s3_key is required"})

            if content_type not in ["image/jpeg", "image/png"]:
                return response(
                    400, {"error": f"Unsupported image type: {content_type}"}
                )

            image_keys.append({
                "s3_key": s3_key,
                "content_type": content_type,
            })

        # S3から画像を取得(どちらのAIにも、Base64で渡す)
        for image in image_keys:

            s3_object = s3.get_object(
                Bucket=BUCKET_NAME,
                Key=image["s3_key"],
            )

            image["base64"] = base64.b64encode(
                s3_object["Body"].read()
            ).decode("utf-8")

        # プランに応じて、使うAIを切り替える
        if plan == PAID:
            answer, tokens = ask_openai(
                get_api_key(OPENAI_SECRET_NAME, "OPENAI_API_KEY"),
                message,
                image_keys,
            )
        else:
            answer, tokens = ask_gemini(
                get_api_key(GEMINI_SECRET_NAME, "GEMINI_API_KEY"),
                message,
                image_keys,
                context,
            )

        # S3の画像を削除
        for image in image_keys:

            s3.delete_object(
                Bucket=BUCKET_NAME,
                Key=image["s3_key"],
            )

        # 使ったトークンを、毎月の枠 → アカウントのトークンの順に減らす
        from_allowance, from_balance = record_usage(
            state["usage_key"], plan, state["account_id"], tokens,
            state["used"], state["balance"],
        )

        print(json.dumps({
            "plan": plan, "tokens": tokens,
            "fromAllowance": from_allowance, "fromBalance": from_balance,
            "linked": state["account_id"] is not None,
        }))

        return response(200, {
            "answer": answer,
            **usage_payload(
                plan,
                state["used"] + from_allowance,
                state["balance_used"] + from_balance,
                state["balance"] - from_balance,
                state["resets_at"],
            ),
        })

    except UpstreamError as e:

        print(json.dumps({
            "provider": e.provider,
            "status": e.status,
            "details": e.details,
        }, ensure_ascii=False))

        return response(UPSTREAM_ERROR_STATUS, {
            "error": f"{e.provider} API request failed",
            "details": e.details,
        })

    except Exception as e:

        # 原因を調べられるよう、CloudWatch Logsに残す
        traceback.print_exc()

        return response(500, {"error": str(e)})
