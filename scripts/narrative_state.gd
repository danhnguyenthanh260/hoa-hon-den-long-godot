class_name NarrativeState
extends RefCounted

const SAVE_VERSION := 1
const MIN_RELEASE_BOND := 2
const RELEASE_EVIDENCE_IDS := [
	"c5_water_refuses_body",
	"c5_blank_tablet_accepts_ash",
	"c5_lantern_is_anchor",
]

var current_beat := "intro_familiar_street"
var pressure := 0.0
var trust_voice := 0
var verify_count := 0
var bond_ba := 0
var bond_child := 0
var heard_boatman := false
var name_kept: Variant = null
var refusal_count := 0
var evidence: Dictionary = {}
var choices: Dictionary = {}
var contradictions: Dictionary = {}


func set_beat(beat_id: String, authored_pressure: float) -> void:
	assert(not beat_id.is_empty(), "Narrative beat IDs must be stable and non-empty")
	current_beat = beat_id
	pressure = clampf(authored_pressure, 0.0, 1.0)


func adjust_trust(amount: int) -> void:
	trust_voice = clampi(trust_voice + amount, 0, 100)


func add_evidence(evidence_id: String, claim: String = "") -> bool:
	if evidence_id.is_empty() or evidence.has(evidence_id):
		return false
	evidence[evidence_id] = {"claim": claim}
	verify_count = evidence.size()
	return true


func set_bond(person: String, value: int) -> void:
	match person:
		"ba":
			bond_ba = clampi(value, 0, 2)
		"child":
			bond_child = clampi(value, 0, 2)
		_:
			push_error("Unknown narrative bond: %s" % person)


func record_refusal() -> void:
	refusal_count += 1
	adjust_trust(-10)


func record_contradiction(contradiction_id: String, description: String) -> bool:
	if contradiction_id.is_empty() or contradictions.has(contradiction_id):
		return false
	contradictions[contradiction_id] = {"description": description}
	adjust_trust(-15)
	return true


func record_choice(choice_id: String, index: int, label: String) -> void:
	if choice_id.is_empty():
		return
	choices[choice_id] = {"index": index, "label": label}
	if choice_id == "c4_crossing_price":
		name_kept = index == 0
		heard_boatman = true


func has_release_evidence() -> bool:
	for evidence_id in RELEASE_EVIDENCE_IDS:
		if not evidence.has(evidence_id):
			return false
	return true


func ending_key() -> String:
	var enough_evidence := has_release_evidence()
	var enough_bond := bond_ba + bond_child >= MIN_RELEASE_BOND
	if enough_evidence and enough_bond:
		return "release"
	return "loop"


func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"current_beat": current_beat,
		"pressure": pressure,
		"trust_voice": trust_voice,
		"verify_count": verify_count,
		"bond_ba": bond_ba,
		"bond_child": bond_child,
		"heard_boatman": heard_boatman,
		"name_kept": name_kept,
		"refusal_count": refusal_count,
		"evidence": evidence.duplicate(true),
		"choices": choices.duplicate(true),
		"contradictions": contradictions.duplicate(true),
	}


func load_dict(data: Dictionary) -> bool:
	if int(data.get("version", -1)) != SAVE_VERSION:
		return false
	var previous := to_dict()
	_apply_dict_unchecked(data)
	var errors := validate()
	if not errors.is_empty():
		_apply_dict_unchecked(previous)
		return false
	return true


func _apply_dict_unchecked(data: Dictionary) -> void:
	current_beat = str(data.get("current_beat", current_beat))
	pressure = clampf(float(data.get("pressure", pressure)), 0.0, 1.0)
	trust_voice = clampi(int(data.get("trust_voice", trust_voice)), 0, 100)
	bond_ba = clampi(int(data.get("bond_ba", bond_ba)), 0, 2)
	bond_child = clampi(int(data.get("bond_child", bond_child)), 0, 2)
	heard_boatman = bool(data.get("heard_boatman", heard_boatman))
	name_kept = data.get("name_kept", name_kept)
	refusal_count = maxi(int(data.get("refusal_count", refusal_count)), 0)
	evidence = Dictionary(data.get("evidence", {})).duplicate(true)
	choices = Dictionary(data.get("choices", {})).duplicate(true)
	contradictions = Dictionary(data.get("contradictions", {})).duplicate(true)
	verify_count = evidence.size()


func validate() -> Array[String]:
	var errors: Array[String] = []
	if current_beat.is_empty():
		errors.append("current_beat is empty")
	if pressure < 0.0 or pressure > 1.0:
		errors.append("pressure is outside 0..1")
	if trust_voice < 0 or trust_voice > 100:
		errors.append("trust_voice is outside 0..100")
	if verify_count != evidence.size():
		errors.append("verify_count does not match unique evidence")
	if name_kept != null and not name_kept is bool:
		errors.append("name_kept is not null or boolean")
	return errors
