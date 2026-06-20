# CHƯƠNG MỘT — NGÕ KHÔNG TÊN (Hỏa)
# Ngõ xám → bà hàng nước không mặt → quầy ký ức → nhà khóa → Chim Lạc ba lớp → Sắc Hỏa → giếng khô xuống C2.
extends Node3D

const Build := preload("res://scripts/build.gd")
const Shapes := preload("res://scripts/shapes.gd")
const BirdStencilPuzzle := preload("res://scripts/bird_stencil_puzzle.gd")

var m  # main
var puzzle
var web_burned := false
var _web: Node3D
var _brazier_pos := Vector3(-4.2, 0.5, -6.0)
var _orb: Node3D
var stall_inspected := false
var has_house_key := false
var house_unlocked := false
var entered_locked_house := false
var bird_puzzle_solved := false
var hoa_unlocked := false
var basement_open := false
var descended_to_c2 := false
var stencil_parts_collected := {}
var _house_door_pos := Vector3(-6.8, 0, -10.8)
var _front_room_pos := Vector3(-8.2, 0, -13.8)
var _basement_pos := Vector3(-8.2, 0, -19.0)
var _house_root: Node3D
var _part_markers := {}
var _cat: Node3D
var _cat_met := false
var _knocked := false
var _street_lamps: Array = []
var _lamps_lit := 0
# mèo đi dạo: các bậu cửa nó hay ngồi
const CAT_PERCHES := [Vector3(14.5, 0.45, 8.6), Vector3(22.0, 0.45, 13.4), Vector3(-10.5, 0.45, 13.4), Vector3(5.0, 0.45, 8.6)]
var _cat_target := 0
var _cat_state := 0.0     # >0: đang ngồi đếm ngược; <=0: đang đi
var _cat_interact: Dictionary
var _cat_t := 0.0
var _cat_tail: Node3D
# vật liệu PBR dùng chung — cùng bộ texture/tint với world.gd để C1 khớp tông phố
var _m_plaster: StandardMaterial3D
var _m_wood: StandardMaterial3D
var _m_darkwood: StandardMaterial3D
var _m_stone: StandardMaterial3D
var _m_tile: StandardMaterial3D


func _init_materials() -> void:
	# ochre Hội An, hơi xỉn lại cho căn nhà khóa lâu năm
	_m_plaster = Build.pbr("res://assets/textures/Plaster001", 0.5, Color(0.78, 0.62, 0.38), 1.4)
	_m_wood = Build.pbr("res://assets/textures/WoodFloor043", 0.85, Color(0.46, 0.33, 0.22), 1.2)
	_m_darkwood = Build.pbr("res://assets/textures/WoodFloor043", 0.7, Color(0.26, 0.17, 0.10), 1.3)
	_m_stone = Build.pbr("res://assets/textures/PavingStones138", 0.6, Color(0.5, 0.46, 0.43), 0.35)
	_m_tile = Build.pbr("res://assets/textures/RoofingTiles013A", 0.55, Color(0.42, 0.22, 0.12), 0.7)


