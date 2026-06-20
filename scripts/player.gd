# Minh — nghệ nhân trẻ gánh đèn. Áo dài ngũ thân xẻ tà chàm sẫm, quần lanh trắng,
# nón lá quai thao, sào tre ghì trên vai phải, đèn lồng giấy đỏ treo đầu sào.
# Toàn bộ dựng procedural: thân lathe mượt, chân/tay hai khớp, tà áo bay theo bước.
extends Node3D

const Build := preload("res://scripts/build.gd")
const Textures := preload("res://scripts/textures.gd")

const SPEED := 4.0

const COLOR_DEFS := {
	"hoa": {"name": "Hỏa", "color": Color(1.0, 0.3, 0.1), "num": 1, "keys": [KEY_1, KEY_KP_1]},
	"thuy": {"name": "Thủy", "color": Color(0.25, 0.55, 1.0), "num": 2, "keys": [KEY_2, KEY_KP_2]},
	"moc": {"name": "Mộc", "color": Color(0.3, 1.0, 0.38), "num": 3, "keys": [KEY_3, KEY_KP_3]},
	"kim": {"name": "Kim", "color": Color(1.0, 0.96, 0.82), "num": 4, "keys": [KEY_4, KEY_KP_4]},
	"tho": {"name": "Thổ", "color": Color(1.0, 0.78, 0.2), "num": 5, "keys": [KEY_5, KEY_KP_5]},
}
const COLOR_ORDER := ["hoa", "thuy", "moc", "kim", "tho"]

var unlocked: Array = []
var current_color := ""
var move_dir := Vector3.ZERO
var facing_yaw := PI
var force_walk := false       # cho bot chụp ảnh tư thế bước
var _near_house := false      # đứng sát thềm nhà ai đó
var _courtesy := 0.0          # 0 → 1: hạ sào + che đèn (phép lịch sự ban đêm)
var first_person := false     # ẩn thân, đi theo hướng nhìn; sào đèn vẫn hiện
var fp_yaw := PI
var _body_parts: Array = []
var _pole_holder: Node3D
var _pole_mi: MeshInstance3D

var _visual: Node3D
var _hang: Node3D
var _paper_mat: StandardMaterial3D
var _light: OmniLight3D
var _target_yaw := PI
var _anim_t := 0.0
var _gait := 0.0              # 0 đứng yên → 1 sải bước (blend mượt)
var _moving := false
var _prev_yaw := PI

# khớp animation
var _leg_l: Node3D
var _leg_r: Node3D
var _knee_l: Node3D
var _knee_r: Node3D
var _arm_swing: Node3D        # tay trái vung theo nhịp
var _elbow_swing: Node3D
var _flap_f: Node3D
var _flap_b: Node3D
var _head: Node3D

# chất liệu
var _robe_mat: StandardMaterial3D


