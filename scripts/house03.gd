# Nhà Hội An 2 TẦNG BAN CÔNG BÔNG GIÓ — theo Screenshots/ref-05:
#   - tầng trệt vữa vàng + cửa buôn 4 cánh gỗ (phố thương mại)
#   - ban công chìa hết mặt tiền, lan can bông gió trắng, chậu cây hai đầu
#   - tầng gác vữa vàng, hai bộ cửa chớp gỗ nâu sậm mở ra ban công
#   - 4 đèn lồng đỏ treo sát mép mái ngay trên ban công
# out: {"lanterns": [...], "windows": [...]} — world đăng ký để light_up thắp.
extends RefCounted

const Build := preload("res://scripts/build.gd")
const Parts := preload("res://scripts/hoian_parts.gd")

const W := 6.0
const D := 5.0
const H_BASE := 0.78
const H1 := 2.9
const H2 := 2.3
const Y1 := H_BASE + H1
const Y2 := Y1 + H2


static func build(parent: Node3D, pos: Vector3, yrot: float, age: float = 0.4, out: Dictionary = {}) -> Node3D:
	var a := Node3D.new()
	a.position = pos
	a.rotation.y = yrot
	parent.add_child(a)
	var m := Parts.mats(age)

	Parts.plinth_steps(a, W, D, H_BASE, m)

	# ---------- tầng trệt: vữa vàng + cửa buôn 4 cánh ----------
	var jamb_z := 1.32
	for side in [-1.0, 1.0]:
		var wz := (W / 2.0 + jamb_z) / 2.0
		Build.box(a, Vector3(D, H1, W / 2.0 - jamb_z), Vector3(D / 2.0, H_BASE + H1 / 2.0, side * wz), m["plaster"])
	Build.box(a, Vector3(D, 0.46, jamb_z * 2.0), Vector3(D / 2.0, Y1 - 0.23, 0), m["plaster"])
	Parts.weather_facade(a, W, H_BASE, Y1, m, 3)
	Parts.pilasters(a, W, H_BASE, H1, m)
	for jz in [-1.0, 1.0]:
		Build.box(a, Vector3(0.14, H1 - 0.4, 0.16), Vector3(-0.04, H_BASE + (H1 - 0.4) / 2.0, jz * jamb_z), m["frame"])
	Build.box(a, Vector3(0.16, 0.2, jamb_z * 2.0 + 0.3), Vector3(-0.045, Y1 - 0.52, 0), m["frame"])
	for li in range(4):
		var lz := -0.93 + li * 0.62
		Build.box(a, Vector3(0.07, H1 - 0.62, 0.58), Vector3(0.12, H_BASE + (H1 - 0.62) / 2.0, lz), m["door"])
		Build.box(a, Vector3(0.025, 0.95, 0.44), Vector3(0.08, H_BASE + 0.62, lz), m["frame"])
		Build.box(a, Vector3(0.025, 0.5, 0.44), Vector3(0.08, H_BASE + 1.45, lz), m["frame"])
	for ez in [-0.36, 0.36]:
		Build.door_eye(a, Vector3(0.02, Y1 - 0.52, ez), 1.0)

	# ---------- ban công bông gió hết mặt tiền (ref-05) ----------
	Parts.balcony_breeze(a, 5.2, Y1 + 0.06, m)

	# ---------- tầng gác vữa vàng + hai bộ cửa chớp mở ra ban công ----------
	Build.box(a, Vector3(D, H2, W), Vector3(D / 2.0, Y1 + H2 / 2.0, 0), m["plaster"])
	var wins: Array = out.get("windows", [])
	for dz in [-0.85, 0.85]:
		Build.box(a, Vector3(0.06, 2.0, 1.14), Vector3(-0.03, Y1 + 1.1, dz), m["frame"])
		for lf in [-1.0, 1.0]:
			var leaf := Build.box(a, Vector3(0.05, 1.9, 0.5), Vector3(-0.07, Y1 + 1.08, dz + lf * 0.27), m["shutter"])
			wins.append(leaf)
			for sl in range(5):
				var slat := Build.box(a, Vector3(0.028, 0.045, 0.4), Vector3(-0.1, Y1 + 0.45 + sl * 0.32, dz + lf * 0.27), m["frame"])
				slat.rotation.z = 0.55
	out["windows"] = wins
	# ván diềm sát mái
	Build.box(a, Vector3(0.06, 0.24, W + 0.04), Vector3(-0.045, Y2 - 0.1, 0), m["frame"])

	# 4 đèn lồng đỏ sát mép mái ngay trên ban công (ref-05)
	var lans: Array = out.get("lanterns", [])
	for lz in [-1.95, -0.65, 0.65, 1.95]:
		lans.append(Build.lantern(a, 0.14, 0.27, Vector3(-0.5, Y2 - 0.22, lz)))
	out["lanterns"] = lans

	Parts.roof_amduong(a, W, D, Y2 + 0.1, m)
	return a