func build(main) -> void:
	m = main
	_init_materials()
	# quán nước xiêu vẹo + bà hàng nước
	var stall := Node3D.new()
	stall.position = Vector3(-4.4, 0, -6)
	add_child(stall)
	Build.box(stall, Vector3(1.6, 0.08, 0.8), Vector3(0, 0.5, 0), _m_wood)
	for dx in [-0.7, 0.7]:
		Build.box(stall, Vector3(0.08, 0.5, 0.08), Vector3(dx, 0.25, 0), _m_darkwood)
	Build.box(stall, Vector3(2.0, 0.05, 1.4), Vector3(0, 1.9, 0), _m_darkwood)
	for p in [Vector3(-0.9, 0.95, -0.6), Vector3(0.9, 0.95, -0.6), Vector3(-0.9, 0.95, 0.6), Vector3(0.9, 0.95, 0.6)]:
		Build.box(stall, Vector3(0.06, 1.9, 0.06), p, _m_wood)
	# lò than còn đỏ — hai mươi năm sau khi quán đóng
	Build.cyl(stall, 0.18, 0.22, 0.25, Vector3(0.5, 0.13, 0.45), Build.mat(Color(0.15, 0.12, 0.1)))
	Build.ball(stall, 0.1, 0.14, Vector3(0.5, 0.28, 0.45), Build.emis(Color(0.6, 0.1, 0.02), Color(1.0, 0.25, 0.05), 1.8))
	var coal_l := OmniLight3D.new()
	coal_l.light_color = Color(1.0, 0.3, 0.08)
	coal_l.light_energy = 0.7
	coal_l.omni_range = 3.0
	coal_l.position = Vector3(0.5, 0.4, 0.45)
	stall.add_child(coal_l)
	var ba := Build.faceless_npc(stall, Vector3(-0.3, 0, 0.5), Color(0.22, 0.18, 0.16))
	ba.rotation.y = 2.6

	_build_locked_house()

	# ấn tơ nhện dưới cửa hầm trong nhà, không còn là trigger giữa phố
	_web = Node3D.new()
	_web.position = _basement_pos + Vector3(0, 1.1, -0.15)
	add_child(_web)
	var web_mat := StandardMaterial3D.new()
	web_mat.albedo_color = Color(0.55, 0.6, 0.68, 0.16)
	web_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	web_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(7):
		var seg := Build.box(_web, Vector3(2.8, 0.02, 0.02), Vector3.ZERO, web_mat)
		seg.rotation.z = i * PI / 7.0 + 0.2
	for i in range(3):
		var ring := Build.cyl(_web, 0.45 + i * 0.45, 0.45 + i * 0.45, 0.015, Vector3.ZERO, web_mat, 10)
		ring.rotation.x = PI / 2.0

	# đố Chim Lạc ba mảnh nằm trong nhà khóa
	puzzle = BirdStencilPuzzle.new()
	add_child(puzzle)
	puzzle.setup(Vector3(-8.2, 1.3, -16.6), -18.45)
	puzzle.solved_callback = Callable(self, "_on_puzzle_solved")

	m.add_interact(Vector3(-4.7, 0, -5.5), 2.2, "Bà hàng nước / mở quầy ký ức", Callable(self, "_talk_ba"), false)
	m.add_interact(_house_door_pos, 2.0, "Cửa nhà sau quán bị khóa", Callable(self, "_try_unlock_house"), false)
	m.add_interact(Vector3(-9.7, 0, -13.2), 1.8, "Mảnh giấy dó: đầu chim", Callable(self, "_collect_stencil_part").bind("head"), true)
	m.add_interact(Vector3(-6.7, 0, -15.0), 1.8, "Mảnh giấy dó: thân và cánh", Callable(self, "_collect_stencil_part").bind("wing_body"), true)
	m.add_interact(Vector3(-8.9, 0, -17.1), 1.8, "Mảnh giấy dó: đuôi và chân", Callable(self, "_collect_stencil_part").bind("tail_leg"), true)
	m.add_interact(puzzle.stand_pos(), 2.6, "Khung đèn Chim Lạc trong nhà", Callable(self, "_enter_puzzle"), false)
	m.add_interact(_basement_pos, 2.2, "Ấn Hỏa trên cửa hầm / giếng khô", Callable(self, "_try_burn"), false)
	m.add_interact(_basement_pos + Vector3(0, 0, -0.8), 2.0, "Đi xuống giếng khô", Callable(self, "_try_descend"), false)
	_build_street_life()


