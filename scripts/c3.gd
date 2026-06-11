# CHƯƠNG BA — NHÀ KÝ ỨC (Mộc)
# Nhà cổ bên trong rộng hơn bên ngoài. Hồn Ma Phai Nhạt (khắc bởi Hỏa).
# Sắc Mộc trên bàn thờ → dây leo mọc thành bậc thang → đố bóng Hoa Sen → ảnh thờ lật lên.
extends Node3D

const Build := preload("res://scripts/build.gd")
const Shapes := preload("res://scripts/shapes.gd")
const ShadowPuzzle := preload("res://scripts/shadow_puzzle.gd")
const Ghost := preload("res://scripts/ghost.gd")

const O := Vector3(60, 0, -30)   # nhà nằm ở "nơi khác" — logic giấc mơ

var m
var puzzle
var ghost
var has_moc := false
var vines_grown := false
var photo_revealed := false
var _steps: Array = []
var _photo: MeshInstance3D
var _moc_orb: Node3D
var _grow_t := -1.0


func build(main) -> void:
	m = main
	var wood_floor := Build.pbr("res://assets/textures/WoodFloor043", 0.7, Color(0.4, 0.31, 0.23), 1.3)
	var wall := Build.mat(Color(0.12, 0.095, 0.07), 0.95)
	# sàn + tường + trần (rất cao — bên trong to hơn bên ngoài)
	Build.box(self, Vector3(15, 0.2, 20), O + Vector3(0, -0.1, 0), wood_floor)
	Build.box(self, Vector3(15, 7.5, 0.5), O + Vector3(0, 3.75, -10), wall)
	Build.box(self, Vector3(15, 7.5, 0.5), O + Vector3(0, 3.75, 10), wall)
	Build.box(self, Vector3(0.5, 7.5, 20), O + Vector3(-7.5, 3.75, 0), wall)
	Build.box(self, Vector3(0.5, 7.5, 20), O + Vector3(7.5, 3.75, 0), wall)
	Build.box(self, Vector3(15, 0.4, 20), O + Vector3(0, 7.4, 0), Build.mat(Color(0.06, 0.045, 0.035)))
	# hai hàng cột lim hút lên bóng tối
	for zz in [-6.0, -2.0, 2.0, 6.0]:
		for xx in [-3.5, 3.5]:
			Build.cyl(self, 0.22, 0.26, 7.2, O + Vector3(xx, 3.6, zz), Build.mat(Color(0.1, 0.07, 0.05), 0.85), 10)
	# bàn thờ cuối gian
	Build.box(self, Vector3(4.0, 1.1, 1.2), O + Vector3(0, 0.55, -8.8), Build.mat(Color(0.16, 0.1, 0.06), 0.8))
	Build.box(self, Vector3(4.2, 0.08, 1.4), O + Vector3(0, 1.14, -8.8), Build.mat(Color(0.2, 0.13, 0.07), 0.7))
	# ảnh thờ — úp mặt xuống
	_photo = Build.box(self, Vector3(0.55, 0.04, 0.75), O + Vector3(0, 1.2, -8.7), Build.mat(Color(0.22, 0.18, 0.12), 0.6))
	# hoành phi sơn son thếp vàng trên án + câu đối hai cột trong
	Build.box(self, Vector3(2.4, 0.7, 0.06), O + Vector3(0, 3.1, -9.6), Build.mat(Color(0.55, 0.42, 0.15), 0.45))
	Build.box(self, Vector3(2.2, 0.55, 0.08), O + Vector3(0, 3.1, -9.58), Build.mat(Color(0.1, 0.04, 0.03), 0.6))
	for xx in [-3.5, 3.5]:
		Build.box(self, Vector3(0.04, 2.2, 0.4), O + Vector3(xx + (0.28 if xx < 0 else -0.28), 2.6, -6.0), Build.mat(Color(0.32, 0.06, 0.04), 0.55))
	# bát nhang + ba nén nhang (đầu nhang đỏ lập lòe)
	Build.cyl(self, 0.16, 0.13, 0.18, O + Vector3(-0.9, 1.28, -8.8), Build.mat(Color(0.3, 0.28, 0.25)))
	for k in range(3):
		var ix := -0.9 + (k - 1) * 0.06
		Build.cyl(self, 0.008, 0.008, 0.5, O + Vector3(ix, 1.6, -8.8 + (k % 2) * 0.04), Build.mat(Color(0.35, 0.22, 0.12)), 6)
		Build.ball(self, 0.015, 0.03, O + Vector3(ix, 1.86, -8.8 + (k % 2) * 0.04), Build.emis(Color(1, 0.3, 0.1), Color(1, 0.25, 0.05), 2.0))
	for cx in [-1.6, 1.6]:
		Build.cyl(self, 0.05, 0.05, 0.35, O + Vector3(cx, 1.35, -8.8), Build.emis(Color(0.9, 0.85, 0.7), Color(1.0, 0.7, 0.3), 1.5))
		var cl := OmniLight3D.new()
		cl.light_color = Color(1.0, 0.65, 0.3)
		cl.light_energy = 0.9
		cl.omni_range = 5.0
		cl.position = O + Vector3(cx, 1.7, -8.8)
		add_child(cl)
	# Sắc Mộc giữa bát nhang
	_moc_orb = Build.color_orb(self, O + Vector3(-0.9, 1.7, -8.8), Color(0.3, 1.0, 0.38))
	# chậu dây leo + các bậc thang chưa mọc
	Build.cyl(self, 0.35, 0.45, 0.5, O + Vector3(-6.2, 0.25, -3.0), Build.mat(Color(0.2, 0.12, 0.08)))
	for i in range(7):
		var step := Build.box(self, Vector3(1.5, 0.16, 0.8),
			O + Vector3(-6.0, 0.4 + i * 0.42, -3.8 - i * 0.78), Build.emis(Color(0.16, 0.4, 0.18), Color(0.3, 1.0, 0.38), 0.4, 0.8))
		step.scale = Vector3(0.01, 0.01, 0.01)
		_steps.append(step)
	# gác lửng
	Build.box(self, Vector3(6.0, 0.25, 3.0), O + Vector3(-4.0, 3.2, -8.3), wood_floor)
	# hồn ma giữa gian
	ghost = Ghost.new()
	add_child(ghost)
	ghost.setup(O + Vector3(0.5, 0, -2.0), "hoa", m.player, Callable(self, "_caught"))
	# đố bóng hoa sen trên gác — chiếu lên vách cuối
	puzzle = ShadowPuzzle.new()
	add_child(puzzle)
	puzzle.setup(O + Vector3(-4.0, 4.4, -7.2), O.z - 9.7, Shapes.lotus_polygon(), 0.45, -1.1, false)
	puzzle.solved_callback = Callable(self, "_on_lotus_solved")

	m.add_interact(O + Vector3(-0.9, 0, -8.0), 2.0, "Nhận SẮC MỘC trên bàn thờ", Callable(self, "_take_moc"), true)
	m.add_interact(O + Vector3(-6.2, 0, -3.0), 2.4, "Chậu dây leo khô", Callable(self, "_try_grow"), false)
	m.add_interact(Vector3(puzzle.light_pos.x, 3.2, puzzle.light_pos.z), 2.4, "Đèn sen của gian thờ", Callable(self, "_enter_puzzle"), false)
	m.add_interact(O + Vector3(0, 0, 9.0), 2.2, "Cánh cửa ra", Callable(self, "_try_exit"), false)


