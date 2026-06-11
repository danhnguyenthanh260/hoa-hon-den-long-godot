# Vòng lặp game + máy trạng thái + điều phối 5 chương.
# Chạy "-- --autoplay" để bot chụp screenshot từng chương vào res://shots/.
extends Node3D

const GameWorld := preload("res://scripts/world.gd")
const PlayerCharacter := preload("res://scripts/player.gd")
const GameUI := preload("res://scripts/game_ui.gd")
const DialogueUI := preload("res://scripts/dialogue_ui.gd")
const C1 := preload("res://scripts/c1.gd")
const C2 := preload("res://scripts/c2.gd")
const C3 := preload("res://scripts/c3.gd")
const C4 := preload("res://scripts/c4.gd")
const C5 := preload("res://scripts/c5.gd")

enum State { INTRO, PLAY, PUZZLE, DIALOGUE, CUTSCENE, WON }

const CHAPTER_TITLES := {
	1: ["Chương Một", "Ngõ Không Tên"],
	2: ["Chương Hai", "Giếng Đôi"],
	3: ["Chương Ba", "Nhà Ký Ức"],
	4: ["Chương Bốn", "Bến Sông Ngược"],
	5: ["Chương Năm", "Chùa Cầu Treo Giữa Không"],
}
const CHAPTER_SPAWNS := {
	2: Vector3(0, 0, -22.5),
	3: Vector3(60, 0, -22),
	4: Vector3(0, 0, -46.5),
	5: Vector3(0, 40, -113.5),
}

var state: int = State.INTRO
var world: Node3D
var player: Node3D
var ui: CanvasLayer
var dialogue: CanvasLayer
var audio: Node
var camera: Camera3D
var cam_look := Vector3(0, 1.3, 7)
var checkpoint := Vector3(0, 0, 7)
var chapter_no := 1
var chapters := {}
var active_puzzle = null
var free_cam := false
var _interacts: Array = []
var _say_then: Callable = Callable()
var _dust: GPUParticles3D


func _ready() -> void:
	world = GameWorld.new()
	add_child(world)
	player = PlayerCharacter.new()
	add_child(player)
	player.position = Vector3(0, 0, 7)
	ui = GameUI.new()
	ui.player = player
	add_child(ui)
	dialogue = DialogueUI.new()
	add_child(dialogue)
	dialogue.finished.connect(_on_dialogue_finished)
	camera = Camera3D.new()
	camera.fov = 60
	add_child(camera)
	camera.position = Vector3(0, 3.4, 13)
	camera.current = true
	_make_dust()
	audio = preload("res://scripts/audio_manager.gd").new()
	add_child(audio)

	chapters = {1: C1.new(), 2: C2.new(), 3: C3.new(), 4: C4.new(), 5: C5.new()}
	for n in chapters:
		add_child(chapters[n])
		chapters[n].build(self)

	var args := OS.get_cmdline_user_args()
	if args.has("--autoplay"):
		_autoplay()
	elif args.has("--flow"):
		_flow_test()
	elif args.has("--chara"):
		_chara_shots()
	elif args.has("--aiview"):
		_aiview()
	elif args.has("--rigview"):
		_rigview()


func is_play() -> bool:
	return state == State.PLAY


func current_chapter():
	return chapters[chapter_no]


# ---------- hạt bụi / tàn tro lơ lửng quanh người chơi ----------
func _make_dust() -> void:
	_dust = GPUParticles3D.new()
	_dust.amount = 80
	_dust.lifetime = 6.0
	_dust.visibility_aabb = AABB(Vector3(-12, -4, -12), Vector3(24, 12, 24))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(9, 3.5, 9)
	pm.gravity = Vector3(0, 0.015, 0)
	pm.initial_velocity_min = 0.02
	pm.initial_velocity_max = 0.12
	pm.angular_velocity_min = -20
	pm.angular_velocity_max = 20
	_dust.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.05, 0.05)
	var qm := StandardMaterial3D.new()
	qm.albedo_color = Color(1.0, 0.7, 0.4, 0.85)
	qm.albedo_texture = preload("res://scripts/textures.gd").soft_dot()
	qm.emission_enabled = true
	qm.emission = Color(1.0, 0.62, 0.3)
	qm.emission_energy_multiplier = 1.6
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	quad.material = qm
	_dust.draw_pass_1 = quad
	add_child(_dust)


