extends SceneTree

const NarrativeState := preload("res://scripts/narrative_state.gd")
const CheckpointService := preload("res://scripts/checkpoint_service.gd")
const TEST_PATH := "user://checkpoint-test.json"

var failures: Array[String] = []


func _init() -> void:
	var service := CheckpointService.new()
	service.clear_checkpoint(TEST_PATH)
	var original := NarrativeState.new()
	original.set_beat("c4_crossing_price", 0.65)
	original.add_evidence("well_reflection")
	original.record_choice("c4_crossing_price", 1, "Trả tên của chính mình — giữ mặt mẹ")
	_check(service.save_checkpoint(original, 4, Vector3(1.5, 0.0, -58.0), TEST_PATH), "checkpoint write failed")
	var payload := service.load_checkpoint(TEST_PATH)
	_check(not payload.is_empty(), "checkpoint read failed")
	var restored := NarrativeState.new()
	var runtime := service.apply_checkpoint(payload, restored)
	_check(int(runtime.get("chapter_no", 0)) == 4, "chapter did not restore")
	_check(runtime.get("player_position", Vector3.ZERO).is_equal_approx(Vector3(1.5, 0.0, -58.0)), "position did not restore")
	_check(restored.name_kept == false, "choice state did not restore")
	_check(restored.verify_count == 1, "evidence did not restore")
	service.clear_checkpoint(TEST_PATH)
	if failures.is_empty():
		print("CHECKPOINT SERVICE OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
