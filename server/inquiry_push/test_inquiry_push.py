"""返信の通知(fcm_client.py と inquiry_push_lambda.py)の動作確認

  python3 -m unittest server/inquiry_push/test_inquiry_push.py
"""
import base64
import json
import os
import shutil
import subprocess
import sys
import tempfile
import types
import unittest
from unittest import mock

sys.path.insert(0, os.path.dirname(__file__))

import fcm_client  # noqa: E402

# boto3 を、偽物に差し替えて読み込む
fake_dynamo = mock.MagicMock()
fake_ssm = mock.MagicMock()
sys.modules["boto3"] = types.SimpleNamespace(
    client=lambda name, *a, **k: fake_dynamo if name == "dynamodb" else fake_ssm
)
import inquiry_push_lambda as lam  # noqa: E402

HAS_OPENSSL = shutil.which("openssl") is not None


def make_key(workdir, pkcs1=False):
    """openssl で作った、テスト用のRSA鍵: (秘密鍵のPEM, 公開鍵のファイル)"""
    private = os.path.join(workdir, "private.pem")
    public = os.path.join(workdir, "public.pem")
    subprocess.run(
        ["openssl", "genpkey", "-algorithm", "RSA", "-pkeyopt",
         "rsa_keygen_bits:2048", "-out", private],
        check=True, capture_output=True,
    )
    subprocess.run(
        ["openssl", "pkey", "-in", private, "-pubout", "-out", public],
        check=True, capture_output=True,
    )

    if pkcs1:
        converted = os.path.join(workdir, "private_pkcs1.pem")
        subprocess.run(
            ["openssl", "rsa", "-in", private, "-traditional", "-out", converted],
            check=True, capture_output=True,
        )
        private = converted

    with open(private) as f:
        return f.read(), public


def openssl_verify(public, message, signature, workdir):
    msg_file = os.path.join(workdir, "msg")
    sig_file = os.path.join(workdir, "sig")
    with open(msg_file, "wb") as f:
        f.write(message)
    with open(sig_file, "wb") as f:
        f.write(signature)

    result = subprocess.run(
        ["openssl", "dgst", "-sha256", "-verify", public,
         "-signature", sig_file, msg_file],
        capture_output=True,
    )
    return result.returncode == 0


@unittest.skipUnless(HAS_OPENSSL, "openssl が必要")
class SignatureTest(unittest.TestCase):
    def test_signature_is_accepted_by_openssl(self):
        for pkcs1 in (False, True):
            with tempfile.TemporaryDirectory() as workdir:
                pem, public = make_key(workdir, pkcs1=pkcs1)
                n, d = fcm_client.parse_private_key(pem)
                message = b"header.claims"

                signature = fcm_client.rs256_sign(message, n, d)

                self.assertEqual(len(signature), 256)
                self.assertTrue(
                    openssl_verify(public, message, signature, workdir),
                    msg=f"pkcs1={pkcs1}",
                )
                self.assertFalse(
                    openssl_verify(public, b"other", signature, workdir)
                )

    def test_jwt_has_three_parts_and_valid_signature(self):
        with tempfile.TemporaryDirectory() as workdir:
            pem, public = make_key(workdir)
            account = {"client_email": "svc@example.iam", "private_key": pem}

            jwt = fcm_client.make_jwt(account, now=1000)
            head, claims, signature = jwt.split(".")

            def decode(part):
                return base64.urlsafe_b64decode(part + "=" * (-len(part) % 4))

            self.assertEqual(json.loads(decode(head))["alg"], "RS256")
            body = json.loads(decode(claims))
            self.assertEqual(body["iss"], "svc@example.iam")
            self.assertEqual(body["scope"], fcm_client.FCM_SCOPE)
            self.assertEqual(body["exp"], 4600)
            self.assertTrue(openssl_verify(
                public, f"{head}.{claims}".encode(), decode(signature), workdir
            ))

    def test_broken_key_is_rejected(self):
        with self.assertRaises(Exception):
            fcm_client.parse_private_key("not a key")


class AccessTokenTest(unittest.TestCase):
    def setUp(self):
        fcm_client._cached.update(token=None, expires=0)
        patcher = mock.patch.object(fcm_client, "make_jwt", return_value="jwt")
        patcher.start()
        self.addCleanup(patcher.stop)

    def test_token_is_cached_until_near_expiry(self):
        post = mock.Mock(return_value=(200, {"access_token": "t1", "expires_in": 3600}))

        self.assertEqual(fcm_client.get_access_token({}, post, now=0), "t1")
        self.assertEqual(fcm_client.get_access_token({}, post, now=3000), "t1")
        self.assertEqual(post.call_count, 1)

        post.return_value = (200, {"access_token": "t2", "expires_in": 3600})
        self.assertEqual(fcm_client.get_access_token({}, post, now=3600), "t2")
        self.assertEqual(post.call_count, 2)

    def test_failure_raises(self):
        post = mock.Mock(return_value=(401, {"error": "invalid_grant"}))
        with self.assertRaises(fcm_client.FcmError):
            fcm_client.get_access_token({}, post, now=0)


