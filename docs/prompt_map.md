# プロンプトの対応表

AIに渡す文章(プロンプト)が、どのファイルに書いてあるかの一覧。
プロンプトを直すときは、ここで場所を確認して、変更したら [prompt_history.md](prompt_history.md) に追記する。

場所はすべて `lib/features/diary_create/domain/` の下。

## 日記を1つにまとめる

| ファイル | 役割 |
|---|---|
| `services/summary_prompt.dart` | **まとめて書く本体**。書き方(読み物・時系列・出来事の一覧など)ごとの指示と、「書く前の最終確認」(`_finalCheck`)が入っている。まとめの品質は、ここで決まる |
| `services/consult_prompt.dart` | 相談チャットのプロンプト(書き方の相談、書き方の指示の提案)。まとめて書く本体ではない |
| `services/summary_rules.dart` | 複数日をまとめる共通ルール。**ふつうの日記の複数日と共用** |
| `services/summary_text.dart` | 日記の材料を文字列にする部分と、長さの目安(`lengthRange`)の計算 |

## ふつうのAI日記

| ファイル | 役割 |
|---|---|
| `usecases/generate_diary_usecase.dart` | プロンプトの**本体**(共通部分)。追加で伝えたいこと、日付、渡した期間、写真、行動履歴(移動手段の注意)、Xの投稿、文字数の目安、「付け足さない」、回答の形式 |
| `services/diary_style_prompt.dart` | 書き方ごとの指示(日記・ブログ風・時系列の記録・箇条書き・自分で指定)。本体の1か所に差し込まれる。`isMultiDay`(複数日)のときの追加の指示も、ここにある |
| `services/summary_rules.dart` | 複数日の「日記」の書き方(上と共用) |
| `services/timeline_text.dart` | AIに渡す**行動履歴の見え方**(「滞在: 場所」「移動(自転車と推定)」) |

## ほかの注意

- `summary_rules.dart` を直すと、まとめ日記とふつうの日記の複数日の**両方**に効く。
- サーバー(`server/ai_chat/ai_chat_lambda.py`)には、日記の指示はない。写真と文章を、各AIに送るだけ。
- 書き方ごとの複数日の指示は、書き方ごとに別々に書いてある(日記・ブログ風・時系列の記録・箇条書き)。ひとつ足したら、ほかの書き方にも要るかを確認する。

## 直したあとの確認

1. テストを実行する(`diary_style_prompt_test.dart`、`summary_style_test.dart`、`summary_text_test.dart` など。文面を確かめるテストが失敗したら、何かが変わった合図)。
2. **条件を変えて試す**。書き方ごと、期間(1日・数日・全期間)ごと、文字数の目安(あり・なし)ごと。
   - 教訓: プロンプトに数字を足す変更は、「目安あり」「目安なし」の両方で、指示が食い違わないか確認する。
3. 1回の変更では、指示を1つだけ足す(原因が分からなくなるため)。
4. [prompt_history.md](prompt_history.md) に、理由と結果を追記する。
