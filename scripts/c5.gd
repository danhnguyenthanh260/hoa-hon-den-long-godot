# CHƯƠNG NĂM — CHÙA CẦU TREO GIỮA KHÔNG
# C5 mới: Không có boss arena. Tìm chứng cứ bằng Sắc.
extends Node3D

const Build := preload("res://scripts/build.gd")

const C := Vector3(0, 40, -120)

var m
var _debris: Array = []
var _time := 0.0

var _water_done := false
var _altar_done := false
var _ground_done := false


func build(main) -> void:
	m = main
	# đảo nền giữa hư không
	Build.cyl(self, 9.0, 8.2, 0.8, C + Vector3(0, -0.4, 0), Build.mat(Color(0.13, 0.12, 0.14), 0.9), 24)
	# CHÙA CẦU
	var bridge := Node3D.new()
	bridge.position = C + Vector3(0, 0, -6.5)
	add_child(bridge)
	var deckwood := Build.pbr("res://assets/textures/WoodFloor043", 0.7, Color(0.5, 0.34, 0.2), 1.2)
	var redcol := Build.mat(Color(0.42, 0.1, 0.07), 0.6)
	
	# mặt cầu cong vòm: 7 nhịp ván
	for s in range(7):
		var sx := -4.5 + s * 1.5
		var sy := 0.6 + 0.55 * (1.0 - pow(sx / 4.5, 2.0))
		var seg := Build.box(bridge, Vector3(1.6, 0.18, 3.2), Vector3(sx, sy, 0), deckwood)
		seg.rotation.z = -sx * 0.05
		# lan can hai bên
		for sz in [-1.5, 1.5]:
			Build.box(bridge, Vector3(1.55, 0.06, 0.08), Vector3(sx, sy + 0.75, sz), deckwood).rotation.z = -sx * 0.05
			Build.cyl(bridge, 0.035, 0.035, 0.72, Vector3(sx, sy + 0.4, sz), redcol, 6)
	# cột đỏ đỡ mái
	for sx in [-4.2, -1.4, 1.4, 4.2]:
		for sz in [-1.35, 1.35]:
			Build.box(bridge, Vector3(0.22, 2.6, 0.22), Vector3(sx, 2.4, sz), redcol)
	# mái âm dương
	Build.box(bridge, Vector3(11.5, 0.22, 4.4), Vector3(0, 3.7, 0), Build.mat(Color(0.09, 0.08, 0.09), 0.7))
	for k in [-1.0, 1.0]:
		var slope := Node3D.new()
		slope.position = Vector3(0, 4.15, k * 1.3)
		slope.rotation.x = k * 0.38
		bridge.add_child(slope)
		var slab := BoxMesh.new()
		slab.size = Vector3(11.8, 0.1, 2.4)
		var smi := MeshInstance3D.new()
		smi.mesh = slab
		smi.material_override = Build.mat(Color(0.11, 0.1, 0.115), 0.6)
		slope.add_child(smi)
		Build.tile_rows(slope, 2.4, 11.8)
	Build.cyl(bridge, 0.1, 0.1, 11.9, Vector3(0, 4.75, 0), Build.mat(Color(0.08, 0.06, 0.05)), 8).rotation.z = PI / 2.0
	for ke in [-1.0, 1.0]:
		var horn := Build.cyl(bridge, 0.012, 0.11, 0.7, Vector3(ke * 5.9, 4.9, 0), Build.mat(Color(0.08, 0.06, 0.05)), 8)
		horn.rotation.z = ke * 1.0
	# miếu nhỏ giữa cầu (thờ Bắc Đế)
	Build.box(bridge, Vector3(1.6, 1.4, 1.0), Vector3(0, 1.9, -2.1), Build.mat(Color(0.36, 0.25, 0.14), 0.9))
	Build.box(bridge, Vector3(1.9, 0.12, 1.3), Vector3(0, 2.7, -2.1), Build.mat(Color(0.09, 0.08, 0.09), 0.7))
	Build.box(bridge, Vector3(0.7, 0.5, 0.05), Vector3(0, 1.8, -1.58), Build.mat(Color(0.05, 0.03, 0.03), 0.6))
	var altar_glow := OmniLight3D.new()
	altar_glow.light_color = Color(1.0, 0.5, 0.2)
	altar_glow.light_energy = 0.8
	altar_glow.omni_range = 4.0
	altar_glow.position = Vector3(0, 2.0, -1.8)
	bridge.add_child(altar_glow)
	# tượng linh khuyển / hầu
	for ke in [-1.0, 1.0]:
		var ped := Vector3(ke * 5.6, 0, 1.0)
		Build.box(bridge, Vector3(0.6, 0.7, 0.6), ped + Vector3(0, 0.35, 0), Build.mat(Color(0.22, 0.22, 0.24), 0.9))
		Build.ball(bridge, 0.22, 0.42, ped + Vector3(0, 0.92, 0), Build.mat(Color(0.3, 0.3, 0.32), 0.85))
		Build.ball(bridge, 0.13, 0.26, ped + Vector3(ke * 0.08, 1.25, 0.08), Build.mat(Color(0.3, 0.3, 0.32), 0.85))
		for ear in [-0.07, 0.07]:
			Build.cyl(bridge, 0.01, 0.04, 0.12, ped + Vector3(ke * 0.08 + ear, 1.4, 0.08), Build.mat(Color(0.28, 0.28, 0.3), 0.85), 6)
	# lồng đèn đỏ
	for i in range(5):
		var lan := Build.lantern(bridge, 0.14, 0.26, Vector3(-4.0 + i * 2.0, 2.6, 0))
		Build.light_lantern(lan, Color(1.0, 0.2, 0.08), 2.2)
	# mảnh phố trôi
	for i in range(9):
		var d := Build.box(self, Vector3(2.0 + (i % 3), 0.4, 2.0 + ((i + 1) % 3)),
			C + Vector3(cos(i * 0.7) * (13.0 + (i % 4) * 2.0), -2.0 + (i % 5) * 1.4, sin(i * 0.7) * (13.0 + (i % 3) * 2.5)),
			Build.mat(Color(0.2, 0.16, 0.12), 0.9))
		_debris.append([d, i * 0.7, 13.0 + (i % 4) * 2.0])
	
	# ánh tà rọi quanh đảo
	for i in range(4):
		var al := OmniLight3D.new()
		al.light_color = Color(0.4, 0.45, 0.9)
		al.light_energy = 0.7
		al.omni_range = 10.0
		var ang := TAU * i / 4.0
		al.position = C + Vector3(cos(ang) * 7.0, 3.0, sin(ang) * 7.0)
		add_child(al)

	# 3 điểm chứng cứ (m.add_interact)
	m.add_interact(C + Vector3(3.0, 0, -5.0), 2.0, "Soi bóng dưới mặt nước đen", Callable(self, "_verify_water"), false)
	m.add_interact(C + Vector3(0, 0, -6.5), 2.5, "Kiểm tra bài vị tại miếu", Callable(self, "_verify_altar"), false)
	m.add_interact(C + Vector3(-4.5, 0, -6.5), 2.0, "Neo cây đèn xuống đất", Callable(self, "_verify_ground"), false)
	# Lối tin-giọng-nói: đặt đèn xuống sớm (thiếu chứng cứ) → ending loop/costly
	m.add_interact(C + Vector3(0, 0, 5.0), 2.2, "Nghe radio — đặt đèn xuống, kết thúc đêm nay", Callable(self, "_place_lantern"), false)


