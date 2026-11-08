"""日記まわりのプロンプトの動作確認

  python3 -m unittest server/ai_chat/test_diary_prompts.py

testdata/prompt_cases.json は、サーバーに移す前のアプリ(Dart)のプロンプトの出力(正解)。
同じ入力から、同じ文章ができることを確かめる。
(作り直すときは、移す前のアプリが必要。プロンプトを意図して変えたときは、正解を直さず、
 test_diary_prompts.py の期待値を、変更に合わせて直すこと)
"""
import json
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(__file__))

import diary_prompts as prompts

CASES_PATH = os.path.join(os.path.dirname(__file__), "testdata", "prompt_cases.json")


class GoldenTest(unittest.TestCase):
    """移す前のアプリのプロンプトと、1文字も違わない"""

    @classmethod
    def setUpClass(cls):
        with open(CASES_PATH, encoding="utf-8") as f:
            cls.cases = json.load(f)

    def test_all_cases_match(self):
        self.assertGreater(len(self.cases), 200)

        for case in self.cases:
            with self.subTest(case["name"]):
                actual = prompts.build_prompt(case["spec"], case["photoCount"])
                self.assertEqual(actual, case["expected"])


class LengthRangeTest(unittest.TestCase):
    def test_clamps(self):
        self.assertEqual(prompts.length_range(0), (300, 500))
        self.assertEqual(prompts.length_range(30000), (3000, 4500))
        self.assertEqual(prompts.length_range(1000000), (6000, 8000))

    def test_guide(self):
        self.assertEqual(prompts.length_guide(30000), "3000〜4500文字")


class ValidationTest(unittest.TestCase):
    def test_unknown_kind(self):
        with self.assertRaises(prompts.PromptError):
            prompts.build_prompt({"kind": "other"})

    def test_not_an_object(self):
        with self.assertRaises(prompts.PromptError):
            prompts.build_prompt("text")

    def test_unknown_style(self):
        spec = {
            "kind": "summary", "style": "unknown", "diaryCount": 2,
            "diariesText": "x", "diariesChars": 10,
        }

        with self.assertRaises(prompts.PromptError):
            prompts.build_prompt(spec)

    def test_bad_date(self):
        spec = {
            "kind": "diary", "diaryDate": "2026/1/1",
            "startDate": "2026-01-01", "endDate": "2026-01-01",
        }

        with self.assertRaises(prompts.PromptError):
            prompts.build_prompt(spec)

    def test_negative_length(self):
        spec = {
            "kind": "diary", "diaryDate": "2026-01-01",
            "startDate": "2026-01-01", "endDate": "2026-01-01",
            "lengthChars": -1,
        }

        with self.assertRaises(prompts.PromptError):
            prompts.build_prompt(spec)

    def test_text_must_be_string(self):
        spec = {
            "kind": "diary", "diaryDate": "2026-01-01",
            "startDate": "2026-01-01", "endDate": "2026-01-01",
            "note": 5,
        }

        with self.assertRaises(prompts.PromptError):
            prompts.build_prompt(spec)


if __name__ == "__main__":
    unittest.main()
