extends SceneTree

const PlayerCharacter := preload("res://scripts/player.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var player := PlayerCharacter.new()
	root.add_child(player)
	await process_frame

	var shadow_casters: Array[String] = []
	_collect_shadow_casters(player, shadow_casters)
	_check(shadow_casters.is_empty(), "player geometry casts shadows: %s" % ", ".join(shadow_casters))

	player.queue_free()
	if failures.is_empty():
		print("PLAYER SHADOW POLICY OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _collect_shadow_casters(node: Node, out: Array[String]) -> void:
	if node is GeometryInstance3D and node.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
		out.append(node.name)
	for child in node.get_children():
		_collect_shadow_casters(child, out)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
