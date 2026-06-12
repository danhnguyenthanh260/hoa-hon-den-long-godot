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
	_plaster = Build.pbr("res://assets/textures/Plaster001", 0.5, Color(0.86, 0.7, 0.44), 1.4)
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
	# đồ ngõ: chậu cây nép chân thềm cạnh cửa (tâm nhà ± 2.2), xe đạp dựa tường,
	# bụi chuối dồn hẳn vào GÓC cuối ngõ sát tường chắn — chừa trống lối đi
	Parts.pot_plant(self, Vector3(4.6, 0, 3.8), 3, 0.9)
	Parts.pot_plant(self, Vector3(-4.6, 0, -3.8), 0, 0.85)
	Parts.bicycle(self, Vector3(4.6, 0, -8.0), PI / 2.0, -0.12)
	Parts.banana_clump(self, Vector3(-3.5, 0, -18.8), 1.2, Vector3(-0.55, 0, -0.83))
	_build_main_street()
	_build_phase2_streets()
	_build_phase3_river()
	_build_phase5_landmarks()


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
		if x < 15.0:   # x≥15 dành cho hội quán Quảng Đông (x=18) + Phúc Kiến (x=30)
			_house(Vector3(x, 0, 14.2), -PI / 2.0, k)        # dãy Bắc, mặt quay Nam
		if absf(x) > 7.0:                                    # chừa miệng ngõ ở dãy Nam
			_house(Vector3(x, 0, 7.9), PI / 2.0, k + 2)
	# ---- đồ phố (ref-07/08/09/10): xe dựa hiên, chậu cảnh NÉP CHÂN THỀM hai bên
	# cửa (C ± 2.2 với C = -33 + 6k là tâm nhà), chuối nép góc trụ nhà —
	# lòng đường + vùng tam cấp (C ± 1.55) + trụ đèn (x = -30..30 bước 12, z 10.2)
	# luôn trống ----
	Parts.bicycle(self, Vector3(-17.3, 0, 13.55), 0.0, -0.12)
	Parts.bicycle(self, Vector3(30.6, 0, 13.5), 0.0, -0.1)
	Parts.motorbike(self, Vector3(18.9, 0, 13.1), 0.18)
	Parts.motorbike(self, Vector3(-24.3, 0, 13.25), -0.25)
	for pp in [[-29.2, 13.55, 2], [-18.8, 13.55, 3], [-11.2, 13.55, 1], [-6.8, 13.55, 0],
			[5.2, 13.55, 3], [11.2, 13.55, 1], [29.2, 13.55, 0]]:
		Parts.pot_plant(self, Vector3(pp[0], 0, pp[1]), int(pp[2]), 1.0)
	for pp2 in [[-11.2, 8.45, 3], [11.2, 8.45, 0], [23.2, 8.45, 2], [-29.2, 8.45, 1]]:
		Parts.pot_plant(self, Vector3(pp2[0], 0, pp2[1]), int(pp2[2]), 0.9)
	# bụi chuối nép góc trụ giữa hai nhà, tàu lá phía tường tự ngắn (ref-10)
	Parts.banana_clump(self, Vector3(-30.1, 0, 13.3), 1.3, Vector3(0, 0, 1))
	Parts.banana_clump(self, Vector3(17.9, 0, 13.3), 1.5, Vector3(0, 0, 1))
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
	# cây xanh phá đường mái — thân vỏ cây thật + cành rẽ + tán texture + ụ đất.
	# Đặt tại RANH hai nhà (x=0 đối diện miệng ngõ, x=24), né dây đèn (±12/±26)
	# và trụ đèn (-30..30 bước 12); tán z tối đa 13.5 < mặt tiền 14.2.
	for tp in [Vector3(0.0, 0, 12.1), Vector3(24.0, 0, 12.1)]:
		Build.ball(self, 0.5, 0.2, tp, Build.pbr("res://assets/textures/MudLeaves01", 0.9, Color(0.85, 0.8, 0.75), 1.3))
		var bark := Build.pbr("res://assets/textures/Bark02", 1.2, Color(0.8, 0.72, 0.6), 1.5)
		Build.cyl(self, 0.13, 0.2, 2.9, tp + Vector3(0, 1.45, 0), bark, 8)
		for bk in range(3):
			var ba := bk * 2.1 + 0.5
			var br := Build.cyl(self, 0.05, 0.09, 1.3, tp + Vector3(cos(ba) * 0.45, 3.15, sin(ba) * 0.45), bark, 6)
			br.rotation.z = cos(ba) * 0.55
			br.rotation.x = -sin(ba) * 0.55
		# hue lệch theo cây + tán = lõi ball + card lá rách viền (cross-plane) xòe quanh
		var hv := 0.88 + 0.24 * fposmod(tp.x * 0.737 + tp.z * 0.311, 1.0)
		var lm := Build.leaf_mat("ForestLeaves03", Color(0.5, 0.7, 0.4) * hv, 0.05, 1.0, 0.55)
		var cm := Build.leaf_mat("ForestLeaves03", Color(0.55, 0.78, 0.42) * hv, 0.05, 1.0, 0.8, 0.5)
		for fb in range(7):
			var off := Vector3(sin(fb * 1.9) * 0.75, 3.4 + 0.45 * sin(fb * 2.7), cos(fb * 1.9) * 0.7)
			Build.ball(self, 0.45 + 0.08 * (fb % 3), 0.8, tp + off, lm)
		for cb in range(8):
			var coff := Vector3(sin(cb * 2.4) * 0.85, 3.45 + 0.5 * sin(cb * 1.7), cos(cb * 2.4) * 0.8)
			var card := Build.leaf_card(self, Vector2(1.5, 1.15), tp + coff, cm)
			card.rotation = Vector3(fposmod(cb * 0.97, 1.0) - 0.5, cb * 0.79, fposmod(cb * 0.61, 0.8) - 0.4)
	# màn sương phong ấn hai đầu phố
	for mx in [-39.0, 39.0]:
		var mist := Build.box(self, Vector3(0.4, 7.0, 14.0), Vector3(mx, 3.5, 11.0), null)
		var mm := StandardMaterial3D.new()
		mm.albedo_color = Color(0.55, 0.62, 0.78, 0.055)
		mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mist.material_override = mm
		mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_build_chua_cau()


