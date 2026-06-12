# Bộ phận kiến trúc Hội An dùng chung cho các mẫu nhà dựng theo ảnh ref
# (đế đá + tam cấp, trụ bổ tường, mái âm dương + hệ vữa trắng).
# Quy ước không gian cục bộ như world._house: mặt tiền tại x=0 quay -x, thân +x.
extends RefCounted

const Build := preload("res://scripts/build.gd")


# bảng vật liệu theo TUỔI NHÀ: age 0 = mới sơn, 0.5 = hơi cũ, 1 = cổ
# (vữa VÀNG NGÀ oxi hóa dần, vữa trắng ngả xám, ngói bạc màu, gỗ phai,
#  đá xám bê tông sần hạt — texture thật, lên rêu theo tuổi)
static func mats(age: float = 0.45) -> Dictionary:
	var plaster_c := Color(0.96, 0.8, 0.46).lerp(Color(0.7, 0.6, 0.42), age * 0.9)
	var trim_c := Color(0.93, 0.92, 0.88).lerp(Color(0.71, 0.7, 0.61), age)
	var stone_c := Color(0.62, 0.6, 0.55).lerp(Color(0.44, 0.5, 0.38), age)
	var step_c := Color(0.74, 0.72, 0.66).lerp(Color(0.56, 0.6, 0.46), age)
	var tile_tint := Color(0.65, 0.46, 0.32).lerp(Color(0.42, 0.36, 0.3), age)
	var tile_row_c := Color(0.48, 0.3, 0.21).lerp(Color(0.3, 0.26, 0.22), age)
	var wood_c := Color(0.5, 0.35, 0.22).lerp(Color(0.33, 0.26, 0.2), age)
	return {
		"plaster": Build.pbr("res://assets/textures/Plaster001", 0.5, plaster_c, 1.3 + age * 0.6),
		"wood": Build.pbr("res://assets/textures/WoodFloor043", 0.85, wood_c, 1.1),
		"door": Build.pbr("res://assets/textures/WoodFloor043", 0.85, wood_c.darkened(0.24), 1.1),
		"shutter": Build.mat(wood_c.darkened(0.34), 0.85),
		"frame": Build.mat(Color(0.14, 0.1, 0.07), 0.85),
		"trim": Build.mat(trim_c, 0.85),
		"stone": Build.pbr("res://assets/textures/ConcreteWall004", 0.55, stone_c, 1.4),
		"step": Build.pbr("res://assets/textures/ConcreteWall004", 0.4, step_c, 1.2),
		"roof_tex": Build.pbr("res://assets/textures/RoofingTiles013A", 0.6, tile_tint, 1.2),
		"tile_c": tile_row_c,
		"moss": Build.mat(Color(0.13, 0.18, 0.09), 0.98),
		"leaf": Build.mat(Color(0.16, 0.3, 0.1), 0.95),
		"pot": Build.mat(Color(0.45, 0.28, 0.2).lerp(Color(0.36, 0.3, 0.2), age), 0.9),
		"age": age,
	}


# vết ố mưa + rêu chân tường theo tuổi nhà — gọi sau khi dựng xong mặt tiền.
# Vị trí giả-ngẫu-nhiên deterministic theo seed để screenshot ổn định.
static func weather_facade(a: Node3D, w: float, h_base: float, h_top: float, m: Dictionary, seed_i: int = 0) -> void:
	var age: float = m["age"]
	if age < 0.15:
		return
	var grime := StandardMaterial3D.new()
	grime.albedo_color = Color(0.22, 0.2, 0.15, 0.08 + 0.2 * age)
	grime.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grime.roughness = 1.0
	for i in range(int(2.0 + age * 4.0)):
		var z := -w / 2.0 + 0.5 + fposmod(i * 2.13 + seed_i * 1.37, w - 1.0)
		var sh := 0.4 + fposmod(i * 1.7 + seed_i, 1.0) * (h_top - h_base) * 0.4
		var gb := Build.box(a, Vector3(0.012, sh, 0.28 + 0.3 * fposmod(i * 0.9, 1.0)), Vector3(-0.02, h_base + sh / 2.0, z), grime)
		gb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# rêu bám dọc mép đế và góc tường khi nhà đã cũ
	if age > 0.55:
		for i in range(int(3.0 + age * 5.0)):
			var z2 := -w / 2.0 + 0.3 + fposmod(i * 1.61 + seed_i * 0.7, w - 0.6)
			Build.ball(a, 0.09 + 0.08 * fposmod(i * 0.77, 1.0), 0.12, Vector3(-0.04, h_base + 0.05, z2), m["moss"])


