# CHƯƠNG HAI — GIẾNG ĐÔI (Thủy)
# Sân giếng lặp như giấc mơ: cổng cuối sân gập về điểm xuất phát. Đứa trẻ không bóng.
# Sắc Thủy hiện đường đá ẩn trên vũng tối. Thoát bằng cách đi GIẬT LÙI qua cổng (Shift).
extends Node3D

const Build := preload("res://scripts/build.gd")
const GhostWalker := preload("res://scripts/ghost_walker.gd")
const ReflectionPool := preload("res://scripts/reflection_pool.gd")

const Z0 := -20.6
const Z1 := -43.6
const POOL_Z0 := -33.0
const POOL_Z1 := -37.5

var m
var loops := 0
var has_thuy := false
# nhiệm vụ điều tra: 0 chưa biết gì → 1 hỏi bà hàng nước → 2 tìm sen giấy
# → 3 có sen → 4 đã trả lễ, cổng mở
var quest_stage := 0
var _trail: Array = []
var _child: Node3D
var _plank: MeshInstance3D
var _tiles: Array = []   # [mesh, Vector3]
var _well_orb: Node3D
var _well_reflection: ReflectionPool
var _right_well_water: MeshInstance3D
var _gate_cooldown := 0.0
var _time := 0.0
var passed := false