func _ready() -> void:
	_visual = Node3D.new()
	_visual.rotation.y = _target_yaw
	add_child(_visual)

	_robe_mat = StandardMaterial3D.new()
	_robe_mat.albedo_color = Color(0.11, 0.16, 0.33)
	_robe_mat.roughness = 0.55
	_robe_mat.clearcoat_enabled = true
	_robe_mat.clearcoat = 0.25
	_robe_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var linen := Build.mat(Color(0.8, 0.76, 0.68), 0.92)
	var skin := Build.mat(Color(0.85, 0.65, 0.5), 0.7)
	var hair := Build.mat(Color(0.06, 0.05, 0.05), 0.85)
	var sandal := Build.mat(Color(0.22, 0.13, 0.07), 0.85)

	# ---- chân hai khớp: đùi (quần trắng) → gối → ống chân → dép ----
	_leg_l = _make_leg(-0.085, linen, sandal)
	_leg_r = _make_leg(0.085, linen, sandal)
	_knee_l = _leg_l.get_child(1)
	_knee_r = _leg_r.get_child(1)

	# ---- thân áo dài: lathe từ cổ áo xuống hông ----
	var profile := [
		Vector2(0.165, 0.78),   # hông
		Vector2(0.150, 0.92),   # eo
		Vector2(0.165, 1.10),   # ngực
		Vector2(0.155, 1.26),   # vai dưới
		Vector2(0.105, 1.38),   # vai
		Vector2(0.055, 1.46),   # cổ áo
		Vector2(0.045, 1.52),
	]
	Build.lathe(_visual, profile, Vector3.ZERO, _robe_mat)
	# viền cổ áo
	Build.cyl(_visual, 0.052, 0.052, 0.025, Vector3(0, 1.50, 0), Build.mat(Color(0.62, 0.47, 0.2), 0.5), 12)

	# ---- hai tà áo xẻ trước sau, đung đưa khi bước ----
	_flap_f = _make_flap(0.115)
	_flap_b = _make_flap(-0.115)

	# ---- đầu: gương mặt đầy đủ, tóc, nón lá quai thao ----
	_head = Node3D.new()
	_head.position = Vector3(0, 1.58, 0)
	_visual.add_child(_head)
	var face := Build.ball(_head, 0.115, 0.215, Vector3.ZERO, skin)
	face.scale = Vector3(0.96, 1.05, 1.0)
	# mắt: lòng trắng hạnh nhân + con ngươi đen
	var eye_white := Build.mat(Color(0.93, 0.91, 0.86), 0.25)
	var pupil_m := Build.mat(Color(0.07, 0.05, 0.04), 0.2)
	for ex in [-1.0, 1.0]:
		var ew := Build.ball(_head, 0.02, 0.036, Vector3(ex * 0.046, 0.008, 0.098), eye_white)
		ew.scale = Vector3(1.25, 0.85, 0.55)
		Build.ball(_head, 0.0105, 0.02, Vector3(ex * 0.044, 0.006, 0.112), pupil_m)
		# lông mày mảnh
		var brow := Build.box(_head, Vector3(0.04, 0.006, 0.008), Vector3(ex * 0.046, 0.042, 0.105), hair)
		brow.rotation.z = -ex * 0.1
		# tai
		var ear := Build.ball(_head, 0.022, 0.042, Vector3(ex * 0.112, -0.005, 0.005), skin)
		ear.scale = Vector3(0.45, 0.9, 0.7)
	# mũi
	var nose := Build.ball(_head, 0.016, 0.03, Vector3(0, -0.018, 0.115), skin)
	nose.scale = Vector3(0.75, 1.1, 0.85)
	# miệng
	var mouth := Build.box(_head, Vector3(0.042, 0.008, 0.01), Vector3(0, -0.06, 0.103), Build.mat(Color(0.6, 0.28, 0.22), 0.5))
	mouth.rotation.y = 0.0
	# tóc ôm gáy dưới vành nón + mái lưa thưa trước trán
	var hair_m := Build.ball(_head, 0.115, 0.2, Vector3(0, 0.02, -0.02), hair)
	hair_m.scale = Vector3(1.05, 0.92, 1.02)
	Build.box(_head, Vector3(0.115, 0.014, 0.014), Vector3(0, 0.094, 0.09), hair)
	# nón lá: chóp thẳng, texture lá cọ — đội cao và ngửa nhẹ để lộ mặt
	var hat_mat := StandardMaterial3D.new()
	hat_mat.albedo_texture = Textures.straw()
	hat_mat.roughness = 0.92
	hat_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var hat := CylinderMesh.new()
	hat.top_radius = 0.008
	hat.bottom_radius = 0.34
	hat.height = 0.2
	hat.radial_segments = 22
	var hat_mi := MeshInstance3D.new()
	hat_mi.mesh = hat
	hat_mi.material_override = hat_mat
	hat_mi.position = Vector3(0, 0.185, -0.01)
	hat_mi.rotation.x = -0.1
	_head.add_child(hat_mi)
	Build.cyl(_head, 0.012, 0.012, 0.03, Vector3(0, 0.295, -0.012), Build.mat(Color(0.5, 0.38, 0.2), 0.8), 8)
	# quai nón: hai dây ôm má chụm dưới cằm + nơ nhỏ
	for qx in [-1.0, 1.0]:
		var strap := Build.cyl(_head, 0.0035, 0.0035, 0.27, Vector3(qx * 0.052, -0.045, 0.062), Build.mat(Color(0.38, 0.08, 0.08), 0.7), 6)
		strap.rotation.z = qx * 0.82
		strap.rotation.x = -0.22
	Build.ball(_head, 0.011, 0.022, Vector3(0, -0.135, 0.075), Build.mat(Color(0.45, 0.1, 0.1), 0.6))

	# ---- tay phải ghì sào trên vai: khuỷu sát thân, bàn tay nắm sào trước vai ----
	var arm_r := Node3D.new()
	arm_r.position = Vector3(0.185, 1.36, 0)
	arm_r.rotation.z = -0.12
	arm_r.rotation.x = 0.42
	_visual.add_child(arm_r)
	Build.ball(arm_r, 0.05, 0.28, Vector3(0, -0.11, 0), _robe_mat)
	var elbow_r := Node3D.new()
	elbow_r.position = Vector3(0, -0.22, 0)
	elbow_r.rotation.x = -1.5
	arm_r.add_child(elbow_r)
	Build.ball(elbow_r, 0.044, 0.24, Vector3(0, -0.09, 0), _robe_mat)
	Build.ball(elbow_r, 0.048, 0.095, Vector3(0, -0.2, 0), skin)

	# ---- tay trái vung theo nhịp bước ----
	_arm_swing = Node3D.new()
	_arm_swing.position = Vector3(-0.19, 1.34, 0)
	_arm_swing.rotation.z = 0.14
	_visual.add_child(_arm_swing)
	Build.ball(_arm_swing, 0.052, 0.3, Vector3(0, -0.12, 0), _robe_mat)
	_elbow_swing = Node3D.new()
	_elbow_swing.position = Vector3(0, -0.24, 0)
	_elbow_swing.rotation.x = -0.25
	_arm_swing.add_child(_elbow_swing)
	Build.ball(_elbow_swing, 0.046, 0.26, Vector3(0, -0.1, 0), _robe_mat)
	Build.ball(_elbow_swing, 0.05, 0.1, Vector3(0, -0.22, 0), skin)

	# ---- sào tre trên vai phải, đèn treo đầu trước ----
	var pole_holder := Node3D.new()
	pole_holder.position = Vector3(0.18, 1.42, 0.05)
	pole_holder.rotation.x = -0.36
	pole_holder.rotation.y = 0.5
	_visual.add_child(pole_holder)
	_pole_holder = pole_holder
	var pole := CylinderMesh.new()
	pole.top_radius = 0.016
	pole.bottom_radius = 0.02
	pole.height = 1.55
	_pole_mi = MeshInstance3D.new()
	_pole_mi.mesh = pole
	_pole_mi.material_override = Build.mat(Color(0.52, 0.42, 0.2), 0.85)
	_pole_mi.rotation.x = PI / 2.0
	_pole_mi.position.z = 0.42
	pole_holder.add_child(_pole_mi)
	# đốt tre
	for kz in [0.0, 0.35, 0.7]:
		Build.cyl(pole_holder, 0.021, 0.021, 0.015, Vector3(0, 0, 0.1 + kz), Build.mat(Color(0.42, 0.33, 0.15), 0.85), 8).rotation.x = PI / 2.0

	_hang = Node3D.new()
	_hang.position = Vector3(0, 0, 1.16)
	pole_holder.add_child(_hang)
	Build.cyl(_hang, 0.007, 0.007, 0.3, Vector3(0, -0.15, 0), Build.mat(Color(0.3, 0.1, 0.08)))
	# đèn lồng giấy lục giác nhỏ
	_paper_mat = Build.emis(Color(1.0, 0.45, 0.25), Color(1.0, 0.42, 0.15), 2.8, 0.5)
	_paper_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var paper := CylinderMesh.new()
	paper.top_radius = 0.105
	paper.bottom_radius = 0.125
	paper.height = 0.22
	paper.radial_segments = 6
	var paper_mi := MeshInstance3D.new()
	paper_mi.mesh = paper
	paper_mi.material_override = _paper_mat
	paper_mi.position.y = -0.43
	paper_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_hang.add_child(paper_mi)
	for dy in [-0.31, -0.55]:
		Build.cyl(_hang, 0.06, 0.06, 0.03, Vector3(0, dy, 0), Build.mat(Color(0.1, 0.07, 0.05)), 6)
	# tua rua đỏ
	for tk in range(3):
		var th := Build.cyl(_hang, 0.004, 0.004, 0.1, Vector3((tk - 1) * 0.015, -0.62, 0), Build.mat(Color(0.7, 0.12, 0.1), 0.7), 4)
		th.rotation.z = (tk - 1) * 0.12
	Build.ball(_hang, 0.018, 0.036, Vector3(0, -0.57, 0), Build.mat(Color(0.85, 0.68, 0.2), 0.5))

	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.62, 0.32)
	_light.light_energy = 2.2
	_light.omni_range = 9.0
	_light.position.y = -0.43
	_hang.add_child(_light)
	# gom các phần THÂN (trừ sào đèn) để ẩn khi vào góc nhìn thứ nhất
	for c in _visual.get_children():
		if c != _pole_holder:
			_body_parts.append(c)
	_disable_shadow_casting(self)


