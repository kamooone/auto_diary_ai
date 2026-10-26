"""AIのLambdaの、使用量まわりの動作確認(AWSにつながず、DynamoDBを偽物に差し替えて行う)

  python3 -m unittest server/ai_chat/test_ai_chat_lambda.py
"""
import hashlib
import json
import os
import sys
import types
import unittest
from datetime import datetime
from unittest import mock

os.environ["USAGE_TABLE_NAME"] = "usage"
os.environ["ACCOUNTS_TABLE_NAME"] = "accounts"
os.environ["DEVICES_TABLE_NAME"] = "devices"


class ClientError(Exception):
    def __init__(self, response, operation):
        super().__init__(operation)
        self.response = response


class FakeDynamo:
    """使う操作だけを、メモリ上で再現する"""

    def __init__(self):
        self.tables = {"usage": {}, "accounts": {}, "devices": {}}

    def get_item(self, TableName, Key, **_):
        key = next(iter(Key.values()))["S"]
        item = self.tables[TableName].get(key)
        return {"Item": item} if item else {}

    def update_item(self, TableName, Key, ExpressionAttributeValues, **kw):
        key = next(iter(Key.values()))["S"]
        table = self.tables[TableName]

        if TableName == "usage":
            row = table.setdefault(key, {"usedTokens": {"N": "0"}})
            for name, field in ((":a", "usedTokens"), (":b", "balanceUsedTokens")):
                before = int(row.get(field, {"N": "0"})["N"])
                row[field] = {
                    "N": str(before + int(ExpressionAttributeValues[name]["N"]))
                }
            row["expiresAt"] = ExpressionAttributeValues[":ttl"]
            return {}

        n = int(ExpressionAttributeValues[":n"]["N"])

        row = table[key]
        if int(row["tokens"]["N"]) < n:
            raise ClientError(
                {"Error": {"Code": "ConditionalCheckFailedException"}}, "u"
            )
        row["tokens"] = {"N": str(int(row["tokens"]["N"]) - n)}
        return {}


fake_dynamo = FakeDynamo()


def fake_client(name, *a, **k):
    return fake_dynamo if name == "dynamodb" else mock.MagicMock()


sys.modules["boto3"] = types.SimpleNamespace(client=fake_client)
botocore = types.ModuleType("botocore")
exceptions = types.ModuleType("botocore.exceptions")
exceptions.ClientError = ClientError
sys.modules["botocore"] = botocore
sys.modules["botocore.exceptions"] = exceptions

sys.path.insert(0, os.path.dirname(__file__))
import ai_chat_lambda as m  # noqa: E402

CLIENT_ID = "a" * 32
FREE_LIMIT = m.MONTHLY_LIMIT_TOKENS[m.FREE]


def sha(value):
    return hashlib.sha256(value.encode()).hexdigest()


def chat_event(plan="free", device_token=None, client_id=CLIENT_ID):
    headers = {}
    if client_id:
        headers["X-Client-Id"] = client_id
    if device_token:
        headers["X-Device-Token"] = device_token
    return {
        "routeKey": "POST /ai/chat",
        "headers": headers,
        "body": json.dumps({"message": "こんにちは", "plan": plan}),
    }


def usage_event(plan="free", device_token=None):
    event = chat_event(plan, device_token)
    event["routeKey"] = "GET /plan/usage"
    event["body"] = None
    event["queryStringParameters"] = {"plan": plan}
    return event


def call(event):
    result = m.lambda_handler(event, mock.MagicMock())
    return result["statusCode"], json.loads(result["body"])


