# CHƯƠNG HAI — GIẾNG ĐÔI (Thủy)
# Một sân giếng kín, một cánh cổng có then thật. Người chơi tự lần ra lễ trả nước.
extends Node3D

const Build := preload("res://scripts/build.gd")
const GhostWalker := preload("res://scripts/ghost_walker.gd")
const ReflectionPool := preload("res://scripts/reflection_pool.gd")

const Z0 := -20.6
const Z1 := -43.6
const LEFT_WELL_POS := Vector3(-3.25, 0, -28.0)
const RIGHT_WELL_POS := Vector3(3.25, 0, -28.0)
const CHILD_POS := Vector3(0.0, 0, -23.8)
const GATE_POS := Vector3(0.0, 0, -42.65)

var m
var has_thuy := false
var has_lotus := false
var quest_stage := 0
var passed := false
var _child_talked := false
var _left_well_seen := false
var _right_well_seen := false
var _right_well_chosen := false
var _gate_open := false
var _time := 0.0
var _child: Node3D
var _well_orb: Node3D
var _lotus_node: Node3D
var _right_well_water: MeshInstance3D
var _well_reflection: ReflectionPool
var _gate_doors: Node3D
var _gate_leaves: Array = []
var _gate_seal: Node3D
var _child_interact: Dictionary
var _right_well_interact: Dictionary
var _gate_interact: Dictionary
var _lotus_interact: Dictionary


func build(main) -> void:
	m = main
	var plaster := Build.mat(Color(0.28, 0.25, 0.23), 0.96)
	var paving := Build.pbr("res://assets/textures/PavingStones138", 0.65, Color(0.42, 0.43, 0.46), 0.45)
	Build.box(self, Vector3(16.0, 0.16, Z0 - Z1 + 1.0), Vector3(0, -0.08, (Z0 + Z1) * 0.5), paving)
	Build.box(self, Vector3(0.6, 4.0, Z0 - Z1 + 1.0), Vector3(-8.0, 2.0, (Z0 + Z1) * 0.5), plaster)
	Build.box(self, Vector3(0.6, 4.0, Z0 - Z1 + 1.0), Vector3(8.0, 2.0, (Z0 + Z1) * 0.5), plaster)
	Build.box(self, Vector3(6.0, 4.0, 0.6), Vector3(-5.0, 2.0, Z1), plaster)
	Build.box(self, Vector3(6.0, 4.0, 0.6), Vector3(5.0, 2.0, Z1), plaster)
	Build.box(self, Vector3(4.2, 1.2, 0.6), Vector3(0, 4.3, Z1), plaster)
	_build_ritual_gate(Build.pbr("res://assets/textures/WoodFloor043", 0.8, Color(0.19, 0.12, 0.07), 1.15))
	_build_entry_backdrop()
	_build_gate_backdrop()

	for lp in [LEFT_WELL_POS + Vector3(0, 3.5, 0), RIGHT_WELL_POS + Vector3(0, 3.5, 0), Vector3(0, 3.0, -36.0)]:
		var moon_light := OmniLight3D.new()
		moon_light.light_color = Color(0.5, 0.75, 1.0)
		moon_light.light_energy = 1.08
		moon_light.omni_range = 8.0
		moon_light.position = lp
		add_child(moon_light)
	_build_well(LEFT_WELL_POS, false)
	_build_well(RIGHT_WELL_POS, true)
	_build_child()

	_child_interact = m.add_interact(CHILD_POS, 1.15, "Đứa trẻ ngồi bên giếng", Callable(self, "_talk_child"), false)
	m.add_interact(LEFT_WELL_POS, 1.10, "Nhìn xuống giếng trái", Callable(self, "_interact_left_well"), false)
	_right_well_interact = m.add_interact(RIGHT_WELL_POS, 1.10, "Nhìn xuống giếng phải", Callable(self, "_interact_right_well"), false)
	_gate_interact = m.add_interact(GATE_POS, 1.65, "Cổng gỗ khóa kín", Callable(self, "_try_gate"), false)

	var walker := GhostWalker.new()
	add_child(walker)
	walker.speed = 0.42
	walker.setup("res://assets/models/minh_rigged.glb", 1.65,
		[Vector3(-5.8, 0, -24.4), Vector3(-5.8, 0, -31.6), Vector3(-1.6, 0, -31.6), Vector3(-1.6, 0, -24.4)])