# ---------- thoại ----------
func say(lines: Array, then: Callable = Callable()) -> void:
	_say_then = then
	state = State.DIALOGUE
	ui.show_prompt("")
	dialogue.start(lines)


func _on_dialogue_finished() -> void:
	if state == State.DIALOGUE:
		state = State.PLAY
	var cb := _say_then
	_say_then = Callable()
	if cb.is_valid():
		cb.call()


# ---------- tương tác ----------
func add_interact(pos: Vector3, r: float, prompt: String, cb: Callable, once: bool) -> void:
	_interacts.append({"pos": pos, "r": r, "prompt": prompt, "cb": cb, "once": once, "used": false})


func _nearest_interact():
	var best = null
	var best_d := 99.0
	for it in _interacts:
		if it["used"]:
			continue
		var d: float = player.position.distance_to(it["pos"])
		if d < it["r"] and d < best_d:
			best_d = d
			best = it
	return best


# ---------- câu đố bóng ----------
func enter_puzzle(p, hint: String) -> void:
	active_puzzle = p
	p.active = true
	state = State.PUZZLE
	ui.show_prompt("")
	ui.show_hint(hint)


func exit_puzzle_after(sec: float) -> void:
	await get_tree().create_timer(sec).timeout
	if active_puzzle != null:
		active_puzzle.active = false
		active_puzzle = null
	ui.show_hint("")
	if state == State.PUZZLE:
		state = State.PLAY


# ---------- chuyển chương / chết / cắt cảnh ----------
func goto_chapter(n: int) -> void:
	state = State.CUTSCENE
	await ui.fade_to(1.0, 1.0)
	chapter_no = n
	if CHAPTER_SPAWNS.has(n):
		player.position = CHAPTER_SPAWNS[n]
	checkpoint = player.position
	camera.position = player.position + Vector3(0, 3.2, 5.6)
	cam_look = player.position + Vector3(0, 1.3, 0)
	current_chapter().enter_beat()
	await ui.fade_to(0.0, 1.2)
	var t: Array = CHAPTER_TITLES[n]
	await ui.title_card(t[0], t[1])
	if state == State.CUTSCENE:
		state = State.PLAY


func respawn(pos: Vector3, thought: String) -> void:
	if state != State.PLAY:
		return
	state = State.CUTSCENE
	await ui.fade_to(1.0, 0.5)
	player.position = pos
	camera.position = pos + Vector3(0, 3.2, 5.6)
	cam_look = pos + Vector3(0, 1.3, 0)
	await ui.fade_to(0.0, 0.6)
	state = State.PLAY
	if thought != "":
		say([["Minh (nghĩ)", thought]])


func flash_black() -> void:
	ui.fade_to(1.0, 0.05)
	await get_tree().create_timer(0.12).timeout
	ui.fade_to(0.0, 0.4)


func ending_sequence() -> void:
	state = State.CUTSCENE
	ui.set_objective("")
	await ui.fade_to(1.0, 3.0, Color(1.0, 0.85, 0.4))
	await ui.title_card("Minh bước vào lòng chiếc Đèn Họa Hồn", "Lửa đỏ chuyển vàng kim — rồi ngũ sắc")
	await ui.title_card("Từ Chùa Cầu, ánh sáng tràn xuống", "Từng mảnh phố ráp lại. Đèn nối đèn. Hoa đăng xuôi dòng trở lại.")
	await ui.fade_to(1.0, 1.5, Color(0, 0, 0))
	await ui.roll_credits()
	ui.show_win()
	await ui.fade_to(0.0, 1.5)
	state = State.WON


# ---------- input ----------
func _unhandled_input(event: InputEvent) -> void:
	if dialogue.active:
		return
	if state == State.INTRO:
		if (event is InputEventKey and event.is_pressed()) or (event is InputEventMouseButton and event.is_pressed()):
			state = State.PLAY
			ui.hide_intro()
			current_chapter().intro_beat()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var cid: String = player.color_for_key(event)
		if cid != "":
			if player.has_color(cid):
				player.set_color(cid)
				ui.toast("Đèn chuyển sắc %s" % player.COLOR_DEFS[cid]["name"])
			else:
				ui.toast("Chưa tìm thấy Sắc %s — nó còn ở đâu đó trong phố..." % player.COLOR_DEFS[cid]["name"])
		if event.keycode == KEY_E:
			_on_interact_key()
		elif event.keycode == KEY_R and state == State.WON:
			get_tree().reload_current_scene()
	ui.update_colors()