# Phase 2 — Nguyễn Thái Học + Lê Lợi + Hoàng Văn Thụ
# Đặt hoàn toàn ở |x|>11 để tránh hành lang ngõ (|x|≤5) và tường C2 (x=±8).
func _build_phase2_streets() -> void:
	# ── Nguyễn Thái Học: E-W trục song song Trần Phú, cách ~40m về Nam ──
	# north row z=-28.5 (mặt quay Nam), south row z=-35.0 (mặt quay Bắc)
	for k in range(12):
		var x := -33.0 + k * 6.0
		if absf(x) > 11.0:
			_house(Vector3(x, 0, -28.5), -PI / 2.0, k + 2)
			_house(Vector3(x, 0, -35.0), PI / 2.0, k + 4)
	# dây đèn NTH — cùng hướng Trần Phú nhưng màu ấm hơn
	var nth_pal := [Color(1.0, 0.5, 0.12), Color(1.0, 0.22, 0.07), Color(0.9, 0.38, 0.8)]
	var li := 0
	for sx in [-26.0, -14.0, 14.0, 26.0]:
		var prev2 := Vector3.ZERO
		for j in range(5):
			var z := -29.2 + j * 1.2
			var y := 3.3 - 0.45 * (1.0 - pow((z + 31.6) / 2.4, 2.0))
			var top := Vector3(sx, y + 0.12, z)
			if j > 0:
				var mid := (prev2 + top) * 0.5
				var seg := Build.box(self, Vector3(0.015, 0.015, prev2.distance_to(top)), mid, Build.mat(Color(0.05, 0.04, 0.035)))
				seg.rotation.x = atan2(top.y - prev2.y, top.z - prev2.z)
			prev2 = top
			_string_lanterns.append([Build.lantern(self, 0.12, 0.22, Vector3(sx, y, z)), nth_pal[li % nth_pal.size()]])
			li += 1
	# chậu cảnh NTH
	for pp in [[-26.8, -28.55, 3], [-20.8, -28.55, 1], [20.8, -28.55, 0], [26.8, -28.55, 2],
			[-17.2, -34.95, 3], [17.2, -34.95, 1]]:
		Parts.pot_plant(self, Vector3(pp[0], 0, pp[1]), int(pp[2]), 0.92)
	# cây xanh tại ranh nhà (x=±18, giữa đường NTH)
	for tp in [Vector3(-18.0, 0, -31.8), Vector3(18.0, 0, -31.8)]:
		Build.ball(self, 0.45, 0.18, tp,
				Build.pbr("res://assets/textures/MudLeaves01", 0.9, Color(0.85, 0.8, 0.75), 1.3))
		var bark := Build.pbr("res://assets/textures/Bark02", 1.2, Color(0.8, 0.72, 0.6), 1.5)
		Build.cyl(self, 0.11, 0.17, 2.5, tp + Vector3(0, 1.25, 0), bark, 8)
		for bk in range(3):
			var ba := bk * 2.1 + 0.3
			var br := Build.cyl(self, 0.045, 0.08, 1.1,
					tp + Vector3(cos(ba) * 0.4, 2.75, sin(ba) * 0.4), bark, 6)
			br.rotation.z = cos(ba) * 0.5
			br.rotation.x = -sin(ba) * 0.5
		var hv := 0.88 + 0.24 * fposmod(tp.x * 0.737 + tp.z * 0.311, 1.0)
		var lm := Build.leaf_mat("ForestLeaves03", Color(0.5, 0.7, 0.4) * hv, 0.05, 1.0, 0.55)
		var cm2 := Build.leaf_mat("ForestLeaves03", Color(0.55, 0.78, 0.42) * hv, 0.05, 1.0, 0.8, 0.5)
		for fb in range(6):
			var off := Vector3(sin(fb * 1.9) * 0.65, 2.95 + 0.4 * sin(fb * 2.7), cos(fb * 1.9) * 0.62)
			Build.ball(self, 0.4 + 0.07 * (fb % 3), 0.72, tp + off, lm)
		for cb in range(7):
			var coff := Vector3(sin(cb * 2.4) * 0.72, 3.0 + 0.42 * sin(cb * 1.7), cos(cb * 2.4) * 0.68)
			var card := Build.leaf_card(self, Vector2(1.3, 1.0), tp + coff, cm2)
			card.rotation = Vector3(fposmod(cb * 0.97, 1.0) - 0.5, cb * 0.79, fposmod(cb * 0.61, 0.8) - 0.4)

	# ── Lê Lợi: phố dọc phía Tây (trung tâm x=-19), nối Trần Phú ↔ NTH ──
	# Nhà tây (x=-22, mặt quay đông/PI) và đông (x=-16, mặt quay tây/0)
	# z=-3,-9,-15,-21: contiguous facade từ z=0 đến z=-24, tránh thân nhà Trần Phú (z≥2.9)
	for j in range(4):
		var z := -3.0 - j * 6.0
		_house(Vector3(-22.0, 0, z), PI, j * 3)
		_house(Vector3(-16.0, 0, z), 0.0, j * 3 + 1)
	# dây đèn Lê Lợi — chạy dọc alley (cố định z, x thay đổi qua đường)
	for zs in [-3.0, -15.0]:
		var prev3 := Vector3.ZERO
		for j in range(5):
			var x := -22.0 + j * 1.5
			var y := 3.2 - 0.42 * (1.0 - pow((x + 19.0) / 2.25, 2.0))
			var top := Vector3(x, y + 0.1, zs)
			if j > 0:
				var mid := (prev3 + top) * 0.5
				var seg := Build.box(self, Vector3(prev3.distance_to(top), 0.015, 0.015), mid, Build.mat(Color(0.05, 0.04, 0.035)))
				seg.rotation.z = atan2(top.y - prev3.y, top.x - prev3.x)
			prev3 = top
			_string_lanterns.append([Build.lantern(self, 0.11, 0.2, Vector3(x, y, zs)), nth_pal[j % nth_pal.size()]])

	# ── Hoàng Văn Thụ: phố dọc phía Đông (trung tâm x=+19), nối Trần Phú ↔ NTH ──
	for j in range(4):
		var z := -3.0 - j * 6.0
		_house(Vector3(16.0, 0, z), PI, j * 3 + 2)
		_house(Vector3(22.0, 0, z), 0.0, j * 3 + 1)
	# dây đèn HVT
	for zs in [-9.0, -21.0]:
		var prev4 := Vector3.ZERO
		for j in range(5):
			var x := 16.0 + j * 1.5
			var y := 3.2 - 0.42 * (1.0 - pow((x - 19.0) / 2.25, 2.0))
			var top := Vector3(x, y + 0.1, zs)
			if j > 0:
				var mid := (prev4 + top) * 0.5
				var seg := Build.box(self, Vector3(prev4.distance_to(top), 0.015, 0.015), mid, Build.mat(Color(0.05, 0.04, 0.035)))
				seg.rotation.z = atan2(top.y - prev4.y, top.x - prev4.x)
			prev4 = top
			_string_lanterns.append([Build.lantern(self, 0.11, 0.2, Vector3(x, y, zs)), nth_pal[(j + 1) % nth_pal.size()]])