# dây leo rủ trên mép mái + đám lá bám ngói — cho nhà cũ (ref-06, ref "cây um tùm ngói")
static func roof_vines(slope: Node3D, slab_l: float, roof_w: float, m: Dictionary, amount: float = 1.0) -> void:
	for i in range(int(8.0 * amount)):
		var z := -roof_w / 2.0 + 0.4 + fposmod(i * 1.93, roof_w - 0.8)
		var x := -slab_l / 2.0 + 0.3 + fposmod(i * 1.27, slab_l - 0.6)
		Build.ball(slope, 0.16 + 0.14 * fposmod(i * 0.83, 1.0), 0.2, Vector3(x, 0.14, z), m["leaf"] if i % 3 != 0 else m["moss"])


# đế đá rêu + gờ đỉnh + tam cấp 5 bậc giữa, má bậc và trụ đầu bậc hai bên
static func plinth_steps(a: Node3D, w: float, d: float, h_base: float, m: Dictionary) -> void:
	Build.box(a, Vector3(d + 0.18, h_base, w + 0.22), Vector3(d / 2.0, h_base / 2.0, 0), m["stone"])
	Build.box(a, Vector3(d + 0.3, 0.09, w + 0.34), Vector3(d / 2.0, h_base - 0.045, 0), m["step"])
	# rêu bám chân đế + lan lên mặt đá theo tuổi nhà
	var age: float = m["age"]
	if age > 0.25:
		for i in range(int(3.0 + age * 7.0)):
			var z := -w / 2.0 + 0.3 + fposmod(i * 1.73, w - 0.6)
			var mr := 0.07 + 0.08 * fposmod(i * 0.91, 1.0)
			var my := 0.04 + fposmod(i * 0.37, 1.0) * h_base * 0.55
			var mb := Build.ball(a, mr, mr * 0.9, Vector3(-0.1 - 0.04 * fposmod(i * 0.53, 1.0), my, z), m["moss"])
			mb.scale = Vector3(0.35, 1.0, 1.0)
	var rise := h_base / 5.0
	for i in range(5):
		var top_y := h_base - i * rise
		Build.box(a, Vector3(0.28, rise, 3.1), Vector3(-0.14 - i * 0.28, top_y - rise / 2.0, 0), m["step"])
	for sz in [-1.62, 1.62]:
		Build.box(a, Vector3(1.45, 0.4, 0.26), Vector3(-0.72, 0.2, sz), m["stone"])
		Build.box(a, Vector3(0.7, 0.34, 0.26), Vector3(-0.35, 0.57, sz), m["stone"])
		Build.box(a, Vector3(0.36, 0.52, 0.36), Vector3(-1.5, 0.26, sz), m["stone"])
		Build.box(a, Vector3(0.44, 0.09, 0.44), Vector3(-1.5, 0.56, sz), m["step"])


# mặt sàn người đi được (LOCAL): mặt đế + từng bậc — world đổi sang rect thế giới
static func floor_rects(w: float, d: float, h_base: float) -> Array:
	var out: Array = [{"x0": -0.09, "x1": d + 0.09, "z0": -(w / 2.0 + 0.11), "z1": w / 2.0 + 0.11, "y": h_base}]
	var rise := h_base / 5.0
	for i in range(5):
		out.append({"x0": -0.28 * (i + 1), "x1": -0.28 * i, "z0": -1.55, "z1": 1.55, "y": h_base - i * rise})
	return out


