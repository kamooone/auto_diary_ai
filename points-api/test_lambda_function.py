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
os.environ["PAIRING_TABLE_NAME"] = "pairing"
os.environ["DEVICES_TABLE_NAME"] = "devices"
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


def event(route, body=None, path=None, logged_in=True, headers=None):
    result = {
        "routeKey": route,
        "body": json.dumps(body) if body is not None else None,
        "pathParameters": path,
        "headers": headers or {},
        "requestContext": {},
    }
    if logged_in:
        result["requestContext"] = {
            "authorizer": {"jwt": {"claims": {"sub": "user-1"}}}
        }
    return result


def call(route, body=None, path=None, logged_in=True, headers=None):
    result = m.lambda_handler(event(route, body, path, logged_in, headers), None)
    return result["statusCode"], json.loads(result["body"])


def conditional_failure(operation):
    return ClientError(
        {"Error": {"Code": "ConditionalCheckFailedException"}}, operation
    )


def pairing_item(
    status="pending", secret="s3cret", expires_in=300, account="user-1",
    app_id=None,
):
    item = {
        "code": {"S": "123456"},
        "status": {"S": status},
        "claimSecretHash": {"S": m.sha256_hex(secret)},
        "label": {"S": "Android"},
        "expiresAt": {"N": str(int(m.time.time()) + expires_in)},
    }
    if app_id:
        item["appId"] = {"S": app_id}
    if status == "linked":
        item["accountId"] = {"S": account}
    return {"Item": item}


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


