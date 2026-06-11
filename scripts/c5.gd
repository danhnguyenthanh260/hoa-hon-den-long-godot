# CHƯƠNG NĂM — CHÙA CẦU TREO GIỮA KHÔNG
# Boss: Bóng Tối Thủ Cựu — 3 pha theo vòng TƯƠNG KHẮC (Thủy khắc Hỏa, Hỏa khắc Kim, Thổ khắc Thủy).
extends Node3D

const Build := preload("res://scripts/build.gd")

const C := Vector3(0, 40, -120)
const PHASES := [
	{"form": "HỎA", "weak": "thuy", "tint": Color(1.0, 0.25, 0.08), "taunt": "Nó bùng lên như đám cháy chợ đêm. Lửa thì sợ gì lửa... Nước. NƯỚC."},
	{"form": "KIM", "weak": "hoa", "tint": Color(0.9, 0.92, 1.0), "taunt": "Nó rít lên như ngàn lưỡi gươm mài vào nhau. Kim loại — phải nung cho nó mềm ra."},
	{"form": "THỦY", "weak": "tho", "tint": Color(0.2, 0.5, 1.0), "taunt": "Nó dâng lên như lũ tháng Mười. Nước lớn cỡ nào... đất cũng đắp được đê."},
]

var m
var phase := 0
var burn := 0.0
var fight_active := false
var defeated := false
var _boss: Node3D
var _core: MeshInstance3D
var _blobs: Array = []
var _neg: OmniLight3D
var _debris: Array = []
var _time := 0.0