func build(main) -> void:
	m = main
	var plaster := Build.mat(Color(0.3, 0.26, 0.2), 0.95)
	# tường bao sân
	Build.box(self, Vector3(0.6, 4.0, Z0 - Z1 + 1.0), Vector3(-8.0, 2.0, (Z0 + Z1) / 2.0), plaster)
	Build.box(self, Vector3(0.6, 4.0, Z0 - Z1 + 1.0), Vector3(8.0, 2.0, (Z0 + Z1) / 2.0), plaster)
	Build.box(self, Vector3(6.0, 4.0, 0.6), Vector3(-5.0, 2.0, Z1), plaster)
	Build.box(self, Vector3(6.0, 4.0, 0.6), Vector3(5.0, 2.0, Z1), plaster)
	Build.box(self, Vector3(4.2, 1.2, 0.6), Vector3(0, 4.3, Z1), plaster)
	# cổng vòm cuối sân
	for sx in [-1.9, 1.9]:
		Build.cyl(self, 0.18, 0.22, 2.7, Vector3(sx, 1.35, Z1), Build.mat(Color(0.24, 0.22, 0.2)))
	# ánh trăng lạnh rọi xuống sân
	for lp in [Vector3(-2.2, 3.5, -27.0), Vector3(2.2, 3.5, -27.0), Vector3(0, 3.0, -35.0), Vector3(0, 3.0, -41.0)]:
		var ml := OmniLight3D.new()
		ml.light_color = Color(0.5, 0.75, 1.0)
		ml.light_energy = 0.85
		ml.omni_range = 8.0
		ml.position = lp
		add_child(ml)
	# giếng đôi — giếng VUÔNG kiểu giếng cổ Bá Lễ (thành đá, khung gỗ đỡ kéo nước)
	for sx in [-2.2, 2.2]:
		var stone := Build.mat(Color(0.24, 0.24, 0.26), 0.95)
		for rot in range(4):
			var ang := rot * PI / 2.0
			var rim := Build.box(self, Vector3(1.5, 0.6, 0.18), Vector3(sx, 0.3, -27.0) + Vector3(cos(ang), 0, sin(ang)) * 0.66, stone)
			rim.rotation.y = -ang
		var water := Build.box(self, Vector3(1.15, 0.02, 1.15), Vector3(sx, 0.5, -27.0), null)
		var wmat := StandardMaterial3D.new()
		wmat.albedo_color = Color(0.02, 0.06, 0.08)
		wmat.metallic = 0.9
		wmat.roughness = 0.06
		water.material_override = wmat
		if sx > 0:
			_right_well_water = water
		# khung gỗ + đòn ngang treo gàu
		for px in [-0.8, 0.8]:
			Build.cyl(self, 0.05, 0.06, 2.1, Vector3(sx + px, 1.05, -27.0), Build.mat(Color(0.16, 0.11, 0.07)), 8)
		Build.cyl(self, 0.04, 0.04, 1.8, Vector3(sx, 2.05, -27.0), Build.mat(Color(0.16, 0.11, 0.07)), 8).rotation.z = PI / 2.0
	_well_reflection = ReflectionPool.new()
	add_child(_well_reflection)
	_well_reflection.setup(m.camera, 0.5, Vector2i(384, 384), 8)
	var refl_mat := StandardMaterial3D.new()
	refl_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	refl_mat.albedo_texture = _well_reflection.texture()
	refl_mat.emission_enabled = true
	refl_mat.emission_texture = _well_reflection.texture()
	refl_mat.emission_energy_multiplier = 0.9
	_right_well_water.material_override = refl_mat
	# ánh sáng dưới giếng phải — phố-còn-sáng-đèn lộn ngược
	var glow := Build.cyl(self, 0.66, 0.66, 0.02, Vector3(2.2, 0.56, -27.0), Build.emis(Color(1, 0.7, 0.4), Color(1.0, 0.55, 0.2), 0.7))
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# vũng tối giữa sân
	var pool := Build.box(self, Vector3(15.0, 0.06, POOL_Z0 - POOL_Z1), Vector3(0, -0.06, (POOL_Z0 + POOL_Z1) / 2.0), null)
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.004, 0.006, 0.012)
	pmat.metallic = 0.85
	pmat.roughness = 0.04
	pool.material_override = pmat
	# tấm ván cũ — sẽ biến mất
	_plank = Build.box(self, Vector3(0.9, 0.08, POOL_Z0 - POOL_Z1 + 1.0), Vector3(-3.5, 0.02, (POOL_Z0 + POOL_Z1) / 2.0), Build.mat(Color(0.2, 0.15, 0.1), 0.95))
	# phiến đá ẩn — chỉ hiện dưới ánh Thủy
	var tile_pos := [Vector3(1.2, 0, -33.6), Vector3(0.1, 0, -34.5), Vector3(1.0, 0, -35.4), Vector3(-0.2, 0, -36.2), Vector3(0.8, 0, -37.0)]
	for p in tile_pos:
		var t := Build.cyl(self, 0.55, 0.6, 0.1, p + Vector3(0, 0.0, 0), null, 8)
		var tm := StandardMaterial3D.new()
		tm.albedo_color = Color(0.4, 0.7, 0.9, 0.0)
		tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tm.emission_enabled = true
		tm.emission = Color(0.25, 0.55, 1.0)
		tm.emission_energy_multiplier = 0.0
		t.material_override = tm
		_tiles.append([t, p])

	# đứa trẻ — xuất hiện sau vòng lặp đầu, KHÔNG đổ bóng
	_child = Build.faceless_npc(self, Vector3(3.4, 0, -26.6), Color(0.5, 0.52, 0.55), 0.55, false)
	_child.rotation.y = -1.4
	_child.visible = false

	m.add_interact(Vector3(3.4, 0, -26.6), 2.0, "Nói chuyện với đứa trẻ", Callable(self, "_talk_child"), false)
	m.add_interact(Vector3(2.2, 0, -27.0), 1.7, "Nhìn xuống giếng", Callable(self, "_look_well"), false)
	m.add_interact(Vector3(2.2, 0, -27.8), 1.6, "Thả đóa sen xuống giếng", Callable(self, "_offer_lotus"), false)

	# hồn dân phố đã phai — đi mãi những vòng quen thuộc của ngày còn sống
	var w1 := GhostWalker.new()
	add_child(w1)
	w1.setup("res://assets/models/minh_rigged.glb", 1.7,
		[Vector3(-5.2, 0, -24.0), Vector3(-5.2, 0, -30.5), Vector3(-1.2, 0, -30.5), Vector3(-1.2, 0, -24.0)])
	var w2 := GhostWalker.new()
	add_child(w2)
	w2.speed = 0.4
	w2.setup("res://assets/models/minh_rigged.glb", 1.65,
		[Vector3(6.0, 0, -23.5), Vector3(6.0, 0, -41.5)])


func enter_beat() -> void:
	m.world.set_zone("c2")
	m.ui.set_objective("Băng qua sân giếng đôi")
	m.checkpoint = Vector3(0, 0, -22.0)
	m.say([
		["Minh (nghĩ)", "Sân giếng đôi. Hồi bé sư phụ cấm tôi ra đây sau giờ Dậu."],
		["Minh (nghĩ)", "Giờ thì... giờ nào cũng là sau giờ Dậu."],
	], func(): m.remote_voice(
		"c2_radio_bad_shortcut",
		0.24,
		[
			"Cứ đi thẳng qua cổng cuối sân. Đừng mất thời gian với đứa trẻ bên giếng.",
			["Minh (nghĩ)", "Lần này giọng nói gấp hơn. Như có ai đang giữ nút phát, sợ tôi kịp hỏi lại."],
		],
		Callable(),
		5
	))


