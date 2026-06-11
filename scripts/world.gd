# Môi trường dùng chung + ngõ phố Hội An (sân khấu của Chương 1).
# Mỗi chương một bảng màu — set_zone() chuyển fog/ambient/màu trời mượt theo thời gian.
extends Node3D

const Build := preload("res://scripts/build.gd")
const Textures := preload("res://scripts/textures.gd")

const ALLEY_HALF := 5.0
const FACADE_X := 5.35

const ZONES := {
	"c1": {"bg": Color(0.015, 0.025, 0.055), "amb": Color(0.16, 0.2, 0.32), "amb_e": 0.6,
		"fog": Color(0.045, 0.06, 0.11), "fog_d": 0.012, "vol": 0.035},
	"c1_lit": {"bg": Color(0.02, 0.03, 0.06), "amb": Color(0.2, 0.22, 0.3), "amb_e": 0.78,
		"fog": Color(0.06, 0.06, 0.1), "fog_d": 0.01, "vol": 0.025},
	"c2": {"bg": Color(0.006, 0.018, 0.028), "amb": Color(0.14, 0.3, 0.38), "amb_e": 1.35,
		"fog": Color(0.025, 0.07, 0.09), "fog_d": 0.015, "vol": 0.05},
	"c3": {"bg": Color(0.004, 0.003, 0.002), "amb": Color(0.24, 0.19, 0.12), "amb_e": 0.95,
		"fog": Color(0.035, 0.025, 0.015), "fog_d": 0.013, "vol": 0.04},
	"c3_dark": {"bg": Color(0.002, 0.002, 0.002), "amb": Color(0.06, 0.05, 0.04), "amb_e": 0.25,
		"fog": Color(0.01, 0.01, 0.01), "fog_d": 0.02, "vol": 0.05},
	"c4": {"bg": Color(0.015, 0.008, 0.035), "amb": Color(0.26, 0.19, 0.38), "amb_e": 1.1,
		"fog": Color(0.05, 0.035, 0.09), "fog_d": 0.011, "vol": 0.035},
	"c5": {"bg": Color(0.004, 0.003, 0.01), "amb": Color(0.16, 0.14, 0.26), "amb_e": 1.05,
		"fog": Color(0.015, 0.012, 0.03), "fog_d": 0.005, "vol": 0.045},
}

var _env: Environment
var _zone_target: Dictionary = ZONES["c1"]
var _gate: MeshInstance3D
var _gate_opening := false
var _hanging: Array = []
var _string_lanterns: Array = []
var _windows: Array = []
var _moon_ball: MeshInstance3D
var _time := 0.0
var blackout := 0.0    # >0: mọi đèn phụt tắt một nhịp (beat kinh dị)

var _plaster: StandardMaterial3D
var _wood: StandardMaterial3D
var _darkwood := Build.mat(Color(0.11, 0.075, 0.05), 0.85)
var _moss := Build.mat(Color(0.11, 0.13, 0.09), 0.98)
var _lacquer := Build.mat(Color(0.32, 0.06, 0.04), 0.55)   # sơn ta đỏ sậm


func _ready() -> void:
	# vữa vôi vàng nghệ + gỗ — PBR thật (ambientCG, CC0), normal map bắt ánh đèn nổi khối
	_plaster = Build.pbr("res://assets/textures/Plaster001", 0.5, Color(0.82, 0.58, 0.27), 1.4)
	_wood = Build.pbr("res://assets/textures/WoodFloor043", 0.85, Color(0.5, 0.38, 0.27), 1.2)
	_build_environment()
	_build_ground()
	_build_houses()
	_build_lantern_strings()
	_build_end_wall()


func _build_environment() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.tonemap_mode = Environment.TONE_MAPPER_ACES
	_env.tonemap_exposure = 1.0
	_env.glow_enabled = true
	_env.glow_intensity = 1.0
	_env.glow_bloom = 0.12
	_env.fog_enabled = true
	_env.volumetric_fog_enabled = true
	_env.volumetric_fog_albedo = Color(0.55, 0.6, 0.75)
	_env.ssr_enabled = true
	_env.ssao_enabled = true
	_env.ssao_intensity = 1.6
	_env.sdfgi_enabled = true
	_env.sdfgi_bounce_feedback = 0.3
	_apply_zone(ZONES["c1"], 1.0)
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)

	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.65, 0.9)
	moon.light_energy = 0.25
	moon.shadow_enabled = true
	moon.rotation_degrees = Vector3(-38, 28, 0)
	add_child(moon)

	_moon_ball = Build.ball(self, 2.2, 4.4, Vector3(-22, 19, -55), null)
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.albedo_color = Color(0.85, 0.9, 1.0)
	mm.emission_enabled = true
	mm.emission = Color(0.8, 0.85, 1.0)
	mm.emission_energy_multiplier = 2.0
	_moon_ball.material_override = mm