func enter_beat() -> void:
	m.world.set_zone("c5")
	m.world.set_moon_visible(false)
	m.checkpoint = C + Vector3(0, 0, 6.5)
	m.ui.set_objective("Chùa Cầu — nơi mọi con đường của phố gặp nhau")
	m.say([
		["Minh (nghĩ)", "Chùa Cầu... treo giữa hư không. Quanh nó, từng mảnh phố trôi như đảo vỡ sau cơn lụt."],
		["Bóng Tối Thủ Cựu", "Người giữ đèn. Lại là ngươi."],
		["Bóng Tối Thủ Cựu", "Ngươi chắc chứ — rằng đêm nay khác những đêm trước?"],
		["Minh (nghĩ)", "Nó nói bằng nhiều giọng chồng lên nhau: bà hàng nước, đứa trẻ, người chèo đò. Tôi không tin giọng nào trong số đó nữa."],
		["Minh (nghĩ)", "Có ba điểm trên cây cầu này khiến tôi gai người. Tự soi bằng Đèn Ngũ Hành — rồi hẵng kết luận."],
	], func(): m.ui.set_objective("Thu thập 3 chứng cứ trên cầu bằng Sắc phù hợp: mép nước, bài vị, mặt đất."))


func _verify_water() -> void:
	if _water_done: return
	if m.player.current_color != "thuy":
		m.ui.toast("Mặt nước phản chiếu ánh lửa mờ mịt. Cần một Sắc có thể soi rõ bản chất của nước.")
		return
	_water_done = true
	m.say([
		["Giọng radio bị nhiễu", "Nếu đúng là cứu người, vì sao nước không chịu nhận bóng của người giữ đèn?"],
		["Minh (nghĩ)", "Nước tách ra quanh chân tôi. Không phải vì phép — vì nó đang tránh một cái xác đã được tiễn nhiều lần."],
	], func(): 
		m.narrative.add_evidence("c5_water_refuses_body", "Nước không nhận bóng Minh.")
		m.narrative.set_bond("ba", 1)
		m.ui.toast("Đã xác minh: Nước từ chối bóng người.")
		_check_ending()
	)

