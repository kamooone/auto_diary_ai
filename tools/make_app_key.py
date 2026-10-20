#!/usr/bin/env python3
"""ゲームごとの秘密のキーを作る

  python3 tools/make_app_key.py kamoooneshot

出力:
  - キー        : ゲームアプリに入れる。他人に見せない・リポジトリに入れない
  - ハッシュ    : AWSのLambdaの環境変数 APP_KEY_HASHES に入れる(漏れても元のキーは分からない)

APP_KEY_HASHES は、JSONで {"アプリID": "ハッシュ", ...} の形にする。
"""
import hashlib
import secrets
import sys

APP_IDS = ["kamoooneshot", "escape_2", "escape_3", "escape_4"]


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in APP_IDS:
        print(f"使い方: python3 tools/make_app_key.py <アプリID>\nアプリID: {', '.join(APP_IDS)}")
        return 1

    key = secrets.token_urlsafe(32)
    digest = hashlib.sha256(key.encode("utf-8")).hexdigest()

    print(f"アプリID : {sys.argv[1]}")
    print(f"キー     : {key}")
    print(f"ハッシュ : {digest}")
    print()
    print("環境変数 APP_KEY_HASHES に追加する部分:")
    print(f'  "{sys.argv[1]}": "{digest}"')
    return 0


if __name__ == "__main__":
    sys.exit(main())
