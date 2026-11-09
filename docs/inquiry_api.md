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

### `POST /push-token`(返信の通知の宛先を登録する)

```json
{ "token": "FCMのトークン" }
```

- 成功(200): `{"ok": true}`(同じ端末は上書き)
- 400: `invalid_token` / `invalid_body`、403 `no_inquiry`(一度も問い合わせを送っていない端末は受け付けない)
- アプリは、**一度でも問い合わせを送った端末だけ**が、宛先を登録する。

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

宛先のテーブル `auto-diary-push-tokens`(環境変数 `PUSH_TOKEN_TABLE_NAME`): パーティションキー `clientId`(S)、`token`(S)、`updatedAt`(S)。

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

## 返信のプッシュ通知(Firebase)

返信の行(`from` が `developer`)が `auto-diary-inquiries` に追加されると、DynamoDB Streams をきっかけに、
別のLambda(`server/inquiry_push/`)が、その端末にFCMで通知を送る。コンソールで書いた返信も対象。

- 通知の文面は固定(「お問い合わせに返信が届きました」)。返信の本文は載せない(ロック画面で見られないよう)。
- 宛先が使えなくなっていたら(アプリを消したなど)、宛先を削除する。
- 通知をタップすると、アプリのお問い合わせの画面が開く。

### 準備(初回のみ)

1. Firebaseのプロジェクトを作り、Androidアプリを登録して、`google-services.json` を `android/app/` に置く
   (`.gitignore` の対象なので、コミットされない。別のPCでは、Firebaseコンソールから取り直す)。
2. Firebaseの「サービス アカウント」で秘密鍵(JSON)を作り、Parameter Store に SecureString で入れる
   (名前 `/auto-diary/fcm-service-account`、値はJSONの中身まるごと)。チャットやGitに載せない。
3. DynamoDBのテーブル `auto-diary-push-tokens` を作る(パーティションキー `clientId` 文字列、オンデマンド)。
4. `auto-diary-inquiries` の「エクスポートおよびストリーム」で、DynamoDB ストリームを有効にする(表示タイプ: 新しいイメージ)。
5. `ai_chat` のLambdaの実行ロールに、`auto-diary-push-tokens` への `PutItem` を許可する。
6. API Gatewayに、リソース `/push-token`(メソッド `POST`、Lambdaプロキシ統合、`ai_chat` につなぐ)を足して、デプロイする。
7. `ai_chat_lambda.py` と `inquiry.py` を貼り直す。
8. 通知用のLambdaを新しく作る(下記)。

### 通知用のLambda

- 関数名 `auto-diary-inquiry-push`、ランタイム Python 3.12 以降、ハンドラ `inquiry_push_lambda.lambda_handler`、タイムアウト 15秒。
- ファイル `server/inquiry_push/inquiry_push_lambda.py` と `server/inquiry_push/fcm_client.py` を、同じ場所に置く。
- 実行ロールの権限:
  - 管理ポリシー `AWSLambdaDynamoDBExecutionRole`(ストリームの読み取りとログ)
  - `auto-diary-push-tokens` への `GetItem` と `DeleteItem`
  - Parameter Store の `/auto-diary/fcm-service-account` への `ssm:GetParameter`
- トリガー: DynamoDB の `auto-diary-inquiries` のストリーム。バッチサイズ 10、開始位置 最新(LATEST)、
  再試行 2回、フィルター(返信だけで動かす):

```json
{ "eventName": ["INSERT"], "dynamodb": { "NewImage": { "from": { "S": ["developer"] } } } }
```
