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
	# Phase 7 — zone địa lý khi tự do khám phá C1 (sau light_up):
	# phố Trần Phú ấm đèn lồng / hành lang khu cầu sương phong ấn đặc lạnh
	"pho_dem": {"bg": Color(0.025, 0.022, 0.045), "amb": Color(0.3, 0.22, 0.2), "amb_e": 0.85,
		"fog": Color(0.085, 0.055, 0.06), "fog_d": 0.009, "vol": 0.022},
	"ngo_cau": {"bg": Color(0.008, 0.016, 0.038), "amb": Color(0.13, 0.17, 0.3), "amb_e": 0.5,
		"fog": Color(0.045, 0.055, 0.1), "fog_d": 0.026, "vol": 0.07},
	# Phase 8 — bờ sông Hoài về đêm: trăng xanh trên mặt nước đen
	"bo_song": {"bg": Color(0.006, 0.012, 0.028), "amb": Color(0.18, 0.24, 0.4), "amb_e": 0.7,
		"fog": Color(0.03, 0.05, 0.09), "fog_d": 0.012, "vol": 0.045},
}

# Phase 8 — mạng phố đi được khi C1 đã light_up (ngoài Trần Phú/ngõ vốn có):
# giao lộ TP→Lê Lợi/HVT (lot ±21 dãy Nam bỏ trống), hai phố dọc, lot TÀN TÍCH
# xuyên hàng NTH, band sau Bạch Đằng, hẻm xuống bến sông Hoài phía Tây.
# Union các rect = vùng đi được; ra ngoài thì kẹp về điểm gần nhất trong union.
const ROAM_RECTS := [
	{"x0": -23.6, "x1": -18.4, "z0": -0.2, "z1": 8.6},     # giao lộ Tây TP→Lê Lợi
	{"x0": -21.8, "x1": -16.2, "z0": -23.4, "z1": 0.4},    # Lê Lợi
	{"x0": -22.6, "x1": -19.4, "z0": -29.2, "z1": -23.0},  # lot tàn tích Lê Lợi→NTH
	{"x0": -35.8, "x1": -8.8, "z0": -34.3, "z1": -29.0},   # Nguyễn Thái Học tây (chạm tường C2)
	{"x0": -22.6, "x1": -19.4, "z0": -40.3, "z1": -34.0},  # lot tàn tích NTH→band sau
	{"x0": -35.5, "x1": -9.3, "z0": -42.3, "z1": -40.0},   # band sau lưng Bạch Đằng
	{"x0": -22.6, "x1": -19.4, "z0": -47.6, "z1": -41.9},  # hẻm Bạch Đằng xuống bến
	{"x0": -35.5, "x1": -9.3, "z0": -52.1, "z1": -46.9},   # bờ sông Hoài tây (nền đá)
	{"x0": 18.4, "x1": 23.6, "z0": -0.2, "z1": 8.6},       # giao lộ Đông TP→HVT
	{"x0": 16.2, "x1": 21.8, "z0": -23.4, "z1": 0.4},      # Hoàng Văn Thụ
	{"x0": 19.4, "x1": 22.6, "z0": -29.2, "z1": -23.0},    # lot tàn tích HVT→NTH
	{"x0": 8.8, "x1": 35.8, "z0": -34.3, "z1": -29.0},     # Nguyễn Thái Học đông
	{"x0": -37.5, "x1": -24.2, "z0": 7.95, "z1": 8.45},    # 4 đoạn thềm Nam (hở miệng giao lộ)
	{"x0": -17.8, "x1": -5.9, "z0": 7.95, "z1": 8.45},
	{"x0": 5.9, "x1": 17.8, "z0": 7.95, "z1": 8.45},
	{"x0": 24.2, "x1": 37.5, "z0": 7.95, "z1": 8.45},
]

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
var geo_zone_on := false   # bật sau light_up() — C1 roam tự do, zone đổi theo nơi đứng

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


# Phase 7 — map khu vực vào zone theo vị trí (chỉ C1 roam tự do; C2-C5 tự đặt zone riêng):
# ngõ giữ c1_lit, ra phố Trần Phú ấm đèn (pho_dem), lách vào hành lang khu cầu thì sương đặc (ngo_cau)
func update_zone_geo(pos: Vector3) -> void:
	if not geo_zone_on:
		return
	if pos.z > 8.0 and pos.x < -38.0:
		set_zone("ngo_cau")
	elif pos.z < -39.5:
		set_zone("bo_song")
	elif pos.z > 8.0 or absf(pos.x) > ALLEY_HALF + 0.5:
		set_zone("pho_dem")
	else:
		set_zone("c1_lit")


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
	_build_phase6_an_hoi()
	_build_phase8_roam()


