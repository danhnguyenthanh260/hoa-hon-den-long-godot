class_name VoiceDirector
extends RefCounted

const DEFAULT_SPEAKER := "Trạm Bốn"

var narrative: NarrativeState


func _init(narrative_state: NarrativeState = null) -> void:
	narrative = narrative_state


func apply_intervention(
	beat_id: String,
	authored_pressure: float,
	trust_delta := 0,
	evidence_id := "",
	evidence_claim := "",
	refusal := false
) -> void:
	assert(narrative != null, "VoiceDirector requires a NarrativeState")
	narrative.set_beat(beat_id, authored_pressure)
	if trust_delta != 0:
		narrative.adjust_trust(trust_delta)
	if not evidence_id.is_empty():
		narrative.add_evidence(evidence_id, evidence_claim)
	if refusal:
		narrative.record_refusal()


func wrap_lines(lines: Array, speaker := DEFAULT_SPEAKER) -> Array:
	var wrapped: Array = []
	for line in lines:
		if line is String:
			wrapped.append([speaker, line])
		else:
			wrapped.append(line)
	return wrapped