func _build_locked_house() -> void:
	_house_root = Node3D.new()
	_house_root.name = "C1_Locked_HoiAn_House"
	add_child(_house_root)
	var wood := _m_wood
	var plaster := _m_plaster
	var tile := _m_tile
	var stone := _m_stone
	# footprint: sau quầy, lệch trái khỏi tim phố để không còn là cổng giữa đường
	Build.box(_house_root, Vector3(5.4, 0.10, 8.4), Vector3(-8.2, 0.05, -15.0), stone)
	Build.box(_house_root, Vector3(5.6, 2.3, 0.12), Vector3(-8.2, 1.15, -10.7), plaster)
	Build.box(_house_root, Vector3(5.6, 2.3, 0.12), Vector3(-8.2, 1.15, -19.3), plaster)
	Build.box(_house_root, Vector3(0.12, 2.3, 8.5), Vector3(-11.0, 1.15, -15.0), plaster)
	Build.box(_house_root, Vector3(0.12, 2.3, 8.5), Vector3(-5.4, 1.15, -15.0), plaster)
	Build.box(_house_root, Vector3(6.0, 0.22, 8.9), Vector3(-8.2, 2.45, -15.0), tile)
	# cửa trước có mắt cửa, nằm ngay sau quầy nước
	Build.box(_house_root, Vector3(1.15, 1.85, 0.10), _house_door_pos + Vector3(0, 0.93, 0.04), wood)
	Build.door_eye(_house_root, _house_door_pos + Vector3(-0.22, 1.45, 0.10), 1.0)
	Build.door_eye(_house_root, _house_door_pos + Vector3(0.22, 1.45, 0.10), 1.0)
	# phòng trước / sân trong / bàn thờ / ngấn lũ
	Build.box(_house_root, Vector3(3.8, 0.04, 0.75), _front_room_pos + Vector3(0, 0.55, 1.3), wood)
	for x in [-9.6, -6.8]:
		Build.cyl(_house_root, 0.07, 0.09, 2.2, Vector3(x, 1.1, -15.5), wood, 8)
	var altar := Build.box(_house_root, Vector3(1.5, 0.12, 0.55), Vector3(-8.2, 0.85, -18.35), wood)
	altar.set_meta("role", "altar")
	Build.cyl(_house_root, 0.04, 0.05, 0.38, Vector3(-8.2, 1.1, -18.36), Build.mat(Color(0.55, 0.45, 0.32)), 8)
	Build.box(_house_root, Vector3(5.1, 0.04, 0.035), Vector3(-8.2, 1.85, -10.62), Build.mat(Color(0.12, 0.18, 0.22)))
	var well := Build.cyl(_house_root, 0.65, 0.65, 0.46, _basement_pos + Vector3(0, 0.23, -0.75), stone, 18)
	well.set_meta("role", "dry_well_c2_entrance")
	# mốc thu nhặt mảnh ghép, dùng placeholder giấy dó chứ không import Meshy nặng
	_make_part_marker("head", Vector3(-9.7, 0.52, -13.2), Color(0.9, 0.48, 0.22))
	_make_part_marker("wing_body", Vector3(-6.7, 0.52, -15.0), Color(0.95, 0.74, 0.25))
	_make_part_marker("tail_leg", Vector3(-8.9, 0.52, -17.1), Color(0.78, 0.38, 0.14))
	m.add_interact(Vector3(-8.2, 0, -18.2), 1.8, "Bàn thờ trong căn nhà khóa", Callable(self, "_altar_clue"), false)


func _make_part_marker(id: String, pos: Vector3, color: Color) -> void:
	var node := Build.box(_house_root, Vector3(0.38, 0.03, 0.24), pos, Build.emis(color * 0.55, color, 0.65))
	node.rotation.y = 0.35
	_part_markers[id] = node


