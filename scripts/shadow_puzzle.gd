# Câu đố bóng tổng quát: stencil quay quanh ngọn nến, bóng phóng đại lên tường
# (tường vuông góc trục z, chiếu về phía -z). Hình mờ trên tường = hình chiếu ở góc 0.
extends Node3D

const Build := preload("res://scripts/build.gd")
const Shapes := preload("res://scripts/shapes.gd")

const STENCIL_DIST := 0.5
const ROT_SPEED := 1.1
const TOLERANCE := 0.07

var active := false
var solved := false
var angle := 1.4
var solved_callback: Callable

var light_pos: Vector3
var _wall_z: float
var _pivot: Node3D
var _ghost: MeshInstance3D
var _light: OmniLight3D
var _time := 0.0


func setup(p_light_pos: Vector3, p_wall_z: float, polygon: PackedVector2Array, stencil_scale: float, start_angle: float, with_stand: bool = true) -> void:
	light_pos = p_light_pos
	_wall_z = p_wall_z
	angle = start_angle
	var wood := Build.mat(Color(0.13, 0.09, 0.06))

	if with_stand:
		Build.cyl(self, 0.05, 0.07, light_pos.y - 0.45, Vector3(light_pos.x, (light_pos.y - 0.45) / 2.0, light_pos.z), wood)
		Build.cyl(self, 0.24, 0.32, 0.1, Vector3(light_pos.x, 0.05, light_pos.z), wood, 14)

	var shell := CylinderMesh.new()
	shell.top_radius = 0.3
	shell.bottom_radius = 0.34
	shell.height = 0.6
	shell.radial_segments = 6
	var shell_mi := MeshInstance3D.new()
	shell_mi.mesh = shell
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(1.0, 0.85, 0.68, 0.4)
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.emission_enabled = true
	smat.emission = Color(1.0, 0.55, 0.3)
	smat.emission_energy_multiplier = 1.1
	smat.cull_mode = BaseMaterial3D.CULL_DISABLED
	shell_mi.material_override = smat
	shell_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shell_mi.position = light_pos
	add_child(shell_mi)
	for dy in [-0.34, 0.34]:
		var rim := Build.cyl(self, 0.36, 0.36, 0.05, light_pos + Vector3(0, dy, 0), wood, 6)
		rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Build.ball(self, 0.06, 0.12, light_pos + Vector3(0, 0.42, 0), Build.mat(Color(0.85, 0.68, 0.25), 0.4))

	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.6, 0.33)
	_light.light_energy = 2.6
	_light.omni_range = 12.0
	_light.shadow_enabled = true
	_light.position = light_pos
	add_child(_light)

	_pivot = Node3D.new()
	_pivot.position = light_pos
	_pivot.rotation.y = angle
	add_child(_pivot)
	var stencil := MeshInstance3D.new()
	stencil.mesh = Shapes.make_mesh(polygon)
	var stmat := StandardMaterial3D.new()
	stmat.albedo_color = Color(0.05, 0.04, 0.04)
	stmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	stmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	stencil.material_override = stmat
	stencil.scale = Vector3.ONE * stencil_scale
	stencil.position.z = -STENCIL_DIST
	stencil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	_pivot.add_child(stencil)

	_ghost = MeshInstance3D.new()
	_ghost.mesh = Shapes.make_mesh(polygon)
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(1.0, 0.91, 0.69, 0.22)
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost.material_override = gmat
	var k := (light_pos.z - _wall_z) / STENCIL_DIST
	_ghost.scale = Vector3.ONE * stencil_scale * k
	_ghost.position = Vector3(light_pos.x, light_pos.y, _wall_z + 0.38)
	_ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ghost)


func stand_pos() -> Vector3:
	return Vector3(light_pos.x, 0, light_pos.z)


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
		_light.light_energy = 2.6 + sin(_time * 13.0) * 0.25 + sin(_time * 7.7) * 0.18
