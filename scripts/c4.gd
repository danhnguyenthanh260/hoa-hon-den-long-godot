# CHƯƠNG BỐN — BẾN SÔNG NGƯỢC (Kim · Thổ)
# Trăng nằm dưới đáy sông, hoa đăng trôi ngược. Gương đồng dẫn tia trăng đến chuông (Kim).
# Đầm bùn cứng lại dưới ánh vàng (Thổ). Người chèo đò đòi trả phí bằng một ký ức.
extends Node3D

const Build := preload("res://scripts/build.gd")

const BANK_Z0 := -45.0
const RIVER_Z := -58.0

var m
var bell1_rung := false
var bell2_rung := false
var has_tho := false
var _bell1_pos := Vector3(-4.8, 1.3, -54.0)
var _bell2_pos := Vector3(-4.5, 0, -57.2)
var _pads: Array = []           # [mesh, pos, hard_t]
var _boatman: Node3D
var _hoa_dang: Array = []
var _kim_orb: Node3D
var _tho_orb: Node3D
var _time := 0.0
var _moon_l: OmniLight3D
var _hoa_speed := 1.0
var _giai_oan_done := false
var _mound_done := false      # đắp mộ bằng Sắc Thổ
var _name_carved := false     # khắc tên bằng Sắc Kim
var _will_o_wisps: Array = []   # [node, base_pos, phase]


func _take_tho() -> void:
	_tho_orb.queue_free()
	m.player.unlock_color("tho")
	m.ui.update_colors()
	has_tho = true
	m.say([["Minh (nghĩ)", "Nặng và ấm, như nắm đất đầu mùa. Đất thì không biết nói dối — chắc vậy mà người ta thề với đất."]],
		func(): m.ui.set_objective("Sang bãi bên kia đầm, đánh quả chuông thứ hai (bấm E)"))


func _take_kim() -> void:
	_kim_orb.queue_free()
	m.player.unlock_color("kim")
	m.ui.update_colors()
	m.say([["Minh (nghĩ)", "Ánh trăng đặc lại như giọt thủy ngân. Sáng — và sắc. Sắc như một lời hứa bị bẻ đôi."]])