# Phase 8 — mở phố: nhà TÀN TÍCH tại các lot đục lối (bóng tối đã "nhai" chúng),
# hẻm Bạch Đằng xuống bến, sương chặn biên mở mới, sàn đá bờ sông đăng ký floor.
func _build_phase8_roam() -> void:
	_ruin_house(Vector3(-21, 0, -28.5), -PI / 2.0, 9)
	_ruin_house(Vector3(21, 0, -28.5), -PI / 2.0, 4)
	_ruin_house(Vector3(-21, 0, -35.0), PI / 2.0, 7)
	# hẻm hai vách hồi nhà kề xuống bến sông + dây đèn lồng vắt ngang
	for hx in [-23.4, -18.6]:
		Build.box(self, Vector3(0.35, 2.7, 5.4), Vector3(hx, 1.35, -44.5), _plaster)
		Build.box(self, Vector3(0.37, 0.5, 5.4), Vector3(hx, 0.25, -44.5), _moss)
	Build.box(self, Vector3(4.8, 0.02, 0.02), Vector3(-21, 2.78, -44.5), Build.mat(Color(0.05, 0.045, 0.04)))
	_hanging.append(Build.lantern(self, 0.12, 0.22, Vector3(-21, 2.62, -44.5)))
	Parts.grass_tuft(self, Vector3(-23.0, 0, -42.3), 0.9)
	# nền đá Bạch Đằng (khối Phase 3 nổi 0.075) — sàn công cộng, không tính "sát thềm nhà"
	_reg_floor(Vector3.ZERO, 0.0, -35.5, -9.0, -54.0, -42.0, 0.075, true)
	# sương phong ấn các biên mở mới (Tây/Đông NTH + Tây bờ sông)
	_mist(Vector3(-37.2, 3.0, -31.6), Vector3(0.4, 6.0, 7.5))
	_mist(Vector3(37.2, 3.0, -31.6), Vector3(0.4, 6.0, 7.5))
	_mist(Vector3(-36.8, 3.0, -46.5), Vector3(0.4, 6.0, 13.5))


# nhà đổ sụp — bóng tối nuốt ký ức của phố, từng căn một: hai mảng mặt tiền còn
# đứng (khoảng giữa = cửa đã sập, thành lối đi xuyên lot), tường hồi gãy bậc thang,
# xà cháy gác chéo, gạch vụn, ngói sập, cỏ dại. Cùng hệ tọa độ với _house().
func _ruin_house(pos: Vector3, yrot: float, idx: int) -> void:
	var a := Node3D.new()
	a.position = pos
	a.rotation.y = yrot
	add_child(a)
	var burnt := Build.mat(Color(0.06, 0.05, 0.045), 0.95)
	var rubble_m := Build.mat(Color(0.46, 0.39, 0.33), 0.97)
	# hai mảng mặt tiền — cao thấp lệch nhau theo idx
	for sgn in [-1.0, 1.0]:
		var h := 2.0 + 0.9 * fposmod(idx * 0.7 + sgn, 1.0)
		Build.box(a, Vector3(0.34, h, 1.5), Vector3(0.1, h / 2.0, sgn * 2.2), _plaster)
		Build.box(a, Vector3(0.36, 0.5, 1.52), Vector3(0.1, 0.25, sgn * 2.2), _moss)
	# tường hồi hai bên giáp nhà kề — gãy thấp dần về sau
	for sgn in [-1.0, 1.0]:
		for i in range(3):
			var h2 := 2.4 - i * 0.75 - 0.3 * fposmod(idx * 1.3 + i + sgn, 1.0)
			Build.box(a, Vector3(1.66, h2, 0.3), Vector3(0.9 + i * 1.62, h2 / 2.0, sgn * 2.85), _plaster)
	# xà gỗ cháy gác chéo (cây vắt ngang lối đi nâng cao khỏi đầu)
	var beam_z := [-2.0, 1.6, 0.3]
	for i in range(3):
		var beam := Build.box(a, Vector3(3.0 + 0.8 * (i % 2), 0.13, 0.13), Vector3(1.4 + i * 1.1, 0.85 + 0.55 * i, beam_z[i]), burnt)
		beam.rotation.z = 0.35 + 0.3 * i
		beam.rotation.y = 0.25 * i - 0.3
	# gạch vụn dồn dọc chân tường hồi
	for i in range(10):
		var s := 0.14 + 0.2 * fposmod(idx * 0.91 + i * 0.67, 1.0)
		var zz := (2.3 - 0.5 * fposmod(i * 1.13, 1.0)) * (1.0 if i % 2 == 0 else -1.0)
		var rb := Build.box(a, Vector3(s * 1.3, s * 0.6, s), Vector3(0.5 + fposmod(i * 1.71 + idx, 4.2), s * 0.28, zz), rubble_m)
		rb.rotation.y = i * 0.8
	# mảng ngói sập nghiêng + cỏ dại mọc xuyên nền
	var tile := Build.box(a, Vector3(1.6, 0.09, 1.1), Vector3(2.4, 0.05, 1.7), Build.mat(Color(0.1, 0.09, 0.1), 0.8))
	tile.rotation.y = 0.5
	tile.rotation.x = 0.06
	Parts.grass_tuft(a, Vector3(1.2, 0, -0.6), 1.15)
	Parts.grass_tuft(a, Vector3(3.6, 0, 0.8), 1.0)
	Parts.grass_tuft(a, Vector3(0.4, 0, 2.0), 0.9)