# ---- phố Trần Phú: những thứ chạm vào được (và vài thứ không nên chạm) ----
func _build_street_life() -> void:
	# mèo đen trên bậu cửa — nó nhìn cậu trước khi cậu thấy nó
	_cat = Node3D.new()
	_cat.position = Vector3(14.5, 0.45, 8.6)
	add_child(_cat)
	var fur := Build.mat(Color(0.04, 0.04, 0.05), 0.9)
	# thân — hình cầu dẹt nằm ngang (scale z > x)
	var body := Build.ball(_cat, 0.13, 0.22, Vector3(0, 0.13, 0), fur)
	body.scale = Vector3(0.85, 0.72, 1.22)
	# đầu
	var head := Build.ball(_cat, 0.088, 0.17, Vector3(0, 0.27, 0.13), fur)
	head.scale = Vector3(1.0, 0.92, 0.88)
	# tai — 2 hình nón nhọn
	for ex in [-0.045, 0.045]:
		var ear := Build.cyl(_cat, 0.003, 0.024, 0.055, Vector3(ex, 0.36, 0.10), fur, 4)
		ear.rotation.z = ex * 8.0
	# mắt phát sáng vàng
	for ex in [-0.032, 0.032]:
		Build.ball(_cat, 0.010, 0.019, Vector3(ex, 0.275, 0.20), Build.emis(Color(0.9, 0.75, 0.2), Color(0.9, 0.7, 0.1), 1.4))
	# 4 chân — hình trụ ngắn thẳng đứng
	for lx in [-0.07, 0.07]:
		for lz_v in [-0.07, 0.06]:
			var lz: float = lz_v
			Build.cyl(_cat, 0.022, 0.026, 0.12, Vector3(lx, 0.06, lz), fur, 6)
	# đuôi — cong lên và ra sau
	_cat_tail = Build.cyl(_cat, 0.014, 0.022, 0.28, Vector3(-0.09, 0.17, -0.15), fur, 6)
	_cat_tail.rotation.z = 0.85
	_cat_tail.rotation.x = -0.3
	_cat_interact = m.add_interact(Vector3(14.5, 0, 8.6), 1.8, "Con mèo đen", Callable(self, "_pet_cat"), false)
	_cat_state = 4.0
	# cửa nhà gõ được — đừng gõ lần hai
	m.add_interact(Vector3(-19.5, 0, 14.0), 1.8, "Gõ cửa ngôi nhà tối", Callable(self, "_knock_door"), false)
	# Chùa Cầu sau sương Tây
	m.add_interact(Vector3(-36.5, 0, 11.0), 2.5, "Nhìn về phía cây cầu", Callable(self, "_seal_bridge"), false)
	# chân cầu cuối ngõ hẹp (Phase 7) — đặt được một bước lên ván là sương đẩy ngược
	m.add_interact(Vector3(-40.2, 0, 11.0), 2.0, "Chân Chùa Cầu", Callable(self, "_bridge_foot"), false)
	# Phase 8 — điểm dừng khi lang thang mạng phố mở (chỉ tới được sau light_up)
	m.add_interact(Vector3(-21.0, 0, -26.5), 2.4, "Căn nhà đã sụp", Callable(self, "_ruin_thought"), false)
	m.add_interact(Vector3(-8.6, 0, -31.6), 2.6, "Bức tường lạ giữa phố", Callable(self, "_wall_thought"), false)
	m.add_interact(Vector3(-20.0, 0, -50.5), 3.0, "Bờ sông Hoài", Callable(self, "_river_thought"), false)
	# chợ sau sương Đông
	m.add_interact(Vector3(36.5, 0, 11.0), 2.5, "Lắng nghe phía chợ", Callable(self, "_seal_market"), false)
	# gánh hoa đăng bỏ không
	Build.box(self, Vector3(0.9, 0.06, 0.5), Vector3(8.0, 0.25, 12.8), _m_darkwood)
	for hk in range(3):
		Build.cyl(self, 0.08, 0.1, 0.07, Vector3(7.7 + hk * 0.3, 0.32, 12.8), Build.mat(Color(0.75, 0.4, 0.45), 0.7), 8)
	m.add_interact(Vector3(8.0, 0, 12.8), 1.8, "Gánh hoa đăng bỏ không", Callable(self, "_hoa_dang_stall"), false)
	# sáu trụ đèn phố thắp được bằng Sắc Hỏa
	for i in range(6):
		var lx := -30.0 + i * 12.0
		Build.cyl(self, 0.05, 0.07, 2.3, Vector3(lx, 1.15, 10.2), _m_darkwood, 8)
		var lan := Build.lantern(self, 0.15, 0.28, Vector3(lx, 2.5, 10.2))
		_street_lamps.append(lan)
		m.add_interact(Vector3(lx, 0, 10.2), 1.7, "Trụ đèn phố nguội lạnh", Callable(self, "_light_lamp").bind(_street_lamps.size() - 1), false)