func build(main) -> void:
	m = main
	# bãi bến + sông
	var ground := Build.box(self, Vector3(16, 0.2, RIVER_Z - (-78.0)), Vector3(0, -0.1, (BANK_Z0 - 35.0)), Build.pbr("res://assets/textures/Ground068", 0.5, Color(0.55, 0.46, 0.4), 1.4))
	ground.position = Vector3(0, -0.1, -51.5)
	var water := Build.box(self, Vector3(16, 0.1, 18), Vector3(0, -0.04, -67.0), null)
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(0.015, 0.03, 0.05)
	wmat.metallic = 0.9
	wmat.roughness = 0.05
	water.material_override = wmat
	# TRĂNG DƯỚI ĐÁY SÔNG
	var moon := Build.cyl(self, 2.6, 2.6, 0.02, Vector3(0, 0.03, -66.0), Build.emis(Color(0.9, 0.93, 1.0), Color(0.85, 0.9, 1.0), 2.2))
	moon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_moon_l = OmniLight3D.new()
	_moon_l.light_color = Color(0.7, 0.8, 1.0)
	_moon_l.light_energy = 1.2
	_moon_l.omni_range = 14.0
	_moon_l.position = Vector3(0, 1.0, -66.0)
	add_child(_moon_l)
	# hoa đăng trôi NGƯỢC dòng
	for i in range(10):
		var hd := Node3D.new()
		hd.position = Vector3(-6.0 + fmod(i * 2.3, 12.0), 0.06, -76.0 + fmod(i * 3.1, 16.0))
		add_child(hd)
		Build.cyl(hd, 0.09, 0.11, 0.09, Vector3(0, 0.05, 0), Build.emis(Color(1.0, 0.8, 0.5), Color(1.0, 0.62, 0.22), 3.0))
		for p in range(6):
			var ang := TAU * p / 6.0
			Build.ball(hd, 0.085, 0.07, Vector3(cos(ang) * 0.13, 0.02, sin(ang) * 0.13), Build.emis(Color(0.9, 0.45, 0.55), Color(0.9, 0.35, 0.4), 0.5, 0.7))
		_hoa_dang.append(hd)
	# nguồn tia trăng: trụ đá + mảnh trăng vỡ
	Build.box(self, Vector3(0.7, 2.4, 0.7), Vector3(6.2, 1.2, -50.0), Build.mat(Color(0.25, 0.25, 0.28)))
	Build.ball(self, 0.22, 0.4, Vector3(6.2, 2.0, -50.0), Build.emis(Color(0.9, 0.93, 1.0), Color(0.85, 0.9, 1.0), 3.0))
	# chuông 1 — treo trên giá, đánh trực tiếp (đã bỏ đố gương)
	Build.box(self, Vector3(1.4, 0.12, 0.3), _bell1_pos + Vector3(0, 0.9, 0), Build.mat(Color(0.13, 0.09, 0.06)))
	for sx in [-0.6, 0.6]:
		Build.box(self, Vector3(0.12, 2.1, 0.3), Vector3(_bell1_pos.x + sx, 1.05, _bell1_pos.z), Build.mat(Color(0.13, 0.09, 0.06)))
	Build.cyl(self, 0.28, 0.4, 0.55, _bell1_pos, Build.mat(Color(0.55, 0.42, 0.2), 0.35), 12)
	m.add_interact(_bell1_pos, 1.8, "Đánh chuông trăng", Callable(self, "_ring_bell1"), false)
	# đầm bùn + phiến
	var mud := Build.box(self, Vector3(6.5, 0.04, 7.0), Vector3(-3.2, -0.02, -52.8), Build.mat(Color(0.08, 0.06, 0.05), 1.0))
	mud.material_override.metallic = 0.3
	mud.material_override.roughness = 0.55
	var pad_pos := [Vector3(-1.4, 0, -50.8), Vector3(-2.8, 0, -51.9), Vector3(-1.8, 0, -53.2), Vector3(-3.4, 0, -54.3), Vector3(-2.4, 0, -55.6), Vector3(-3.8, 0, -56.4)]
	for p in pad_pos:
		var pad := Build.cyl(self, 0.62, 0.68, 0.12, p + Vector3(0, 0.04, 0), Build.emis(Color(0.35, 0.28, 0.18), Color(1.0, 0.78, 0.2), 0.0, 0.9), 8)
		_pads.append([pad, p, 0.0])
	# Sắc Thổ bên mép đầm
	_tho_orb = Build.color_orb(self, Vector3(0.4, 0.9, -50.4), Color(1.0, 0.78, 0.2))
	m.add_interact(Vector3(0.4, 0, -50.4), 1.8, "Nhận SẮC THỔ", Callable(self, "_take_tho"), true)
	# chuông 2 bên kia đầm
	Build.cyl(self, 0.3, 0.42, 0.6, _bell2_pos + Vector3(0, 1.3, 0), Build.mat(Color(0.55, 0.42, 0.2), 0.35), 12)
	for sx in [-0.6, 0.6]:
		Build.box(self, Vector3(0.12, 2.2, 0.3), _bell2_pos + Vector3(sx, 1.1, 0), Build.mat(Color(0.13, 0.09, 0.06)))
	Build.box(self, Vector3(1.4, 0.12, 0.3), _bell2_pos + Vector3(0, 2.1, 0), Build.mat(Color(0.13, 0.09, 0.06)))
	m.add_interact(_bell2_pos, 1.6, "Đánh chuông bến", Callable(self, "_ring_bell2"), false)
	# đò + người chèo đò
	var boat := Node3D.new()
	boat.position = Vector3(2.5, 0.05, -59.2)
	add_child(boat)
	Build.box(boat, Vector3(1.4, 0.3, 3.6), Vector3(0, 0.15, 0), Build.mat(Color(0.16, 0.11, 0.07), 0.85))
	Build.box(boat, Vector3(1.2, 0.08, 0.5), Vector3(0, 0.34, 0.8), Build.mat(Color(0.2, 0.14, 0.09)))
	_boatman = Build.faceless_npc(boat, Vector3(0, 0.3, -1.2), Color(0.12, 0.12, 0.14))
	Build.cyl(_boatman, 0.025, 0.025, 2.6, Vector3(0.35, 1.0, 0.3), Build.mat(Color(0.4, 0.32, 0.18)))
	m.add_interact(Vector3(2.5, 0, -58.6), 2.4, "Người chèo đò", Callable(self, "_talk_boatman"), false)
	# ma trơi trên sông — 6 đốm hồn lang thang
	for i in range(6):
		var wnode := Node3D.new()
		var wx := -5.5 + fmod(i * 2.1, 11.0)
		var wz := -62.0 + fmod(i * 3.7, 12.0)
		wnode.position = Vector3(wx, 0.3 + fmod(i * 0.8, 0.6), wz)
		add_child(wnode)
		Build.ball(wnode, 0.06, 0.12, Vector3.ZERO, Build.emis(Color(0.6, 0.9, 1.0), Color(0.4, 0.8, 1.0), 3.5, 0.5))
		var wl := OmniLight3D.new()
		wl.light_color = Color(0.5, 0.85, 1.0)
		wl.light_energy = 0.5
		wl.omni_range = 2.5
		wnode.add_child(wl)
		_will_o_wisps.append([wnode, wnode.position, i * 1.13])
	# mộ gió đắp dở bên mép bến (Minh đang nặn cho người chèo đò khi bị cuốn đi)
	var mg_pos := Vector3(-5.8, 0, -47.2)
	Build.cyl(self, 0.45, 0.55, 0.22, mg_pos + Vector3(0, 0.11, 0), Build.mat(Color(0.12, 0.09, 0.07), 0.95), 12)
	var effigy := Node3D.new()
	effigy.position = mg_pos + Vector3(0.1, 0.22, 0)
	add_child(effigy)
	Build.cyl(effigy, 0.025, 0.02, 0.28, Vector3(0, 0.14, 0), Build.mat(Color(0.38, 0.3, 0.18), 0.9), 5)
	Build.ball(effigy, 0.055, 0.1, Vector3(0.02, 0.32, 0), Build.mat(Color(0.42, 0.34, 0.2), 0.9))
	Build.box(effigy, Vector3(0.18, 0.04, 0.04), Vector3(0, 0.24, 0), Build.mat(Color(0.38, 0.3, 0.18), 0.9))
	m.add_interact(mg_pos, 1.8, "Mộ gió đắp dở", Callable(self, "_work_mo_gio"), false)


