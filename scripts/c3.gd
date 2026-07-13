# CHƯƠNG BA — NHÀ KÝ ỨC (Mộc)
# Nhà cổ bên trong rộng hơn bên ngoài. Hồn Ma Phai Nhạt (khắc bởi Hỏa).
# Sắc Mộc trên bàn thờ → dây leo mọc thành bậc thang → chạm nút dây leo trên gác → ảnh thờ lật lên.
extends Node3D

const Build := preload("res://scripts/build.gd")
const Ghost := preload("res://scripts/ghost.gd")

const O := Vector3(60, 0, -30)   # nhà nằm ở "nơi khác" — logic giấc mơ
const MEMORY_VINE_OFFSET := Vector3(-2.8, 3.32, -7.5)
const MEMORY_ASSEMBLE_SECONDS := 1.2
const MEMORY_HOLD_SECONDS := 0.55

var m
var ghost
var has_moc := false
var vines_grown := false
var photo_revealed := false
var _steps: Array = []
var _photo: MeshInstance3D
var _moc_orb: Node3D
var _grow_t := -1.0
var _frags: Array = []      # [mesh, scattered_pos, assembled_pos]
var _memory_vine: Node3D
var _memory_revealing := false
var _memory_reveal_t := 0.0
var _exit_door: Node3D
var _loft_accessed := false


func build(main) -> void:
	m = main
	var wood_floor := Build.pbr("res://assets/textures/WoodFloor043", 0.7, Color(0.4, 0.31, 0.23), 1.3)
	var wall := Build.mat(Color(0.12, 0.095, 0.07), 0.95)
	var ceiling := Build.mat(Color(0.06, 0.045, 0.035), 0.95)
	wall.cull_mode = BaseMaterial3D.CULL_DISABLED
	ceiling.cull_mode = BaseMaterial3D.CULL_DISABLED
	# sàn + tường + trần (rất cao — bên trong to hơn bên ngoài)
	Build.box(self, Vector3(15, 0.2, 20), O + Vector3(0, -0.1, 0), wood_floor)
	Build.box(self, Vector3(15, 7.5, 0.5), O + Vector3(0, 3.75, -10), wall)
	var exit_width := 2.1
	var side_width := (15.0 - exit_width) * 0.5
	var side_center := exit_width * 0.5 + side_width * 0.5
	Build.box(self, Vector3(side_width, 7.5, 0.5), O + Vector3(-side_center, 3.75, 10), wall)
	Build.box(self, Vector3(side_width, 7.5, 0.5), O + Vector3(side_center, 3.75, 10), wall)
	Build.box(self, Vector3(exit_width, 4.6, 0.5), O + Vector3(0, 5.2, 10), wall)
	Build.box(self, Vector3(0.5, 7.5, 20), O + Vector3(-7.5, 3.75, 0), wall)
	Build.box(self, Vector3(0.5, 7.5, 20), O + Vector3(7.5, 3.75, 0), wall)
	Build.box(self, Vector3(15, 0.4, 20), O + Vector3(0, 7.4, 0), ceiling)
	_exit_door = Node3D.new()
	_exit_door.name = "C3_ExitDoor"
	_exit_door.position = O + Vector3(0, 1.4, 9.68)
	add_child(_exit_door)
	for side in [-1.0, 1.0]:
		Build.box(_exit_door, Vector3(0.97, 2.7, 0.12), Vector3(side * 0.50, 0, 0), wood_floor)
	Build.box(self, Vector3(0.16, 2.8, 0.20), O + Vector3(-1.05, 1.4, 9.65), wood_floor)
	Build.box(self, Vector3(0.16, 2.8, 0.20), O + Vector3(1.05, 1.4, 9.65), wood_floor)
	var entry_light := OmniLight3D.new()
	entry_light.light_color = Color(1.0, 0.5, 0.22)
	entry_light.light_energy = 2.15
	entry_light.omni_range = 10.0
	entry_light.position = O + Vector3(0, 2.4, 7.2)
	add_child(entry_light)
	var hall_light := OmniLight3D.new()
	hall_light.light_color = Color(0.58, 0.38, 0.18)
	hall_light.light_energy = 2.0
	hall_light.omni_range = 12.0
	hall_light.position = O + Vector3(0, 4.4, -1.5)
	add_child(hall_light)
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
		cl.light_energy = 1.45
		cl.omni_range = 7.5
		cl.position = O + Vector3(cx, 1.7, -8.8)
		add_child(cl)
	# Sắc Mộc giữa bát nhang
	_moc_orb = Build.color_orb(self, O + Vector3(-0.9, 1.7, -8.8), Color(0.3, 1.0, 0.38))
	# chậu dây leo + các bậc thang chưa mọc
	Build.cyl(self, 0.35, 0.45, 0.5, O + Vector3(-6.2, 0.25, -3.0), Build.mat(Color(0.2, 0.12, 0.08)))
	var vine_step_mat := Build.pbr("res://assets/textures/WoodFloor043", 0.9, Color(0.16, 0.27, 0.12), 1.0)
	for i in range(7):
		var step := Build.box(self, Vector3(1.5, 0.16, 0.8),
			O + Vector3(-6.0, 0.4 + i * 0.42, -3.8 - i * 0.78), vine_step_mat)
		step.scale = Vector3(0.01, 0.01, 0.01)
		_steps.append(step)
	# gác lửng
	Build.box(self, Vector3(6.0, 0.25, 3.0), O + Vector3(-4.0, 3.2, -8.3), wood_floor)
	_build_memory_vine(wood_floor)
	# hồn ma giữa gian
	ghost = Ghost.new()
	add_child(ghost)
	# hồn ma chỉ để không khí — không bắt, không reset người chơi (callback rỗng)
	ghost.setup(O + Vector3(0.5, 0, -2.0), "hoa", m.player, Callable())
	# Mảnh bóng ký ức rải khắp gian; nút dây leo trên gác sẽ gọi chúng về thành hình.
	_build_memory_fragments()

	m.add_interact(O + Vector3(-0.9, 0, -8.0), 2.0, "Nhận SẮC MỘC trên bàn thờ", Callable(self, "_take_moc"), true)
	m.add_interact(O + Vector3(-6.2, 0, -3.0), 2.4, "Chậu dây leo khô", Callable(self, "_try_grow"), false)
	m.add_interact(memory_vine_position(), 2.1, "Chạm vào nút dây leo trên gác", Callable(self, "_begin_memory_reveal"), true)
	m.add_interact(O + Vector3(0, 0, 9.0), 2.2, "Cánh cửa ra", Callable(self, "_try_exit"), false)


