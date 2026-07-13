# CHƯƠNG NĂM — CHÙA CẦU TREO GIỮA KHÔNG (Thổ)
# Vá một chân cầu bằng phiến đá cùng hoa văn, lấy Sắc Thổ, rồi treo đủ năm Sắc ở rìa cầu.
extends Node3D

const Build := preload("res://scripts/build.gd")

const C := Vector3(0, 40, -120)
const PILLAR_IDS := ["hoa", "thuy", "moc", "kim", "tho"]
const FOUNDATION_SOCKET_POS := C + Vector3(5.85, 0, 3.05)
const FOUNDATION_STONE_POS := C + Vector3(-5.75, 0, 1.45)
const BRIDGE_ENTRY_POS := C + Vector3(0, 0, -3.45)

var m
var _time := 0.0
var _foundation_seen := false
var _foundation_stone_carried := false
var _foundation_restored := false
var _tho_taken := false
var _ritual_complete := false
var _tho_orb: Node3D
var _foundation_stone: Node3D
var _socket_interact: Dictionary
var _stone_interact: Dictionary
var _pillar_done: Dictionary = {}
var _pillar_positions: Dictionary = {}
var _pillar_lights: Dictionary = {}
var _pillar_interacts: Dictionary = {}
var _bridge_interact: Dictionary
var _mist_lights: Array = []


func build(main) -> void:
	m = main
	_build_ground_and_bridge()
	_build_foundation()
	_build_ritual_posts()
	var moon := Build.ball(self, 1.25, 2.5, C + Vector3(-2.8, 8.3, -5.8), Build.emis(Color(0.76, 0.82, 1.0), Color(0.52, 0.64, 1.0), 1.1))
	moon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var moon_light := OmniLight3D.new()
	moon_light.light_color = Color(0.56, 0.64, 1.0)
	moon_light.light_energy = 1.35
	moon_light.omni_range = 20.0
	moon_light.position = C + Vector3(-2.8, 5.6, -3.6)
	add_child(moon_light)
	# Trăng hắt xuống sân nghi lễ; các cột Sắc vẫn tắt cho tới khi người chơi hoàn thành nghi thức.
	for guide_pos in [C + Vector3(-3.4, 3.1, 4.8), C + Vector3(3.4, 3.1, 4.8), C + Vector3(0, 2.8, -5.8)]:
		var guide_light := OmniLight3D.new()
		guide_light.light_color = Color(0.48, 0.56, 0.95)
		guide_light.light_energy = 1.35
		guide_light.omni_range = 11.0
		guide_light.position = guide_pos
		add_child(guide_light)
	for i in range(14):
		var phase := float(i) * 0.61
		var glow := Build.ball(self, 0.035, 0.075, C + Vector3(-7.0 + fmod(float(i) * 1.93, 14.0), 0.45 + fmod(float(i) * 0.41, 1.9), -4.8 + fmod(float(i) * 1.27, 9.0)), Build.emis(Color(0.86, 0.70, 0.34), Color(1.0, 0.62, 0.18), 1.1))
		glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mist_lights.append([glow, phase])


func _build_ground_and_bridge() -> void:
	var ground := Build.mat(Color(0.10, 0.075, 0.065), 0.94)
	Build.cyl(self, 8.3, 8.3, 0.16, C + Vector3(0, -0.08, 0), ground, 32)
	var rim := Build.cyl(self, 8.42, 8.42, 0.04, C + Vector3(0, 0.02, 0), Build.mat(Color(0.34, 0.22, 0.13), 0.7), 32)
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# lối giữa được giữ trống: cầu bắt đầu sau sân nghi lễ, không có cột mọc giữa ván.
	var bridge := Node3D.new()
	bridge.position = C + Vector3(0, 0.12, -6.5)
	add_child(bridge)
	var wood := Build.pbr("res://assets/textures/WoodFloor043", 0.85, Color(0.25, 0.14, 0.08), 1.1)
	for i in range(12):
		Build.box(bridge, Vector3(3.8, 0.16, 0.42), Vector3(0, 0, -2.55 + i * 0.47), wood)
	for side in [-1.0, 1.0]:
		for i in range(5):
			Build.cyl(bridge, 0.045, 0.06, 1.18, Vector3(side * 2.05, 0.55, -2.3 + i * 1.15), Build.mat(Color(0.14, 0.08, 0.05)), 8)
		Build.box(bridge, Vector3(0.05, 0.05, 5.25), Vector3(side * 2.05, 1.08, -0.25), Build.mat(Color(0.34, 0.24, 0.15), 0.75))
	var shrine := Node3D.new()
	shrine.position = C + Vector3(0, 0, -9.5)
	add_child(shrine)
	Build.box(shrine, Vector3(2.6, 0.35, 1.1), Vector3(0, 0.18, 0), Build.mat(Color(0.25, 0.17, 0.10), 0.8))
	for side in [-0.75, 0.75]:
		var lantern := Build.lantern(shrine, 0.13, 0.24, Vector3(side, 0.72, 0))
		Build.light_lantern(lantern, Color(0.92, 0.44, 0.15), 1.8)
		var shrine_light := OmniLight3D.new()
		shrine_light.light_color = Color(1.0, 0.48, 0.18)
		shrine_light.light_energy = 1.15
		shrine_light.omni_range = 7.0
		shrine_light.position = Vector3(side, 0.72, 0)
		shrine.add_child(shrine_light)


