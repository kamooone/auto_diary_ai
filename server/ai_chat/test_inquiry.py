"""お問い合わせ(inquiry.py)の動作確認(AWSにつながず、DynamoDBを偽物に差し替えて行う)

  python3 -m unittest server/ai_chat/test_inquiry.py
"""
import json
import os
import sys
import unittest
from datetime import datetime, timedelta, timezone

os.environ["INQUIRY_TABLE_NAME"] = "inquiries"
os.environ["PUSH_TOKEN_TABLE_NAME"] = "push-tokens"
sys.path.insert(0, os.path.dirname(__file__))

import inquiry  # noqa: E402

CLIENT = "a" * 32
OTHER = "b" * 32
NOW = datetime(2026, 11, 9, 12, 0, tzinfo=timezone.utc)


class FakeDynamo:
    """put_item と query だけを、メモリ上で再現する"""

    def __init__(self):
        self.rows = []
        self.tokens = {}

    def put_item(self, TableName, Item):
        if TableName == "push-tokens":
            self.tokens[Item["clientId"]["S"]] = Item
            return
        self.rows.append(Item)

    def query(self, TableName, KeyConditionExpression, ExpressionAttributeValues,
              ScanIndexForward=True, Limit=None, **_):
        client = ExpressionAttributeValues[":c"]["S"]
        since = ExpressionAttributeValues.get(":since", {}).get("S")
        items = [
            r for r in self.rows
            if r["clientId"]["S"] == client and (since is None or r["sk"]["S"] > since)
        ]
        items.sort(key=lambda r: r["sk"]["S"], reverse=not ScanIndexForward)
        return {"Items": items[:Limit] if Limit else items}


def body(message="アプリが落ちます", category="bug", **extra):
    return {"message": message, "category": category, **extra}


class SendInquiryTest(unittest.TestCase):
    def setUp(self):
        self.db = FakeDynamo()

    def send(self, b, client=CLIENT, now=NOW):
        return inquiry.send_inquiry(self.db, client, b, now=now)

    def test_saves_inquiry_with_app_info(self):
        sent = self.send(body(appVersion="1.0.0 (111)", platform="android 15"))

        self.assertEqual(sent["from"], "user")
        self.assertEqual(sent["message"], "アプリが落ちます")
        self.assertEqual(sent["category"], "bug")
        row = self.db.rows[0]
        self.assertEqual(row["clientId"]["S"], CLIENT)
        self.assertEqual(row["appVersion"]["S"], "1.0.0 (111)")
        self.assertEqual(row["platform"]["S"], "android 15")

    def test_message_is_trimmed(self):
        self.assertEqual(self.send(body("  こんにちは \n"))["message"], "こんにちは")

    def test_invalid_input_is_rejected(self):
        for bad, error in [
            (body(""), "message_required"),
            (body("   "), "message_required"),
            ({"category": "bug"}, "message_required"),
            (body(1), "message_required"),
            (body("あ" * 1001), "message_too_long"),
            (body(category="spam"), "invalid_category"),
            ({"message": "a"}, "invalid_category"),
            ("text", "invalid_body"),
        ]:
            with self.assertRaises(inquiry.InquiryError, msg=str(bad)) as cm:
                self.send(bad)
            self.assertEqual((cm.exception.status, cm.exception.error),
                             (400, error))

        self.assertEqual(self.db.rows, [])

    def test_max_length_is_accepted(self):
        self.send(body("あ" * 1000))
        self.assertEqual(len(self.db.rows), 1)

    def test_limit_per_day(self):
        for i in range(inquiry.MAX_PER_DAY):
            self.send(body(f"{i}"), now=NOW + timedelta(minutes=i))

        with self.assertRaises(inquiry.InquiryError) as cm:
            self.send(body("多すぎ"), now=NOW + timedelta(hours=1))
        self.assertEqual((cm.exception.status, cm.exception.error),
                         (429, "too_many_inquiries"))

        # 24時間たてば、また送れる。別の端末には影響しない
        self.send(body("翌日"), now=NOW + timedelta(hours=25))
        self.send(body("別の端末"), client=OTHER, now=NOW + timedelta(hours=1))

    def test_developer_replies_do_not_count_toward_daily_limit(self):
        for i in range(inquiry.MAX_PER_DAY - 1):
            self.send(body(f"{i}"), now=NOW + timedelta(minutes=i))
        for i in range(10):
            self.db.rows.append({
                "clientId": {"S": CLIENT},
                "sk": {"S": inquiry.make_sort_key(NOW + timedelta(minutes=30, seconds=i))},
                "from": {"S": "developer"}, "message": {"S": "返信"},
            })

        self.send(body("最後の1件"), now=NOW + timedelta(hours=1))

    def test_limit_per_client_total(self):
        old = NOW - timedelta(days=30)
        for i in range(inquiry.MAX_MESSAGES_PER_CLIENT):
            self.db.rows.append({
                "clientId": {"S": CLIENT},
                "sk": {"S": inquiry.make_sort_key(old + timedelta(seconds=i))},
                "from": {"S": "user"}, "message": {"S": "x"},
            })

        with self.assertRaises(inquiry.InquiryError) as cm:
            self.send(body())
        self.assertEqual(cm.exception.status, 429)