# Phase 3 — Sông Hoài: Bạch Đằng bắc ngạn + bờ kè + cầu tàu + mặt sông rộng + thuyền mui cong
# Tất cả ở |x|>9 (tránh hành lang C4: |x|≤7.4, z∈[-57.4,-44.5]).
func _build_phase3_river() -> void:
	var stone := Build.pbr("res://assets/textures/PavingStones138", 0.65, Color(0.56, 0.50, 0.48), 0.25)
	var woodmat := Build.pbr("res://assets/textures/WoodFloor043", 0.88, Color(0.42, 0.31, 0.21), 1.2)
	var dark := Build.mat(Color(0.1, 0.08, 0.07), 0.9)

	# ── Bạch Đằng: một hàng nhà bắc ngạn, mặt quay sông (Nam), |x|>9 ──
	# facade z=-47, thân kéo bắc tới z=-42 (kẽ với NTH south body z=-40, gap 2m)
	for k in range(12):
		var x := -33.0 + k * 6.0
		if absf(x) > 9.0:
			_house(Vector3(x, 0, -47.0), -PI / 2.0, k + 1)
	# chậu cảnh + xe thuyền Bạch Đằng
	for pp in [[-26.8, -47.05, 2], [-20.8, -47.05, 0], [20.8, -47.05, 3], [26.8, -47.05, 1]]:
		Parts.pot_plant(self, Vector3(pp[0], 0, pp[1]), int(pp[2]), 0.88)
	Parts.bicycle(self, Vector3(-24.5, 0, -47.5), 0.0, 0.15)
	Parts.motorbike(self, Vector3(24.5, 0, -47.6), -0.18)

	# ── Nền đá lát Bạch Đằng + bờ sông (|x| 9→35, z -42→-54) ──
	for side in [-1.0, 1.0]:
		var cx: float = side * 22.0   # center của dải 26m rộng (±9 → ±35)
		Build.box(self, Vector3(26.0, 0.15, 12.0), Vector3(cx, 0.0, -48.0), stone)

	# ── Bờ kè đá: tường thấp + lan can ──
	for side in [-1.0, 1.0]:
		var cx: float = side * 22.0
		# thân bờ kè
		Build.box(self, Vector3(26.0, 0.55, 0.6), Vector3(cx, 0.27, -52.5), Build.mat(Color(0.51, 0.48, 0.44), 0.96))
		# trụ lan can mỗi 2.5m
		for qi in range(11):
			var qx: float = cx - 12.5 + qi * 2.5
			Build.box(self, Vector3(0.2, 0.4, 0.22), Vector3(qx, 0.75, -52.5), Build.mat(Color(0.46, 0.43, 0.4), 0.98))
		# dải lan can ngang
		Build.box(self, Vector3(26.0, 0.1, 0.15), Vector3(cx, 0.92, -52.5), Build.mat(Color(0.42, 0.39, 0.36), 0.96))

	# ── Bậc xuống nước tại ±18, ±26 (4 bậc × 4 vị trí) ──
	for bx in [-26.0, -18.0, 18.0, 26.0]:
		for step in range(4):
			Build.box(self, Vector3(2.1, 0.2, 0.55), Vector3(bx, 0.54 - step * 0.2, -53.0 - step * 0.58), stone)

	# ── Cầu tàu gỗ (bến thuyền) tại x=±20, hướng ra sông ──
	for side in [-1.0, 1.0]:
		var px: float = side * 20.0
		# ván sàn cầu tàu
		Build.box(self, Vector3(2.2, 0.18, 12.0), Vector3(px, 0.12, -58.5), woodmat)
		# cọc gỗ (3 đôi mỗi bên, cắm sâu dưới nước)
		for pi in range(6):
			Build.box(self, Vector3(0.22, 2.6, 0.22),
					Vector3(px - 0.9 + (pi % 2) * 1.8, -0.9, -53.5 - int(pi / 2) * 4.0), dark)
		# đèn bến tàu
		var dock_l := OmniLight3D.new()
		dock_l.light_color = Color(1.0, 0.6, 0.22)
		dock_l.light_energy = 0.9
		dock_l.omni_range = 7.5
		dock_l.position = Vector3(px, 2.1, -58.0)
		add_child(dock_l)

	# ── Mặt sông rộng hai cánh (|x| 9→35, z -58→-78) ──
	var wmat3 := StandardMaterial3D.new()
	wmat3.albedo_color = Color(0.012, 0.024, 0.042)
	wmat3.metallic = 0.93
	wmat3.roughness = 0.04
	wmat3.emission_enabled = true
	wmat3.emission = Color(0.015, 0.032, 0.065)
	wmat3.emission_energy_multiplier = 0.28
	for side in [-1.0, 1.0]:
		var rw := Build.box(self, Vector3(26.0, 0.08, 20.0), Vector3(side * 22.0, -0.06, -68.0), null)
		rw.material_override = wmat3
		rw.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# ── Thuyền mui cong (2 thuyền hai bên, neo cạnh cầu tàu) ──
	var boat_pal := [Color(1.0, 0.55, 0.2), Color(1.0, 0.62, 0.25)]
	for si in range(2):
		var side := 1.0 - si * 2.0   # +1 hoặc -1
		var bnode := Node3D.new()
		bnode.position = Vector3(side * 25.0, 0.04, -64.0)
		add_child(bnode)
		# thân thuyền gỗ
		Build.box(bnode, Vector3(2.2, 0.42, 6.2), Vector3(0, 0.21, 0), woodmat)
		# mũi vát
		var prow := Build.box(bnode, Vector3(2.2, 0.34, 0.9), Vector3(0, 0.17, 3.1), woodmat)
		prow.rotation.x = 0.44
		# mui cong: 5 tấm liên tiếp ghép thành cung mái thuyền
		for ri in range(5):
			var ra := (ri - 2.0) * 0.28
			var ry := 1.12 - cos(ra * 1.4) * 0.21
			var panel := Build.box(bnode, Vector3(2.3, 0.08, 1.35), Vector3(0, ry, ra * 1.9), dark)
			panel.rotation.x = ra * 0.52
		# đèn thuyền
		var bl := OmniLight3D.new()
		bl.light_color = boat_pal[si % boat_pal.size()]
		bl.light_energy = 0.75
		bl.omni_range = 5.5
		bl.position = Vector3(0, 1.95, 0)
		bnode.add_child(bl)
		# phản chiếu đèn trên mặt sông
		var glow := Build.cyl(self, 0.33, 0.33, 0.02, Vector3(side * 25.0, -0.03, -64.0),
				Build.emis(boat_pal[si % boat_pal.size()], boat_pal[si % boat_pal.size()] * 0.7, 1.5))
		glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# ── Dây đèn lồng vắt qua sông (3 dây, mỗi dây 9 đèn) ──
	var riv_pal := [Color(1.0, 0.16, 0.08), Color(1.0, 0.62, 0.12), Color(0.95, 0.25, 0.4)]
	var rli := 0
	for rz in [-60.0, -64.5, -69.0]:
		var prev_r := Vector3.ZERO
		for j in range(9):
			var rx := -32.0 + j * 8.0
			var ry := 3.7 - 0.58 * (1.0 - pow(rx / 32.0, 2.0))
			var top := Vector3(rx, ry + 0.12, rz)
			if j > 0:
				var mid := (prev_r + top) * 0.5
				var seg := Build.box(self, Vector3(prev_r.distance_to(top), 0.015, 0.015), mid, Build.mat(Color(0.05, 0.04, 0.035)))
				seg.rotation.z = atan2(top.y - prev_r.y, top.x - prev_r.x)
			prev_r = top
			_string_lanterns.append([Build.lantern(self, 0.15, 0.28, Vector3(rx, ry, rz)), riv_pal[rli % riv_pal.size()]])
			rli += 1

	# ── Hoa đăng bổ sung hai cánh sông (|x|>9 chỉ, tĩnh — chuyển động do C4 xử lý giữa dòng) ──
	var hd_positions := [
		Vector3(-28.0, 0.05, -63.5), Vector3(-21.0, 0.05, -66.8), Vector3(-16.0, 0.05, -70.2),
		Vector3(-25.0, 0.05, -73.5), Vector3(15.0, 0.05, -61.9), Vector3(22.0, 0.05, -65.4),
		Vector3(28.0, 0.05, -69.1), Vector3(19.0, 0.05, -72.8),
	]
	for hdp in hd_positions:
		var hd := Node3D.new()
		hd.position = hdp
		add_child(hd)
		Build.cyl(hd, 0.09, 0.11, 0.09, Vector3(0, 0.05, 0),
				Build.emis(Color(1.0, 0.8, 0.5), Color(1.0, 0.62, 0.22), 3.0))
		for p in range(6):
			var ang := TAU * p / 6.0
			Build.ball(hd, 0.085, 0.07, Vector3(cos(ang) * 0.13, 0.02, sin(ang) * 0.13),
					Build.emis(Color(0.9, 0.45, 0.55), Color(0.9, 0.35, 0.4), 0.5, 0.7))


