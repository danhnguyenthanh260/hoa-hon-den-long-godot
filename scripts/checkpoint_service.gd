class_name CheckpointService
extends RefCounted

const SAVE_VERSION := 1
const DEFAULT_PATH := "user://checkpoint-v1.json"


func save_checkpoint(
	narrative: NarrativeState,
	chapter_no: int,
	player_position: Vector3,
	path: String = DEFAULT_PATH
) -> bool:
	var payload := {
		"version": SAVE_VERSION,
		"chapter_no": chapter_no,
		"player_position": [player_position.x, player_position.y, player_position.z],
		"narrative": narrative.to_dict(),
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write checkpoint: %s" % path)
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true


func load_checkpoint(path: String = DEFAULT_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or int(parsed.get("version", -1)) != SAVE_VERSION:
		return {}
	var position = parsed.get("player_position", [])
	if not position is Array or position.size() != 3:
		return {}
	return parsed


func apply_checkpoint(payload: Dictionary, narrative: NarrativeState) -> Dictionary:
	if payload.is_empty() or not narrative.load_dict(Dictionary(payload.get("narrative", {}))):
		return {}
	var position: Array = payload["player_position"]
	return {
		"chapter_no": clampi(int(payload.get("chapter_no", 1)), 1, 5),
		"player_position": Vector3(float(position[0]), float(position[1]), float(position[2])),
	}


func clear_checkpoint(path: String = DEFAULT_PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