func enter_beat() -> void:
	m.world.set_zone("c4")
	m.world.set_moon_visible(false)
	m.checkpoint = Vector3(0, 0, -46.0)
	m.ui.set_objective("Bến sông Hoài — tìm đường qua sông")
	m.say([
		["Minh (nghĩ)", "Sông Hoài chảy ngược, hoa đăng trôi về thượng nguồn. Trăng nằm DƯỚI đáy sông."],
		["Minh (nghĩ)", "Ma trơi đầy sông — mỗi đốm một hồn chưa ai lập mộ gió cho."],
	])


func _ring_bell1() -> void:
	if bell1_rung:
		return
	bell1_rung = true
	m.ui.play_chime()
	m.ui.toast("Quả chuông thứ nhất ngân — ánh trăng đọng lại thành SẮC KIM")
	_kim_orb = Build.color_orb(self, _bell1_pos + Vector3(0, -0.6, 0.8), Color(1.0, 0.96, 0.82))
	m.add_interact(Vector3(_bell1_pos.x, 0, _bell1_pos.z + 0.8), 1.8, "Nhận SẮC KIM", Callable(self, "_take_kim"), true)
	if bell2_rung:
		m.ui.set_objective("Quay lại chỗ người chèo đò")


func _after_giai_oan() -> void:
	_giai_oan_done = true
	# đảm bảo có Kim & Thổ để đắp mộ gió (cấp ngầm nếu lỡ chưa nhặt)
	var _keep = m.player.current_color
	for c in ["tho", "kim"]:
		if not m.player.has_color(c):
			m.player.unlock_color(c)
	if _keep != "":
		m.player.set_color(_keep)
	m.ui.update_colors()
	m.ui.set_objective("Đắp mộ gió cho người chèo đò: đổi Sắc THỔ (5) đắp đất, rồi Sắc KIM (4) khắc tên — tới mộ gió bấm E")