class ListMessagesTest(unittest.TestCase):
    def setUp(self):
        self.db = FakeDynamo()

    def add(self, sender, text, at, client=CLIENT):
        self.db.rows.append({
            "clientId": {"S": client},
            "sk": {"S": inquiry.make_sort_key(at)},
            "from": {"S": sender}, "message": {"S": text},
            "createdAt": {"S": at.isoformat()},
        })

    def test_returns_own_messages_oldest_first_with_replies(self):
        self.add("user", "質問", NOW)
        self.add("developer", "回答", NOW + timedelta(hours=2))
        self.add("user", "他人", NOW, client=OTHER)

        messages = inquiry.list_messages(self.db, CLIENT)

        self.assertEqual([(m["from"], m["message"]) for m in messages],
                         [("user", "質問"), ("developer", "回答")])
        self.assertEqual(messages[1]["createdAt"],
                         (NOW + timedelta(hours=2)).isoformat())

    def test_returns_only_newest_100(self):
        for i in range(inquiry.MAX_RETURNED + 5):
            self.add("user", f"{i}", NOW + timedelta(minutes=i))

        messages = inquiry.list_messages(self.db, CLIENT)

        self.assertEqual(len(messages), inquiry.MAX_RETURNED)
        self.assertEqual(messages[0]["message"], "5")
        self.assertEqual(messages[-1]["message"], str(inquiry.MAX_RETURNED + 4))

    def test_no_messages(self):
        self.assertEqual(inquiry.list_messages(self.db, CLIENT), [])


class HandleTest(unittest.TestCase):
    def setUp(self):
        self.db = FakeDynamo()

    def test_post_then_get(self):
        status, result = inquiry.handle(
            "POST", self.db, CLIENT, json.dumps(body("要望です", "request"))
        )
        self.assertEqual(status, 200)
        self.assertEqual(result["message"]["message"], "要望です")

        status, result = inquiry.handle("GET", self.db, CLIENT, None)
        self.assertEqual(status, 200)
        self.assertEqual(len(result["messages"]), 1)

    def test_errors_become_status_and_error(self):
        self.assertEqual(
            inquiry.handle("POST", self.db, CLIENT, "not json"),
            (400, {"error": "invalid_body"}),
        )
        self.assertEqual(
            inquiry.handle("POST", self.db, CLIENT, json.dumps(body(""))),
            (400, {"error": "message_required"}),
        )
        self.assertEqual(
            inquiry.handle("POST", self.db, CLIENT, None),
            (400, {"error": "message_required"}),
        )


TOKEN = "fcm:" + "A" * 40


class PushTokenTest(unittest.TestCase):
    def setUp(self):
        self.db = FakeDynamo()
        inquiry.send_inquiry(self.db, CLIENT, body(), now=NOW)

    def register(self, token, client=CLIENT):
        return inquiry.handle_push_token(
            self.db, client, json.dumps({"token": token})
        )

    def test_registers_and_overwrites(self):
        self.assertEqual(self.register(TOKEN), (200, {"ok": True}))
        self.assertEqual(self.db.tokens[CLIENT]["token"]["S"], TOKEN)

        self.register(TOKEN + "2")
        self.assertEqual(self.db.tokens[CLIENT]["token"]["S"], TOKEN + "2")
        self.assertEqual(len(self.db.tokens), 1)

    def test_invalid_token_is_rejected(self):
        for bad in ["short", "a b" * 20, "x" * 4097, 123, None]:
            self.assertEqual(
                self.register(bad), (400, {"error": "invalid_token"}), msg=str(bad)
            )
        self.assertEqual(self.db.tokens, {})

    def test_client_without_inquiry_is_rejected(self):
        self.assertEqual(
            self.register(TOKEN, client=OTHER), (403, {"error": "no_inquiry"})
        )
        self.assertEqual(self.db.tokens, {})

    def test_bad_body(self):
        self.assertEqual(
            inquiry.handle_push_token(self.db, CLIENT, "not json"),
            (400, {"error": "invalid_body"}),
        )
        self.assertEqual(
            inquiry.handle_push_token(self.db, CLIENT, None),
            (400, {"error": "invalid_token"}),
        )


if __name__ == "__main__":
    unittest.main()
