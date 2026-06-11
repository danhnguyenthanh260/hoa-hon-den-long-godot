# Minh — nghệ nhân trẻ: áo dài, nón lá, gánh chiếc đèn lồng trên sào tre.
extends Node3D

const SPEED := 4.0

var _visual: Node3D
var _hang: Node3D      # điểm treo đèn ở đầu sào — đong đưa khi bước
var _target_yaw := PI  # quay mặt vào ngõ lúc bắt đầu
var _anim_t := 0.0
var _moving := false


static func _mat(c: Color, rough: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _ready() -> void:
	_visual = Node3D.new()
	_visual.rotation.y = _target_yaw
	add_child(_visual)

	# tà áo dài
	var robe := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.17
	rm.bottom_radius = 0.33
	rm.height = 1.0
	rm.radial_segments = 14
	robe.mesh = rm
	robe.material_override = _mat(Color(0.13, 0.2, 0.42), 0.8)
	robe.position.y = 0.5
	_visual.add_child(robe)

	# thân trên
	var torso := MeshInstance3D.new()
	var tm := CapsuleMesh.new()
	tm.radius = 0.17
	tm.height = 0.62
	torso.mesh = tm
	torso.material_override = _mat(Color(0.16, 0.24, 0.48), 0.8)
	torso.position.y = 1.18
	_visual.add_child(torso)

	# đầu
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.125
	hm.height = 0.25
	head.mesh = hm
	head.material_override = _mat(Color(0.87, 0.7, 0.55), 0.75)
	head.position.y = 1.52
	_visual.add_child(head)

	# nón lá
	var hat := MeshInstance3D.new()
	var nm := CylinderMesh.new()
	nm.top_radius = 0.015
	nm.bottom_radius = 0.42
	nm.height = 0.2
	nm.radial_segments = 18
	hat.mesh = nm
	hat.material_override = _mat(Color(0.76, 0.62, 0.38), 0.95)
	hat.position.y = 1.66
	_visual.add_child(hat)

	# hai cánh tay buông
	for sx in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		var am := CapsuleMesh.new()
		am.radius = 0.05
		am.height = 0.5
		arm.mesh = am
		arm.material_override = _mat(Color(0.16, 0.24, 0.48), 0.8)
		arm.position = Vector3(sx * 0.24, 1.1, 0.02)
		arm.rotation.z = -sx * 0.18
		_visual.add_child(arm)

	# sào tre vác chếch trên vai, đèn treo ở đầu trước
	var pole_holder := Node3D.new()
	pole_holder.position = Vector3(0.18, 1.32, 0.1)
	pole_holder.rotation.x = -0.38
	pole_holder.rotation.y = 0.55  # chếch sang vai phải để đèn không bị thân che khi nhìn từ sau
	_visual.add_child(pole_holder)

	var pole := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.018
	pm.bottom_radius = 0.022
	pm.height = 1.5
	pole.mesh = pm
	pole.material_override = _mat(Color(0.55, 0.45, 0.22), 0.9)
	pole.rotation.x = PI / 2.0
	pole.position.z = 0.45
	pole_holder.add_child(pole)

	_hang = Node3D.new()
	_hang.position = Vector3(0, 0, 1.18)
	pole_holder.add_child(_hang)

	# dây treo
	var cord := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.008
	cm.bottom_radius = 0.008
	cm.height = 0.36
	cord.mesh = cm
	cord.material_override = _mat(Color(0.3, 0.1, 0.08))
	cord.position.y = -0.18
	_hang.add_child(cord)

	# đèn lồng giấy đỏ
	var paper := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.26
	paper.mesh = sm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(1.0, 0.45, 0.25)
	pmat.emission_enabled = true
	pmat.emission = Color(1.0, 0.42, 0.15)
	pmat.emission_energy_multiplier = 2.8
	pmat.roughness = 0.5
	paper.material_override = pmat
	paper.position.y = -0.5
	_hang.add_child(paper)

	for dy in [-0.37, -0.63]:
		var rim := MeshInstance3D.new()
		var rmm := CylinderMesh.new()
		rmm.top_radius = 0.06
		rmm.bottom_radius = 0.06
		rmm.height = 0.03
		rim.mesh = rmm
		rim.material_override = _mat(Color(0.1, 0.07, 0.05))
		rim.position.y = dy
		_hang.add_child(rim)

	# tua rua dưới đèn
	var tassel := MeshInstance3D.new()
	var tsm := CylinderMesh.new()
	tsm.top_radius = 0.02
	tsm.bottom_radius = 0.035
	tsm.height = 0.12
	tassel.mesh = tsm
	tassel.material_override = _mat(Color(0.85, 0.7, 0.2), 0.7)
	tassel.position.y = -0.72
	_hang.add_child(tassel)

	# nguồn sáng của đèn cầm tay
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.62, 0.32)
	light.light_energy = 2.2
	light.omni_range = 9.0
	light.position.y = -0.5
	_hang.add_child(light)


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
	if _moving:
		dir = dir.normalized()
		position += dir * SPEED * delta
		_target_yaw = atan2(dir.x, dir.z)
	position = clamp_cb.call(position)


func _process(delta: float) -> void:
	_anim_t += delta * (7.0 if _moving else 1.6)
	_visual.rotation.y = lerp_angle(_visual.rotation.y, _target_yaw, 1.0 - pow(0.0001, delta))
	# nhún khi bước + đèn đong đưa
	_visual.position.y = absf(sin(_anim_t)) * (0.05 if _moving else 0.0)
	var sway := sin(_anim_t * (1.0 if _moving else 0.6)) * (0.14 if _moving else 0.05)
	_hang.rotation.x = sway
	_hang.rotation.z = sin(_anim_t * 0.7) * 0.04