# ---------- chậu cây cảnh đất nung (ref-09) ----------
# kind: 0 bonsai, 1 quất quả cam, 2 chuối cảnh, 3 dương xỉ/bụi rủ
static func pot_plant(parent: Node3D, pos: Vector3, kind: int, s: float = 1.0, age: float = 0.5) -> Node3D:
	var p := Node3D.new()
	p.position = pos
	parent.add_child(p)
	var clay := Build.mat(Color(0.52, 0.3, 0.2).lerp(Color(0.38, 0.32, 0.22), age * 0.7), 0.92)
	var soil := Build.mat(Color(0.16, 0.11, 0.07), 1.0)
	var trunk := Build.mat(Color(0.3, 0.2, 0.12), 0.95)
	var leaf := Build.mat(Color(0.2, 0.38, 0.12), 0.9)
	var leaf_d := Build.mat(Color(0.12, 0.24, 0.08), 0.95)
	var r := 0.26 * s
	var h := 0.34 * s
	# chậu bụng phình miệng loe + lớp đất
	Build.lathe(p, [Vector2(r * 0.62, 0), Vector2(r * 0.95, h * 0.35), Vector2(r, h * 0.72), Vector2(r * 0.86, h * 0.9), Vector2(r * 0.93, h)], Vector3.ZERO, clay, 14)
	Build.cyl(p, r * 0.78, r * 0.78, 0.025, Vector3(0, h, 0), soil, 12)
	match kind:
		0:	# bonsai: thân vặn nghiêng + tán dẹt xếp tầng
			var t1 := Build.cyl(p, 0.025 * s, 0.05 * s, 0.32 * s, Vector3(0, h + 0.14 * s, 0), trunk, 6)
			t1.rotation.z = 0.35
			var t2 := Build.cyl(p, 0.016 * s, 0.024 * s, 0.22 * s, Vector3(-0.1 * s, h + 0.3 * s, 0), trunk, 6)
			t2.rotation.z = -0.55
			for pad in [[-0.16, 0.42, 0.0, 0.17], [0.07, 0.33, 0.06, 0.12], [-0.05, 0.5, -0.05, 0.1]]:
				var b := Build.ball(p, pad[3] * s, pad[3] * 2.0 * s, Vector3(pad[0] * s, h + pad[1] * s, pad[2] * s), leaf_d)
				b.scale = Vector3(1.0, 0.32, 1.0)
		1:	# quất: tán tròn dày + quả cam đính NGOÀI mặt tán mới thấy được
			Build.cyl(p, 0.03 * s, 0.04 * s, 0.32 * s, Vector3(0, h + 0.15 * s, 0), trunk, 6)
			Build.ball(p, 0.3 * s, 0.56 * s, Vector3(0, h + 0.52 * s, 0), leaf)
			for fi in range(9):
				var ang := fi * 2.7
				var fy := sin(fi * 1.3) * 0.55
				var fr := sqrt(maxf(0.04, 1.0 - fy * fy))
				Build.ball(p, 0.042 * s, 0.084 * s, Vector3(cos(ang) * fr * 0.3 * s, h + (0.52 + fy * 0.27) * s, sin(ang) * fr * 0.3 * s), Build.mat(Color(0.95, 0.55, 0.1), 0.6))
		2:	# chuối cảnh: thân giả + tàu lá to cong ra ngoài
			Build.cyl(p, 0.05 * s, 0.075 * s, 0.55 * s, Vector3(0, h + 0.26 * s, 0), Build.mat(Color(0.45, 0.55, 0.3), 0.85), 8)
			for li in range(6):
				var ang := li * 1.05 + 0.4
				var lb := Build.ball(p, 0.4 * s, 0.8 * s, Vector3(cos(ang) * 0.3 * s, h + (0.62 + 0.1 * (li % 3)) * s, sin(ang) * 0.3 * s), Build.mat(Color(0.25, 0.5, 0.14), 0.75))
				lb.scale = Vector3(0.85, 0.12, 0.3)
				lb.rotation.y = -ang
				lb.rotation.z = 0.45
		3:	# dương xỉ / bụi lá rủ quanh miệng chậu
			for li in range(8):
				var ang := li * 0.79
				var fb := Build.ball(p, 0.17 * s, 0.34 * s, Vector3(cos(ang) * 0.14 * s, h + 0.1 * s, sin(ang) * 0.14 * s), leaf if li % 2 == 0 else leaf_d)
				fb.scale = Vector3(1.0, 0.45, 0.4)
				fb.rotation.y = -ang
				fb.rotation.z = 0.5
	return p