var _child_talked := false
func _talk_child() -> void:
	if not _child.visible:
		return
	if not _child_talked:
		_child_talked = true
		m.say([
			["Đứa Trẻ Soi Giếng", "Anh ơi. Anh có thấy mặt em dưới đó không?"],
			["Minh", "Em... em là con nhà ai? Khuya rồi sao còn—"],
			["Đứa Trẻ Soi Giếng", "Em soi mãi mà không thấy mặt em đâu. Giếng này soi cái khác cơ."],
			["Đứa Trẻ Soi Giếng", "Anh thử đi. Nhưng anh đừng soi lâu. Soi lâu thì cái dưới đó nó soi lại mình."],
			["Minh (nghĩ)", "Đèn của tôi chiếu thẳng vào nó... mà dưới chân nó không có bóng."],
		], func(): m.ui.set_objective("Nhìn xuống giếng bên phải"))
	else:
		m.say([["Đứa Trẻ Soi Giếng", "Ở đây cái gì cũng ngược, anh ạ. Trăng dưới nước. Sông chảy lên. Muốn ra thì đi như người ở đây đi."]])


var _looked := false
func _look_well() -> void:
	if not _child_talked:
		m.say([["Minh (nghĩ)", "Nước giếng đen như mực mài. Có ánh gì le lói rất sâu... để sau. Đi tiếp cái đã."]])
		return
	if _looked:
		return
	_looked = true
	m.say([
		["Minh (nghĩ)", "Mặt nước theo chậm hơn một nhịp. Tôi nghiêng đầu — bóng dưới kia vẫn đứng yên."],
		["Minh (nghĩ)", "Một gợn sóng chạy qua. Chỗ lẽ ra là mặt tôi lại mở ra PHỐ — còn sáng đèn, nguyên vẹn, đông người... lộn ngược."],
		["Minh (nghĩ)", "Đáy giếng đang giữ cái phố mà tôi nhớ."],
		["Đứa Trẻ Soi Giếng", "Anh thấy chưa. Anh lấy một ít về đi — nước ở đây nhớ dai lắm."],
	], func(): m.remote_voice(
		"c2_well_contradiction",
		0.36,
		[
			"Rời giếng đi. Cái dưới nước chỉ nhại lại ký ức của cậu thôi.",
			["Minh (nghĩ)", "Không. Nó không nhại. Nó chậm hơn tôi — và chỗ đáng lẽ là mặt tôi lại là một con phố nguyên vẹn."],
		],
		Callable(self, "_confirm_well_contradiction"),
		-12,
		"well_reflection",
		"Well reflection lags behind the player and shows the intact inverted town instead of Minh's face."
	))


func _confirm_well_contradiction() -> void:
	m.narrative.record_contradiction(
		"c2_well_vs_radio_shortcut",
		"Trạm Bốn bảo bỏ qua giếng vì nó 'chỉ nhại ký ức', nhưng giếng cho thấy phố nguyên vẹn lộn ngược — chi tiết mà radio không thể biết nếu nó chỉ đang nhại lại trí nhớ của Minh."
	)
	_spawn_thuy()


func _spawn_thuy() -> void:
	_well_orb = Build.color_orb(self, Vector3(2.2, 1.3, -27.0), Color(0.25, 0.55, 1.0))
	m.add_interact(Vector3(2.2, 0, -27.2), 1.8, "Nhận SẮC THỦY", Callable(self, "_take_thuy"), true)


func _take_thuy() -> void:
	_well_orb.queue_free()
	m.player.unlock_color("thuy")
	m.ui.update_colors()
	has_thuy = true
	quest_stage = 1
	m.say([
		["Minh (nghĩ)", "Lạnh. Như cầm một vốc đáy sông trong lòng bàn tay."],
		["Đứa Trẻ Soi Giếng", "Ánh nước soi được những thứ giả vờ là không có. Cả đường đi cũng giả vờ được, anh biết không?"],
		["Minh", "Còn cái cổng? Làm sao qua được cái cổng gập?"],
		["Đứa Trẻ Soi Giếng", "Cổng chỉ mở cho người mang ĐÚNG THỨ nó chờ. Em không nhớ là thứ gì... nhưng bà hàng nước thì nhớ. Bà ấy múc nước giếng này cả một đời mà."],
	], func(): m.ui.set_objective("Quay ra phố — hỏi bà hàng nước về cánh cổng gập"))


