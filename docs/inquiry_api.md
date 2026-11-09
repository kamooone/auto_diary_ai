# お問い合わせのAPI(アプリ内のフォーム)

メールは使わない。端末の匿名のID(`X-Client-Id`)で、送った内容と返信をひも付ける。
返信は、開発者が `server/inquiry_admin/inquiry_admin.py` で書き込み、アプリのお問い合わせ画面に表示される。

## API(`ai_chat_lambda.py` の中で処理する。コードは `server/ai_chat/inquiry.py`)

共通: ヘッダー `X-Client-Id`(32桁の英数字。ないと 400 `client_id_required`)。

### `POST /inquiries`

```json
{ "category": "bug | request | other", "message": "本文(1〜1000文字)", "appVersion": "1.0.0 (111)", "platform": "android" }
```

- 成功(200): `{"message": {"id", "from": "user", "category", "message", "createdAt"}}`
- 400: `message_required` / `message_too_long` / `invalid_category` / `invalid_body`
- 429 `too_many_inquiries`: 24時間に5件まで、端末ごとに保存200件まで(連投・荒らしの対策)

### `GET /inquiries`

- 成功(200): `{"messages": [{"id", "from": "user | developer", "category", "message", "createdAt"}, ...]}`
  (古い順。多いときは新しい方の最大100件)

## 保存先(DynamoDB)

テーブル名 `auto-diary-inquiries`(環境変数 `INQUIRY_TABLE_NAME` で変えられる)

| 項目 | 型 | 内容 |
|---|---|---|
| `clientId`(パーティションキー) | S | 端末の匿名のID |
| `sk`(ソートキー) | S | `<日時(UTC・ミリ秒)>#<乱数>`。日時順に並ぶ |
| `from` | S | `user` または `developer` |
| `category` | S | `bug` / `request` / `other`(`user`のみ) |
| `message` | S | 本文 |
| `createdAt` | S | ISO 8601 |
| `appVersion`, `platform` | S | 不具合の調査用(`user`のみ) |

## AWS側の準備(初回のみ)

1. DynamoDBのテーブルを作る: 名前 `auto-diary-inquiries`、パーティションキー `clientId`(文字列)、ソートキー `sk`(文字列)、オンデマンド。
2. Lambda(`ai_chat`)の実行ロールに、このテーブルの `PutItem` と `Query` を許可する。
3. API Gatewayに、ルート `POST /inquiries` と `GET /inquiries` を足し、`ai_chat` のLambdaにつなぐ(`/plan/usage` と同じ)。
4. Lambdaに、`ai_chat_lambda.py` と `inquiry.py` を置く(`diary_prompts.py` と同じ場所)。

## 返信の書き方(開発者のパソコンで)

AWSの認証情報が設定してあること(`aws configure`)。boto3 が必要(`pip install boto3`)。

```
python3 server/inquiry_admin/inquiry_admin.py list              # 返信待ちの端末の一覧
python3 server/inquiry_admin/inquiry_admin.py show <端末のID>   # やり取りを全部見る
python3 server/inquiry_admin/inquiry_admin.py reply <端末のID> "返信の文章"
```

## アプリ側の動き

- 設定画面の「お問い合わせ」から開く。種類(不具合・要望・その他)を選んで送る。
- **一度でも送った端末だけ**が、アプリを開いたとき(ホーム・設定)に `GET /inquiries` で返信を確認する。
  新しい返信があると、ホームの設定アイコンと設定画面のタイルに印が付く。
- アプリを削除すると端末のIDが変わり、やり取りは見られなくなる。
