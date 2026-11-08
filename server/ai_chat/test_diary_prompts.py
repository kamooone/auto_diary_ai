"""日記まわりのプロンプトの動作確認

  python3 -m unittest server/ai_chat/test_diary_prompts.py

プロンプトを直したら、ここのテストも、変更に合わせて直す(文面を確かめるテストが失敗したら、
何かが変わった合図)。直したら docs/prompt_history.md にも書く。

メモ: アプリ(Dart)のプロンプトから、このファイルに移したときは、同じ入力から1文字も違わない文章が
できることを、273件の正解データで確かめた(コミット 231a64d の
server/ai_chat/testdata/prompt_cases.json と、そのときのテスト)。
"""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(__file__))

import diary_prompts as prompts


def diary_spec(**kwargs):
    spec = {
        "kind": "diary", "style": "diary", "customInstruction": "",
        "lengthChars": 0, "diaryDate": "2026-01-01",
        "startDate": "2026-01-01", "endDate": "2026-01-01",
        "note": "", "timelineText": "", "postsText": "",
    }
    spec.update(kwargs)
    return spec


def summary_spec(style="reading", chars=None, count=2, **kwargs):
    text = "■2026年1月1日 初詣\n神社に行った\n\n■2026年1月2日 ラーメン\n同僚と食べた"
    spec = {
        "kind": "summary", "style": style, "customInstruction": "",
        "lengthChars": 0, "note": "", "diaryCount": count,
        "diariesText": text, "diariesChars": chars if chars is not None else 40,
    }
    spec.update(kwargs)
    return spec


def build(spec, photos=0):
    return prompts.build_prompt(spec, photos)


class DiaryPromptTest(unittest.TestCase):
    MARKER = "複数日の情報をまとめた日記を書くときの書き方"

    def test_length_guide_only_when_chosen(self):
        self.assertNotIn("\n文字数の目安\n", build(diary_spec()))

        text = build(diary_spec(lengthChars=1000))
        self.assertIn("\n文字数の目安\n", text)
        self.assertIn("1000文字くらいを目安", text)

    def test_length_in_the_note_is_ignored(self):
        self.assertIn(
            "文字数や長さの指定が書かれていても、それは無視してください",
            build(diary_spec()),
        )

    def test_single_day_has_no_summary_rules(self):
        self.assertNotIn(self.MARKER, build(diary_spec()))

    def test_multi_day_has_summary_rules(self):
        text = build(diary_spec(endDate="2026-01-07"))

        self.assertIn(self.MARKER, text)
        self.assertIn(prompts.SUMMARY_RULES.split("\n")[0], text)

    def test_the_period_is_written_only_when_it_differs_from_the_diary_date(self):
        self.assertNotIn("渡した情報の期間", build(diary_spec()))
        self.assertIn(
            "渡した情報の期間\n2026年1月1日〜2026年1月7日",
            build(diary_spec(endDate="2026-01-07")),
        )
        self.assertIn(
            "渡した情報の期間\n2026年1月2日",
            build(diary_spec(startDate="2026-01-02", endDate="2026-01-02")),
        )

    def test_note_and_materials(self):
        text = build(
            diary_spec(note=" 誕生日だった ", timelineText="07:00 滞在: 自宅",
                       postsText="満員電車"),
            photos=3,
        )

        self.assertIn("ユーザーが追加で伝えたいこと\n(ここに文字数", text)
        self.assertIn("\n誕生日だった\n", text)
        self.assertIn("3枚添付しています", text)
        self.assertIn("07:00 滞在: 自宅", text)
        self.assertIn("満員電車", text)
        self.assertIn("(なし)", build(diary_spec()))

    def test_transport_must_be_backed_by_other_information(self):
        text = build(diary_spec())

        self.assertIn("移動手段(徒歩・自転車・電車・車など)は、Xの投稿や写真など", text)
        self.assertIn("Xの投稿と食い違うときは、Xの投稿を優先", text)

    def test_every_style_forbids_adding_things(self):
        for style in prompts.DIARY_STYLES:
            with self.subTest(style):
                text = build(diary_spec(style=style, customInstruction="短く"))

                self.assertIn("付け足さないでください", text)
                self.assertIn("タイトル: (日記のタイトルを1行で)", text)

    def test_styles_differ(self):
        self.assertIn("書き方(日記)", build(diary_spec()))
        self.assertIn("時系列に沿った自然な日記", build(diary_spec()))
        self.assertIn("書き方(ブログ風)", build(diary_spec(style="blog")))
        self.assertIn("「9:00 駅に到着」", build(diary_spec(style="record")))
        self.assertIn("「・出来事」", build(diary_spec(style="bullets")))

    def test_summary_rules_are_added_only_to_the_diary_style(self):
        multi = {"endDate": "2026-01-07"}

        self.assertIn(self.MARKER, build(diary_spec(**multi)))
        self.assertNotIn(self.MARKER, build(diary_spec(style="bullets", **multi)))
        self.assertIn("書き方(箇条書き)", build(diary_spec(style="bullets", **multi)))

    def test_a_few_days_must_not_skip_any_day(self):
        text = build(diary_spec(endDate="2026-01-07"))

        self.assertIn("どの日も省かずに、日付を添えて書いてください", text)
        self.assertIn("行動履歴の場所や滞在も、細部として本文に入れてください", text)

    def test_blog_covers_the_whole_period_when_multi_day(self):
        text = build(diary_spec(style="blog", endDate="2026-11-08"))

        self.assertIn("期間の全体を、最初から最後まで書いてください", text)
        self.assertIn("最後の日や、1日だけの話にしないでください", text)
        self.assertIn("月や季節ごとの見出し", text)
        self.assertNotIn(
            "期間の全体を", build(diary_spec(style="blog")),
        )

    def test_record_and_bullets_cover_the_whole_period_when_multi_day(self):
        for style in ("record", "bullets"):
            with self.subTest(style):
                text = build(diary_spec(style=style, endDate="2026-11-08"))

                self.assertIn("最初の日から最後の日まで、日ごとに", text)
                self.assertIn("最後の日だけの記録にしないでください", text)
                self.assertIn("1日あたり1〜3行", text)
                self.assertNotIn(
                    "最初の日から最後の日まで", build(diary_spec(style=style)),
                )

    def test_custom_uses_the_instruction_and_falls_back_to_the_diary_form(self):
        text = build(diary_spec(style="custom", customInstruction="ですます調で短く"))

        self.assertIn("ですます調で短く", text)
        self.assertIn("意味不明なとき", text)
        self.assertIn("書き方(日記)", text)