# bà hàng nước kể sự tích giếng — gọi từ c1 khi quest_stage == 1
func ba_lore() -> void:
	quest_stage = 2
	m.say([
		["Bà Hàng Nước", "Cái cổng sau sân giếng hả... Cậu nhỏ hỏi đúng người rồi đấy."],
		["Bà Hàng Nước", "Giếng đó người Chăm đào, trước cả phố này. Nước ngọt quanh năm — nhưng xưa nay XIN NƯỚC PHẢI TRẢ LỄ. Một đóa sen giấy thả xuống lòng giếng, để nước biết mình không lấy không của đất."],
		["Bà Hàng Nước", "Hai mươi năm nay không ai trả lễ nữa. Nên cái sân ấy... nó giận. Nó gập đường lại, không cho ai đi qua mà tay không."],
		["Minh", "Sen giấy... giờ tìm đâu ra?"],
		["Bà Hàng Nước", "Gánh hoa đăng nhà con Tư còn bỏ ngoài phố kìa. Nó đi rồi, nhưng sen thì còn. Lấy một đóa — nó không trách đâu. Người bán hoa đăng chưa bao giờ trách người cần ánh sáng."],
	], func(): m.ui.set_objective("Lấy một đóa sen giấy ở gánh hoa đăng trên phố"))


func take_lotus() -> void:
	quest_stage = 3
	m.ui.toast("Nhận: ĐÓA SEN GIẤY")
	m.say([
		["Minh (nghĩ)", "Một đóa sen giấy hồng, giấy đã ngả màu nhưng nếp gấp vẫn sắc. Người gấp nó có đôi tay rất khéo."],
	], func(): m.ui.set_objective("Thả đóa sen xuống giếng phải — trả lễ cho nước"))


func _gate_loop_beat() -> void:
	loops += 1
	m.flash_black()
	m.player.position = Vector3(0, 0, -22.0)
	if loops == 1:
		_child.visible = true
		m.say([
			["Minh (nghĩ)", "...Tôi vừa đi thẳng qua cổng. Mà sao lại quay về chỗ cũ?"],
			["Minh (nghĩ)", "Có ai đó ở bên giếng. Lúc nãy sân này trống không mà."],
		])
	elif loops == 2:
		_plank.visible = false
		m.say([
			["Minh (nghĩ)", "Lại quay về. Cái cổng này gập lại như tờ giấy."],
			["Minh (nghĩ)", "...Tấm ván bắc qua vũng nước. Lúc nãy nó còn ở đó. LÚC NÃY NÓ CÒN Ở ĐÓ MÀ."],
		])
	else:
		m.say([["Minh (nghĩ)", "Lại quay về. Cái cổng này muốn một thứ gì đó... mà tôi chưa có."]])


# trả lễ: sen chạm nước — vệt sáng xanh chảy từ giếng ra cổng, dẫn đường qua vũng tối
func _offer_lotus() -> void:
	if quest_stage < 3:
		if quest_stage >= 1:
			m.say([["Minh (nghĩ)", "Giếng chờ một lễ vật. Tay tôi đang trống không."]])
		return
	if quest_stage >= 4:
		return
	quest_stage = 4
	m.ui.play_chime()
	# đóa sen nổi trên mặt giếng
	var lotus := Node3D.new()
	lotus.position = Vector3(2.2, 0.56, -27.0)
	add_child(lotus)
	Build.cyl(lotus, 0.07, 0.09, 0.06, Vector3.ZERO, Build.emis(Color(1.0, 0.8, 0.5), Color(1.0, 0.6, 0.25), 2.5), 8)
	for pk in range(6):
		var ang := TAU * pk / 6.0
		Build.ball(lotus, 0.06, 0.05, Vector3(cos(ang) * 0.1, 0.01, sin(ang) * 0.1), Build.mat(Color(0.85, 0.4, 0.5), 0.7))
	# vệt nước dẫn đường: giếng → phiến đá ẩn → cổng
	var path_pts := [Vector3(2.2, 0.04, -28.5), Vector3(1.6, 0.04, -31.0), Vector3(1.2, 0.04, -33.6),
		Vector3(0.1, 0.04, -34.5), Vector3(1.0, 0.04, -35.4), Vector3(-0.2, 0.04, -36.2),
		Vector3(0.8, 0.04, -37.0), Vector3(0.4, 0.04, -39.5), Vector3(0.0, 0.04, -42.0)]
	for pp in path_pts:
		var dot := Build.cyl(self, 0.16, 0.2, 0.025, pp, Build.emis(Color(0.5, 0.8, 1.0), Color(0.3, 0.65, 1.0), 2.0), 10)
		dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_trail.append(dot)
	m.say([
		["Minh (nghĩ)", "Đóa sen chạm nước — và lòng giếng SÁNG LÊN, như ai vừa thắp đèn dưới đó."],
		["Minh (nghĩ)", "Một vệt nước phát sáng tràn ra khỏi thành giếng... chảy NGƯỢC dốc, băng qua vũng tối, vẽ một con đường thẳng ra cổng."],
		["Đứa Trẻ Soi Giếng", "Nước nhớ anh rồi đó. Đi theo nó đi. Nhớ giữ ánh nước trên đèn — đường trên vũng tối chỉ chịu chân người mang Thủy."],
	], func(): m.ui.set_objective("Theo vệt nước ra cổng (giữ Sắc Thủy — phím 2 — khi qua vũng tối)"))