func _work_mo_gio() -> void:
	# mộ gió: Thổ đắp nấm đất, Kim khắc tên lên bài vị — hai công dụng rõ của Sắc 4 & 5
	if not _giai_oan_done:
		m.say([["Minh (nghĩ)", "Hình nhân tôi nặn dở cho người chèo đò. Thắp chuông, nghe ông kể xong đã, rồi mới đắp mộ được."]])
		return
	if not _mound_done:
		if m.player.current_color != "tho":
			m.ui.toast("Nấm mộ còn dở. Đổi sang Sắc THỔ (phím 5) để đắp đất cho tròn.")
			return
		_mound_done = true
		m.say([["Minh (nghĩ)", "Ánh vàng của Thổ tụ đất lại — nấm mộ gió tròn đầy dưới tay tôi."]],
			func(): m.ui.set_objective("Giờ khắc tên lên bài vị: đổi Sắc KIM (phím 4), tới mộ gió bấm E"))
		return
	if not _name_carved:
		if m.player.current_color != "kim":
			m.ui.toast("Bài vị còn trống. Đổi sang Sắc KIM (phím 4) để khắc tên.")
			return
		_name_carved = true
		m.say([
			["Minh (nghĩ)", "Ánh Kim sắc như mũi dao. Tôi khắc lên bài vị cái tên người chèo đò — cuối cùng cũng có người nhớ."],
		], func(): m.ui.set_objective("Mộ gió đã xong — quay lại người chèo đò"))
		return
	m.say([["Minh (nghĩ)", "Mộ gió đã tròn, bài vị đã có tên. Ông ấy yên rồi."]])


var _boatman_met := false
func _talk_boatman() -> void:
	if bell1_rung and bell2_rung and not _giai_oan_done:
		m.say([
			["Người Chèo Đò", "Hai chuông cùng tỉnh. Nước thuận rồi. ...Thầy đứng nghe được không?"],
			["Người Chèo Đò", "Đêm lụt, ta chở sáu bảy chuyến người chạy lụt. Chuyến cuối lật đò giữa dòng — ta không bơi được. Ta chết oan mà mấy chục năm không ai chịu nghe."],
			["Người Chèo Đò", "*(gác chèo)* ...Nhẹ cả người. Mấy chục năm mới có người nghe ta kể hết."],
		], Callable(self, "_after_giai_oan"))
	elif bell1_rung and bell2_rung and _giai_oan_done and not _name_carved:
		m.say([["Người Chèo Đò", "Đắp xong mộ gió cho ta đã, thầy — đắp đất, khắc tên. Xong rồi ta mới yên lòng mà chở."]])
	elif bell1_rung and bell2_rung and _giai_oan_done and _name_carved:
		m.say([
			["Người Chèo Đò", "Thầy đắp mộ cho ta rồi. Giờ tới lượt thầy — trả ta một ký ức để qua sông."],
			["Người Chèo Đò", "Trả gương mặt mẹ thì thầy còn tên để người khác gọi về. Trả tên mình thì giữ được mặt mẹ — nhưng có thể chẳng còn đường về."],
		], Callable(self, "_prepare_choice_cinematic"))
	elif not _boatman_met:
		_boatman_met = true
		m.say([
			["Người Chèo Đò", "Qua sông không, thầy? Ta chở ai thì biết người đó — biết cả cái sào đèn của thầy. Nhưng sông đêm nay chảy ngược, ta chèo không lại."],
			["Người Chèo Đò", "Đêm nước lên ta chở người chạy lụt, lật đò giữa dòng. Ta chết oan mà chưa ai chịu nghe ta kể."],
			["Người Chèo Đò", "Thắp giùm ta hai quả chuông bến — một quả ưa ánh trăng, một quả ưa tiếng người."],
		], func(): m.ui.set_objective("Thắp 2 quả chuông bến trên bãi sông (tới gần, bấm E)"))
	else:
		m.say([["Người Chèo Đò", "Chuông chưa tỉnh hết. Ta vẫn nghe sông chảy lên đấy, thầy."]])


func _dolly_to_boatman(p: Vector3) -> void:
	m.camera.global_position = p
	m.camera.look_at(_boatman.global_position + Vector3(0, 1.0, 0))


func _prepare_choice_cinematic() -> void:
	m.free_cam = true
	m.audio.sting()
	var start := _boatman.global_position + Vector3(1.6, 1.9, 4.0)
	var dst := _boatman.global_position + Vector3(0.6, 1.4, 2.0)
	_dolly_to_boatman(start)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(Callable(self, "_dolly_to_boatman"), start, dst, 2.5)
	tw.tween_interval(0.5)
	tw.tween_callback(Callable(self, "_show_crossing_choice"))