func set_zone(zone: String) -> void:
	_zone_target = ZONES[zone]


func set_moon_visible(v: bool) -> void:
	_moon_ball.visible = v


func _apply_zone(z: Dictionary, w: float) -> void:
	_env.background_color = _env.background_color.lerp(z["bg"], w)
	_env.ambient_light_color = _env.ambient_light_color.lerp(z["amb"], w)
	_env.ambient_light_energy = lerpf(_env.ambient_light_energy, z["amb_e"], w)
	_env.fog_light_color = _env.fog_light_color.lerp(z["fog"], w)
	_env.fog_density = lerpf(_env.fog_density, z["fog_d"], w)
	_env.volumetric_fog_density = lerpf(_env.volumetric_fog_density, z["vol"], w)


func _build_ground() -> void:
	var gmat := Build.pbr("res://assets/textures/PavingStones138", 0.42, Color(0.72, 0.68, 0.64), 1.5)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(110, 76)
	ground.mesh = pm
	ground.material_override = gmat
	ground.position = Vector3(0, 0, -11)
	add_child(ground)


func _build_houses() -> void:
	# ngõ không tên (C1) — hai dãy nhà quay mặt vào ngõ
	for i in range(7):
		var z := 6.0 - i * 4.0
		var h := 2.9 + (i % 3) * 0.5
		_house(Vector3(FACADE_X, 0, z), 0.0, h, i)
		_house(Vector3(-FACADE_X, 0, z), PI, h, i)
	_build_main_street()


# phố Trần Phú chạy Đông-Tây ngang đầu ngõ + Chùa Cầu đầu Tây, chợ đầu Đông
func _build_main_street() -> void:
	var i := 0
	for k in range(9):
		var x := -34.0 + k * 8.5
		var h_n := 2.9 + ((k + 1) % 3) * 0.5
		_house(Vector3(x + 2.0, 0, 14.2), -PI / 2.0, h_n, k)        # dãy Bắc, mặt quay Nam
		if absf(x) > 7.0:                                            # chừa miệng ngõ ở dãy Nam
			_house(Vector3(x, 0, 7.9), PI / 2.0, 2.9 + (k % 3) * 0.5, k + 1)
		i += 1
	# dây đèn giăng ngang phố
	var palette := [Color(1.0, 0.16, 0.08), Color(1.0, 0.62, 0.12), Color(0.95, 0.25, 0.4)]
	var idx := 0
	for sx in [-26.0, -12.0, 12.0, 26.0]:
		var prev := Vector3.ZERO
		for j in range(5):
			var z := 8.6 + j * 1.3
			var y := 3.6 - 0.5 * (1.0 - pow((z - 11.2) / 2.6, 2.0))
			var top := Vector3(sx, y + 0.14, z)
			if j > 0:
				var mid := (prev + top) * 0.5
				var seg := Build.box(self, Vector3(0.015, 0.015, prev.distance_to(top)), mid, Build.mat(Color(0.05, 0.045, 0.04)))
				seg.rotation.x = atan2(top.y - prev.y, top.z - prev.z)
			prev = top
			_string_lanterns.append([Build.lantern(self, 0.13, 0.24, Vector3(sx, y, z)), palette[idx % palette.size()]])
			idx += 1
	# màn sương phong ấn hai đầu phố
	for mx in [-39.0, 39.0]:
		var mist := Build.box(self, Vector3(0.4, 7.0, 14.0), Vector3(mx, 3.5, 11.0), null)
		var mm := StandardMaterial3D.new()
		mm.albedo_color = Color(0.55, 0.62, 0.78, 0.055)
		mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mist.material_override = mm
		mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# CHÙA CẦU — bóng sau sương đầu Tây (phiên bản thật của đấu trường chương 5)
	var bridge := Node3D.new()
	bridge.position = Vector3(-46, 0, 11)
	add_child(bridge)
	var dark := Build.mat(Color(0.1, 0.08, 0.07), 0.9)
	for s in range(5):
		var sx := -3.0 + s * 1.5
		Build.box(bridge, Vector3(1.6, 0.18, 3.2), Vector3(sx, 0.7 + 0.45 * (1.0 - pow(sx / 3.0, 2.0)), 0), dark)
	for sx in [-2.8, 2.8]:
		for sz in [-1.3, 1.3]:
			Build.box(bridge, Vector3(0.2, 2.4, 0.2), Vector3(sx, 2.2, sz), dark)
	Build.box(bridge, Vector3(8.0, 0.2, 4.2), Vector3(0, 3.5, 0), dark)
	for kk in [-1.0, 1.0]:
		Build.box(bridge, Vector3(8.2, 0.1, 2.3), Vector3(0, 3.9, kk * 1.15), dark).rotation.x = kk * 0.36
	var altar_glow := OmniLight3D.new()
	altar_glow.light_color = Color(1.0, 0.4, 0.15)
	altar_glow.light_energy = 0.6
	altar_glow.omni_range = 5.0
	altar_glow.position = Vector3(-46, 2.0, 10)
	add_child(altar_glow)
	# CHỢ HỘI AN — nhà lồng sau sương đầu Đông
	var market := Node3D.new()
	market.position = Vector3(46, 0, 11)
	add_child(market)
	for cxk in range(4):
		for czk in range(2):
			Build.box(market, Vector3(0.25, 3.2, 0.25), Vector3(-4.5 + cxk * 3.0, 1.6, -2.0 + czk * 4.0), dark)
	Build.box(market, Vector3(11.0, 0.2, 6.5), Vector3(0, 3.4, 0), dark)
	for kk in [-1.0, 1.0]:
		Build.box(market, Vector3(11.2, 0.1, 3.5), Vector3(0, 3.85, kk * 1.7), dark).rotation.x = kk * 0.3
	var mglow := OmniLight3D.new()
	mglow.light_color = Color(1.0, 0.55, 0.25)
	mglow.light_energy = 0.5
	mglow.omni_range = 7.0
	mglow.position = Vector3(45, 2.2, 11)
	add_child(mglow)