func _on_interact_key() -> void:
	if state == State.PUZZLE:
		if active_puzzle != null and not active_puzzle.solved:
			active_puzzle.active = false
			active_puzzle = null
			ui.show_hint("")
			state = State.PLAY
		return
	if state != State.PLAY:
		return
	var it = _nearest_interact()
	if it != null:
		if it["once"]:
			it["used"] = true
		it["cb"].call()


# ---------- vòng lặp ----------
func _process(delta: float) -> void:
	match state:
		State.PLAY:
			player.update_move(delta, Callable(current_chapter(), "clamp_player"))
			var it = _nearest_interact()
			ui.show_prompt(it["prompt"] if it != null else "")
		State.PUZZLE:
			if active_puzzle != null:
				active_puzzle.update_puzzle(delta)
	if state == State.PLAY or state == State.PUZZLE or state == State.DIALOGUE:
		current_chapter().update(delta)
	world.update_world(delta)
	_dust.position = player.position
	audio.update(delta, self)
	_update_camera(delta)


func _update_camera(delta: float) -> void:
	if free_cam:
		return
	var desired: Vector3
	var look: Vector3
	if state == State.PUZZLE and active_puzzle != null:
		var lp: Vector3 = active_puzzle.light_pos
		desired = lp + Vector3(-2.2, 0.9, 4.9)
		look = Vector3(lp.x, lp.y + 0.1, lp.z - 2.5)
	else:
		desired = player.position + Vector3(0, 3.2, 5.6)
		look = player.position + Vector3(0, 1.3, 0)
	var t := 1.0 - pow(0.001, delta)
	camera.position = camera.position.lerp(desired, t)
	cam_look = cam_look.lerp(look, t)
	if camera.position.distance_to(cam_look) > 0.05:
		camera.look_at(cam_look)