func intro_beat() -> void:
	m.ui.set_objective("Đi sâu vào ngõ. Tìm quán nước còn sáng.")
	m.say([
		["Minh (nghĩ)", "Tiếng rao chè trôi qua đầu ngõ... nhưng đã mười năm rồi không ai gánh chè qua đây."],
		["Minh (nghĩ)", "Sương đêm nay có mùi tro. Như ai vừa đốt một chồng thư cũ."],
	], func(): m.remote_voice(
		"c1_first_radio",
		0.12,
		[
			"Trạm Bốn gọi người giữ đèn. Nếu nghe được thì đừng đứng giữa phố.",
			"Quán nước còn sáng là mốc đầu tiên. Người ngồi đó có thể đã quên mình chờ ai.",
			"Không xuống giếng khi chưa có lửa. Nhắc lại: không xuống giếng khi chưa có lửa.",
			["Minh (nghĩ)", "Giọng phát ra từ trong lồng đèn, rè như máy bộ đàm ngấm nước. Nhưng nó biết tôi đang đứng ở đầu ngõ."],
		],
		Callable(),
		7
	))


var _ba_talked := false
func _talk_ba() -> void:
	if m.chapters[2].quest_stage == 1:
		m.chapters[2].ba_lore()
		return
	if not _ba_talked:
		_ba_talked = true
		m.say([
			["Bà Hàng Nước", "Trà còn nóng đó, cậu nhỏ. Ngồi xuống đi. Bà chờ khách... lâu lắm rồi."],
			["Minh", "Bà ơi... quán này đóng cửa từ khi cháu còn bé mà?"],
			["Bà Hàng Nước", "Đóng? À... phải. Bà cũng nhớ là có đóng. Nhưng cậu nhỏ này, NHỚ với CÒN — hai chữ đó ở phố này bây giờ là một đấy."],
			["Bà Hàng Nước", "Đừng hỏi bà cửa nào mở. Đồ trên quầy nhớ rõ hơn bà."],
		], func(): m.open_memory_stall(self))
	elif not stall_inspected:
		m.open_memory_stall(self)
	elif puzzle.solved and _orb != null:
		m.say([["Bà Hàng Nước", "Đem lửa của bà đi. Đằng nào bà cũng không còn ai để pha trà."]])
	else:
		m.say([["Bà Hàng Nước", "Nhà sau quán không tự mở. Chim trong nhà cũng không tự bay."]])


func on_memory_stall_closed(inspected_ids: Array, key_taken: bool) -> void:
	stall_inspected = true
	if key_taken:
		has_house_key = true
		m.ui.set_objective("Dùng chìa khóa mở căn nhà sau quán nước.")
	else:
		m.ui.set_objective("Đọc đủ đồ trên quầy ký ức để hiểu chìa khóa nhà sau quán.")


func _try_unlock_house() -> void:
	if house_unlocked:
		entered_locked_house = true
		m.ui.set_objective("Tìm ba mảnh giấy dó trong nhà để phục dựng Chim Lạc.")
		return
	if not has_house_key:
		m.say([
			["Minh (nghĩ)", "Cửa gỗ cài then từ bên trong. Hai mắt cửa nhìn tôi như nhận ra một người khác."],
			["Trạm Bốn", "Không có chìa thì đừng ép cửa. Nhà ở phố này nhớ lực tay rất lâu."],
		])
		return
	house_unlocked = true
	entered_locked_house = true
	m.say([
		["Minh (nghĩ)", "Chìa xoay đúng một nửa vòng rồi tự kéo tay tôi vào trong."],
		["Minh (nghĩ)", "Phòng trước, sân trong, bàn thờ. Và một miệng giếng khô nằm ở chỗ đáng lẽ phải là nền nhà."],
	], func(): m.ui.set_objective("Tìm ba mảnh giấy dó trong căn nhà. Con mèo đã đi trước."))


func _collect_stencil_part(id: String) -> void:
	if not house_unlocked:
		m.say([["Minh (nghĩ)", "Mảnh giấy nằm bên trong nhà. Tôi cần mở cửa trước đã."]])
		return
	if stencil_parts_collected.has(id):
		return
	stencil_parts_collected[id] = true
	puzzle.collect_and_place_part(id)
	if _part_markers.has(id) and _part_markers[id] != null:
		_part_markers[id].visible = false
	var names := {"head": "đầu chim", "wing_body": "thân và cánh", "tail_leg": "đuôi và chân"}
	m.ui.toast("Đã đặt mảnh %s vào khung đèn" % names.get(id, id))
	if puzzle.has_all_parts():
		m.ui.set_objective("Ba mảnh đã vào khung. Xoay 3 lớp bóng cho Chim Lạc rõ hình.")
	else:
		m.ui.set_objective("Tìm đủ ba mảnh giấy dó trong nhà khóa.")


