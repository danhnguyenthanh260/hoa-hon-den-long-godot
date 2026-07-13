# CHƯƠNG BỐN — BẾN SÔNG NGƯỢC (Kim)
# Người chèo đò chỉ cho hai tiếng chuông và một ngôi mộ vô danh; không còn gương hay lựa chọn rẽ nhánh.
extends Node3D

const Build := preload("res://scripts/build.gd")

const BANK_Z0 := -45.0
const RIVER_Z := -58.0
const BELL_LEFT_POS := Vector3(-5.1, 0, -51.2)
const BELL_RIGHT_POS := Vector3(5.1, 0, -53.8)
const BOATMAN_POS := Vector3(2.6, 0, -58.3)
const KIM_POS := Vector3(0.0, 0, -55.8)
const MEMORIAL_POS := Vector3(-5.7, 0, -47.4)

var m
var bell1_rung := false
var bell2_rung := false
var _boatman_met := false
var _kim_taken := false
var _memorial_carved := false
var _ready_to_cross := false
var _time := 0.0
var _kim_orb: Node3D
var _boatman: Node3D
var _boatman_interact: Dictionary
var _memorial_interact: Dictionary
var _bell_lights: Array = []
var _hoa_dang: Array = []
var _memorial_stone: MeshInstance3D


func build(main) -> void:
	m = main
	var bank := Build.pbr("res://assets/textures/PavingStones138", 0.62, Color(0.31, 0.27, 0.24), 0.5)
	Build.box(self, Vector3(16.0, 0.16, 16.0), Vector3(0, -0.08, -52.7), bank)
	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.015, 0.035, 0.09)
	water_mat.metallic = 0.82
	water_mat.roughness = 0.10
	Build.box(self, Vector3(16.0, 0.05, 4.8), Vector3(0, -0.04, -59.4), water_mat)
	_build_river_backdrop()
	_build_bell(BELL_LEFT_POS, 0)
	_build_bell(BELL_RIGHT_POS, 1)
	_build_boat()
	_build_memorial()

	var moon := Build.ball(self, 1.0, 2.0, Vector3(-1.8, 7.0, -60.4), Build.emis(Color(0.82, 0.85, 1.0), Color(0.58, 0.68, 1.0), 1.25))
	moon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var moon_light := OmniLight3D.new()
	moon_light.light_color = Color(0.55, 0.68, 1.0)
	moon_light.light_energy = 1.35
	moon_light.omni_range = 18.0
	moon_light.position = Vector3(-1.8, 5.4, -56.0)
	add_child(moon_light)
	for shore_pos in [Vector3(-4.8, 2.0, -50.4), Vector3(4.8, 2.0, -54.8), Vector3(0, 2.4, -57.0)]:
		var shore_light := OmniLight3D.new()
		shore_light.light_color = Color(0.46, 0.56, 0.92)
		shore_light.light_energy = 0.95
		shore_light.omni_range = 9.0
		shore_light.position = shore_pos
		add_child(shore_light)
	_build_shore_lantern(Vector3(-3.8, 0, -48.4))
	_build_shore_lantern(Vector3(4.2, 0, -51.0))

	for i in range(12):
		_make_lantern(Vector3(-6.6 + fmod(float(i) * 2.17, 13.2), 0.07, -57.6 - fmod(float(i) * 1.31, 3.0)), float(i) * 0.7)

	_boatman_interact = m.add_interact(BOATMAN_POS, 1.45, "Hỏi người chèo đò", Callable(self, "_talk_boatman"), false)
	m.add_interact(BELL_LEFT_POS, 1.25, "Đánh chuông bên bờ trái", Callable(self, "_ring_bell1"), false)
	m.add_interact(BELL_RIGHT_POS, 1.25, "Đánh chuông bên bờ phải", Callable(self, "_ring_bell2"), false)
	_memorial_interact = m.add_interact(MEMORIAL_POS, 1.25, "Mộ vô danh bên bờ sông", Callable(self, "_work_mo_gio"), false)


func _build_river_backdrop() -> void:
	var backdrop := Node3D.new()
	backdrop.position = Vector3(0, 0, -62.4)
	add_child(backdrop)
	var silhouette := Build.mat(Color(0.025, 0.035, 0.085), 0.96)
	for i in range(9):
		var x := -7.0 + i * 1.75
		var h := 1.0 + float((i * 5) % 4) * 0.45
		Build.box(backdrop, Vector3(1.45, h, 0.8), Vector3(x, h * 0.5, 0), silhouette)
		if i % 3 == 0:
			var far_lantern := Build.lantern(backdrop, 0.075, 0.14, Vector3(x, h * 0.62, -0.46))
			Build.light_lantern(far_lantern, Color(1.0, 0.38, 0.12), 1.0)


