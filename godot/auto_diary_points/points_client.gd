class_name PointsClient
extends Node
## ポイントのサーバーと通信する部品(4つのゲームで共通)
##
## ゲームの Autoload に登録して使う(名前の例: Points)。
##   Points.start_pairing()      紐づけコードを発行する → pairing_code_ready で表示する
##   Points.send_event("stage_clear")   成果を知らせる(紐づけていなければ何もしない)
##
## ポイントの量は、サーバーが決める。ゲームは「成果の種類」だけを送る。
## 詳しくは docs/game_points_api.md と、この部品の README.md を見る。

## 紐づけコードを発行した(画面に表示する)。expires_at は期限(UNIX秒)
signal pairing_code_ready(code: String, expires_at: int)
## 紐づけが済んだ
signal pairing_linked
## 紐づけが終わった(失敗)。reason: "expired"(期限切れ) / "start_failed"(発行できない) / "invalid_app"(キーが違う)
signal pairing_failed(reason: String)
## 紐づけの状態が変わった(紐づけた・解除した・サーバーに断られた)
signal linked_changed(is_linked: bool)
## ポイントが付いた
signal points_granted(granted: int, total_points: int)
## ポイントが付かなかった。reason: "duplicate" / "event_limit" / "daily_ceiling"
signal event_skipped(event_type: String, reason: String)

const API_URL := "https://137rd6syod.execute-api.ap-northeast-1.amazonaws.com"
const WEB_URL := "https://dq2edjyr3ccb9.cloudfront.net/index.html"

## ゲームごとの設定(アプリIDとキー)。リポジトリに入れない(.gitignore)
const GAME_CONFIG_PATH := "res://points_game_config.gd"

const STORAGE_PATH := "user://points.dat"
const POLL_SECONDS := 3.0
const REQUEST_TIMEOUT_SECONDS := 10.0
const RETRY_SECONDS := 60.0
## 送れなかった成果をためておく数の上限
const MAX_QUEUE := 50

## テストなどで、つなぐ先や間隔を変えるときに使う
var api_url: String = API_URL
var poll_seconds: float = POLL_SECONDS
var retry_seconds: float = RETRY_SECONDS

var _app_id: String = ""
var _app_key: String = ""
var _device_token: String = ""
## 送れていない成果: [{"eventId": ..., "type": ...}]
var _queue: Array = []
var _session: Dictionary = {}
var _pairing_id: int = 0
var _flushing: bool = false
var _retry_timer: Timer


func _ready() -> void:
	_load_game_config()
	_load_storage()

	_retry_timer = Timer.new()
	_retry_timer.one_shot = true
	_retry_timer.timeout.connect(flush)
	add_child(_retry_timer)

	# 前回、送れなかった成果を送る
	flush()


func _notification(what: int) -> void:
	# アプリに戻ってきたときも、送れていない成果を送る
	if what == NOTIFICATION_APPLICATION_RESUMED:
		flush()


## テストなどで、設定ファイルを使わずに設定する
func configure(app_id: String, app_key: String) -> void:
	_app_id = app_id
	_app_key = app_key


func is_linked() -> bool:
	return not _device_token.is_empty()


## 送れていない成果の数
func pending_event_count() -> int:
	return _queue.size()


## 紐づけコードを発行する。結果は pairing_code_ready / pairing_failed で受け取る
func start_pairing(label: String = "") -> void:
	cancel_pairing()
	var id := _pairing_id

	var result := await _request(
		"/pairing/start",
		{"appId": _app_id, "label": label if not label.is_empty() else _default_label()},
		_app_headers()
	)
	if id != _pairing_id:
		return

	if result.status != 200:
		var reason := "invalid_app" if result.status == 403 else "start_failed"
		pairing_failed.emit(reason)
		return

	var body: Dictionary = result.body
	_session = {
		"code": str(body.get("code", "")),
		"claimSecret": str(body.get("claimSecret", "")),
		"expiresAt": int(body.get("expiresAt", 0)),
	}
	pairing_code_ready.emit(_session.code, _session.expiresAt)
	_poll(id)


## 紐づけを途中でやめる
func cancel_pairing() -> void:
	_pairing_id += 1
	_session = {}


## Webのページを開く。コードを渡すと、Webの入力欄にコードが入る
func open_web(code: String = "") -> void:
	var url := WEB_URL
	if not code.is_empty():
		url += "?pair=" + code.uri_encode()
	OS.shell_open(url)


## このゲームでの紐づけを解除する。サーバーにも伝えて、Webの端末一覧からも消す
## (通信できなくても、この端末では解除する。Webからも解除できる)
func unlink() -> void:
	var token := _device_token
	_clear_link()
	if not token.is_empty():
		await _request("/device/unlink", {}, {"X-Device-Token": token})


## 成果を知らせる。紐づけていなければ何もしない
## 通信に失敗しても、ためておいて、あとで送り直す(二重には付かない)
func send_event(event_type: String) -> void:
	if not is_linked():
		return

	_queue.append({"eventId": _new_event_id(), "type": event_type})
	# たまりすぎたら、古いものを捨てる
	while _queue.size() > MAX_QUEUE:
		_queue.pop_front()
	_save_storage()
	flush()


## ためてある成果を、順に送る
func flush() -> void:
	if _flushing or not is_linked() or _queue.is_empty():
		return

	_flushing = true

	while not _queue.is_empty() and is_linked():
		var item: Dictionary = _queue[0]
		var result := await _request(
			"/events",
			{"eventId": item.eventId, "type": item.type},
			_app_headers({"X-Device-Token": _device_token})
		)

		# 通信できない・サーバーが混んでいる。あとで送り直す
		if result.status == 0 or result.status == 429 or result.status >= 500:
			_schedule_retry()
			break

		# 紐づけが解除された、または別のアプリのトークン。紐づけをやめる
		if result.status == 401 and result.body.get("error") == "invalid_device_token" \
				or result.status == 403:
			_clear_link()
			break

		_handle_event_result(item.type, result)
		# 送れた(または送っても直らない)ものは、ためておく必要がない
		if not _queue.is_empty():
			_queue.pop_front()
		_save_storage()

	_flushing = false


