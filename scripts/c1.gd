# CHƯƠNG MỘT — NGÕ KHÔNG TÊN (Hỏa)
# Ngõ xám → bà hàng nước không mặt → đố bóng Chim Lạc → Sắc Hỏa → đốt rào tơ nhện.
extends Node3D

const Build := preload("res://scripts/build.gd")
const Shapes := preload("res://scripts/shapes.gd")
const ShadowPuzzle := preload("res://scripts/shadow_puzzle.gd")

var m  # main
var puzzle
var web_burned := false
var _web: Node3D
var _brazier_pos := Vector3(-4.2, 0.5, -6.0)
var _orb: Node3D
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


func build(main) -> void:
	m = main
	# quán nước xiêu vẹo + bà hàng nước
	var stall := Node3D.new()
	stall.position = Vector3(-4.4, 0, -6)
	add_child(stall)
	Build.box(stall, Vector3(1.6, 0.08, 0.8), Vector3(0, 0.5, 0), Build.mat(Color(0.2, 0.14, 0.09)))
	for dx in [-0.7, 0.7]:
		Build.box(stall, Vector3(0.08, 0.5, 0.08), Vector3(dx, 0.25, 0), Build.mat(Color(0.13, 0.09, 0.06)))
	Build.box(stall, Vector3(2.0, 0.05, 1.4), Vector3(0, 1.9, 0), Build.mat(Color(0.25, 0.2, 0.12)))
	for p in [Vector3(-0.9, 0.95, -0.6), Vector3(0.9, 0.95, -0.6), Vector3(-0.9, 0.95, 0.6), Vector3(0.9, 0.95, 0.6)]:
		Build.box(stall, Vector3(0.06, 1.9, 0.06), p, Build.mat(Color(0.3, 0.25, 0.14)))
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

	# rào tơ nhện sau cổng
	_web = Node3D.new()
	_web.position = Vector3(0, 1.4, -21.4)
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

	# đố bóng Chim Lạc
	puzzle = ShadowPuzzle.new()
	add_child(puzzle)
	puzzle.setup(Vector3(3.2, 1.6, -17), -20.0, Shapes.bird_polygon(), 0.5, 1.4)
	puzzle.solved_callback = Callable(self, "_on_puzzle_solved")

	m.add_interact(Vector3(-4.7, 0, -5.5), 2.2, "Nói chuyện với bà hàng nước", Callable(self, "_talk_ba"), false)
	m.add_interact(puzzle.stand_pos(), 2.6, "Thắp sáng ký ức (đèn lồng phong ấn)", Callable(self, "_enter_puzzle"), false)
	m.add_interact(Vector3(0, 0, -21.2), 2.4, "Rào tơ nhện chắn lối — cần một ngọn lửa", Callable(self, "_try_burn"), false)
	_build_street_life()


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
	Build.box(self, Vector3(0.9, 0.06, 0.5), Vector3(8.0, 0.25, 12.8), Build.mat(Color(0.3, 0.22, 0.12)))
	for hk in range(3):
		Build.cyl(self, 0.08, 0.1, 0.07, Vector3(7.7 + hk * 0.3, 0.32, 12.8), Build.mat(Color(0.75, 0.4, 0.45), 0.7), 8)
	m.add_interact(Vector3(8.0, 0, 12.8), 1.8, "Gánh hoa đăng bỏ không", Callable(self, "_hoa_dang_stall"), false)
	# sáu trụ đèn phố thắp được bằng Sắc Hỏa
	for i in range(6):
		var lx := -30.0 + i * 12.0
		Build.cyl(self, 0.05, 0.07, 2.3, Vector3(lx, 1.15, 10.2), Build.mat(Color(0.13, 0.09, 0.06)), 8)
		var lan := Build.lantern(self, 0.15, 0.28, Vector3(lx, 2.5, 10.2))
		_street_lamps.append(lan)
		m.add_interact(Vector3(lx, 0, 10.2), 1.7, "Trụ đèn phố nguội lạnh", Callable(self, "_light_lamp").bind(_street_lamps.size() - 1), false)