class SendPushTest(unittest.TestCase):
    def send(self, status, body):
        post = mock.Mock(return_value=(status, body))
        result = fcm_client.send_push(
            "proj", "access", "devtoken", "題名", "本文", {"type": "x"}, post
        )
        return result, post

    def test_success_sends_expected_message(self):
        result, post = self.send(200, {"name": "m"})

        self.assertEqual(result, "ok")
        url, data, headers = post.call_args[0]
        self.assertEqual(
            url, "https://fcm.googleapis.com/v1/projects/proj/messages:send"
        )
        self.assertEqual(headers["Authorization"], "Bearer access")
        message = json.loads(data)["message"]
        self.assertEqual(message["token"], "devtoken")
        self.assertEqual(message["notification"], {"title": "題名", "body": "本文"})
        self.assertEqual(message["data"], {"type": "x"})
        self.assertEqual(message["android"]["priority"], "high")

    def test_unregistered_token(self):
        self.assertEqual(self.send(404, {"error": {"status": "NOT_FOUND"}})[0],
                         "unregistered")
        body = {"error": {"status": "NOT_FOUND", "details": [
            {"errorCode": "UNREGISTERED"}]}}
        self.assertEqual(self.send(404, body)[0], "unregistered")

    def test_other_failure_raises(self):
        with self.assertRaises(fcm_client.FcmError):
            self.send(500, {"error": {"status": "INTERNAL"}})


def record(event="INSERT", sender="developer", client="a" * 32):
    return {
        "eventName": event,
        "dynamodb": {"NewImage": {
            "clientId": {"S": client}, "from": {"S": sender},
            "message": {"S": "返信の本文(通知には載せない)"},
        }},
    }


class LambdaTest(unittest.TestCase):
    def setUp(self):
        fake_dynamo.reset_mock()
        fake_ssm.reset_mock()
        lam._service_account = None
        fake_ssm.get_parameter.return_value = {"Parameter": {"Value": json.dumps(
            {"project_id": "proj", "client_email": "e", "private_key": "k"}
        )}}
        fake_dynamo.get_item.return_value = {"Item": {"token": {"S": "devtoken"}}}

        for target, value in [
            ("get_access_token", "access"), ("send_push", "ok"),
        ]:
            patcher = mock.patch.object(fcm_client, target, return_value=value)
            setattr(self, target, patcher.start())
            self.addCleanup(patcher.stop)

    def test_only_developer_inserts_are_sent(self):
        out = lam.lambda_handler({"Records": [
            record(sender="user"), record(event="MODIFY"), record(event="REMOVE"),
            record(),
        ]}, None)

        self.assertEqual(out["results"], ["ok"])
        self.send_push.assert_called_once()

    def test_message_text_is_not_in_notification(self):
        lam.lambda_handler({"Records": [record()]}, None)

        args = self.send_push.call_args[0]
        self.assertEqual(args[0], "proj")
        self.assertEqual(args[3], lam.TITLE)
        self.assertEqual(args[4], lam.BODY)
        self.assertNotIn("返信の本文", json.dumps(args, ensure_ascii=False))
        self.assertEqual(args[5], {"type": "inquiry_reply"})

    def test_no_token_means_nothing_is_sent(self):
        fake_dynamo.get_item.return_value = {}

        out = lam.lambda_handler({"Records": [record()]}, None)

        self.assertEqual(out["results"], ["no_token"])
        self.send_push.assert_not_called()

    def test_unregistered_token_is_deleted(self):
        self.send_push.return_value = "unregistered"

        out = lam.lambda_handler({"Records": [record()]}, None)

        self.assertEqual(out["results"], ["unregistered"])
        fake_dynamo.delete_item.assert_called_once()

    def test_failure_does_not_raise_and_continues(self):
        self.send_push.side_effect = [fcm_client.FcmError("x"), "ok"]

        out = lam.lambda_handler({"Records": [record(), record()]}, None)

        self.assertEqual(out["results"], ["error", "ok"])


if __name__ == "__main__":
    unittest.main()
