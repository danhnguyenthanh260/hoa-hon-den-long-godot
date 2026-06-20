# QA-ONLY (không phải code nâng cấp): render turntable 360° + chu kỳ đi bộ của
# minh_player_rigged.glb ra shots/qa/ để đánh giá rig/anatomy/màu/dáng đi.
# Chạy (CÓ render, KHÔNG --headless):
#   tools\Godot_v4.5-stable_win64.exe --path . res://scenes/turntable.tscn
# Ảnh lưu: shots/qa/turntable-00..23.png  và  shots/qa/walk-00..15.png
extends Node3D

const MODEL := "res://assets/models/minh_player_rigged.glb"
const ARM_REST_DROP := 0.95
const TURN_FRAMES := 24
const WALK_FRAMES := 16
const TARGET_H := 1.72

var _skel: Skeleton3D
var _bone := {}
var _bone_rest := {}
var _model: Node3D
var _cam: Camera3D


func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.16, 0.19)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.55, 0.6)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-50), deg_to_rad(35), 0)
	key.light_energy = 1.5
	add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-2.5, 2.0, 3.0)
	fill.light_energy = 1.2
	fill.omni_range = 14.0
	add_child(fill)

	_cam = Camera3D.new()
	_cam.position = Vector3(0, TARGET_H * 0.62, 3.2)
	_cam.look_at(Vector3(0, TARGET_H * 0.55, 0))
	add_child(_cam)

	var packed := load(MODEL) as PackedScene
	_model = packed.instantiate()
	add_child(_model)
	_skel = _model.find_children("*", "Skeleton3D", true, false)[0]

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(0.9, 0.85, 0.8)
	mat.roughness = 0.7
	var min_y := 1e9
	var max_y := -1e9
	for mi in _model.find_children("*", "MeshInstance3D", true, false):
		mi.material_override = mat
		var ab: AABB = mi.get_aabb()
		min_y = minf(min_y, ab.position.y)
		max_y = maxf(max_y, ab.position.y + ab.size.y)
	var s := TARGET_H / maxf(max_y - min_y, 0.01)
	_model.scale = Vector3(s, s, s)
	_model.position.y = -min_y * s

	for n in ["thighL", "shinL", "thighR", "shinR", "spine", "head",
			"upperarmL", "forearmL", "upperarmR", "forearmR"]:
		_bone[n] = _skel.find_bone(n)
	_set_rest("upperarmL", Quaternion(Vector3.FORWARD, ARM_REST_DROP))
	_set_rest("upperarmR", Quaternion(Vector3.FORWARD, -ARM_REST_DROP))
	_run()


func _set_rest(n: String, q: Quaternion) -> void:
	var b: int = _bone.get(n, -1)
	if b < 0:
		return
	var base := _skel.get_bone_rest(b).basis.get_rotation_quaternion()
	_bone_rest[b] = base * q
	_skel.set_bone_pose_rotation(b, base * q)


func _pose(n: String, q: Quaternion) -> void:
	var b: int = _bone.get(n, -1)
	if b < 0:
		return
	var rest: Quaternion = _bone_rest.get(b, _skel.get_bone_rest(b).basis.get_rotation_quaternion())
	_skel.set_bone_pose_rotation(b, rest * q)


func _run() -> void:
	var dir := ProjectSettings.globalize_path("res://shots/qa")
	DirAccess.make_dir_recursive_absolute(dir)
	await RenderingServer.frame_post_draw
	# turntable 360
	for i in range(TURN_FRAMES):
		_model.rotation.y = TAU * float(i) / TURN_FRAMES
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		_shot(dir + "/turntable-%02d.png" % i)
	# chu kỳ đi bộ (góc 3/4 sau lưng)
	_model.rotation.y = PI + 0.5
	for i in range(WALK_FRAMES):
		var t := TAU * float(i) / WALK_FRAMES
		var sw := sin(t) * 0.55
		_pose("thighL", Quaternion(Vector3.RIGHT, sw))
		_pose("thighR", Quaternion(Vector3.RIGHT, -sw))
		_pose("shinL", Quaternion(Vector3.RIGHT, -maxf(0.0, sin(t - 0.7)) * 0.9))
		_pose("shinR", Quaternion(Vector3.RIGHT, -maxf(0.0, sin(t - 0.7 + PI)) * 0.9))
		_pose("spine", Quaternion(Vector3.UP, sin(t) * 0.04))
		_pose("upperarmL", Quaternion(Vector3.RIGHT, -sw * 0.7))
		_pose("upperarmR", Quaternion(Vector3.RIGHT, sw * 0.7))
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		_shot(dir + "/walk-%02d.png" % i)
	print("QA SHOTS DONE -> ", dir)
	get_tree().quit()


func _shot(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
