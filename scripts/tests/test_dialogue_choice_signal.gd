extends SceneTree

const DialogueUI := preload("res://scripts/dialogue_ui.gd")

var failures: Array[String] = []
var picked := {}
var finished_seen := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ui := DialogueUI.new()
	root.add_child(ui)
	await process_frame

	ui.auto_advance = true
	ui.choice_selected.connect(func(choice_id: String, index: int, label: String) -> void:
		picked = {
			"choice_id": choice_id,
			"index": index,
			"label": label,
		}
	)
	ui.finished.connect(func() -> void:
		finished_seen = true
	)

	ui.start([
		["Minh", "Tên thật chưa được phép hiện ra."],
		{
			"choice_id": "test_keep_name",
			"choice": [
				["Giữ tên", [["Minh (nghĩ)", "Tôi vẫn còn ở đây."]]],
				["Bỏ tên", [["Giọng xa", "Không còn tên."]]],
			],
		},
	])

	_check(not str(ui._name_label.text).begins_with("Minh"), "player name was visible before reveal")
	for _i in range(120):
		ui._process(0.20)
		if finished_seen:
			break

	_check(finished_seen, "dialogue did not finish in auto mode")
	_check(str(picked.get("choice_id", "")) == "test_keep_name", "choice_id signal was not emitted")
	_check(int(picked.get("index", -1)) == 0, "auto choice did not pick index 0")
	_check(str(picked.get("label", "")) == "Giữ tên", "choice label signal mismatch")

	ui.queue_free()

	if failures.is_empty():
		print("DIALOGUE CHOICE SIGNAL OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
