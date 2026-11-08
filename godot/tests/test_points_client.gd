extends SceneTree
## PointsClient の動作確認(偽サーバー mock_server.py に対して行う)
## run_tests.sh から実行する。

const Client := preload("res://auto_diary_points/points_client.gd")

var failures: int = 0
var server_url: String = ""


func _initialize() -> void:
	server_url = OS.get_environment("MOCK_URL")
	_run()


func check(condition: bool, name: String) -> void:
	if condition:
		print("  OK   ", name)
	else:
		print("  NG   ", name)
		failures += 1


func wait_until(condition: Callable, seconds: float = 8.0) -> bool:
	var waited := 0.0
	while waited < seconds:
		if condition.call():
			return true
		await create_timer(0.05).timeout
		waited += 0.05
	return condition.call()


func make_client(key: String = "test-key") -> Node:
	var client: Node = Client.new()
	client.api_url = server_url
	client.poll_seconds = 0.2
	client.retry_seconds = 0.3
	client.configure("kamoooneshot", key)
	root.add_child(client)
	return client


func set_server(values: Dictionary) -> void:
	var http := HTTPRequest.new()
	root.add_child(http)
	http.request(server_url + "/_state", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(values))
	await http.request_completed
	http.queue_free()


func server_state() -> Dictionary:
	var http := HTTPRequest.new()
	root.add_child(http)
	http.request(server_url + "/_state")
	var response: Array = await http.request_completed
	http.queue_free()
	return JSON.parse_string((response[3] as PackedByteArray).get_string_from_utf8())


func server_events() -> Array:
	return (await server_state()).events


func _run() -> void:
	# ツリーが動き出してから始める
	await process_frame
	await process_frame

	DirAccess.remove_absolute("user://points.dat")

	print("[紐づけ]")
	var client := make_client()
	check(not client.is_linked(), "最初は未紐づけ")

	var codes: Array = []
	var linked_flags: Array = []
	client.pairing_code_ready.connect(func(code: String, _e: int) -> void: codes.append(code))
	client.linked_changed.connect(func(v: bool) -> void: linked_flags.append(v))

	client.start_pairing("テスト端末")
	await wait_until(func() -> bool: return client.is_linked())
	check(codes == ["123456"], "コードが表示用に通知される")
	check(client.is_linked(), "Webで確定したあと、紐づけ済みになる(2回目の確認で完了)")
	check(linked_flags == [true], "紐づけの変化が通知される")

	print("[成果]")
	var granted: Array = []
	var skipped: Array = []
	client.points_granted.connect(func(g: int, total: int) -> void: granted.append([g, total]))
	client.event_skipped.connect(func(t: String, r: String) -> void: skipped.append([t, r]))

	client.send_event("stage_clear")
	await wait_until(func() -> bool: return granted.size() == 1)
	check(granted == [[50, 50]], "ポイントが付いたと通知される")
	check(client.pending_event_count() == 0, "送れたら、ためておかない")

	client.send_event("limited_event")
	client.send_event("limited_event")
	await wait_until(func() -> bool: return skipped.size() == 1)
	check(skipped == [["limited_event", "event_limit"]], "付かなかった理由が通知される")

	print("[送り直し]")
	await set_server({"fail_next_event": 1})
	var before := (await server_events()).size()
	client.send_event("stage_clear")
	await wait_until(func() -> bool: return client.pending_event_count() == 1, 2.0)
	check(client.pending_event_count() == 1, "サーバーが失敗したら、ためておく")
	await wait_until(func() -> bool: return client.pending_event_count() == 0)
	check(client.pending_event_count() == 0, "しばらくして、自動で送り直す")
	var after := (await server_events()).size()
	check(after == before + 1, "送り直しても、サーバーには1件だけ届く")

	print("[保存]")
	var restored := make_client()
	check(restored.is_linked(), "再起動しても、紐づけ済みのまま")
	restored.queue_free()

	print("[未紐づけ]")
	var other := make_client()
	other.unlink()
	check(not other.is_linked(), "解除できる")
	await create_timer(0.5).timeout
	check((await server_state()).get("unlinked", 0) == 1, "解除をサーバーにも伝える")
	var count_before := (await server_events()).size()
	other.send_event("stage_clear")
	await create_timer(0.5).timeout
	check((await server_events()).size() == count_before, "未紐づけなら、成果を送らない")

	print("[サーバーに断られた]")
	var again := make_client()
	again.start_pairing()
	await wait_until(func() -> bool: return again.is_linked())
	await set_server({"revoked": true})
	var flags: Array = []
	again.linked_changed.connect(func(v: bool) -> void: flags.append(v))
	again.send_event("stage_clear")
	await wait_until(func() -> bool: return not again.is_linked())
	check(not again.is_linked(), "紐づけが解除されていたら、未紐づけに戻る")
	check(flags == [false], "戻ったことが通知される")
	check(again.pending_event_count() == 0, "送れない成果は捨てる")
	await set_server({"revoked": false})

	print("[キーが違う]")
	var wrong := make_client("wrong-key")
	var reasons: Array = []
	wrong.pairing_failed.connect(func(r: String) -> void: reasons.append(r))
	wrong.start_pairing()
	await wait_until(func() -> bool: return reasons.size() == 1)
	check(reasons == ["invalid_app"], "キーが違うと、紐づけを始められない")

	print("")
	print("失敗: %d" % failures)
	quit(1 if failures > 0 else 0)
