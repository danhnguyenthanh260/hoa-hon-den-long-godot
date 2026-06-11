# Ngõ phố Hội An ban đêm: nhà tường vàng nghệ + cột gỗ + mái ngói, dây đèn lồng
# giăng ngang ngõ, tường cuối ngõ có cổng phong ấn, sau cổng là bến sông hoa đăng.
# Trục ngõ chạy dọc z, người chơi đi từ z=7 về z=-20.
extends Node3D

const ALLEY_HALF := 5.0
const FACADE_X := 5.35

var _env: Environment
var _gate: MeshInstance3D
var _gate_opening := false
var _hanging: Array = []        # đèn lồng treo dưới mái hiên
var _string_lanterns: Array = [] # đèn trên dây giăng ngang ngõ
var _windows: Array = []        # cửa sổ sáng lên sau khi giải phong ấn
var _hoa_dang: Array = []       # [node, phase]
var _time := 0.0

var _plaster := _mat(Color(0.36, 0.25, 0.12), 0.92)
var _wood := _mat(Color(0.16, 0.11, 0.07), 0.85)
var _darkwood := _mat(Color(0.11, 0.075, 0.05), 0.85)
var _tile := _mat(Color(0.10, 0.09, 0.105), 0.7)


static func _mat(c: Color, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


static func _box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	return mi


func _ready() -> void:
	_build_environment()
	_build_ground()
	_build_houses()
	_build_lantern_strings()
	_build_end_wall()
	_build_river()


func _build_environment() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.015, 0.025, 0.055)
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.16, 0.20, 0.32)
	_env.ambient_light_energy = 0.6
	_env.tonemap_mode = Environment.TONE_MAPPER_ACES
	_env.tonemap_exposure = 1.0
	_env.glow_enabled = true
	_env.glow_intensity = 1.0
	_env.glow_bloom = 0.12
	_env.fog_enabled = true
	_env.fog_light_color = Color(0.045, 0.06, 0.11)
	_env.fog_density = 0.012
	_env.volumetric_fog_enabled = true
	_env.volumetric_fog_density = 0.035
	_env.volumetric_fog_albedo = Color(0.55, 0.6, 0.75)
	_env.ssr_enabled = true
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)

	# trăng: nguồn sáng xanh lạnh + quả cầu phát sáng trên trời
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.65, 0.9)
	moon.light_energy = 0.25
	moon.shadow_enabled = true
	moon.rotation_degrees = Vector3(-38, 28, 0)
	add_child(moon)

	var moon_ball := MeshInstance3D.new()
	var ms := SphereMesh.new()
	ms.radius = 2.2
	ms.height = 4.4
	moon_ball.mesh = ms
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.albedo_color = Color(0.85, 0.9, 1.0)
	mm.emission_enabled = true
	mm.emission = Color(0.8, 0.85, 1.0)
	mm.emission_energy_multiplier = 2.0
	moon_ball.material_override = mm
	moon_ball.position = Vector3(-22, 19, -55)
	add_child(moon_ball)


func _build_ground() -> void:
	var noise := FastNoiseLite.new()
	noise.frequency = 0.12
	var ntex := NoiseTexture2D.new()
	ntex.noise = noise
	ntex.width = 256
	ntex.height = 256

	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.17, 0.125, 0.105)
	gmat.albedo_texture = ntex
	gmat.uv1_scale = Vector3(8, 24, 1)
	gmat.roughness = 0.95

	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(26, 72)
	ground.mesh = pm
	ground.material_override = gmat
	ground.position = Vector3(0, 0, -12)
	add_child(ground)


func _make_lantern(radius: float, height: float, pos: Vector3) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	# đèn lồng tròn kiểu Hội An: sphere dẹt
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = height
	body.mesh = sm
	body.material_override = _mat(Color(0.22, 0.17, 0.155), 0.8)
	body.position = pos
	add_child(body)
	# vành trên/dưới
	for dy in [-height * 0.5, height * 0.5]:
		var rim := MeshInstance3D.new()
		var rm := CylinderMesh.new()
		rm.top_radius = radius * 0.35
		rm.bottom_radius = radius * 0.35
		rm.height = 0.035
		rim.mesh = rm
		rim.material_override = _darkwood
		rim.position = pos + Vector3(0, dy, 0)
		add_child(rim)
	return body


func _light_lantern(mesh: MeshInstance3D, color: Color, energy: float) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.85, 0.7)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.roughness = 0.6
	mesh.material_override = m