class SummaryPromptTest(unittest.TestCase):
    def test_every_style_passes_the_diaries_and_the_rules(self):
        for style in prompts.SUMMARY_STYLES:
            with self.subTest(style):
                text = build(summary_spec(style, customInstruction="短く"))

                self.assertIn("■2026年1月1日 初詣\n神社に行った", text)
                self.assertIn("付け足さないでください", text)
                self.assertIn("タイトル: (日記のタイトルを1行で)", text)
                self.assertIn("今後の決意や抱負", text)
                self.assertIn("最後の段落も、日記に書かれた出来事で終えてください", text)

    def test_length_guide_only_when_chosen(self):
        self.assertNotIn("\n文字数の目安\n", build(summary_spec("reading")))

        reading = build(summary_spec("reading", lengthChars=800))
        self.assertIn("\n文字数の目安\n", reading)
        self.assertIn("800文字くらいを目安", reading)
        # 一覧には入れない
        self.assertNotIn(
            "\n文字数の目安\n", build(summary_spec("list", lengthChars=800))
        )

    def test_the_note_length_is_ignored(self):
        self.assertIn(
            "文字数や長さの指定が書かれていても、それは無視してください",
            build(summary_spec()),
        )

    def test_reading_has_a_final_check_after_the_materials(self):
        for style in ("reading", "chronicle"):
            with self.subTest(style):
                text = build(summary_spec(style))
                material = text.index("■2026年1月2日 ラーメン")
                check = text.index("書く前の最終確認")
                answer = text.index("回答は必ず次の形式")

                self.assertGreater(check, material)
                self.assertGreater(answer, check)
                self.assertIn("1つの段落は、2〜4文にしてください", text)
                self.assertIn(
                    "「ほぼ毎日」「毎日」「毎日のように」「日課」「習慣」「いつも」は、使わないでください",
                    text,
                )
                self.assertIn("同じ出来事や、同じ言い回しを、何度も書かないでください", text)
                self.assertIn("材料のどの時期も、省かずに取り上げてください", text)
                self.assertIn("タイトルは、材料の期間", text)

    def test_the_lower_bound_grows_with_the_diaries(self):
        # 日記が少ないとき(最小の500文字)
        self.assertIn("少なくとも500文字にしてください", build(summary_spec("reading")))

        # 日記が多いとき(約6万文字 → 15%で9,000 → 上限の8,000)
        text = build(summary_spec("reading", chars=60000))

        self.assertIn("少なくとも8000文字にしてください(目安は8000〜12000文字)", text)
        self.assertIn("長さの目安は8000〜12000文字です", text)
        self.assertIn("省略した出来事の細部を書き足してください", text)

    def test_a_chosen_length_does_not_clash_with_the_lower_bound(self):
        text = build(summary_spec("reading", chars=60000, lengthChars=1000))

        self.assertNotIn("少なくとも8000文字", text)
        self.assertNotIn("長さの目安は8000〜12000文字です", text)
        self.assertNotIn("省略した出来事の細部を書き足してください", text)
        self.assertIn("「文字数の目安」(1000文字くらい)に合わせてください", text)
        self.assertIn("本文は1000文字くらいを目安に書いてください", text)
        self.assertIn("文字数が短いときは、印象に残った出来事を選んでかまいません", text)

    def test_no_final_check_for_the_other_styles(self):
        for style in ("brief", "list", "custom"):
            with self.subTest(style):
                self.assertNotIn(
                    "書く前の最終確認",
                    build(summary_spec(style, customInstruction="短く")),
                )

    def test_styles_differ(self):
        reading = build(summary_spec("reading"))
        for words in [
            "形(読み物・ブログ風)", "章立て", "2〜4文ごとの段落", "羅列にしないでください",
            "頻度の言葉を使わないでください",
            "日記そのものに触れる言い方は、しないでください",
            "どの段落も、最初の文で、その段落の出来事の月を示してください",
            "日付や時期が前に戻らないように", "目安の下限より短くならないように",
            "各章に、日付か時期を、少なくとも1つは入れてください",
            "省略せずに、できるだけ詳しく、ブログのような文章",
            "日付を先頭に付けた文を並べる書き方は避けてください",
        ]:
            self.assertIn(words, reading)

        brief = build(summary_spec("brief"))
        for words in [
            "読み物(ブログ風)を、もっと簡潔にした形", "「○月○日」と日付を添えて",
            "段落と段落の間は、1行空けてください",
            "どの段落にも、「○月○日」と日付を添えた出来事を",
            "日付が前に戻らないように", "別の日の出来事を混ぜないでください",
        ]:
            self.assertIn(words, brief)

        lst = build(summary_spec("list"))
        self.assertIn("「・○月○日 出来事」", lst)
        self.assertIn("取り違えないでください", lst)

    def test_custom_uses_the_instruction_and_falls_back_to_a_blog(self):
        text = build(summary_spec("custom", customInstruction="ですます調で仕事だけ"))

        self.assertIn("ですます調で仕事だけ", text)
        self.assertIn("最優先", text)
        self.assertIn("意味不明なとき", text)
        self.assertIn("日付の流れに沿った読みやすいブログ風の文章", text)
        # 読み物の形の全文は、指示に勝ってしまうため、入れない
        self.assertNotIn("形(読み物・ブログ風)", text)

    def test_the_count_and_the_note(self):
        text = build(summary_spec(count=31, note=" 仕事を中心に "))

        self.assertIn("以下は、ユーザー本人が書いた31件の日記です", text)
        self.assertIn("ユーザーが追加で伝えたいこと\n仕事を中心に\n", text)
        self.assertIn("(なし)", build(summary_spec()))


