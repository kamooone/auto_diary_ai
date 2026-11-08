#!/usr/bin/env python3
"""AABをGoogle Playの内部テストにアップロードして、公開する(下書きにしない)

  python3 tools/play_upload.py <aabのパス> <リリースノート>

サービスアカウントのJSONを使う(標準ライブラリとopensslだけで動く)。
JSONの場所は、環境変数 PLAY_SERVICE_ACCOUNT_FILE で指定する。
"""
import base64
import json
import os
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request

PACKAGE_NAME = "com.kazusa.auto_diary_ai"
TRACK = "internal"
SCOPE = "https://www.googleapis.com/auth/androidpublisher"
API = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications"
UPLOAD_API = (
    "https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications"
)


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def access_token(account: dict) -> str:
    now = int(time.time())
    header = b64url(json.dumps({"alg": "RS256", "typ": "JWT"}).encode())
    claims = b64url(
        json.dumps(
            {
                "iss": account["client_email"],
                "scope": SCOPE,
                "aud": "https://oauth2.googleapis.com/token",
                "iat": now,
                "exp": now + 3600,
            }
        ).encode()
    )
    unsigned = f"{header}.{claims}".encode()

    # 秘密鍵は、本人だけが読める一時ファイルに置き、署名したらすぐ消す
    with tempfile.NamedTemporaryFile("w", delete=False) as key_file:
        os.chmod(key_file.name, 0o600)
        key_file.write(account["private_key"])
    try:
        signed = subprocess.run(
            ["openssl", "dgst", "-sha256", "-sign", key_file.name, "-binary"],
            input=unsigned,
            check=True,
            capture_output=True,
        ).stdout
    finally:
        os.unlink(key_file.name)

    body = urllib.parse.urlencode(
        {
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion": f"{unsigned.decode()}.{b64url(signed)}",
        }
    ).encode()
    return call("POST", "https://oauth2.googleapis.com/token", None, body, form=True)[
        "access_token"
    ]


def call(method, url, token, body=None, form=False, content_type=None):
    headers = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if form:
        headers["Content-Type"] = "application/x-www-form-urlencoded"
    elif content_type:
        headers["Content-Type"] = content_type
    elif body is not None:
        headers["Content-Type"] = "application/json"
        body = json.dumps(body).encode()

    request = urllib.request.Request(url, data=body, method=method, headers=headers)
    try:
        with urllib.request.urlopen(request, timeout=600) as response:
            return json.load(response)
    except urllib.error.HTTPError as e:
        raise SystemExit(f"ERROR: {method} {url.split('?')[0]} -> {e.code}\n{e.read().decode()}")


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)

    aab_path, notes = sys.argv[1], sys.argv[2]
    account_file = os.environ.get("PLAY_SERVICE_ACCOUNT_FILE", "")

    if not account_file or not os.path.isfile(account_file):
        raise SystemExit("ERROR: PLAY_SERVICE_ACCOUNT_FILE が見つかりません")

    with open(account_file) as f:
        account = json.load(f)

    token = access_token(account)
    base = f"{API}/{PACKAGE_NAME}"

    edit_id = call("POST", f"{base}/edits", token, {})["id"]

    with open(aab_path, "rb") as f:
        bundle = call(
            "POST",
            f"{UPLOAD_API}/{PACKAGE_NAME}/edits/{edit_id}/bundles?uploadType=media",
            token,
            f.read(),
            content_type="application/octet-stream",
        )
    version_code = bundle["versionCode"]
    print(f"Uploaded versionCode {version_code}")

    call(
        "PUT",
        f"{base}/edits/{edit_id}/tracks/{TRACK}",
        token,
        {
            "track": TRACK,
            "releases": [
                {
                    "name": f"{version_code}",
                    "versionCodes": [str(version_code)],
                    "status": "completed",
                    "releaseNotes": [{"language": "ja-JP", "text": notes[:500]}],
                }
            ],
        },
    )
    call("POST", f"{base}/edits/{edit_id}:commit", token, {})
    print(f"Released to the {TRACK} track.")


if __name__ == "__main__":
    main()