# ---------- autoplay: chụp ảnh kiểm tra từng chương ----------
func _autoplay() -> void:
	var dir := ProjectSettings.globalize_path("res://shots")
	DirAccess.make_dir_recursive_absolute(dir)
	await get_tree().create_timer(1.2).timeout
	await _shot(dir + "/01-intro.png")
	state = State.PLAY
	ui.hide_intro()
	# ---- chụp cận nhân vật 4 góc dưới đèn studio tạm ----
	free_cam = true
	player.position = Vector3(0, 0, 2)
	var studio := OmniLight3D.new()
	studio.light_color = Color(1.0, 0.92, 0.8)
	studio.light_energy = 2.2
	studio.omni_range = 8.0
	studio.position = Vector3(1.5, 2.6, 3.5)
	add_child(studio)
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.5, 0.6, 1.0)
	fill.light_energy = 0.9
	fill.omni_range = 8.0
	fill.position = Vector3(-2.0, 1.8, 0.5)
	add_child(fill)
	var views := {
		"front": Vector3(0, 1.25, -2.3),
		"side": Vector3(2.3, 1.25, 0.2),
		"back": Vector3(0.4, 1.45, 2.4),
	}
	for vname in views:
		camera.position = player.position + views[vname]
		camera.look_at(player.position + Vector3(0, 1.05, 0))
		await get_tree().create_timer(0.5).timeout
		await _shot(dir + "/chara-%s.png" % vname)
	player.force_walk = true
	camera.position = player.position + Vector3(1.9, 1.2, -1.6)
	camera.look_at(player.position + Vector3(0, 0.95, 0))
	await get_tree().create_timer(0.9).timeout
	await _shot(dir + "/chara-walk.png")
	player.force_walk = false
	studio.queue_free()
	fill.queue_free()
	free_cam = false
	player.position = Vector3(0, 0, 7)
	await get_tree().create_timer(0.8).timeout
	await _shot(dir + "/c1-alley.png")
	# C1: câu đố bóng
	player.position = Vector3(3.2, 0, -14.8)
	var c1 = chapters[1]
	enter_puzzle(c1.puzzle, "A / D — xoay đèn cho bóng Chim Lạc khớp hình mờ")
	c1.puzzle.angle = 0.4
	await get_tree().create_timer(1.2).timeout
	await _shot(dir + "/c1-puzzle.png")
	c1.puzzle.angle = 0.05
	await get_tree().create_timer(1.5).timeout
	await _shot(dir + "/c1-solved.png")
	state = State.PLAY
	# C2
	for cid in ["hoa", "thuy", "moc", "kim", "tho"]:
		player.unlock_color(cid)
	ui.update_colors()
	chapter_no = 2
	world.set_zone("c2")
	chapters[2]._child.visible = true
	player.set_color("thuy")
	player.position = Vector3(0.5, 0, -30.5)
	camera.position = player.position + Vector3(0, 3.2, 5.6)
	await get_tree().create_timer(1.5).timeout
	await _shot(dir + "/c2-wells.png")
	player.position = Vector3(0.6, 0, -34.0)
	await get_tree().create_timer(1.0).timeout
	await _shot(dir + "/c2-tiles.png")
	# C3
	chapter_no = 3
	world.set_zone("c3")
	world.set_moon_visible(false)
	var c3 = chapters[3]
	c3.vines_grown = true
	c3._grow_t = 0.0
	player.set_color("hoa")
	player.position = Vector3(60, 0, -26)
	camera.position = player.position + Vector3(0, 3.2, 5.6)
	await get_tree().create_timer(2.5).timeout
	await _shot(dir + "/c3-house.png")
	enter_puzzle(c3.puzzle, "A / D — xoay đèn cho bóng HOA SEN khớp vệt mờ")
	c3.puzzle.angle = 0.35
	await get_tree().create_timer(1.2).timeout
	await _shot(dir + "/c3-lotus.png")
	state = State.PLAY
	ui.show_hint("")
	if active_puzzle != null:
		active_puzzle.active = false
		active_puzzle = null
	# C4
	chapter_no = 4
	world.set_zone("c4")
	player.set_color("tho")
	player.position = Vector3(0, 0, -52)
	camera.position = player.position + Vector3(0, 3.2, 5.6)
	await get_tree().create_timer(1.5).timeout
	await _shot(dir + "/c4-river.png")
	player.position = Vector3(2.0, 0, -51)
	await get_tree().create_timer(1.0).timeout
	await _shot(dir + "/c4-mirrors.png")
	# C5
	chapter_no = 5
	world.set_zone("c5")
	player.set_color("thuy")
	player.position = Vector3(0, 40, -114)
	camera.position = player.position + Vector3(0, 3.2, 5.6)
	chapters[5].fight_active = true
	await get_tree().create_timer(1.5).timeout
	await _shot(dir + "/c5-boss.png")
	# hộp thoại
	say([["Bóng Tối Thủ Cựu", "Người giữ đèn. LẠI là ngươi. Lần nào ngươi cũng tới đây."]])
	await get_tree().create_timer(1.0).timeout
	await _shot(dir + "/c5-dialogue.png")
	print("AUTOPLAY DONE")
	get_tree().quit()


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("shot: ", path)


# ---------- chụp nhân vật full HD: turntable 8 góc + cận mặt + tư thế bước ----------
func _chara_shots() -> void:
	get_window().size = Vector2i(1920, 1080)
	var dir := ProjectSettings.globalize_path("res://shots/chara")
	DirAccess.make_dir_recursive_absolute(dir)
	state = State.PLAY
	ui.hide_intro()
	free_cam = true
	camera.fov = 45
	player.position = Vector3(0, 0, 2)
	var key_l := OmniLight3D.new()
	key_l.light_color = Color(1.0, 0.92, 0.8)
	key_l.light_energy = 2.4
	key_l.omni_range = 9.0
	key_l.position = Vector3(1.6, 2.6, 3.6)
	add_child(key_l)
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.5, 0.62, 1.0)
	fill.light_energy = 1.0
	fill.omni_range = 9.0
	fill.position = Vector3(-2.2, 1.6, 0.8)
	add_child(fill)
	var rim := OmniLight3D.new()
	rim.light_color = Color(1.0, 0.75, 0.45)
	rim.light_energy = 1.4
	rim.omni_range = 8.0
	rim.position = Vector3(0.5, 2.4, -2.6)
	add_child(rim)
	await get_tree().create_timer(1.0).timeout
	# turntable 8 góc — nhân vật choán đầy khung 1080p
	var center: Vector3 = player.position + Vector3(0, 0.95, 0)
	for i in range(8):
		var a := TAU * i / 8.0 + PI   # bắt đầu từ chính diện (mặt hướng -z)
		camera.position = center + Vector3(sin(a) * 2.35, 0.25, cos(a) * 2.35)
		camera.look_at(center)
		await get_tree().create_timer(0.35).timeout
		await _shot(dir + "/turn-%d.png" % i)
	# cận mặt
	camera.position = player.position + Vector3(0.18, 1.56, -0.78)
	camera.look_at(player.position + Vector3(0, 1.56, 0))
	await get_tree().create_timer(0.4).timeout
	await _shot(dir + "/face.png")
	# tư thế bước (góc 3/4)
	player.force_walk = true
	camera.position = player.position + Vector3(1.7, 1.15, -1.5)
	camera.look_at(player.position + Vector3(0, 0.9, 0))
	await get_tree().create_timer(0.85).timeout
	await _shot(dir + "/walk.png")
	await get_tree().create_timer(0.3).timeout
	await _shot(dir + "/walk2.png")
	print("CHARA DONE")
	get_tree().quit()


