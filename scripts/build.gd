# Thư viện dựng hình dùng chung cho mọi chương.
extends RefCounted


static func mat(c: Color, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


# vật liệu PBR từ bộ texture ambientCG (CC0): Color + NormalGL + Roughness, chiếu triplanar
static func pbr(folder: String, scale: float, tint := Color(1, 1, 1), normal_strength := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var dir := DirAccess.open(folder)
	if dir != null:
		for f in dir.get_files():
			if f.ends_with("_Color.jpg"):
				m.albedo_texture = load(folder + "/" + f)
			elif f.ends_with("_NormalGL.jpg"):
				m.normal_enabled = true
				m.normal_texture = load(folder + "/" + f)
				m.normal_scale = normal_strength
			elif f.ends_with("_Roughness.jpg"):
				m.roughness_texture = load(folder + "/" + f)
	m.albedo_color = tint
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(scale, scale, scale)
	return m


static func emis(albedo: Color, emission: Color, energy: float, rough: float = 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.emission_enabled = true
	m.emission = emission
	m.emission_energy_multiplier = energy
	m.roughness = rough
	return m


static func box(parent: Node3D, size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = material
	parent.add_child(mi)
	return mi


static func cyl(parent: Node3D, r_top: float, r_bot: float, h: float, pos: Vector3, material: Material, segs: int = 12) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r_top
	mesh.bottom_radius = r_bot
	mesh.height = h
	mesh.radial_segments = segs
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = material
	parent.add_child(mi)
	return mi


static func ball(parent: Node3D, radius: float, height: float, pos: Vector3, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = material
	parent.add_child(mi)
	return mi


# đèn lồng tròn treo (tắt); thắp bằng light_lantern
static func lantern(parent: Node3D, radius: float, height: float, pos: Vector3) -> MeshInstance3D:
	var body := ball(parent, radius, height, pos, mat(Color(0.22, 0.17, 0.155), 0.8))
	for dy in [-height * 0.5, height * 0.5]:
		cyl(parent, radius * 0.35, radius * 0.35, 0.035, pos + Vector3(0, dy, 0), mat(Color(0.11, 0.075, 0.05)))
	return body


static func light_lantern(mesh: MeshInstance3D, color: Color, energy: float) -> void:
	mesh.material_override = emis(Color(1.0, 0.85, 0.7), color, energy)


# bóng người không mặt: áo thụng tối + nón, khoảng trống thay mặt
static func faceless_npc(parent: Node3D, pos: Vector3, robe_color: Color, scale_f: float = 1.0, casts_shadow: bool = true) -> Node3D:
	var npc := Node3D.new()
	npc.position = pos
	parent.add_child(npc)
	var robe := cyl(npc, 0.16 * scale_f, 0.38 * scale_f, 1.15 * scale_f, Vector3(0, 0.58 * scale_f, 0), mat(robe_color, 0.95), 14)
	# khoảng trống thay mặt — đen tuyệt đối, không bắt sáng
	var void_mat := StandardMaterial3D.new()
	void_mat.albedo_color = Color(0.0, 0.0, 0.0)
	void_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var head := ball(npc, 0.12 * scale_f, 0.24 * scale_f, Vector3(0, 1.32 * scale_f, 0), void_mat)
	var hat := cyl(npc, 0.012, 0.4 * scale_f, 0.17 * scale_f, Vector3(0, 1.46 * scale_f, 0), mat(Color(0.5, 0.4, 0.24), 0.95), 18)
	if not casts_shadow:
		for c in [robe, head, hat]:
			c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return npc


# mesh tròn xoay từ profile 2D (radius, y) — cho thân áo, vật dụng cong mượt
static func lathe(parent: Node3D, profile: Array, pos: Vector3, material: Material, segs: int = 20) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	for i in range(profile.size() - 1):
		var p0: Vector2 = profile[i]
		var p1: Vector2 = profile[i + 1]
		for s in range(segs):
			var a0 := TAU * s / segs
			var a1 := TAU * (s + 1) / segs
			var v00 := Vector3(cos(a0) * p0.x, p0.y, sin(a0) * p0.x)
			var v01 := Vector3(cos(a1) * p0.x, p0.y, sin(a1) * p0.x)
			var v10 := Vector3(cos(a0) * p1.x, p1.y, sin(a0) * p1.x)
			var v11 := Vector3(cos(a1) * p1.x, p1.y, sin(a1) * p1.x)
			st.add_vertex(v00)
			st.add_vertex(v10)
			st.add_vertex(v11)
			st.add_vertex(v00)
			st.add_vertex(v11)
			st.add_vertex(v01)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.position = pos
	mi.material_override = material
	parent.add_child(mi)
	return mi


# dải vải mềm: lưới đỉnh cong dần về cuối, normal mịn — cho tà áo, rèm
static func ribbon(parent: Node3D, width: float, length: float, curve: float, taper: float, material: Material, segs: int = 9) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	var rows := []
	for i in range(segs + 1):
		var t := float(i) / segs
		var w := width * (1.0 - taper * t) * 0.5
		rows.append([
			Vector3(-w, -length * t, curve * length * t * t),
			Vector3(w, -length * t, curve * length * t * t),
		])
	for i in range(segs):
		var a: Vector3 = rows[i][0]
		var b: Vector3 = rows[i][1]
		var c: Vector3 = rows[i + 1][0]
		var d: Vector3 = rows[i + 1][1]
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(d)
		st.add_vertex(a)
		st.add_vertex(d)
		st.add_vertex(b)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = material
	parent.add_child(mi)
	return mi


# mái ngói âm dương: hàng ống ngói chạy dọc dốc mái (MultiMesh cho rẻ)
# slope_node đặt tại tâm slab, đã xoay sẵn — ngói rải trên mặt local XZ.
static func tile_rows(slope_node: Node3D, width: float, depth: float) -> void:
	var count := int(depth / 0.11)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.045
	cyl.bottom_radius = 0.045
	cyl.height = width
	cyl.radial_segments = 8
	mm.mesh = cyl
	mm.instance_count = count
	for i in range(count):
		var t := Transform3D(Basis(Vector3(0, 0, 1), PI / 2.0), Vector3(0, 0.07, -depth / 2.0 + 0.055 + i * 0.11))
		mm.set_instance_transform(i, t)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(0.14, 0.125, 0.135)
	tmat.roughness = 0.5
	tmat.metallic = 0.08
	mmi.material_override = tmat
	slope_node.add_child(mmi)


# mắt cửa — đôi mắt gỗ tròn trên cửa, hồn nhà Hội An
static func door_eye(parent: Node3D, pos: Vector3, side: float) -> void:
	var outer := cyl(parent, 0.075, 0.075, 0.03, pos, mat(Color(0.32, 0.07, 0.05), 0.7), 12)
	outer.rotation.z = PI / 2.0
	var inner := cyl(parent, 0.048, 0.048, 0.035, pos + Vector3(-side * 0.005, 0, 0), mat(Color(0.7, 0.55, 0.2), 0.5), 12)
	inner.rotation.z = PI / 2.0
	var dot := cyl(parent, 0.016, 0.016, 0.04, pos + Vector3(-side * 0.01, 0, 0), mat(Color(0.08, 0.05, 0.04), 0.6), 8)
	dot.rotation.z = PI / 2.0


# đốm Sắc Ngũ Hành lơ lửng
static func color_orb(parent: Node3D, pos: Vector3, color: Color) -> Node3D:
	var orb := Node3D.new()
	orb.position = pos
	parent.add_child(orb)
	ball(orb, 0.12, 0.24, Vector3.ZERO, emis(color, color, 4.0))
	var halo := ball(orb, 0.2, 0.4, Vector3.ZERO, null)
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(color.r, color.g, color.b, 0.18)
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo.material_override = hm
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = 1.2
	l.omni_range = 4.0
	orb.add_child(l)
	return orb
