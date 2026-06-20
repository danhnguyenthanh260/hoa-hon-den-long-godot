# Đèn giữ hồn — vật phẩm RIÊNG theo chủ đề "Họa Hồn Đèn Lồng".
# Kéo quân hóa: lụa Hội An dáng củ tỏi bọc ngoài + LÕI QUAY chiếu bóng hồn
# (chim Lạc / sen) hắt lên lụa + lụa phát Sắc ngũ hành (set_color).
# Gốc (origin) = chỗ bàn tay nắm sào. Dùng: preload(...).new() rồi add_child.
extends Node3D

const Build := preload("res://scripts/build.gd")

var _silk: Array = []          # vật liệu lụa (đổi Sắc)
var _light: OmniLight3D
var _drum: Node3D              # lõi kéo quân — quay
var spin := 0.7               # tốc độ quay lõi (rad/s)
var _cy := 1.06               # tâm bầu đèn trên sào


func _ready() -> void:
	var wood := Build.mat(Color(0.5, 0.38, 0.2), 0.8)
	var bamboo := Build.mat(Color(0.30, 0.20, 0.10), 0.7)

	# sào tre dựng đứng, tay nắm ở gốc
	var pole := CylinderMesh.new()
	pole.top_radius = 0.012
	pole.bottom_radius = 0.016
	pole.height = 1.0
	var pmi := MeshInstance3D.new()
	pmi.mesh = pole
	pmi.material_override = wood
	pmi.position.y = 0.5
	pmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pmi)
	for ky in [0.1, 0.45, 0.8]:
		Build.cyl(self, 0.018, 0.018, 0.013, Vector3(0, ky, 0), bamboo, 8)

	# nắp gỗ trên/dưới + cổ củ tỏi
	Build.cyl(self, 0.055, 0.085, 0.04, Vector3(0, _cy + 0.22, 0), wood, 12)
	Build.cyl(self, 0.085, 0.055, 0.04, Vector3(0, _cy - 0.22, 0), wood, 12)
	Build.cyl(self, 0.013, 0.013, 0.07, Vector3(0, _cy + 0.29, 0), wood, 8)   # cổ/núm
	# tua đỏ dưới
	Build.cyl(self, 0.006, 0.006, 0.1, Vector3(0, _cy - 0.3, 0), Build.mat(Color(0.7, 0.12, 0.1), 0.7), 4)

	# bầu lụa dáng củ tỏi (ovoid) — trong suốt + phát sáng
	var silk := _silk_mat(Color(1.0, 0.42, 0.15))
	var sph := SphereMesh.new()
	sph.radius = 0.16
	sph.height = 0.44
	var smi := MeshInstance3D.new()
	smi.mesh = sph
	smi.material_override = silk
	smi.position.y = _cy
	smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(smi)
	_silk.append(silk)

	# nan tre dọc quanh bầu
	for i in range(6):
		var a := TAU * i / 6.0
		Build.cyl(self, 0.005, 0.005, 0.42, Vector3(cos(a) * 0.15, _cy, sin(a) * 0.15), bamboo, 4)

	# ngọn lửa giữa đèn (Sắc ngũ hành)
	_light = OmniLight3D.new()
	_light.position.y = _cy
	_light.light_color = Color(1.0, 0.62, 0.32)
	_light.light_energy = 2.4
	_light.omni_range = 6.0
	add_child(_light)

	# lõi kéo quân: bóng hồn quay (chim Lạc + sen)
	_drum = Node3D.new()
	_drum.position.y = _cy
	add_child(_drum)
	var shade := Build.mat(Color(0.04, 0.03, 0.03), 0.95)
	_bird(0.0, shade)
	_lotus(TAU / 3.0, shade)
	_bird(2.0 * TAU / 3.0, shade)

	set_color(Color(1.0, 0.42, 0.15))


func _silk_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, 0.5)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 1.6
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


# bóng chim Lạc (thân + 2 cánh xòe), dán quanh lõi, hướng ra ngoài
func _bird(ang: float, mat: Material) -> void:
	var f := Node3D.new()
	f.position = Vector3(cos(ang) * 0.085, 0, sin(ang) * 0.085)
	f.rotation.y = -ang
	_drum.add_child(f)
	Build.box(f, Vector3(0.012, 0.05, 0.012), Vector3.ZERO, mat)        # thân
	var wl := Build.box(f, Vector3(0.012, 0.05, 0.012), Vector3(-0.03, 0.01, 0), mat)
	wl.rotation.z = 0.7
	var wr := Build.box(f, Vector3(0.012, 0.05, 0.012), Vector3(0.03, 0.01, 0), mat)
	wr.rotation.z = -0.7


# bóng hoa sen (vài cánh xòe)
func _lotus(ang: float, mat: Material) -> void:
	var f := Node3D.new()
	f.position = Vector3(cos(ang) * 0.085, -0.02, sin(ang) * 0.085)
	f.rotation.y = -ang
	_drum.add_child(f)
	for k in [-0.5, 0.0, 0.5]:
		var p := Build.box(f, Vector3(0.01, 0.06, 0.01), Vector3(0, 0.02, 0), mat)
		p.rotation.z = k


func set_color(c: Color) -> void:
	for m in _silk:
		m.albedo_color = Color(c.r, c.g, c.b, 0.5)
		m.emission = c
	if _light:
		_light.light_color = c.lerp(Color(1, 1, 1), 0.2)


func _process(delta: float) -> void:
	if _drum:
		_drum.rotation.y += spin * delta
