extends Node3D

const Build := preload("res://scripts/build.gd")
const Shapes := preload("res://scripts/shapes.gd")

const PARTS := ["head", "wing_body", "tail_leg"]
const PART_NAMES := {
	"head": "đầu chim",
	"wing_body": "thân / cánh",
	"tail_leg": "đuôi / chân",
}
const TOLERANCE := 0.08

var active := false
var solved := false
var solved_callback: Callable
var light_pos := Vector3.ZERO
var wall_z := 0.0
var selected_part_index := 0
var collected_parts := {}
var placed_parts := {}
var part_angles := {
	"head": 0.65,
	"wing_body": -0.55,
	"tail_leg": 0.78,
}

var _part_nodes := {}
var _feedback: Label3D
var _fly_t := -1.0
var _bird_group: Node3D


func setup(p_light_pos: Vector3, p_wall_z: float) -> void:
	light_pos = p_light_pos
	wall_z = p_wall_z
	position = Vector3.ZERO

	var wall_mat := Build.mat(Color(0.16, 0.12, 0.08), 0.95)
	Build.box(self, Vector3(4.6, 2.8, 0.08), Vector3(light_pos.x, 1.55, wall_z), wall_mat)

	var target_mat := StandardMaterial3D.new()
	target_mat.albedo_color = Color(1.0, 0.78, 0.30, 0.22)
	target_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	target_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var target := Shapes.make_mesh(Shapes.bird_polygon())
	var target_mi := MeshInstance3D.new()
	target_mi.mesh = target
	target_mi.material_override = target_mat
	target_mi.position = Vector3(light_pos.x, 1.55, wall_z - 0.055)
	target_mi.scale = Vector3(1.55, 1.55, 1.55)
	target_mi.rotation_degrees = Vector3(0, 180, 0)
	add_child(target_mi)

	_bird_group = Node3D.new()
	add_child(_bird_group)
	_make_part("head", _head_poly(), Color(0.95, 0.50, 0.20), Vector3(light_pos.x - 0.95, 1.78, wall_z - 0.11))
	_make_part("wing_body", _wing_poly(), Color(0.95, 0.76, 0.24), Vector3(light_pos.x - 0.05, 1.48, wall_z - 0.12))
	_make_part("tail_leg", _tail_poly(), Color(0.78, 0.42, 0.18), Vector3(light_pos.x + 0.72, 1.24, wall_z - 0.13))

	var lantern := Build.lantern(self, 0.18, 0.34, light_pos)
	Build.light_lantern(lantern, Color(1.0, 0.48, 0.16), 2.3)
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.55, 0.18)
	lamp.light_energy = 2.0
	lamp.omni_range = 7.0
	lamp.position = light_pos
	add_child(lamp)

	_feedback = Label3D.new()
	_feedback.text = "Thiếu ba mảnh giấy dó."
	_feedback.modulate = Color(1.0, 0.76, 0.34)
	_feedback.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_feedback.position = Vector3(light_pos.x, 2.95, wall_z - 0.2)
	add_child(_feedback)
	_refresh_visuals()


func _make_part(id: String, poly: Array, color: Color, pos: Vector3) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.58)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mi := MeshInstance3D.new()
	mi.mesh = Shapes.make_mesh(poly)
	mi.material_override = mat
	mi.position = pos
	mi.scale = Vector3(1.35, 1.35, 1.35)
	mi.rotation_degrees = Vector3(0, 180, 0)
	_bird_group.add_child(mi)
	_part_nodes[id] = mi


func _head_poly() -> Array:
	return [
		Vector2(-0.55, 0.12), Vector2(-0.10, 0.34), Vector2(0.20, 0.22),
		Vector2(0.32, 0.08), Vector2(0.05, -0.08), Vector2(-0.38, -0.03),
	]


func _wing_poly() -> Array:
	return [
		Vector2(-0.72, 0.18), Vector2(0.16, 0.48), Vector2(0.86, 0.10),
		Vector2(0.35, -0.16), Vector2(-0.12, -0.40), Vector2(-0.62, -0.18),
	]