func _build_well(pos: Vector3, remembers: bool) -> void:
	var stone := Build.mat(Color(0.24, 0.24, 0.26), 0.95)
	for rot in range(4):
		var ang := rot * PI / 2.0
		var rim := Build.box(self, Vector3(1.5, 0.6, 0.18), pos + Vector3(cos(ang), 0.3, sin(ang)) * 0.66, stone)
		rim.rotation.y = -ang
	var water := Build.box(self, Vector3(1.15, 0.02, 1.15), pos + Vector3(0, 0.5, 0), null)
	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.02, 0.06, 0.08)
	water_mat.metallic = 0.9
	water_mat.roughness = 0.06
	water.material_override = water_mat
	for side in [-0.8, 0.8]:
		Build.cyl(self, 0.05, 0.06, 2.1, pos + Vector3(side, 1.05, 0), Build.mat(Color(0.16, 0.11, 0.07)), 8)
	Build.cyl(self, 0.04, 0.04, 1.8, pos + Vector3(0, 2.05, 0), Build.mat(Color(0.16, 0.11, 0.07)), 8).rotation.z = PI / 2.0
	if remembers:
		_right_well_water = water
		_well_reflection = ReflectionPool.new()
		add_child(_well_reflection)
		_well_reflection.setup(m.camera, 0.5, Vector2i(384, 384), 8)
		var reflection_mat := StandardMaterial3D.new()
		reflection_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		reflection_mat.albedo_texture = _well_reflection.texture()
		reflection_mat.emission_enabled = true
		reflection_mat.emission_texture = _well_reflection.texture()
		reflection_mat.emission_energy_multiplier = 0.92
		_right_well_water.material_override = reflection_mat
		var glow := Build.cyl(self, 0.66, 0.66, 0.02, pos + Vector3(0, 0.56, 0), Build.emis(Color(1, 0.7, 0.4), Color(1.0, 0.55, 0.2), 0.7))
		glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_child() -> void:
	_child = Build.faceless_npc(self, CHILD_POS, Color(0.5, 0.52, 0.55), 0.55, false)
	_child.rotation.y = -1.4
	var child_light := OmniLight3D.new()
	child_light.light_color = Color(0.48, 0.68, 1.0)
	child_light.light_energy = 0.38
	child_light.omni_range = 3.2
	child_light.position = CHILD_POS + Vector3(0, 1.1, 0)
	add_child(child_light)


func _build_gate_backdrop() -> void:
	# Cổng mở ra một ngõ tiếp nối có chiều sâu, không phải một tấm backdrop ngay sau cánh cửa.
	var outlook := Node3D.new()
	outlook.name = "C2_GateOutlook"
	outlook.position = Vector3(0, 0, -50.8)
	add_child(outlook)
	var paving := Build.pbr("res://assets/textures/PavingStones138", 0.7, Color(0.31, 0.34, 0.40), 0.4)
	var house := Build.mat(Color(0.055, 0.07, 0.13), 0.95)
	var roof := Build.mat(Color(0.13, 0.07, 0.05), 0.9)
	var wood := Build.mat(Color(0.11, 0.065, 0.04), 0.88)
	Build.box(outlook, Vector3(13.8, 0.14, 13.2), Vector3(0, -0.09, 0), paving)
	for side in [-1.0, 1.0]:
		Build.box(outlook, Vector3(1.25, 3.0, 12.6), Vector3(side * 6.25, 1.5, 0.25), house)
		Build.box(outlook, Vector3(1.62, 0.18, 12.9), Vector3(side * 6.18, 3.08, 0.25), roof)
		for z in [-3.6, 1.0, 4.9]:
			Build.cyl(outlook, 0.055, 0.075, 2.05, Vector3(side * 5.45, 1.02, z), wood, 8)
			var lantern := Build.lantern(outlook, 0.10, 0.18, Vector3(side * 5.45, 2.0, z))
			Build.light_lantern(lantern, Color(1.0, 0.40, 0.13), 1.45)
	# Mái nhà và cổng nhỏ ở cuối ngõ tạo một điểm nhìn thay vì chặn lối bằng mảng xanh.
	for side in [-1.0, 1.0]:
		Build.box(outlook, Vector3(4.3, 2.45, 0.68), Vector3(side * 4.65, 1.22, -5.9), house)
		var eave := Build.box(outlook, Vector3(4.65, 0.22, 1.05), Vector3(side * 4.65, 2.58, -5.92), roof)
		eave.rotation.z = side * 0.075
	Build.box(outlook, Vector3(0.18, 3.15, 0.55), Vector3(-1.58, 1.58, -5.9), wood)
	Build.box(outlook, Vector3(0.18, 3.15, 0.55), Vector3(1.58, 1.58, -5.9), wood)
	Build.box(outlook, Vector3(3.35, 0.18, 0.55), Vector3(0, 3.02, -5.9), wood)
	var distant_lantern := Build.lantern(outlook, 0.12, 0.22, Vector3(0, 2.12, -5.55))
	Build.light_lantern(distant_lantern, Color(0.86, 0.55, 0.22), 1.65)