# ---------- xem mesh AI sinh cạnh Minh procedural ----------
func _aiview() -> void:
	get_window().size = Vector2i(1920, 1080)
	var dir := ProjectSettings.globalize_path("res://shots/chara")
	DirAccess.make_dir_recursive_absolute(dir)
	state = State.PLAY
	ui.hide_intro()
	free_cam = true
	camera.fov = 45
	player.position = Vector3(-0.75, 0, 2)
	var scene := load("res://assets/models/minh_shape_0.glb")
	var inst: Node3D = scene.instantiate()
	add_child(inst)
	# đo AABB toàn cục, scale về cao ~1.8m và đặt đứng trên nền
	await get_tree().process_frame
	var aabb := AABB()
	var first := true
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var a: AABB = mi.global_transform * mi.get_aabb()
		aabb = a if first else aabb.merge(a)
		first = false
	var k := 1.8 / aabb.size.y
	inst.scale = Vector3.ONE * k
	inst.position = Vector3(0.75, -aabb.position.y * k, 2)
	# đèn studio
	for cfg in [[Vector3(1.6, 2.6, 5.6), Color(1.0, 0.92, 0.8), 2.4], [Vector3(-2.2, 1.6, 2.8), Color(0.5, 0.62, 1.0), 1.0], [Vector3(0.5, 2.4, -0.6), Color(1.0, 0.75, 0.45), 1.4]]:
		var l := OmniLight3D.new()
		l.position = cfg[0]
		l.light_color = cfg[1]
		l.light_energy = cfg[2]
		l.omni_range = 10.0
		add_child(l)
	await get_tree().create_timer(1.0).timeout
	var center := Vector3(0, 0.95, 2)
	var angles := {"front": PI, "side": PI / 2.0, "back": 0.0}
	for vname in angles:
		var a: float = angles[vname]
		camera.position = center + Vector3(sin(a) * 3.4, 0.3, cos(a) * 3.4)
		camera.look_at(center)
		await get_tree().create_timer(0.4).timeout
		await _shot(dir + "/ai-%s.png" % vname)
	print("AIVIEW DONE")
	get_tree().quit()


# ---------- xem hồn ma rig bước đi cận cảnh ----------
func _rigview() -> void:
	get_window().size = Vector2i(1920, 1080)
	var dir := ProjectSettings.globalize_path("res://shots/chara")
	DirAccess.make_dir_recursive_absolute(dir)
	state = State.PLAY
	ui.hide_intro()
	free_cam = true
	camera.fov = 45
	player.position = Vector3(0, 0, 9)
	var walker := preload("res://scripts/ghost_walker.gd").new()
	add_child(walker)
	walker.setup("res://assets/models/minh_rigged.glb", 1.7,
		[Vector3(-2.0, 0, 2.0), Vector3(2.0, 0, 2.0)])
	var key_l := OmniLight3D.new()
	key_l.light_color = Color(1.0, 0.92, 0.8)
	key_l.light_energy = 2.0
	key_l.omni_range = 9.0
	key_l.position = Vector3(1.5, 2.6, 4.6)
	add_child(key_l)
	await get_tree().create_timer(1.5).timeout
	for i in range(4):
		camera.position = walker.position + Vector3(1.4, 1.1, 2.2)
		camera.look_at(walker.position + Vector3(0, 0.9, 0))
		await get_tree().create_timer(0.0).timeout
		await _shot(dir + "/rig-%d.png" % i)
		await get_tree().create_timer(0.8).timeout
	print("RIGVIEW DONE")
	get_tree().quit()


