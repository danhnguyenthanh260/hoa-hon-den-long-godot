# Cơ chế "Thắp Sáng Ký Ức": stencil Chim Lạc quay quanh ngọn nến trong đèn lồng lục giác.
# Hình học: nến tại (3.2, 1.6, -17), tường tại z=-20 (cách 3m), stencil cách nến 0.5m
# => bóng chiếu lên tường được phóng đại 6 lần. Hình mờ trên tường là hình chiếu
# tính sẵn tại góc đúng (góc 0 — mặt stencil song song với tường).
extends Node3D

const Bird := preload("res://scripts/bird.gd")

const LIGHT_POS := Vector3(3.2, 1.6, -17)
const STENCIL_DIST := 0.5
const STENCIL_SCALE := 0.5
const WALL_Z := -20.0
const ROT_SPEED := 1.1
const TOLERANCE := 0.07

var active := false
var solved := false
var angle := 1.4
var solved_callback: Callable

var _pivot: Node3D
var _ghost: MeshInstance3D
var _light: OmniLight3D
var _time := 0.0


static func _mat(c: Color, rough: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func stand_pos() -> Vector3:
	return Vector3(LIGHT_POS.x, 0, LIGHT_POS.z)


func _ready() -> void:
	var wood := _mat(Color(0.13, 0.09, 0.06))

	# trụ gỗ đỡ đèn
	var pole := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.05
	pm.bottom_radius = 0.07
	pm.height = 1.15
	pole.mesh = pm
	pole.material_override = wood
	pole.position = Vector3(LIGHT_POS.x, 0.58, LIGHT_POS.z)
	add_child(pole)

	var base := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.24
	bm.bottom_radius = 0.32
	bm.height = 0.1
	base.mesh = bm
	base.material_override = wood
	base.position = Vector3(LIGHT_POS.x, 0.05, LIGHT_POS.z)
	add_child(base)

	# vỏ đèn giấy lục giác (không đổ bóng — bóng chỉ đến từ stencil)
	var shell := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.3
	sm.bottom_radius = 0.34
	sm.height = 0.6
	sm.radial_segments = 6
	shell.mesh = sm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(1.0, 0.85, 0.68, 0.4)
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.emission_enabled = true
	smat.emission = Color(1.0, 0.55, 0.3)
	smat.emission_energy_multiplier = 1.1
	smat.cull_mode = BaseMaterial3D.CULL_DISABLED
	shell.material_override = smat
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shell.position = LIGHT_POS
	add_child(shell)

	# vành + chóp
	for dy in [-0.34, 0.34]:
		var rim := MeshInstance3D.new()
		var rm := CylinderMesh.new()
		rm.top_radius = 0.36
		rm.bottom_radius = 0.36
		rm.height = 0.05
		rm.radial_segments = 6
		rim.mesh = rm
		rim.material_override = wood
		rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		rim.position = LIGHT_POS + Vector3(0, dy, 0)
		add_child(rim)
	var finial := MeshInstance3D.new()
	var fm := SphereMesh.new()
	fm.radius = 0.06
	fm.height = 0.12
	finial.mesh = fm
	finial.material_override = _mat(Color(0.85, 0.68, 0.25), 0.4)
	finial.position = LIGHT_POS + Vector3(0, 0.42, 0)
	add_child(finial)

	# ngọn nến
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.6, 0.33)
	_light.light_energy = 2.6
	_light.omni_range = 12.0
	_light.shadow_enabled = true
	_light.position = LIGHT_POS
	add_child(_light)

	# stencil Chim Lạc quay quanh nến
	_pivot = Node3D.new()
	_pivot.position = LIGHT_POS
	_pivot.rotation.y = angle
	add_child(_pivot)
	var stencil := MeshInstance3D.new()
	stencil.mesh = Bird.make_mesh()
	var stmat := StandardMaterial3D.new()
	stmat.albedo_color = Color(0.05, 0.04, 0.04)
	stmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	stmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	stencil.material_override = stmat
	stencil.scale = Vector3.ONE * STENCIL_SCALE
	stencil.position.z = -STENCIL_DIST
	stencil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	_pivot.add_child(stencil)

	# hình mờ trên tường
	_ghost = MeshInstance3D.new()
	_ghost.mesh = Bird.make_mesh()
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(1.0, 0.91, 0.69, 0.22)
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost.material_override = gmat
	var k := (LIGHT_POS.z - WALL_Z) / STENCIL_DIST
	_ghost.scale = Vector3.ONE * STENCIL_SCALE * k
	_ghost.position = Vector3(LIGHT_POS.x, LIGHT_POS.y, WALL_Z + 0.38)
	_ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ghost)


func update_puzzle(delta: float) -> void:
	if not active or solved:
		return
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		angle += ROT_SPEED * delta
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		angle -= ROT_SPEED * delta
	angle = wrapf(angle, -PI, PI)
	_pivot.rotation.y = angle
	if absf(angle) < TOLERANCE:
		solved = true
		angle = 0.0
		_pivot.rotation.y = 0.0
		var gm := _ghost.material_override as StandardMaterial3D
		gm.albedo_color = Color(1.0, 0.82, 0.29, 0.62)
		_light.light_energy = 4.0
		if solved_callback.is_valid():
			solved_callback.call()


func _process(delta: float) -> void:
	_time += delta
	if not solved:
		# nến leo lét
		_light.light_energy = 2.6 + sin(_time * 13.0) * 0.25 + sin(_time * 7.7) * 0.18