func _build_shore_lantern(pos: Vector3) -> void:
	var post := Node3D.new()
	post.position = pos
	add_child(post)
	Build.cyl(post, 0.055, 0.075, 2.05, Vector3(0, 1.02, 0), Build.mat(Color(0.13, 0.08, 0.05), 0.9), 8)
	var lantern := Build.lantern(post, 0.13, 0.24, Vector3(0, 2.0, 0))
	Build.light_lantern(lantern, Color(1.0, 0.48, 0.16), 2.2)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.54, 0.24)
	light.light_energy = 1.75
	light.omni_range = 8.5
	light.position = Vector3(0, 1.9, 0)
	post.add_child(light)


func _build_bell(pos: Vector3, index: int) -> void:
	var frame := Node3D.new()
	frame.position = pos
	add_child(frame)
	var wood := Build.mat(Color(0.13, 0.08, 0.05), 0.9)
	for side in [-0.58, 0.58]:
		Build.cyl(frame, 0.065, 0.08, 2.1, Vector3(side, 1.05, 0), wood, 8)
	Build.box(frame, Vector3(1.38, 0.10, 0.12), Vector3(0, 2.05, 0), wood)
	Build.cyl(frame, 0.28, 0.18, 0.42, Vector3(0, 1.55, 0), Build.mat(Color(0.46, 0.28, 0.09), 0.4), 16)
	Build.cyl(frame, 0.04, 0.04, 0.36, Vector3(0, 1.18, 0), Build.mat(Color(0.14, 0.09, 0.06)), 8)
	var bell_light := OmniLight3D.new()
	bell_light.light_color = Color(1.0, 0.82, 0.48)
	bell_light.light_energy = 0.0
	bell_light.omni_range = 5.0
	bell_light.position = Vector3(0, 1.45, 0)
	frame.add_child(bell_light)
	_bell_lights.append(bell_light)


func _build_boat() -> void:
	var boat := Node3D.new()
	boat.position = BOATMAN_POS + Vector3(0, 0.22, -0.45)
	add_child(boat)
	var wood := Build.mat(Color(0.17, 0.095, 0.05), 0.86)
	Build.box(boat, Vector3(3.6, 0.28, 1.25), Vector3.ZERO, wood)
	Build.box(boat, Vector3(3.9, 0.12, 0.16), Vector3(0, 0.28, -0.58), wood)
	Build.box(boat, Vector3(3.9, 0.12, 0.16), Vector3(0, 0.28, 0.58), wood)
	_boatman = Build.faceless_npc(boat, Vector3(0.45, 0.14, 0.05), Color(0.11, 0.10, 0.13), 0.8, false)
	_boatman.rotation.y = PI
	var pole := Build.cyl(boat, 0.025, 0.03, 3.1, Vector3(1.2, 1.4, 0.1), Build.mat(Color(0.22, 0.13, 0.07)), 8)
	pole.rotation.z = -0.22
	var boat_lantern := Build.lantern(boat, 0.11, 0.22, Vector3(-1.15, 0.62, 0.15))
	Build.light_lantern(boat_lantern, Color(0.95, 0.38, 0.12), 1.8)


func _build_memorial() -> void:
	var soil := Build.mat(Color(0.22, 0.15, 0.10), 0.96)
	Build.cyl(self, 0.9, 1.15, 0.22, MEMORIAL_POS + Vector3(0, 0.11, 0), soil, 10)
	_memorial_stone = Build.box(self, Vector3(0.65, 0.78, 0.15), MEMORIAL_POS + Vector3(0, 0.48, -0.15), Build.mat(Color(0.26, 0.28, 0.30), 0.82))
	_memorial_stone.rotation.x = -0.12
	Build.cyl(self, 0.045, 0.06, 0.28, MEMORIAL_POS + Vector3(0.48, 0.15, 0.28), Build.mat(Color(0.12, 0.23, 0.12)), 7)


func _make_lantern(pos: Vector3, phase: float) -> void:
	var node := Node3D.new()
	node.position = pos
	add_child(node)
	var body := Build.cyl(node, 0.11, 0.14, 0.08, Vector3.ZERO, Build.emis(Color(0.9, 0.34, 0.12), Color(1.0, 0.28, 0.08), 1.35), 8)
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_hoa_dang.append([node, phase])


func enter_beat() -> void:
	m.world.set_zone("c4")
	m.world.set_moon_visible(true)
	m.checkpoint = Vector3(0, 0, -46.5)
	m.ui.set_objective("")
	m.say([["Minh (nghĩ)", "Sông chảy ngược dưới trăng. Một con đò đợi sát bờ, như chưa từng rời đi."]])