func enter_beat() -> void:
	m.world.set_zone("c3")
	m.world.set_moon_visible(false)
	m.checkpoint = O + Vector3(0, 0, 8.5)
	m.ui.set_objective("Ngôi nhà duy nhất còn mở cửa")
	m.say([
		["Minh (nghĩ)", "Cửa ngoài rộng hai sải tay. Gian trong... mười cột. Nhà ai mà bên trong to hơn bên ngoài?"],
		["Minh (nghĩ)", "Mùi gỗ lim, mùi nhang tắt. Quen lắm. Quen đến mức tôi không dám nhớ ra là quen ở đâu."],
		["Minh (nghĩ)", "Giữa gian có một... khoảng người bị xóa. Như vết ngón tay cái di lên bức tranh còn ướt."],
		["Minh (nghĩ)", "Nó không nhìn tôi. Nó nhìn ÁNH SÁNG của tôi. Thử lửa xem — phím 1."],
	])


func _caught() -> void:
	m.respawn(m.checkpoint, "Lạnh. Như rơi vào giấc ngủ không đáy. Suýt nữa thì tôi cũng... phai.")


func _take_moc() -> void:
	_moc_orb.queue_free()
	m.player.unlock_color("moc")
	m.ui.update_colors()
	has_moc = true
	m.say([
		["Minh (nghĩ)", "Một mầm xanh mọc từ tro nhang nguội. Sống — ở chỗ chết nhất căn nhà."],
	], func(): m.ui.set_objective("SẮC MỘC (phím 3): đánh thức chậu dây leo ở góc nhà"))


