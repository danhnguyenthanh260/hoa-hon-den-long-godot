extends SceneTree

const Main := preload("res://scripts/main.gd")
const MemoryStallInspectUI := preload("res://scripts/memory_stall_inspect_ui.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := Main.new()
	root.add_child(game)
	await process_frame
	game.dialogue.auto_advance = true
	game.state = game.State.PLAY
	game.ui.hide_intro()
	var c1 = game.chapters[1]

	_check(not c1._tea_offered, "tea ritual should not start pre-offered")
	c1._offer_tea()
	await _settle(game)
	_check(not c1._tea_offered, "tea ritual should require talking to Ba first")

	c1._talk_ba()
	await _settle(game)
	c1._offer_tea()
	await _settle(game)
	_check(c1._tea_offered, "tea ritual was not recorded after offering tea")
	_check(game.narrative.evidence.has("c1_tea_ritual"), "tea ritual did not record evidence")

	c1._try_descend()
	await _settle(game)
	_check(game.chapter_no == 1, "entered C2 without key/house/puzzle")

	_check(c1.has_house_key and c1.stall_inspected, "tea ritual did not grant key state")
	c1._try_descend()
	await _settle(game)
	_check(game.chapter_no == 1, "entered C2 with key but locked house")

	c1._try_unlock_house()
	await _settle(game)
	_check(c1.house_unlocked, "house did not unlock with key")
	c1._try_descend()
	await _settle(game)
	_check(game.chapter_no == 1, "entered C2 before Chim Lac puzzle")

	_check(c1.puzzle.required_part_count() == 3, "C1 puzzle is not a three-part stencil puzzle")
	c1._collect_stencil()
	await _settle(game)
	_check(c1.bird_puzzle_solved, "C1 bird puzzle solved state missing")
	_check(game.narrative.evidence.has("c1_bird_stencil_memory_repaired"), "bird stencil puzzle did not record memory-repair evidence")

	c1._take_hoa()
	await _settle(game)
	_check(c1.hoa_unlocked and game.player.has_color("hoa"), "Fire state was not saved/unlocked")
	c1._try_descend()
	await _settle(game)
	_check(game.chapter_no == 1, "entered C2 before basement/dry well opened")

	game.player.set_color("hoa")
	c1._try_burn()
	await _settle(game)
	_check(c1.basement_open, "basement/dry well did not open with Fire")

	game.player.position = Vector3(0, 0, -23.5)
	await _settle(game)
	_check(game.chapter_no == 1, "old street trigger still enters C2")

	game.player.position = c1._basement_pos
	c1._try_descend()
	await _until(func(): return game.chapter_no == 2 and game.state == game.State.PLAY, "house basement descent", game)
	_check(c1.descended_to_c2, "C1 descent state not set")

	game.queue_free()
	if failures.is_empty():
		print("C1 PROGRESSION OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _settle(game) -> void:
	for _i in range(20):
		if game.dialogue.active:
			game.dialogue._process(0.25)
		await process_frame


func _until(cond: Callable, label: String, game, timeout_frames := 240) -> void:
	for _i in range(timeout_frames):
		if cond.call():
			return
		if game.dialogue.active:
			game.dialogue._process(0.25)
		await process_frame
	failures.append("timeout: " + label)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