func _build_houses() -> void:
	for i in range(7):
		var z := 6.0 - i * 4.0
		var h := 2.9 + (i % 3) * 0.5
		for side in [-1.0, 1.0]:
			var cx: float = side * 6.9
			# thân nhà tường vàng
			add_child(_box(Vector3(3.0, h, 3.6), Vector3(cx, h / 2.0, z), _plaster))
			# cột gỗ trên mặt tiền
			for dz in [-1.7, 0.0, 1.7]:
				add_child(_box(Vector3(0.12, h, 0.12), Vector3(side * FACADE_X, h / 2.0, z + dz), _darkwood))
			# cửa gỗ
			add_child(_box(Vector3(0.07, 2.0, 1.3), Vector3(side * (FACADE_X + 0.02), 1.0, z), _wood))
			# cửa sổ gác trên (sáng lên khi phố hồi sinh)
			var win := _box(Vector3(0.06, 0.65, 0.95), Vector3(side * (FACADE_X + 0.03), h - 0.75, z + 1.0), _mat(Color(0.09, 0.07, 0.055), 0.8))
			add_child(win)
			_windows.append(win)
			# mái ngói hai dốc, đòn dông chạy dọc ngõ
			for k in [-1.0, 1.0]:
				var slab := _box(Vector3(2.1, 0.07, 4.0), Vector3(cx + k * 0.95, h + 0.42, z), _tile)
				slab.rotation.z = -k * 0.42
				add_child(slab)
			add_child(_box(Vector3(0.3, 0.12, 4.0), Vector3(cx, h + 0.88, z), _darkwood))
			# đèn lồng treo dưới hiên
			var lan := _make_lantern(0.16, 0.3, Vector3(side * (FACADE_X - 0.15), h - 0.45, z - 1.2))
			_hanging.append(lan)


func _build_lantern_strings() -> void:
	var palette := [Color(1.0, 0.16, 0.08), Color(1.0, 0.62, 0.12), Color(1.0, 0.32, 0.08), Color(0.95, 0.25, 0.4)]
	var idx := 0
	for z in [2.0, -6.0, -14.0]:
		var prev := Vector3.ZERO
		for i in range(7):
			var x := -4.8 + i * 1.6
			var y := 3.55 - 0.55 * (1.0 - pow(x / 4.8, 2.0))
			var top := Vector3(x, y + 0.14, z)
			if i > 0:
				_add_rope(prev, top)
			prev = top
			var lan := _make_lantern(0.13, 0.24, Vector3(x, y, z))
			_string_lanterns.append([lan, palette[idx % palette.size()]])
			idx += 1


func _add_rope(a: Vector3, b: Vector3) -> void:
	var mid := (a + b) * 0.5
	var seg := _box(Vector3(a.distance_to(b), 0.015, 0.015), mid, _mat(Color(0.05, 0.045, 0.04)))
	seg.rotation.z = atan2(b.y - a.y, b.x - a.x)
	add_child(seg)


func _build_end_wall() -> void:
	add_child(_box(Vector3(4.5, 5.0, 0.6), Vector3(-3.75, 2.5, -20), _plaster))
	add_child(_box(Vector3(4.5, 5.0, 0.6), Vector3(3.75, 2.5, -20), _plaster))
	add_child(_box(Vector3(3.0, 2.1, 0.6), Vector3(0, 3.95, -20), _plaster))
	# trụ đá hai bên cổng
	add_child(_box(Vector3(0.5, 3.2, 0.75), Vector3(-1.7, 1.6, -20), _mat(Color(0.28, 0.27, 0.26))))
	add_child(_box(Vector3(0.5, 3.2, 0.75), Vector3(1.7, 1.6, -20), _mat(Color(0.28, 0.27, 0.26))))
	# cánh cổng gỗ + hai thanh ngang
	_gate = _box(Vector3(3.0, 2.9, 0.25), Vector3(0, 1.45, -20), _wood)
	add_child(_gate)
	for dy in [-0.7, 0.7]:
		var batten := _box(Vector3(3.0, 0.18, 0.08), Vector3(0, dy, -0.17), _darkwood)
		_gate.add_child(batten)
	# đèn lồng mặt sau tường — đón người chơi bước ra bến sông
	for x in [-4.0, -2.2, 2.2, 4.0]:
		var lan := _make_lantern(0.16, 0.3, Vector3(x, 2.7, -20.5))
		_hanging.append(lan)


