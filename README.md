# auto_diary_ai

行動の記録から、AIが日記を書いてくれるFlutterアプリ。ゲームで貯めたポイントを、Webでトークンに交換して、AIを使える量を増やせる。

## フォルダー

| フォルダー | 動く場所 | 中身 |
|---|---|---|
| `lib/`、`test/` | スマホ(日記アプリ) | Flutterのコードとテスト |
| `android/`、`ios/` ほか | スマホ | プラットフォームごとの設定 |
| `server/points_api/` | AWS Lambda | ポイント・紐づけ・端末の管理のAPI |
| `server/ai_chat/` | AWS Lambda | AIへの問い合わせと、使用量・トークンの消費 |
| `server/points_web/` | S3 + CloudFront | ポイントの確認・交換、端末の管理のWebページ |
| `godot/auto_diary_points/` | ゲーム(Godot) | 4つのゲームで共通の、ポイントの部品 |
| `godot/tests/` | パソコン | 上の部品の動作確認(`godot/tests/run_tests.sh`) |
| `tools/` | パソコン | ビルド、配布、キーの作成などのスクリプト |
| `docs/` | | 設計と手順の説明 |

`server/` の下は、AWSに置くコードです。アプリには入りません。変更したら、AWSのコンソールで置き換える必要があります(手順は `docs/web_points_roadmap.md`)。

## アプリ(`lib/features/`)の主な機能

| フォルダー | 内容 |
|---|---|
| `points/` | Webのアカウントとの紐づけ(コードの発行、解除) |
| `plan/` | 使用量とトークン残高の表示 |
| `ai/` | AIへの問い合わせの送信 |

## テスト

```
tools/test.sh                                                              # Flutter
python3 -m unittest server/points_api/test_lambda_function.py server/ai_chat/test_ai_chat_lambda.py   # サーバー
godot/tests/run_tests.sh                                                   # Godotの部品
```

## 配布

- `tools/deploy.sh`: DeployGateへ
- `tools/deploy_play.sh "コメント"`: Google Playの内部テストへ(事前に `pubspec.yaml` のビルド番号を上げる)
- `tools/build_aab.sh`: 署名済みのAABを作るだけ

## 関連する説明

- `docs/game_points_api.md`: ゲームから使うAPI
- `docs/plan_api.md`: 日記アプリが使うAPI
- `docs/web_points_roadmap.md`: AWSの作り方と更新の手順
