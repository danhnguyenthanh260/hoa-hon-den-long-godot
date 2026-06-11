# CHƯƠNG HAI — GIẾNG ĐÔI (Thủy)
# Sân giếng lặp như giấc mơ: cổng cuối sân gập về điểm xuất phát. Đứa trẻ không bóng.
# Sắc Thủy hiện đường đá ẩn trên vũng tối. Thoát bằng cách đi GIẬT LÙI qua cổng (Shift).
extends Node3D

const Build := preload("res://scripts/build.gd")

const Z0 := -20.6
const Z1 := -43.6
const POOL_Z0 := -33.0
const POOL_Z1 := -37.5

var m
var loops := 0
var has_thuy := false
var _child: Node3D
var _plank: MeshInstance3D
var _tiles: Array = []   # [mesh, Vector3]
var _well_orb: Node3D
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
		# khung gỗ + đòn ngang treo gàu
		for px in [-0.8, 0.8]:
			Build.cyl(self, 0.05, 0.06, 2.1, Vector3(sx + px, 1.05, -27.0), Build.mat(Color(0.16, 0.11, 0.07)), 8)
		Build.cyl(self, 0.04, 0.04, 1.8, Vector3(sx, 2.05, -27.0), Build.mat(Color(0.16, 0.11, 0.07)), 8).rotation.z = PI / 2.0
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


func enter_beat() -> void:
	m.world.set_zone("c2")
	m.ui.set_objective("Băng qua sân giếng đôi")
	m.checkpoint = Vector3(0, 0, -22.0)
	m.say([
		["Minh (nghĩ)", "Sân giếng đôi. Hồi bé sư phụ cấm tôi ra đây sau giờ Dậu."],
		["Minh (nghĩ)", "Giờ thì... giờ nào cũng là sau giờ Dậu."],
	])


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
		["Minh (nghĩ)", "Dưới nước không có mặt tôi."],
		["Minh (nghĩ)", "Dưới nước là PHỐ. Phố hội còn sáng đèn, nguyên vẹn, đông người... lộn ngược."],
		["Minh (nghĩ)", "Đáy giếng đang giữ cái phố mà tôi nhớ."],
		["Đứa Trẻ Soi Giếng", "Anh thấy chưa. Anh lấy một ít về đi — nước ở đây nhớ dai lắm."],
	], func(): _spawn_thuy())


func _spawn_thuy() -> void:
	_well_orb = Build.color_orb(self, Vector3(2.2, 1.3, -27.0), Color(0.25, 0.55, 1.0))
	m.add_interact(Vector3(2.2, 0, -27.2), 1.8, "Nhận SẮC THỦY", Callable(self, "_take_thuy"), true)


func _take_thuy() -> void:
	_well_orb.queue_free()
	m.player.unlock_color("thuy")
	m.ui.update_colors()
	has_thuy = true
	m.say([
		["Minh (nghĩ)", "Lạnh. Như cầm một vốc đáy sông trong lòng bàn tay."],
		["Đứa Trẻ Soi Giếng", "Ánh nước soi được những thứ giả vờ là không có. Cả đường đi cũng giả vờ được, anh biết không?"],
	], func(): m.ui.set_objective("SẮC THỦY (phím 2): tìm đường qua vũng tối — rồi qua cổng vòm theo cách của nơi này (giữ Shift đi lùi)"))


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
		m.say([["Minh (nghĩ)", "Đi tới là vô vọng rồi. 'Đi như người ở đây đi'... Ở đây cái gì cũng ngược."]])


func update(delta: float) -> void:
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
	# cổng vòm: đi tới = lặp; đi GIẬT LÙI (Shift) = thoát
	if p.z < Z1 + 0.9 and _gate_cooldown <= 0.0 and not passed:
		var backward: bool = Input.is_key_pressed(KEY_SHIFT) and m.player.move_dir.z < 0.0
		if backward and loops >= 1 and has_thuy:
			passed = true
			m.say([
				["Minh (nghĩ)", "Sư phụ từng nói: trong mơ, muốn về thì đừng chạy về phía cửa."],
				["Minh (nghĩ)", "Hóa ra... thầy không nói về giấc mơ."],
			], func(): m.goto_chapter(3))
		else:
			_gate_cooldown = 1.0
			_gate_loop_beat()
	# đứa trẻ lắc lư rất chậm — hơi sai nhịp người thật
	if _child.visible:
		_child.rotation.z = sin(_time * 0.7) * 0.06


func clamp_player(pos: Vector3) -> Vector3:
	pos.x = clampf(pos.x, -7.4, 7.4)
	pos.z = clampf(pos.z, Z1 + 0.3, Z0 + 0.4)
	return pos