func _build_river() -> void:
	# mặt nước sau cổng
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(26, 9)
	water.mesh = pm
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.02, 0.05, 0.07)
	wm.metallic = 0.85
	wm.roughness = 0.05
	water.material_override = wm
	water.position = Vector3(0, 0.02, -29.5)
	add_child(water)

	# ánh sáng ấm bao trùm bến sông để hoa đăng không trôi trong hư vô
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.6, 0.3)
	glow.light_energy = 1.4
	glow.omni_range = 14.0
	glow.position = Vector3(0, 2.2, -28.5)
	add_child(glow)

	# hoa đăng trôi trên sông
	for i in range(13):
		var node := Node3D.new()
		var x := -5.5 + i * 0.92 + fmod(i * 2.7, 1.0)
		var z := -26.0 - fmod(i * 2.3, 5.0)
		node.position = Vector3(x, 0.06, z)
		var hub := MeshInstance3D.new()
		var hm := CylinderMesh.new()
		hm.top_radius = 0.09
		hm.bottom_radius = 0.11
		hm.height = 0.09
		hub.mesh = hm
		var hmat := StandardMaterial3D.new()
		hmat.albedo_color = Color(1.0, 0.8, 0.5)
		hmat.emission_enabled = true
		hmat.emission = Color(1.0, 0.62, 0.22)
		hmat.emission_energy_multiplier = 3.4
		hub.material_override = hmat
		hub.position.y = 0.05
		node.add_child(hub)
		for p in range(6):
			var petal := MeshInstance3D.new()
			var ps := SphereMesh.new()
			ps.radius = 0.085
			ps.height = 0.07
			petal.mesh = ps
			var petal_mat := StandardMaterial3D.new()
			petal_mat.albedo_color = Color(0.9, 0.45, 0.55)
			petal_mat.emission_enabled = true
			petal_mat.emission = Color(0.9, 0.35, 0.4)
			petal_mat.emission_energy_multiplier = 0.5
			petal_mat.roughness = 0.7
			petal.material_override = petal_mat
			var ang := TAU * p / 6.0
			petal.position = Vector3(cos(ang) * 0.13, 0.02, sin(ang) * 0.13)
			node.add_child(petal)
		add_child(node)
		_hoa_dang.append([node, float(i) * 1.7])


func open_gate() -> void:
	_gate_opening = true


func is_gate_passable() -> bool:
	return _gate_opening and _gate.position.y < -0.8


# thắp sáng cả phố khi phong ấn được giải
func light_up() -> void:
	var palette := [Color(1.0, 0.16, 0.08), Color(1.0, 0.62, 0.12), Color(1.0, 0.32, 0.08), Color(0.95, 0.25, 0.4)]
	for i in range(_hanging.size()):
		_light_lantern(_hanging[i], palette[i % palette.size()], 2.4)
	for pair in _string_lanterns:
		_light_lantern(pair[0], pair[1], 2.6)
	for win in _windows:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(1.0, 0.8, 0.5)
		m.emission_enabled = true
		m.emission = Color(1.0, 0.6, 0.25)
		m.emission_energy_multiplier = 0.9
		win.material_override = m
	# vài nguồn sáng ấm dọc ngõ cho mặt đất bắt sáng
	for z in [2.0, -6.0, -14.0]:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.6, 0.3)
		l.light_energy = 0.9
		l.omni_range = 8.0
		l.position = Vector3(0, 3.0, z)
		add_child(l)
	_env.ambient_light_energy = 0.78
	_env.volumetric_fog_density = 0.025


func update_world(delta: float) -> void:
	_time += delta
	if _gate_opening and _gate.position.y > -1.7:
		_gate.position.y -= delta * 1.1
	for pair in _hoa_dang:
		var node: Node3D = pair[0]
		var phase: float = pair[1]
		node.position.y = 0.06 + sin(_time * 1.2 + phase) * 0.02
		node.position.x += sin(_time * 0.25 + phase) * delta * 0.06


func clamp_player(pos: Vector3) -> Vector3:
	pos.x = clampf(pos.x, -ALLEY_HALF, ALLEY_HALF)
	if is_gate_passable():
		pos.z = clampf(pos.z, -25.0, 8.5)
		if pos.z < -19.2 and pos.z > -20.8:
			pos.x = clampf(pos.x, -1.1, 1.1)
	else:
		pos.z = clampf(pos.z, -19.2, 8.5)
	return pos
