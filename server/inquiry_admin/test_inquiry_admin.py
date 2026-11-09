"""inquiry_admin.py の動作確認

  python3 -m unittest server/inquiry_admin/test_inquiry_admin.py
"""
import os
import sys
import unittest
from datetime import datetime, timezone

sys.path.insert(0, os.path.dirname(__file__))

import inquiry_admin as admin  # noqa: E402

A, B = "a" * 32, "b" * 32


def row(client, sk, sender, text, **extra):
    item = {
        "clientId": {"S": client}, "sk": {"S": sk}, "from": {"S": sender},
        "message": {"S": text}, "createdAt": {"S": sk},
    }
    item.update({k: {"S": v} for k, v in extra.items()})
    return item


class FakeDynamo:
    def __init__(self, rows):
        self.rows = list(rows)

    def scan(self, TableName, **_):
        return {"Items": self.rows}

    def query(self, TableName, ExpressionAttributeValues, Limit=None, **_):
        client = ExpressionAttributeValues[":c"]["S"]
        items = sorted(
            (r for r in self.rows if r["clientId"]["S"] == client),
            key=lambda r: r["sk"]["S"],
        )
        return {"Items": items[:Limit] if Limit else items}

    def put_item(self, TableName, Item):
        self.rows.append(Item)


class AdminTest(unittest.TestCase):
    def setUp(self):
        self.db = FakeDynamo([
            row(A, "2026-11-01T10:00:00.000Z#1", "user", "Aの質問", category="bug"),
            row(A, "2026-11-02T10:00:00.000Z#admin", "developer", "Aへの返信"),
            row(B, "2026-11-03T10:00:00.000Z#2", "user", "Bの質問", category="request"),
        ])

    def test_list_shows_only_waiting_by_default(self):
        text = admin.list_threads(self.db)

        self.assertIn(B, text)
        self.assertNotIn(A, text)
        self.assertIn("返信待ち", text)

    def test_list_all_includes_answered(self):
        text = admin.list_threads(self.db, show_all=True)

        self.assertIn(A, text)
        self.assertIn("返信済み", text)
        self.assertLess(text.index(B), text.index(A))  # 新しい方が上

    def test_list_when_nothing_waiting(self):
        db = FakeDynamo([row(A, "2026-11-01T10:00:00.000Z#1", "developer", "x")])
        self.assertEqual(admin.list_threads(db), "(なし)")

    def test_show_prints_conversation_in_order(self):
        text = admin.show_thread(self.db, A)

        self.assertLess(text.index("Aの質問"), text.index("Aへの返信"))
        self.assertIn("(不具合)", text)
        self.assertNotIn("Bの質問", text)

    def test_reply_is_written_as_developer_after_existing_rows(self):
        now = datetime(2026, 11, 9, 0, 0, tzinfo=timezone.utc)
        key = admin.reply(self.db, B, "  お返事です ", now=now)

        added = self.db.rows[-1]
        self.assertEqual(added["from"]["S"], "developer")
        self.assertEqual(added["message"]["S"], "お返事です")
        self.assertEqual(added["sk"]["S"], key)
        self.assertGreater(key, "2026-11-03T10:00:00.000Z#2")
        self.assertFalse(admin.is_waiting(admin.threads(self.db.rows)[B]))

    def test_reply_rejects_unknown_client_and_bad_text(self):
        for client, text in [("c" * 32, "x"), (A, "  "), (A, "あ" * 1001)]:
            with self.assertRaises(ValueError):
                admin.reply(self.db, client, text)


if __name__ == "__main__":
    unittest.main()
