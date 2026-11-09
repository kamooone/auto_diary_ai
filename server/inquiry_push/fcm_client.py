"""FCM(Firebaseのプッシュ通知)に送るための部品

Lambdaに入っている boto3 だけで動くよう、サービスアカウントの鍵による署名(RS256)を、
標準ライブラリだけで行う(google-auth などを、Lambdaに追加しなくて済むようにするため)。
"""
import base64
import hashlib
import json
import re
import time
import urllib.error
import urllib.parse
import urllib.request

TOKEN_URL = "https://oauth2.googleapis.com/token"
FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging"

# SHA-256 の DigestInfo(PKCS#1 v1.5 の署名の頭につける決まった並び)
SHA256_DIGEST_INFO = bytes.fromhex("3031300d060960864801650304020105000420")


class FcmError(Exception):
    pass


# ----------------------------------------------------------------------
# 秘密鍵(PEM)の読み取りと、RS256の署名
# ----------------------------------------------------------------------

def _read_der(data, pos):
    """DERの1要素を読む: (タグ, 中身の開始位置, 中身の終わりの位置)"""
    tag = data[pos]
    length = data[pos + 1]
    pos += 2

    if length & 0x80:
        size = length & 0x7F
        length = int.from_bytes(data[pos:pos + size], "big")
        pos += size

    return tag, pos, pos + length


def _read_sequence_items(data, start, end):
    items = []
    pos = start

    while pos < end:
        tag, body_start, body_end = _read_der(data, pos)
        items.append((tag, body_start, body_end))
        pos = body_end

    return items


def parse_private_key(pem):
    """RSAの秘密鍵(PEM。PKCS#8 でも PKCS#1 でも可)から、(n, d)を返す"""
    body = re.sub(r"-----[A-Z ]+-----|\s", "", pem)
    der = base64.b64decode(body)

    tag, start, end = _read_der(der, 0)
    if tag != 0x30:
        raise FcmError("private key is not a DER sequence")

    items = _read_sequence_items(der, start, end)

    # PKCS#8: SEQUENCE { INTEGER 0, SEQUENCE {...}, OCTET STRING { RSAPrivateKey } }
    if len(items) >= 3 and items[2][0] == 0x04:
        inner_start, inner_end = items[2][1], items[2][2]
        tag, start, end = _read_der(der, inner_start)
        items = _read_sequence_items(der, start, end)

    # RSAPrivateKey: SEQUENCE { version, n, e, d, ... }
    if len(items) < 4 or any(i[0] != 0x02 for i in items[:4]):
        raise FcmError("unsupported private key format")

    def integer(item):
        return int.from_bytes(der[item[1]:item[2]], "big")

    return integer(items[1]), integer(items[3])


def rs256_sign(message, n, d):
    """RSASSA-PKCS1-v1_5 と SHA-256 で署名する"""
    size = (n.bit_length() + 7) // 8
    digest_info = SHA256_DIGEST_INFO + hashlib.sha256(message).digest()
    padding = b"\xff" * (size - len(digest_info) - 3)
    encoded = b"\x00\x01" + padding + b"\x00" + digest_info

    signature = pow(int.from_bytes(encoded, "big"), d, n)
    return signature.to_bytes(size, "big")


def _b64url(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def make_jwt(service_account, now=None):
    """Googleのアクセストークンをもらうための、署名つきの申込書(JWT)"""
    now = int(now if now is not None else time.time())

    header = {"alg": "RS256", "typ": "JWT"}
    claims = {
        "iss": service_account["client_email"],
        "scope": FCM_SCOPE,
        "aud": TOKEN_URL,
        "iat": now,
        "exp": now + 3600,
    }
    signing_input = (
        _b64url(json.dumps(header, separators=(",", ":")).encode())
        + "."
        + _b64url(json.dumps(claims, separators=(",", ":")).encode())
    )

    n, d = parse_private_key(service_account["private_key"])
    signature = rs256_sign(signing_input.encode(), n, d)

    return signing_input + "." + _b64url(signature)


# ----------------------------------------------------------------------
# 通信
# ----------------------------------------------------------------------

def _post(url, data, headers, timeout=10):
    """(ステータス, 本文のdict)を返す。通信できなければ FcmError"""
    request = urllib.request.Request(
        url, data=data, headers=headers, method="POST"
    )

    try:
        with urllib.request.urlopen(request, timeout=timeout) as r:
            status, text = r.status, r.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        status, text = e.code, e.read().decode("utf-8", "replace")
    except (urllib.error.URLError, TimeoutError, OSError) as e:
        raise FcmError(f"network error: {type(e).__name__}")

    try:
        return status, json.loads(text) if text else {}
    except json.JSONDecodeError:
        return status, {}


_cached = {"token": None, "expires": 0}


def get_access_token(service_account, post=_post, now=None):
    """アクセストークンを返す(期限まで使い回す)"""
    now = now if now is not None else time.time()

    if _cached["token"] and now < _cached["expires"] - 60:
        return _cached["token"]

    form = urllib.parse.urlencode({
        "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "assertion": make_jwt(service_account, now),
    }).encode()
    status, body = post(
        TOKEN_URL, form, {"Content-Type": "application/x-www-form-urlencoded"}
    )

    if status != 200 or "access_token" not in body:
        raise FcmError(f"token request failed: {status}")

    _cached["token"] = body["access_token"]
    _cached["expires"] = now + int(body.get("expires_in", 3600))
    return _cached["token"]


def send_push(project_id, access_token, device_token, title, body, data,
              post=_post):
    """通知を1件送る。戻り値: "ok" または "unregistered"(宛先がもう使えない)

    それ以外の失敗は FcmError。
    """
    message = {
        "message": {
            "token": device_token,
            "notification": {"title": title, "body": body},
            "data": data,
            "android": {"priority": "high"},
        }
    }
    status, result = post(
        f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send",
        json.dumps(message).encode(),
        {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
        },
    )

    if status == 200:
        return "ok"

    error = result.get("error", {}) if isinstance(result, dict) else {}
    codes = {
        d.get("errorCode")
        for d in error.get("details", [])
        if isinstance(d, dict)
    }

    if status == 404 or "UNREGISTERED" in codes:
        return "unregistered"

    raise FcmError(f"send failed: {status} {error.get('status', '')}")
