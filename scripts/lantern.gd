# Đèn lồng cầm tay — vật phẩm dựng RIÊNG, tái dùng cho cả game lẫn viewer QA.
# Gốc (origin) = chỗ bàn tay nắm; sào dựng đứng, lồng đèn treo phía trước-trên.
# Dùng: var den = preload("res://scripts/lantern.gd").make(); parent.add_child(den)
extends Node3D

const Build := preload("res://scripts/build.gd")


static func make() -> Node3D:
	var holder := Node3D.new()
	var wood := Build.mat(Color(0.5, 0.38, 0.2), 0.8)
	var dark := Build.mat(Color(0.12, 0.08, 0.05), 0.85)

	# sào tre dựng đứng — tay nắm ở gốc (origin)
	var pole := CylinderMesh.new()
	pole.top_radius = 0.013
	pole.bottom_radius = 0.018
	pole.height = 1.25
	var pmi := MeshInstance3D.new()
	pmi.mesh = pole
	pmi.material_override = wood
	pmi.position.y = 0.42
	pmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(pmi)
	for ky in [0.1, 0.5, 0.9]:
		Build.cyl(holder, 0.02, 0.02, 0.015, Vector3(0, ky, 0), Build.mat(Color(0.42, 0.33, 0.15), 0.85), 8)

	# cần ngang đầu sào để treo đèn ra trước
	var topy := 1.0
	Build.box(holder, Vector3(0.022, 0.022, 0.3), Vector3(0, topy, 0.14), wood)

	# cụm đèn treo
	var hang := Node3D.new()
	hang.position = Vector3(0, topy - 0.02, 0.27)
	holder.add_child(hang)
	Build.cyl(hang, 0.006, 0.006, 0.12, Vector3(0, -0.06, 0), dark)
	for dy in [-0.13, -0.43]:
		Build.cyl(hang, 0.07, 0.07, 0.03, Vector3(0, dy, 0), dark, 6)

	# thân giấy lục giác phát sáng (đèn lồng Hội An)
	var paper_mat := Build.emis(Color(1.0, 0.5, 0.25), Color(1.0, 0.42, 0.15), 2.6, 0.5)
	paper_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var paper := CylinderMesh.new()
	paper.top_radius = 0.085
	paper.bottom_radius = 0.1
	paper.height = 0.26
	paper.radial_segments = 6
	var lmi := MeshInstance3D.new()
	lmi.mesh = paper
	lmi.material_override = paper_mat
	lmi.name = "PaperBody"
	lmi.position.y = -0.28
	lmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hang.add_child(lmi)
	Build.cyl(hang, 0.005, 0.005, 0.08, Vector3(0, -0.45, 0), Build.mat(Color(0.7, 0.12, 0.1), 0.7), 4)

	var l := OmniLight3D.new()
	l.name = "Glow"
	l.light_color = Color(1.0, 0.62, 0.32)
	l.light_energy = 2.4
	l.omni_range = 6.0
	l.position.y = -0.28
	hang.add_child(l)
	return holder
