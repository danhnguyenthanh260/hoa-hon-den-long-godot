# Căn nhà ống Hội An 2 TẦNG dựng CHUẨN THEO ẢNH Screenshots/ref-01.png.
# Đo từ ảnh (mặt tiền 6m làm gốc quy đổi):
#   - đế đá rêu cao ~0.78m, tam cấp 5 bậc giữa, có má bậc + trụ đầu bậc
#   - tầng trệt vữa vàng nghệ cao ~2.9m, trụ bổ tường 2 góc có đầu trụ,
#     cửa buôn 4 cánh gỗ nâu sậm rộng ~2.6m chiếm giữa
#   - MÁI HIÊN ngói chen giữa hai tầng, chìa ~0.9m, đỡ bằng hai con sơn gỗ
#   - tầng gác ốp ván gỗ nâu sậm, 3 ô cửa sổ chớp (giữa rộng, hai bên hẹp)
#   - mái âm dương ngói nâu rỉ, đòn dông song song mặt phố, hệ vữa trắng
# Phần đế/trụ/mái dùng chung từ hoian_parts.gd. Mặt sàn đi được: Parts.floor_rects.
extends RefCounted

const Build := preload("res://scripts/build.gd")
const Parts := preload("res://scripts/hoian_parts.gd")

const W := 6.0          # bề ngang mặt tiền
const D := 5.0          # chiều sâu thân nhà
const H_BASE := 0.78    # đế đá
const H1 := 2.9         # tầng trệt
const H2 := 2.2         # tầng gác
const Y1 := H_BASE + H1            # 3.68 — đỉnh tầng trệt
const Y2 := Y1 + 0.62 + H2         # đỉnh tầng gác (0.62 = dải mái hiên)


