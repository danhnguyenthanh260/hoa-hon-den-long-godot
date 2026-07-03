# QA + GEN cho THÂN LẮP RÁP (Player procedural, không phải AI mesh).
#  -- side/front/back : chụp chu kỳ đi bộ 16 khung nhìn nghiêng/trước/sau.
#  -- apose           : chụp 4 view A-pose (tay dang) nền sáng -> shots/chara/apose_*
#                       để đưa vào gen3d.py sinh mesh AI CÓ KHE tay-thân.
extends Node3D

const PlayerScript := preload("res://scripts/player.gd")
var _player: Node3D
var _env: Environment


func _ready() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.16, 0.16, 0.19)
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.55, 0.55, 0.6)
	_env.ambient_light_energy = 0.6
	_env.tonemap_mode = Environment.TONE_MAPPER_ACES
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-50), deg_to_rad(35), 0)
	key.light_energy = 1.5
	add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-2.5, 2.0, 3.0)
	fill.light_energy = 1.0
	fill.omni_range = 14.0
	add_child(fill)

	var cam := Camera3D.new()
	add_child(cam)

	_player = Node3D.new()
	_player.set_script(PlayerScript)
	add_child(_player)

	var ua := OS.get_cmdline_user_args()
	await get_tree().process_frame
	if "apose" in ua:
		cam.fov = 45.0
		cam.position = Vector3(0, 0.92, 3.0)
		cam.look_at(Vector3(0, 0.92, 0))
		await _capture_apose()
	else:
		cam.position = Vector3(0, 1.0, 3.4)
		cam.look_at(Vector3(0, 0.9, 0))
		_player.force_walk = true
		await _capture_walk(ua)
	get_tree().quit()


# 4 view A-pose nền sáng cho gen3d (rembg tách áo tối tốt hơn trên nền sáng)
func _capture_apose() -> void:
	_env.background_color = Color(0.62, 0.64, 0.66)
	_env.ambient_light_energy = 1.0
	_player.set_process(false)              # tắt animation, giữ pose tĩnh
	_player.set_apose()
	var dir := ProjectSettings.globalize_path("res://shots/chara")
	DirAccess.make_dir_recursive_absolute(dir)
	var views := {"front": 0.0, "left": -PI * 0.5, "back": PI, "right": PI * 0.5}
	for name in views:
		_player._visual.rotation.y = views[name]
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png(dir + "/apose_%s.png" % name)
	print("CHUP A-POSE 4 VIEW XONG -> ", dir, " (apose_front/left/back/right.png)")


func _capture_walk(ua: PackedStringArray) -> void:
	var yaw := -PI * 0.5
	var tag := "side"
	if "front" in ua:
		yaw = PI; tag = "front"
	elif "back" in ua:
		yaw = 0.0; tag = "back"
	var dir := ProjectSettings.globalize_path("res://shots/qa/playercap_" + tag)
	DirAccess.make_dir_recursive_absolute(dir)
	var d := DirAccess.open(dir)
	if d:
		for f in d.get_files():
			if f.ends_with(".png"):
				d.remove(f)
	_player._gait = 1.0
	_player._visual.rotation.y = yaw
	_player._target_yaw = yaw
	for i in range(16):
		_player._anim_t = TAU * float(i) / 16.0
		_player._process(0.0)
		_player._visual.rotation.y = yaw
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png(dir + "/walk-%02d.png" % i)
	print("CHUP PLAYER (", tag, ") XONG -> ", dir)