func _show_crossing_choice() -> void:
	m.say([
		{"choice_id": "c4_crossing_price", "choice": [
			["Trả gương mặt của mẹ — giữ tên", [
				["Người Chèo Đò", "Thầy giữ cái tên — người giữ tên là người còn đường về."],
				["Người Chèo Đò", "...Mà lần trước qua sông, thầy cũng chọn y như vậy đấy."],
				["Minh", "...Lần trước?"],
			]],
			["Trả tên của chính mình — giữ mặt mẹ", [
				["Người Chèo Đò", "Thầy đưa ta cái tên. Người bỏ tên là người không định về nữa."],
				["Người Chèo Đò", "Khách bỏ tên... thường là khách bỏ từ lâu rồi, chỉ chưa biết thôi."],
			]],
		]},
	], Callable(self, "_begin_crossing_cinematic"))


func _begin_crossing_cinematic() -> void:
	m.say([
		["Minh (nghĩ)", "Đò trôi vào sương. Hai bên bờ, phố trôi NGƯỢC qua như cuộn phim tua lui — đèn tắt dần, người thưa dần, rồi không còn gì."],
	], Callable(self, "_on_c4_choice_done"))
	create_tween().tween_property(_moon_l, "light_energy", 0.05, 4.0)
	_hoa_speed = 2.4
	var start: Vector3 = m.camera.global_position
	var dst: Vector3 = start + Vector3(1.0, 0.5, 3.0)
	var tw := create_tween()
	tw.tween_method(Callable(self, "_dolly_to_boatman"), start, dst, 5.0)


func _on_c4_choice_done() -> void:
	# chốt an toàn: C5 cần Hỏa/Thủy/Thổ để soi 3 chứng cứ. Không còn cổng ép lấy Thổ nữa,
	# nên cấp ngầm màu nào lỡ bỏ qua (giữ nguyên màu đang cầm).
	var _keep = m.player.current_color
	for c in ["hoa", "thuy", "tho"]:
		if not m.player.has_color(c):
			m.player.unlock_color(c)
	if _keep != "":
		m.player.set_color(_keep)
	m.ui.update_colors()
	_hoa_speed = 5.0
	if m.narrative.name_kept == true:
		m.ui.toast("Bóng hình thân thuộc mờ dần trong tâm trí...")
	else:
		m.ui.toast("Một phần ký ức bị lấy đi... Nhẹ bẫng.")
	var tw = create_tween()
	tw.tween_interval(1.0)
	tw.tween_callback(func(): m.audio.sting())
	tw.tween_interval(1.4)
	tw.tween_callback(func():
		m.free_cam = false
		m.goto_chapter(5)
	)


func _ring_bell2() -> void:
	if bell2_rung or not _reached_bell2():
		return
	bell2_rung = true
	m.ui.play_chime()
	m.ui.toast("Quả chuông thứ hai ngân — mặt sông phẳng lại một nửa")
	if bell1_rung:
		m.ui.set_objective("Quay lại chỗ người chèo đò")


func _reached_bell2() -> bool:
	return m.player.position.distance_to(Vector3(_bell2_pos.x, 0, _bell2_pos.z)) < 1.8


func update(delta: float) -> void:
	_time += delta
	# ma trơi lơ lửng trên sông
	for trio in _will_o_wisps:
		var wnode: Node3D = trio[0]
		var base: Vector3 = trio[1]
		var ph: float = trio[2] + _time * 0.3
		wnode.position = base + Vector3(sin(ph * 0.7) * 0.5, sin(ph * 1.1) * 0.25, cos(ph * 0.6) * 0.5)
	# hoa đăng trôi ngược (+z là ngược về thượng nguồn ở đây)
	for hd in _hoa_dang:
		hd.position.z += delta * 0.35 * _hoa_speed
		hd.position.y = 0.06 + sin(_time * 1.2 + hd.position.x) * 0.02
		if hd.position.z > -59.0:
			hd.position.z = -76.0
	# phiến bùn sáng lên dưới ánh Thổ — chỉ còn hiệu ứng, không còn sa lầy chết
	for pad in _pads:
		if has_tho and m.player.current_color == "tho" and m.player.position.distance_to(Vector3(pad[1].x, 0, pad[1].z)) < 3.5:
			pad[2] = 2.6
		pad[2] = maxf(0.0, pad[2] - delta)
		var mt: StandardMaterial3D = pad[0].material_override
		mt.emission_energy_multiplier = lerpf(mt.emission_energy_multiplier, 1.5 if pad[2] > 0.0 else 0.0, 1.0 - pow(0.01, delta))


func clamp_player(pos: Vector3) -> Vector3:
	pos.x = clampf(pos.x, -7.4, 7.4)
	pos.z = clampf(pos.z, RIVER_Z + 0.6, BANK_Z0 + 0.5)
	return pos