func _handle_event_result(event_type: String, result: Dictionary) -> void:
	if result.status != 200:
		# キーの間違いや、成果の種類の間違いなど。送り直しても直らない
		push_warning("ポイント: 成果を送れませんでした (%d %s)" % [result.status, str(result.body.get("error", ""))])
		return

	var granted := int(result.body.get("granted", 0))
	if granted > 0:
		points_granted.emit(granted, int(result.body.get("points", 0)))
	else:
		event_skipped.emit(event_type, str(result.body.get("reason", "")))


func _poll(id: int) -> void:
	while id == _pairing_id:
		await get_tree().create_timer(poll_seconds).timeout
		if id != _pairing_id:
			return

		if Time.get_unix_time_from_system() >= _session.expiresAt:
			_finish_pairing(id, "expired")
			return

		var result := await _request(
			"/pairing/claim",
			{"code": _session.code, "claimSecret": _session.claimSecret},
			{}
		)
		if id != _pairing_id:
			return

		if result.status == 200:
			var token := str(result.body.get("deviceToken", ""))
			if not token.is_empty():
				_pairing_id += 1
				_session = {}
				_device_token = token
				_queue.clear()
				_save_storage()
				linked_changed.emit(true)
				pairing_linked.emit()
				return
		elif result.status == 404:
			_finish_pairing(id, "expired")
			return
		# 202(まだ)や通信の失敗は、期限まで待ち続ける


func _finish_pairing(id: int, reason: String) -> void:
	if id != _pairing_id:
		return
	_pairing_id += 1
	_session = {}
	pairing_failed.emit(reason)


func _schedule_retry() -> void:
	if _retry_timer != null and _retry_timer.is_stopped():
		_retry_timer.start(retry_seconds)


func _clear_link() -> void:
	var was_linked := is_linked()
	_device_token = ""
	_queue.clear()
	_save_storage()
	if was_linked:
		linked_changed.emit(false)


func _app_headers(extra: Dictionary = {}) -> Dictionary:
	var headers := {"X-App-Key": _app_key}
	headers.merge(extra)
	return headers


## 戻り値: {"status": HTTPのステータス(通信できなければ0), "body": Dictionary}
func _request(path: String, body: Dictionary, headers: Dictionary) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = REQUEST_TIMEOUT_SECONDS
	add_child(http)

	var header_list := PackedStringArray(["Content-Type: application/json"])
	for key in headers:
		header_list.append("%s: %s" % [key, headers[key]])

	var error := http.request(api_url + path, header_list, HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		http.queue_free()
		return {"status": 0, "body": {}}

	var response: Array = await http.request_completed
	http.queue_free()

	if response[0] != HTTPRequest.RESULT_SUCCESS:
		return {"status": 0, "body": {}}

	var parsed: Variant = JSON.parse_string((response[3] as PackedByteArray).get_string_from_utf8())
	return {"status": int(response[1]), "body": parsed if parsed is Dictionary else {}}


func _new_event_id() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()


## Webの確認画面に出る、この端末の名前
func _default_label() -> String:
	var model := OS.get_model_name()
	if model.is_empty() or model == "GenericDevice":
		return OS.get_name()
	return model


func _load_game_config() -> void:
	# configure() で設定済みなら、設定ファイルは使わない
	if not _app_id.is_empty():
		return

	if not ResourceLoader.exists(GAME_CONFIG_PATH):
		push_warning("ポイント: %s がありません。points_game_config.example.gd をコピーして作ってください" % GAME_CONFIG_PATH)
		return

	var script: GDScript = load(GAME_CONFIG_PATH)
	var constants: Dictionary = script.get_script_constant_map()
	_app_id = str(constants.get("APP_ID", ""))
	_app_key = str(constants.get("APP_KEY", ""))


# ---------- 保存(端末用のトークンと、送れていない成果)
#
# 注意: Godot には、Keystore・Keychain を使う標準の仕組みがない。
# ここでは、端末のIDから作った鍵で、ファイルを暗号化している(ファイルを覗かれにくくする程度)。
# 端末用のトークンでできることは、このゲームの成果の通知だけ(ポイントの使用や、
# アカウントの確認はできない)。盗まれても、被害は1日の上限までに収まる。

func _storage_password() -> String:
	var device_id := OS.get_unique_id()
	if device_id.is_empty():
		device_id = "no-device-id"
	return "points:%s:%s" % [_app_id, device_id]


func _save_storage() -> void:
	var file := FileAccess.open_encrypted_with_pass(STORAGE_PATH, FileAccess.WRITE, _storage_password())
	if file == null:
		push_warning("ポイント: 保存できませんでした")
		return
	file.store_string(JSON.stringify({"deviceToken": _device_token, "queue": _queue}))


func _load_storage() -> void:
	if not FileAccess.file_exists(STORAGE_PATH):
		return

	var file := FileAccess.open_encrypted_with_pass(STORAGE_PATH, FileAccess.READ, _storage_password())
	if file == null:
		# 読めない(端末のIDが変わったなど)。未紐づけとして扱う
		return

	var data: Variant = JSON.parse_string(file.get_as_text())
	if data is Dictionary:
		_device_token = str(data.get("deviceToken", ""))
		var queue: Variant = data.get("queue", [])
		_queue = queue if queue is Array else []
