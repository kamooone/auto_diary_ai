# プロンプトの対応表

AIに渡す文章(プロンプト)が、どこに書いてあるかの一覧。
プロンプトを直すときは、ここで場所を確認して、変更したら [prompt_history.md](prompt_history.md) に追記する。

## 仕組み(2026-11-08〜、サーバーがプロンプトを組み立てる)

- **アプリ**は、材料(行動履歴・Xの投稿・日記を文章にしたもの)と、設定(書き方・文字数の目安など)だけを送る(`prompt`)。
- **サーバー**(Lambda)が、指示の文章と組み立てを持つ。**プロンプトを直すときは、サーバーの `diary_prompts.py` を直して、Lambdaに貼る。アプリの更新はいらない。**
- 回答の形式(「タイトル:」「本文:」「【相談の回答】」など)は、アプリが解析している。**形式の文言は変えない**(変えるとアプリが回答を読み取れない)。

## プロンプトの場所(サーバー)

`server/ai_chat/diary_prompts.py`(Lambdaには、`ai_chat_lambda.py` と**同じ場所に置く**)

| 関数 | 役割 |
|---|---|
| `build_prompt(spec, photo_count)` | 入口。`spec["kind"]` で、下のどれかを呼ぶ |
| `build_diary_prompt` | ふつうのAI日記の本体(共通部分)。追加で伝えたいこと、日付、期間、写真の枚数、行動履歴の注意、Xの投稿、文字数の目安、「付け足さない」、回答の形式 |
| `diary_style_section` | ふつうの日記の書き方別の指示(日記・ブログ風・時系列の記録・箇条書き・自分で指定)。複数日(`is_multi_day`)の追加の指示もここ |
| `build_summary_prompt` | 日記を1つにするの本体。書き方別の指示(`_summary_reading` / `_summary_brief` / `_SUMMARY_LIST` / `_summary_custom`)と、書く前の最終確認(`_summary_final_check`) |
| `build_consult_first_prompt` / `build_consult_follow_up_prompt` | 書き方の相談(最初・続き) |
| `SUMMARY_RULES` | 複数日をまとめる共通ルール(まとめ日記と、ふつうの日記の複数日で共用) |
| `length_range` / `length_guide` | 長さの目安の計算(日記の文字数の○〜○%。下限・上限あり) |

サーバー側のテスト: `server/ai_chat/test_diary_prompts.py`(文面)、`test_ai_chat_lambda.py`(受け取り)

## 材料を文章にする部分(アプリに残っている)

`lib/features/diary_create/domain/` の下

| ファイル | 役割 |
|---|---|
| `services/prompt_spec.dart` | **サーバーに送る内容(キー名)を作る。** キー名は、サーバーの `diary_prompts.py` と合わせてある |
| `services/timeline_text.dart` | 行動履歴を文章にする(「滞在: 場所」「移動(自転車と推定)」) |
| `services/summary_text.dart` | 日記を文章にする(`formatForAi`は「■」で区切る)、文字数 |
| `usecases/generate_diary_usecase.dart` | ふつうの日記: 写真の縮小、行動履歴・投稿を文章にして、`PromptSpec.diary` を送る |
| `usecases/generate_summary_diary_usecase.dart` | 日記を1つにする: `PromptSpec.summary` を送る |
| `usecases/consult_summary_usecase.dart` | 相談: `PromptSpec.consultFirst` / `consultFollowUp` を送る |
| `services/generated_diary_parser.dart` / `consult_reply_parser.dart` | 回答の解析(**サーバーの回答形式と合わせてある**) |

## サーバーを貼るときの注意

- Lambdaには、**`ai_chat_lambda.py` と `diary_prompts.py` の2つ**を置く(同じ場所。コンソールのエディタで、新しいファイルを作って貼る)。
- `ALLOW_RAW_MESSAGE`(環境変数。初めは `true`): アプリが全文(`message`)を送ることを許すか。古いアプリのため、いまは許している。**公開前に、アプリが `prompt` を送るようになったら、`false` にする**(アプリから好きな文章をAIに送られて、トークンを使われるのを防げる)。
- 貼り忘れに注意。アプリが新しく、サーバーが古いと、作成が失敗する(`prompt` を理解できない)。**サーバーを先に貼って、アプリを出す。**

## ほかの注意

- `SUMMARY_RULES` を直すと、まとめ日記とふつうの日記の複数日の**両方**に効く。
- 書き方ごとの複数日の指示は、書き方ごとに別々に書いてある(日記・ブログ風・時系列の記録・箇条書き)。ひとつ足したら、ほかの書き方にも要るかを確認する。

## 直したあとの確認

1. サーバーのテストを実行する(`python3 -m unittest server/ai_chat/test_diary_prompts.py`)。文面を確かめるテストが失敗したら、何かが変わった合図。直したときは、テストも直す。
2. **条件を変えて試す**。書き方ごと、期間(1日・数日・全期間)ごと、文字数の目安(あり・なし)ごと。
   - 教訓: プロンプトに数字を足す変更は、「目安あり」「目安なし」の両方で、指示が食い違わないか確認する。
3. 1回の変更では、指示を1つだけ足す(原因が分からなくなるため)。
4. [prompt_history.md](prompt_history.md) に、理由と結果を追記する。
