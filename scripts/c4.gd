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
var _mirrors: Array = []        # [node, angle]
var _beam_segs: Array = []
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


func _take_tho() -> void:
	_tho_orb.queue_free()
	m.player.unlock_color("tho")
	m.ui.update_colors()
	has_tho = true
	m.say([["Minh (nghĩ)", "Nặng và ấm, như nắm đất đầu mùa. Đất thì không biết nói dối — chắc vậy mà người ta thề với đất."]],
		func(): m.ui.set_objective("SẮC THỔ (phím 5): làm cứng phiến bùn, băng đầm đến quả chuông thứ hai"))


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
	# ba gương đồng xoay được
	for i in range(3):
		var pos: Vector3 = [Vector3(1.8, 0, -50.0), Vector3(1.8, 0, -54.0), Vector3(-1.5, 0, -51.2)][i]
		var node := Node3D.new()
		node.position = pos
		add_child(node)
		Build.cyl(node, 0.07, 0.09, 1.3, Vector3(0, 0.65, 0), Build.mat(Color(0.12, 0.09, 0.06)))
		var disc := Build.cyl(node, 0.55, 0.55, 0.06, Vector3(0, 1.45, 0), null, 18)
		var mmat := StandardMaterial3D.new()
		mmat.albedo_color = Color(0.85, 0.65, 0.3)
		mmat.metallic = 0.95
		mmat.roughness = 0.12
		disc.material_override = mmat
		disc.rotation.x = PI / 2.0
		_mirrors.append([node, 0.6 + i * 0.8])
		node.rotation.y = _mirrors[i][1]
		m.add_interact(pos, 2.0, "Gương đồng (A / D xoay khi đứng gần)", Callable(self, "_noop"), false)
	# chuông 1 (treo trên giá)
	Build.box(self, Vector3(1.4, 0.12, 0.3), _bell1_pos + Vector3(0, 0.9, 0), Build.mat(Color(0.13, 0.09, 0.06)))
	for sx in [-0.6, 0.6]:
		Build.box(self, Vector3(0.12, 2.1, 0.3), Vector3(_bell1_pos.x + sx, 1.05, _bell1_pos.z), Build.mat(Color(0.13, 0.09, 0.06)))
	Build.cyl(self, 0.28, 0.4, 0.55, _bell1_pos, Build.mat(Color(0.55, 0.42, 0.2), 0.35), 12)
	# tia sáng (pool các đoạn)
	for i in range(4):
		var seg := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.025
		cm.bottom_radius = 0.025
		cm.height = 1.0
		seg.mesh = cm
		seg.material_override = Build.emis(Color(1, 1, 1), Color(0.9, 0.95, 1.0), 4.0)
		seg.visible = false
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(seg)
		_beam_segs.append(seg)
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


func enter_beat() -> void:
	m.world.set_zone("c4")
	m.world.set_moon_visible(false)
	m.checkpoint = Vector3(0, 0, -46.0)
	m.ui.set_objective("Bến sông Hoài — tìm đường qua sông")
	m.say([
		["Minh (nghĩ)", "Sông Hoài. Nhưng nước đang chảy... ngược. Hoa đăng trôi về thượng nguồn như đàn cá về tổ."],
		["Minh (nghĩ)", "Và trăng — trăng nằm DƯỚI đáy sông. Trên trời chỉ còn một lỗ tròn đen ngòm, như ai khoét đi."],
	])


func _noop() -> void:
	pass


var _boatman_met := false
func _talk_boatman() -> void:
	if bell1_rung and bell2_rung:
		m.say([
			["Người Chèo Đò", "Hai chuông cùng tỉnh. Nước thuận rồi đó, cậu giữ đèn."],
			["Người Chèo Đò", "Khách qua sông thì trả tiền đò. Nhưng tiền của cậu, ta không tiêu được. Cậu trả ta một ký ức nhé."],
			["Người Chèo Đò", "Nếu trả gương mặt mẹ, cậu còn tên để người khác gọi về. Nếu trả tên mình, cậu giữ được mặt mẹ — nhưng có thể chẳng còn đường về."],
			["Người Chèo Đò", "Ta nói trước giá rồi. Chọn thứ cậu chấp nhận để lại bên sông."],
		], Callable(self, "_prepare_choice_cinematic"))
	elif not _boatman_met:
		_boatman_met = true
		m.say([
			["Người Chèo Đò", "Qua sông không, cậu giữ đèn?"],
			["Minh", "Ông biết tôi?"],
			["Người Chèo Đò", "Ta chở ai thì biết người đó. Có điều sông đêm nay chảy ngược, ta chèo không lại."],
			["Người Chèo Đò", "Cậu thắp giùm ta hai quả chuông bến — chuông tỉnh thì nước thuận. Một quả chuông ưa ánh trăng, một quả ưa tiếng người."],
		], func(): m.ui.set_objective("Thắp 2 chuông bến: dẫn tia trăng qua gương đồng · băng đầm bùn đánh chuông"))
	else:
		m.say([["Người Chèo Đò", "Chuông chưa tỉnh hết. Ta vẫn nghe sông chảy lên đấy, cậu giữ đèn."]])


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
				["Người Chèo Đò", "Cậu giữ cái tên. Người giữ tên là người còn muốn được gọi."],
				["Người Chèo Đò", "...Mà cậu giữ đèn này. Lần trước qua sông, cậu cũng chọn y như vậy đấy."],
				["Minh", "...Lần trước?"],
				["Người Chèo Đò", "Lên đò đi."],
			]],
			["Trả tên của chính mình — giữ mặt mẹ", [
				["Người Chèo Đò", "Cậu giữ gương mặt mẹ. Người bỏ tên là người không định quay về."],
				["Người Chèo Đò", "Lạ thật. Khách bỏ tên... thường là khách đã bỏ từ lâu rồi. Chỉ chưa biết thôi."],
				["Người Chèo Đò", "Lên đò đi."],
			]],
		]},
	], Callable(self, "_begin_crossing_cinematic"))


