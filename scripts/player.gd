# Minh — áo dài, nón lá, sào tre gánh đèn. Đèn đổi được màu Ngũ Hành (phím 1-5).
extends Node3D

const Build := preload("res://scripts/build.gd")

const SPEED := 4.0

const COLOR_DEFS := {
	"hoa": {"name": "Hỏa", "color": Color(1.0, 0.3, 0.1), "key": KEY_1},
	"thuy": {"name": "Thủy", "color": Color(0.25, 0.55, 1.0), "key": KEY_2},
	"moc": {"name": "Mộc", "color": Color(0.3, 1.0, 0.38), "key": KEY_3},
	"kim": {"name": "Kim", "color": Color(1.0, 0.96, 0.82), "key": KEY_4},
	"tho": {"name": "Thổ", "color": Color(1.0, 0.78, 0.2), "key": KEY_5},
}
const COLOR_ORDER := ["hoa", "thuy", "moc", "kim", "tho"]

var unlocked: Array = []           # id các Sắc đã nhận
var current_color := ""            # "" = lửa thường (cam ấm)
var move_dir := Vector3.ZERO       # hướng di chuyển frame này (cho cơ chế đi lùi)
var facing_yaw := PI

var _visual: Node3D
var _hang: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _paper_mat: StandardMaterial3D
var _light: OmniLight3D
var _target_yaw := PI
var _anim_t := 0.0
var _moving := false


func _ready() -> void:
	_visual = Node3D.new()
	_visual.rotation.y = _target_yaw
	add_child(_visual)

	var robe := CylinderMesh.new()
	robe.top_radius = 0.17
	robe.bottom_radius = 0.33
	robe.height = 1.0
	robe.radial_segments = 14
	var robe_mi := MeshInstance3D.new()
	robe_mi.mesh = robe
	robe_mi.material_override = Build.mat(Color(0.13, 0.2, 0.42), 0.8)
	robe_mi.position.y = 0.5
	_visual.add_child(robe_mi)

	Build.ball(_visual, 0.19, 0.62, Vector3(0, 1.18, 0), Build.mat(Color(0.16, 0.24, 0.48), 0.8))
	Build.ball(_visual, 0.125, 0.25, Vector3(0, 1.52, 0), Build.mat(Color(0.87, 0.7, 0.55), 0.75))
	Build.cyl(_visual, 0.015, 0.42, 0.2, Vector3(0, 1.66, 0), Build.mat(Color(0.76, 0.62, 0.38), 0.95), 18)

	# tay đánh nhịp khi bước
	_arm_l = _make_arm(-1.0)
	_arm_r = _make_arm(1.0)

	var pole_holder := Node3D.new()
	pole_holder.position = Vector3(0.18, 1.32, 0.1)
	pole_holder.rotation.x = -0.38
	pole_holder.rotation.y = 0.55
	_visual.add_child(pole_holder)

	var pole := CylinderMesh.new()
	pole.top_radius = 0.018
	pole.bottom_radius = 0.022
	pole.height = 1.5
	var pole_mi := MeshInstance3D.new()
	pole_mi.mesh = pole
	pole_mi.material_override = Build.mat(Color(0.55, 0.45, 0.22), 0.9)
	pole_mi.rotation.x = PI / 2.0
	pole_mi.position.z = 0.45
	pole_holder.add_child(pole_mi)

	_hang = Node3D.new()
	_hang.position = Vector3(0, 0, 1.18)
	pole_holder.add_child(_hang)

	Build.cyl(_hang, 0.008, 0.008, 0.36, Vector3(0, -0.18, 0), Build.mat(Color(0.3, 0.1, 0.08)))
	_paper_mat = Build.emis(Color(1.0, 0.45, 0.25), Color(1.0, 0.42, 0.15), 2.8, 0.5)
	Build.ball(_hang, 0.16, 0.26, Vector3(0, -0.5, 0), _paper_mat)
	for dy in [-0.37, -0.63]:
		Build.cyl(_hang, 0.06, 0.06, 0.03, Vector3(0, dy, 0), Build.mat(Color(0.1, 0.07, 0.05)))
	Build.cyl(_hang, 0.02, 0.035, 0.12, Vector3(0, -0.72, 0), Build.mat(Color(0.85, 0.7, 0.2), 0.7))

	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.62, 0.32)
	_light.light_energy = 2.2
	_light.omni_range = 9.0
	_light.position.y = -0.5
	_hang.add_child(_light)


func _make_arm(side: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(side * 0.24, 1.32, 0.02)
	_visual.add_child(pivot)
	var arm := CapsuleMesh.new()
	arm.radius = 0.05
	arm.height = 0.5
	var mi := MeshInstance3D.new()
	mi.mesh = arm
	mi.material_override = Build.mat(Color(0.16, 0.24, 0.48), 0.8)
	mi.position.y = -0.2
	pivot.add_child(mi)
	pivot.rotation.z = -side * 0.16
	return pivot


func unlock_color(id: String) -> void:
	if not unlocked.has(id):
		unlocked.append(id)
	set_color(id)


func has_color(id: String) -> bool:
	return unlocked.has(id)


func set_color(id: String) -> void:
	current_color = id
	var c: Color = COLOR_DEFS[id]["color"] if id != "" else Color(1.0, 0.42, 0.15)
	_light.light_color = c.lerp(Color(1, 1, 1), 0.15)
	_paper_mat.emission = c
	_paper_mat.albedo_color = c.lerp(Color(1, 1, 1), 0.35)


func handle_color_keys(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		for id in COLOR_ORDER:
			if event.keycode == COLOR_DEFS[id]["key"] and unlocked.has(id):
				set_color(id)


func update_move(delta: float, clamp_cb: Callable) -> void:
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.z -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.z += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	_moving = dir.length_squared() > 0.0
	move_dir = dir
	if _moving:
		dir = dir.normalized()
		# đi lùi: giữ Shift thì bước lùi, mặt vẫn quay hướng cũ
		if Input.is_key_pressed(KEY_SHIFT):
			position += dir * SPEED * 0.7 * delta
		else:
			position += dir * SPEED * delta
			_target_yaw = atan2(dir.x, dir.z)
	position = clamp_cb.call(position)
	facing_yaw = _visual.rotation.y


func _process(delta: float) -> void:
	_anim_t += delta * (7.0 if _moving else 1.6)
	_visual.rotation.y = lerp_angle(_visual.rotation.y, _target_yaw, 1.0 - pow(0.0001, delta))
	_visual.position.y = absf(sin(_anim_t)) * (0.05 if _moving else 0.0)
	# tay vung + đèn đong đưa
	var swing := sin(_anim_t) * (0.5 if _moving else 0.06)
	_arm_l.rotation.x = swing
	_arm_r.rotation.x = -swing
	_hang.rotation.x = sin(_anim_t * (1.0 if _moving else 0.6)) * (0.14 if _moving else 0.05)
	_hang.rotation.z = sin(_anim_t * 0.7) * 0.04
	# lửa thở
	_light.light_energy = 2.2 + sin(_anim_t * 2.3) * 0.15
