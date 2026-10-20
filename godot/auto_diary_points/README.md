# auto_diary_points(Godot 4 用・ポイントの共通部品)

4つのゲーム(KamoooneShot・脱出ゲーム２・3・4)で共通に使う、ポイントの部品。
サーバーとのやり取りは `docs/game_points_api.md` に書いてある。

| ファイル | 役割 |
|---|---|
| `points_client.gd` | サーバーとの通信。紐づけと、成果の通知(通信に失敗しても、ためて送り直す) |
| `points_panel.gd` | 紐づけの画面。文言とボタンは auto_diary アプリと同じ(コードを発行する、Webを開く、コードをコピー、Webでポイントを交換する、この端末の紐づけを解除)。コードだけで画面を作る |
| `points_game_config.example.gd` | ゲームごとの設定(アプリIDとキー)の見本 |

## 使い方(ゲームごとに1回)

1. **フォルダーごとコピー:** このフォルダー `auto_diary_points` を、ゲームのプロジェクトの中(例: `res://auto_diary_points/`)にコピーする。
2. **設定ファイルを作る:** `points_game_config.example.gd` を、**プロジェクトの直下に** `points_game_config.gd` という名前でコピーし、
   アプリIDとキーを書く(`res://points_game_config.gd`)。
   - アプリID: `kamoooneshot` / `escape_2` / `escape_3` / `escape_4`
   - キー: `python3 tools/make_app_key.py <アプリID>` で作ったもの(**ハッシュではないほう**)
   - **`points_game_config.gd` はリポジトリに入れない**(`.gitignore` に追加する)。
3. **Autoload に登録:** プロジェクト設定 → Autoload で、`points_client.gd` を、名前 `Points` で追加する。
4. **画面に置く:** 設定画面などに VBoxContainer を置き、`points_panel.gd` をスクリプトとして付ける。
5. **Android の書き出し設定:** 「Internet」の権限をオンにする(通信に必要)。

## 成果を知らせる

```gdscript
# ステージをクリアしたとき
Points.send_event("stage_clear")

# 1日の初回プレイ(ゲームを起動したとき。1日1回しか付かないので、毎回送ってよい)
Points.send_event("daily_first_play")
```

- ポイントの量は送らない(サーバーが決める)。成果の種類と量は、`points-api/lambda_function.py` の `EVENT_RULES`。
- 紐づけていなければ、何もしない。送るかどうかを、ゲーム側で判断する必要はない。
- 通信できないときは、端末にためておき、あとで自動で送り直す(同じ成果が二重に付くことはない)。

### ポイントが付いたことを表示したいとき
```gdscript
func _ready() -> void:
	Points.points_granted.connect(func(granted: int, total: int) -> void:
		print("%d ポイント獲得(合計 %d)" % [granted, total]))
```

| シグナル | 意味 |
|---|---|
| `points_granted(granted, total_points)` | ポイントが付いた |
| `event_skipped(event_type, reason)` | 付かなかった(`duplicate`・`event_limit`・`daily_ceiling`) |
| `linked_changed(is_linked)` | 紐づけた・解除した・サーバーに断られた |

## 動作確認(AWSにつながない)

```
godot/tests/run_tests.sh
```

偽のサーバーを起動して、Godot をヘッドレスで動かし、通信の部分と画面の部分を確かめる(Godot 4 が `godot` コマンドで使えること)。

## 注意

- **キーは、ゲームの中に入る。** 書き出したファイルを解析されると、取り出せる。守りの本命は、サーバー側の上限。
- 端末用のトークンは、端末のIDから作った鍵で暗号化して、`user://points.dat` に保存する。
  Godot には Keystore・Keychain を使う標準の仕組みがないため、ファイルを覗かれにくくする程度の守り。
  このトークンでできるのは、そのゲームの成果の通知だけ(ポイントの使用はできない)。
- 端末の機種名(`OS.get_model_name()`)が、Web の確認画面と一覧に出る。取れない場合は、OS名(Android・iOS)になる。
