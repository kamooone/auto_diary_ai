# お問い合わせ機能のまとめ(運用ガイド)

アプリ内のお問い合わせ(メールなし)と、返信のプッシュ通知について、忘れても思い出せるようにまとめたもの。
API の細かい仕様は `docs/inquiry_api.md`、コードは「5. コードの場所」を参照。

## 1. 何ができるか

- ユーザーは、設定画面の「お問い合わせ」から、種類(不具合・要望・その他)と本文を送る。
- メールアドレスは使わない。端末の匿名のID(アプリを入れるたびに作られる乱数)で、送った内容と返信をひも付ける。
- 開発者(自分)が返信を書くと、ユーザーのアプリの「お問い合わせ」画面に、チャットのように表示される。
- 返信を書くと、その端末にだけ、プッシュ通知が出る(「お問い合わせに返信が届きました」)。
  通知をタップすると、お問い合わせの画面が開く。返信の本文は、通知に載せない(ロック画面で見られないため)。
- ユーザー側の印: 新しい返信があると、ホームの設定アイコンと、設定画面の「お問い合わせ」に、赤い印が付く。

## 2. 全体の流れ

```
[ユーザーのアプリ]
   ① 送信 ──────────▶ API Gateway ─▶ Lambda ai_chat(inquiry.py) ─▶ DynamoDB auto-diary-inquiries
   ② 宛先(通知のトークン)を登録 ──▶ POST /push-token ─▶ DynamoDB auto-diary-push-tokens

[開発者(自分)]
   ③ DynamoDB のコンソールで、返信の行を追加する(from = developer)

[AWS]
   ④ DynamoDB ストリーム ─▶ Lambda auto-diary-inquiry-push ─▶ Firebase(FCM) ─▶ ユーザーの端末に通知
   
[ユーザーのアプリ]
   ⑤ 通知をタップ(またはアプリを開く)─▶ GET /inquiries で返信を取得して表示
```

- ②の宛先の登録は、**一度でも問い合わせを送った端末だけ**が行う(送っていない人の宛先は、サーバーに送らない)。
- 返信の確認(GET)も、一度でも送った端末だけが、アプリを開いたときに行う。

## 3. 使っているもの(名前の一覧)

| 種類 | 名前 | 役割 |
|---|---|---|
| DynamoDB テーブル | `auto-diary-inquiries` | 問い合わせと返信。キー: `clientId`(文字列)+ `sk`(文字列)。ストリーム有効(新しいイメージ) |
| DynamoDB テーブル | `auto-diary-push-tokens` | 通知の宛先。キー: `clientId`(文字列)のみ |
| Lambda | `ai_chat` | `inquiry.py` を同じ場所に置いてある。`/inquiries` と `/push-token` を処理 |
| Lambda | `auto-diary-inquiry-push` | 返信が追加されたら、通知を送る。ファイルは `inquiry_push_lambda.py` と `fcm_client.py`。ハンドラ `inquiry_push_lambda.lambda_handler`、タイムアウト15秒 |
| API Gateway | `auto-diary-ai-api`(REST) | `GET /inquiries`、`POST /inquiries`、`POST /push-token`(いずれも Lambda プロキシ統合、`ai_chat` につないである) |
| Parameter Store | `/auto-diary/fcm-service-account` | Firebase のサービスアカウントの鍵(JSON)。SecureString。**外に出さない** |
| Firebase | プロジェクト `auto-diary-ai` | プッシュ通知(FCM)用。Android のパッケージ名 `com.kazusa.auto_diary_ai` |
| IAM(`ai_chat` のロール) | インラインポリシー `inquiry-table-access` | `auto-diary-inquiries` と `auto-diary-push-tokens` への `PutItem`、`auto-diary-inquiries` への `Query` |
| IAM(通知用 Lambda のロール) | `AWSLambdaDynamoDBExecutionRole`(管理ポリシー)、インラインポリシー `inquiry-push-access` | ストリームの読み取り、宛先の取得・削除(`GetItem`・`DeleteItem`)、鍵の読み取り(`ssm:GetParameter`) |
| Lambda トリガー | `auto-diary-inquiry-push` に DynamoDB ストリーム | 対象 `auto-diary-inquiries`、バッチ10、開始位置 最新、再試行2回。フィルター: 下記 |

