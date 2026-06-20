extends SceneTree

const NarrativeState := preload("res://scripts/narrative_state.gd")
const VoiceDirector := preload("res://scripts/voice_director.gd")

var failures: Array[String] = []


func _init() -> void:
	_test_intervention_updates_state()
	_test_line_wrapping_preserves_authored_pairs()
	if failures.is_empty():
		print("VOICE DIRECTOR OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_intervention_updates_state() -> void:
	var narrative := NarrativeState.new()
	var voice := VoiceDirector.new(narrative)
	voice.apply_intervention(
		"c2_well_contradiction",
		0.36,
		12,
		"well_reflection",
		"well reflection lags behind the player"
	)
	_check(narrative.current_beat == "c2_well_contradiction", "voice beat was not recorded")
	_check(is_equal_approx(narrative.pressure, 0.36), "voice pressure was not recorded")
	_check(narrative.trust_voice == 12, "voice trust delta was not applied")
	_check(narrative.verify_count == 1, "voice evidence was not recorded")

	voice.apply_intervention("c2_refuse_bad_order", 0.42, 0, "", "", true)
	_check(narrative.refusal_count == 1, "voice refusal was not recorded")
	_check(narrative.trust_voice == 2, "refusal did not reduce trust")


func _test_line_wrapping_preserves_authored_pairs() -> void:
	var narrative := NarrativeState.new()
	var voice := VoiceDirector.new(narrative)
	var wrapped := voice.wrap_lines([
		"Nghe được không?",
		["Minh (nghĩ)", "Giọng này không thuộc về phố."],
	])
	_check(wrapped[0][0] == VoiceDirector.DEFAULT_SPEAKER, "plain voice line was not wrapped")
	_check(wrapped[0][1] == "Nghe được không?", "plain voice text changed")
	_check(wrapped[1][0] == "Minh (nghĩ)", "authored speaker pair was overwritten")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