func build(main) -> void:
	m = main
	# đảo nền giữa hư không
	Build.cyl(self, 9.0, 8.2, 0.8, C + Vector3(0, -0.4, 0), Build.mat(Color(0.13, 0.12, 0.14), 0.9), 24)
	# CHÙA CẦU: cầu vòm gỗ có mái che, miếu nhỏ giữa cầu, tượng thú trấn hai đầu
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
	# mái âm dương cong hai lớp, đầu đao vểnh
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
	# miếu nhỏ giữa cầu (thờ Bắc Đế trấn phong ba)
	Build.box(bridge, Vector3(1.6, 1.4, 1.0), Vector3(0, 1.9, -2.1), Build.mat(Color(0.36, 0.25, 0.14), 0.9))
	Build.box(bridge, Vector3(1.9, 0.12, 1.3), Vector3(0, 2.7, -2.1), Build.mat(Color(0.09, 0.08, 0.09), 0.7))
	Build.box(bridge, Vector3(0.7, 0.5, 0.05), Vector3(0, 1.8, -1.58), Build.mat(Color(0.05, 0.03, 0.03), 0.6))
	var altar_glow := OmniLight3D.new()
	altar_glow.light_color = Color(1.0, 0.5, 0.2)
	altar_glow.light_energy = 0.8
	altar_glow.omni_range = 4.0
	altar_glow.position = Vector3(0, 2.0, -1.8)
	bridge.add_child(altar_glow)
	# tượng linh khuyển / linh hầu trấn hai đầu cầu
	for ke in [-1.0, 1.0]:
		var ped := Vector3(ke * 5.6, 0, 1.0)
		Build.box(bridge, Vector3(0.6, 0.7, 0.6), ped + Vector3(0, 0.35, 0), Build.mat(Color(0.22, 0.22, 0.24), 0.9))
		Build.ball(bridge, 0.22, 0.42, ped + Vector3(0, 0.92, 0), Build.mat(Color(0.3, 0.3, 0.32), 0.85))
		Build.ball(bridge, 0.13, 0.26, ped + Vector3(ke * 0.08, 1.25, 0.08), Build.mat(Color(0.3, 0.3, 0.32), 0.85))
		for ear in [-0.07, 0.07]:
			Build.cyl(bridge, 0.01, 0.04, 0.12, ped + Vector3(ke * 0.08 + ear, 1.4, 0.08), Build.mat(Color(0.28, 0.28, 0.3), 0.85), 6)
	# dãy đèn lồng đỏ dưới mái — thứ duy nhất còn ấm ở đây
	for i in range(5):
		var lan := Build.lantern(bridge, 0.14, 0.26, Vector3(-4.0 + i * 2.0, 2.6, 0))
		Build.light_lantern(lan, Color(1.0, 0.2, 0.08), 2.2)
	# mảnh phố trôi quanh
	for i in range(9):
		var d := Build.box(self, Vector3(2.0 + (i % 3), 0.4, 2.0 + ((i + 1) % 3)),
			C + Vector3(cos(i * 0.7) * (13.0 + (i % 4) * 2.0), -2.0 + (i % 5) * 1.4, sin(i * 0.7) * (13.0 + (i % 3) * 2.5)),
			Build.mat(Color(0.2, 0.16, 0.12), 0.9))
		_debris.append([d, i * 0.7, 13.0 + (i % 4) * 2.0])
	# BOSS
	_boss = Node3D.new()
	_boss.position = C + Vector3(0, 0, -4.0)
	add_child(_boss)
	var void_mat := StandardMaterial3D.new()
	void_mat.albedo_color = Color(0.01, 0.005, 0.02, 0.92)
	void_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	void_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(7):
		var b := Build.ball(_boss, 0.5 + 0.15 * (i % 3), 1.1 + 0.2 * (i % 2),
			Vector3(sin(i * 1.9) * 0.5, 1.2 + i * 0.45, cos(i * 1.4) * 0.4), void_mat)
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_blobs.append(b)
	_core = Build.ball(_boss, 0.34, 0.68, Vector3(0, 2.4, 0), Build.emis(Color(1, 0.3, 0.1), Color(1, 0.3, 0.1), 3.5))
	# đốm ngũ sắc bay quanh nó — những mảnh ký ức nó đã nuốt
	for i in range(6):
		var spark := Build.ball(_boss, 0.05, 0.1,
			Vector3(sin(i * 1.05) * 1.2, 1.0 + (i % 3) * 0.8, cos(i * 1.05) * 1.2),
			Build.emis(Color(0.7, 0.4, 1.0), Color(0.6, 0.3, 1.0), 2.5))
		spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# ánh tà rọi quanh đảo để trận đánh đọc được
	for i in range(4):
		var al := OmniLight3D.new()
		al.light_color = Color(0.4, 0.45, 0.9)
		al.light_energy = 0.7
		al.omni_range = 10.0
		var ang := TAU * i / 4.0
		al.position = C + Vector3(cos(ang) * 7.0, 3.0, sin(ang) * 7.0)
		add_child(al)
	_neg = OmniLight3D.new()
	_neg.light_negative = true
	_neg.light_energy = 2.2
	_neg.omni_range = 7.0
	_neg.position.y = 2.0
	_boss.add_child(_neg)
	# quầng sáng lạnh sát đất quanh nó — khối bóng nổi thành silhouette đen trên nền sáng
	var halo := OmniLight3D.new()
	halo.light_color = Color(0.5, 0.55, 1.0)
	halo.light_energy = 2.4
	halo.omni_range = 5.0
	halo.position.y = 0.25
	_boss.add_child(halo)


func enter_beat() -> void:
	m.world.set_zone("c5")
	m.world.set_moon_visible(false)
	m.checkpoint = C + Vector3(0, 0, 6.5)
	m.ui.set_objective("Chùa Cầu — nơi mọi con đường của phố gặp nhau")
	m.say([
		["Minh (nghĩ)", "Chùa Cầu... treo giữa hư không. Quanh nó, từng mảnh phố trôi như đảo vỡ sau cơn lụt."],
		["Bóng Tối Thủ Cựu", "Người giữ đèn. LẠI là ngươi. Lần nào ngươi cũng tới đây."],
		["Minh", "Trả ánh sáng lại cho phố. Trả ký ức lại cho người."],
		["Bóng Tối Thủ Cựu", "Ký ức của AI, hở Minh? Ngươi thắp lại quán nước — bà lão vẫn không nhớ tên mình. Ngươi soi sáng nhà thờ tổ — ảnh trên án là ảnh của ai?"],
		["Bóng Tối Thủ Cựu", "Ngươi chưa từng hỏi: vì sao cả phố quên... mà MỘT MÌNH NGƯƠI nhớ?"],
		["Minh (nghĩ)", "Nó nói bằng nhiều giọng chồng lên nhau. Giọng bà hàng nước. Giọng đứa trẻ. Giọng người chèo đò."],
	], func(): _start_fight())


func _start_fight() -> void:
	fight_active = true
	_announce_phase()