func intro_beat() -> void:
	m.ui.set_objective("Đi sâu vào ngõ. Tìm nguồn sáng cuối phố.")
	m.say([
		["Minh (nghĩ)", "Tiếng rao chè trôi qua đầu ngõ... nhưng đã mười năm rồi không ai gánh chè qua đây."],
		["Minh (nghĩ)", "Sương đêm nay có mùi tro. Như ai vừa đốt một chồng thư cũ."],
	], func(): m.remote_voice(
		"c1_first_radio",
		0.10,
		[
			"Nghe được không? Nếu đèn còn sáng thì cứ đi sâu vào ngõ.",
			"Đừng trả lời nếu có ai gọi đúng tên. Ở phố này, tên là thứ dễ bị mượn nhất.",
			["Minh (nghĩ)", "Giọng phát ra từ trong lồng đèn, rè như máy bộ đàm ngấm nước. Nhưng nó biết tôi đang đứng ở đầu ngõ."],
		],
		Callable(),
		8
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
			["Bà Hàng Nước", "Cái đèn cuối ngõ ấy. Họa tiết bay mất rồi. Con chim không có bóng thì không đậu lại được đâu."],
			["Bà Hàng Nước", "Lửa trong đèn không phải là lửa, cậu nhỏ ạ. Là điều cậu còn nhớ."],
		], func(): m.ui.set_objective("Sửa chiếc đèn lồng phong ấn ở cuối ngõ (E để tương tác)"))
	elif puzzle.solved and _orb != null:
		m.say([["Bà Hàng Nước", "Đem lửa của bà đi. Đằng nào bà cũng không còn ai để pha trà."]])
	else:
		m.say([["Bà Hàng Nước", "Bóng đổ trên tường ấy, cậu nhỏ. Xoay cho con chim về đúng chỗ nó từng đậu."]])


func _enter_puzzle() -> void:
	if not puzzle.solved:
		m.enter_puzzle(puzzle, "A / D — xoay đèn cho bóng Chim Lạc khớp với hình mờ trên tường")


func _on_puzzle_solved() -> void:
	m.ui.play_chime()
	m.world.open_gate()
	m.world.light_up()
	m.exit_puzzle_after(1.8)
	m.ui.toast("Ký ức đã được thắp sáng. Cánh cổng đang mở...")
	# Sắc Hỏa hiện trên lò than
	_orb = Build.color_orb(self, Vector3(-3.9, 1.1, -5.55), Color(1.0, 0.3, 0.1))
	m.add_interact(Vector3(-3.9, 0, -5.55), 1.8, "Nhận SẮC HỎA", Callable(self, "_take_hoa"), true)
	m.ui.set_objective("Quay lại quán nước — có gì đó vừa hiện trên lò than")


func _take_hoa() -> void:
	_orb.queue_free()
	_orb = null
	m.player.unlock_color("hoa")
	m.ui.update_colors()
	m.say([
		["Bà Hàng Nước", "Đem lửa của bà đi. Đằng nào bà cũng không còn ai để pha trà."],
		["Bà Hàng Nước", "...Mà cậu nhỏ. Lúc nãy cậu gọi bà là gì nhỉ? Bà... không nhớ tên mình từ lúc nào rồi."],
		["Minh (nghĩ)", "Tôi cũng không nhớ. Cả phố gọi bà là 'bà hàng nước'. Hình như... chưa ai từng gọi bằng tên."],
	], func(): m.ui.set_objective("SẮC HỎA (phím 1): đốt rào tơ nhện sau cổng"))


func _try_burn() -> void:
	if web_burned:
		return
	if m.player.current_color != "hoa":
		m.say([["Minh (nghĩ)", "Tơ nhện dày như vải liệm. Tay không thì không xé nổi... Lửa. Cần lửa. (Phím 1 — Sắc Hỏa)"]])
		return
	web_burned = true
	_web.queue_free()
	m.world.blackout_beat()
	m.say([
		["Minh (nghĩ)", "Tơ cháy không khói. Cháy như chưa từng có ở đó."],
		["Minh (nghĩ)", "...Đèn vừa tắt một nhịp. Cả phố. Cùng một nhịp."],
		["Minh (nghĩ)", "Có thứ gì vừa đi qua. Không phải đi qua ngõ. Đi qua TÔI."],
	], func(): m.ui.set_objective("Đi qua cổng — sân giếng đôi ở phía sau"))


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
	# chỉ kích hoạt khi đi sâu TRONG NGÕ — phố mở (Phase 8) cũng có z<-23 ở Lê Lợi/NTH
	if web_burned and m.player.position.z < -23.0 and absf(m.player.position.x) < 5.5:
		m.goto_chapter(2)


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
	if not web_burned and pos.z < -21.0:
		pos.z = -21.0
	return pos
