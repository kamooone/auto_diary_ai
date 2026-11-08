extends SceneTree
## 画面の部品(points_panel.gd)の動作確認。Autoload「Points」がある前提

var failures: int = 0


func _initialize() -> void:
	_run()


func check(condition: bool, name: String) -> void:
	print("  ", "OK   " if condition else "NG   ", name)
	if not condition:
		failures += 1


func wait_until(condition: Callable, seconds: float = 8.0) -> bool:
	var waited := 0.0
	while waited < seconds:
		if condition.call():
			return true
		await create_timer(0.05).timeout
		waited += 0.05
	return condition.call()


func buttons(panel: Node) -> Dictionary:
	var result := {}
	for child in panel.get_children():
		if child is Button:
			result[child.text] = child
	return result


func _run() -> void:
	await process_frame
	await process_frame

	var points: Node = root.get_node("Points")
	points.api_url = OS.get_environment("MOCK_URL")
	points.poll_seconds = 0.2
	points.configure("kamoooneshot", "test-key")

	var panel: VBoxContainer = load("res://auto_diary_points/points_panel.gd").new()
	root.add_child(panel)
	await process_frame

	print("[未紐づけ]")
	var b := buttons(panel)
	check(b["コードを発行する"].visible, "発行ボタンが出る")
	check(b["Webを開く"].visible, "Webを開くボタンが出る")
	check(not b["Webでポイントを交換する"].visible, "交換ボタンは出ない")
	check(not b["この端末の紐づけを解除"].visible, "解除ボタンは出ない")
	check(not b["Webを開いて紐づける"].visible, "コード発行前は、Webボタンが出ない")

	print("[コード表示]")
	b["コードを発行する"].pressed.emit()
	var code_label: Label = panel.get_node("Code")
	await wait_until(func() -> bool: return code_label.text == "123456")
	check(code_label.text == "123456", "コードが画面に出る")
	check(b["Webを開いて紐づける"].visible and b["キャンセル"].visible, "Webボタンとキャンセルが出る")
	check(b["コードをコピー"].visible, "コピーボタンが出る")
	check(not b["コードを発行する"].visible, "発行ボタンは消える")

	print("[紐づけ完了]")
	await wait_until(func() -> bool: return points.is_linked())
	await process_frame
	check(panel.get_node("Title").text == "アカウントと紐づけ済み", "紐づけ済みの表示になる")
	check(b["この端末の紐づけを解除"].visible, "解除ボタンが出る")
	check(b["Webでポイントを交換する"].visible, "交換ボタンが出る")
	check(not b["コードをコピー"].visible, "コピーボタンは消える")
	check(not code_label.visible, "コードは消える")

	print("[解除]")
	b["この端末の紐づけを解除"].pressed.emit()
	await process_frame
	var dialog: ConfirmationDialog = null
	for child in panel.get_children():
		if child is ConfirmationDialog:
			dialog = child
	check(dialog != null and dialog.visible, "確認ダイアログが出る")
	check(points.is_linked(), "確認の前は、解除されない")
	dialog.confirmed.emit()
	await process_frame
	check(not points.is_linked(), "解除できる")
	check(b["コードを発行する"].visible, "発行ボタンに戻る")

	print("")
	print("失敗: %d" % failures)
	quit(1 if failures > 0 else 0)
