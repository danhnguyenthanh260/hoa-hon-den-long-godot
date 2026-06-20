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

	c1._try_descend()
	await _settle(game)
	_check(game.chapter_no == 1, "entered C2 without key/house/puzzle")

	c1.on_memory_stall_closed(["tea_pot", "debt_book", "incense_bowl", "brass_key", "lotus_paper"], true)
	_check(c1.has_house_key and c1.stall_inspected, "memory stall did not grant inspected key state")
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
	c1._collect_stencil_part("head")
	c1.puzzle.set_part_angle("head", 0.0)
	c1.puzzle.complete_if_ready()
	_check(not c1.puzzle.solved, "C1 puzzle solved with only one stencil part")
	c1._collect_stencil_part("wing_body")
	c1._collect_stencil_part("tail_leg")
	c1.puzzle.set_part_angle("head", 0.0)
	c1.puzzle.set_part_angle("wing_body", 0.0)
	c1.puzzle.set_part_angle("tail_leg", 0.0)
	c1.puzzle.complete_if_ready()
	await _settle(game)
	_check(c1.bird_puzzle_solved, "C1 bird puzzle solved state missing")

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
