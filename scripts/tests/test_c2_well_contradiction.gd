extends SceneTree

const Main := preload("res://scripts/main.gd")

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
	game.goto_chapter(2)
	await _until(func(): return game.chapter_no == 2 and game.state == game.State.PLAY, "vao C2", game)

	var c2 = game.chapters[2]
	c2._child.visible = true
	c2._talk_child()
	await _settle(game)
	c2._interact_left_well()
	await _settle(game)
	c2._look_well()
	await _until(func(): return game.narrative.contradictions.has("c2_well_vs_radio_shortcut"), "well contradiction dialogue chain", game)
	await _until(func(): return c2._well_choice_open, "well choice opens after both wells", game)
	c2._choose_right_well()
	await _until(func(): return c2._well_orb != null, "Sac Thuy appears after choosing the remembering well", game)

	_check(game.narrative.contradictions.has("c2_well_vs_radio_shortcut"), "well contradiction was not recorded")
	_check(game.narrative.evidence.has("well_reflection"), "well reflection evidence was not recorded")
	_check(c2._well_orb != null, "Sac Thuy orb did not spawn after choosing the remembering well")

	game.queue_free()
	if failures.is_empty():
		print("C2 WELL CONTRADICTION OK")
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