func _tail_poly() -> Array:
	return [
		Vector2(-0.32, 0.16), Vector2(0.54, 0.32), Vector2(0.22, 0.03),
		Vector2(0.62, -0.28), Vector2(-0.10, -0.14), Vector2(-0.40, -0.42),
	]


func stand_pos() -> Vector3:
	return Vector3(light_pos.x, 0, light_pos.z)


func required_part_count() -> int:
	return PARTS.size()


func collect_part(id: String) -> void:
	if not PARTS.has(id):
		return
	collected_parts[id] = true
	_refresh_visuals()


func place_part(id: String) -> void:
	if not collected_parts.has(id):
		return
	placed_parts[id] = true
	_refresh_visuals()


func collect_and_place_part(id: String) -> void:
	collect_part(id)
	place_part(id)


func has_all_parts() -> bool:
	for id in PARTS:
		if not placed_parts.has(id):
			return false
	return true


func set_part_angle(id: String, angle: float) -> void:
	if not part_angles.has(id):
		return
	part_angles[id] = angle
	_refresh_visuals()


func is_part_aligned(id: String) -> bool:
	if not placed_parts.has(id):
		return false
	return absf(float(part_angles[id])) <= TOLERANCE


func all_layers_aligned() -> bool:
	for id in PARTS:
		if not is_part_aligned(id):
			return false
	return true


func complete_if_ready() -> bool:
	if solved:
		return true
	if has_all_parts() and all_layers_aligned():
		solved = true
		active = false
		_fly_t = 0.0
		_feedback.text = "Chim Lạc đã đậu vào đúng bóng. Ấn Hỏa mở dưới nền nhà."
		if solved_callback.is_valid():
			solved_callback.call()
		return true
	return false


func debug_solve() -> void:
	for id in PARTS:
		collect_and_place_part(id)
		set_part_angle(id, 0.0)
	complete_if_ready()


func update_puzzle(delta: float) -> void:
	if solved:
		_update_flight(delta)
		return
	if not active:
		return
	if Input.is_key_pressed(KEY_1):
		selected_part_index = 0
	if Input.is_key_pressed(KEY_2):
		selected_part_index = 1
	if Input.is_key_pressed(KEY_3):
		selected_part_index = 2
	var id: String = PARTS[selected_part_index]
	if placed_parts.has(id):
		var dir := 0.0
		if Input.is_key_pressed(KEY_A):
			dir -= 1.0
		if Input.is_key_pressed(KEY_D):
			dir += 1.0
		if dir != 0.0:
			part_angles[id] = float(part_angles[id]) + dir * delta * 0.75
	_refresh_visuals()
	complete_if_ready()


func _process(delta: float) -> void:
	_update_flight(delta)


func _update_flight(delta: float) -> void:
	if _fly_t < 0.0 or _bird_group == null:
		return
	_fly_t += delta
	_bird_group.position.y = sin(_fly_t * 5.0) * 0.08
	_bird_group.position.z = -min(_fly_t, 1.0) * 0.18


func _refresh_visuals() -> void:
	if _part_nodes.is_empty():
		return
	var placed := 0
	var aligned := 0
	for id in PARTS:
		var mi: MeshInstance3D = _part_nodes[id]
		mi.visible = placed_parts.has(id)
		mi.rotation_degrees = Vector3(0, 180 + rad_to_deg(float(part_angles[id])), 0)
		if placed_parts.has(id):
			placed += 1
			if is_part_aligned(id):
				aligned += 1
	if _feedback == null:
		return
	if solved:
		_feedback.text = "Chim Lạc đã bay. Ấn dưới hầm vừa nứt."
	elif placed < PARTS.size():
		_feedback.text = "Đã đặt %d / %d mảnh giấy dó vào khung đèn." % [placed, PARTS.size()]
	elif aligned < PARTS.size():
		var id: String = PARTS[selected_part_index]
		_feedback.text = "Lớp %d: %s. Gần đúng: %s. Đúng lớp: %d / %d." % [
			selected_part_index + 1,
			PART_NAMES[id],
			"có" if is_part_aligned(id) else "chưa",
			aligned,
			PARTS.size(),
		]