func _build_foundation() -> void:
	var stone := Build.mat(Color(0.34, 0.31, 0.27), 0.88)
	var socket := Node3D.new()
	socket.position = FOUNDATION_SOCKET_POS
	add_child(socket)
	Build.cyl(socket, 0.92, 1.05, 0.24, Vector3(0, 0.12, 0), stone, 10)
	Build.box(socket, Vector3(0.78, 0.06, 0.78), Vector3(0, 0.25, 0), Build.mat(Color(0.08, 0.07, 0.065), 0.9))
	for i in range(4):
		var mark := Build.box(socket, Vector3(0.34, 0.022, 0.06), Vector3(0, 0.30, 0), Build.emis(Color(0.34, 0.22, 0.12), Color(0.65, 0.42, 0.18), 0.22))
		mark.rotation.y = i * PI * 0.5
	_socket_interact = m.add_interact(FOUNDATION_SOCKET_POS, 1.12, "Chân cầu bị khuyết", Callable(self, "_inspect_foundation_socket"), false)

	_foundation_stone = Node3D.new()
	_foundation_stone.position = FOUNDATION_STONE_POS + Vector3(0, 0.18, 0)
	add_child(_foundation_stone)
	var stone_piece := Build.box(_foundation_stone, Vector3(0.78, 0.26, 0.78), Vector3.ZERO, stone)
	stone_piece.rotation.y = 0.48
	var edge := Build.box(_foundation_stone, Vector3(0.46, 0.035, 0.08), Vector3(0, 0.15, 0), Build.emis(Color(0.48, 0.31, 0.14), Color(0.85, 0.52, 0.18), 0.35))
	edge.rotation.y = 0.48
	_stone_interact = m.add_interact(FOUNDATION_STONE_POS, 0.95, "Phiến đá khắc hoa văn", Callable(self, "_take_foundation_stone"), false)


func _build_ritual_posts() -> void:
	_pillar_positions = {
		"hoa": C + Vector3(-6.15, 0, 3.35),
		"thuy": C + Vector3(-6.15, 0, 0.25),
		"moc": C + Vector3(-5.65, 0, -3.0),
		"kim": C + Vector3(5.65, 0, -3.0),
		"tho": C + Vector3(6.15, 0, 0.25),
	}
	for sac in PILLAR_IDS:
		var post := Node3D.new()
		post.position = _pillar_positions[sac]
		add_child(post)
		var base := Build.cyl(post, 0.42, 0.52, 0.18, Vector3(0, 0.09, 0), Build.mat(Color(0.28, 0.20, 0.14), 0.86), 10)
		base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		Build.cyl(post, 0.08, 0.10, 1.02, Vector3(0, 0.56, 0), Build.mat(Color(0.16, 0.095, 0.055), 0.84), 8)
		var lantern := Build.lantern(post, 0.13, 0.24, Vector3(0, 1.13, 0))
		var light := OmniLight3D.new()
		light.light_color = _sac_color(sac)
		light.light_energy = 0.0
		light.omni_range = 4.4
		light.position = Vector3(0, 1.12, 0)
		post.add_child(light)
		_pillar_lights[sac] = {"lantern": lantern, "light": light}
		_pillar_interacts[sac] = m.add_interact(_pillar_positions[sac], 1.0, "Treo SẮC %s lên cột đèn" % _sac_label(sac), Callable(self, "_offer_sac").bind(sac), false)