func _announce_phase() -> void:
	var ph: Dictionary = PHASES[phase]
	_core.material_override = Build.emis(ph["tint"], ph["tint"], 3.5)
	m.ui.set_objective("Nó khoác hình %s — chiếu màu KHẮC nó (giữ nó trong vùng sáng của đèn)" % ph["form"])
	m.say([["Minh (nghĩ)", ph["taunt"]]])


func _phase_break() -> void:
	burn = 0.0
	phase += 1
	m.ui.play_chime()
	_boss.position = C + Vector3(0, 0, -5.0)
	if phase >= PHASES.size():
		_defeat()
	else:
		m.ui.toast("Lớp bóng bong ra như tro giấy...")
		_announce_phase()


func _defeat() -> void:
	defeated = true
	fight_active = false
	m.ui.set_objective("")
	# bóng tối nhỏ lại thành một người gánh đèn
	for b in _blobs:
		b.visible = false
	_core.visible = false
	_neg.light_energy = 0.0
	var figure := Build.faceless_npc(_boss, Vector3.ZERO, Color(0.13, 0.2, 0.42))
	figure.rotation.y = PI
	m.say([
		["Minh (nghĩ)", "Pha cuối vỡ ra. Nó không gầm. Nó NHỎ LẠI — thành một bóng người gầy, đội nón, gánh sào đèn."],
		["Minh (nghĩ)", "Là tôi."],
		["Bóng Tối Thủ Cựu", "Phố không quên chuyện xưa đâu. Phố chỉ quên... người kể."],
		["Bóng Tối Thủ Cựu", "Ngươi chết lâu rồi, người giữ đèn ạ. Đêm nào ngươi cũng đi lại con đường này, thắp lại từng ấy đèn, gặp lại từng ấy người dở dang như ngươi. Rồi đến sáng, tất cả lại xám."],
		["Minh", "...Tôi biết."],
		["Minh", "Biết từ lúc nhìn cái ảnh trên bàn thờ. Nhưng mà này — BIẾT với THÔI là hai chuyện khác nhau."],
		["Minh", "Chừng nào lòng người còn mong cầu cái đẹp, ánh sáng không bao giờ tắt. Sư phụ tôi dạy thế. Ông ấy không nói gì về việc người thắp phải còn sống."],
	], func(): m.ending_sequence())


func update(delta: float) -> void:
	_time += delta
	for trio in _debris:
		var node: MeshInstance3D = trio[0]
		var ang: float = trio[1] + _time * 0.05
		node.position = C + Vector3(cos(ang) * trio[2], node.position.y - C.y, sin(ang) * trio[2])
		node.rotation.y = ang
	if not fight_active or defeated:
		return
	var ph: Dictionary = PHASES[phase]
	var p: Vector3 = m.player.position
	var to_p: Vector3 = p - _boss.position
	to_p.y = 0
	var d: float = to_p.length()
	var correct: bool = m.player.current_color == ph["weak"] and d < 8.0
	if correct:
		burn += delta
		_boss.position -= to_p.normalized() * 0.5 * delta
		var s := 1.0 - burn / 8.0
		_boss.scale = Vector3(s, s, s)
		if burn > 3.2:
			_phase_break()
			return
	else:
		burn = maxf(0.0, burn - delta * 0.5)
		if d > 0.01:
			_boss.position += to_p.normalized() * (0.9 if d > 3.0 else 1.3) * delta
	for i in range(_blobs.size()):
		_blobs[i].scale = Vector3.ONE * (1.0 + 0.22 * sin(_time * 2.6 + i * 1.3))
	_neg.light_energy = 2.2 + sin(_time * 3.4) * 0.5
	if d < 1.3:
		m.respawn(C + Vector3(0, 0, 6.5), "Nó chạm vào tôi — và trong một giây tôi không nhớ nổi MẶT MẸ TÔI. Không. Không được chạm vào nó.")
		_boss.position = C + Vector3(0, 0, -5.0)


func clamp_player(pos: Vector3) -> Vector3:
	var flat := Vector2(pos.x - C.x, pos.z - C.z)
	if flat.length() > 8.2:
		flat = flat.normalized() * 8.2
	pos.x = C.x + flat.x
	pos.z = C.z + flat.y
	pos.y = C.y
	return pos