func _verify_altar() -> void:
	if _altar_done: return
	if m.player.current_color != "hoa":
		m.ui.toast("Bài vị trống trơn, lạnh lẽo. Cần một Sắc có thể làm cháy lớp tro bụi che mờ sự thật.")
		return
	_altar_done = true
	m.say([
		["Giọng radio bị nhiễu", "Tên nào bị giữ lại thì bài vị nào cũng trống. Thử đốt phần nói dối đi."],
		["Minh (nghĩ)", "Tro vàng rơi lên bài vị trống. Nét chữ hiện ra không ghi tên người chết — nó ghi 'người kể chuyện'."],
	], func(): 
		m.narrative.add_evidence("c5_blank_tablet_accepts_ash", "Bài vị ghi tên người kể chuyện.")
		m.narrative.set_bond("child", 1)
		m.ui.toast("Đã xác minh: Bài vị hiện chữ dưới lửa.")
		_check_ending()
	)

func _verify_ground() -> void:
	if _ground_done: return
	if m.player.current_color != "tho":
		m.ui.toast("Mặt đất cứng như đá lạnh. Cần một Sắc có thể neo giữ lại những gì sắp trôi đi.")
		return
	_ground_done = true
	m.say([
		["Giọng radio bị nhiễu", "Nếu chiếc đèn là đường về, đặt nó xuống. Nếu không đặt được, nó là xiềng."],
		["Minh (nghĩ)", "Đất nứt ra, giữ lấy chân đèn. Lần đầu tiên, cây đèn không kéo tôi đi tiếp vòng phố cũ."],
	], func(): 
		m.narrative.add_evidence("c5_lantern_is_anchor", "Đất neo được cây đèn.")
		m.ui.toast("Đã xác minh: Đèn lồng được neo xuống đất.")
		_check_ending()
	)


func _place_lantern() -> void:
	if _water_done and _altar_done and _ground_done:
		m.ui.toast("Chứng cứ đã đủ — sự thật tự hiện ra. Không cần nghe radio nữa.")
		return
	m.say([
		["Giọng radio bị nhiễu", "Đặt đèn xuống đi. Nghi lễ xong rồi. Phố sáng rồi mà — về thôi."],
		["Minh (nghĩ)", "Tay tôi mỏi. Có lẽ chỉ cần phố sáng đêm nay... là đủ. Tôi chưa kịp hiểu vì sao."],
	], func(): m.ending_sequence())


func _check_ending() -> void:
	if _water_done and _altar_done and _ground_done:
		m.say([
			["Minh (nghĩ)", "Nước không nhận bóng tôi. Bài vị ghi 'người kể chuyện'. Đất giữ được chân đèn."],
			["Minh (nghĩ)", "Ba điều ấy chỉ khớp với một người. Không phải tôi đi tìm ký ức cho phố — tôi là ký ức phố không thể quên."],
			["Bóng Tối Thủ Cựu", "...Ngươi tự nói ra rồi đấy. Ta chẳng cần nói gì."],
			["Minh", "Vậy thì tôi đặt đèn xuống đây."],
		], func():
			_show_statue_and_end()
		)


func _show_statue_and_end() -> void:
	var minh_statue := Node3D.new()
	minh_statue.position = C + Vector3(0, 0, -5.0)
	add_child(minh_statue)
	var ghost_mat := StandardMaterial3D.new()
	ghost_mat.albedo_color = Color(0.9, 0.93, 1.0)
	ghost_mat.emission_enabled = true
	ghost_mat.emission = Color(0.6, 0.66, 0.95)
	ghost_mat.emission_energy_multiplier = 0.65
	var figure := Build.glb_statue(minh_statue, "res://assets/models/minh_shape_0.glb", 1.7, ghost_mat)
	figure.rotation.y = PI
	
	m.say([
		["Minh (nghĩ)", "Làn sương đen tụ lại thành một bức tượng trắng nhòe. Bức tượng người gầy, đội nón, gánh sào đèn... Là tôi."],
	], func(): m.ending_sequence())


func update(delta: float) -> void:
	_time += delta
	for trio in _debris:
		var node: MeshInstance3D = trio[0]
		var ang: float = trio[1] + _time * 0.05
		node.position = C + Vector3(cos(ang) * trio[2], node.position.y - C.y, sin(ang) * trio[2])
		node.rotation.y = ang


func clamp_player(pos: Vector3) -> Vector3:
	var flat := Vector2(pos.x - C.x, pos.z - C.z)
	if flat.length() > 8.2:
		flat = flat.normalized() * 8.2
	pos.x = C.x + flat.x
	pos.z = C.z + flat.y
	pos.y = C.y
	return pos