class PairingTest(unittest.TestCase):
    def setUp(self):
        fake_client.reset_mock(side_effect=True)

    def test_開始すると6桁のコードと合言葉を返し_合言葉はハッシュで保存する(self):
        status, body = call("POST /pairing/start", {"label": "Android"}, logged_in=False)
        self.assertEqual(status, 200)
        self.assertRegex(body["code"], r"^\d{6}$")

        item = fake_client.put_item.call_args.kwargs["Item"]
        self.assertEqual(item["claimSecretHash"]["S"], m.sha256_hex(body["claimSecret"]))
        self.assertNotIn(body["claimSecret"], json.dumps(item))

    def test_コードが重なったら作り直す(self):
        fake_client.put_item.side_effect = [conditional_failure("PutItem"), None]
        status, _ = call("POST /pairing/start", {}, logged_in=False)
        self.assertEqual(status, 200)
        self.assertEqual(fake_client.put_item.call_count, 2)

    def test_端末の名前は長さと文字を制限する(self):
        self.assertEqual(m.clean_label("A" * 100), "A" * m.MAX_LABEL_LENGTH)
        self.assertEqual(m.clean_label("a\nb"), "ab")
        self.assertEqual(m.clean_label(123), "アプリ")

    def test_不正な形のコードは調べずに無効(self):
        for bad in ("12345", "abcdef", "1234567", None, 123456):
            status, _ = call("POST /pairing/lookup", {"code": bad})
            self.assertEqual(status, 404, bad)
        fake_client.get_item.assert_not_called()

    def test_期限切れのコードは無効(self):
        fake_client.get_item.return_value = pairing_item(expires_in=-1)
        status, _ = call("POST /pairing/lookup", {"code": "123456"})
        self.assertEqual(status, 404)

    def test_確認すると端末の名前を返す(self):
        fake_client.get_item.return_value = pairing_item()
        status, body = call("POST /pairing/lookup", {"code": "123456"})
        self.assertEqual(status, 200)
        self.assertEqual(body["label"], "Android")
        # アプリIDがない行は、auto_diaryとして扱う
        self.assertEqual(body["appId"], "auto_diary")

    def test_確定するとアカウントに結ばれる(self):
        fake_client.get_item.return_value = pairing_item()
        fake_client.query.return_value = {"Items": []}
        status, _ = call("POST /pairing/confirm", {"code": "123456"})
        self.assertEqual(status, 200)

        update = fake_client.update_item.call_args.kwargs
        self.assertEqual(update["ExpressionAttributeValues"][":a"], {"S": "user-1"})
        # 使っていない値や名前を渡すと、DynamoDBがエラーにする
        for name in update["ExpressionAttributeValues"]:
            self.assertIn(name, update["UpdateExpression"] + update["ConditionExpression"])

    def test_端末が上限に達していると確定できない(self):
        fake_client.get_item.return_value = pairing_item()
        # アプリIDがない(これまでのauto_diary)端末も、auto_diaryとして数える
        fake_client.query.return_value = {
            "Items": [{"appId": {"S": "auto_diary"}}] * (m.MAX_DEVICES - 1)
            + [{}]
        }
        status, body = call("POST /pairing/confirm", {"code": "123456"})
        self.assertEqual((status, body["error"]), (409, "device_limit"))
        fake_client.update_item.assert_not_called()

    def test_先に確定されたコードは二重に確定できない(self):
        fake_client.get_item.return_value = pairing_item()
        fake_client.query.return_value = {"Items": []}
        fake_client.update_item.side_effect = conditional_failure("UpdateItem")
        status, _ = call("POST /pairing/confirm", {"code": "123456"})
        self.assertEqual(status, 404)

    def test_未確定のうちは待つ(self):
        fake_client.get_item.return_value = pairing_item("pending")
        status, body = call(
            "POST /pairing/claim",
            {"code": "123456", "claimSecret": "s3cret"},
            logged_in=False,
        )
        self.assertEqual((status, body["status"]), (202, "pending"))
        fake_client.put_item.assert_not_called()

    def test_合言葉が違うとトークンを渡さない(self):
        fake_client.get_item.return_value = pairing_item("linked")
        status, _ = call(
            "POST /pairing/claim",
            {"code": "123456", "claimSecret": "wrong"},
            logged_in=False,
        )
        self.assertEqual(status, 404)
        fake_client.put_item.assert_not_called()

    def test_確定済みなら端末を登録してトークンを渡す(self):
        fake_client.get_item.return_value = pairing_item("linked")
        status, body = call(
            "POST /pairing/claim",
            {"code": "123456", "claimSecret": "s3cret"},
            logged_in=False,
        )
        self.assertEqual((status, body["status"]), (200, "linked"))

        device_id, secret = body["deviceToken"].split(".")
        fake_client.delete_item.assert_called_once()  # コードは使い切り
        device = fake_client.put_item.call_args.kwargs["Item"]
        self.assertEqual(device["deviceId"], {"S": device_id})
        self.assertEqual(device["accountId"], {"S": "user-1"})
        self.assertEqual(device["tokenHash"], {"S": m.sha256_hex(secret)})
        self.assertNotIn(secret, json.dumps(device))

    def test_トークンは1回しか渡さない(self):
        fake_client.get_item.return_value = pairing_item("linked")
        fake_client.delete_item.side_effect = conditional_failure("DeleteItem")
        status, _ = call(
            "POST /pairing/claim",
            {"code": "123456", "claimSecret": "s3cret"},
            logged_in=False,
        )
        self.assertEqual(status, 404)
        fake_client.put_item.assert_not_called()

    def test_ログインが必要なルートは_ログインなしでは動かない(self):
        for route in ("GET /me", "POST /pairing/confirm", "GET /devices"):
            status, _ = call(route, {}, logged_in=False)
            self.assertEqual(status, 500, route)
        fake_client.update_item.assert_not_called()


class DevicesTest(unittest.TestCase):
    def setUp(self):
        fake_client.reset_mock(side_effect=True)

    def test_自分の端末だけを新しい順でなく古い順に一覧する(self):
        fake_client.query.return_value = {
            "Items": [
                {"deviceId": {"S": "b"}, "label": {"S": "iPhone"}, "createdAt": {"N": "20"}},
                {"deviceId": {"S": "a"}, "label": {"S": "Android"}, "createdAt": {"N": "10"}},
            ]
        }
        status, body = call("GET /devices")
        self.assertEqual(status, 200)
        self.assertEqual([d["deviceId"] for d in body["devices"]], ["a", "b"])
        self.assertEqual(body["maxDevices"], m.MAX_DEVICES)
        self.assertNotIn("tokenHash", json.dumps(body))

    def test_解除は自分の端末だけ(self):
        device_id = "a" * 32
        status, _ = call("DELETE /devices/{deviceId}", path={"deviceId": device_id})
        self.assertEqual(status, 200)
        kwargs = fake_client.delete_item.call_args.kwargs
        self.assertEqual(kwargs["ConditionExpression"], "accountId = :a")

        fake_client.delete_item.side_effect = conditional_failure("DeleteItem")
        status, _ = call("DELETE /devices/{deviceId}", path={"deviceId": device_id})
        self.assertEqual(status, 404)

    def test_形の違うIDは受け付けない(self):
        status, _ = call("DELETE /devices/{deviceId}", path={"deviceId": "../x"})
        self.assertEqual(status, 404)
        fake_client.delete_item.assert_not_called()


