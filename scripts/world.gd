# Môi trường dùng chung + ngõ phố Hội An (sân khấu của Chương 1).
# Mỗi chương một bảng màu — set_zone() chuyển fog/ambient/màu trời mượt theo thời gian.
extends Node3D

const Build := preload("res://scripts/build.gd")
const Textures := preload("res://scripts/textures.gd")
const Parts := preload("res://scripts/hoian_parts.gd")
const House01 := preload("res://scripts/house01.gd")
const House02 := preload("res://scripts/house02.gd")
const House03 := preload("res://scripts/house03.gd")
const House04 := preload("res://scripts/house04.gd")
const House05 := preload("res://scripts/house05.gd")

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
var _floor_rects: Array = []   # mặt sàn đi được: đế nhà, bậc tam cấp (rect thế giới)
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
	# phố Hội An lát gạch PHẲNG — normal hạ thấp để hết cảm giác lồi lõm ổ gà
	var gmat := Build.pbr("res://assets/textures/PavingStones138", 0.6, Color(0.68, 0.62, 0.58), 0.35)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(110, 76)
	ground.mesh = pm
	ground.material_override = gmat
	ground.position = Vector3(0, 0, -11)
	add_child(ground)


func _build_houses() -> void:
	# ngõ không tên (C1) — hai dãy nhà quay mặt vào ngõ
	for i in range(4):
		var z := 6.0 - i * 6.0
		_house(Vector3(FACADE_X, 0, z), 0.0, i)
		_house(Vector3(-FACADE_X, 0, z), PI, i + 3)
	# đồ ngõ: chậu cây nép chân thềm, xe đạp dựa tường, bụi chuối góc cuối ngõ
	Parts.pot_plant(self, Vector3(4.55, 0, 4.0), 3, 0.9)
	Parts.pot_plant(self, Vector3(-4.55, 0, -4.2), 0, 0.85)
	Parts.bicycle(self, Vector3(4.6, 0, -8.0), PI / 2.0, -0.12)
	Parts.banana_clump(self, Vector3(-3.6, 0, -17.4), 1.2)
	_build_main_street()


# ---------- mặt sàn đi được (đế nhà + tam cấp) ----------
func _reg_floor(pos: Vector3, yrot: float, x0: float, x1: float, z0: float, z1: float, y: float) -> void:
	var t := Transform3D(Basis(Vector3.UP, yrot), pos)
	var p0 := t * Vector3(x0, 0, z0)
	var p1 := t * Vector3(x1, 0, z1)
	_floor_rects.append({
		"x0": minf(p0.x, p1.x), "x1": maxf(p0.x, p1.x),
		"z0": minf(p0.z, p1.z), "z1": maxf(p0.z, p1.z), "y": y,
	})


# cao độ mặt sàn dưới chân (0 = mặt đường) — người chơi bước LÊN bậc/thềm thật
func ground_height(pos: Vector3) -> float:
	var h := 0.0
	for r in _floor_rects:
		if pos.x >= r["x0"] and pos.x <= r["x1"] and pos.z >= r["z0"] and pos.z <= r["z1"]:
			h = maxf(h, r["y"])
	return h


# đứng sát thềm nhà ai đó? — để Minh cất đèn, tránh phiền gia chủ ban đêm
func near_house(pos: Vector3) -> bool:
	for r in _floor_rects:
		if pos.x >= r["x0"] - 1.3 and pos.x <= r["x1"] + 1.3 and pos.z >= r["z0"] - 1.3 and pos.z <= r["z1"] + 1.3:
			return true
	return false


