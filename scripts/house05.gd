# Nhà Hội An MỘT TẦNG HIÊN GỖ — nhà buôn mặt phố thấp (ref-01/ref-10 dạng 1 tầng):
#   - đế đá thấp + tam cấp, thân vữa vàng
#   - cửa buôn rộng giữa (thượng song hạ bản) + biển hiệu gỗ viền vàng
#   - hai cửa sổ chớp gỗ hai bên
#   - hiên ngói che vỉa hè trên hai cột gỗ + dãy đèn lồng
# out: {"lanterns": [...], "windows": [...]}.
extends RefCounted

const Build := preload("res://scripts/build.gd")
const Parts := preload("res://scripts/hoian_parts.gd")

const W := 6.0
const D := 5.0
const H_BASE := 0.6
const H1 := 3.1
const Y1 := H_BASE + H1


static func build(parent: Node3D, pos: Vector3, yrot: float, age: float = 0.5, out: Dictionary = {}) -> Node3D:
	var a := Node3D.new()
	a.position = pos
	a.rotation.y = yrot
	parent.add_child(a)
	var m := Parts.mats(age)

	Parts.plinth_steps(a, W, D, H_BASE, m)

	# ---------- thân vữa vàng, chừa lỗ cửa buôn giữa ----------
	var jamb_z := 1.1
	for side in [-1.0, 1.0]:
		var wz := (W / 2.0 + jamb_z) / 2.0
		Build.box(a, Vector3(D, H1, W / 2.0 - jamb_z), Vector3(D / 2.0, H_BASE + H1 / 2.0, side * wz), m["plaster"])
	Build.box(a, Vector3(D, 0.8, jamb_z * 2.0), Vector3(D / 2.0, Y1 - 0.4, 0), m["plaster"])
	Parts.weather_facade(a, W, H_BASE, Y1, m, 5)
	Parts.pilasters(a, W, H_BASE, H1, m)

	# ---------- cửa buôn: thượng song hạ bản + mắt cửa ----------
	for jz in [-1.0, 1.0]:
		Build.box(a, Vector3(0.14, H1 - 0.8, 0.16), Vector3(-0.04, H_BASE + (H1 - 0.8) / 2.0, jz * jamb_z), m["frame"])
	Build.box(a, Vector3(0.16, 0.18, jamb_z * 2.0 + 0.3), Vector3(-0.045, Y1 - 0.85, 0), m["frame"])
	# cửa đóng kín nguyên tấm — rèm/nội thất là chuyện bên trong, không bày ra phố
	Build.box(a, Vector3(0.06, 0.95, 2.05), Vector3(0.1, H_BASE + 0.48, 0), m["door"])
	for bz in range(9):
		Build.cyl(a, 0.022, 0.022, 0.95, Vector3(0.1, H_BASE + 1.48, -0.88 + bz * 0.22), m["frame"], 6)
	Build.box(a, Vector3(0.08, 0.1, 2.1), Vector3(0.1, H_BASE + 2.0, 0), m["frame"])
	for ez in [-0.32, 0.32]:
		Build.door_eye(a, Vector3(0.0, H_BASE + 2.22, ez), 1.0)
	# vách gỗ tối ngay sau song cửa — nhìn qua song thấy chiều sâu, không thấy xuyên nhà
	Build.box(a, Vector3(0.05, H1 - 0.85, jamb_z * 2.0), Vector3(0.45, H_BASE + (H1 - 0.85) / 2.0, 0), Build.mat(Color(0.08, 0.06, 0.05), 0.95))
	# biển hiệu gỗ viền vàng trên cửa
	Build.box(a, Vector3(0.07, 0.46, 1.68), Vector3(-0.05, Y1 - 0.45, 0), Build.mat(Color(0.55, 0.42, 0.15), 0.5))
	Build.box(a, Vector3(0.09, 0.38, 1.56), Vector3(-0.06, Y1 - 0.45, 0), Build.mat(Color(0.09, 0.05, 0.04), 0.6))

	# ---------- cửa sổ chớp gỗ hai bên ----------
	var wins: Array = out.get("windows", [])
	for sz in [-1.0, 1.0]:
		# z=±1.9: mép khung 2.4 < trụ bổ tường 2.44 — không đè khung lên trụ
		var wz2: float = sz * 1.9
		Build.box(a, Vector3(0.08, 1.2, 1.0), Vector3(-0.03, H_BASE + 1.55, wz2), m["frame"])
		var leaf := Build.box(a, Vector3(0.06, 1.1, 0.9), Vector3(-0.06, H_BASE + 1.55, wz2), m["shutter"])
		wins.append(leaf)
		for sl in range(6):
			var slat := Build.box(a, Vector3(0.03, 0.045, 0.8), Vector3(-0.09, H_BASE + 1.12 + sl * 0.17, wz2), m["frame"])
			slat.rotation.z = 0.55
		Build.box(a, Vector3(0.3, 0.07, 1.0), Vector3(-0.1, H_BASE + 0.92, wz2), m["trim"])
	out["windows"] = wins

	# ---------- hiên ngói che vỉa hè trên hai cột gỗ ----------
	var porch := Node3D.new()
	porch.position = Vector3(-0.68, Y1 - 0.5, 0)
	porch.rotation.z = 0.45
	a.add_child(porch)
	var pslab := BoxMesh.new()
	pslab.size = Vector3(1.55, 0.06, W - 0.04)
	var pmi := MeshInstance3D.new()
	pmi.mesh = pslab
	pmi.material_override = m["roof_tex"]
	porch.add_child(pmi)
	Build.tile_rows(porch, 1.55, W - 0.04, m["tile_c"])
	for pz in [-2.4, 2.4]:
		# cột cao chạm hẳn mặt dưới vạt hiên (hiên dốc 0.45, mép dưới tại x=-1.25 ≈ Y1-0.76)
		Build.cyl(a, 0.07, 0.085, Y1 - 0.72, Vector3(-1.25, (Y1 - 0.72) / 2.0, pz), m["wood"], 8)

	# dãy đèn lồng dưới hiên — phố Hội là phố của đèn
	var lans: Array = out.get("lanterns", [])
	for lz in [-1.8, -0.6, 0.6, 1.8]:
		lans.append(Build.lantern(a, 0.13, 0.25, Vector3(-0.85, Y1 - 1.0, lz)))
	out["lanterns"] = lans

	Parts.roof_amduong(a, W, D, Y1 + 0.05, m)
	return a