GAME_KEY = "game-key-kamoooneshot"
OTHER_KEY = "game-key-escape-2"

m.APP_KEY_HASHES = {
    "kamoooneshot": m.sha256_hex(GAME_KEY),
    "escape_2": m.sha256_hex(OTHER_KEY),
}

DEVICE_SECRET = "device-secret"


def device_row(app_id="kamoooneshot", account="user-1"):
    item = {
        "deviceId": {"S": "dev1"},
        "accountId": {"S": account},
        "tokenHash": {"S": m.sha256_hex(DEVICE_SECRET)},
    }
    if app_id:
        item["appId"] = {"S": app_id}
    return {"Item": item}


class AppPairingTest(unittest.TestCase):
    def setUp(self):
        fake_client.reset_mock(side_effect=True)

    def start(self, body, key=None):
        headers = {"X-App-Key": key} if key else None
        return call("POST /pairing/start", body, logged_in=False, headers=headers)

    def test_appIdがなければauto_diaryで_キーは要らない(self):
        status, _ = self.start({"label": "Android"})
        self.assertEqual(status, 200)
        self.assertEqual(
            fake_client.put_item.call_args.kwargs["Item"]["appId"], {"S": "auto_diary"}
        )

    def test_ゲームはキーが合えば紐づけを始められる(self):
        status, _ = self.start({"appId": "kamoooneshot"}, key=GAME_KEY)
        self.assertEqual(status, 200)
        self.assertEqual(
            fake_client.put_item.call_args.kwargs["Item"]["appId"],
            {"S": "kamoooneshot"},
        )

    def test_キーがない_または別のゲームのキーでは始められない(self):
        for key in (None, "wrong", OTHER_KEY):
            status, body = self.start({"appId": "kamoooneshot"}, key=key)
            self.assertEqual((status, body["error"]), (403, "invalid_app"), key)
        fake_client.put_item.assert_not_called()

    def test_登録されていないアプリは始められない(self):
        status, body = self.start({"appId": "unknown_app"}, key=GAME_KEY)
        self.assertEqual((status, body["error"]), (400, "invalid_app"))

    def test_確認画面にアプリ名が出る(self):
        fake_client.get_item.return_value = pairing_item(app_id="escape_2")
        status, body = call("POST /pairing/lookup", {"code": "123456"})
        self.assertEqual((status, body["appName"]), (200, "脱出ゲーム２"))

    def test_上限はアプリごとに数える(self):
        # auto_diaryが3台でも、ゲームの紐づけは別に数える
        fake_client.get_item.return_value = pairing_item(app_id="kamoooneshot")
        fake_client.query.return_value = {
            "Items": [{"appId": {"S": "auto_diary"}}] * m.MAX_DEVICES
        }
        status, _ = call("POST /pairing/confirm", {"code": "123456"})
        self.assertEqual(status, 200)

        fake_client.query.return_value = {
            "Items": [{"appId": {"S": "kamoooneshot"}}] * m.MAX_DEVICES
        }
        status, body = call("POST /pairing/confirm", {"code": "123456"})
        self.assertEqual((status, body["error"]), (409, "device_limit"))

    def test_端末にアプリIDを保存する(self):
        fake_client.get_item.return_value = pairing_item("linked", app_id="escape_2")
        status, _ = call(
            "POST /pairing/claim",
            {"code": "123456", "claimSecret": "s3cret"},
            logged_in=False,
        )
        self.assertEqual(status, 200)
        device = fake_client.put_item.call_args.kwargs["Item"]
        self.assertEqual(device["appId"], {"S": "escape_2"})

    def test_一覧にアプリ名が出る(self):
        fake_client.query.return_value = {
            "Items": [
                {"deviceId": {"S": "a"}, "label": {"S": "iPad"},
                 "appId": {"S": "kamoooneshot"}, "createdAt": {"N": "1"}},
                {"deviceId": {"S": "b"}, "label": {"S": "iPhone"},
                 "createdAt": {"N": "2"}},
            ]
        }
        _, body = call("GET /devices")
        self.assertEqual(
            [(d["appId"], d["appName"]) for d in body["devices"]],
            [("kamoooneshot", "KamoooneShot"), ("auto_diary", "auto_diary")],
        )