# ---------- mặt sàn đi được (đế nhà + tam cấp) ----------
func _reg_floor(pos: Vector3, yrot: float, x0: float, x1: float, z0: float, z1: float, y: float, nc := false) -> void:
	var t := Transform3D(Basis(Vector3.UP, yrot), pos)
	var p0 := t * Vector3(x0, 0, z0)
	var p1 := t * Vector3(x1, 0, z1)
	# nc: sàn công cộng (bờ sông...) — đi được nhưng KHÔNG tính "sát thềm nhà ai đó"
	_floor_rects.append({
		"x0": minf(p0.x, p1.x), "x1": maxf(p0.x, p1.x),
		"z0": minf(p0.z, p1.z), "z1": maxf(p0.z, p1.z), "y": y, "nc": nc,
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
		if r.get("nc", false):
			continue
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
		# dãy Nam: chừa miệng ngõ + lot ±21 = giao lộ xuống Lê Lợi/Hoàng Văn Thụ (Phase 8)
		if absf(x) > 7.0 and absf(x) != 21.0:
			_house(Vector3(x, 0, 7.9), PI / 2.0, k + 2)
	# ---- đồ phố (ref-07/08/09/10): xe dựa hiên, chậu cảnh NÉP CHÂN THỀM hai bên
	# cửa (C ± 2.2 với C = -33 + 6k là tâm nhà), chuối nép góc trụ nhà —
	# lòng đường + vùng tam cấp (C ± 1.55) + trụ đèn (x = -30..30 bước 12, z 10.2)
	# luôn trống ----
	Parts.bicycle(self, Vector3(-17.3, 0, 13.55), 0.0, -0.12)
	Parts.bicycle(self, Vector3(30.6, 0, 13.5), 0.0, -0.1)
	Parts.motorbike(self, Vector3(18.9, 0, 13.1), 0.18)
	Parts.motorbike(self, Vector3(-24.3, 0, 13.25), -0.25)
	# chậu đứng TRÊN thềm đá nâng (ref-10) — trừ x>14.5 (khu hội quán không có thềm)
	for pp in [[-29.2, 2], [-18.8, 3], [-11.2, 1], [-6.8, 0], [5.2, 3], [11.2, 1]]:
		Parts.pot_plant(self, Vector3(pp[0], 0.14, 13.95), int(pp[1]), 1.0)
	Parts.pot_plant(self, Vector3(29.2, 0, 13.55), 0, 1.0)
	for pp2 in [[-11.2, 3], [11.2, 0], [25.2, 2], [-29.2, 1]]:
		Parts.pot_plant(self, Vector3(pp2[0], 0.14, 8.2), int(pp2[1]), 0.9)
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
		_mist(Vector3(mx, 3.5, 11.0), Vector3(0.4, 7.0, 14.0))
	_build_sidewalks()
	_build_ngo_hep()
	_build_chua_cau()


# màn sương phong ấn — chặn các biên thế giới chưa/không mở
func _mist(pos: Vector3, size: Vector3) -> void:
	var mist := Build.box(self, size, pos, null)
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(0.55, 0.62, 0.78, 0.055)
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mist.material_override = mm
	mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# Phase 7 — thềm đá nâng kiểu ref-10: nhà đứng trên nền đá liền, lòng đường thấp hơn
# một nhịp 0.14m. Đăng ký floor để người chơi bước hẳn lên thềm, đi dọc chân nhà.
func _build_sidewalks() -> void:
	var kerb := Build.pbr("res://assets/textures/PavingStones138", 0.5, Color(0.45, 0.43, 0.42), 0.45)
	# dãy Bắc Trần Phú: thềm liền từ sương Tây tới ranh hội quán (x>14.5 sân riêng)
	Build.box(self, Vector3(52.0, 0.14, 0.55), Vector3(-11.5, 0.07, 13.975), kerb)
	_reg_floor(Vector3.ZERO, 0.0, -37.5, 14.5, 13.7, 14.25, 0.14)
	# dãy Nam: 4 đoạn — hở miệng ngõ + hai miệng giao lộ ±(18..24) (Phase 8)
	for seg in [[-37.5, -24.2], [-17.8, -5.9], [5.9, 17.8], [24.2, 37.5]]:
		var x0: float = seg[0]
		var x1: float = seg[1]
		Build.box(self, Vector3(x1 - x0, 0.14, 0.5), Vector3((x0 + x1) / 2.0, 0.07, 8.2), kerb)
		_reg_floor(Vector3.ZERO, 0.0, x0, x1, 7.95, 8.45, 0.14)


# Phase 7 — ngõ hẹp khu cầu: hành lang vữa cao ép sát hai bên, cổng trụ + lanh tô +
# đèn lồng ở đầu Đông. Lách qua màn sương là tới chân Chùa Cầu (tượng linh thú ngay
# vách Bắc) — lên ván cầu vẫn bị phong ấn (C1: "chưa phải lúc").
func _build_ngo_hep() -> void:
	for sz in [9.4, 12.6]:
		Build.box(self, Vector3(2.3, 3.4, 0.5), Vector3(-39.6, 1.7, sz), _plaster)
		Build.box(self, Vector3(2.42, 0.12, 0.62), Vector3(-39.6, 3.46, sz), _darkwood)
		Build.box(self, Vector3(2.3, 0.5, 0.06), Vector3(-39.6, 0.25, sz + (0.26 if sz < 11.0 else -0.26)), _moss)
	# cổng vào: hai trụ vuông + lanh tô + mái ngói nhỏ + một đèn lồng (sáng cùng light_up)
	for pz in [9.8, 12.2]:
		Build.box(self, Vector3(0.38, 2.9, 0.38), Vector3(-38.6, 1.45, pz), _plaster)
	Build.box(self, Vector3(0.46, 0.5, 3.1), Vector3(-38.6, 3.05, 11.0), _plaster)
	Build.box(self, Vector3(0.95, 0.1, 3.6), Vector3(-38.6, 3.42, 11.0), Build.mat(Color(0.09, 0.08, 0.09), 0.7))
	_hanging.append(Build.lantern(self, 0.13, 0.24, Vector3(-38.6, 2.52, 11.0)))
	# bậc đá thấp ngay ngưỡng cổng — phố dốc nhẹ xuống phía cầu (ref-10)
	var kerb := Build.pbr("res://assets/textures/PavingStones138", 0.5, Color(0.42, 0.4, 0.4), 0.5)
	Build.box(self, Vector3(0.6, 0.1, 2.6), Vector3(-38.2, 0.05, 11.0), kerb)
	_reg_floor(Vector3.ZERO, 0.0, -38.5, -37.9, 9.7, 12.3, 0.1)
	# cỏ kẽ đá chân vách — hành lang ẩm, ít người qua
	Parts.grass_tuft(self, Vector3(-39.4, 0, 9.9), 0.85)
	Parts.grass_tuft(self, Vector3(-40.3, 0, 12.15), 0.9)


# Phase 2 — Nguyễn Thái Học + Lê Lợi + Hoàng Văn Thụ
# Đặt hoàn toàn ở |x|>11 để tránh hành lang ngõ (|x|≤5) và tường C2 (x=±8).
func _build_phase2_streets() -> void:
	# ── Nguyễn Thái Học: E-W trục song song Trần Phú, cách ~40m về Nam ──
	# north row z=-28.5 (mặt quay Nam), south row z=-35.0 (mặt quay Bắc)
	for k in range(12):
		var x := -33.0 + k * 6.0
		if absf(x) > 11.0:
			# Phase 8: lot ±21 hàng Bắc + lot -21 hàng Nam bỏ trống — nhà TÀN TÍCH
			# đục lối Lê Lợi/HVT xuyên xuống (dựng trong _build_phase8_roam)
			if absf(x) != 21.0:
				_house(Vector3(x, 0, -28.5), -PI / 2.0, k + 2)
			if x != -21.0:
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
	# chậu né lot tàn tích ±21 (Phase 8): -20.8→-14.8, 20.8→14.8
	for pp in [[-26.8, -28.55, 3], [-14.8, -28.55, 1], [14.8, -28.55, 0], [26.8, -28.55, 2],
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
		# Phase 8: lot -21 bỏ trống — hẻm hai vách xuống bến sông (dựng trong _build_phase8_roam)
		if absf(x) > 9.0 and x != -21.0:
			_house(Vector3(x, 0, -47.0), -PI / 2.0, k + 1)
	# chậu cảnh + xe thuyền Bạch Đằng (-20.8 dời -14.8 né miệng hẻm)
	for pp in [[-26.8, -47.05, 2], [-14.8, -47.05, 0], [20.8, -47.05, 3], [26.8, -47.05, 1]]:
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


# Phase 6 — An Hội bờ nam: Cầu An Hội + dải nhà thấp + chợ đêm đèn lồng.
func _build_phase6_an_hoi() -> void:
	_build_an_hoi_bridge()
	_build_an_hoi_south_bank()


# Cầu gỗ vòm nhẹ nối bờ bắc (Bạch Đằng z=-52.5) ↔ bờ nam An Hội (z=-82), tại x=22, span 30m.
func _build_an_hoi_bridge() -> void:
	var br := Node3D.new()
	br.position = Vector3(22, 0, -67.25)
	add_child(br)
	var dk := Build.pbr("res://assets/textures/WoodFloor043", 0.75, Color(0.45, 0.30, 0.18), 1.1)
	var rl := Build.mat(Color(0.28, 0.16, 0.09), 0.8)
	# 6 nhịp deck cong hump, cao nhất ở tâm
	for i in range(6):
		var sz := -12.5 + i * 5.0
		var sy := 0.9 + 0.35 * (1.0 - pow(sz / 12.5, 2.0))
		var seg := Build.box(br, Vector3(2.8, 0.16, 5.1), Vector3(0, sy, sz), dk)
		seg.rotation.x = -sz * 0.018
	# lan can: 7 cặp cột + 2 thanh dọc
	for ri in range(7):
		var sz := -15.0 + ri * 5.0
		for rx in [-1.3, 1.3]:
			Build.box(br, Vector3(0.12, 1.0, 0.12), Vector3(rx, 1.5, sz), rl)
	for rx in [-1.3, 1.3]:
		Build.box(br, Vector3(0.07, 0.07, 31.0), Vector3(rx, 2.02, 0), rl)
	# 7 đèn lồng đỏ treo giữa cầu
	for li in range(7):
		var sz := -12.0 + li * 4.0
		_hanging.append(Build.lantern(br, 0.13, 0.23, Vector3(0, 2.6, sz)))
	# 3 đôi cọc chống bên dưới
	for pz in [-8.0, 0.0, 8.0]:
		for px in [-1.0, 1.0]:
			Build.cyl(br, 0.16, 0.16, 3.8, Vector3(px, -0.9, pz), rl, 6)


# Bờ nam An Hội: bờ kè đá + 6 nhà thấp + chợ đêm 6 gian + 3 dây đèn + glow mặt sông.
func _build_an_hoi_south_bank() -> void:
	var stone := Build.pbr("res://assets/textures/PavingStones138", 0.65, Color(0.54, 0.48, 0.44), 0.25)
	var dk := Build.mat(Color(0.09, 0.08, 0.07), 0.85)
	# bờ kè + đường đi bờ nam
	Build.box(self, Vector3(48.0, 0.12, 7.0), Vector3(0, 0.06, -85.0), stone)
	Build.box(self, Vector3(48.0, 0.45, 0.55), Vector3(0, 0.22, -82.0), stone)
	# 6 nhà phố thấp bờ nam — mặt quay Bắc nhìn ra sông
	for k in range(6):
		_house(Vector3(-15.0 + k * 6.0, 0, -90.0), PI / 2.0, k + 7)
	# 6 gian chợ đêm màu sắc xen kẽ nhau
	var stall_colors := [
		Color(0.72, 0.20, 0.10), Color(0.62, 0.52, 0.12),
		Color(0.12, 0.36, 0.58), Color(0.18, 0.46, 0.20),
		Color(0.55, 0.14, 0.40), Color(0.65, 0.32, 0.10),
	]
	for si in range(6):
		var sx := -12.5 + si * 5.0
		var sc: Color = stall_colors[si % stall_colors.size()]
		var sm := Build.mat(sc, 0.75)
		var sn := Node3D.new()
		sn.position = Vector3(sx, 0, -87.5); add_child(sn)
		Build.box(sn, Vector3(4.0, 2.2, 2.2), Vector3(0, 1.1, 0), sm)
		Build.box(sn, Vector3(4.6, 0.1, 2.8), Vector3(0, 2.35, 0.2), sm)
		var sg := OmniLight3D.new()
		sg.light_color = sc.lightened(0.3); sg.light_energy = 1.0; sg.omni_range = 5.5
		sg.position = Vector3(0, 1.8, -0.8); sn.add_child(sg)
	# 3 dây đèn lồng E-W chợ đêm (9 đèn/dây)
	var mpal := [Color(1.0, 0.62, 0.12), Color(0.95, 0.22, 0.4), Color(1.0, 0.16, 0.08)]
	var mli := 0
	for mz in [-87.0, -90.0, -93.5]:
		var prev_m := Vector3.ZERO
		for j in range(9):
			var mx := -16.0 + j * 4.0
			var my := 3.8 - 0.55 * (1.0 - pow(mx / 16.0, 2.0))
			var top := Vector3(mx, my + 0.12, mz)
			if j > 0:
				var mid := (prev_m + top) * 0.5
				var seg := Build.box(self, Vector3(prev_m.distance_to(top), 0.015, 0.015), mid, dk)
				seg.rotation.z = atan2(top.y - prev_m.y, top.x - prev_m.x)
			prev_m = top
			_string_lanterns.append([Build.lantern(self, 0.14, 0.25, Vector3(mx, my, mz)), mpal[mli % mpal.size()]])
			mli += 1
	# glow đèn phản chiếu cạnh bờ nam trên mặt sông
	var refl_pal := [Color(1.0, 0.55, 0.2), Color(0.95, 0.25, 0.4), Color(1.0, 0.62, 0.12)]
	for ri in range(6):
		var rx := -12.5 + ri * 5.0
		var rc: Color = refl_pal[ri % refl_pal.size()]
		var gd := Build.cyl(self, 0.35, 0.35, 0.015, Vector3(rx, -0.02, -82.4),
			Build.emis(rc, rc * 0.6, 2.2))
		gd.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# Phase 4 — Chùa Cầu thật: cầu gỗ vòm có mái ngói, miếu Bắc Đế giữa cầu, tượng thú trấn hai đầu.
# Khớp c5.gd về chất lượng hình học; vật liệu PBR; vai trò phong ấn C1 giữ nguyên (sau mist x=-39).
func _build_chua_cau() -> void:
	# Phase 9 rebuild: reality-to-game dossier (REALITY-TO-GAME-RULES.md)
	# Cầu thật: 18m × 3m, trụ đá granite, miếu gắn MẶT BẮC giữa nhịp, mái rust-orange.
	var bridge := Node3D.new()
	bridge.position = Vector3(-46, 0, 11)
	add_child(bridge)
	var deckwood  := Build.pbr("res://assets/textures/WoodFloor043", 0.7, Color(0.42, 0.30, 0.18), 1.2)
	var redcol    := Build.mat(Color(0.50, 0.08, 0.06), 0.55)
	var rooftile  := Build.mat(Color(0.54, 0.28, 0.13), 0.65)   # rust-orange (dossier: ★)
	var stonegrey := Build.mat(Color(0.50, 0.48, 0.46), 0.88)   # granite pier
	var plaster   := Build.mat(Color(0.88, 0.80, 0.70), 0.72)   # cream pavilion
	var darkwood  := Build.mat(Color(0.20, 0.13, 0.08), 0.88)

	# ── TRỤ ĐÁ GRANITE (new — silhouette đặc trưng quan trọng nhất) ──
	# 2 trụ ở hai đầu, nửa chìm dưới mực nước lạch nhỏ (y < 0)
	for k in [-1.0, 1.0]:
		var kf: float = k
		Build.box(bridge, Vector3(2.6, 3.4, 4.6), Vector3(kf * 7.0, -1.4, 0.0), stonegrey)

	# Mặt nước lạch nhỏ dưới cầu (decorative, below grade)
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(0.10, 0.16, 0.24)
	wmat.metallic = 0.90
	wmat.roughness = 0.05
	Build.box(bridge, Vector3(18.0, 0.06, 5.4), Vector3(0.0, -2.7, 0.0), wmat)

	# ── MẶT CẦU (11 nhịp, ~16.5m — gần đúng 18m thật) ──
	for s in range(11):
		var sx: float = -7.5 + s * 1.5
		var sy: float = 0.42 + 0.60 * (1.0 - pow(sx / 7.5, 2.0))
		var seg := Build.box(bridge, Vector3(1.62, 0.18, 2.8), Vector3(sx, sy, 0.0), deckwood)
		seg.rotation.z = -sx * 0.028
		# lan can + chấn song đỏ hai bên
		for sz in [-1.35, 1.35]:
			var szf: float = sz
			Build.box(bridge, Vector3(1.58, 0.06, 0.08), Vector3(sx, sy + 0.82, szf), deckwood).rotation.z = -sx * 0.028
			Build.cyl(bridge, 0.030, 0.030, 0.78, Vector3(sx, sy + 0.44, szf), redcol, 6)

	# ── CỘT ĐỎ ĐỠ MÁI (5 cặp trải đều) ──
	for i in range(5):
		var sxf: float = -6.0 + i * 3.0
		var cy: float = 0.42 + 0.60 * (1.0 - pow(sxf / 7.5, 2.0))
		for sz in [-1.25, 1.25]:
			var szf: float = sz
			Build.box(bridge, Vector3(0.22, 2.85, 0.22), Vector3(sxf, cy + 1.3, szf), redcol)

	# ── MÁI NGÓI (rust-orange — đã sửa từ gần đen) ──
	Build.box(bridge, Vector3(15.8, 0.22, 4.8), Vector3(0.0, 3.92, 0.0), rooftile)
	for k in [-1.0, 1.0]:
		var kf: float = k
		var slope := Node3D.new()
		slope.position = Vector3(0.0, 4.28, kf * 1.45)
		slope.rotation.x = kf * 0.36
		bridge.add_child(slope)
		var slab := BoxMesh.new()
		slab.size = Vector3(15.8, 0.1, 2.55)
		var smi := MeshInstance3D.new()
		smi.mesh = slab
		smi.material_override = rooftile
		slope.add_child(smi)
		Build.tile_rows(slope, 2.55, 15.8)
	# đòn nóc + đầu đao vểnh
	Build.cyl(bridge, 0.10, 0.10, 15.9, Vector3(0.0, 5.02, 0.0), darkwood, 8).rotation.z = PI / 2.0
	for k in [-1.0, 1.0]:
		var kf: float = k
		var horn := Build.cyl(bridge, 0.012, 0.11, 0.75, Vector3(kf * 7.85, 5.18, 0.0), darkwood, 8)
		horn.rotation.z = kf * 1.05

	# ── MIẾU — GẮN MẶT BẮC (+z), protrudes ra ngoài hành lang (đã sửa vị trí) ──
	# Thật: shrine gắn dọc mặt Bắc tại điểm giữa nhịp, không ăn vào lối đi chính.
	Build.box(bridge, Vector3(2.2, 1.85, 1.3), Vector3(0.0, 1.18, 2.35), darkwood)
	Build.box(bridge, Vector3(2.6, 0.14, 1.75), Vector3(0.0, 2.14, 2.35), rooftile)
	for k in [-1.0, 1.0]:
		var kf: float = k
		var sroof := Node3D.new()
		sroof.position = Vector3(0.0, 2.32, 2.35 + kf * 0.62)
		sroof.rotation.x = kf * 0.44
		bridge.add_child(sroof)
		var ss := BoxMesh.new()
		ss.size = Vector3(2.6, 0.08, 1.15)
		var smi2 := MeshInstance3D.new()
		smi2.mesh = ss
		smi2.material_override = rooftile
		sroof.add_child(smi2)
	Build.box(bridge, Vector3(0.65, 0.95, 0.06), Vector3(0.0, 1.30, 1.73), darkwood)   # cửa miếu
	var altar_glow := OmniLight3D.new()
	altar_glow.light_color = Color(1.0, 0.55, 0.18)
	altar_glow.light_energy = 1.0
	altar_glow.omni_range = 3.5
	altar_glow.position = Vector3(0.0, 1.5, 2.55)
	bridge.add_child(altar_glow)

	# ── NHÀ BIA HAI ĐẦU CẦU (cream/hồng vữa — pavilion thật) ──
	for k in [-1.0, 1.0]:
		var kf: float = k
		var px: float = kf * 8.6
		Build.box(bridge, Vector3(1.9, 3.0, 4.0), Vector3(px, 1.5, 0.0), plaster)
		Build.box(bridge, Vector3(0.06, 2.0, 1.9), Vector3(px - kf * 0.97, 1.0, 0.0), darkwood)  # cửa vào
		Build.box(bridge, Vector3(2.3, 0.22, 4.4), Vector3(px, 3.2, 0.0), rooftile)
		for k2 in [-1.0, 1.0]:
			var k2f: float = k2
			var prslope := Node3D.new()
			prslope.position = Vector3(px, 3.40, k2f * 1.45)
			prslope.rotation.x = k2f * 0.37
			bridge.add_child(prslope)
			var ps := BoxMesh.new()
			ps.size = Vector3(2.3, 0.09, 2.5)
			var psmi := MeshInstance3D.new()
			psmi.mesh = ps
			psmi.material_override = rooftile
			prslope.add_child(psmi)

	# ── TƯỢNG TRẤN (một con mỗi đầu cầu, trong nhà bia) ──
	var statmat := Build.mat(Color(0.44, 0.42, 0.40), 0.85)
	for k in [-1.0, 1.0]:
		var kf: float = k
		var ped := Vector3(kf * 8.5, 0.0, 0.0)
		Build.box(bridge, Vector3(0.65, 0.72, 0.65), ped + Vector3(0.0, 0.36, 0.0), stonegrey)
		Build.ball(bridge, 0.23, 0.44, ped + Vector3(0.0, 0.96, 0.0), statmat)
		Build.ball(bridge, 0.135, 0.27, ped + Vector3(kf * 0.08, 1.32, 0.10), statmat)
		for ear in [-0.08, 0.08]:
			var earf: float = ear
			Build.cyl(bridge, 0.012, 0.045, 0.13, ped + Vector3(kf * 0.08 + earf, 1.48, 0.08), statmat, 6)

	# ── ĐÈN LỒNG 7 cái trải đều dưới mái ──
	for i in range(7):
		var lan := Build.lantern(bridge, 0.14, 0.26, Vector3(-4.5 + i * 1.5, 3.38, 0.0))
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
	geo_zone_on = true   # phố đã thức — từ giờ zone đổi theo nơi Minh đứng (Phase 7)


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


# Phase 8 — kẹp về điểm gần nhất trong union ROAM_RECTS (mạng phố mở sau light_up)
func _roam_clamp(pos: Vector3) -> Vector3:
	var best := pos
	var best_d := 1e18
	for r in ROAM_RECTS:
		var cx: float = clampf(pos.x, r["x0"], r["x1"])
		var cz: float = clampf(pos.z, r["z0"], r["z1"])
		var d: float = (cx - pos.x) * (cx - pos.x) + (cz - pos.z) * (cz - pos.z)
		if d < best_d:
			best_d = d
			best = Vector3(cx, pos.y, cz)
	best.y = ground_height(best)
	return best


func clamp_alley(pos: Vector3) -> Vector3:
	# Phase 8: phố đã thức (light_up) → mạng phố phía Nam mở, kẹp theo union rect
	if geo_zone_on and pos.z <= 8.0 and absf(pos.x) > ALLEY_HALF + 0.5:
		return _roam_clamp(pos)
	# trên phố Trần Phú: đi ngang thoải mái giữa hai màn sương
	# (|x|>5.5 luôn xử lý theo phố — kẻo lọt biên z=8 trên thềm Nam bị giật về ngõ)
	if pos.z > 8.0 or absf(pos.x) > ALLEY_HALF + 0.5:
		# ngõ hẹp khu cầu (Phase 7): đúng dải cổng hẹp thì lách qua sương tới chân cầu
		var xmin := -40.55 if (pos.z >= 9.95 and pos.z <= 12.05) else -37.5
		pos.x = clampf(pos.x, xmin, 37.5)
		if pos.x < -37.5:
			pos.z = clampf(pos.z, 9.95, 12.05)
		var on_floor := ground_height(pos) > 0.05
		# có tam cấp thì lên tận cửa; chỉ có thềm đá (Phase 7) thì đi dọc thềm;
		# không có gì thì dừng trước hiên
		var gh_n := ground_height(Vector3(pos.x, 0, 14.1))
		var zmax := 14.25 if gh_n > 0.3 else (14.1 if gh_n > 0.05 else 13.6)
		pos.z = clampf(pos.z, 8.0, zmax)
		# ngoài miệng ngõ thì không xuống được dãy nhà Nam — trừ khi đứng trên
		# bậc/thềm, hoặc đang ở miệng giao lộ ±(18.4..23.6) lúc phố đã mở (Phase 8)
		var in_mouth := geo_zone_on and absf(pos.x) >= 18.4 and absf(pos.x) <= 23.6
		if absf(pos.x) > ALLEY_HALF and pos.z < 8.4 and not on_floor and not in_mouth:
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
