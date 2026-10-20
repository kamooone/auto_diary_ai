extends VBoxContainer
## ポイントの紐づけ画面(部品)。設定画面などに、この名前のスクリプトを付けた
## VBoxContainer を置くだけで使える。画面の部品は、コードで作る(シーンの作成は不要)。
##
## 前提: Autoload に PointsClient を「Points」という名前で登録している。

var _status: Label
var _code: Label
var _note: Label
var _start_button: Button
var _web_button: Button
var _cancel_button: Button
var _unlink_button: Button
var _current_code: String = ""


func _ready() -> void:
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status)

	_code = Label.new()
	_code.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_code.add_theme_font_size_override("font_size", 48)
	add_child(_code)

	_note = Label.new()
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_note)

	_start_button = _add_button("コードを発行して、アカウントと紐づける", _on_start)
	_web_button = _add_button("Webを開いて紐づける", _on_web)
	_cancel_button = _add_button("キャンセル", _on_cancel)
	_unlink_button = _add_button("紐づけを解除", _on_unlink)

	Points.pairing_code_ready.connect(_on_code_ready)
	Points.pairing_linked.connect(_on_linked)
	Points.pairing_failed.connect(_on_failed)
	Points.linked_changed.connect(func(_linked: bool) -> void: _refresh())

	_refresh()


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

	_code.text = _current_code if waiting else ""
	_code.visible = waiting
	_web_button.visible = waiting
	_cancel_button.visible = waiting
	_start_button.visible = not waiting and not linked
	_unlink_button.visible = linked and not waiting

	if waiting:
		_status.text = "Webにログインして、このコードを入力してください。"
		_note.text = "有効期限は10分です。ご自身で発行したコード以外は、入力しないでください。"
	elif linked:
		_status.text = "アカウントと紐づけ済みです。遊ぶとポイントが貯まります。"
		_note.text = "ポイントの確認とトークンへの交換は、Webで行います。"
	else:
		_status.text = "アカウントと紐づけると、遊んでポイントを貯められます。"
		_note.text = "アカウントがなくても、ゲームは遊べます。"


func _on_start() -> void:
	_status.text = "コードを発行しています…"
	_start_button.visible = false
	Points.start_pairing()


func _on_code_ready(code: String, _expires_at: int) -> void:
	_current_code = code
	_refresh()


func _on_linked() -> void:
	_current_code = ""
	_refresh()


func _on_failed(reason: String) -> void:
	_current_code = ""
	_refresh()
	match reason:
		"expired":
			_note.text = "コードの有効期限が切れました。もう一度発行してください。"
		"invalid_app":
			_note.text = "このゲームの設定が正しくありません。"
		_:
			_note.text = "コードを発行できませんでした。通信を確認して、もう一度お試しください。"


func _on_web() -> void:
	Points.open_web(_current_code)


func _on_cancel() -> void:
	Points.cancel_pairing()
	_current_code = ""
	_refresh()


func _on_unlink() -> void:
	Points.unlink()
	_refresh()