class UnlinkSelfTest(unittest.TestCase):
    def setUp(self):
        fake_client.reset_mock(side_effect=True)
        fake_client.get_item.return_value = device_row()

    def send(self, token):
        headers = {"X-Device-Token": token} if token else {}
        return call("POST /device/unlink", {}, logged_in=False, headers=headers)

    def test_端末自身が解除すると端末の行が消える(self):
        status, body = self.send(f"dev1.{DEVICE_SECRET}")

        self.assertEqual(status, 200)
        self.assertTrue(body["unlinked"])
        kwargs = fake_client.delete_item.call_args.kwargs
        self.assertEqual(kwargs["TableName"], m.DEVICES_TABLE_NAME)
        self.assertEqual(kwargs["Key"], {"deviceId": {"S": "dev1"}})

    def test_トークンが違うと解除できない(self):
        for token in ["dev1.wrong", "garbage", None]:
            status, body = self.send(token)
            self.assertEqual(status, 401)
            self.assertEqual(body["error"], "invalid_device_token")

        fake_client.delete_item.assert_not_called()


class EventsTest(unittest.TestCase):
    def setUp(self):
        fake_client.reset_mock(side_effect=True)
        fake_client.get_item.side_effect = self.get_item
        self.device = device_row()

    def get_item(self, **kwargs):
        if kwargs["TableName"] == m.DEVICES_TABLE_NAME:
            return self.device
        return balance_item(150, 0)

    def send(self, body, key=GAME_KEY, token=f"dev1.{DEVICE_SECRET}"):
        headers = {}
        if key:
            headers["X-App-Key"] = key
        if token:
            headers["X-Device-Token"] = token
        return call("POST /events", body, logged_in=False, headers=headers)

    def valid(self, **extra):
        return {"eventId": "event-0001", "type": "stage_clear", **extra}

    def transaction(self):
        items = fake_client.transact_write_items.call_args.kwargs["TransactItems"]
        return items

    def test_成果を送るとサーバーが決めたポイントが付く(self):
        # ゲームがポイントの量を送ってきても、無視する
        status, body = self.send(self.valid(points=999999))

        self.assertEqual(status, 200)
        self.assertEqual(body["granted"], 50)

        items = self.transaction()
        balance = next(i["Update"] for i in items if i.get("Update", {}).get("TableName") == m.TABLE_NAME)
        self.assertEqual(balance["ExpressionAttributeValues"][":p"], {"N": "50"})

    def test_履歴に_アプリと成果の種類が残る(self):
        self.send(self.valid())

        ledger = [
            i["Put"] for i in self.transaction()
            if "Put" in i and i["Put"]["TableName"] == m.LEDGER_TABLE_NAME
        ][0]["Item"]
        self.assertEqual(ledger["type"], {"S": "game_grant"})
        self.assertEqual(ledger["appId"], {"S": "kamoooneshot"})
        self.assertEqual(ledger["eventType"], {"S": "stage_clear"})
        self.assertEqual(ledger["pointsDelta"], {"N": "50"})

    def test_式に使わない値は渡さない(self):
        # DynamoDBは、式で使っていない値が渡されるとエラーにする
        self.send({"eventId": "event-0002", "type": "daily_first_play"})

        for item in self.transaction():
            update = item.get("Update")
            if not update:
                continue
            expressions = update["UpdateExpression"] + " " + update.get(
                "ConditionExpression", ""
            )
            for name in update["ExpressionAttributeValues"]:
                self.assertIn(name, expressions)

    def test_キーが合わなければ付かない(self):
        for key in (None, "wrong"):
            status, body = self.send(self.valid(), key=key)
            self.assertEqual((status, body["error"]), (401, "invalid_app"), key)
        fake_client.transact_write_items.assert_not_called()

    def test_端末用のトークンが正しくなければ付かない(self):
        for token in (None, "garbage", "dev1.wrong"):
            status, body = self.send(self.valid(), token=token)
            self.assertEqual(
                (status, body["error"]), (401, "invalid_device_token"), token
            )
        self.device = {}
        status, _ = self.send(self.valid())
        self.assertEqual(status, 401)
        fake_client.transact_write_items.assert_not_called()

    def test_別のアプリの端末用トークンでは付かない(self):
        self.device = device_row(app_id="escape_2")
        status, body = self.send(self.valid())
        self.assertEqual((status, body["error"]), (403, "app_mismatch"))
        fake_client.transact_write_items.assert_not_called()

    def test_登録されていない成果と不正なeventIdは受け付けない(self):
        status, body = self.send({"eventId": "event-0001", "type": "free_points"})
        self.assertEqual((status, body["error"]), (400, "unknown_event"))

        for bad in (None, "short", "a b c d e f g h", 123):
            status, body = self.send({"eventId": bad, "type": "stage_clear"})
            self.assertEqual((status, body["error"]), (400, "invalid_event_id"), bad)
        fake_client.transact_write_items.assert_not_called()

    def cancelled(self, *failed):
        items = self.transaction_names()
        reasons = [
            {"Code": "ConditionalCheckFailed" if name in failed else "None"}
            for name in items
        ]
        return ClientError(
            {"Error": {"Code": "TransactionCanceledException"},
             "CancellationReasons": reasons},
            "TransactWriteItems",
        )

    def transaction_names(self):
        # 項目の並び: event, (per_day), (total), ceiling, balance, ledger
        names = ["event"]
        if "maxPerDay" in m.EVENT_RULES[self.event_type]:
            names.append("per_day")
        names += ["ceiling", "balance", "ledger"]
        return names

    def test_同じeventIdは二重に付けない(self):
        self.event_type = "daily_first_play"
        fake_client.transact_write_items.side_effect = self.cancelled("event")

        status, body = self.send({"eventId": "event-0001", "type": "daily_first_play"})

        self.assertEqual(status, 200)
        self.assertEqual((body["granted"], body["reason"]), (0, "duplicate"))

    def test_1日の回数の上限に達したら付かない(self):
        self.event_type = "daily_first_play"
        fake_client.transact_write_items.side_effect = self.cancelled("per_day")

        status, body = self.send({"eventId": "event-0002", "type": "daily_first_play"})

        self.assertEqual(status, 200)
        self.assertEqual((body["granted"], body["reason"]), (0, "event_limit"))

    def test_1日の合計の上限に達したら付かない(self):
        self.event_type = "stage_clear"
        fake_client.transact_write_items.side_effect = self.cancelled("ceiling")

        status, body = self.send(self.valid())

        self.assertEqual(status, 200)
        self.assertEqual((body["granted"], body["reason"]), (0, "daily_ceiling"))

    def test_上限の条件は_アカウントごとの1日の合計で判断する(self):
        self.send(self.valid())

        ceiling = [
            i["Update"] for i in self.transaction()
            if "Update" in i and i["Update"]["Key"].get("counterKey", {}).get("S", "").startswith("sum#user-1#")
        ][0]
        values = ceiling["ExpressionAttributeValues"]
        self.assertEqual(values[":room"], {"N": str(m.DAILY_POINTS_CEILING - 50)})
        self.assertIn("pts <= :room", ceiling["ConditionExpression"])

    def test_回数の記録はアカウントとアプリと成果ごとに分かれる(self):
        self.send({"eventId": "event-0003", "type": "daily_first_play"})

        keys = [
            i["Update"]["Key"]["counterKey"]["S"]
            for i in self.transaction()
            if "Update" in i and "counterKey" in i["Update"]["Key"]
        ]
        self.assertTrue(any(
            k.startswith("day#user-1#") and k.endswith("#kamoooneshot#daily_first_play")
            for k in keys
        ))

    def test_想定外のエラーは500(self):
        fake_client.transact_write_items.side_effect = ClientError(
            {"Error": {"Code": "ProvisionedThroughputExceededException"}},
            "TransactWriteItems",
        )
        status, body = self.send(self.valid())
        self.assertEqual((status, body["error"]), (500, "internal_error"))


if __name__ == "__main__":
    unittest.main()
