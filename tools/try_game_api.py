#!/usr/bin/env python3
"""ゲームのAPI(紐づけと、ポイントの付与)を、順番に試す

  python3 tools/try_game_api.py kamoooneshot

案内に従って進める。ゲームのキーは、入力しても画面に出ない。
キー・合言葉・端末用のトークンは、画面に表示しない。
"""
import getpass
import json
import sys
import time
import urllib.error
import urllib.request
import uuid

API = "https://137rd6syod.execute-api.ap-northeast-1.amazonaws.com"
WEB = "https://dq2edjyr3ccb9.cloudfront.net/index.html"


def call(path, body, headers):
    request = urllib.request.Request(
        API + path,
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json", **headers},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            return response.status, json.loads(response.read())
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read())
        except ValueError:
            return e.code, {}


def show_result(title, status, body):
    safe = {k: v for k, v in body.items() if k not in ("claimSecret", "deviceToken")}
    print(f"  {title}: HTTP {status} {json.dumps(safe, ensure_ascii=False)}")


def main():
    if len(sys.argv) != 2:
        print("使い方: python3 tools/try_game_api.py <アプリID>  (例: kamoooneshot)")
        return 1

    app_id = sys.argv[1]
    key = getpass.getpass("ゲームのキーを貼り付けて Enter(画面には出ません): ").strip()
    app_headers = {"X-App-Key": key}

    print("\n[1] 紐づけコードを発行します")
    status, body = call("/pairing/start", {"appId": app_id, "label": "curl"}, app_headers)
    show_result("結果", status, body)
    if status != 200:
        print("  → 発行できませんでした。キーが、環境変数 APP_KEY_HASHES のハッシュと合っているか確認してください。")
        return 1

    print(f"\n[2] ブラウザで {WEB} を開き、ログインして、")
    print(f"    「アプリを紐づける」に、このコードを入力してください:  {body['code']}")
    print("    確認画面に「KamoooneShot」などのゲーム名が出たら、OK を押して紐づけます。")
    input("    紐づけたら、ここで Enter を押してください… ")

    print("\n[3] 端末用のトークンを受け取ります")
    status, claimed = call(
        "/pairing/claim", {"code": body["code"], "claimSecret": body["claimSecret"]}, {}
    )
    show_result("結果", status, claimed)
    token = claimed.get("deviceToken")
    if not token:
        print("  → トークンを受け取れませんでした(まだ紐づけていない、または期限切れ)。最初からやり直してください。")
        return 1

    headers = {**app_headers, "X-Device-Token": token}

    print("\n[4] 成果を送ります")
    event_id = uuid.uuid4().hex
    tries = [
        ("daily_first_play を送る(100ポイントのはず)", event_id, "daily_first_play"),
        ("同じ eventId をもう一度送る(duplicate のはず)", event_id, "daily_first_play"),
        ("別の eventId で daily_first_play(event_limit のはず)", uuid.uuid4().hex, "daily_first_play"),
        ("stage_clear を送る(50ポイントのはず)", uuid.uuid4().hex, "stage_clear"),
    ]
    for title, event_id_to_send, event_type in tries:
        status, result = call(
            "/events", {"eventId": event_id_to_send, "type": event_type}, headers
        )
        show_result(title, status, result)
        time.sleep(0.5)

    print("\n完了。Web のページを再読み込みして、ポイントが増えているか確認してください。")
    print("(今日すでに daily_first_play を送っていた場合、1回目も event_limit になります)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
