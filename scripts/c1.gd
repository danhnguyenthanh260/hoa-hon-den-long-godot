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


func intro_beat() -> void:
	m.ui.set_objective("Đi sâu vào ngõ. Tìm nguồn sáng cuối phố.")
	m.say([
		["Minh (nghĩ)", "Tiếng rao chè trôi qua đầu ngõ... nhưng đã mười năm rồi không ai gánh chè qua đây."],
		["Minh (nghĩ)", "Sương đêm nay có mùi tro. Như ai vừa đốt một chồng thư cũ."],
	])


var _ba_talked := false
func _talk_ba() -> void:
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


func update(_delta: float) -> void:
	if web_burned and m.player.position.z < -23.0:
		m.goto_chapter(2)


func clamp_player(pos: Vector3) -> Vector3:
	pos = m.world.clamp_alley(pos)
	if not web_burned and pos.z < -21.0:
		pos.z = -21.0
	return pos