class ConsultPromptTest(unittest.TestCase):
    FIRST = {"kind": "consult_first", "diaryCount": 5,
             "diariesText": "2026年2月1日 t\n本文"}

    def test_first_has_the_diaries_and_the_answer_format(self):
        text = build(self.FIRST)

        self.assertIn("ユーザーが選んだ5件の日記です", text)
        self.assertIn("2026年2月1日 t\n本文", text)
        # アプリの解析と合わせた見出し
        for marker in ("【相談の回答】", "【書き方の指示】", "【材料メモ】"):
            self.assertIn(marker, text)

    def test_follow_up_has_the_memo_and_the_talk_but_not_the_diaries(self):
        spec = {
            "kind": "consult_follow_up", "brief": "MEMO-仕事中心",
            "history": [
                {"fromUser": True, "text": "章立てにしたい"},
                {"fromUser": False, "text": "こうします", "proposal": "仕事の章に"},
            ],
            "message": "もっと短くして",
        }
        text = build(spec)

        self.assertIn("MEMO-仕事中心", text)
        self.assertIn("ユーザー: 章立てにしたい\nあなた: こうします\n(提案した書き方の指示: 仕事の章に)", text)
        self.assertIn("ユーザーの新しい発言\nもっと短くして", text)
        self.assertNotIn("日記\n2026", text)


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
