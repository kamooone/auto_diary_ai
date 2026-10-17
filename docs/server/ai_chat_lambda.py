import json
import boto3
import urllib.request
import urllib.error
import base64
import socket
import traceback


secrets_manager = boto3.client("secretsmanager")
s3 = boto3.client("s3")

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

# 1つのモデルを待つ最長の時間(秒)
GEMINI_ATTEMPT_TIMEOUT = 10

# API Gatewayの統合タイムアウト(29秒)に間に合わせるため、残りがこれ未満なら次を試さない
MIN_REMAINING_SECONDS = 12

# 受け付けるプラン。これ以外(未指定を含む)は、無料プランとして扱う
PAID = "paid"
FREE = "free"

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

    for model in GEMINI_MODELS:

        # 時間が足りなければ、次のモデルは試さない
        if last_error is not None and context is not None:
            remaining = context.get_remaining_time_in_millis() / 1000
            if remaining < MIN_REMAINING_SECONDS:
                break

        try:
            data = post_json(
                "Gemini",
                (
                    "https://generativelanguage.googleapis.com/v1beta/models/"
                    f"{model}:generateContent"
                ),
                # URLにキーを付けると、ログに残るため、ヘッダーで渡す
                {"x-goog-api-key": api_key},
                {"contents": [{"role": "user", "parts": parts}]},
                timeout=GEMINI_ATTEMPT_TIMEOUT,
            )
        except UpstreamError as e:
            if e.status not in GEMINI_RETRY_STATUSES:
                raise

            print(json.dumps({
                "provider": "Gemini", "model": model, "status": e.status,
                "action": "switch_model",
            }))
            last_error = e
            continue
        except (socket.timeout, TimeoutError, urllib.error.URLError) as e:
            # 応答が遅い、または接続できないときも、次のモデルを試す
            print(json.dumps({
                "provider": "Gemini", "model": model, "error": str(e),
                "action": "switch_model",
            }))
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
        tokens = data.get("usageMetadata", {}).get("totalTokenCount", 0)

        print(json.dumps({"provider": "Gemini", "model": model}))

        return answer, tokens

    # すべてのモデルが使えなかった
    raise last_error


def response(status, body):
    return {
        "statusCode": status,
        "body": json.dumps(body, ensure_ascii=False),
    }


def lambda_handler(event, context):

    image_keys = []

    try:
        body = json.loads(event.get("body", "{}"))

        message = body.get("message", "")

        if not message:
            return response(400, {"error": "message is required"})

        # アプリから受け取ったプラン
        # (注意: アプリが申告した値のため、課金の確認をするまでは信用できない。
        #  課金を実装したら、購入の確認結果から決める)
        plan = PAID if body.get("plan") == PAID else FREE

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

        # tokensは、使用量の集計に使う(集計は別途実装)
        print(json.dumps({"plan": plan, "tokens": tokens}))

        return response(200, {"answer": answer, "plan": plan})

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