func _build_entry_backdrop() -> void:
	# Phía sau lưng lúc mới xuống giếng vẫn là một khoảng sân có lối đi lên, không hở thẳng ra nền trời.
	var entry := Node3D.new()
	entry.name = "C2_WellEntryBackdrop"
	# Lùi hẳn qua vị trí camera follow tại spawn để cảnh chỉ là hậu cảnh, không cắt ngang ống kính.
	entry.position = Vector3(0, 0, Z0 + 7.4)
	add_child(entry)
	var stone := Build.mat(Color(0.19, 0.21, 0.25), 0.92)
	var dark := Build.mat(Color(0.025, 0.035, 0.06), 0.98)
	var roof := Build.mat(Color(0.14, 0.075, 0.045), 0.86)
	Build.box(entry, Vector3(13.6, 0.16, 4.7), Vector3(0, -0.08, 0), stone)
	Build.box(entry, Vector3(4.6, 3.6, 0.48), Vector3(-4.45, 1.8, -0.5), stone)
	Build.box(entry, Vector3(4.6, 3.6, 0.48), Vector3(4.45, 1.8, -0.5), stone)
	Build.box(entry, Vector3(4.1, 0.55, 0.48), Vector3(0, 3.35, -0.5), stone)
	Build.box(entry, Vector3(3.95, 2.75, 0.06), Vector3(0, 1.45, -0.24), dark)
	Build.box(entry, Vector3(10.0, 0.24, 1.05), Vector3(0, 3.82, -0.52), roof)
	for x in [-2.0, 2.0]:
		Build.cyl(entry, 0.07, 0.09, 2.15, Vector3(x, 1.08, -0.16), Build.mat(Color(0.12, 0.075, 0.045), 0.9), 8)
		var lantern := Build.lantern(entry, 0.10, 0.18, Vector3(x, 2.12, -0.12))
		Build.light_lantern(lantern, Color(0.58, 0.74, 1.0), 1.15)
	for i in range(3):
		Build.box(entry, Vector3(2.8 - i * 0.45, 0.12, 0.42), Vector3(0, 0.08 + i * 0.12, 1.22 + i * 0.42), stone)


func _build_ritual_gate(wood: Material) -> void:
	_gate_doors = Node3D.new()
	_gate_doors.name = "C2_RitualGate"
	_gate_doors.position = Vector3(0, 1.55, Z1 + 0.32)
	add_child(_gate_doors)
	var brace := Build.mat(Color(0.09, 0.055, 0.03), 0.82)
	for side in [-1.0, 1.0]:
		var leaf := Node3D.new()
		leaf.position = Vector3(side * 1.68, 0, 0)
		_gate_doors.add_child(leaf)
		_gate_leaves.append(leaf)
		var panel_offset := Vector3(-side * 0.825, 0, 0)
		Build.box(leaf, Vector3(1.65, 3.0, 0.16), panel_offset, wood)
		Build.box(leaf, Vector3(1.28, 0.09, 0.06), panel_offset + Vector3(0, 0.58, 0.12), brace).rotation.z = side * 0.56
		Build.box(leaf, Vector3(1.28, 0.09, 0.06), panel_offset + Vector3(0, -0.58, 0.12), brace).rotation.z = -side * 0.56
	_gate_seal = Node3D.new()
	_gate_doors.add_child(_gate_seal)
	var seal := Build.emis(Color(0.22, 0.48, 0.72), Color(0.28, 0.7, 1.0), 1.15)
	Build.box(_gate_seal, Vector3(2.92, 0.08, 0.06), Vector3(0, 0.02, 0.18), seal)
	for x in [-1.1, -0.55, 0.0, 0.55, 1.1]:
		Build.ball(_gate_seal, 0.055, 0.08, Vector3(x, 0.02, 0.2), seal)


