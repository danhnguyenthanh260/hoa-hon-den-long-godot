extends SceneTree

const MemoryStallInspectUI := preload("res://scripts/memory_stall_inspect_ui.gd")

var failures: Array[String] = []
var closed_seen := false
var closed_ids: Array = []
var closed_key := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ui := MemoryStallInspectUI.new()
	root.add_child(ui)
	await process_frame
	ui.closed.connect(func(ids: Array, key_taken: bool) -> void:
		closed_seen = true
		closed_ids = ids
		closed_key = key_taken
	)
	ui.open_panel()
	_check(ui.active, "memory stall did not open")
	ui.inspect_item("tea_pot")
	ui.inspect_item("debt_book")
	ui.inspect_item("incense_bowl")
	_check(not ui.can_take_key(), "key unlocked before all required clues")
	ui.inspect_item("brass_key")
	ui.inspect_item("lotus_paper")
	_check(ui.can_take_key(), "key did not unlock after required clues")
	ui._take_key()
	_check(ui.key_taken, "key_taken was not persisted")
	ui.close_panel()
	_check(closed_seen, "closed signal not emitted")
	_check(closed_key, "closed signal did not include key")
	for id in MemoryStallInspectUI.REQUIRED_FOR_KEY:
		_check(closed_ids.has(id), "closed ids missing %s" % id)
	ui.queue_free()

	if failures.is_empty():
		print("MEMORY STALL UI OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