func _altar_clue() -> void:
	if not house_unlocked:
		m.say([["Minh (nghĩ)", "Bàn thờ nằm sau lớp cửa khóa. Tôi chỉ thấy một vệt đỏ qua khe gỗ."]])
		return
	m.say([
		["Minh (nghĩ)", "Trên bàn thờ không có ảnh. Chỉ có một ô trống hình đèn lồng."],
		["Minh (nghĩ)", "Dưới chân bàn, dòng chữ khắc vội: 'Đừng để người giữ đèn tự nhớ một mình.'"],
	])


func _enter_puzzle() -> void:
	if not house_unlocked:
		m.say([["Minh (nghĩ)", "Khung đèn nằm trong nhà sau quán. Cửa vẫn khóa."]])
		return
	if not puzzle.has_all_parts():
		m.say([["Minh (nghĩ)", "Khung đèn còn khuyết. Cần đủ ba mảnh: đầu, thân/cánh, đuôi/chân."]])
		return
	if not puzzle.solved:
		m.enter_puzzle(puzzle, "1/2/3 — chọn lớp giấy dó · A/D — xoay cho ba lớp Chim Lạc khớp hình mờ")


func _on_puzzle_solved() -> void:
	bird_puzzle_solved = true
	m.ui.play_chime()
	m.world.light_up()
	m.exit_puzzle_after(1.8)
	m.ui.toast("Chim Lạc đã rõ hình. Ấn Hỏa dưới nền nhà nứt ra.")
	_orb = Build.color_orb(self, _basement_pos + Vector3(0.8, 1.1, -0.35), Color(1.0, 0.3, 0.1))
	m.add_interact(_basement_pos + Vector3(0.8, 0, -0.35), 1.8, "Nhận SẮC HỎA từ ấn nứt", Callable(self, "_take_hoa"), true)
	m.ui.set_objective("Nhận SẮC HỎA cạnh giếng khô trong căn nhà.")


func _take_hoa() -> void:
	if _orb != null:
		_orb.queue_free()
		_orb = null
	hoa_unlocked = true
	m.player.unlock_color("hoa")
	m.ui.update_colors()
	m._save_checkpoint()
	m.say([
		["Bà Hàng Nước", "Đem lửa của bà đi. Đằng nào bà cũng không còn ai để pha trà."],
		["Bà Hàng Nước", "...Mà cậu nhỏ. Lúc nãy cậu gọi bà là gì nhỉ? Bà... không nhớ tên mình từ lúc nào rồi."],
		["Minh (nghĩ)", "Tôi cũng không nhớ. Cả phố gọi bà là 'bà hàng nước'. Hình như... chưa ai từng gọi bằng tên."],
	], func(): m.ui.set_objective("SẮC HỎA (phím 1): mở ấn cửa hầm / giếng khô trong nhà."))


func _try_burn() -> void:
	if basement_open:
		return
	if not house_unlocked:
		m.say([["Minh (nghĩ)", "Cửa hầm ở trong căn nhà sau quán. Không thể mở từ ngoài phố."]])
		return
	if not bird_puzzle_solved:
		m.say([["Minh (nghĩ)", "Ấn trên nền vẫn liền mạch. Con chim trên tường còn chưa thành hình."]])
		return
	if not hoa_unlocked:
		m.say([["Minh (nghĩ)", "Ấn nứt ra, nhưng bên trong lạnh như nước giếng. Cần lửa lấy từ chính căn nhà này."]])
		return
	if m.player.current_color != "hoa":
		m.say([["Minh (nghĩ)", "Tơ phủ cửa hầm co lại khi đèn đổi màu. Cần Sắc Hỏa. (Phím 1)"]])
		return
	web_burned = true
	basement_open = true
	if _web != null:
		_web.queue_free()
		_web = null
	m.world.blackout_beat()
	m._save_checkpoint()
	m.say([
		["Minh (nghĩ)", "Tơ trên cửa hầm cháy không khói. Cháy như giấy bị xóa khỏi trí nhớ."],
		["Trạm Bốn", "Đường xuống đã mở. Đừng nhìn lên nếu nghe tiếng nước phía trên đầu."],
		["Minh (nghĩ)", "Miệng giếng khô thở ra mùi đất ướt. Dưới đó có tiếng trẻ con đếm nhịp."],
	], func(): m.ui.set_objective("Đi xuống giếng khô trong nhà để sang Giếng Đôi."))


