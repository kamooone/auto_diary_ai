# ポイント・トークンのWeb側 構築手順(AWS)

進め方: 手順を1つずつ示し、AWSのコンソールはあなたが操作する。
各手順の最後に「確認すること」があるので、結果を伝えてもらう。

## 全体の構成(最小・サーバーレス)

```
[ブラウザ] ─ 静的なWebページ(S3 + CloudFront)
    │  ログイン/アカウント作成: Cognito のホストUI(自作の入力フォームは作らない)
    ▼
[API Gateway(HTTP API)] ─ Cognito のJWTで認証 ─ [Lambda(Python)] ─ [DynamoDB]
                                                         ▲
[日記アプリ / ゲーム] ───── 端末用トークンで認証 ───────────┘
```

- リージョンは、既存と同じ `ap-northeast-1`(東京)にそろえる。
- 言語は、既存のLambdaと同じPython。Webページは、フレームワークなしのHTML+JavaScript。
- 費用は、小さい規模ならほぼ無料枠に収まる。最初に予算アラートを入れる。

## 手順(モックから始める)

| 手順 | 内容 | できあがるもの |
|---|---|---|
| 0 | 準備: 予算アラート、名前の決定 | 使いすぎの通知 |
| 1 | Cognito: アカウントの作成・ログインの土台 | ホストUIでサインアップ/ログインできる |
| 2 | Webページ(S3 + CloudFront) | ログインして「ログイン中: メールアドレス」と出るページ |
| 3 | DynamoDB + Lambda + API: ポイント残高(モック) | ページに残高が出る。テスト用にポイントを付ける口(開発用) |
| 4 | ポイント → トークンの交換 | Webで交換でき、残高が増減する |
| 5 | ペアリング: 端末とアカウントの紐づけ | アプリのコードをWebに入れると紐づく |
| 6 | `/ai/chat` との連携 | AI利用時にトークンが引かれる。使用量APIが残高を返す |
| 7 | 本番化: ゲームからの付与、不正対策、退会ページ、プライバシー | 公開できる状態 |

手順1〜4は、日記アプリと独立して作れる。5以降で、アプリ側の実装(私が行う)と合流する。

---

## 手順0: 準備

### 0-1. 予算アラート(必須。最初にやる)

誤って費用が増えたときに、気づくための設定。

1. AWSコンソール右上のアカウント名 → 「Billing and Cost Management」
2. 左メニュー「Budgets」→「Create budget」
3. 「Use a template (simplified)」→「Monthly cost budget」
4. 予算額は、例えば `1,000円` 相当(USDで `7` くらい)。通知先に自分のメールアドレスを入れる
5. 作成する

### 0-2. 名前を決める

- Webサービスの名前(仮でよい)。例: `auto-diary-points`
- 以後のリソース名の接頭辞に使う。

### 確認すること
- 予算アラートを作成できたか。
- サービス名の候補。

---

## 手順1: Cognito(アカウント)

### 作るもの
ユーザープール(メールアドレス+パスワード)と、Webページ用のアプリクライアント。

### 手順(画面の表記は、AWSの更新で少し変わることがある)

1. コンソール右上のリージョンを「アジアパシフィック(東京) ap-northeast-1」にする
2. 「Cognito」→「ユーザープールを作成」
3. アプリケーションタイプ: **シングルページアプリケーション(SPA)**
4. 名前: `auto-diary-points-web` など
5. サインイン識別子: **メールアドレス**
6. 必須の属性: メールアドレス
7. 戻りURL(リダイレクト先): いまは仮に `http://localhost:8080/callback`(手順2でCloudFrontのURLに変える)
8. 作成する
9. 作成後、ユーザープールの設定で次を確認する
   - 「アプリケーションクライアント」: クライアントシークレットが**ない**こと(SPAなので不要)
   - 「ブランディング/ドメイン」: Cognitoのドメイン(例: `https://xxxx.auth.ap-northeast-1.amazoncognito.com`)があること
   - MFA(多要素認証)は、いまは「なし」でよい(本番化の前に再検討)
10. ホストUIの確認: 「アプリケーションクライアント」→ ログインページを表示 で、画面が出ることを確認し、テスト用のアカウントを1つ作ってみる(メールに確認コードが届く)

### 確認すること(私に教えてほしい値。どれも秘密ではない)
- ユーザープールID(例: `ap-northeast-1_XXXXXXXXX`)
- アプリクライアントID
- Cognitoのドメイン
- テスト用のアカウントを作成できたか

### この手順で学ぶこと
- ユーザープール = アカウントの入れ物。ホストUI = Cognitoが用意するログイン画面。
- クライアントシークレットがない理由: ブラウザのコードは公開されるため、秘密を置けない。

