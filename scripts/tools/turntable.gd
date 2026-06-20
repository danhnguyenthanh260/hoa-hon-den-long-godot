# QA viewer (tương tác) cho minh_player_rigged.glb — xoay 360 + đi bộ, chỉnh tốc độ.
# Chạy (CÓ render): tools\Godot_v4.5-stable_win64.exe --path . res://scenes/turntable.tscn
# Phím:  ◄ ►  xoay tay   ·  ▲ ▼  tốc độ xoay   ·  Space  dừng/chạy xoay
#        W  bật/tắt đi bộ ·  [ ]  tốc độ đi bộ  ·  S  chụp ảnh  ·  Esc  thoát
extends Node3D

const MODEL := "res://assets/models/minh_player_rigged.glb"
const TARGET_H := 1.72

var _skel: Skeleton3D
var _bone := {}
var _bone_rest := {}
var _model: Node3D
var _lbl: Label
var _yaw := 0.0
var _spin := 0.5          # rad/s
var _spinning := true
var _walking := true
var _walk_speed := 1.0
var _walk_t := 0.0
var _snap := 0
var _capturing := false
var _lantern: Node3D
var _hand_bone := -1


func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.16, 0.19)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.55, 0.6)
	env.ambient_light_energy = 0.6
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

	var cam := Camera3D.new()
	cam.position = Vector3(0, TARGET_H * 0.6, 3.3)
	cam.look_at(Vector3(0, TARGET_H * 0.52, 0))
	add_child(cam)

	_model = (load(MODEL) as PackedScene).instantiate()
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

	for n in ["thighL", "shinL", "footL", "thighR", "shinR", "footR", "spine", "head",
			"upperarmL", "forearmL", "handL", "upperarmR", "forearmR", "handR"]:
		_bone[n] = _skel.find_bone(n)
	# tay-buông: không hạ tay; co nhẹ khuỷu phải đưa đèn ra trước
	var fr: int = _bone.get("forearmR", -1)
	if fr >= 0:
		var rr := _skel.get_bone_rest(fr).basis.get_rotation_quaternion()
		_skel.set_bone_pose_rotation(fr, rr * Quaternion(Vector3.RIGHT, -0.5))
	# đèn lồng (vật phẩm riêng) cầm tay phải
	_hand_bone = _bone.get("handR", -1)
	_lantern = preload("res://scripts/lantern.gd").new()
	add_child(_lantern)

	var cl := CanvasLayer.new()
	add_child(cl)
	_lbl = Label.new()
	_lbl.position = Vector2(16, 12)
	_lbl.add_theme_color_override("font_color", Color(1, 0.86, 0.5))
	cl.add_child(_lbl)

	# tự chụp rồi thoát: "-- cap360" (xoay vòng) hoặc "-- walkcap" (chu kỳ đi bộ)
	var ua := OS.get_cmdline_user_args()
	if "cap360" in ua:
		await get_tree().process_frame
		await _capture_360()
		get_tree().quit()
	elif "walkcap" in ua:
		await get_tree().process_frame
		await _capture_walk()
		get_tree().quit()


func _drop_arm(up_name: String, hand_name: String) -> void:
	var bu: int = _bone.get(up_name, -1)
	var bh: int = _bone.get(hand_name, -1)
	if bu < 0 or bh < 0:
		return
	var sh := _skel.get_bone_global_rest(bu).origin
	var wr := _skel.get_bone_global_rest(bh).origin
	var dir := (wr - sh).normalized()
	var axis := dir.cross(Vector3.DOWN)
	var q := Quaternion.IDENTITY
	if axis.length() > 0.001:
		q = Quaternion(axis.normalized(), dir.angle_to(Vector3.DOWN))
	_bone_rest[bu] = q
	_skel.set_bone_pose_rotation(bu, q)


func _pose(n: String, q: Quaternion) -> void:
	var b: int = _bone.get(n, -1)
	if b < 0:
		return
	var rest: Quaternion = _bone_rest.get(b, Quaternion.IDENTITY)
	_skel.set_bone_pose_rotation(b, rest * q)


func _walk_pose(p: float) -> void:
	var legL := sin(p)
	var legR := sin(p + PI)
	_pose("thighL", Quaternion(Vector3.RIGHT, legL * 0.22))
	_pose("thighR", Quaternion(Vector3.RIGHT, legR * 0.22))
	var liftL := clampf(sin(p + 1.4), 0.0, 1.0)
	var liftR := clampf(sin(p + PI + 1.4), 0.0, 1.0)
	_pose("shinL", Quaternion(Vector3.RIGHT, -liftL * 0.55))
	_pose("shinR", Quaternion(Vector3.RIGHT, -liftR * 0.55))
	_pose("footL", Quaternion(Vector3.RIGHT, liftL * 0.25))
	_pose("footR", Quaternion(Vector3.RIGHT, liftR * 0.25))
	_pose("spine", Quaternion(Vector3.UP, legL * 0.03))
	_pose("upperarmL", Quaternion(Vector3.RIGHT, -legL * 0.35))
	# tay phải giữ đèn — không vung