# bụi chuối mọc thẳng từ đất — "có nơi có cây chuối" (ref-09)
static func banana_clump(parent: Node3D, pos: Vector3, s: float = 1.5) -> Node3D:
	var p := Node3D.new()
	p.position = pos
	parent.add_child(p)
	for st in range(3):
		var off := Vector3(sin(st * 2.5) * 0.3 * s, 0, cos(st * 2.5) * 0.3 * s)
		var hh := (1.1 + 0.4 * (st % 2)) * s
		Build.cyl(p, 0.05 * s, 0.09 * s, hh, off + Vector3(0, hh / 2.0, 0), Build.mat(Color(0.45, 0.55, 0.3), 0.85), 8)
		for li in range(5):
			var ang := li * 1.26 + st
			var lb := Build.ball(p, 0.5 * s, 1.0 * s, off + Vector3(cos(ang) * 0.35 * s, hh + 0.15 * s, sin(ang) * 0.35 * s), Build.mat(Color(0.22, 0.46, 0.12), 0.75))
			lb.scale = Vector3(0.9, 0.12, 0.3)
			lb.rotation.y = -ang
			lb.rotation.z = 0.5
	return p


# ---------- xe đạp cũ (ref-07): khung xanh rêu, giỏ mây, chắn bùn ----------
# dựng dọc trục x cục bộ (đầu xe về -x); lean nghiêng dựa tường quanh trục dọc
static func bicycle(parent: Node3D, pos: Vector3, yrot: float, lean: float = 0.0) -> Node3D:
	var b := Node3D.new()
	b.position = pos
	b.rotation.y = yrot
	b.rotation.x = lean
	parent.add_child(b)
	var frame_m := Build.mat(Color(0.16, 0.26, 0.18), 0.5)
	var rubber := Build.mat(Color(0.07, 0.07, 0.07), 0.85)
	var chrome := Build.mat(Color(0.62, 0.62, 0.58), 0.3)
	var rattan := Build.mat(Color(0.55, 0.4, 0.2), 0.92)
	var wr := 0.33
	for wx in [-0.55, 0.55]:
		var wheel := Node3D.new()
		wheel.position = Vector3(wx, wr, 0)
		b.add_child(wheel)
		var tor := TorusMesh.new()
		tor.inner_radius = wr - 0.035
		tor.outer_radius = wr
		var tmi := MeshInstance3D.new()
		tmi.mesh = tor
		tmi.material_override = rubber
		tmi.rotation.x = PI / 2.0
		wheel.add_child(tmi)
		var hub := Build.cyl(wheel, 0.035, 0.035, 0.07, Vector3.ZERO, chrome, 8)
		hub.rotation.x = PI / 2.0
		for sp in range(6):
			var spoke := Build.cyl(wheel, 0.0045, 0.0045, wr * 1.85, Vector3.ZERO, chrome, 4)
			spoke.rotation.z = sp * PI / 6.0
		# chắn bùn ôm nửa trên bánh
		for fa in range(5):
			var ang := PI * 0.28 + fa * PI * 0.11
			var fb := Build.box(wheel, Vector3(0.13, 0.014, 0.08), Vector3(cos(ang) * (wr + 0.03), sin(ang) * (wr + 0.03), 0), frame_m)
			fb.rotation.z = ang + PI / 2.0
	# khung nữ ống chéo đôi + cọc yên + càng trước
	var down := Build.cyl(b, 0.019, 0.019, 0.85, Vector3(-0.06, 0.55, 0), frame_m, 6)
	down.rotation.z = 1.15
	var down2 := Build.cyl(b, 0.015, 0.015, 0.8, Vector3(-0.08, 0.47, 0), frame_m, 6)
	down2.rotation.z = 1.28
	var seat_tube := Build.cyl(b, 0.019, 0.019, 0.52, Vector3(0.34, 0.64, 0), frame_m, 6)
	seat_tube.rotation.z = 0.22
	var stays := Build.cyl(b, 0.014, 0.014, 0.5, Vector3(0.45, 0.5, 0), frame_m, 6)
	stays.rotation.z = -0.75
	var fork := Build.cyl(b, 0.018, 0.018, 0.6, Vector3(-0.49, 0.62, 0), frame_m, 6)
	fork.rotation.z = -0.28
	# ghi-đông + tay nắm vểnh sau + yên da + gác-ba-ga + giỏ mây
	var hbar := Build.cyl(b, 0.014, 0.014, 0.4, Vector3(-0.42, 0.99, 0), chrome, 6)
	hbar.rotation.x = PI / 2.0
	for hz in [-1.0, 1.0]:
		var grip := Build.cyl(b, 0.018, 0.018, 0.12, Vector3(-0.38, 0.99, hz * 0.21), rubber, 6)
		grip.rotation.x = PI / 2.0
		grip.rotation.y = hz * 0.5
	var saddle := Build.ball(b, 0.13, 0.26, Vector3(0.42, 0.92, 0), rubber)
	saddle.scale = Vector3(1.0, 0.28, 0.6)
	Build.box(b, Vector3(0.34, 0.02, 0.24), Vector3(0.56, 0.62, 0), chrome)
	for rz in [-0.09, 0.09]:
		Build.box(b, Vector3(0.3, 0.015, 0.02), Vector3(0.55, 0.6, rz), chrome)
	var basket := Build.box(b, Vector3(0.28, 0.22, 0.32), Vector3(-0.56, 0.84, 0), rattan)
	basket.scale = Vector3(1.0, 1.0, 1.0)
	Build.box(b, Vector3(0.3, 0.03, 0.34), Vector3(-0.56, 0.95, 0), Build.mat(Color(0.42, 0.3, 0.14), 0.9))
	# giò đạp + xích
	var crank := Build.cyl(b, 0.07, 0.07, 0.04, Vector3(0.08, 0.3, 0), chrome, 10)
	crank.rotation.x = PI / 2.0
	for pk in [-1.0, 1.0]:
		Build.box(b, Vector3(0.1, 0.025, 0.06), Vector3(0.08 + pk * 0.1, 0.3 + pk * 0.1, pk * 0.08), rubber)
	return b