static func build(parent: Node3D, pos: Vector3, yrot: float, age: float = 0.5, out: Dictionary = {}) -> Node3D:
	var a := Node3D.new()
	a.position = pos
	a.rotation.y = yrot
	parent.add_child(a)
	var m := Parts.mats(age)

	Parts.plinth_steps(a, W, D, H_BASE, m)

	# ---------- thân tầng trệt: vữa vàng, chừa lỗ cửa giữa ----------
	var jamb_z := 1.15                                    # cửa 2.3m — chừa mảng tường thở hai bên (Phase 0)
	for side in [-1.0, 1.0]:
		var wz := (W / 2.0 + jamb_z) / 2.0                # tâm mảng tường bên
		Build.box(a, Vector3(D, H1, W / 2.0 - jamb_z), Vector3(D / 2.0, H_BASE + H1 / 2.0, side * wz), m["plaster"])
	# dải tường trên cửa (lanh tô vữa)
	Build.box(a, Vector3(D, 0.46, jamb_z * 2.0), Vector3(D / 2.0, Y1 - 0.23, 0), m["plaster"])
	# phong hóa mặt tiền theo tuổi (vệt ố nằm hai mảng tường, không đè cửa)
	Parts.weather_facade(a, W, H_BASE, Y1, m, 1)

	Parts.pilasters(a, W, H_BASE, H1, m)

	# cửa sổ chớp hai bên cửa buôn + ô gió song gỗ trên lanh tô
	# (tâm ±1.84: khe cửa↔viền = viền↔trụ ≈ 0.18m — mặt tiền có mảng tường thở)
	for wgz in [-1.84, 1.84]:
		Parts.window_ground(a, wgz, H_BASE, m)
	Parts.door_vent(a, Y1 - 0.21, 2.0, m)

	# ---------- cửa buôn 4 cánh gỗ + khung đen + mắt cửa ----------
	for jz in [-1.0, 1.0]:
		Build.box(a, Vector3(0.14, H1 - 0.4, 0.16), Vector3(-0.04, H_BASE + (H1 - 0.4) / 2.0, jz * jamb_z), m["frame"])
	Build.box(a, Vector3(0.16, 0.2, jamb_z * 2.0 + 0.3), Vector3(-0.045, Y1 - 0.52, 0), m["frame"])
	for li in range(4):                                   # 4 cánh, hơi thụt vào trong
		var lz := -0.825 + li * 0.55
		Build.box(a, Vector3(0.07, H1 - 0.62, 0.52), Vector3(0.12, H_BASE + (H1 - 0.62) / 2.0, lz), m["door"])
		# ô panel: bản dưới đặc, ô giữa, song chớp trên
		Build.box(a, Vector3(0.025, 0.95, 0.4), Vector3(0.08, H_BASE + 0.62, lz), m["frame"])
		Build.box(a, Vector3(0.025, 0.5, 0.4), Vector3(0.08, H_BASE + 1.45, lz), m["frame"])
		for sl in range(5):
			var slat := Build.box(a, Vector3(0.025, 0.05, 0.4), Vector3(0.085, H_BASE + 1.85 + sl * 0.11, lz), m["shutter"])
			slat.rotation.z = 0.5
	for ez in [-0.36, 0.36]:                              # mắt cửa trên đố giữa
		Build.door_eye(a, Vector3(0.02, Y1 - 0.52, ez), 1.0)

	# ---------- mái hiên ngói giữa hai tầng + con sơn ----------
	var awn := Node3D.new()
	awn.position = Vector3(-0.42, Y1 + 0.3, 0)
	awn.rotation.z = 0.42
	a.add_child(awn)
	# bề ngang hiên = W - 0.04: nhà liền kề, hiên không vắt sang nhà bên
	var awn_w := W - 0.04
	var awn_slab := BoxMesh.new()
	awn_slab.size = Vector3(1.35, 0.06, awn_w)
	var awn_mi := MeshInstance3D.new()
	awn_mi.mesh = awn_slab
	awn_mi.material_override = m["roof_tex"]
	awn.add_child(awn_mi)
	Build.tile_rows(awn, 1.35, awn_w, m["tile_c"])
	# hàng đầu ống ngói sáng màu dọc mép hiên
	for ci in range(int(awn_w / 0.22)):
		Build.cyl(awn, 0.052, 0.052, 0.03, Vector3(-0.66, 0.07, -awn_w / 2.0 + 0.11 + ci * 0.22), Build.mat(Color(0.72, 0.68, 0.6), 0.8), 8).rotation.x = PI / 2.0
	# diềm gỗ + hai con sơn đỡ hiên (khối đen trên góc cửa như ảnh)
	Build.box(a, Vector3(0.05, 0.18, awn_w), Vector3(-0.95, Y1 + 0.04, 0), m["frame"])
	for cz in [-jamb_z, jamb_z]:
		Build.box(a, Vector3(0.55, 0.14, 0.16), Vector3(-0.3, Y1 - 0.07, cz), m["frame"])
		Build.box(a, Vector3(0.14, 0.34, 0.16), Vector3(-0.08, Y1 - 0.24, cz), m["frame"])

	# ---------- tầng gác ốp ván gỗ + 3 ô cửa sổ chớp ----------
	var y2_mid := Y1 + 0.62 + H2 / 2.0
	Build.box(a, Vector3(D, H2 + 0.62, W), Vector3(D / 2.0, Y1 + (H2 + 0.62) / 2.0, 0), m["plaster"])
	Build.box(a, Vector3(0.1, H2, W - 0.02), Vector3(-0.03, y2_mid, 0), m["wood"])
	# đố dọc chia 3 gian + xà ngang chân/đầu cửa sổ — đố góc lùi vào trong biên
	for vz in [-2.93, -1.32, 1.32, 2.93]:
		Build.box(a, Vector3(0.13, H2, 0.13), Vector3(-0.06, y2_mid, vz), m["frame"])
	var sill_y := Y1 + 0.62 + 0.42
	var head_y := sill_y + 1.3
	Build.box(a, Vector3(0.12, 0.12, W - 0.02), Vector3(-0.055, sill_y - 0.06, 0), m["frame"])
	Build.box(a, Vector3(0.12, 0.1, W - 0.02), Vector3(-0.055, head_y + 0.05, 0), m["frame"])
	# cửa sổ: [tâm z, bề rộng] — giữa rộng 1.7m, hai bên 1.0m; cánh chớp NỔI trước khung
	for wdef in [[0.0, 1.7], [-2.16, 1.0], [2.16, 1.0]]:
		var wz: float = wdef[0]
		var ww: float = wdef[1]
		Build.box(a, Vector3(0.06, 1.3, ww), Vector3(-0.04, sill_y + 0.65, wz), m["frame"])
		var leaves := 2 if ww > 1.2 else 1
		var lw := (ww - 0.12) / leaves
		for li in range(leaves):
			var lz := wz - (ww - 0.12) / 2.0 + lw * (li + 0.5)
			Build.box(a, Vector3(0.05, 1.18, lw - 0.06), Vector3(-0.1, sill_y + 0.65, lz), m["shutter"])
			for sl in range(7):
				var slat := Build.box(a, Vector3(0.028, 0.05, lw - 0.16), Vector3(-0.13, sill_y + 0.18 + sl * 0.16, lz), m["frame"])
				slat.rotation.z = 0.55
	# ván diềm sát mái
	Build.box(a, Vector3(0.06, 0.24, W - 0.02), Vector3(-0.045, Y2 - 0.1, 0), m["frame"])

	# dãy đèn lồng dưới mép mái hiên giữa tầng — world đăng ký để light_up thắp
	var lans: Array = out.get("lanterns", [])
	for lz in [-2.1, -0.7, 0.7, 2.1]:
		lans.append(Build.lantern(a, 0.13, 0.26, Vector3(-0.85, Y1 + 0.06, lz)))
	out["lanterns"] = lans

	Parts.roof_amduong(a, W, D, Y2 + 0.1, m)
	return a