func enter_beat() -> void:
	m.world.set_zone("c3")
	m.world.set_moon_visible(false)
	m.checkpoint = O + Vector3(0, 0, 8.5)
	m.ui.set_objective("")
	m.say([
		["Minh (nghĩ)", "Căn nhà rộng hơn lớp vỏ bên ngoài. Có thứ gì đó đang bị giữ lại giữa gian."],
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
		func(): m.ui.set_objective("Lên gác lửng — tìm nút dây leo sáng trên gác"))


func memory_vine_position() -> Vector3:
	return O + MEMORY_VINE_OFFSET


func _build_memory_vine(wood: Material) -> void:
	_memory_vine = Node3D.new()
	_memory_vine.name = "C3_MemoryVineKnot"
	_memory_vine.position = memory_vine_position()
	add_child(_memory_vine)
	var vine := Build.mat(Color(0.12, 0.28, 0.10), 0.88)
	Build.box(_memory_vine, Vector3(0.72, 0.08, 0.66), Vector3.ZERO, wood)
	for i in range(4):
		var x := -0.22 + i * 0.14
		var stalk := Build.cyl(_memory_vine, 0.035, 0.052, 0.92, Vector3(x, 0.45, 0.04 * sin(i * 2.1)), vine, 8)
		stalk.rotation.z = (i - 1.5) * 0.13
	Build.cyl(_memory_vine, 0.14, 0.1, 0.16, Vector3(0, 0.58, 0), vine, 10).rotation.x = PI * 0.5
	Build.ball(_memory_vine, 0.075, 0.1, Vector3(0, 0.62, 0.08), Build.emis(Color(0.3, 0.72, 0.34), Color(0.22, 0.9, 0.38), 1.15))
	var knot_light := OmniLight3D.new()
	knot_light.light_color = Color(0.42, 1.0, 0.55)
	knot_light.light_energy = 0.45
	knot_light.omni_range = 2.4
	knot_light.position = Vector3(0, 0.62, 0.08)
	_memory_vine.add_child(knot_light)


func _begin_memory_reveal() -> void:
	if photo_revealed or _memory_revealing or not vines_grown:
		return
	_memory_revealing = true
	_memory_reveal_t = 0.0
	if _memory_vine != null:
		var pulse := create_tween()
		pulse.tween_property(_memory_vine, "scale", Vector3(1.12, 1.12, 1.12), 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		pulse.tween_property(_memory_vine, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _build_memory_fragments() -> void:
	# Nút dây leo gọi các mảnh rải khắp gian về thành dáng người trên vách cuối gian.
	var assembled := [
		O + Vector3(0.0, 3.15, -9.55), O + Vector3(-0.5, 2.65, -9.55), O + Vector3(0.5, 2.65, -9.55),
		O + Vector3(-0.35, 2.05, -9.55), O + Vector3(0.35, 2.05, -9.55), O + Vector3(0.0, 1.5, -9.55),
	]
	# vị trí RẢI RÁC: khắp gian trước khi nút dây leo được chạm tới
	var scattered := [
		O + Vector3(-3.5, 4.6, -5.0), O + Vector3(3.4, 1.2, -3.2), O + Vector3(-3.6, 1.0, -7.5),
		O + Vector3(3.5, 4.8, -6.5), O + Vector3(-2.2, 5.2, -2.0), O + Vector3(2.6, 2.4, 1.0),
	]
	for i in range(assembled.size()):
		var shard_mat := StandardMaterial3D.new()
		shard_mat.albedo_color = Color(0.05, 0.16, 0.08, 0.06)
		shard_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		shard_mat.emission_enabled = true
		shard_mat.emission = Color(0.28, 0.9, 0.42)
		shard_mat.emission_energy_multiplier = 0.02
		shard_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var frag := Build.box(self, Vector3(0.55, 0.36, 0.03), scattered[i], shard_mat)
		frag.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_frags.append([frag, scattered[i], assembled[i]])


func _on_photo_resolved() -> void:
	m.ui.play_chime()
	for trio in _frags:
		var frag: MeshInstance3D = trio[0]
		frag.visible = false
	if _exit_door != null:
		_exit_door.visible = false
	# ảnh thờ tự lật lên + nến phụt tắt một nhịp
	var tw := create_tween()
	tw.tween_property(_photo, "rotation:x", -1.45, 1.2).set_ease(Tween.EASE_OUT)
	_photo.material_override = Build.emis(Color(0.8, 0.75, 0.65), Color(0.9, 0.85, 0.7), 0.35)
	m.world.blackout_beat()
	m.say([
		["Minh (nghĩ)", "Dây leo kéo những mảnh bóng về, chồng khít thành một dáng người. Ảnh thờ tự lật lên."],
		["Minh (nghĩ)", "Một gương mặt trẻ, trên vai là sào đèn quen thuộc. Sau lưng cậu, một người phụ nữ đặt tay lên vai như giữ cậu ở lại."],
		["Minh (nghĩ)", "Quen khủng khiếp. ...Chắc mình nhìn nhầm thôi."],
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
	# Tương tác trên gác chủ động gọi các mảnh về, không còn trigger theo một tọa độ ẩn.
	if _memory_revealing and not _frags.is_empty():
		_memory_reveal_t += delta
		var progress := clampf(_memory_reveal_t / MEMORY_ASSEMBLE_SECONDS, 0.0, 1.0)
		var e := progress * progress * (3.0 - 2.0 * progress)
		for trio in _frags:
			var frag: MeshInstance3D = trio[0]
			frag.position = (trio[1] as Vector3).lerp(trio[2], e)
			var mt := frag.material_override as StandardMaterial3D
			mt.albedo_color.a = 0.05 + e * 0.32
			mt.emission_energy_multiplier = 0.02 + e * 0.65
		if _memory_reveal_t >= MEMORY_ASSEMBLE_SECONDS + MEMORY_HOLD_SECONDS:
			_memory_revealing = false
			photo_revealed = true
			_on_photo_resolved()


func clamp_player(pos: Vector3) -> Vector3:
	pos.x = clampf(pos.x, O.x - 7.0, O.x + 7.0)
	pos.z = clampf(pos.z, O.z - 9.4, O.z + 9.4)
	# leo bậc dây leo: vùng cầu thang nâng cao độ dần
	var y := 0.0
	var on_vine_steps := vines_grown and absf(pos.x - (O.x - 6.0)) < 1.1 and pos.z < O.z - 3.2 and pos.z > O.z - 9.6
	if on_vine_steps:
		var prog := clampf((O.z - 3.6 - pos.z) / 4.6, 0.0, 1.0)
		y = prog * 3.2
		if y >= 2.5:
			_loft_accessed = true
	# Không suy luận quyền ở trên gác từ y của frame trước: lúc chuyển ngang ở bậc cuối,
	# y có thể vừa bị kéo về 0 và làm người chơi rơi xuyên sàn gác.
	var on_loft := pos.x > O.x - 7.0 and pos.x < O.x - 1.0 and pos.z < O.z - 6.8
	if _loft_accessed and on_loft:
		y = 3.32
	pos.y = lerpf(pos.y, y, 0.4) if absf(pos.y - y) > 0.01 else y
	return pos
