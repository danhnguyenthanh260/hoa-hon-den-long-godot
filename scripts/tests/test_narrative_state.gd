extends SceneTree

const NarrativeState := preload("res://scripts/narrative_state.gd")

var failures: Array[String] = []


func _init() -> void:
	_test_unique_evidence()
	_test_choice_and_endings()
	_test_round_trip()
	_test_invalid_load_is_atomic()
	if failures.is_empty():
		print("NARRATIVE STATE OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _test_unique_evidence() -> void:
	var state := NarrativeState.new()
	_check(state.add_evidence("well_reflection", "reflection contradicts the voice"), "first evidence insert failed")
	_check(not state.add_evidence("well_reflection"), "duplicate evidence was accepted")
	_check(state.verify_count == 1, "duplicate evidence changed verify_count")


func _test_choice_and_endings() -> void:
	var loop_state := NarrativeState.new()
	loop_state.adjust_trust(100)
	loop_state.record_choice("c4_crossing_price", 0, "Trả gương mặt của mẹ — giữ tên")
	_check(loop_state.ending_key() == "loop", "loop ending is unreachable without verified evidence")

	var state := NarrativeState.new()
	state.set_bond("ba", 1)
	state.set_bond("child", 1)
	state.add_evidence("well_reflection")
	state.add_evidence("blank_tablet")
	state.add_evidence("original_radio_layer")
	state.record_choice("c4_crossing_price", 0, "Trả gương mặt của mẹ — giữ tên")
	_check(state.name_kept == true, "first crossing choice did not preserve the name")
	_check(state.ending_key() == "release", "release ending eligibility is wrong")
	state.record_choice("c4_crossing_price", 1, "Trả tên của chính mình — giữ mặt mẹ")
	_check(state.name_kept == false, "second crossing choice did not surrender the name")
	_check(state.ending_key() == "costly_hope", "costly-hope ending eligibility is wrong")


func _test_round_trip() -> void:
	var original := NarrativeState.new()
	original.set_beat("c3_blank_tablet", 0.52)
	original.adjust_trust(35)
	original.add_evidence("blank_tablet", "the name cannot be inscribed")
	original.record_refusal()
	var restored := NarrativeState.new()
	_check(restored.load_dict(original.to_dict()), "valid narrative state did not load")
	_check(restored.current_beat == original.current_beat, "beat changed during save round-trip")
	_check(restored.trust_voice == original.trust_voice, "trust changed during save round-trip")
	_check(restored.verify_count == original.verify_count, "evidence changed during save round-trip")
	_check(restored.refusal_count == original.refusal_count, "refusal count changed during save round-trip")


func _test_invalid_load_is_atomic() -> void:
	var state := NarrativeState.new()
	state.set_beat("c2_first_displacement", 0.24)
	state.adjust_trust(20)
	var before := state.to_dict()
	var corrupt := before.duplicate(true)
	corrupt["current_beat"] = ""
	corrupt["name_kept"] = "invalid"
	_check(not state.load_dict(corrupt), "corrupt narrative state was accepted")
	_check(state.to_dict() == before, "failed load mutated the live narrative state")
