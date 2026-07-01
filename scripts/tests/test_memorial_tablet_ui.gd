extends SceneTree

const MemorialTabletUI := preload("res://scripts/memorial_tablet_ui.gd")

var failures: Array[String] = []
var closed_seen := false
var closed_name := ""
var closed_attempts := -1


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ui := MemorialTabletUI.new()
	root.add_child(ui)
	await process_frame
	ui.closed.connect(func(attempted_name: String, attempts: int) -> void:
		closed_seen = true
		closed_name = attempted_name
		closed_attempts = attempts
	)
	ui.open_panel()
	_check(ui.active, "memorial tablet did not open")
	_check(ui.attempts == 0, "attempts should start at zero")

	ui._name_edit.text = "Minh"
	ui._try_inscribe()
	_check(ui.attempts == 1, "first inscribe attempt was not counted")
	_check(ui._name_edit.text == "", "input field was not cleared after refusal")

	ui._name_edit.text = "Minh"
	ui._try_inscribe()
	_check(ui.attempts == 2, "second inscribe attempt was not counted")

	ui.close_panel()
	_check(closed_seen, "closed signal not emitted")
	_check(closed_name == "Minh", "closed signal did not report last attempted name")
	_check(closed_attempts == 2, "closed signal did not report attempt count")
	ui.queue_free()

	if failures.is_empty():
		print("MEMORIAL TABLET UI OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