# nhà ống Hội An dựng trong KHÔNG GIAN CỤC BỘ: mặt tiền tại local x=0 quay về -x,
# thân nhà kéo về +x. Đặt qua anchor xoay được — dùng cho cả ngõ lẫn phố chính.
func _house(pos: Vector3, yrot: float, h: float, idx: int) -> void:
	var a := Node3D.new()
	a.position = pos
	a.rotation.y = yrot
	add_child(a)
	Build.box(a, Vector3(3.0, h, 3.6), Vector3(1.55, h / 2.0, 0), _plaster)
	Build.box(a, Vector3(3.04, 0.42, 3.64), Vector3(1.55, 0.21, 0), _moss)
	for dz in [-1.7, -0.6, 0.6, 1.7]:
		Build.box(a, Vector3(0.13, h, 0.13), Vector3(0, h / 2.0, dz), _wood)
	for dz in [-0.6, 0.6]:
		Build.box(a, Vector3(0.025, 1.5, 0.3), Vector3(-0.08, 1.5, dz), _lacquer)
	# cửa thượng song hạ bản + mắt cửa
	Build.box(a, Vector3(0.06, 0.95, 1.1), Vector3(0.02, 0.48, 0), _wood)
	for bz in range(5):
		Build.cyl(a, 0.022, 0.022, 0.85, Vector3(0.02, 1.42, -0.44 + bz * 0.22), _darkwood, 6)
	Build.box(a, Vector3(0.08, 0.1, 1.2), Vector3(0.02, 1.92, 0), _darkwood)
	for ez in [-0.32, 0.32]:
		Build.door_eye(a, Vector3(-0.04, 2.14, ez), 1.0)
	# cửa sổ chấn song gác
	var win := Build.box(a, Vector3(0.06, 0.65, 0.95), Vector3(0.03, h - 0.75, 1.0), Build.mat(Color(0.07, 0.055, 0.045), 0.8))
	_windows.append(win)
	for bz in range(4):
		Build.cyl(a, 0.018, 0.018, 0.6, Vector3(-0.01, h - 0.75, 0.62 + bz * 0.25), _darkwood, 6)
	# ban công nhà hai tầng
	if h > 3.3:
		var by := h - 1.35
		Build.box(a, Vector3(0.6, 0.08, 2.2), Vector3(-0.3, by, -0.2), _wood)
		Build.box(a, Vector3(0.55, 0.06, 2.1), Vector3(-0.32, by + 0.62, -0.2), _darkwood)
		for bz in range(6):
			Build.cyl(a, 0.022, 0.022, 0.6, Vector3(-0.55, by + 0.32, -1.2 + bz * 0.4), _darkwood, 6)
		_hanging.append(Build.lantern(a, 0.13, 0.24, Vector3(-0.6, by - 0.32, -1.3)))
	# mái âm dương + đòn dông + đầu đao
	for k in [-1.0, 1.0]:
		var slope := Node3D.new()
		slope.position = Vector3(1.55 + k * 0.95, h + 0.42, 0)
		slope.rotation.z = -k * 0.42
		a.add_child(slope)
		var slab := BoxMesh.new()
		slab.size = Vector3(2.1, 0.07, 4.0)
		var slab_mi := MeshInstance3D.new()
		slab_mi.mesh = slab
		slab_mi.material_override = Build.pbr("res://assets/textures/RoofingTiles013A", 0.6, Color(0.5, 0.47, 0.5), 1.2)
		slope.add_child(slab_mi)
		Build.tile_rows(slope, 2.1, 4.0)
	Build.cyl(a, 0.09, 0.09, 4.05, Vector3(1.55, h + 0.9, 0), _darkwood).rotation.x = PI / 2.0
	for ke in [-1.0, 1.0]:
		var horn := Build.cyl(a, 0.01, 0.09, 0.5, Vector3(1.55, h + 1.0, ke * 2.0), _darkwood, 8)
		horn.rotation.x = -ke * 0.9
	_hanging.append(Build.lantern(a, 0.16, 0.3, Vector3(-0.15, h - 0.45, -1.2)))


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
				var mid := (prev + top) * 0.5
				var seg := Build.box(self, Vector3(prev.distance_to(top), 0.015, 0.015), mid, Build.mat(Color(0.05, 0.045, 0.04)))
				seg.rotation.z = atan2(top.y - prev.y, top.x - prev.x)
			prev = top
			_string_lanterns.append([Build.lantern(self, 0.13, 0.24, Vector3(x, y, z)), palette[idx % palette.size()]])
			idx += 1