トリガーのフィルター(返信が追加されたときだけ動かす):

```json
{ "eventName": ["INSERT"], "dynamodb": { "NewImage": { "from": { "S": ["developer"] } } } }
```

## 4. 毎日の運用

### 4-1. 問い合わせが来ているか見る

今は、新しい問い合わせの通知は来ない。**DynamoDB のコンソールで見に行く**。

1. AWS コンソール → DynamoDB → テーブル `auto-diary-inquiries` →「テーブルアイテムの探索」。
2. 「スキャン」で、全部を表示する。`from` が `user` の行が、ユーザーの送信。
3. 見る項目: `message`(本文)、`category`(`bug`=不具合・`request`=要望・`other`=その他)、`appVersion`、`platform`、`createdAt`。
4. 返信待ちかどうかは、同じ `clientId` の行を並べて、**最後の行が `user` なら返信待ち**。
   (行が多くなったら、フィルターで `from = user` に絞り、`createdAt` の新しい順に見る)

パソコンのターミナルで見たいときは、`server/inquiry_admin/inquiry_admin.py` が使える
(`list` で返信待ちの一覧、`show <端末のID>` でやり取り、`reply <端末のID> "返信"` で返信)。
使うには、`pip install boto3` と `aws configure` が必要。コンソールで足りるなら、なくてよい。

### 4-2. 返信を書く(コンソール)

1. `auto-diary-inquiries` で、返信したい相手の行(`from` が `user`)を選ぶ。
2. 「アクション」→「項目を複製」。
3. 次のように直して、「項目を作成」。

| 項目 | 入れる値 |
|---|---|
| `clientId` | **変えない**(相手と同じ) |
| `sk` | 元の行より**後ろ**の日時(UTC)+ `#admin`。例: `2026-11-10T09:30:00.000Z#admin` |
| `from` | `developer` |
| `message` | 返信の文章(1000文字まで) |
| `createdAt` | `sk` の日時に合わせる。例: `2026-11-10T09:30:00+00:00` |
| `category`、`appVersion`、`platform` | 削除する |

- **`sk` は日時順に並べるための値**。元の行より前にすると、返信が上(古い側)に出てしまう。
- 日時は **UTC**(日本時間から9時間引く)。
- 追加すると、数秒〜十数秒で、相手の端末に通知が出る。

### 4-3. 返信の方針

- 個別の返信が難しいものは、返信せず、アップデートの内容に「〜を直しました」と書く形でもよい。
- ユーザー画面の案内文には「返信がある場合は、この画面に表示されます」と書いてあり、返信を約束してはいない。

## 5. コードの場所

| 内容 | ファイル |
|---|---|
| アプリ: 画面 | `lib/features/inquiry/presentation/ui/inquiry_page.dart` |
| アプリ: 通信 | `lib/features/inquiry/data/aws_inquiry_repository_impl.dart`、`aws_push_token_repository_impl.dart` |
| アプリ: 通知の宛先の登録・通知のタップ | `lib/features/inquiry/application/push_registrar.dart` |
| アプリ: 新しい返信の印 | `lib/features/inquiry/application/providers/inquiry_providers.dart`(`hasUnreadReplyProvider`) |
| サーバー: 問い合わせ・宛先の登録 | `server/ai_chat/inquiry.py`(`ai_chat_lambda.py` から呼ぶ) |
| サーバー: 通知を送る Lambda | `server/inquiry_push/inquiry_push_lambda.py`、`fcm_client.py` |
| サーバー: 返信用のスクリプト(任意) | `server/inquiry_admin/inquiry_admin.py` |
| API・準備の手順 | `docs/inquiry_api.md` |

Lambda を更新するときは、`server/` のファイルの中身を貼り直して、Deploy する
(`ai_chat_lambda.py` は、`MONTHLY_LIMIT_TOKENS` の2か所の数字を、いつもどおり入れ直すこと)。

## 6. 制限と、気をつけること

- 1端末につき、24時間に5件まで。保存は200件まで。本文は1000文字まで(荒らし・連投の対策)。
- **アプリを削除・再インストールすると、端末のIDが変わり、ユーザーは過去のやり取りを見られなくなる**
  (DynamoDB には残る)。再インストール後に返信しても、新しい端末のIDではないので、届かない。