func _open_ritual_gate() -> void:
	if _gate_open:
		return
	_gate_open = true
	_gate_interact["prompt"] = "Đi qua cổng đã mở"
	var door_tween := create_tween().set_parallel(true)
	for i in range(_gate_leaves.size()):
		var direction := -1.0 if i == 0 else 1.0
		door_tween.tween_property(_gate_leaves[i], "rotation:y", direction * PI * 0.58, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if _gate_seal != null:
		var seal_tween := create_tween()
		seal_tween.tween_property(_gate_seal, "scale", Vector3(1.0, 0.01, 0.01), 0.35)
		seal_tween.tween_callback(_gate_seal.queue_free)


func enter_beat() -> void:
	m.world.set_zone("c2")
	m.checkpoint = Vector3(0, 0, -22.0)
	m.ui.set_objective("")
	m.say([["Minh (nghĩ)", "Hai giếng đứng đối diện nhau. Một đứa trẻ đã ngồi chờ ở giữa sân."]])


func _talk_child() -> void:
	if not _child_talked:
		_child_talked = true
		quest_stage = 1
		m.say([
			["Đứa Trẻ Soi Giếng", "Giếng trái soi người đang đứng đây. Giếng phải nhớ người đã rời đi."],
		], func(): m.ui.set_objective("Mặt nước ở hai giếng không giống nhau."))
	elif _right_well_chosen and not has_thuy:
		m.say([["Đứa Trẻ Soi Giếng", "Nước đã nhận ra anh. Lấy ánh nước đi."]])
	elif has_thuy and not has_lotus:
		m.say([["Đứa Trẻ Soi Giếng", "Em để một đóa sen giấy trên bậc giếng. Nước chỉ mở đường cho người biết trả lễ."]])
	elif has_lotus:
		m.say([["Đứa Trẻ Soi Giếng", "Đóa sen cần chạm đúng giếng biết nhớ."]])
	else:
		m.say([["Đứa Trẻ Soi Giếng", "Đừng vội. Nước không kể cùng một chuyện hai lần."]])


func _interact_left_well() -> void:
	if not _child_talked:
		m.say([["Minh (nghĩ)", "Đứa trẻ nhìn mặt nước, như chờ tôi hỏi điều gì đó."]])
		return
	if _left_well_seen:
		m.say([["Minh (nghĩ)", "Giếng trái vẫn chỉ soi sân, ngọn đèn và bóng tôi."]])
		return
	_left_well_seen = true
	m.say([["Minh (nghĩ)", "Giếng trái trả lại đúng những gì đang ở đây: tường đá, ngọn đèn, bóng tôi run trên nước."]], Callable(self, "_after_well_seen"))


func _interact_right_well() -> void:
	if has_lotus:
		_offer_lotus()
		return
	if not _child_talked:
		m.say([["Minh (nghĩ)", "Nước đen như mực. Tôi nên nghe đứa trẻ trước."]])
		return
	if _right_well_chosen:
		m.say([["Minh (nghĩ)", "Dưới mặt nước, phố vẫn sáng lộn ngược."]])
		return
	if not _right_well_seen:
		_right_well_seen = true
		m.narrative.record_contradiction("c2_well_vs_radio_shortcut", "Giếng phải không phản chiếu Minh mà giữ hình ảnh phố Hội còn sáng đèn, lộn ngược dưới đáy nước.")
		m.say([
			["Minh (nghĩ)", "Chỗ lẽ ra là mặt tôi lại là một con phố còn sáng đèn, lộn ngược dưới đáy nước."],
			["Đứa Trẻ Soi Giếng", "Giếng này không soi. Nó nhớ."],
		], Callable(self, "_after_well_seen"))
		return
	_choose_remembering_well()


func _after_well_seen() -> void:
	if _left_well_seen and _right_well_seen and not _right_well_chosen:
		_right_well_interact["prompt"] = "Chạm lại giếng biết nhớ"
		m.ui.set_objective("Một giếng soi. Một giếng nhớ.")


func _choose_remembering_well() -> void:
	_right_well_chosen = true
	quest_stage = 2
	m.say([
		["Minh (nghĩ)", "Tôi đặt tay lên thành giếng phải. Nước không trả lại mặt tôi, chỉ trả lại một thành phố chưa kịp quên."],
	], Callable(self, "_spawn_thuy"))


func _spawn_thuy() -> void:
	if _well_orb != null:
		return
	_well_orb = Build.color_orb(self, RIGHT_WELL_POS + Vector3(0, 1.1, -1.35), Color(0.25, 0.55, 1.0))
	m.add_interact(RIGHT_WELL_POS + Vector3(0, 0, -1.35), 0.82, "Nhận SẮC THỦY", Callable(self, "_take_thuy"), true)
	_right_well_interact["prompt"] = "Giếng phải đang phát sáng"


func _take_thuy() -> void:
	if _well_orb == null:
		return
	_well_orb.queue_free()
	_well_orb = null
	has_thuy = true
	quest_stage = 3
	m.player.unlock_color("thuy")
	m.ui.update_colors()
	_spawn_lotus()
	m.say([
		["Minh (nghĩ)", "Sắc nước lạnh nằm yên trong đèn. Trên bậc giếng, đứa trẻ đặt xuống một đóa sen giấy."],
	], func(): m.ui.set_objective("Một đóa sen giấy đang chờ bên đứa trẻ."))


func _spawn_lotus() -> void:
	if _lotus_node != null:
		return
	_lotus_node = Node3D.new()
	_lotus_node.position = CHILD_POS + Vector3(1.35, 0.22, 0.12)
	add_child(_lotus_node)
	Build.cyl(_lotus_node, 0.075, 0.09, 0.06, Vector3.ZERO, Build.emis(Color(1.0, 0.8, 0.5), Color(1.0, 0.6, 0.25), 2.3), 8)
	for petal in range(6):
		var ang := TAU * petal / 6.0
		Build.ball(_lotus_node, 0.055, 0.045, Vector3(cos(ang) * 0.1, 0.02, sin(ang) * 0.1), Build.mat(Color(0.85, 0.4, 0.5), 0.7))
	_lotus_interact = m.add_interact(CHILD_POS + Vector3(1.35, 0, 0.12), 0.75, "Nhận đóa sen giấy", Callable(self, "_take_lotus"), true)


func _take_lotus() -> void:
	if _lotus_node == null:
		return
	_lotus_node.queue_free()
	_lotus_node = null
	has_lotus = true
	_right_well_interact["prompt"] = "Thả đóa sen xuống giếng phải"
	m.ui.toast("Nhận: ĐÓA SEN GIẤY")
	m.say([["Đứa Trẻ Soi Giếng", "Nước nhớ đường về. Trả đóa sen cho nó trước khi đi."]], func(): m.ui.set_objective("Giếng phải đang chờ lễ trả."))


func _offer_lotus() -> void:
	if not has_lotus:
		m.say([["Minh (nghĩ)", "Giếng này chờ một lễ vật."]])
		return
	if m.player.current_color != "thuy":
		m.say([["Minh (nghĩ)", "Nước trong đèn phải sáng trước khi sen chạm mặt giếng. (Sắc Thủy - phím 2)"]])
		return
	if _gate_open:
		return
	quest_stage = 4
	_right_well_interact["used"] = true
	m.ui.play_chime()
	_open_ritual_gate()
	var lotus := Node3D.new()
	lotus.position = RIGHT_WELL_POS + Vector3(0, 0.56, 0)
	add_child(lotus)
	Build.cyl(lotus, 0.07, 0.09, 0.06, Vector3.ZERO, Build.emis(Color(1.0, 0.8, 0.5), Color(1.0, 0.6, 0.25), 2.5), 8)
	m.say([
		["Minh (nghĩ)", "Đóa sen chạm nước. Then cửa phía cuối sân bật một tiếng khô, rồi hai cánh gỗ mở ra."],
	], func(): m.ui.set_objective("Cổng cuối sân đã mở."))


func _try_gate() -> void:
	if _gate_open:
		if passed:
			return
		passed = true
		m.goto_chapter(3)
		return
	m.say([["Minh (nghĩ)", "Then cửa không nhúc nhích. Nước lạnh khóa kín khe gỗ."]])


func update(delta: float) -> void:
	_time += delta
	if _well_reflection != null:
		_well_reflection.update(delta)
	if _child != null:
		_child.rotation.z = sin(_time * 0.7) * 0.045


func clamp_player(pos: Vector3) -> Vector3:
	pos.x = clampf(pos.x, -7.4, 7.4)
	pos.z = clampf(pos.z, Z1 + 0.35, Z0 + 0.4)
	return pos