func _build_end_wall() -> void:
	Build.box(self, Vector3(4.5, 5.0, 0.6), Vector3(-3.75, 2.5, -20), _plaster)
	Build.box(self, Vector3(4.5, 5.0, 0.6), Vector3(3.75, 2.5, -20), _plaster)
	Build.box(self, Vector3(3.0, 2.1, 0.6), Vector3(0, 3.95, -20), _plaster)
	Build.box(self, Vector3(0.5, 3.2, 0.75), Vector3(-1.7, 1.6, -20), Build.mat(Color(0.28, 0.27, 0.26)))
	Build.box(self, Vector3(0.5, 3.2, 0.75), Vector3(1.7, 1.6, -20), Build.mat(Color(0.28, 0.27, 0.26)))
	_gate = Build.box(self, Vector3(3.0, 2.9, 0.25), Vector3(0, 1.45, -20), _wood)
	for dy in [-0.7, 0.7]:
		var batten := BoxMesh.new()
		batten.size = Vector3(3.0, 0.18, 0.08)
		var bm := MeshInstance3D.new()
		bm.mesh = batten
		bm.position = Vector3(0, dy, -0.17)
		bm.material_override = _darkwood
		_gate.add_child(bm)


func open_gate() -> void:
	_gate_opening = true


func is_gate_passable() -> bool:
	return _gate_opening and _gate.position.y < -0.8


func light_up() -> void:
	var palette := [Color(1.0, 0.16, 0.08), Color(1.0, 0.62, 0.12), Color(1.0, 0.32, 0.08), Color(0.95, 0.25, 0.4)]
	for i in range(_hanging.size()):
		Build.light_lantern(_hanging[i], palette[i % palette.size()], 2.4)
	for pair in _string_lanterns:
		Build.light_lantern(pair[0], pair[1], 2.6)
	for win in _windows:
		win.material_override = Build.emis(Color(1.0, 0.8, 0.5), Color(1.0, 0.6, 0.25), 0.9)
	for z in [2.0, -6.0, -14.0]:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.6, 0.3)
		l.light_energy = 0.9
		l.omni_range = 8.0
		l.position = Vector3(0, 3.0, z)
		add_child(l)
	set_zone("c1_lit")


# đèn cả phố phụt tắt một nhịp rồi sáng lại — "có thứ gì vừa đi qua"
func blackout_beat() -> void:
	blackout = 0.7


func update_world(delta: float) -> void:
	_time += delta
	if _gate_opening and _gate.position.y > -1.7:
		_gate.position.y -= delta * 1.1
	var w := 1.0 - pow(0.05, delta)
	if blackout > 0.0:
		blackout -= delta
		_apply_zone(ZONES["c3_dark"], 0.6)
	else:
		_apply_zone(_zone_target, w)


func clamp_alley(pos: Vector3) -> Vector3:
	# trên phố Trần Phú: đi ngang thoải mái giữa hai màn sương
	if pos.z > 8.0:
		pos.x = clampf(pos.x, -37.5, 37.5)
		pos.z = clampf(pos.z, 8.0, 13.6)
		# ngoài miệng ngõ thì không xuống được dãy nhà Nam
		if absf(pos.x) > ALLEY_HALF and pos.z < 8.4:
			pos.z = 8.4
		return pos
	# trong ngõ: kẹp như cũ, vào ngõ rồi thì kẹp ngang theo ngõ
	pos.x = clampf(pos.x, -ALLEY_HALF, ALLEY_HALF)
	if is_gate_passable():
		pos.z = clampf(pos.z, -24.0, 13.6)
		if pos.z < -19.2 and pos.z > -20.8:
			pos.x = clampf(pos.x, -1.1, 1.1)
	else:
		pos.z = clampf(pos.z, -19.2, 13.6)
	return pos
