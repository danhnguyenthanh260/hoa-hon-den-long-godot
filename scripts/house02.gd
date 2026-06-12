# Nhà Hội An MỘT TẦNG tường vàng + panel GẠCH BÔNG GIÓ trắng — theo Screenshots/ref-02:
#   - cửa đôi gỗ nâu cao ở giữa, hai bên hai Ô BÔNG GIÓ trắng 3x3 nhìn xuyên được
#     (lỗ tường thật, đèn trong nhà hắt ấm qua khe hoa)
#   - mái âm dương viền vữa trắng hai đầu cong, đế đá cao + tam cấp như ref-01
# Dùng chung bộ phận hoian_parts.gd. Mặt sàn đi được: Parts.floor_rects.
extends RefCounted

const Build := preload("res://scripts/build.gd")
const Parts := preload("res://scripts/hoian_parts.gd")

const W := 6.0
const D := 5.0
const H_BASE := 0.78
const H1 := 3.2
const Y1 := H_BASE + H1


static func build(parent: Node3D, pos: Vector3, yrot: float, age: float = 0.15) -> Node3D:
	var a := Node3D.new()
	a.position = pos
	a.rotation.y = yrot
	parent.add_child(a)
	var m := Parts.mats(age)

	Parts.plinth_steps(a, W, D, H_BASE, m)

	# ---------- thân: khối đặc phía sau + mặt tiền dày 0.35 chừa lỗ cửa và 2 ô bông gió ----------
	Build.box(a, Vector3(D - 0.35, H1, W), Vector3((D + 0.35) / 2.0, H_BASE + H1 / 2.0, 0), m["plaster"])
	var jamb_z := 0.82
	var o_w := 1.15                                       # ô bông gió vuông 1.15m, tâm z ±1.95
	var o_z0 := 1.95 - o_w / 2.0
	var o_z1 := 1.95 + o_w / 2.0
	var sill := H_BASE + 1.05
	var head := sill + o_w
	for s in [-1.0, 1.0]:
		# cột tường cạnh cửa và góc nhà
		Build.box(a, Vector3(0.35, H1, o_z0 - jamb_z), Vector3(0.175, H_BASE + H1 / 2.0, s * (jamb_z + (o_z0 - jamb_z) / 2.0)), m["plaster"])
		Build.box(a, Vector3(0.35, H1, W / 2.0 - o_z1), Vector3(0.175, H_BASE + H1 / 2.0, s * (o_z1 + (W / 2.0 - o_z1) / 2.0)), m["plaster"])
		# mảng dưới bậu + trên đầu ô
		Build.box(a, Vector3(0.35, sill - H_BASE, o_w), Vector3(0.175, (H_BASE + sill) / 2.0, s * 1.95), m["plaster"])
		Build.box(a, Vector3(0.35, Y1 - head, o_w), Vector3(0.175, (head + Y1) / 2.0, s * 1.95), m["plaster"])
		# panel bông gió trắng 3x3: NHỎ HƠN lỗ tường và đặt NỔI ngang mặt vữa
		# (không lún vào tường), bốn phía có viền trắng ôm quanh ô như ref-02
		Build.breeze_panel(a, Vector3(-0.01, (sill + head) / 2.0, s * 1.95), 3, 3, (o_w - 0.16) / 3.0)
		for ed in [-1.0, 1.0]:
			Build.box(a, Vector3(0.07, 0.07, o_w + 0.2), Vector3(-0.025, (sill if ed < 0 else head) + ed * 0.02, s * 1.95), m["trim"])
			Build.box(a, Vector3(0.07, head - sill + 0.1, 0.07), Vector3(-0.025, (sill + head) / 2.0, s * (1.95 + ed * (o_w / 2.0 + 0.02))), m["trim"])
		Build.box(a, Vector3(0.42, 0.07, o_w + 0.2), Vector3(0.0, sill - 0.07, s * 1.95), m["trim"])
		# ánh đèn ấm trong nhà hắt qua khe hoa
		var glow := Build.box(a, Vector3(0.02, o_w - 0.06, o_w - 0.06), Vector3(0.42, (sill + head) / 2.0, s * 1.95), Build.emis(Color(1.0, 0.75, 0.45), Color(1.0, 0.55, 0.22), 0.5))
		glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# dải tường trên cửa
	Build.box(a, Vector3(0.35, Y1 - (H_BASE + 2.6), jamb_z * 2.0), Vector3(0.175, (H_BASE + 2.6 + Y1) / 2.0, 0), m["plaster"])

	Parts.pilasters(a, W, H_BASE, H1, m)

	# ---------- cửa đôi gỗ nâu cao + khung đen + mắt cửa ----------
	for jz in [-1.0, 1.0]:
		Build.box(a, Vector3(0.14, 2.6, 0.16), Vector3(-0.04, H_BASE + 1.3, jz * jamb_z), m["frame"])
	Build.box(a, Vector3(0.16, 0.2, jamb_z * 2.0 + 0.3), Vector3(-0.045, H_BASE + 2.7, 0), m["frame"])
	for s in [-1.0, 1.0]:
		Build.box(a, Vector3(0.07, 2.42, 0.72), Vector3(0.12, H_BASE + 1.21, s * 0.37), m["door"])
		Build.box(a, Vector3(0.025, 1.1, 0.52), Vector3(0.08, H_BASE + 0.72, s * 0.37), m["frame"])
		Build.box(a, Vector3(0.025, 0.85, 0.52), Vector3(0.08, H_BASE + 1.85, s * 0.37), m["frame"])
		Build.ball(a, 0.025, 0.05, Vector3(0.07, H_BASE + 1.25, s * 0.09), Build.mat(Color(0.35, 0.28, 0.12), 0.4))
	for ez in [-0.36, 0.36]:
		Build.door_eye(a, Vector3(0.02, H_BASE + 2.7, ez), 1.0)

	# ván diềm sát mái + mái âm dương viền trắng
	Build.box(a, Vector3(0.06, 0.24, W + 0.04), Vector3(-0.045, Y1 - 0.1, 0), m["frame"])
	Parts.roof_amduong(a, W, D, Y1 + 0.1, m)
	return a