func can_descend_to_c2() -> bool:
	return stall_inspected and has_house_key and house_unlocked and bird_puzzle_solved and hoa_unlocked and basement_open


func _try_descend() -> void:
	if not can_descend_to_c2():
		if not house_unlocked:
			m.say([["Minh (nghĩ)", "Lối xuống không nằm ngoài phố. Nó ở sau cánh cửa nhà khóa."]])
		elif not bird_puzzle_solved:
			m.say([["Minh (nghĩ)", "Miệng giếng chưa mở. Chim Lạc trên tường vẫn thiếu bóng."]])
		elif not basement_open:
			m.say([["Minh (nghĩ)", "Cửa hầm còn bị ấn Hỏa giữ lại."]])
		return
	descended_to_c2 = true
	m.goto_chapter(2)


func _pet_cat() -> void:
	if not _cat_met:
		_cat_met = true
		m.say([
			["Minh (nghĩ)", "Một con mèo đen. Nó không chớp mắt. Mèo phố này hồi xưa thấy người là chạy..."],
			["Minh (nghĩ)", "Nó không nhìn tôi. Nó nhìn... cái đèn sau vai tôi."],
		])
	elif _cat.visible:
		_cat.visible = false
		m.say([["Minh (nghĩ)", "...Nó không còn ở đó. Mà tôi chưa từng thấy nó rời đi."]])
	else:
		m.say([["Minh (nghĩ)", "Bậu cửa trống. Ấm — như có gì vừa ngồi đây rất lâu."]])


func _knock_door() -> void:
	if not _knocked:
		_knocked = true
		m.say([
			["Minh (nghĩ)", "Cốc. Cốc. Cốc."],
			["Minh (nghĩ)", "..."],
			["Minh (nghĩ)", "Cốc. Cốc. Cốc. — từ BÊN TRONG. Đúng nhịp tôi vừa gõ."],
			["Minh (nghĩ)", "Tôi sẽ không gõ nữa."],
		])
	else:
		m.say([["Minh (nghĩ)", "Không. Tôi đã bảo là không gõ nữa."]])


func _seal_bridge() -> void:
	m.say([
		["Minh (nghĩ)", "Chùa Cầu. Sương đặc đến mức cây cầu chỉ còn là một nét mực tàu."],
		["Minh (nghĩ)", "Có gì đó bên kia sương... vẫn nhớ tôi. Chưa phải lúc. Nhưng sẽ phải đến."],
	])


func _bridge_foot() -> void:
	m.say([
		["Minh (nghĩ)", "Ván cầu ngay trước mũi chân. Tôi đưa chân lên — sương đặc lại thành một bức tường mềm, đẩy ngược."],
		["Minh (nghĩ)", "Con linh thú đá bên vách nhìn thẳng. Không dữ. Chỉ như muốn nói: chưa phải lượt của cậu."],
	])


func _ruin_thought() -> void:
	m.say([
		["Minh (nghĩ)", "Căn nhà này sụp lâu rồi. Vữa gãy, xà cháy đen... nhưng không có mùi khói."],
		["Minh (nghĩ)", "Như thể nó không cháy — mà bị NHAI. Bóng tối ăn ký ức của phố, từng căn một."],
	])


func _wall_thought() -> void:
	m.say([
		["Minh (nghĩ)", "Một bức tường trơn chắn ngang Nguyễn Thái Học. Bản đồ trong đầu tôi nói chỗ này phố thông."],
		["Minh (nghĩ)", "Vữa còn ấm. Có thứ vừa XÂY nó. Và đang giữ một khoảng sân ở bên trong."],
	])