---

## 手順2: ログインできるWebページ

ページは `points-web/` に用意してある(Flutterの `web/` とは別のフォルダ)。

### 2-1. 設定ファイルに値を入れる

`points-web/config.js` の2つの値を、手順1で控えた値にする。
- `cognitoDomain`: Cognito のドメイン(`https://….auth.ap-northeast-1.amazoncognito.com`。末尾に `/` は付けない)
- `clientId`: アプリクライアントID

### 2-2. 自分のパソコンで動かして確認する

1. Cognito のアプリクライアントの設定で、**許可されている戻りURL**に `http://localhost:8080/index.html` を追加する
   (「ログインページ」の欄を編集)。
2. ターミナルで次を実行する。

```
cd points-web
python3 -m http.server 8080
```

3. ブラウザで `http://localhost:8080/index.html` を開く。
4. 「ログイン / アカウント作成」を押す → 手順1で作ったアカウントでログイン →
   ページに戻り、「ログイン中: メールアドレス」と出れば成功。
5. 「ログアウト」を押すと、ログイン前の表示に戻る。
   ログアウトが「redirect」系のエラーになるときは、アプリクライアントの
   「許可されているサインアウトURL」に同じURLを追加する。

### 2-3. インターネットに公開する(S3 + CloudFront)

ファイルをS3(置き場)に置き、CloudFront(配信の窓口)から、HTTPSで公開する。
S3は非公開のままにして、CloudFront経由でだけ見られるようにする(OAC)。

1. **S3のバケットを作る**
   - S3 → 「バケットを作成」。リージョンは東京。名前は世界で一意にする
     (例: `auto-diary-points-web-<ランダムな数字>`)。
   - 「パブリックアクセスをすべてブロック」は、**オンのまま**(既定)。
   - 作成後、バケットを開いて `index.html`、`app.js`、`config.js` をアップロードする
     (`config.js` は、値を入れたもの)。
2. **CloudFrontのディストリビューションを作る**
   - CloudFront → 「ディストリビューションを作成」。
   - オリジン: 作ったS3バケットを選ぶ(「S3の静的ウェブサイトのエンドポイント」ではなく、通常のS3バケット)。
   - オリジンへのアクセス: **Origin access control (OAC)**。「新しいOACを作成」で、既定のまま作る。
   - ビューワープロトコルポリシー: **Redirect HTTP to HTTPS**。
   - デフォルトルートオブジェクト: `index.html`。
   - WAFは、有効にしない(費用が増える)。料金プランを選ぶ画面が出たら、無料のプランでよい。
3. **S3にバケットポリシーを入れる**
   - ディストリビューションを作ると、「ポリシーをコピー」と書かれたメッセージが出る。
     コピーして、S3のバケット → 「アクセス許可」→「バケットポリシー」に貼り付けて保存する。
     (CloudFrontだけがS3を読めるようにする設定)
4. **公開URLを確かめる**
   - ディストリビューションの状態が「デプロイ済み」になるのを待つ(数分)。
   - 「ディストリビューションのドメイン名」(`dxxxxxxxx.cloudfront.net`)を控える。
5. **Cognitoに、公開URLを登録する**(2-2のAと同じ場所)
   - 許可するコールバックURLに、次の**2つ**を追加する。
     - `https://dxxxxxxxx.cloudfront.net/index.html`
     - `https://dxxxxxxxx.cloudfront.net/`
   - 許可するサインアウトURLにも、同じ2つを追加する。
   - (ページは、開いたURLそのものを戻り先に使うため、`/` で開いても動くように、両方登録する)
6. **試す**
   - `https://dxxxxxxxx.cloudfront.net/index.html` を開き、ログイン・ログアウトできることを確認する。

### 後でファイルを更新するとき
CloudFrontは、ファイルを一定時間キャッシュする。S3に新しいファイルを上げたあと、
CloudFrontの「無効化」タブで、`/*` を指定して作成すると、すぐに反映される。

### 確認すること
- 2-2で、「ログイン中: メールアドレス」が表示されたか。
- 表示されなかった場合は、画面に出たメッセージと、ブラウザのアドレス欄のURL
  (`code=` や `state=` の値は、伏せてよい)。

---

## 手順3: ポイント残高のAPI(モック)

ログインしたアカウントの残高を、DynamoDBに持ち、APIで返す。
コードは `points-api/lambda_function.py`(Lambda)と、`points-web/`(ページ)に用意してある。