func update(delta: float) -> void:
	if _well_reflection != null:
		_well_reflection.update(delta)
	_time += delta
	_gate_cooldown = maxf(0.0, _gate_cooldown - delta)
	# phiến đá ẩn hiện dần dưới ánh Thủy
	var show: bool = m.player.current_color == "thuy"
	for pair in _tiles:
		var mt: StandardMaterial3D = pair[0].material_override
		var target := 0.55 if show else 0.0
		mt.albedo_color.a = lerpf(mt.albedo_color.a, target, 1.0 - pow(0.01, delta))
		mt.emission_energy_multiplier = lerpf(mt.emission_energy_multiplier, 1.4 if show else 0.0, 1.0 - pow(0.01, delta))
	# rơi xuống vũng tối
	var p: Vector3 = m.player.position
	if p.z < POOL_Z0 and p.z > POOL_Z1 and not passed:
		var safe := false
		if _plank.visible and absf(p.x + 3.5) < 0.55:
			safe = true
		if show:
			for pair in _tiles:
				var tp: Vector3 = pair[1]
				if Vector2(p.x - tp.x, p.z - tp.z).length() < 0.75:
					safe = true
					break
		if not safe:
			m.respawn(Vector3(0, 0, -31.5), "Lạnh thấu xương. Vũng nước này không có đáy — nó nhả tôi ra như nhả một hạt sạn.")
			return
	# cổng vòm: chưa trả lễ thì gập đường về chỗ cũ; trả lễ rồi thì mở
	if p.z < Z1 + 0.9 and _gate_cooldown <= 0.0 and not passed:
		if quest_stage >= 4:
			passed = true
			m.say([
				["Minh (nghĩ)", "Cánh cổng không động đậy — chỉ là con đường sau nó THẲNG ra. Như tờ giấy gập được vuốt phẳng."],
				["Minh (nghĩ)", "Xin thì phải trả. Phố này chưa từng quên phép tắc — chỉ có người là quên."],
			], func(): m.goto_chapter(3))
		else:
			_gate_cooldown = 1.0
			_gate_loop_beat()
	# đứa trẻ lắc lư rất chậm — hơi sai nhịp người thật
	if _child.visible:
		_child.rotation.z = sin(_time * 0.7) * 0.06


func clamp_player(pos: Vector3) -> Vector3:
	# nhiệm vụ "hỏi bà hàng nước" + "lấy sen ở gánh hoa đăng" đòi đi bộ thật ngược lên
	# khu C1 (Bà ở z=-5.5, gánh hoa đăng ở z=12.8) — ngoài dải sân giếng của C2.
	# Ra khỏi miệng sân thì dùng lại clamp phố của C1 cho đoạn đường quay lại đó.
	if pos.z > Z0 + 0.4:
		# dùng nguyên clamp của C1 (không chỉ world.clamp_alley) để còn quay lại
		# ĐƯỢC vào trong nhà khóa qua cửa trước — chỗ có giếng khô xuống lại C2.
		return m.chapters[1].clamp_player(pos)
	pos.x = clampf(pos.x, -7.4, 7.4)
	pos.z = clampf(pos.z, Z1 + 0.3, Z0 + 0.4)
	return pos
