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

LAMBDA_PATH = os.path.join(os.path.dirname(__file__), "ai_chat_lambda.py")
LIMIT_PLACEHOLDER = "/* ここは直接入力する */"


def load_lambda():
    """月の上限は、ファイルでは「直接入力する」の印のため、テスト用の数字に置き換えて読み込む"""
    with open(LAMBDA_PATH, encoding="utf-8") as f:
        source = f.read()

    assert source.count(LIMIT_PLACEHOLDER) == 2
    source = source.replace(LIMIT_PLACEHOLDER, "3_000", 1)
    source = source.replace(LIMIT_PLACEHOLDER, "500_000", 1)

    module = types.ModuleType("ai_chat_lambda")
    module.__file__ = LAMBDA_PATH
    sys.modules["ai_chat_lambda"] = module
    exec(compile(source, LAMBDA_PATH, "exec"), module.__dict__)
    return module


m = load_lambda()

CLIENT_ID = "a" * 32
FREE_LIMIT = m.MONTHLY_LIMIT_TOKENS[m.FREE]


def sha(value):
    return hashlib.sha256(value.encode()).hexdigest()


def chat_event(plan="free", device_token=None, client_id=CLIENT_ID, model=None):
    headers = {}
    if client_id:
        headers["X-Client-Id"] = client_id
    if device_token:
        headers["X-Device-Token"] = device_token
    body = {"message": "こんにちは", "plan": plan}
    if model is not None:
        body["model"] = model
    return {
        "routeKey": "POST /ai/chat",
        "headers": headers,
        "body": json.dumps(body),
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

        patcher = mock.patch.object(m, "get_gemini_api_key", return_value="key")
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

    @mock.patch.object(m, "GPT_ENABLED", True)
    def test_gpt_model_uses_gpt_with_the_free_limit(self):
        status, body = call(chat_event(model="gpt"))

        self.assertEqual(status, 200)
        self.openai.assert_called_once()
        self.gemini.assert_not_called()
        self.assertEqual(body["usage"]["limitTokens"], FREE_LIMIT)

    @mock.patch.object(m, "GPT_ENABLED", True)
    def test_gemini_or_unknown_model_uses_gemini(self):
        for model in (None, "gemini", "unknown"):
            self.gemini.reset_mock()
            status, _ = call(chat_event(model=model))

            self.assertEqual(status, 200)
            self.gemini.assert_called_once()
            self.openai.assert_not_called()

    def test_gpt_model_is_refused_while_disabled(self):
        status, body = call(chat_event(model="gpt"))

        self.assertEqual(status, 400)
        self.assertEqual(body["error"], "gpt_not_enabled")
        self.openai.assert_not_called()
        self.gemini.assert_not_called()
        self.assertEqual(self.used(), 0)

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


class AskGeminiTimeoutTest(unittest.TestCase):
    """Geminiの待ち時間(写真が多いと時間がかかるため、10秒では足りなかった)"""

    OK = {
        "candidates": [{"content": {"parts": [{"text": "回答"}]}}],
        "usageMetadata": {"totalTokenCount": 10},
    }

    def run_gemini(self, outcomes):
        """outcomes: 呼ばれるたびの結果(例外か応答)と、その間に進む秒数のリスト"""
        clock = [0.0]
        timeouts = []
        queue = list(outcomes)

        def fake_post(provider, url, headers, body, timeout=None):
            timeouts.append(timeout)
            result, seconds = queue.pop(0)
            clock[0] += seconds
            if isinstance(result, Exception):
                raise result
            return result

        with mock.patch.object(m, "post_json", fake_post), \
                mock.patch.object(m.time, "monotonic", lambda: clock[0]):
            try:
                answer = m.ask_gemini("key", "message", [])
            except m.UpstreamError as e:
                answer = e

        return answer, timeouts

    def test_thinking_is_limited_and_retried_without_on_400(self):
        bodies = []

        def fake_post(provider, url, headers, body, timeout=None):
            bodies.append(body)
            if len(bodies) == 1:
                raise m.UpstreamError("Gemini", 400, "bad thinking")
            return self.OK

        with mock.patch.object(m, "post_json", fake_post):
            answer = m.ask_gemini("key", "message", [])

        self.assertEqual(answer, ("回答", 10))
        self.assertEqual(
            bodies[0]["generationConfig"]["thinkingConfig"],
            m.GEMINI_THINKING_CONFIG,
        )
        self.assertNotIn("generationConfig", bodies[1])

    def test_first_model_may_take_longer_than_ten_seconds(self):
        answer, timeouts = self.run_gemini([(self.OK, 15)])

        self.assertEqual(answer, ("回答", 10))
        self.assertEqual(timeouts, [m.GEMINI_ATTEMPT_TIMEOUT])
        self.assertGreater(m.GEMINI_ATTEMPT_TIMEOUT, 10)

    def test_next_model_gets_the_remaining_time_after_a_timeout(self):
        left = m.GEMINI_TOTAL_BUDGET - m.GEMINI_ATTEMPT_TIMEOUT
        self.assertGreaterEqual(left, m.MIN_REMAINING_SECONDS)

        answer, timeouts = self.run_gemini([
            (TimeoutError("timed out"), m.GEMINI_ATTEMPT_TIMEOUT),
            (self.OK, 5),
        ])

        self.assertEqual(answer, ("回答", 10))
        self.assertEqual(timeouts, [m.GEMINI_ATTEMPT_TIMEOUT, left])

    def test_no_third_model_when_the_time_is_used_up(self):
        left = m.GEMINI_TOTAL_BUDGET - m.GEMINI_ATTEMPT_TIMEOUT
        answer, timeouts = self.run_gemini([
            (TimeoutError("timed out"), m.GEMINI_ATTEMPT_TIMEOUT),
            (TimeoutError("timed out"), left),
        ])

        self.assertIsInstance(answer, m.UpstreamError)
        self.assertEqual(len(timeouts), 2)

    def test_second_model_is_tried_after_a_quick_failure(self):
        quick = m.UpstreamError("Gemini", 503, "busy")
        answer, timeouts = self.run_gemini([(quick, 1), (self.OK, 5)])

        self.assertEqual(answer, ("回答", 10))
        self.assertEqual(len(timeouts), 2)
        # 残りの時間を超えて待たない
        self.assertLessEqual(timeouts[1], m.GEMINI_TOTAL_BUDGET - 1)


class AskOpenAiTest(unittest.TestCase):
    """GPTの、回答の取り出しと、考える量の指定"""

    PLAIN = {
        "output": [
            {
                "type": "message",
                "content": [{"type": "output_text", "text": "回答です"}],
            }
        ],
        "usage": {"input_tokens": 100, "output_tokens": 20, "total_tokens": 120},
    }

    # 考えるモデルは、先頭に思考の項目(reasoning)が入る
    WITH_REASONING = {
        "output": [
            {"type": "reasoning", "summary": []},
            {
                "type": "message",
                "content": [
                    {"type": "output_text", "text": "回答"},
                    {"type": "output_text", "text": "です"},
                ],
            },
        ],
        "usage": {
            "input_tokens": 100,
            "output_tokens": 220,
            "total_tokens": 320,
            "output_tokens_details": {"reasoning_tokens": 200},
        },
    }

    def ask(self, data, effort=""):
        with mock.patch.object(m, "post_json", return_value=data) as post, \
                mock.patch.object(m, "OPENAI_REASONING_EFFORT", effort):
            result = m.ask_openai("key", "こんにちは", [])

        return result, post.call_args.args[3]

    def test_plain_response(self):
        (answer, tokens), _ = self.ask(self.PLAIN)

        self.assertEqual(answer, "回答です")
        self.assertEqual(tokens, 120)

    def test_reasoning_item_before_the_message_is_skipped(self):
        (answer, tokens), _ = self.ask(self.WITH_REASONING)

        self.assertEqual(answer, "回答です")
        self.assertEqual(tokens, 320)

    def test_effort_is_not_sent_unless_set(self):
        _, payload = self.ask(self.PLAIN)

        self.assertNotIn("reasoning", payload)

    def test_effort_is_sent_when_set(self):
        _, payload = self.ask(self.PLAIN, effort="minimal")

        self.assertEqual(payload["reasoning"], {"effort": "minimal"})

    def test_response_without_answer_text_is_an_error(self):
        with self.assertRaises(m.UpstreamError):
            self.ask({"output": [{"type": "reasoning"}], "usage": {}})

    def test_model_comes_from_the_environment_with_a_default(self):
        self.assertEqual(m.OPENAI_MODEL, "gpt-5-mini")
        self.assertEqual(m.OPENAI_REASONING_EFFORT, "minimal")

    def test_wait_time_is_limited_by_the_budget(self):
        _, _ = self.ask(self.PLAIN)

        with mock.patch.object(m, "post_json", return_value=self.PLAIN) as post:
            m.ask_openai("key", "こんにちは", [])

        self.assertEqual(post.call_args.kwargs["timeout"], m.OPENAI_TOTAL_BUDGET)

    def test_wait_time_is_limited_by_the_lambda_remaining_time(self):
        context = mock.Mock()
        context.get_remaining_time_in_millis.return_value = 30_000

        with mock.patch.object(m, "post_json", return_value=self.PLAIN) as post:
            m.ask_openai("key", "こんにちは", [], context)

        self.assertEqual(
            post.call_args.kwargs["timeout"], 30 - m.RESERVED_SECONDS
        )

    def test_timeout_becomes_an_upstream_error_the_app_can_recognize(self):
        with mock.patch.object(
            m, "post_json", side_effect=TimeoutError("The read operation timed out")
        ):
            with self.assertRaises(m.UpstreamError) as raised:
                m.ask_openai("key", "こんにちは", [])

        self.assertEqual(raised.exception.provider, "OpenAI")
        self.assertIn("timed out", raised.exception.details)

    def test_budgets_fit_in_the_120_second_gateway(self):
        self.assertLess(m.GEMINI_TOTAL_BUDGET, 120)
        self.assertLess(m.OPENAI_TOTAL_BUDGET, 120)


class GeminiApiKeyTest(unittest.TestCase):
    def setUp(self):
        patcher = mock.patch.object(m, "ssm")
        self.ssm = patcher.start()
        self.addCleanup(patcher.stop)

        patcher = mock.patch.object(m, "secrets_manager")
        self.secrets = patcher.start()
        self.addCleanup(patcher.stop)

    def test_Parameter_Storeから暗号を解いて読む(self):
        self.ssm.get_parameter.return_value = {"Parameter": {"Value": " gem-key \n"}}

        self.assertEqual("gem-key", m.get_gemini_api_key())

        self.ssm.get_parameter.assert_called_once_with(
            Name=m.GEMINI_PARAMETER_NAME, WithDecryption=True
        )
        self.secrets.get_secret_value.assert_not_called()

    def test_JSONで保存されていても_キーを取り出せる(self):
        self.ssm.get_parameter.return_value = {
            "Parameter": {"Value": '{"GEMINI_API_KEY": "gem-key"}'}
        }

        self.assertEqual("gem-key", m.get_gemini_api_key())

    def test_パラメータがないときは_Secrets_Managerから読む(self):
        self.ssm.get_parameter.side_effect = ClientError(
            {"Error": {"Code": "ParameterNotFound"}}, "GetParameter"
        )
        self.secrets.get_secret_value.return_value = {"SecretString": "old-key"}

        self.assertEqual("old-key", m.get_gemini_api_key())

    def test_OpenAIのキーは_これまでどおりSecrets_Managerから読む(self):
        self.secrets.get_secret_value.return_value = {
            "SecretString": '{"OPENAI_API_KEY": "oa-key"}'
        }

        self.assertEqual(
            "oa-key", m.get_api_key(m.OPENAI_SECRET_NAME, "OPENAI_API_KEY")
        )
        self.ssm.get_parameter.assert_not_called()


class UnfilledLimitTest(unittest.TestCase):
    def test_上限を入力せずに貼ると_構文エラーになる(self):
        with open(LAMBDA_PATH, encoding="utf-8") as f:
            source = f.read()

        with self.assertRaises(SyntaxError):
            compile(source, LAMBDA_PATH, "exec")


if __name__ == "__main__":
    unittest.main()