# ---------- xe Cub cũ (ref-08): dè kem + yên nâu ----------
static func motorbike(parent: Node3D, pos: Vector3, yrot: float) -> Node3D:
	var b := Node3D.new()
	b.position = pos
	b.rotation.y = yrot
	parent.add_child(b)
	var cream := Build.mat(Color(0.78, 0.73, 0.6), 0.55)
	var brown := Build.mat(Color(0.3, 0.19, 0.11), 0.7)
	var rubber := Build.mat(Color(0.08, 0.08, 0.08), 0.85)
	var chrome := Build.mat(Color(0.65, 0.65, 0.6), 0.25)
	var engine := Build.mat(Color(0.35, 0.35, 0.37), 0.5)
	var wr := 0.27
	for wx in [-0.62, 0.62]:
		var wheel := Node3D.new()
		wheel.position = Vector3(wx, wr, 0)
		b.add_child(wheel)
		var tor := TorusMesh.new()
		tor.inner_radius = wr - 0.05
		tor.outer_radius = wr
		var tmi := MeshInstance3D.new()
		tmi.mesh = tor
		tmi.material_override = rubber
		tmi.rotation.x = PI / 2.0
		wheel.add_child(tmi)
		var hub := Build.cyl(wheel, 0.07, 0.07, 0.09, Vector3.ZERO, chrome, 10)
		hub.rotation.x = PI / 2.0
		for sp in range(5):
			var spoke := Build.cyl(wheel, 0.006, 0.006, wr * 1.7, Vector3.ZERO, chrome, 4)
			spoke.rotation.z = sp * PI / 5.0
		# dè kem ôm nửa trên bánh
		for fa in range(5):
			var ang := PI * 0.22 + fa * PI * 0.14
			var fb := Build.box(wheel, Vector3(0.16, 0.025, 0.14), Vector3(cos(ang) * (wr + 0.045), sin(ang) * (wr + 0.045), 0), cream)
			fb.rotation.z = ang + PI / 2.0
	# càng trước + đèn pha + ghi-đông
	var fork := Build.cyl(b, 0.022, 0.022, 0.62, Vector3(-0.56, 0.6, 0), cream, 8)
	fork.rotation.z = -0.3
	Build.ball(b, 0.085, 0.17, Vector3(-0.62, 0.95, 0), chrome)
	var hbar := Build.cyl(b, 0.015, 0.015, 0.46, Vector3(-0.52, 1.04, 0), brown, 6)
	hbar.rotation.x = PI / 2.0
	var mir := Build.cyl(b, 0.005, 0.005, 0.09, Vector3(-0.5, 1.1, 0.13), chrome, 4)
	mir.rotation.z = 0.3
	Build.ball(b, 0.022, 0.044, Vector3(-0.48, 1.15, 0.14), chrome)
	# yếm che chân: tấm cong nhỏ ôm cổ phuộc, không che kín như tấm ván
	var shield := Build.box(b, Vector3(0.04, 0.4, 0.32), Vector3(-0.38, 0.62, 0), cream)
	shield.rotation.z = -0.3
	Build.box(b, Vector3(0.42, 0.04, 0.5), Vector3(-0.05, 0.32, 0), rubber)
	# thân bụng cong (khung cong chữ S đặc trưng Cub) + máy + ống pô
	var spine := Build.ball(b, 0.3, 0.6, Vector3(0.08, 0.62, 0), cream)
	spine.scale = Vector3(1.5, 0.45, 0.55)
	Build.box(b, Vector3(0.3, 0.24, 0.26), Vector3(0.06, 0.36, 0), engine)
	var exhaust := Build.cyl(b, 0.035, 0.045, 0.62, Vector3(0.36, 0.3, 0.12), chrome, 8)
	exhaust.rotation.z = PI / 2.0 - 0.08
	# yên nâu hai tầng + gác-ba-ga sau
	var seat := Build.ball(b, 0.17, 0.34, Vector3(0.12, 0.84, 0), brown)
	seat.scale = Vector3(1.35, 0.4, 0.75)
	var seat2 := Build.ball(b, 0.14, 0.28, Vector3(0.42, 0.86, 0), brown)
	seat2.scale = Vector3(1.1, 0.35, 0.7)
	Build.box(b, Vector3(0.3, 0.02, 0.3), Vector3(0.62, 0.78, 0), chrome)
	for rz in [-0.12, 0.0, 0.12]:
		Build.box(b, Vector3(0.26, 0.015, 0.02), Vector3(0.62, 0.76, rz), chrome)
	# chân chống giữa
	for kz in [-0.08, 0.08]:
		var kst := Build.cyl(b, 0.012, 0.012, 0.3, Vector3(0.18, 0.14, kz), engine, 4)
		kst.rotation.z = 0.25
	return b


