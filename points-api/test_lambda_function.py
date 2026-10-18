"""Lambdaの動作確認(AWSにつながず、DynamoDBを偽物に差し替えて行う)

  python3 -m unittest points-api/test_lambda_function.py
"""
import json
import os
import sys
import types
import unittest
from unittest import mock

os.environ["TABLE_NAME"] = "accounts"
os.environ["LEDGER_TABLE_NAME"] = "ledger"
os.environ["ENABLE_DEV_GRANT"] = "true"

# boto3がなくても動かせるよう、偽物を先に登録する
fake_client = mock.MagicMock()
sys.modules["boto3"] = types.SimpleNamespace(client=lambda *a, **k: fake_client)

botocore = types.ModuleType("botocore")
exceptions = types.ModuleType("botocore.exceptions")


class ClientError(Exception):
    def __init__(self, response, operation):
        super().__init__(operation)
        self.response = response


exceptions.ClientError = ClientError
sys.modules["botocore"] = botocore
sys.modules["botocore.exceptions"] = exceptions

sys.path.insert(0, os.path.dirname(__file__))
import lambda_function as m  # noqa: E402


def event(route, body=None):
    return {
        "routeKey": route,
        "body": json.dumps(body) if body is not None else None,
        "requestContext": {"authorizer": {"jwt": {"claims": {"sub": "user-1"}}}},
    }


def balance_item(points, tokens):
    return {"Item": {"points": {"N": str(points)}, "tokens": {"N": str(tokens)}}}


class ExchangeTest(unittest.TestCase):
    def setUp(self):
        fake_client.reset_mock(side_effect=True)
        fake_client.get_item.return_value = balance_item(0, 12000)

    def call(self, body):
        result = m.lambda_handler(event("POST /exchange", body), None)
        return result["statusCode"], json.loads(result["body"])

    def test_最低ポイント未満は交換できない(self):
        status, body = self.call({"points": 9999})
        self.assertEqual((status, body["error"]), (400, "below_minimum"))
        fake_client.transact_write_items.assert_not_called()

    def test_整数以外は受け付けない(self):
        for bad in ("10000", 10000.5, True, None, -5, 0):
            status, body = self.call({"points": bad})
            self.assertEqual((status, body["error"]), (400, "invalid_points"), bad)
        fake_client.transact_write_items.assert_not_called()

    def test_交換すると残高と履歴を同時に更新する(self):
        status, body = self.call({"points": 12000, "requestId": "abc"})
        self.assertEqual(status, 200)
        self.assertEqual(body["tokens"], 12000)

        args = fake_client.transact_write_items.call_args.kwargs
        update = args["TransactItems"][0]["Update"]
        put = args["TransactItems"][1]["Put"]
        self.assertEqual(update["ConditionExpression"], "points >= :points")
        self.assertEqual(update["ExpressionAttributeValues"][":tokens"], {"N": "12000"})
        self.assertEqual(put["Item"]["pointsDelta"], {"N": "-12000"})
        self.assertEqual(put["Item"]["tokensDelta"], {"N": "12000"})
        self.assertEqual(args["ClientRequestToken"], "abc")

        # DynamoDBは、式で使っていない値が渡されるとエラーにする
        expressions = update["UpdateExpression"] + " " + update["ConditionExpression"]
        for name in update["ExpressionAttributeValues"]:
            self.assertIn(name, expressions)

    def test_ポイントが足りないときは交換されない(self):
        fake_client.transact_write_items.side_effect = ClientError(
            {
                "Error": {"Code": "TransactionCanceledException"},
                "CancellationReasons": [{"Code": "ConditionalCheckFailed"}, {"Code": "None"}],
            },
            "TransactWriteItems",
        )
        status, body = self.call({"points": 10000})
        self.assertEqual((status, body["error"]), (400, "insufficient_points"))

    def test_想定外のエラーは500(self):
        fake_client.transact_write_items.side_effect = ClientError(
            {"Error": {"Code": "ProvisionedThroughputExceededException"}},
            "TransactWriteItems",
        )
        status, body = self.call({"points": 10000})
        self.assertEqual((status, body["error"]), (500, "internal_error"))


class DevGrantTest(unittest.TestCase):
    def setUp(self):
        fake_client.reset_mock(side_effect=True)
        fake_client.get_item.return_value = balance_item(10, 0)

    def test_上限を超える追加は受け付けない(self):
        result = m.lambda_handler(
            event("POST /dev/grant", {"amount": m.DEV_GRANT_MAX + 1}), None
        )
        self.assertEqual(result["statusCode"], 400)

    def test_無効にすると404(self):
        with mock.patch.object(m, "ENABLE_DEV_GRANT", False):
            result = m.lambda_handler(event("POST /dev/grant", {"amount": 10}), None)
        self.assertEqual(result["statusCode"], 404)

    def test_履歴も残る(self):
        result = m.lambda_handler(event("POST /dev/grant", {"amount": 10}), None)
        self.assertEqual(result["statusCode"], 200)
        items = fake_client.transact_write_items.call_args.kwargs["TransactItems"]
        self.assertEqual(items[1]["Put"]["Item"]["type"], {"S": "dev_grant"})

        update = items[0]["Update"]
        for name in update["ExpressionAttributeValues"]:
            self.assertIn(name, update["UpdateExpression"])


class MeTest(unittest.TestCase):
    def test_交換のルールも返す(self):
        fake_client.update_item.return_value = {
            "Attributes": {"points": {"N": "5"}, "tokens": {"N": "0"}}
        }
        result = m.lambda_handler(event("GET /me"), None)
        body = json.loads(result["body"])
        self.assertEqual(body["points"], 5)
        self.assertEqual(body["exchange"], {"minPoints": 10000, "tokensPerPoint": 1})


if __name__ == "__main__":
    unittest.main()
