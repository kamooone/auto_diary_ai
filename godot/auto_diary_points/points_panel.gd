extends VBoxContainer
## ポイントの紐づけ画面(部品)。設定画面などに、この名前のスクリプトを付けた
## VBoxContainer を置くだけで使える。画面の部品は、コードで作る(シーンの作成は不要)。
## 文言とボタンは、auto_diary アプリの「ポイント・トークン」画面と同じ。
##
## 前提: Autoload に PointsClient を「Points」という名前で登録している。

var _title: Label
var _error: Label
var _status: Label
var _steps: Label
var _code: Label
var _note: Label
var _start_button: Button
var _open_web_button: Button
var _copy_button: Button
var _pair_web_button: Button
var _cancel_button: Button
var _exchange_button: Button
var _unlink_button: Button
var _unlink_dialog: ConfirmationDialog
var _current_code: String = ""


func _ready() -> void:
	add_theme_constant_override("separation", 8)

	var description := _add_label(
		"Webのアカウントでポイントをトークンに交換すると、AIに日記を書いてもらえる量が増えます。"
		+ "アカウントの作成と、ポイントの交換は、Webで行います。"
		+ "アカウントがなくても、アプリは毎月の枠の中で使えます。"
	)
	description.name = "Description"

	_title = _add_label("")
	_title.name = "Title"
	_title.add_theme_font_size_override("font_size", 22)

	_error = _add_label("")
	_error.name = "Error"
	_error.add_theme_color_override("font_color", Color(0.85, 0.2, 0.2))

	_status = _add_label("")
	_status.name = "Status"

	_steps = _add_label(
		"1. 下のボタンで、6桁のコードを発行します\n"
		+ "2. Webにログインして、コードを入力します\n"
		+ "3. 確認画面で、この端末であることを確かめて、紐づけます"
	)
	_steps.name = "Steps"

	_code = Label.new()
	_code.name = "Code"
	_code.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_code.add_theme_font_size_override("font_size", 48)
	add_child(_code)

	_note = _add_label("")
	_note.name = "Note"

	_start_button = _add_button("コードを発行する", _on_start)
	_open_web_button = _add_button("Webを開く", _on_open_web)
	_copy_button = _add_button("コードをコピー", _on_copy)
	_pair_web_button = _add_button("Webを開いて紐づける", _on_pair_web)
	_cancel_button = _add_button("キャンセル", _on_cancel)
	_exchange_button = _add_button("Webでポイントを交換する", _on_open_web)
	_unlink_button = _add_button("この端末の紐づけを解除", _on_unlink)

	_unlink_dialog = ConfirmationDialog.new()
	_unlink_dialog.title = "紐づけを解除しますか？"
	_unlink_dialog.dialog_text = (
		"この端末では、アカウントのトークンを使えなくなります。"
		+ "トークンの残高は、アカウントに残ります。"
		+ "Webの端末一覧からも、この端末が消えます。"
	)
	_unlink_dialog.dialog_autowrap = true
	_unlink_dialog.ok_button_text = "解除する"
	_unlink_dialog.cancel_button_text = "やめる"
	_unlink_dialog.confirmed.connect(_on_unlink_confirmed)
	add_child(_unlink_dialog)

	Points.pairing_code_ready.connect(_on_code_ready)
	Points.pairing_linked.connect(_on_linked)
	Points.pairing_failed.connect(_on_failed)
	Points.linked_changed.connect(func(_linked: bool) -> void: _refresh())

	_refresh()


func _add_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	return label


func _add_button(text: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(handler)
	add_child(button)
	return button


## 状態に合わせて、表示を切り替える
func _refresh() -> void:
	var waiting := not _current_code.is_empty()
	var linked: bool = Points.is_linked()
	var idle := not waiting and not linked

	# 未紐づけ(コード発行前)
	_steps.visible = idle
	_start_button.visible = idle
	_open_web_button.visible = idle

	# コード発行中
	_code.text = _current_code
	_code.visible = waiting
	_copy_button.visible = waiting
	_pair_web_button.visible = waiting
	_cancel_button.visible = waiting

	# 紐づけ済み
	_exchange_button.visible = linked and not waiting
	_unlink_button.visible = linked and not waiting

	if waiting:
		_title.text = "アカウントと紐づける"
		_status.text = "Webにログインして、このコードを入力してください。"
		_note.text = (
			"有効期限は10分です。Webで紐づけると、この画面が自動で切り替わります。"
			+ "自分で発行したコード以外は、入力しないでください。"
		)
	elif linked:
		_title.text = "アカウントと紐づけ済み"
		_status.text = "遊ぶとポイントが貯まります。"
		_note.text = "ポイントの確認とトークンへの交換は、Webで行います。"
		_error.text = ""
	else:
		_title.text = "アカウントと紐づける"
		_status.text = ""
		_note.text = ""

	_status.visible = not _status.text.is_empty()
	_note.visible = not _note.text.is_empty()
	_error.visible = not _error.text.is_empty()


func _on_start() -> void:
	_error.text = ""
	_start_button.visible = false
	Points.start_pairing()


func _on_code_ready(code: String, _expires_at: int) -> void:
	_current_code = code
	_refresh()


func _on_linked() -> void:
	_current_code = ""
	_error.text = ""
	_refresh()


func _on_failed(reason: String) -> void:
	_current_code = ""
	match reason:
		"expired":
			_error.text = "コードの有効期限が切れました。もう一度発行してください。"
		"invalid_app":
			_error.text = "このゲームの設定が正しくありません。"
		_:
			_error.text = "コードを発行できませんでした。通信を確認して、もう一度お試しください。"
	_refresh()


func _on_open_web() -> void:
	Points.open_web()


func _on_pair_web() -> void:
	# 同じ端末なら、コードを入力する手間を省く
	Points.open_web(_current_code)


func _on_copy() -> void:
	DisplayServer.clipboard_set(_current_code)


func _on_cancel() -> void:
	Points.cancel_pairing()
	_current_code = ""
	_refresh()


func _on_unlink() -> void:
	_unlink_dialog.popup_centered(Vector2i(500, 0))


func _on_unlink_confirmed() -> void:
	Points.unlink()
	_refresh()