# phố Trần Phú chạy Đông-Tây ngang đầu ngõ + Chùa Cầu đầu Tây, chợ đầu Đông
func _build_main_street() -> void:
	# dãy phố 6m/căn xoay vòng 5 mẫu nhà ref — mặt tiền liền kề liên tục
	for k in range(12):
		var x := -33.0 + k * 6.0
		_house(Vector3(x, 0, 14.2), -PI / 2.0, k)            # dãy Bắc, mặt quay Nam
		if absf(x) > 7.0:                                    # chừa miệng ngõ ở dãy Nam
			_house(Vector3(x, 0, 7.9), PI / 2.0, k + 2)
	# ---- đồ phố (ref-07/08/09): xe đạp dựa hiên, xe Cub đậu, chậu cây trước thềm
	# (tọa độ né các vùng tam cấp tại tâm nhà C = -33 + 6k, C ± 1.55) ----
	Parts.bicycle(self, Vector3(-17.3, 0, 13.55), 0.0, -0.12)
	Parts.bicycle(self, Vector3(30.6, 0, 13.5), 0.0, -0.1)
	Parts.motorbike(self, Vector3(18.9, 0, 13.1), 0.18)
	Parts.motorbike(self, Vector3(-24.3, 0, 13.25), -0.25)
	for pp in [[-6.0, 13.6, 2], [-29.5, 13.6, 3], [5.8, 13.55, 1], [-18.6, 13.6, 0],
			[12.3, 13.6, 3], [24.0, 13.6, 1], [29.3, 13.6, 0]]:
		Parts.pot_plant(self, Vector3(pp[0], 0, pp[1]), int(pp[2]), 1.0)
	for pp2 in [[-11.2, 8.5, 3], [11.8, 8.5, 0], [23.5, 8.55, 2], [-29.8, 8.5, 1]]:
		Parts.pot_plant(self, Vector3(pp2[0], 0, pp2[1]), int(pp2[2]), 0.9)
	# bụi chuối chen cạnh gốc cây — "có nơi có cây chuối"
	Parts.banana_clump(self, Vector3(-11.3, 0, 13.05), 1.3)
	Parts.banana_clump(self, Vector3(17.4, 0, 13.0), 1.5)
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
	# cây xanh phá đường mái — phố thật luôn có tán cây chen giữa nhà
	for tp in [Vector3(-11.9, 0, 12.9), Vector3(23.0, 0, 12.9)]:
		Build.cyl(self, 0.14, 0.2, 2.8, tp + Vector3(0, 1.4, 0), Build.mat(Color(0.16, 0.12, 0.09), 0.95), 8)
		for fb in range(4):
			var off := Vector3(sin(fb * 1.9) * 0.65, 3.1 + (fb % 2) * 0.55, cos(fb * 1.9) * 0.55)
			Build.ball(self, 0.62 + 0.18 * (fb % 2), 1.1, tp + off, Build.mat(Color(0.09, 0.16, 0.07), 0.95))
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
	# CHỢ HỘI AN — nhà lồng cao phía TÂY BẮC sau dãy Bắc (đúng sơ đồ tổng thể),
	# mái nhô trên đường mái phố, ánh đèn ấm hắt lên — thấy được từ ngoài phố
	var market := Node3D.new()
	market.position = Vector3(-20, 0, 26)
	add_child(market)
	for cxk in range(4):
		for czk in range(2):
			Build.box(market, Vector3(0.3, 6.0, 0.3), Vector3(-4.5 + cxk * 3.0, 3.0, -2.0 + czk * 4.0), dark)
	Build.box(market, Vector3(11.0, 0.2, 6.5), Vector3(0, 6.2, 0), dark)
	for kk in [-1.0, 1.0]:
		Build.box(market, Vector3(11.2, 0.12, 3.5), Vector3(0, 6.7, kk * 1.7), dark).rotation.x = kk * 0.3
	var mglow := OmniLight3D.new()
	mglow.light_color = Color(1.0, 0.55, 0.25)
	mglow.light_energy = 0.8
	mglow.omni_range = 10.0
	mglow.position = Vector3(-20, 3.5, 25)
	add_child(mglow)


# nhà phố Hội An: xoay vòng 5 MẪU NHÀ dựng theo ảnh ref (house01..house05) —
# mẫu + tuổi nhà chọn deterministic theo idx nên không nhà nào giống nhà nào.
# Mặt tiền tại local x=0 quay về -x, thân kéo về +x — dùng cho cả ngõ lẫn phố chính.
func _house(pos: Vector3, yrot: float, idx: int) -> void:
	var models := [House01, House02, House03, House04, House05]
	var ms: GDScript = models[idx % 5]
	var age := 0.2 + 0.55 * fposmod(idx * 0.618, 1.0)
	var out := {}
	var a: Node3D = ms.build(self, pos, yrot, age, out)
	for l in out.get("lanterns", []):
		_hanging.append(l)
	for w in out.get("windows", []):
		_windows.append(w)
	# mặt sàn đi được: đế + từng bậc tam cấp — người chơi bước lên thềm thật
	for r in Parts.floor_rects(6.0, 5.0, ms.H_BASE):
		_reg_floor(pos, yrot, r["x0"], r["x1"], r["z0"], r["z1"], r["y"])
	# hoa giấy rủ góc hiên — mỗi ba nhà một giàn
	if (idx * 11) % 3 == 0:
		var base_p := Vector3(-0.55, ms.H_BASE + 2.3, 2.5)
		for fi in range(16):
			var fx := sin(fi * 2.39 + idx) * 0.3
			var fy := -absf(sin(fi * 1.7)) * 0.7
			var fz := cos(fi * 2.39 + idx) * 0.3
			var fc := Color(0.78, 0.12, 0.4) if fi % 4 != 0 else Color(0.1, 0.22, 0.08)
			Build.ball(a, 0.055 + 0.03 * (fi % 2), 0.1, base_p + Vector3(fx, fy, fz), Build.mat(fc, 0.85))

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
		var on_floor := ground_height(pos) > 0.05
		# nhà nào có thềm thì bước hẳn lên thềm trước cửa, không thì dừng trước hiên
		var zmax := 14.25 if ground_height(Vector3(pos.x, 0, 14.1)) > 0.3 else 13.6
		pos.z = clampf(pos.z, 8.0, zmax)
		# ngoài miệng ngõ thì không xuống được dãy nhà Nam (trừ khi đang đứng trên bậc)
		if absf(pos.x) > ALLEY_HALF and pos.z < 8.4 and not on_floor:
			pos.z = 8.4
		pos.y = ground_height(pos)
		return pos
	# trong ngõ: kẹp như cũ, vào ngõ rồi thì kẹp ngang theo ngõ
	pos.x = clampf(pos.x, -ALLEY_HALF, ALLEY_HALF)
	if is_gate_passable():
		pos.z = clampf(pos.z, -24.0, 13.6)
		if pos.z < -19.2 and pos.z > -20.8:
			pos.x = clampf(pos.x, -1.1, 1.1)
	else:
		pos.z = clampf(pos.z, -19.2, 13.6)
	pos.y = ground_height(pos)
	return pos