# ---------- flow test: chơi hết 5 chương bằng chính các handler thật (headless) ----------
func _flow_test() -> void:
	dialogue.auto_advance = true
	state = State.PLAY
	ui.hide_intro()
	var c1 = chapters[1]
	c1.intro_beat()
	await _wait_dialogue()
	c1._talk_ba()
	await _wait_dialogue()
	enter_puzzle(c1.puzzle, "")
	c1.puzzle.angle = 0.05
	await _until(func(): return c1.puzzle.solved, "c1 puzzle")
	await _until(func(): return state == State.PLAY, "c1 exit puzzle")
	c1._take_hoa()
	await _wait_dialogue()
	player.set_color("hoa")
	c1._try_burn()
	await _wait_dialogue()
	assert(c1.web_burned)
	player.position = Vector3(0, 0, -23.5)
	await _until(func(): return chapter_no == 2 and state == State.PLAY, "vào c2", 30.0)
	var c2 = chapters[2]
	for i in range(2):
		player.position = Vector3(0, 0, -43.0)
		await _until(func(): return c2.loops == i + 1, "vòng lặp cổng %d" % (i + 1))
		await _wait_dialogue()
	c2._talk_child()
	await _wait_dialogue()
	c2._look_well()
	await _wait_dialogue()
	c2._take_thuy()
	await _wait_dialogue()
	c2.passed = true
	goto_chapter(3)
	await _until(func(): return chapter_no == 3 and state == State.PLAY, "vào c3", 30.0)
	var c3 = chapters[3]
	c3._take_moc()
	await _wait_dialogue()
	player.set_color("moc")
	c3._try_grow()
	await _wait_dialogue()
	await _until(func(): return c3._grow_t > 4.5, "dây leo mọc", 30.0)
	player.position = Vector3(56, 3.32, -38)
	c3._enter_puzzle()
	c3.puzzle.angle = 0.05
	await _until(func(): return c3.puzzle.solved, "đố hoa sen")
	await _wait_dialogue()
	c3._try_exit()
	await _until(func(): return chapter_no == 4 and state == State.PLAY, "vào c4", 30.0)
	var c4 = chapters[4]
	c4._talk_boatman()
	await _wait_dialogue()
	c4._mirrors[0][1] = -PI / 4.0
	c4._mirrors[1][1] = 3.0 * PI / 4.0
	for pairm in c4._mirrors:
		pairm[0].rotation.y = pairm[1]
	await _until(func(): return c4.bell1_rung, "chuông 1 (gương)")
	c4._take_kim()
	await _wait_dialogue()
	c4._take_tho()
	await _wait_dialogue()
	player.set_color("tho")
	player.position = Vector3(c4._bell2_pos.x, 0, c4._bell2_pos.z)
	c4._ring_bell2()
	assert(c4.bell2_rung)
	c4._talk_boatman()
	await _until(func(): return chapter_no == 5 and state == State.PLAY, "vào c5", 40.0)
	var c5 = chapters[5]
	await _until(func(): return c5.fight_active, "trận cuối bắt đầu", 30.0)
	await _wait_dialogue()
	for ph in range(3):
		player.set_color(c5.PHASES[ph]["weak"])
		var t := 0.0
		while c5.phase == ph and not c5.defeated and t < 25.0:
			player.position = c5._boss.position + Vector3(3.0, 0, 0)
			player.position.y = 40
			await get_tree().create_timer(0.1).timeout
			t += 0.1
		if c5.phase == ph and not c5.defeated:
			push_error("FLOW TIMEOUT: pha boss %d" % ph)
			get_tree().quit(1)
			return
		await _wait_dialogue()
	await _until(func(): return state == State.WON, "ending + credits", 60.0)
	print("FLOW OK — het 5 chuong, ending chay tron ven")
	get_tree().quit()


func _wait_dialogue() -> void:
	await get_tree().create_timer(0.4).timeout
	while dialogue.active:
		await get_tree().create_timer(0.1).timeout


func _until(cond: Callable, label: String, timeout := 20.0) -> void:
	var t := 0.0
	while not cond.call():
		await get_tree().create_timer(0.1).timeout
		t += 0.1
		if t > timeout:
			push_error("FLOW TIMEOUT: " + label)
			get_tree().quit(1)
			return