# Phase 5 — Landmarks: Chợ Hội An (nhà lồng) + 2 Hội quán (Quảng Đông + Phúc Kiến).
func _build_phase5_landmarks() -> void:
	_build_cho_hoi_an()
	# Hội quán Quảng Đông — tường vôi cam, ngói lục (phía tây hơn)
	_build_hoi_quan(Vector3(18.0, 0, 14.2),
		Build.mat(Color(0.72, 0.42, 0.12), 0.75),
		Build.mat(Color(0.18, 0.22, 0.14), 0.65))
	# Hội quán Phúc Kiến — tường đỏ son, ngói xanh (phía đông, nổi bật nhất)
	_build_hoi_quan(Vector3(30.0, 0, 14.2),
		Build.mat(Color(0.70, 0.12, 0.09), 0.75),
		Build.mat(Color(0.14, 0.25, 0.12), 0.65))


# Chợ Hội An nhà lồng: arcade 8 cột gỗ, mái ngói 2 dốc, quầy hàng, 4 đèn lồng.
func _build_cho_hoi_an() -> void:
	var mkt := Node3D.new()
	mkt.position = Vector3(-20, 0, 26)
	add_child(mkt)
	var col_wood := Build.pbr("res://assets/textures/WoodFloor043", 0.8, Color(0.38, 0.24, 0.14), 1.1)
	var roof_dark := Build.mat(Color(0.11, 0.09, 0.09), 0.65)
	var stall_mat := Build.mat(Color(0.80, 0.68, 0.50), 0.9)
	# 8 cột arcade: 4 nhịp × 2 hàng (hàng z=±2.2)
	for ci in range(4):
		for cz in [-2.2, 2.2]:
			Build.box(mkt, Vector3(0.35, 5.6, 0.35), Vector3(-4.5 + ci * 3.0, 2.8, cz), col_wood)
	# xà ngang + xà dọc mái
	for cz in [-2.2, 2.2]:
		Build.box(mkt, Vector3(11.5, 0.18, 0.22), Vector3(0, 5.55, cz), col_wood)
	for ci in range(3):
		Build.box(mkt, Vector3(2.75, 0.18, 4.5), Vector3(-3.0 + ci * 3.0, 5.55, 0), col_wood)
	# mái 2 dốc ngói
	Build.box(mkt, Vector3(12.2, 0.22, 5.0), Vector3(0, 5.7, 0), roof_dark)
	for k in [-1.0, 1.0]:
		var sl := Node3D.new()
		sl.position = Vector3(0, 6.15, k * 1.55)
		sl.rotation.x = k * 0.42
		mkt.add_child(sl)
		var sm := BoxMesh.new(); sm.size = Vector3(12.4, 0.1, 2.5)
		var smi := MeshInstance3D.new(); smi.mesh = sm
		smi.material_override = roof_dark; sl.add_child(smi)
		Build.tile_rows(sl, 2.5, 12.4)
	Build.cyl(mkt, 0.1, 0.1, 12.6, Vector3(0, 6.85, 0), Build.mat(Color(0.07, 0.05, 0.04)), 8).rotation.z = PI / 2.0
	# quầy hàng (6 gian, 2 hàng)
	for si in range(3):
		for sz in [-1.6, 1.6]:
			Build.box(mkt, Vector3(2.5, 0.85, 1.7), Vector3(-3.0 + si * 3.0, 0.425, sz), stall_mat)
	# 4 đèn lồng treo giữa chợ
	for li in range(4):
		_hanging.append(Build.lantern(mkt, 0.16, 0.28, Vector3(-4.5 + li * 3.0, 4.2, 0)))
	var iglow := OmniLight3D.new()
	iglow.light_color = Color(1.0, 0.62, 0.32)
	iglow.light_energy = 1.2; iglow.omni_range = 14.0
	iglow.position = Vector3(0, 4.0, 0); mkt.add_child(iglow)