func enter_beat() -> void:
	m.world.set_zone("c5")
	m.world.set_moon_visible(true)
	m.checkpoint = C + Vector3(0, 0, 7.0)
	m.ui.set_objective("")
	m.say([["Minh (nghĩ)", "Chùa Cầu treo giữa khoảng tối. Một chân cầu đã mất, như có ai rút nó khỏi ký ức của phố."]])


func _inspect_foundation_socket() -> void:
	if _foundation_restored:
		m.say([["Minh (nghĩ)", "Chân cầu đã liền lại. Đá dưới tay vẫn còn ấm."]])
		return
	if _foundation_stone_carried:
		_restore_foundation()
		return
	_foundation_seen = true
	_socket_interact["prompt"] = "Chân cầu đang chờ một phiến đá"
	m.say([["Minh (nghĩ)", "Ô đá khuyết có đúng một hoa văn. Gần mép sân, một phiến đá lật úp mang nét khắc cùng hình."]], func(): m.ui.set_objective("Có một phiến đá cùng hoa văn ở mép sân."))


func _take_foundation_stone() -> void:
	if not _foundation_seen:
		m.say([["Minh (nghĩ)", "Phiến đá này không thuộc về đống gạch vụn. Trên mặt nó có một hoa văn bị bẻ đôi."]])
		return
	if _foundation_stone_carried:
		return
	_foundation_stone_carried = true
	_foundation_stone.visible = false
	_stone_interact["used"] = true
	_socket_interact["prompt"] = "Đặt phiến đá vào chân cầu"
	m.say([["Minh (nghĩ)", "Phiến đá vừa khít trong tay, nặng như một đoạn nền nhà bị nhổ khỏi lòng đất."]], func(): m.ui.set_objective("Chân cầu đang chờ phiến đá."))


func _restore_foundation() -> void:
	if _foundation_restored or not _foundation_stone_carried:
		return
	_foundation_restored = true
	_foundation_stone_carried = false
	_socket_interact["used"] = true
	Build.box(self, Vector3(0.76, 0.24, 0.76), FOUNDATION_SOCKET_POS + Vector3(0, 0.36, 0), Build.emis(Color(0.42, 0.31, 0.19), Color(0.76, 0.50, 0.20), 0.32))
	_tho_orb = Build.color_orb(self, FOUNDATION_SOCKET_POS + Vector3(0, 1.1, 0), Color(0.94, 0.65, 0.22))
	m.add_interact(FOUNDATION_SOCKET_POS, 0.86, "Nhận SẮC THỔ", Callable(self, "_take_tho"), true)
	m.ui.play_chime()
	m.say([["Minh (nghĩ)", "Phiến đá khóa vào móng cầu. Từ đường nứt, một sắc vàng đất trồi lên như hơi ấm còn sót lại."]], func(): m.ui.set_objective("Một sắc vàng đất đang sáng ở chân cầu."))


func _take_tho() -> void:
	if _tho_orb == null:
		return
	_tho_orb.queue_free()
	_tho_orb = null
	_tho_taken = true
	m.player.unlock_color("tho")
	m.ui.update_colors()
	m.say([["Minh (nghĩ)", "Năm sắc đã đủ. Năm cột đèn quanh cầu chờ được treo lại."]], func(): m.ui.set_objective("Treo năm Sắc lên năm cột đèn."))


