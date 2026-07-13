# Mở đầu ngắn trước C1: ký ức lũ vỡ từng mảnh, không tiết lộ nhiệm vụ.
extends Node3D

const Build := preload("res://scripts/build.gd")

signal finished

const DURATION := 26.0

var m
var _playing := false
var _time := 0.0
var _lantern_root: Node3D
var _warm_light: OmniLight3D
var _rain: Array = []
var _last_caption := -1


func setup(main) -> void:
	m = main
	position = Vector3(0, 0, 72)
	visible = false
	var water := Build.mat(Color(0.012, 0.02, 0.055), 0.18)
	water.metallic = 0.75
	Build.box(self, Vector3(20.0, 0.10, 16.0), Vector3(0, 0, 0), water)
	var far := Build.mat(Color(0.018, 0.022, 0.055), 0.95)
	for i in range(9):
		var x := -8.0 + i * 2.0
		var h := 1.4 + float((i * 3) % 4) * 0.55
		Build.box(self, Vector3(1.65, h, 0.45), Vector3(x, h * 0.5, -7.2), far)
	var moon := Build.ball(self, 1.05, 2.1, Vector3(4.5, 5.3, -6.4), Build.emis(Color(0.65, 0.78, 1.0), Color(0.45, 0.62, 1.0), 0.8))
	moon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var boat := Node3D.new()
	boat.position = Vector3(-1.2, 0.18, -0.45)
	add_child(boat)
	var boat_wood := Build.mat(Color(0.16, 0.095, 0.055), 0.8)
	Build.box(boat, Vector3(4.5, 0.24, 1.18), Vector3.ZERO, boat_wood)
	Build.box(boat, Vector3(4.9, 0.12, 0.18), Vector3(0, 0.26, -0.54), boat_wood)
	Build.box(boat, Vector3(4.9, 0.12, 0.18), Vector3(0, 0.26, 0.54), boat_wood)
	var adult := Build.faceless_npc(boat, Vector3(-0.85, 0.12, 0.05), Color(0.09, 0.075, 0.07), 0.75, false)
	adult.rotation.y = 0.5
	var child := Build.faceless_npc(boat, Vector3(0.72, 0.12, 0.18), Color(0.36, 0.33, 0.30), 0.48, false)
	child.rotation.y = -0.4
	_lantern_root = Node3D.new()
	_lantern_root.position = Vector3(-0.05, 1.24, 0.30)
	boat.add_child(_lantern_root)
	var lantern := Build.lantern(_lantern_root, 0.18, 0.32, Vector3.ZERO)
	Build.light_lantern(lantern, Color(1.0, 0.34, 0.10), 3.2)
	_warm_light = OmniLight3D.new()
	_warm_light.light_color = Color(1.0, 0.32, 0.10)
	_warm_light.light_energy = 1.8
	_warm_light.omni_range = 7.0
	_lantern_root.add_child(_warm_light)
	var rain_mat := StandardMaterial3D.new()
	rain_mat.albedo_color = Color(0.46, 0.68, 1.0, 0.20)
	rain_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rain_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(34):
		var x := fmod(float(i) * 1.37, 13.0) - 6.5
		var z := fmod(float(i) * 2.11, 12.0) - 6.0
		var drop := Build.box(self, Vector3(0.018, 0.72, 0.018), Vector3(x, 1.2 + float(i % 6) * 0.52, z), rain_mat)
		drop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_rain.append([drop, float(i) * 0.23])


func play() -> void:
	_time = 0.0
	_last_caption = -1
	_playing = true
	visible = true
	m.camera.fov = 54.0
	m.ui.show_cinematic_caption("Mười năm trước.")
	m.ui.show_skip_hint(true)


func skip() -> void:
	_finish()


func _process(delta: float) -> void:
	if not _playing:
		return
	_time += delta
	_update_caption()
	_update_camera()
	_lantern_root.position.y = 1.24 + sin(_time * 3.0) * 0.04
	_warm_light.light_energy = 1.45 + sin(_time * 5.0) * 0.22
	for pair in _rain:
		var drop: MeshInstance3D = pair[0]
		drop.position.y -= delta * (2.6 + fmod(pair[1], 0.8))
		if drop.position.y < -0.3:
			drop.position.y = 4.6
	if _time >= DURATION:
		_finish()


func _update_caption() -> void:
	var stage := 0
	var text := "Mười năm trước."
	if _time >= 5.5 and _time < 12.0:
		stage = 1
		text = "Nước lên nhanh hơn tiếng gọi."
	elif _time >= 12.0 and _time < 19.0:
		stage = 2
		text = "Một ngọn đèn vẫn chưa chịu tắt."
	elif _time >= 19.0:
		stage = 3
		text = "Có người quay lại giữa dòng."
	if stage != _last_caption:
		_last_caption = stage
		m.ui.show_cinematic_caption(text)


func _update_camera() -> void:
	var p := Vector3(3.5, 2.35, 5.6)
	var look := Vector3(-0.55, 1.0, -0.5)
	if _time > 12.0:
		p = Vector3(1.8, 1.75, 3.6)
		look = Vector3(-0.1, 0.9, -0.2)
	if _time > 19.0:
		p = Vector3(-0.6, 1.45, 2.6)
		look = Vector3(-0.45, 0.85, -0.2)
	m.camera.global_position = to_global(p)
	m.camera.look_at(to_global(look))


func _finish() -> void:
	if not _playing:
		return
	_playing = false
	visible = false
	m.camera.fov = 60.0
	finished.emit()