# Hội quán generic: cổng tam quan 3 nhịp + sân + chính điện — parameterized màu.
# wpos = vị trí node (mặt Nam cổng ngay tại đây), compound kéo Bắc 11m.
func _build_hoi_quan(wpos: Vector3, wall: StandardMaterial3D, tile: StandardMaterial3D) -> void:
	var hq := Node3D.new()
	hq.position = wpos
	add_child(hq)
	var gold := Build.mat(Color(0.72, 0.56, 0.18), 0.5)
	var stone := Build.mat(Color(0.50, 0.44, 0.38), 0.85)
	# ── Cổng tam quan: 2 cột biên + 2 cột trong, gate depth 1.4m ──
	for gx in [-3.5, 3.5]:   # cột biên thấp
		Build.box(hq, Vector3(0.42, 3.6, 0.42), Vector3(gx, 1.8, 0.7), wall)
	for gx in [-1.1, 1.1]:   # cột trong cao (nhịp giữa)
		Build.box(hq, Vector3(0.42, 4.2, 0.42), Vector3(gx, 2.1, 0.7), wall)
	# tường bịt 2 bên
	for side in [-1.0, 1.0]:
		Build.box(hq, Vector3(1.85, 3.2, 0.32), Vector3(side * 2.6, 1.6, 0.7), wall)
	# đà ngang vàng
	Build.box(hq, Vector3(2.4, 0.26, 0.36), Vector3(0, 3.85, 0.7), gold)
	for side in [-1.0, 1.0]:
		Build.box(hq, Vector3(2.1, 0.22, 0.33), Vector3(side * 2.6, 3.2, 0.7), gold)
	# mái cổng: slab + 2 dốc + đòn nóc
	Build.box(hq, Vector3(8.2, 0.2, 2.0), Vector3(0, 4.5, 0.7), tile)
	for k in [-1.0, 1.0]:
		var gs := Node3D.new()
		gs.position = Vector3(0, 4.85, 0.7 + k * 0.62)
		gs.rotation.x = k * 0.44; hq.add_child(gs)
		var gm := BoxMesh.new(); gm.size = Vector3(8.4, 0.1, 1.5)
		var gmi := MeshInstance3D.new(); gmi.mesh = gm; gmi.material_override = tile
		gs.add_child(gmi); Build.tile_rows(gs, 1.5, 8.4)
	Build.cyl(hq, 0.09, 0.09, 8.6, Vector3(0, 5.3, 0.7), Build.mat(Color(0.07, 0.05, 0.04)), 8).rotation.z = PI / 2.0
	# ── Sân trong ──
	Build.box(hq, Vector3(8.0, 0.07, 4.2), Vector3(0, 0.035, 3.5), stone)
	# ── Chính điện: tường hồi + hậu + mái lớn ──
	for hx in [-3.8, 3.8]:
		Build.box(hq, Vector3(0.38, 4.6, 5.8), Vector3(hx, 2.3, 7.2), wall)
	Build.box(hq, Vector3(8.0, 4.6, 0.32), Vector3(0, 2.3, 10.0), wall)
	Build.box(hq, Vector3(8.5, 0.22, 6.5), Vector3(0, 4.8, 7.2), tile)
	for k in [-1.0, 1.0]:
		var hs := Node3D.new()
		hs.position = Vector3(0, 5.15, 7.2 + k * 2.0)
		hs.rotation.x = k * 0.38; hq.add_child(hs)
		var hm := BoxMesh.new(); hm.size = Vector3(8.7, 0.1, 2.8)
		var hmi := MeshInstance3D.new(); hmi.mesh = hm; hmi.material_override = tile
		hs.add_child(hmi); Build.tile_rows(hs, 2.8, 8.7)
	Build.cyl(hq, 0.1, 0.1, 9.0, Vector3(0, 5.95, 7.2), Build.mat(Color(0.07, 0.05, 0.04)), 8).rotation.z = PI / 2.0
	# đèn lồng cổng + nội sáng
	for li in range(3):
		_hanging.append(Build.lantern(hq, 0.14, 0.26, Vector3(-2.0 + li * 2.0, 3.8, 0.7)))
	var hglow := OmniLight3D.new()
	hglow.light_color = Color(1.0, 0.42, 0.15)
	hglow.light_energy = 1.2; hglow.omni_range = 10.0
	hglow.position = Vector3(0, 3.0, 4.5); hq.add_child(hglow)