class AiChatUsageTest(unittest.TestCase):
    def setUp(self):
        fake_dynamo.tables = {"usage": {}, "accounts": {}, "devices": {}}
        self.month, _ = m.month_window()
        self.usage_key = f"{CLIENT_ID}#{self.month}"

        patcher = mock.patch.object(m, "ask_gemini")
        self.gemini = patcher.start()
        self.gemini.return_value = ("日記", 1000)
        self.addCleanup(patcher.stop)

        patcher = mock.patch.object(m, "ask_openai")
        self.openai = patcher.start()
        self.openai.return_value = ("日記", 1000)
        self.addCleanup(patcher.stop)

        patcher = mock.patch.object(m, "get_api_key", return_value="key")
        patcher.start()
        self.addCleanup(patcher.stop)

    def set_used(self, tokens):
        fake_dynamo.tables["usage"][self.usage_key] = {
            "usedTokens": {"N": str(tokens)}
        }

    def used(self):
        row = fake_dynamo.tables["usage"].get(self.usage_key)
        return int(row["usedTokens"]["N"]) if row else 0

    def set_balance_used(self, tokens):
        row = fake_dynamo.tables["usage"].setdefault(
            self.usage_key, {"usedTokens": {"N": "0"}}
        )
        row["balanceUsedTokens"] = {"N": str(tokens)}

    def link_device(self, balance):
        fake_dynamo.tables["devices"]["dev1"] = {
            "deviceId": {"S": "dev1"},
            "accountId": {"S": "acc1"},
            "tokenHash": {"S": sha("secret")},
        }
        fake_dynamo.tables["accounts"]["acc1"] = {"tokens": {"N": str(balance)}}

    def balance(self):
        return int(fake_dynamo.tables["accounts"]["acc1"]["tokens"]["N"])

    def test_month_window(self):
        jst = m.JST
        key, resets = m.month_window(datetime(2026, 10, 19, 12, tzinfo=jst))
        self.assertEqual(key, "2026-10")
        self.assertEqual(resets, "2026-11-01T00:00:00+09:00")

        key, resets = m.month_window(datetime(2026, 12, 31, 23, 59, tzinfo=jst))
        self.assertEqual(key, "2026-12")
        self.assertEqual(resets, "2027-01-01T00:00:00+09:00")

    def test_without_account_reduces_monthly_allowance(self):
        status, body = call(chat_event())

        self.assertEqual(status, 200)
        self.assertEqual(self.used(), 1000)
        self.assertEqual(body["usage"]["usedTokens"], 1000)
        self.assertEqual(body["usage"]["limitTokens"], FREE_LIMIT)
        self.assertEqual(body["tokenBalance"], 0)
        self.gemini.assert_called_once()

    def test_paid_plan_is_treated_as_free_while_disabled(self):
        status, body = call(chat_event(plan="paid"))

        self.assertEqual(status, 200)
        self.gemini.assert_called_once()
        self.openai.assert_not_called()
        self.assertEqual(body["usage"]["limitTokens"], FREE_LIMIT)

        status, body = call(usage_event(plan="paid"))
        self.assertEqual(body["plan"], "free")

    @mock.patch.object(m, "PAID_ENABLED", True)
    def test_paid_plan_uses_gpt_and_its_own_limit(self):
        status, body = call(chat_event(plan="paid"))

        self.assertEqual(status, 200)
        self.openai.assert_called_once()
        self.gemini.assert_not_called()
        self.assertEqual(
            body["usage"]["limitTokens"], m.MONTHLY_LIMIT_TOKENS[m.PAID]
        )

    def test_missing_client_id_is_rejected(self):
        status, body = call(chat_event(client_id=None))

        self.assertEqual(status, 400)
        self.gemini.assert_not_called()

    def test_exceeded_without_balance_is_refused_without_calling_ai(self):
        self.set_used(FREE_LIMIT)

        status, body = call(chat_event())

        self.assertEqual(status, 429)
        self.assertEqual(body["error"], "usage_limit_exceeded")
        self.assertEqual(body["usage"]["usedTokens"], FREE_LIMIT)
        self.gemini.assert_not_called()

    def test_balance_extends_usable_amount(self):
        self.link_device(balance=5000)
        self.set_used(FREE_LIMIT)

        status, body = call(chat_event(device_token="dev1.secret"))

        # 毎月の枠が尽きているため、アカウントのトークンから減る
        self.assertEqual(status, 200)
        self.assertEqual(self.balance(), 4000)
        self.assertEqual(self.used(), FREE_LIMIT)
        self.assertEqual(body["tokenBalance"], 4000)
        # 使った量は、残高から使った分も含み、分母は縮まない
        self.assertEqual(body["usage"]["usedTokens"], FREE_LIMIT + 1000)
        self.assertEqual(body["usage"]["limitTokens"], FREE_LIMIT + 5000)

    def test_usage_is_split_between_allowance_and_balance(self):
        self.link_device(balance=5000)
        self.set_used(FREE_LIMIT - 400)

        status, body = call(chat_event(device_token="dev1.secret"))

        self.assertEqual(status, 200)
        self.assertEqual(self.used(), FREE_LIMIT)
        self.assertEqual(self.balance(), 5000 - 600)

    def test_balance_never_goes_negative(self):
        self.link_device(balance=300)
        self.set_used(FREE_LIMIT)

        status, body = call(chat_event(device_token="dev1.secret"))

        self.assertEqual(status, 200)
        self.assertEqual(self.balance(), 0)

    def test_balance_is_kept_while_allowance_remains(self):
        self.link_device(balance=5000)

        call(chat_event(device_token="dev1.secret"))

        self.assertEqual(self.balance(), 5000)
        self.assertEqual(self.used(), 1000)

    def test_unlinked_or_wrong_device_token_is_401(self):
        self.link_device(balance=5000)

        for token in ["dev1.wrong", "nodevice.secret", "garbage"]:
            status, body = call(chat_event(device_token=token))
            self.assertEqual(status, 401)
            self.assertEqual(body["error"], "invalid_device_token")

        self.gemini.assert_not_called()
        self.assertEqual(self.balance(), 5000)

    def test_display_adds_balance_to_the_monthly_limit(self):
        # 残高10,000 を足した状態で、毎月の枠 + 3,000 使った場合
        self.link_device(balance=10_000)
        self.set_used(FREE_LIMIT)
        self.set_balance_used(3_000)
        fake_dynamo.tables["accounts"]["acc1"] = {"tokens": {"N": "7000"}}

        status, body = call(usage_event(device_token="dev1.secret"))

        self.assertEqual(status, 200)
        self.assertEqual(body["usage"]["usedTokens"], FREE_LIMIT + 3_000)
        self.assertEqual(body["usage"]["limitTokens"], FREE_LIMIT + 10_000)
        self.assertEqual(body["tokenBalance"], 7_000)

        status, body = call(chat_event(device_token="dev1.secret"))

        # さらに1,000 使うと、枠 + 4,000 / 枠 + 10,000
        self.assertEqual(body["usage"]["usedTokens"], FREE_LIMIT + 4_000)
        self.assertEqual(body["usage"]["limitTokens"], FREE_LIMIT + 10_000)

    def test_next_month_resets_used_but_keeps_balance(self):
        self.link_device(balance=6_000)
        self.set_used(FREE_LIMIT)
        self.set_balance_used(4_000)
        # 翌月の行はまだないため、使った量は0に戻る
        with mock.patch.object(
            m, "month_window", return_value=("2026-11", "2026-12-01T00:00:00+09:00")
        ):
            status, body = call(usage_event(device_token="dev1.secret"))

        self.assertEqual(body["usage"]["usedTokens"], 0)
        self.assertEqual(body["usage"]["limitTokens"], FREE_LIMIT + 6_000)

    def test_plan_usage(self):
        self.link_device(balance=2500)
        self.set_used(700)

        status, body = call(usage_event(device_token="dev1.secret"))

        self.assertEqual(status, 200)
        self.assertEqual(body["usage"]["usedTokens"], 700)
        self.assertEqual(body["usage"]["limitTokens"], FREE_LIMIT + 2500)
        self.assertEqual(body["tokenBalance"], 2500)
        self.assertEqual(body["plan"], "free")
        self.gemini.assert_not_called()

    def test_plan_usage_from_rest_api_event(self):
        # REST APIのプロキシ統合は、routeKeyがなく、httpMethodとresourceで届く
        event = usage_event()
        del event["routeKey"]
        event["httpMethod"] = "GET"
        event["resource"] = "/plan/usage"

        status, body = call(event)

        self.assertEqual(status, 200)
        self.assertEqual(body["usage"]["limitTokens"], FREE_LIMIT)
        self.gemini.assert_not_called()

    def test_chat_from_rest_api_event_is_not_usage_request(self):
        event = chat_event()
        del event["routeKey"]
        event["httpMethod"] = "POST"
        event["resource"] = "/ai/chat"

        status, _ = call(event)

        self.assertEqual(status, 200)
        self.gemini.assert_called_once()

    def test_plan_usage_requires_client_id(self):
        event = usage_event()
        event["headers"] = {}

        status, _ = call(event)

        self.assertEqual(status, 400)


if __name__ == "__main__":
    unittest.main()