func _talk_boatman() -> void:
	if not _boatman_met:
		_boatman_met = true
		m.narrative.heard_boatman = true
		m.say([
			["Người Chèo Đò", "Muốn qua sông thì gọi nước yên lại. Hai chiếc chuông kia đã im quá lâu."],
		], func(): m.ui.set_objective("Hai tiếng chuông đang chờ ở hai bờ."))
		return
	if bell1_rung and bell2_rung and not _kim_taken:
		m.say([["Người Chèo Đò", "Nước đã nghe. Thứ nó trả lại nằm trên bến."]])
		return
	if _kim_taken and not _memorial_carved:
		m.say([["Người Chèo Đò", "Mang sắc ấy đến mộ vô danh. Đừng khắc tên người chết, chỉ khắc điều họ đã giữ." ]])
		return
	if _memorial_carved and not _ready_to_cross:
		_ready_to_cross = true
		_boatman_interact["prompt"] = "Lên đò qua sông"
		m.say([["Người Chèo Đò", "Mộ đã có tiếng chuông giữ hộ. Lên đò đi."]])
		return
	if _ready_to_cross:
		m.goto_chapter(5)


func _ring_bell1() -> void:
	_ring_bell(0)


func _ring_bell2() -> void:
	_ring_bell(1)


func _ring_bell(index: int) -> void:
	if not _boatman_met:
		m.say([["Minh (nghĩ)", "Chuông lạnh ngắt. Người chèo đò có vẻ biết vì sao chúng im lặng."]])
		return
	if index == 0 and bell1_rung:
		m.say([["Minh (nghĩ)", "Tiếng chuông trái vẫn rung rất khẽ trong ngực."]])
		return
	if index == 1 and bell2_rung:
		m.say([["Minh (nghĩ)", "Tiếng chuông phải đã trả lời rồi."]])
		return
	if index == 0:
		bell1_rung = true
	else:
		bell2_rung = true
	_bell_lights[index].light_energy = 1.45
	m.ui.play_chime()
	var text := "Một tiếng chuông dội qua mặt nước."
	if bell1_rung and bell2_rung:
		text = "Hai tiếng chuông chạm nhau. Trên bến, một mảnh sáng sắc như lưỡi dao hiện ra."
	m.say([["Minh (nghĩ)", text]], Callable(self, "_after_bell"))


func _after_bell() -> void:
	if bell1_rung and bell2_rung and _kim_orb == null and not _kim_taken:
		_kim_orb = Build.color_orb(self, KIM_POS + Vector3(0, 1.05, 0), Color(1.0, 0.88, 0.48))
		m.add_interact(KIM_POS, 1.0, "Nhận SẮC KIM", Callable(self, "_take_kim"), true)
		m.ui.set_objective("Một mảnh sáng xuất hiện giữa bến.")


func _take_kim() -> void:
	if _kim_orb == null:
		return
	_kim_orb.queue_free()
	_kim_orb = null
	_kim_taken = true
	m.player.unlock_color("kim")
	m.ui.update_colors()
	m.say([["Minh (nghĩ)", "Sắc Kim lạnh và mỏng như tiếng chuông vừa tắt." ]], func(): m.ui.set_objective("Người chèo đò nhìn về phía mộ vô danh."))


func _work_mo_gio() -> void:
	if not _kim_taken:
		m.say([["Minh (nghĩ)", "Tấm đá trơn, không có tên. Có lẽ nó chờ một nét khắc khác."]])
		return
	if m.player.current_color != "kim":
		m.say([["Minh (nghĩ)", "Mặt đá bắt sáng trong đèn rồi lại tắt. Cần Sắc Kim. (Phím 4)"]])
		return
	if _memorial_carved:
		m.say([["Minh (nghĩ)", "Trên đá chỉ còn một nét chuông. Vậy là đủ."]])
		return
	_memorial_carved = true
	_memorial_interact["used"] = true
	_memorial_stone.material_override = Build.emis(Color(0.55, 0.50, 0.36), Color(1.0, 0.77, 0.28), 0.45)
	m.narrative.add_evidence("c4_bell_mark_on_memorial", "Sắc Kim khắc lên mộ vô danh một nét chuông, trả lại dấu vết cho người từng giữ bến.")
	m.say([
		["Minh (nghĩ)", "Tôi không khắc tên. Chỉ khắc hai nhịp chuông. Mặt đá ấm lên như vừa có người đặt tay lên."],
	], func(): m.ui.set_objective("Quay lại người chèo đò."))


func update(delta: float) -> void:
	_time += delta
	for pair in _hoa_dang:
		var node: Node3D = pair[0]
		var phase: float = pair[1]
		node.position.y = 0.07 + sin(_time * 1.3 + phase) * 0.025
		node.position.x += sin(_time * 0.16 + phase) * delta * 0.12


func clamp_player(pos: Vector3) -> Vector3:
	pos.x = clampf(pos.x, -7.4, 7.4)
	pos.z = clampf(pos.z, -60.3, BANK_Z0 + 0.25)
	return pos