# Phase 4 — Chùa Cầu thật: cầu gỗ vòm có mái ngói, miếu Bắc Đế giữa cầu, tượng thú trấn hai đầu.
# Khớp c5.gd về chất lượng hình học; vật liệu PBR; vai trò phong ấn C1 giữ nguyên (sau mist x=-39).
func _build_chua_cau() -> void:
	var bridge := Node3D.new()
	bridge.position = Vector3(-46, 0, 11)
	add_child(bridge)
	var deckwood := Build.pbr("res://assets/textures/WoodFloor043", 0.7, Color(0.5, 0.34, 0.2), 1.2)
	var redcol := Build.mat(Color(0.42, 0.1, 0.07), 0.6)
	var rooftile := Build.mat(Color(0.09, 0.08, 0.09), 0.7)
	var stonegrey := Build.mat(Color(0.22, 0.22, 0.24), 0.9)
	# mặt cầu cong vòm: 7 nhịp ván gỗ theo đường parabol
	for s in range(7):
		var sx := -4.5 + s * 1.5
		var sy := 0.6 + 0.55 * (1.0 - pow(sx / 4.5, 2.0))
		var seg := Build.box(bridge, Vector3(1.6, 0.18, 3.2), Vector3(sx, sy, 0), deckwood)
		seg.rotation.z = -sx * 0.05
		for sz in [-1.5, 1.5]:
			Build.box(bridge, Vector3(1.55, 0.06, 0.08), Vector3(sx, sy + 0.75, sz), deckwood).rotation.z = -sx * 0.05
			Build.cyl(bridge, 0.035, 0.035, 0.72, Vector3(sx, sy + 0.4, sz), redcol, 6)
	# cột đỏ đỡ mái: 4 cặp tại sx=±4.2, ±1.4
	for sx in [-4.2, -1.4, 1.4, 4.2]:
		for sz in [-1.35, 1.35]:
			Build.box(bridge, Vector3(0.22, 2.6, 0.22), Vector3(sx, 2.4, sz), redcol)
	# mái âm dương cong: slab ngang + 2 mái dốc ngói
	Build.box(bridge, Vector3(11.5, 0.22, 4.4), Vector3(0, 3.7, 0), rooftile)
	for k in [-1.0, 1.0]:
		var slope := Node3D.new()
		slope.position = Vector3(0, 4.15, k * 1.3)
		slope.rotation.x = k * 0.38
		bridge.add_child(slope)
		var slab := BoxMesh.new()
		slab.size = Vector3(11.8, 0.1, 2.4)
		var smi := MeshInstance3D.new()
		smi.mesh = slab
		smi.material_override = Build.mat(Color(0.11, 0.1, 0.115), 0.6)
		slope.add_child(smi)
		Build.tile_rows(slope, 2.4, 11.8)
	# đòn nóc ngang + đầu đao vểnh hai đầu
	Build.cyl(bridge, 0.1, 0.1, 11.9, Vector3(0, 4.75, 0), Build.mat(Color(0.08, 0.06, 0.05)), 8).rotation.z = PI / 2.0
	for ke in [-1.0, 1.0]:
		var horn := Build.cyl(bridge, 0.012, 0.11, 0.7, Vector3(ke * 5.9, 4.9, 0), Build.mat(Color(0.08, 0.06, 0.05)), 8)
		horn.rotation.z = ke * 1.0
	# miếu nhỏ giữa cầu — thờ Bắc Đế Trấn Vũ (trấn phong ba sông Hoài)
	Build.box(bridge, Vector3(1.6, 1.4, 1.0), Vector3(0, 1.9, -2.1), Build.mat(Color(0.36, 0.25, 0.14), 0.9))
	Build.box(bridge, Vector3(1.9, 0.12, 1.3), Vector3(0, 2.7, -2.1), rooftile)
	Build.box(bridge, Vector3(0.7, 0.5, 0.05), Vector3(0, 1.8, -1.58), Build.mat(Color(0.05, 0.03, 0.03), 0.6))
	var altar_glow := OmniLight3D.new()
	altar_glow.light_color = Color(1.0, 0.5, 0.2)
	altar_glow.light_energy = 0.8
	altar_glow.omni_range = 4.5
	altar_glow.position = Vector3(0, 2.0, -1.8)
	bridge.add_child(altar_glow)
	# tượng linh khuyển / linh hầu trấn hai đầu cầu
	for ke in [-1.0, 1.0]:
		var ped := Vector3(ke * 5.6, 0, 1.0)
		Build.box(bridge, Vector3(0.6, 0.7, 0.6), ped + Vector3(0, 0.35, 0), stonegrey)
		Build.ball(bridge, 0.22, 0.42, ped + Vector3(0, 0.92, 0), Build.mat(Color(0.3, 0.3, 0.32), 0.85))
		Build.ball(bridge, 0.13, 0.26, ped + Vector3(ke * 0.08, 1.25, 0.08), Build.mat(Color(0.3, 0.3, 0.32), 0.85))
		for ear in [-0.07, 0.07]:
			Build.cyl(bridge, 0.01, 0.04, 0.12, ped + Vector3(ke * 0.08 + ear, 1.4, 0.08), Build.mat(Color(0.28, 0.28, 0.3), 0.85), 6)
	# đèn lồng đỏ dưới mái — kích hoạt cùng light_up()
	for i in range(5):
		var lan := Build.lantern(bridge, 0.14, 0.26, Vector3(-4.0 + i * 2.0, 2.6, 0))
		_hanging.append(lan)


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
	# hoa giấy ôm trụ góc mặt tiền — mỗi ba nhà một giàn, có thân leo bám tường
	# (khóm hoa nửa chìm vào mặt trụ z=2.72 — dính tường chứ không lơ lửng,
	#  né hẳn vùng cửa sổ trệt z≤2.43)
	if (idx * 11) % 3 == 0:
		var vine_h: float = ms.H_BASE + 2.1
		Build.cyl(a, 0.022, 0.032, vine_h, Vector3(-0.16, vine_h / 2.0 + 0.25, 2.72), Build.mat(Color(0.25, 0.17, 0.1), 0.9), 6)
		var base_p := Vector3(-0.12, ms.H_BASE + 2.45, 2.72)
		for fi in range(16):
			var fx := -absf(sin(fi * 2.39 + idx)) * 0.2
			var fy := -absf(sin(fi * 1.7)) * 0.85
			var fz := cos(fi * 2.39 + idx) * 0.26
			var fc := Color(1.9, 0.3, 1.0) if fi % 4 != 0 else Color(0.4, 0.65, 0.3)
			Build.ball(a, 0.055 + 0.03 * (fi % 2), 0.1, base_p + Vector3(fx, fy, fz), Build.leaf_mat("ForestLeaves03", fc, 0.035, 1.6, 1.4))
	# bụi cỏ chen chân đế — phố ẩm, cỏ mọc kẽ đá (một nửa số nhà, vị trí lệch theo idx)
	if (idx * 7) % 2 == 0:
		Parts.grass_tuft(a, Vector3(-0.22, 0, -2.7 + fposmod(idx * 1.93, 0.9)), 0.9)
		Parts.grass_tuft(a, Vector3(-0.3, 0, 1.9 + fposmod(idx * 1.31, 0.7)), 0.8)

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