func _disable_shadow_casting(node: Node) -> void:
	if node is GeometryInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_disable_shadow_casting(child)


func set_near_house(v: bool) -> void:
	_near_house = v


func set_first_person(v: bool) -> void:
	first_person = v
	for c in _body_parts:
		c.visible = not v
	# góc nhìn thứ nhất: rút ngắn sào để đèn không chọc xuyên tường nhà
	if v:
		_pole_mi.scale.y = 0.55
		_pole_mi.position.z = 0.24
		_hang.position.z = 0.68
	else:
		_pole_mi.scale.y = 1.0
		_pole_mi.position.z = 0.42
		_hang.position.z = 1.16


func _make_leg(x: float, linen: Material, sandal: Material) -> Node3D:
	var hip := Node3D.new()
	hip.position = Vector3(x, 0.82, 0)
	_visual.add_child(hip)
	Build.ball(hip, 0.06, 0.42, Vector3(0, -0.18, 0), linen)   # đùi (ống quần)
	var knee := Node3D.new()
	knee.position = Vector3(0, -0.38, 0)
	hip.add_child(knee)
	Build.ball(knee, 0.05, 0.36, Vector3(0, -0.15, 0), linen)  # ống chân
	# bàn chân + dép bo tròn
	var foot := Build.ball(knee, 0.05, 0.1, Vector3(0, -0.36, 0.04), sandal)
	foot.scale = Vector3(0.85, 0.42, 1.75)
	return hip