func _river_thought() -> void:
	m.say([
		["Minh (nghĩ)", "Sông Hoài. Mặt nước đen như mực mài, im đến mức nghe được tim mình."],
		["Minh (nghĩ)", "Một đóa hoa đăng trôi NGƯỢC dòng, về phía thượng nguồn. Tôi vờ như chưa thấy."],
	])


func _seal_market() -> void:
	m.say([
		["Minh (nghĩ)", "Phía chợ. Tôi nghe tiếng rao, tiếng dao thớt, tiếng cãi giá..."],
		["Minh (nghĩ)", "...vọng ra từ một khu chợ trống không. Âm thanh không có người. Như đĩa hát quay trong căn nhà bỏ hoang."],
	])


func _hoa_dang_stall() -> void:
	if m.chapters[2].quest_stage == 2:
		m.chapters[2].take_lotus()
		return
	m.say([
		["Minh (nghĩ)", "Gánh hoa đăng bỏ không. Ba đóa sen giấy còn nguyên, giấy chưa ố."],
		["Minh (nghĩ)", "Người bán chỉ vừa rời đi — hai mươi năm trước."],
	])


func _light_lamp(i: int) -> void:
	var lamp: MeshInstance3D = _street_lamps[i]
	if lamp.get_meta("lit", false):
		m.say([["Minh (nghĩ)", "Ngọn đèn này đã ấm lại rồi."]])
		return
	if m.player.current_color != "hoa":
		m.say([["Minh (nghĩ)", "Bấc đèn còn nguyên, chỉ thiếu lửa. (Sắc Hỏa — phím 1)"]])
		return
	lamp.set_meta("lit", true)
	Build.light_lantern(lamp, Color(1.0, 0.45, 0.12), 2.6)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.55, 0.25)
	l.light_energy = 1.1
	l.omni_range = 6.0
	l.position = lamp.position
	add_child(l)
	_lamps_lit += 1
	if _lamps_lit >= 6:
		m.say([
			["Minh (nghĩ)", "Sáu trụ đèn — cả phố Trần Phú ấm lại."],
			["Minh (nghĩ)", "Sau lưng tôi... cảm giác như có rất nhiều người vừa khẽ mỉm cười. Tôi không quay lại nhìn."],
		])
	else:
		m.ui.toast("Đèn phố đã thắp: %d / 6" % _lamps_lit)


func update(delta: float) -> void:
	_update_cat(delta)
	# C2 chỉ được mở bằng tương tác giếng khô trong nhà khóa; không còn street trigger.


# mèo đi dạo giữa các bậu cửa; người lại gần là nó lảng — đúng kiểu mèo
func _update_cat(delta: float) -> void:
	if _cat == null or not _cat.visible:
		return
	_cat_t += delta
	var pdist: float = m.player.position.distance_to(_cat.position)
	if _cat_state > 0.0:
		_cat_state -= delta
		_cat_tail.rotation.x = sin(_cat_t * 1.8) * 0.25
		if pdist < 2.0:
			# người tới gần — đứng dậy lảng sang bậu cửa xa nhất
			var best := 0
			var best_d := 0.0
			for i in range(CAT_PERCHES.size()):
				var d: float = m.player.position.distance_to(CAT_PERCHES[i])
				if d > best_d:
					best_d = d
					best = i
			_cat_target = best
			_cat_state = 0.0
	else:
		var target: Vector3 = CAT_PERCHES[_cat_target]
		var to_t := target - _cat.position
		if to_t.length() < 0.2:
			_cat_state = 5.0 + fmod(_cat_t, 4.0)
		else:
			var speed := 3.4 if pdist < 3.0 else 1.3
			_cat.position += to_t.normalized() * speed * delta
			_cat.rotation.y = atan2(to_t.x, to_t.z)
			_cat.position.y = 0.45 + absf(sin(_cat_t * 9.0)) * 0.05
			_cat_tail.rotation.x = sin(_cat_t * 6.0) * 0.4
	_cat_interact["pos"] = Vector3(_cat.position.x, 0, _cat.position.z)


func clamp_player(pos: Vector3) -> Vector3:
	pos = m.world.clamp_alley(pos)
	if not basement_open and pos.z < -21.0:
		pos.z = -21.0
	return pos