- ユーザー向けの注意書き: 「個人情報や、日記の内容は、書かないでください」。
- プッシュ通知は Android のみ設定済み(iOS 向けには、APNs の設定などが別に必要)。
- 通知の許可は、アプリの起動時に求めている。ユーザーが拒否していたら、通知は出ない(アプリを開けば、印は出る)。
- 古い行を消す仕組みは、まだない(増えて困ったら、DynamoDB の TTL などで消す)。
- 費用は、ほぼ0円(Lambda・DynamoDB・API Gateway は使った分だけ。FCM は無料)。

## 7. うまくいかないとき

| 症状 | 見る場所 |
|---|---|
| アプリで「送信できませんでした」 | API Gateway のルート(`/inquiries`)とデプロイ。`ai_chat` のログ。`ai_chat_lambda.py`・`inquiry.py` の貼り忘れ |
| ログに `AccessDeniedException` | `ai_chat` のロールのポリシー `inquiry-table-access` |
| ログに `inquiry.py を読み込めません` | `inquiry.py` が `ai_chat_lambda.py` と同じ場所にあるか、Deploy したか |
| `auto-diary-push-tokens` に行が入らない | `ai_chat` のログに `/push-token` の記録があるか。API Gateway の `/push-token` のデプロイ。アプリを開き直す(または1件送る) |
| 返信を追加しても通知が出ない | `auto-diary-inquiry-push` のログ(下記)。端末の通知設定 |
| 通知用 Lambda のログ `{"results": ["ok"]}` | 送信は成功。端末側(通知オフ・おやすみモード)を確認 |
| 同 `["no_token"]` | 宛先がない。`clientId` が `auto-diary-push-tokens` の行と同じか |
| 同 `push failed: FcmError` | 鍵・送信先の問題。Parameter Store の鍵、Firebase のプロジェクト |
| 同 `push failed: ClientError` | 通知用 Lambda の IAM 権限 |
| 同 ログが何も出ない | トリガーが有効か。返信の行の `from` が `developer` か。ストリームが有効か |
| 通知は出るが、タップしても画面が開かない | アプリを最新に更新する |

ログの見方: Lambda の画面 →「モニタリング」→「CloudWatch のログを表示」。
通知用 Lambda のログには、宛先や返信の本文は出さない作りにしてある。

## 8. 将来の検討: 問い合わせが来たら、自分に知らせる

今は、問い合わせが来ても、通知は来ない。件数が増えたら、**自分のメール(または Slack など)に知らせる**ことを検討する。

### 方法の案

1. **DynamoDB ストリーム → SNS → メール**(おすすめ)
   - 返信と同じストリームを使う。ユーザーの送信(`from` が `user` の行が追加されたとき)に反応させる。
   - SNS のトピックを作り、自分のメールアドレスを購読(確認メールが届く)。
   - つなぎ方は2通り:
     - 小さな Lambda を足して、SNS に `publish` する(メール本文に、種類・本文の頭・`clientId` を入れる)。
     - コードなしで、EventBridge Pipes を使う(ストリームを入口、SNS を出口にし、フィルターで `from = user` に絞る)。
   - 費用は、ほぼ0円(SNS のメールは月1,000通まで無料)。
   - フィルターの例: `{ "eventName": ["INSERT"], "dynamodb": { "NewImage": { "from": { "S": ["user"] } } } }`
2. **Slack や Discord の Webhook に送る**
   - 小さな Lambda から、Webhook の URL に POST する。スマホの通知で気づきやすい。
   - Webhook の URL は、鍵と同じく、Parameter Store(SecureString)に置く。
3. **1日1回のまとめメール**
   - 件数が多いとき向き。EventBridge のスケジュールで Lambda を動かし、前日の分をまとめて送る。

### 決めておくこと

- 本文を、メールに入れるか。入れると、個人情報が書かれていた場合に、メールにも残る(「個人情報は書かないで」と案内はしているが、書く人はいる)。
  安全にするなら、「新しい問い合わせが届きました(種類:不具合)」だけにして、中身は DynamoDB で見る。
- 連投・荒らしがあっても、メールが大量に来ないようにする(1端末につき1日5件までの制限が、すでにある)。

### 返信の手間を減らす案(あわせて検討)

- 返信の入力に、コンソールの「項目の複製」が手間になったら、`inquiry_admin.py reply` を使う、または、返信専用の簡単な画面を作る。