# ---------- ban công lan can bông gió (ref-05) ----------
# sàn chìa ra trước mặt tiền tại cao độ y_floor, lan can bông gió trắng + chậu cây
static func balcony_breeze(a: Node3D, w: float, y_floor: float, m: Dictionary) -> void:
	var depth := 0.85
	Build.box(a, Vector3(depth, 0.1, w), Vector3(-depth / 2.0, y_floor, 0), m["trim"])
	Build.box(a, Vector3(depth - 0.08, 0.07, w - 0.1), Vector3(-depth / 2.0, y_floor - 0.08, 0), m["wood"])
	for bz in [-w / 2.0 + 0.35, 0.0, w / 2.0 - 0.35]:
		var bracket := Build.box(a, Vector3(0.3, 0.3, 0.12), Vector3(-0.4, y_floor - 0.26, bz), m["frame"])
		bracket.rotation.z = 0.78
	var rail_h := 0.78
	Build.breeze_panel(a, Vector3(-depth + 0.04, y_floor + 0.42, 0), int((w - 0.5) / 0.36), 2, 0.36)
	Build.box(a, Vector3(0.12, 0.07, w), Vector3(-depth + 0.04, y_floor + rail_h + 0.1, 0), m["trim"])
	for pz in [-1.0, 1.0]:
		Build.box(a, Vector3(0.14, rail_h + 0.2, 0.14), Vector3(-depth + 0.04, y_floor + (rail_h + 0.2) / 2.0, pz * (w / 2.0 - 0.07)), m["trim"])
		# lan can hồi hai bên kín thấp
		Build.box(a, Vector3(depth - 0.1, 0.45, 0.07), Vector3(-depth / 2.0, y_floor + 0.28, pz * (w / 2.0 - 0.05)), m["trim"])
	pot_plant(a, Vector3(-depth + 0.32, y_floor + 0.05, -w / 2.0 + 0.38), 3, 0.75)
	pot_plant(a, Vector3(-depth + 0.32, y_floor + 0.05, w / 2.0 - 0.38), 1, 0.7)


# trụ bổ tường hai góc mặt tiền: đầu trụ chỉ vữa trắng, chân ố xám
static func pilasters(a: Node3D, w: float, h_base: float, h1: float, m: Dictionary) -> void:
	for pz in [-1.0, 1.0]:
		var zc: float = pz * (w / 2.0 - 0.28)
		Build.box(a, Vector3(0.14, h1, 0.56), Vector3(-0.065, h_base + h1 / 2.0, zc), m["plaster"])
		Build.box(a, Vector3(0.18, 0.07, 0.64), Vector3(-0.075, h_base + h1 - 0.1, zc), m["trim"])
		Build.box(a, Vector3(0.16, 0.06, 0.6), Vector3(-0.07, h_base + h1 - 0.2, zc), m["trim"])
		Build.box(a, Vector3(0.17, 0.55, 0.6), Vector3(-0.07, h_base + 0.275, zc), m["stone"])