func _try_grow() -> void:
	if vines_grown:
		return
	if not has_moc or m.player.current_color != "moc":
		m.say([["Minh (nghĩ)", "Dây leo khô quắt từ bao giờ. Nhưng rễ thì... rễ vẫn bám. Thứ này cần màu của sự sống."]])
		return
	vines_grown = true
	_grow_t = 0.0
	m.say([["Minh (nghĩ)", "Dây leo bò lên trong ánh xanh — chậm rãi, kẽo kẹt, như người già vươn vai sau giấc ngủ dài."]],
		func(): m.ui.set_objective("Lên gác lửng theo bậc dây leo"))


func _enter_puzzle() -> void:
	if not puzzle.solved and m.player.position.y > 2.5:
		m.enter_puzzle(puzzle, "A / D — xoay đèn cho bóng HOA SEN khớp vệt mờ trên vách")


func _on_lotus_solved() -> void:
	m.ui.play_chime()
	photo_revealed = true
	m.exit_puzzle_after(1.6)
	# ảnh thờ tự lật lên + nến phụt tắt một nhịp
	var tw := create_tween()
	tw.tween_property(_photo, "rotation:x", -1.45, 1.2).set_ease(Tween.EASE_OUT)
	_photo.material_override = Build.emis(Color(0.8, 0.75, 0.65), Color(0.9, 0.85, 0.7), 0.35)
	m.world.blackout_beat()
	m.say([
		["Minh (nghĩ)", "Bóng sen vừa khớp — cả gian nhà THỞ ra một hơi. Và cái ảnh thờ... tự lật lên."],
		["Minh (nghĩ)", "Một gương mặt trẻ. Quen khủng khiếp."],
		["Minh (nghĩ)", "...Ảnh thờ nhà người ta. Mình nhìn nhầm thôi. Nhìn nhầm... thôi."],
	], func(): m.ui.set_objective("Rời khỏi ngôi nhà"))


func _try_exit() -> void:
	if photo_revealed:
		m.say([["Minh (nghĩ)", "Cánh cửa mở ra... không phải con ngõ lúc nãy. Gió sông. Ngôi nhà nhả tôi ra ở một nơi khác."]],
			func(): m.goto_chapter(4))
	else:
		m.say([["Minh (nghĩ)", "Cửa đóng chặt như nín thở. Ngôi nhà này chưa muốn cho tôi đi — nó còn giữ một thứ chưa ai thắp."]])


func update(delta: float) -> void:
	if _grow_t >= 0.0 and _grow_t < 12.0:
		_grow_t += delta
		for i in range(_steps.size()):
			var t := clampf(_grow_t - i * 0.55, 0.0, 1.0)
			var s := 1.0 - pow(1.0 - t, 3.0)
			_steps[i].scale = Vector3(maxf(s, 0.01), maxf(s, 0.01), maxf(s, 0.01))


func clamp_player(pos: Vector3) -> Vector3:
	pos.x = clampf(pos.x, O.x - 7.0, O.x + 7.0)
	pos.z = clampf(pos.z, O.z - 9.4, O.z + 9.4)
	# leo bậc dây leo: vùng cầu thang nâng cao độ dần
	var y := 0.0
	if vines_grown and absf(pos.x - (O.x - 6.0)) < 1.1 and pos.z < O.z - 3.2 and pos.z > O.z - 9.6:
		var prog := clampf((O.z - 3.6 - pos.z) / 4.6, 0.0, 1.0)
		y = prog * 3.2
	# trên gác lửng
	if pos.y > 2.0 and pos.x > O.x - 7.0 and pos.x < O.x - 1.0 and pos.z < O.z - 6.8:
		y = 3.32
	pos.y = lerpf(pos.y, y, 0.4) if absf(pos.y - y) > 0.01 else y
	return pos