func _make_flap(z: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(0, 0.84, z)
	_visual.add_child(pivot)
	# tà áo: dải vải liền cong mượt, hơi thu nhỏ về đuôi tà
	Build.ribbon(pivot, 0.26, 0.64, sign(z) * 0.18, 0.14, _robe_mat, 10)
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


# trả về id màu ứng với phím (kể cả numpad), "" nếu không phải phím màu
func color_for_key(event: InputEvent) -> String:
	if event is InputEventKey and event.pressed and not event.echo:
		for id in COLOR_ORDER:
			if event.keycode in COLOR_DEFS[id]["keys"]:
				return id
	return ""


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
	if first_person and _moving:
		dir = dir.rotated(Vector3.UP, fp_yaw - PI)
	move_dir = dir
	if _moving:
		dir = dir.normalized()
		position += dir * SPEED * delta
		if first_person:
			_target_yaw = fp_yaw
		else:
			_target_yaw = atan2(dir.x, dir.z)
	elif first_person:
		_target_yaw = fp_yaw
	position = clamp_cb.call(position)
	facing_yaw = _visual.rotation.y


func _process(delta: float) -> void:
	var walking := _moving or force_walk
	_gait = lerpf(_gait, 1.0 if walking else 0.0, 1.0 - pow(0.002, delta))
	_anim_t += delta * (8.5 * maxf(_gait, 0.12))

	# xoay người + nghiêng vào khúc cua
	_visual.rotation.y = lerp_angle(_visual.rotation.y, _target_yaw, 1.0 - pow(0.0001, delta))
	var yaw_rate := wrapf(_visual.rotation.y - _prev_yaw, -PI, PI) / maxf(delta, 0.001)
	_prev_yaw = _visual.rotation.y
	_visual.rotation.z = clampf(-yaw_rate * 0.03, -0.1, 0.1) * _gait
	_visual.rotation.x = 0.055 * _gait      # chúi nhẹ về trước khi bước

	# nhún người theo nhịp (2 nhịp mỗi chu kỳ chân)
	_visual.position.y = absf(sin(_anim_t)) * 0.045 * _gait + sin(_anim_t * 0.35) * 0.006 * (1.0 - _gait)

	# chân: đùi vung, gối gập lúc chân vung tới
	var sw := sin(_anim_t) * 0.55 * _gait
	_leg_l.rotation.x = sw
	_leg_r.rotation.x = -sw
	_knee_l.rotation.x = maxf(0.0, sin(_anim_t - 0.7)) * 0.85 * _gait
	_knee_r.rotation.x = maxf(0.0, sin(_anim_t - 0.7 + PI)) * 0.85 * _gait

	# tay trái vung ngược chân trái
	_arm_swing.rotation.x = -sw * 0.75
	_elbow_swing.rotation.x = -0.25 - maxf(0.0, -sw) * 0.5

	# tà áo bay: phất ra sau khi bước + rung nhẹ
	var trail := 0.32 * _gait
	_flap_f.rotation.x = trail + sin(_anim_t * 2.0 + 0.6) * 0.07 * _gait + sin(_anim_t * 0.35) * 0.015
	_flap_b.rotation.x = -trail - sin(_anim_t * 2.0) * 0.07 * _gait - sin(_anim_t * 0.35) * 0.015

	# đầu giữ thăng bằng (nghiêng ngược thân một chút)
	_head.rotation.x = -_visual.rotation.x * 0.6
	_head.rotation.z = -_visual.rotation.z * 0.5

	# đèn lồng đong đưa theo quán tính
	_hang.rotation.x = sin(_anim_t * (1.0 if walking else 0.55)) * (0.13 * _gait + 0.045)
	_hang.rotation.z = sin(_anim_t * 0.7) * 0.04

	# lại gần nhà ai ban đêm thì hạ sào, che bớt đèn — phép lịch sự của người gánh đèn
	_courtesy = lerpf(_courtesy, 1.0 if _near_house else 0.0, 1.0 - pow(0.01, delta))
	_pole_holder.rotation.x = -0.36 + 0.6 * _courtesy
	_pole_holder.rotation.y = 0.5 + 0.55 * _courtesy
	_light.light_energy = (2.2 + sin(_anim_t * 2.3) * 0.15) * (1.0 - 0.82 * _courtesy)
	_light.omni_range = 9.0 - 5.5 * _courtesy
	_paper_mat.emission_energy_multiplier = 2.8 - 2.25 * _courtesy