# mái âm dương đòn dông song song mặt phố + toàn bộ hệ vữa trắng
# (bờ chảy, đuôi hất, bờ nóc + ô trang trí + đuôi én). Trả về cao độ đòn dông.
static func roof_amduong(a: Node3D, w: float, d: float, eave_y: float, m: Dictionary) -> float:
	var pitch := 0.45
	var run := d / 2.0 + 0.55                  # hình chiếu ngang một vạt mái
	var slab_l := run / cos(pitch)
	var roof_w := w + 0.9                      # chìa hồi 0.45m mỗi bên
	var ridge_y := eave_y + run * tan(pitch)
	for k in [-1.0, 1.0]:
		var slope := Node3D.new()
		slope.position = Vector3(d / 2.0 + k * (slab_l / 2.0) * cos(pitch), ridge_y - (slab_l / 2.0) * sin(pitch), 0)
		slope.rotation.z = -k * pitch
		a.add_child(slope)
		var slab := BoxMesh.new()
		slab.size = Vector3(slab_l, 0.08, roof_w)
		var slab_mi := MeshInstance3D.new()
		slab_mi.mesh = slab
		slab_mi.material_override = m["roof_tex"]
		slope.add_child(slab_mi)
		Build.tile_rows(slope, slab_l, roof_w, m["tile_c"])
		# bờ chảy TRẮNG dọc hai mép hồi + đuôi hất lên ở đầu giọt ranh
		for vz in [-roof_w / 2.0, roof_w / 2.0]:
			Build.box(slope, Vector3(slab_l + 0.05, 0.16, 0.24), Vector3(0, 0.14, vz), m["trim"])
			var tip := Build.box(slope, Vector3(0.5, 0.16, 0.24), Vector3(k * (slab_l / 2.0 - 0.14), 0.28, vz), m["trim"])
			tip.rotation.z = k * 0.4
		# hàng đầu ống ngói sáng dọc giọt ranh
		for ci in range(int(roof_w / 0.22)):
			Build.cyl(slope, 0.052, 0.052, 0.03, Vector3(k * (slab_l / 2.0 - 0.01), 0.07, -roof_w / 2.0 + 0.11 + ci * 0.22), Build.mat(Color(0.72, 0.68, 0.6), 0.8), 8).rotation.x = PI / 2.0
	# bờ nóc trắng: ô trang trí giữa + hai đầu đuôi én cong vút
	Build.box(a, Vector3(0.32, 0.24, roof_w + 0.1), Vector3(d / 2.0, ridge_y + 0.08, 0), m["trim"])
	Build.box(a, Vector3(0.38, 0.44, 1.35), Vector3(d / 2.0, ridge_y + 0.16, 0), m["trim"])
	Build.box(a, Vector3(0.42, 0.28, 1.0), Vector3(d / 2.0, ridge_y + 0.16, 0), Build.mat(Color(0.8, 0.79, 0.74), 0.9))
	for ke in [-1.0, 1.0]:
		var ze: float = ke * (roof_w + 0.1) / 2.0
		var s1 := Build.box(a, Vector3(0.3, 0.24, 0.8), Vector3(d / 2.0, ridge_y + 0.12, ze - ke * 0.32), m["trim"])
		s1.rotation.x = -ke * 0.28
		var s2 := Build.box(a, Vector3(0.28, 0.22, 0.6), Vector3(d / 2.0, ridge_y + 0.34, ze + ke * 0.02), m["trim"])
		s2.rotation.x = -ke * 0.65
		var s3 := Build.box(a, Vector3(0.26, 0.2, 0.45), Vector3(d / 2.0, ridge_y + 0.58, ze + ke * 0.22), m["trim"])
		s3.rotation.x = -ke * 1.0
		var horn := Build.cyl(a, 0.035, 0.13, 0.55, Vector3(d / 2.0, ridge_y + 0.84, ze + ke * 0.38), m["trim"], 8)
		horn.rotation.x = -ke * 1.2
	return ridge_y