func _offer_sac(id: String) -> void:
	if not _tho_taken:
		m.say([["Minh (nghĩ)", "Các cột đèn im lặng. Cầu vẫn thiếu một chân đứng trên đất."]])
		return
	if m.player.current_color != id:
		m.say([["Minh (nghĩ)", "Cột này chỉ nhận SẮC %s. (Phím %d)" % [_sac_label(id), _sac_key(id)]]])
		return
	if _pillar_done.has(id):
		return
	_pillar_done[id] = true
	_pillar_interacts[id]["used"] = true
	var fixture: Dictionary = _pillar_lights[id]
	Build.light_lantern(fixture["lantern"], _sac_color(id), 2.2)
	fixture["light"].light_energy = 1.2
	m.ui.play_chime()
	match id:
		"hoa":
			m.narrative.set_bond("ba", 2)
			m.say([["Minh (nghĩ)", "Lửa trên cột đỏ lên. Hơi trà cũ thoảng qua, như có người vừa rót thêm một chén."]], Callable(self, "_check_ritual_complete"))
		"thuy":
			m.narrative.set_bond("child", 2)
			m.narrative.add_evidence("c5_water_refuses_body", "Sắc Thủy giữ lại một lối về thay vì nhấn chìm người đã quay lại giữa dòng.")
			m.say([["Minh (nghĩ)", "Ánh nước trôi dọc cột đèn. Ở đáy sáng, đứa trẻ cuối cùng cũng có một cái bóng."]], Callable(self, "_check_ritual_complete"))
		"moc":
			m.narrative.add_evidence("c5_blank_tablet_accepts_ash", "Sắc Mộc giữ hình người trên ảnh thờ thành một ký ức sống, không cần bài vị hay tên khắc.")
			m.say([["Minh (nghĩ)", "Một mầm xanh quấn quanh chân cột. Căn nhà ký ức không còn khép cửa nữa."]], Callable(self, "_check_ritual_complete"))
		"kim":
			m.say([["Minh (nghĩ)", "Tiếng chuông mỏng và trong đi qua mặt sông. Lần này không ai gọi đòi một cái giá."]], Callable(self, "_check_ritual_complete"))
		"tho":
			m.narrative.add_evidence("c5_lantern_is_anchor", "Sắc Thổ neo năm cột đèn vào nền cầu, để lời gọi cuối cùng không còn lặp lại trong đêm lũ.")
			m.say([["Minh (nghĩ)", "Đất dưới chân ngừng rung. Cây cầu có chỗ để đứng lại trong ký ức của phố."]], Callable(self, "_check_ritual_complete"))


func _check_ritual_complete() -> void:
	if _ritual_complete:
		return
	if _pillar_done.size() < PILLAR_IDS.size():
		m.ui.set_objective("Treo các Sắc còn lại lên cột đèn (%d/5)" % _pillar_done.size())
		return
	_ritual_complete = true
	_bridge_interact = m.add_interact(BRIDGE_ENTRY_POS, 1.25, "Bước lên Chùa Cầu", Callable(self, "_begin_ending"), false)
	m.say([
		["Minh (nghĩ)", "Năm cột sáng ở hai bên cầu. Lối giữa cuối cùng cũng trống, như đang chờ người giữ đèn đi qua."]
	], func(): m.ui.set_objective("Chùa Cầu đã sáng."))


func _begin_ending() -> void:
	if not _ritual_complete:
		return
	_bridge_interact["used"] = true
	var figure := Node3D.new()
	figure.position = C + Vector3(0, 0.18, -9.15)
	add_child(figure)
	var ghost_mat := Build.emis(Color(0.82, 0.88, 1.0), Color(0.58, 0.68, 1.0), 0.52)
	Build.faceless_npc(figure, Vector3.ZERO, Color(0.72, 0.76, 0.88), 0.82, false)
	var figure_light := OmniLight3D.new()
	figure_light.light_color = Color(0.70, 0.78, 1.0)
	figure_light.light_energy = 1.0
	figure_light.omni_range = 6.0
	figure_light.position = Vector3(0, 1.2, 0)
	figure.add_child(figure_light)
	m.say([["Minh (nghĩ)", "Ở đầu cầu là bóng người gánh đèn. Không phải điều phố giam lại. Là điều tôi đã bỏ quên."]], func(): m.ending_sequence())


func _sac_label(id: String) -> String:
	match id:
		"hoa": return "HỎA"
		"thuy": return "THỦY"
		"moc": return "MỘC"
		"kim": return "KIM"
		"tho": return "THỔ"
	return id.to_upper()


func _sac_key(id: String) -> int:
	return PILLAR_IDS.find(id) + 1


func _sac_color(id: String) -> Color:
	match id:
		"hoa": return Color(1.0, 0.30, 0.12)
		"thuy": return Color(0.28, 0.62, 1.0)
		"moc": return Color(0.32, 0.90, 0.46)
		"kim": return Color(1.0, 0.92, 0.68)
		"tho": return Color(0.96, 0.72, 0.24)
	return Color.WHITE


func update(delta: float) -> void:
	_time += delta
	for pair in _mist_lights:
		var mote: MeshInstance3D = pair[0]
		var phase: float = pair[1]
		mote.position.y = C.y + 0.45 + fmod(phase, 1.8) + sin(_time * 1.1 + phase) * 0.15


func clamp_player(pos: Vector3) -> Vector3:
	var flat := Vector2(pos.x - C.x, pos.z - C.z)
	if flat.length() > 8.2:
		flat = flat.normalized() * 8.2
	pos.x = C.x + flat.x
	pos.z = C.z + flat.y
	pos.y = C.y
	return pos
