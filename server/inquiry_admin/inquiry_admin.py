"""お問い合わせの確認と返信(開発者が、自分のパソコンで使う。Lambdaには置かない)

AWSの認証情報が設定してあるパソコンで実行する(aws configure 済み。boto3 が必要)。

  python3 server/inquiry_admin/inquiry_admin.py list             # 返信待ちの端末の一覧
  python3 server/inquiry_admin/inquiry_admin.py list --all       # すべての端末
  python3 server/inquiry_admin/inquiry_admin.py show <端末のID>  # やり取りを全部見る
  python3 server/inquiry_admin/inquiry_admin.py reply <端末のID> "返信の文章"

環境変数 INQUIRY_TABLE_NAME(なければ auto-diary-inquiries)、AWS_REGION(なければ ap-northeast-1)
"""
import os
import sys
from datetime import datetime, timezone

TABLE_NAME = os.environ.get("INQUIRY_TABLE_NAME", "auto-diary-inquiries")

CATEGORY_LABELS = {"bug": "不具合", "request": "要望", "other": "その他"}

MAX_REPLY_LENGTH = 1000


def scan_all(dynamodb):
    items = []
    params = {"TableName": TABLE_NAME}

    while True:
        result = dynamodb.scan(**params)
        items += result.get("Items", [])

        if "LastEvaluatedKey" not in result:
            return items

        params["ExclusiveStartKey"] = result["LastEvaluatedKey"]


def threads(items):
    """端末ごとに、古い順に並べた行をまとめる: {clientId: [行, ...]}"""
    result = {}

    for item in sorted(items, key=lambda e: e["sk"]["S"]):
        result.setdefault(item["clientId"]["S"], []).append(item)

    return result


def is_waiting(rows):
    """最後が端末(ユーザー)からの送信なら、返信待ち"""
    return rows[-1].get("from", {}).get("S") != "developer"


def format_row(item):
    sender = "開発者" if item.get("from", {}).get("S") == "developer" else "ユーザー"
    category = CATEGORY_LABELS.get(item.get("category", {}).get("S"), "")
    info = " ".join(
        item[k]["S"] for k in ("appVersion", "platform") if k in item
    )
    head = f"[{item['createdAt']['S'] if 'createdAt' in item else item['sk']['S']}] {sender}"
    if category:
        head += f"({category})"
    if info:
        head += f" {info}"

    return f"{head}\n{item.get('message', {}).get('S', '')}"


def list_threads(dynamodb, show_all=False):
    """一覧の文字列。新しい問い合わせが上"""
    grouped = threads(scan_all(dynamodb))
    lines = []

    ordered = sorted(grouped.items(), key=lambda e: e[1][-1]["sk"]["S"], reverse=True)

    for client_id, rows in ordered:
        if not show_all and not is_waiting(rows):
            continue

        last = rows[-1]
        status = "返信待ち" if is_waiting(rows) else "返信済み"
        text = last.get("message", {}).get("S", "").replace("\n", " ")
        lines.append(
            f"{client_id}  {status}  {last['sk']['S'][:16]}  {len(rows)}件  {text[:40]}"
        )

    return "\n".join(lines) if lines else "(なし)"


def show_thread(dynamodb, client_id):
    result = dynamodb.query(
        TableName=TABLE_NAME,
        KeyConditionExpression="clientId = :c",
        ExpressionAttributeValues={":c": {"S": client_id}},
    )
    rows = result.get("Items", [])

    if not rows:
        return "(その端末のやり取りはありません)"

    return "\n\n".join(format_row(r) for r in rows)


def reply(dynamodb, client_id, text, now=None):
    """返信を書き込む。やり取りのない端末のIDにはできない"""
    text = text.strip()

    if not text:
        raise ValueError("返信が空です")

    if len(text) > MAX_REPLY_LENGTH:
        raise ValueError(f"返信は{MAX_REPLY_LENGTH}文字までです")

    exists = dynamodb.query(
        TableName=TABLE_NAME,
        KeyConditionExpression="clientId = :c",
        ExpressionAttributeValues={":c": {"S": client_id}},
        Limit=1,
    ).get("Items")

    if not exists:
        raise ValueError("その端末のIDで、問い合わせが見つかりません")

    now = (now or datetime.now(timezone.utc)).astimezone(timezone.utc)
    sort_key = f"{now.strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3]}Z#admin"

    dynamodb.put_item(
        TableName=TABLE_NAME,
        Item={
            "clientId": {"S": client_id},
            "sk": {"S": sort_key},
            "from": {"S": "developer"},
            "message": {"S": text},
            "createdAt": {"S": now.isoformat()},
        },
    )

    return sort_key


def main(argv):
    import boto3

    dynamodb = boto3.client(
        "dynamodb", region_name=os.environ.get("AWS_REGION", "ap-northeast-1")
    )
    command = argv[1] if len(argv) > 1 else ""

    if command == "list":
        print(list_threads(dynamodb, show_all="--all" in argv))
    elif command == "show" and len(argv) == 3:
        print(show_thread(dynamodb, argv[2]))
    elif command == "reply" and len(argv) == 4:
        reply(dynamodb, argv[2], argv[3])
        print("返信しました")
    else:
        print(__doc__)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