# Chụp chu kỳ đi bộ nhìn NGHIÊNG (profile) — 16 khung qua 1 nhịp, để soi
# chân bước tới/lui + thân-chân có khớp hướng không.
func _capture_walk() -> void:
	_capturing = true
	var dir := ProjectSettings.globalize_path("res://shots/qa/walkcap")
	DirAccess.make_dir_recursive_absolute(dir)
	var d := DirAccess.open(dir)
	if d:
		for f in d.get_files():
			if f.ends_with(".png"):
				d.remove(f)
	_model.rotation.y = PI * 0.5     # nhìn nghiêng: thấy rõ chân vung tới/lui
	for i in range(16):
		var p := TAU * float(i) / 16.0
		_walk_pose(p)
		if _lantern and _hand_bone >= 0:
			var hw := _skel.global_transform * _skel.get_bone_global_pose(_hand_bone)
			_lantern.global_position = hw.origin
			_lantern.rotation.y = _model.rotation.y
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png(dir + "/walk-%02d.png" % i)
	print("CHUP DI BO XONG -> ", dir, " (walk-00..15.png, nhin nghieng)")
	_capturing = false


func _capture_360() -> void:
	_capturing = true
	# folder debug riêng, dọn ảnh cũ trước
	var dir := ProjectSettings.globalize_path("res://shots/qa/debug360")
	DirAccess.make_dir_recursive_absolute(dir)
	var d := DirAccess.open(dir)
	if d:
		for f in d.get_files():
			if f.ends_with(".png"):
				d.remove(f)
	# tư thế đứng yên cho turntable sạch (dễ soi rig/skin)
	for n in ["thighL", "thighR", "shinL", "shinR"]:
		_pose(n, Quaternion.IDENTITY)
	for i in range(24):
		_model.rotation.y = TAU * float(i) / 24.0
		if _lantern and _hand_bone >= 0:
			var hw := _skel.global_transform * _skel.get_bone_global_pose(_hand_bone)
			_lantern.global_position = hw.origin
			_lantern.rotation.y = _model.rotation.y
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png(dir + "/turntable-%02d.png" % i)
	print("CHUP 360 XONG -> ", dir, " (turntable-00..23.png)")
	_capturing = false


func _process(delta: float) -> void:
	if _capturing:
		return
	if _spinning:
		_yaw += _spin * delta
	_model.rotation.y = _yaw
	# đèn lồng bám bàn tay phải + xoay theo thân
	if _lantern and _hand_bone >= 0:
		var hw := _skel.global_transform * _skel.get_bone_global_pose(_hand_bone)
		_lantern.global_position = hw.origin
		_lantern.rotation.y = _yaw
	if _walking:
		_walk_t += delta * 7.0 * _walk_speed
		_walk_pose(_walk_t)
	_lbl.text = "GÓC NHÌN QA — Minh\nxoay: %s (%.1f rad/s)   đi bộ: %s (x%.1f)\n◄►: xoay tay  ▲▼: tốc độ xoay  Space: dừng xoay\nW: đi bộ  [ ]: tốc độ đi  C: CHỤP 360°  S: chụp 1  Esc: thoát" % [
		"CHẠY" if _spinning else "DỪNG", _spin,
		"BẬT" if _walking else "TẮT", _walk_speed]


func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed):
		return
	match e.keycode:
		KEY_SPACE:
			_spinning = not _spinning
		KEY_LEFT:
			_yaw -= 0.12
		KEY_RIGHT:
			_yaw += 0.12
		KEY_UP:
			_spin = minf(_spin + 0.15, 4.0)
		KEY_DOWN:
			_spin = maxf(_spin - 0.15, 0.0)
		KEY_W:
			_walking = not _walking
		KEY_BRACKETLEFT:
			_walk_speed = maxf(_walk_speed - 0.25, 0.0)
		KEY_BRACKETRIGHT:
			_walk_speed = minf(_walk_speed + 0.25, 4.0)
		KEY_S:
			var p := ProjectSettings.globalize_path("res://shots/qa")
			DirAccess.make_dir_recursive_absolute(p)
			var img := get_viewport().get_texture().get_image()
			img.save_png(p + "/snap-%02d.png" % _snap)
			_snap += 1
		KEY_C:
			if not _capturing:
				_capture_360()
		KEY_ESCAPE:
			get_tree().quit()