### 3-1. DynamoDBのテーブル
- DynamoDB → 「テーブルの作成」。リージョンは東京。
- テーブル名: `auto-diary-points-accounts`
- パーティションキー: `accountId`(文字列)
- 設定: 「デフォルト設定」でよい(オンデマンド)。
- 1アカウントが1行。項目は `points`(ポイント)、`tokens`(トークン)、`createdAt`。
  `accountId` には、Cognito の `sub`(アカウント固有のID)を使う。メールアドレスは保存しない。

### 3-2. Lambda関数
- Lambda → 「関数の作成」→「一から作成」。名前: `auto-diary-points-api`、ランタイム: Python(最新)、
  実行ロール: 「基本的なLambdaアクセス権限で新しいロールを作成」。
- コード: `points-api/lambda_function.py` の中身を、エディタに貼って「Deploy」。
- 「設定」→「環境変数」: `TABLE_NAME` = `auto-diary-points-accounts`、`ENABLE_DEV_GRANT` = `true`。
- 「設定」→「アクセス権限」→ 実行ロールを開き、インラインポリシーを追加して、
  対象のテーブルにだけ `dynamodb:UpdateItem` を許可する(リソースは、テーブルのARN)。

### 3-3. API Gateway(HTTP API)
- API Gateway → 「APIを作成」→ **HTTP API**。統合: 上のLambda。
- ルート: `GET /me`、`POST /dev/grant`。ステージ: `$default`(自動デプロイ)。
- 認可 → 「オーソライザーを作成」(JWT): 発行者 `https://cognito-idp.ap-northeast-1.amazonaws.com/<ユーザープールID>`、
  対象者 = アプリクライアントID。2つのルートに割り当てる。
- CORS: 許可するオリジンに `https://dq2edjyr3ccb9.cloudfront.net` と `http://localhost:8080`、
  ヘッダーは `authorization,content-type`、メソッドは `GET,POST,OPTIONS`。
- 「呼び出しURL」(`https://xxxx.execute-api.ap-northeast-1.amazonaws.com`)を控える。

### 3-4. ページを動かす
- `points-web/config.js` の `apiBase` に、呼び出しURLを入れる。
- ローカル(`python3 -m http.server 8080`)で確認してから、S3へ上げ直し、CloudFrontで `/*` を無効化する。
- ログイン後、ポイント0・トークン0が出て、「テスト用: ポイントを10追加」で10ずつ増えれば成功。

---

## 手順4: ポイント → トークンの交換

### ルール(コードの先頭の定数。変えるときはここだけ直す)
- 1ポイント = 1トークン(`TOKENS_PER_POINT`)
- 1回の交換で、最低 10,000 ポイントを使う(`MIN_EXCHANGE_POINTS`)。上限は、持っているポイントまで。

### 仕組み
- `POST /exchange` に `{"points": 12000, "requestId": "..."}` を送る。
- 残高の更新(ポイントを引き、トークンを足す)と、履歴(ledgerテーブル)への記録を、
  DynamoDBのトランザクションで同時に行う。
- 「ポイントが足りているときだけ更新する」条件を付けてあるので、
  同時に2回押されても、残高がマイナスにならない。
- `requestId` が同じリクエストは、約10分間、1回しか実行されない(送り直しの二重実行を防ぐ)。

### 作業
1. DynamoDBに、履歴のテーブルを作る
   - テーブル名: `auto-diary-points-ledger`
   - パーティションキー: `accountId`(文字列)、ソートキー: `entryId`(文字列)
2. Lambdaの環境変数に `LEDGER_TABLE_NAME` = `auto-diary-points-ledger` を追加する
3. Lambdaの実行ロールのインラインポリシーを、2つのテーブルに合わせて直す
   - accountsテーブル: `dynamodb:UpdateItem`、`dynamodb:GetItem`
   - ledgerテーブル: `dynamodb:PutItem`
4. Lambdaのコードを `points-api/lambda_function.py` の内容に置き換えて、Deploy
5. API Gatewayに、ルート `POST /exchange` を追加し、統合(Lambda)とオーソライザー(`cognito`)を付ける
6. ページ(`index.html`、`app.js`)を、ローカルで確認してから、S3へ上げてCloudFrontのキャッシュを削除する

### 確認
- 「ポイントを10,000追加」→「トークンに交換」で、ポイントが減り、トークンが増える。
- 10,000未満を入れると、「10,000ポイント以上から交換できます」と出る。
- ポイントより多く入れると、「ポイントが足りません」と出る。
- ledgerテーブルに、`dev_grant` と `exchange` の履歴が1行ずつ増える。

### Lambdaの単体テスト(AWSにつながない)
```
python3 -m unittest points-api/test_lambda_function.py
```

---

