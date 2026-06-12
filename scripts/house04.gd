# Nhà Hội An SÂN THƯỢNG CÂY CỐI — theo Screenshots/ref-06:
#   - tầng trệt vữa vàng + cửa đôi gỗ, mái hiên ngói che vỉa hè
#   - SÂN THƯỢNG trên nửa trước: sàn gạch, lan can bông gió trắng,
#     chậu cây um tùm, dây leo tràn qua mép lan can
#   - khối gác SAU cao hơn: cửa sổ chớp + mái âm dương riêng
# out: {"lanterns": [...], "windows": [...]}.
extends RefCounted

const Build := preload("res://scripts/build.gd")
const Parts := preload("res://scripts/hoian_parts.gd")

const W := 6.0
const D := 5.0
const H_BASE := 0.78
const H1 := 3.0
const Y1 := H_BASE + H1


static func build(parent: Node3D, pos: Vector3, yrot: float, age: float = 0.6, out: Dictionary = {}) -> Node3D:
	var a := Node3D.new()
	a.position = pos
	a.rotation.y = yrot
	parent.add_child(a)
	var m := Parts.mats(age)

	Parts.plinth_steps(a, W, D, H_BASE, m)

	# ---------- tầng trệt: vữa vàng + cửa đôi gỗ ----------
	var jamb_z := 0.82
	for side in [-1.0, 1.0]:
		var wz := (W / 2.0 + jamb_z) / 2.0
		Build.box(a, Vector3(D, H1, W / 2.0 - jamb_z), Vector3(D / 2.0, H_BASE + H1 / 2.0, side * wz), m["plaster"])
	Build.box(a, Vector3(D, Y1 - (H_BASE + 2.6), jamb_z * 2.0), Vector3(D / 2.0, (H_BASE + 2.6 + Y1) / 2.0, 0), m["plaster"])
	Parts.weather_facade(a, W, H_BASE, Y1, m, 4)
	Parts.pilasters(a, W, H_BASE, H1, m)
	for jz in [-1.0, 1.0]:
		Build.box(a, Vector3(0.14, 2.6, 0.16), Vector3(-0.04, H_BASE + 1.3, jz * jamb_z), m["frame"])
	Build.box(a, Vector3(0.16, 0.2, jamb_z * 2.0 + 0.3), Vector3(-0.045, H_BASE + 2.7, 0), m["frame"])
	for s in [-1.0, 1.0]:
		Build.box(a, Vector3(0.07, 2.42, 0.72), Vector3(0.12, H_BASE + 1.21, s * 0.37), m["door"])
		Build.box(a, Vector3(0.025, 1.1, 0.52), Vector3(0.08, H_BASE + 0.72, s * 0.37), m["frame"])
		Build.box(a, Vector3(0.025, 0.85, 0.52), Vector3(0.08, H_BASE + 1.85, s * 0.37), m["frame"])
	for ez in [-0.36, 0.36]:
		Build.door_eye(a, Vector3(0.02, H_BASE + 2.7, ez), 1.0)

	# ---------- mái hiên ngói che vỉa hè ----------
	var awn := Node3D.new()
	awn.position = Vector3(-0.5, Y1 - 0.28, 0)
	awn.rotation.z = 0.4
	a.add_child(awn)
	var awn_slab := BoxMesh.new()
	awn_slab.size = Vector3(1.45, 0.06, W + 0.4)
	var awn_mi := MeshInstance3D.new()
	awn_mi.mesh = awn_slab
	awn_mi.material_override = m["roof_tex"]
	awn.add_child(awn_mi)
	Build.tile_rows(awn, 1.45, W + 0.4, m["tile_c"])
	for cz in [-jamb_z, jamb_z]:
		Build.box(a, Vector3(0.5, 0.13, 0.16), Vector3(-0.28, Y1 - 0.62, cz), m["frame"])

	# đèn lồng treo dưới hiên
	var lans: Array = out.get("lanterns", [])
	for lz in [-1.5, 1.5]:
		lans.append(Build.lantern(a, 0.14, 0.27, Vector3(-0.75, Y1 - 0.75, lz)))
	out["lanterns"] = lans

	# ---------- sân thượng nửa trước: sàn gạch + lan can bông gió + cây ----------
	var ty := Y1 + 0.12
	Build.box(a, Vector3(2.5, 0.14, W + 0.06), Vector3(1.25, ty - 0.07, 0), Build.mat(Color(0.52, 0.34, 0.26).lerp(Color(0.4, 0.3, 0.24), age), 0.9))
	Build.breeze_panel(a, Vector3(0.08, ty + 0.4, 0), 14, 2, 0.36)
	Build.box(a, Vector3(0.12, 0.07, W + 0.06), Vector3(0.08, ty + 0.82, 0), m["trim"])
	for pz in [-1.0, 1.0]:
		Build.box(a, Vector3(0.14, 1.0, 0.14), Vector3(0.08, ty + 0.5, pz * (W / 2.0 - 0.04)), m["trim"])
		# tường hồi chạy kín từ trụ góc trước tới khối gác sau — không hở khe
		Build.box(a, Vector3(2.48, 0.45, 0.08), Vector3(1.27, ty + 0.28, pz * (W / 2.0 - 0.01)), m["trim"])
	for pk in range(4):
		Parts.pot_plant(a, Vector3(0.6 + (pk % 2) * 0.9, ty, -2.0 + pk * 1.3), (pk * 2 + 1) % 4, 0.85, age)
	# dây leo tràn qua mép lan can — um tùm như ref-06
	var leaf := Build.mat(Color(0.24, 0.44, 0.14), 0.9)
	var moss := Build.mat(Color(0.17, 0.26, 0.11), 0.95)
	for vi in range(8):
		var vz := -2.4 + fposmod(vi * 1.37, 4.8)
		Build.ball(a, 0.14 + 0.1 * fposmod(vi * 0.83, 1.0), 0.22,
			Vector3(0.04, ty + 0.74 - 0.42 * fposmod(vi * 0.6, 1.0), vz),
			leaf if vi % 3 != 0 else moss)

	# ---------- khối gác sau cao + cửa sổ chớp + mái âm dương ----------
	Build.box(a, Vector3(D / 2.0, 1.6, W), Vector3(D * 0.75, Y1 + 0.8, 0), m["plaster"])
	var wins: Array = out.get("windows", [])
	var shut := Build.box(a, Vector3(0.1, 0.78, 0.86), Vector3(2.44, Y1 + 0.85, 0), m["shutter"])
	wins.append(shut)
	out["windows"] = wins
	Build.box(a, Vector3(0.08, 0.9, 0.98), Vector3(2.47, Y1 + 0.85, 0), m["frame"])
	var back := Node3D.new()
	back.position = Vector3(D / 2.0, 0, 0)
	a.add_child(back)
	Parts.roof_amduong(back, W, D / 2.0, Y1 + 1.65, m)
	return a