func _begin_crossing_cinematic() -> void:
	m.say([
		["Minh (nghĩ)", "Đò trôi vào sương. Hai bên bờ, phố trôi NGƯỢC qua như cuộn phim tua lui — đèn tắt dần, người thưa dần, rồi không còn gì."],
	], Callable(self, "_on_c4_choice_done"))
	create_tween().tween_property(_moon_l, "light_energy", 0.05, 4.0)
	_hoa_speed = 2.4
	var start := m.camera.global_position
	var dst := start + Vector3(1.0, 0.5, 3.0)
	var tw := create_tween()
	tw.tween_method(Callable(self, "_dolly_to_boatman"), start, dst, 5.0)


func _on_c4_choice_done() -> void:
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
	# hoa đăng trôi ngược (+z là ngược về thượng nguồn ở đây)
	for hd in _hoa_dang:
		hd.position.z += delta * 0.35 * _hoa_speed
		hd.position.y = 0.06 + sin(_time * 1.2 + hd.position.x) * 0.02
		if hd.position.z > -59.0:
			hd.position.z = -76.0
	# xoay gương khi đứng gần
	for pair in _mirrors:
		var node: Node3D = pair[0]
		if m.player.position.distance_to(Vector3(node.position.x, 0, node.position.z)) < 2.0 and m.is_play():
			if Input.is_key_pressed(KEY_A):
				pair[1] += 0.9 * delta
			if Input.is_key_pressed(KEY_D):
				pair[1] -= 0.9 * delta
			node.rotation.y = pair[1]
	_update_beam()
	# phiến bùn cứng dưới ánh Thổ
	var p: Vector3 = m.player.position
	for pad in _pads:
		if has_tho and m.player.current_color == "tho" and p.distance_to(Vector3(pad[1].x, 0, pad[1].z)) < 3.5:
			pad[2] = 2.6
		pad[2] = maxf(0.0, pad[2] - delta)
		var mt: StandardMaterial3D = pad[0].material_override
		mt.emission_energy_multiplier = lerpf(mt.emission_energy_multiplier, 1.5 if pad[2] > 0.0 else 0.0, 1.0 - pow(0.01, delta))
	# sa lầy
	if p.x > -6.4 and p.x < -0.2 and p.z < -49.5 and p.z > -56.2:
		var safe := false
		for pad in _pads:
			if pad[2] > 0.0 and Vector2(p.x - pad[1].x, p.z - pad[1].z).length() < 0.8:
				safe = true
				break
		if not safe:
			m.respawn(Vector3(-0.6, 0, -49.0), "Bùn nuốt đến đầu gối — lạnh và háu đói. Tôi giật chân ra kịp.")


func _update_beam() -> void:
	for seg in _beam_segs:
		seg.visible = false
	var origin := Vector3(6.2, 1.45, -50.0)
	var dir := Vector3(-1, 0, 0)
	var remaining := _mirrors.duplicate()
	for i in range(_beam_segs.size()):
		var best_t := 999.0
		var best = null
		for pair in remaining:
			var node: Node3D = pair[0]
			var mp := Vector3(node.position.x, 1.45, node.position.z)
			var t := (mp - origin).dot(dir)
			if t > 0.4 and t < best_t and (origin + dir * t).distance_to(mp) < 0.5:
				best_t = t
				best = pair
		# chuông 1?
		var bt := (_bell1_pos + Vector3(0, 0.15, 0) - origin).dot(dir)
		if bt > 0.4 and (origin + dir * bt).distance_to(_bell1_pos + Vector3(0, 0.15, 0)) < 0.65 and (best == null or bt < best_t):
			_draw_seg(i, origin, origin + dir * bt)
			if not bell1_rung:
				bell1_rung = true
				m.ui.play_chime()
				m.ui.toast("Quả chuông thứ nhất ngân — ánh trăng đọng lại thành SẮC KIM")
				_kim_orb = Build.color_orb(self, _bell1_pos + Vector3(0, -0.6, 0.8), Color(1.0, 0.96, 0.82))
				m.add_interact(Vector3(_bell1_pos.x, 0, _bell1_pos.z + 0.8), 1.8, "Nhận SẮC KIM", Callable(self, "_take_kim"), true)
			return
		if best == null:
			_draw_seg(i, origin, origin + dir * 14.0)
			return
		var node2: Node3D = best[0]
		var hit := Vector3(node2.position.x, 1.45, node2.position.z)
		_draw_seg(i, origin, hit)
		var ang: float = best[1]
		var n := Vector3(sin(ang), 0, cos(ang))
		dir = (dir - n * 2.0 * dir.dot(n)).normalized()
		origin = hit
		remaining.erase(best)


func _draw_seg(i: int, a: Vector3, b: Vector3) -> void:
	var seg: MeshInstance3D = _beam_segs[i]
	var d := b - a
	if d.length() < 0.01:
		seg.visible = false
		return
	seg.visible = true
	seg.position = (a + b) * 0.5
	seg.look_at(b, Vector3.UP if absf(d.normalized().y) < 0.9 else Vector3.RIGHT)
	seg.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	seg.scale = Vector3(1, d.length(), 1)


func clamp_player(pos: Vector3) -> Vector3:
	pos.x = clampf(pos.x, -7.4, 7.4)
	pos.z = clampf(pos.z, RIVER_Z + 0.6, BANK_Z0 + 0.5)
	return pos