## 手順5: アプリとの紐づけ

### 流れ
1. アプリが `POST /pairing/start` を呼ぶ → サーバーが **6桁のコード** と **合言葉(claimSecret)** を返す(コードは10分で失効)。
2. アプリの画面にコードを表示する。合言葉は、アプリの中だけに持つ(画面には出さない)。
3. ユーザーがWebにログインして、コードを入力する → `POST /pairing/lookup` で端末の名前を確認し、
   確認ダイアログで本人に確かめてから、`POST /pairing/confirm` で端末とアカウントを結ぶ。
4. アプリは、`POST /pairing/claim`(コードと合言葉)を、数秒おきに呼ぶ。
   確定済みになると、**端末用のトークン**(`<端末ID>.<秘密の文字列>`)が1回だけ返る。
5. アプリはトークンを安全な場所(Keychain/Keystore)に保存する。手順6で、`/ai/chat` に付ける。

### セキュリティ上の約束
- サーバーに保存するのは、合言葉と、端末の秘密の文字列の **ハッシュだけ**(漏れても元の値は分からない)。
- コードは使い切り。トークンを渡したら、コードの行は削除する。
- 「画面を見ただけの人」は、合言葉を知らないので、トークンを横取りできない。
- 想定される攻撃: 「このコードをWebに入力して」と言われて、ログイン中の人が他人のアプリを紐づけてしまう。
  → Webは、確認ダイアログで端末の名前を見せ、「ご自身のアプリのコードだけ」と注意書きを出す。
- 端末は、アカウントごとに3台まで(`MAX_DEVICES`)。Webから解除できる。

### 作業
1. DynamoDBのテーブルを2つ作る(東京)
   - `auto-diary-points-pairing`: パーティションキー `code`(文字列)。
     作成後、「追加の設定」→「有効期限 (TTL)」を有効にして、属性名は `expiresAt`
     (期限切れの行を、DynamoDBが自動で削除する)。
   - `auto-diary-points-devices`: パーティションキー `deviceId`(文字列)。
     作成後、「インデックス」→「インデックスを作成」: パーティションキー `accountId`(文字列)、
     名前 `accountId-index`、射影は「すべて」。
2. Lambdaの環境変数に追加
   - `PAIRING_TABLE_NAME` = `auto-diary-points-pairing`
   - `DEVICES_TABLE_NAME` = `auto-diary-points-devices`
3. 実行ロールのインラインポリシーに、次を追加する(ARNは自分のもの)
   - pairingテーブル: `dynamodb:PutItem`、`dynamodb:GetItem`、`dynamodb:UpdateItem`、`dynamodb:DeleteItem`
   - devicesテーブル: `dynamodb:PutItem`、`dynamodb:DeleteItem`
   - devicesテーブルのインデックス(`<devicesのARN>/index/accountId-index`): `dynamodb:Query`
4. Lambdaのコードを `points-api/lambda_function.py` の内容に置き換えて、Deploy
5. API Gatewayにルートを追加する
   - ログインが必要(オーソライザー `cognito` を付ける):
     `POST /pairing/lookup`、`POST /pairing/confirm`、`GET /devices`、`DELETE /devices/{deviceId}`
   - ログイン不要(**オーソライザーを付けない**): `POST /pairing/start`、`POST /pairing/claim`
   - 6つとも、統合はLambda(`auto-diary-points-api`)。
6. ログイン不要の2つに、呼び出し回数の制限をかける
   - コンソールには、ルートごとのスロットリングの設定が見当たらなかったため、**公開前の宿題**とする
     (手順の最後の「本番に向けた総点検」で、AWS CLIの `update-stage --route-settings` などで設定する)。
   - 目安は、`POST /pairing/start` と `POST /pairing/claim` を、毎秒5回・バースト10回くらい。
7. ページ(`index.html`、`app.js`)をS3へ上げて、CloudFrontのキャッシュを削除する

### 確認(アプリの実装前は、`curl` で試せる)
```
# アプリの代わり: コードを発行する(ログイン不要)
curl -s -X POST https://<API>/pairing/start -H 'Content-Type: application/json' -d '{"label":"テスト端末"}'
```
返ってきた `code` を、Webの「アプリを紐づける」に入力する → 端末が一覧に出る。
その後、`code` と `claimSecret` で、次を呼ぶと、`deviceToken` が返る。
```
curl -s -X POST https://<API>/pairing/claim -H 'Content-Type: application/json' -d '{"code":"<code>","claimSecret":"<claimSecret>"}'
```
- 2回目の `claim` は、404になる(トークンは1回しか渡さない)。
- Webの「解除」で、一覧から消える。
