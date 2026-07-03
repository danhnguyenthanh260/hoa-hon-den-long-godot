# Vòng lặp game + máy trạng thái + điều phối 5 chương.
# Chạy "-- --autoplay" để bot chụp screenshot từng chương vào res://shots/.
extends Node3D

const GameWorld := preload("res://scripts/world.gd")
const PlayerCharacter := preload("res://scripts/player.gd")
const GameUI := preload("res://scripts/game_ui.gd")
const DialogueUI := preload("res://scripts/dialogue_ui.gd")
const MemoryStallInspectUI := preload("res://scripts/memory_stall_inspect_ui.gd")
const C1 := preload("res://scripts/c1.gd")
const C2 := preload("res://scripts/c2.gd")
const C3 := preload("res://scripts/c3.gd")
const C4 := preload("res://scripts/c4.gd")
const C5 := preload("res://scripts/c5.gd")
const NarrativeState := preload("res://scripts/narrative_state.gd")
const CheckpointService := preload("res://scripts/checkpoint_service.gd")
const VoiceDirector := preload("res://scripts/voice_director.gd")
const Pixel3DShader := preload("res://assets/shaders/pixel3d.gdshader")

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
var memory_stall: CanvasLayer
var narrative: NarrativeState
var checkpoints: CheckpointService
var voice: VoiceDirector
var audio: Node
var camera: Camera3D
var cam_look := Vector3(0, 1.3, 7)
var checkpoint := Vector3(0, 0, 7)
var chapter_no := 1
var chapters := {}
var active_puzzle = null
var first_person := true
var fp_yaw := PI
var fp_pitch := -0.08
# Góc nhìn: V xoay vòng Ngôi-1 -> Ngôi-3 (orbit sau lưng) -> Follow cố định
enum View { FIRST, THIRD, FOLLOW }
var view_mode: int = View.FIRST
var tp_yaw := PI            # hướng orbit ngôi-3 (chuột)
var tp_pitch := 0.18        # góc ngẩng/cúi ngôi-3
var tp_dist := 4.2          # khoảng cách sau lưng
var tp_height := 1.45       # tâm ngắm ngang vai
var bot_mode := false
var free_cam := false
var map_mode := false
var _pre_map_fp := false
var _interacts: Array = []
var _say_then: Callable = Callable()
var _memory_stall_owner = null
var _dust: GPUParticles3D
var _debug_dir := ""
var _debug_shot_n := 0
var _debug_mode := false
var _debug_pos_lbl: Label
var _debug_toast_lbl: Label
var _debug_toast_timer := 0.0
var _debug_note_panel: CanvasItem
var _debug_note_edit: LineEdit
var _debug_note_idx := -1
var _debug_session: Array = []
var _pixel3d_layer: CanvasLayer
var _pixel3d_rect: ColorRect
var _pixel3d_mat: ShaderMaterial


func _ready() -> void:
	narrative = NarrativeState.new()
	checkpoints = CheckpointService.new()
	voice = VoiceDirector.new(narrative)
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
	dialogue.choice_selected.connect(_on_dialogue_choice_selected)
	memory_stall = MemoryStallInspectUI.new()
	add_child(memory_stall)
	memory_stall.closed.connect(_on_memory_stall_closed)
	camera = Camera3D.new()
	camera.fov = 60
	add_child(camera)
	camera.position = Vector3(0, 3.4, 13)
	camera.current = true
	_make_pixel3d_overlay()
	_make_dust()
	audio = preload("res://scripts/audio_manager.gd").new()
	add_child(audio)

	# Debug session: clear shots/debug/ at every launch
	_debug_dir = ProjectSettings.globalize_path("res://shots/debug")
	DirAccess.make_dir_recursive_absolute(_debug_dir)
	var _da := DirAccess.open(_debug_dir)
	if _da:
		_da.list_dir_begin()
		var _fn := _da.get_next()
		while _fn != "":
			if _fn.ends_with(".png"):
				DirAccess.remove_absolute(_debug_dir + "/" + _fn)
			_fn = _da.get_next()

	chapters = {1: C1.new(), 2: C2.new(), 3: C3.new(), 4: C4.new(), 5: C5.new()}
	for n in chapters:
		add_child(chapters[n])
		chapters[n].build(self)

	var args := OS.get_cmdline_user_args()
	bot_mode = args.size() > 0
	if bot_mode:
		first_person = false
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
	elif args.has("--houseview"):
		_house_view()
	elif args.has("--debug"):
		_debug_mode = true
		free_cam = true
		state = State.PLAY
		ui.hide_intro()
		# Ánh sáng ban ngày — giống houseview QA
		var dbg_env := Environment.new()
		dbg_env.background_mode = Environment.BG_COLOR
		dbg_env.background_color = Color(0.60, 0.70, 0.85)
		dbg_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		dbg_env.ambient_light_color = Color(0.82, 0.87, 0.95)
		dbg_env.ambient_light_energy = 1.1
		dbg_env.tonemap_mode = Environment.TONE_MAPPER_ACES
		camera.environment = dbg_env
		var dbg_sun := DirectionalLight3D.new()
		dbg_sun.light_color = Color(1.0, 0.97, 0.90)
		dbg_sun.light_energy = 2.2
		dbg_sun.shadow_enabled = false
		dbg_sun.rotation_degrees = Vector3(-50, -35, 0)
		add_child(dbg_sun)
		var dbg_fill := DirectionalLight3D.new()
		dbg_fill.light_color = Color(0.72, 0.82, 1.0)
		dbg_fill.light_energy = 0.8
		dbg_fill.rotation_degrees = Vector3(-25, 145, 0)
		add_child(dbg_fill)
		# Camera khởi đầu nhìn bao quát phố
		camera.fov = 70
		camera.position = Vector3(-10.0, 8.0, 5.0)
		camera.look_at(Vector3(-20.0, 1.0, 11.0))
		# HUD hướng dẫn
		var hud := CanvasLayer.new()
		add_child(hud)
		var guide := Label.new()
		guide.text = "WASD/QE = bay  |  Shift = nhanh x3  |  Click = bắt chuột / nhìn  |  ESC = thả chuột  |  F11 = toggle fly  |  F12 = chụp ảnh"
		guide.add_theme_font_size_override("font_size", 14)
		guide.add_theme_color_override("font_color", Color(1.0, 1.0, 0.75))
		guide.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
		guide.add_theme_constant_override("shadow_offset_x", 1)
		guide.add_theme_constant_override("shadow_offset_y", 1)
		guide.position = Vector2(10, 8)
		hud.add_child(guide)
		_debug_pos_lbl = Label.new()
		_debug_pos_lbl.add_theme_font_size_override("font_size", 13)
		_debug_pos_lbl.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
		_debug_pos_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
		_debug_pos_lbl.add_theme_constant_override("shadow_offset_x", 1)
		_debug_pos_lbl.add_theme_constant_override("shadow_offset_y", 1)
		_debug_pos_lbl.position = Vector2(10, 28)
		hud.add_child(_debug_pos_lbl)
		var click_hint := Label.new()
		click_hint.text = "[ Click vào cửa sổ để bắt chuột và nhìn xung quanh ]"
		click_hint.add_theme_font_size_override("font_size", 16)
		click_hint.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
		click_hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
		click_hint.add_theme_constant_override("shadow_offset_x", 1)
		click_hint.add_theme_constant_override("shadow_offset_y", 1)
		click_hint.set_anchors_preset(Control.PRESET_CENTER)
		click_hint.position = Vector2(400, 440)
		hud.add_child(click_hint)
		# Toast xác nhận chụp ảnh (top-center, ẩn mặc định)
		_debug_toast_lbl = Label.new()
		_debug_toast_lbl.visible = false
		_debug_toast_lbl.add_theme_font_size_override("font_size", 18)
		_debug_toast_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		_debug_toast_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
		_debug_toast_lbl.add_theme_constant_override("shadow_offset_x", 1)
		_debug_toast_lbl.add_theme_constant_override("shadow_offset_y", 1)
		_debug_toast_lbl.position = Vector2(420, 50)
		hud.add_child(_debug_toast_lbl)
		# Panel ghi chú (xuất hiện sau khi chụp, ẩn mặc định)
		var note_bg := ColorRect.new()
		note_bg.color = Color(0, 0, 0, 0.82)
		note_bg.size = Vector2(1280, 88)
		note_bg.position = Vector2(0, 632)
		note_bg.visible = false
		hud.add_child(note_bg)
		_debug_note_panel = note_bg
		var note_lbl := Label.new()
		note_lbl.name = "NoteLbl"
		note_lbl.add_theme_font_size_override("font_size", 13)
		note_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
		note_lbl.position = Vector2(10, 6)
		note_bg.add_child(note_lbl)
		_debug_note_edit = LineEdit.new()
		_debug_note_edit.placeholder_text = "Mô tả vấn đề hoặc ghi chú... (Enter = lưu | ESC = bỏ qua)"
		_debug_note_edit.size = Vector2(1260, 34)
		_debug_note_edit.position = Vector2(10, 48)
		_debug_note_edit.add_theme_font_size_override("font_size", 14)
		_debug_note_edit.text_submitted.connect(_on_debug_note_submitted)
		note_bg.add_child(_debug_note_edit)
		# Chuột: bắt đầu tự do, click vào cửa sổ mới capture
		get_window().size = Vector2i(1280, 720)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


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


func remote_voice(
	beat_id: String,
	authored_pressure: float,
	lines: Array,
	then: Callable = Callable(),
	trust_delta := 0,
	evidence_id := "",
	evidence_claim := "",
	refusal := false
) -> void:
	voice.apply_intervention(beat_id, authored_pressure, trust_delta, evidence_id, evidence_claim, refusal)
	_save_checkpoint()
	say(voice.wrap_lines(lines), then)


func _on_dialogue_finished() -> void:
	if state == State.DIALOGUE:
		state = State.PLAY
	var cb := _say_then
	_say_then = Callable()
	if cb.is_valid():
		cb.call()


func _on_dialogue_choice_selected(choice_id: String, index: int, label: String) -> void:
	narrative.record_choice(choice_id, index, label)
	_save_checkpoint()


func open_memory_stall(owner) -> void:
	_memory_stall_owner = owner
	state = State.DIALOGUE
	ui.show_prompt("")
	memory_stall.open_panel()


func _on_memory_stall_closed(inspected_ids: Array, key_taken: bool) -> void:
	if state == State.DIALOGUE:
		state = State.PLAY
	if _memory_stall_owner != null and _memory_stall_owner.has_method("on_memory_stall_closed"):
		_memory_stall_owner.on_memory_stall_closed(inspected_ids, key_taken)
	_memory_stall_owner = null
	_save_checkpoint()


func _save_checkpoint() -> void:
	if player == null:
		return
	if not checkpoints.save_checkpoint(narrative, chapter_no, player.position):
		push_warning("Checkpoint save failed")


# ---------- tương tác ----------
func add_interact(pos: Vector3, r: float, prompt: String, cb: Callable, once: bool) -> Dictionary:
	var it := {"pos": pos, "r": r, "prompt": prompt, "cb": cb, "once": once, "used": false}
	_interacts.append(it)
	return it


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
	match n:
		2:
			narrative.set_beat("c2_first_displacement", 0.24)
		3:
			narrative.set_beat("c3_memory_house", 0.42)
		4:
			narrative.set_beat("c4_conflicting_testimony", 0.62)
		5:
			narrative.set_beat("c5_verification", 0.78)
	if CHAPTER_SPAWNS.has(n):
		player.position = CHAPTER_SPAWNS[n]
	checkpoint = player.position
	_save_checkpoint()
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
	var outcome := narrative.ending_key()
	if outcome == "release":
		await ui.fade_to(1.0, 3.0, Color(1.0, 0.85, 0.4))
		dialogue.reveal_player_name()
		dialogue.start([
			["Giọng từ phía sông", "Minh..."],
			["Giọng từ đầu ngõ", "Minh..."],
			["Những giọng trong phố", "Minh, mau về."],
			["Minh (nghĩ)", "Lần đầu tiên trong đêm, cái tên ấy thuộc về tôi."],
		])
		await dialogue.finished
		await ui.title_card("MINH", "Lần đầu tiên trong đêm, những giọng khác gọi đúng tên người giữ đèn")
		await ui.title_card("Minh đặt đèn xuống", "Phố không xám lại. Hoa đăng xuôi dòng trở về.")
	elif outcome == "costly_hope":
		await ui.fade_to(1.0, 3.0, Color(0.65, 0.75, 1.0))
		await ui.title_card("Một tiếng gọi mắc lại bên kia sông", "Người chèo đò mở bàn tay. Trong đó còn một đốm sáng chưa tắt.")
		await ui.title_card("Người giữ đèn đặt gánh xuống", "Phố sáng qua một đêm. Cái tên vẫn đang vượt sông trước bình minh.")
	else:
		await ui.fade_to(1.0, 2.0, Color(0.35, 0.38, 0.5))
		await ui.title_card("Nghi lễ hoàn tất", "Tất cả đèn trong phố sáng lên cùng một nhịp.")
		await ui.title_card("Rồi trời gần sáng", "Phố xám lại. Người giữ đèn vẫn cầm gánh ở đầu ngõ.")
	await ui.fade_to(1.0, 1.5, Color(0, 0, 0))
	await ui.roll_credits("Minh" if outcome == "release" else "Người giữ đèn")
	ui.show_win()
	await ui.fade_to(0.0, 1.5)
	state = State.WON


# ---------- input ----------
func _unhandled_input(event: InputEvent) -> void:
	# ESC đóng note panel (trước mọi handler khác)
	if _debug_note_panel and _debug_note_panel.visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_debug_note_submitted("")
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and _debug_mode and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if _debug_note_panel == null or not _debug_note_panel.visible:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if event is InputEventMouseMotion and free_cam and _debug_mode and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera.rotate_y(-event.relative.x * 0.003)
		camera.rotate(camera.global_basis.x.normalized(), -event.relative.y * 0.003)
		return
	if event is InputEventMouseMotion and first_person and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		fp_yaw -= event.relative.x * 0.0028
		fp_pitch = clampf(fp_pitch - event.relative.y * 0.0028, -1.15, 0.65)
		player.fp_yaw = fp_yaw
		return
	if event is InputEventMouseMotion and view_mode == View.THIRD and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		tp_yaw -= event.relative.x * 0.0028
		tp_pitch = clampf(tp_pitch + event.relative.y * 0.0028, -0.25, 0.95)
		return
	if memory_stall != null and memory_stall.active:
		return
	if dialogue.active:
		return
	if state == State.INTRO:
		if (event is InputEventKey and event.is_pressed()) or (event is InputEventMouseButton and event.is_pressed()):
			state = State.PLAY
			ui.hide_intro()
			if first_person:
				player.set_first_person(true)
				player.fp_yaw = fp_yaw
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
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
		elif event.keycode == KEY_V:
			view_mode = (view_mode + 1) % 3
			_apply_view_mode()
		elif event.keycode == KEY_M and state != State.INTRO and state != State.CUTSCENE and state != State.WON:
			_toggle_map()
		elif event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
		elif event.keycode == KEY_F11 and _debug_mode:
			free_cam = not free_cam
			if free_cam:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				print("free-fly ON  cam=%s" % str(camera.position.snapped(Vector3(0.1,0.1,0.1))))
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				print("free-fly OFF")
		elif event.keycode == KEY_F12:
			RenderingServer.frame_post_draw.connect(_take_debug_shot, CONNECT_ONE_SHOT)
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


func _apply_view_mode() -> void:
	first_person = view_mode == View.FIRST
	player.set_first_person(first_person)
	player.cam_relative = view_mode != View.FOLLOW
	if view_mode == View.THIRD:
		tp_yaw = player.facing_yaw      # bắt đầu sau lưng theo hướng đang quay
	var capture := view_mode == View.FIRST or view_mode == View.THIRD
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if capture else Input.MOUSE_MODE_VISIBLE
	ui.toast(["Góc nhìn thứ nhất", "Góc nhìn thứ ba", "Camera theo dõi"][view_mode])


# ---------- vòng lặp ----------
func _process(delta: float) -> void:
	if _debug_mode:
		if _debug_toast_timer > 0.0:
			_debug_toast_timer -= delta
			if _debug_toast_timer <= 0.0 and _debug_toast_lbl:
				_debug_toast_lbl.visible = false
	var _note_open := _debug_note_panel != null and _debug_note_panel.visible
	if free_cam and _debug_mode and not _note_open:
		var spd := 14.0 * delta
		if Input.is_key_pressed(KEY_SHIFT): spd *= 3.0
		var basis := camera.global_basis
		if Input.is_key_pressed(KEY_W): camera.global_position -= basis.z * spd
		if Input.is_key_pressed(KEY_S): camera.global_position += basis.z * spd
		if Input.is_key_pressed(KEY_A): camera.global_position -= basis.x * spd
		if Input.is_key_pressed(KEY_D): camera.global_position += basis.x * spd
		if Input.is_key_pressed(KEY_Q): camera.global_position -= Vector3.UP * spd
		if Input.is_key_pressed(KEY_E): camera.global_position += Vector3.UP * spd
		if _debug_pos_lbl:
			var cp := camera.position.snapped(Vector3(0.1, 0.1, 0.1))
			var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			_debug_pos_lbl.text = "cam %s  |  %s  |  ảnh tiếp: d%03d" % [
				str(cp),
				"[chuột BẮT - ESC để thả]" if captured else "[chuột TỰ DO - Click để nhìn]",
				_debug_shot_n + 1
			]
	_update_pixel3d_overlay()
	match state:
		State.PLAY:
			player.view_yaw = tp_yaw if view_mode == View.THIRD else fp_yaw
			player.update_move(delta, Callable(current_chapter(), "clamp_player"))
			player.set_near_house(world.near_house(player.position))
			if chapter_no == 1:
				world.update_zone_geo(player.position)
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


func _make_pixel3d_overlay() -> void:
	_pixel3d_layer = CanvasLayer.new()
	_pixel3d_layer.layer = -20
	add_child(_pixel3d_layer)
	_pixel3d_rect = ColorRect.new()
	_pixel3d_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pixel3d_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pixel3d_rect.color = Color.WHITE
	_pixel3d_mat = ShaderMaterial.new()
	_pixel3d_mat.shader = Pixel3DShader
	_pixel3d_rect.material = _pixel3d_mat
	_pixel3d_layer.add_child(_pixel3d_rect)
	_update_pixel3d_overlay()


func _update_pixel3d_overlay() -> void:
	if _pixel3d_rect == null:
		return
	_pixel3d_rect.visible = chapter_no == 1 and not _debug_mode


func _update_camera(delta: float) -> void:
	if free_cam:
		return
	var desired: Vector3
	var look: Vector3
	if state == State.PUZZLE and active_puzzle != null:
		var lp: Vector3 = active_puzzle.light_pos
		desired = lp + Vector3(-2.2, 0.9, 4.9)
		look = Vector3(lp.x, lp.y + 0.1, lp.z - 2.5)
	elif first_person and (state == State.PLAY or state == State.DIALOGUE):
		# góc nhìn thứ nhất: mắt ở đầu, lắc nhẹ theo nhịp bước — giữ nguyên cả khi thoại
		camera.position = player.position + Vector3(0, 1.56 + player._visual.position.y * 0.6, 0)
		camera.rotation = Vector3(fp_pitch, fp_yaw - PI, 0)
		return
	elif view_mode == View.THIRD and (state == State.PLAY or state == State.DIALOGUE):
		# góc nhìn thứ ba: camera sau lưng, xoay quanh bằng chuột, ngắm ngang vai
		var pivot := player.position + Vector3(0, tp_height, 0)
		var fwd := Vector3(sin(tp_yaw), 0, cos(tp_yaw))
		desired = pivot - fwd * (tp_dist * cos(tp_pitch)) + Vector3.UP * (tp_dist * sin(tp_pitch))
		var tt := 1.0 - pow(0.0001, delta)
		camera.position = camera.position.lerp(desired, tt)
		cam_look = cam_look.lerp(pivot, tt)
		camera.look_at(cam_look)
		return
	else:
		desired = player.position + Vector3(0, 3.2, 5.6)
		look = player.position + Vector3(0, 1.3, 0)
	var t := 1.0 - pow(0.001, delta)
	camera.position = camera.position.lerp(desired, t)
	cam_look = cam_look.lerp(look, t)
	if camera.position.distance_to(cam_look) > 0.05:
		camera.look_at(cam_look)


# ---------- bản đồ từ trên cao (phím M) ----------
func _toggle_map() -> void:
	if map_mode:
		# đóng: tween camera về sau lưng người chơi rồi thả cho _update_camera
		map_mode = false
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		var fp_restore := _pre_map_fp
		var tw := create_tween()
		tw.tween_property(camera, "position", player.position + Vector3(0, 3.2, 5.6), 0.4) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_callback(func():
			free_cam = false
			first_person = fp_restore
			player.set_first_person(first_person)
			if first_person:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		)
	else:
		# mở: tween lên y=70, chuyển orthographic khi đến nơi
		_pre_map_fp = first_person
		map_mode = true
		free_cam = true
		first_person = false
		player.set_first_person(false)
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var tw := create_tween()
		tw.tween_property(camera, "position", Vector3(0, 70, -22), 0.65) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_callback(func():
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			camera.size = 60.0
			camera.look_at(Vector3(0, 0, -22))
		)
		ui.toast("Bản đồ — nhấn M để đóng")


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
	free_cam = true
	player.position = Vector3(0, 0, 7)
	camera.position = Vector3(0.6, 1.7, 9.6)        # sau lưng Minh, nhìn XUÔI ngõ về phía quán nước
	camera.look_at(Vector3(-3.5, 0.9, -5.0))
	await get_tree().create_timer(0.8).timeout
	await _shot(dir + "/c1-alley.png")
	free_cam = false
	# phố Trần Phú — camera đặt dọc trục phố
	free_cam = true
	player.position = Vector3(-14, 0, 11)
	camera.position = Vector3(-4, 2.8, 11.2)
	camera.look_at(Vector3(-18, 1.2, 10.8))
	await get_tree().create_timer(1.0).timeout
	await _shot(dir + "/c1-street.png")
	player.position = Vector3(-31, 0, 11)
	camera.position = Vector3(-24, 2.4, 11.5)
	camera.look_at(Vector3(-40, 1.5, 11))
	await get_tree().create_timer(1.0).timeout
	await _shot(dir + "/c1-bridge-mist.png")
	free_cam = false
	# C1: câu đố bóng
	player.position = Vector3(3.2, 0, -14.8)
	var c1 = chapters[1]
	for pid in ["head", "wing_body", "tail_leg"]:
		c1.puzzle.collect_and_place_part(pid)
	enter_puzzle(c1.puzzle, "A / D — xoay đèn cho bóng Chim Lạc khớp hình mờ")
	for pid in c1.puzzle.part_angles.keys():
		c1.puzzle.set_part_angle(pid, 0.4)        # lệch — bóng chưa khớp
	await get_tree().create_timer(1.2).timeout
	await _shot(dir + "/c1-puzzle.png")
	for pid in c1.puzzle.part_angles.keys():
		c1.puzzle.set_part_angle(pid, 0.02)       # khớp — Chim Lạc rõ hình
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


# ---------- xem căn nhà ref-01 trên sân khấu trung tính (so với ảnh tham khảo) ----------
func _house_view() -> void:
	get_window().size = Vector2i(1280, 960)
	var dir := ProjectSettings.globalize_path("res://shots/house")
	DirAccess.make_dir_recursive_absolute(dir)
	state = State.PLAY
	ui.hide_intro()
	ui.visible = false
	free_cam = true
	# môi trường riêng giống ảnh ref: nền xám nhạt, nắng dịu đều, không sương
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.78, 0.79, 0.81)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.87, 0.92)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.ssao_enabled = true
	camera.environment = env
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.97, 0.9)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-38, -68, 0)
	add_child(sun)
	# sàn xám + căn nhà đặt xa khu phố
	var base := Vector3(0, 0, 120)
	var floor_mat := preload("res://scripts/build.gd").mat(Color(0.6, 0.6, 0.61), 0.95)
	var fl := MeshInstance3D.new()
	var fp := PlaneMesh.new()
	fp.size = Vector2(50, 50)
	fl.mesh = fp
	fl.material_override = floor_mat
	fl.position = base
	add_child(fl)
	preload("res://scripts/house01.gd").build(self, base, 0.0)
	# house02 đặt SÁT house01 (đúng 6m như phố liền kề) — soát khối thò qua biên
	var base2 := base + Vector3(0, 0, -6)
	preload("res://scripts/house02.gd").build(self, base2, 0.0)
	camera.fov = 38
	await get_tree().create_timer(1.2).timeout
	# chính diện như ref-01
	camera.position = base + Vector3(-15.5, 3.9, 0)
	camera.look_at(base + Vector3(1.5, 3.9, 0))
	await get_tree().create_timer(0.5).timeout
	await _shot(dir + "/front.png")
	# góc 3/4
	camera.position = base + Vector3(-11.5, 5.2, 7.5)
	camera.look_at(base + Vector3(1.8, 3.6, 0))
	await get_tree().create_timer(0.4).timeout
	await _shot(dir + "/quarter.png")
	# cận mái (bờ nóc + đầu cong)
	camera.position = base + Vector3(-7.5, 8.6, 3.0)
	camera.look_at(base + Vector3(2.4, 7.2, 0))
	await get_tree().create_timer(0.4).timeout
	await _shot(dir + "/roof.png")
	# cận cửa + tam cấp
	camera.position = base + Vector3(-5.5, 2.1, 1.6)
	camera.look_at(base + Vector3(0.4, 1.9, 0))
	await get_tree().create_timer(0.4).timeout
	await _shot(dir + "/door.png")
	# nhà bông gió (ref-02): chính diện + cận panel
	camera.position = base2 + Vector3(-14.0, 3.0, 0)
	camera.look_at(base2 + Vector3(1.5, 2.8, 0))
	await get_tree().create_timer(0.4).timeout
	await _shot(dir + "/front02.png")
	camera.position = base2 + Vector3(-3.0, 2.5, 2.7)
	camera.look_at(base2 + Vector3(0.3, 2.25, 1.95))
	await get_tree().create_timer(0.4).timeout
	await _shot(dir + "/breeze.png")
	# house03/04/05 trên sân khấu: chính diện + cận cửa từng mẫu (audit khe hở/đè khối)
	var stage3 := [
		[preload("res://scripts/house03.gd"), base + Vector3(0, 0, 12), "03"],
		[preload("res://scripts/house04.gd"), base + Vector3(0, 0, 18), "04"],
		[preload("res://scripts/house05.gd"), base + Vector3(10, 0, 6), "05"],
	]
	for hd in stage3:
		var hb: Vector3 = hd[1]
		hd[0].build(self, hb, 0.0)
		camera.position = hb + Vector3(-14.0, 3.4, 0)
		camera.look_at(hb + Vector3(1.5, 3.0, 0))
		await get_tree().create_timer(0.4).timeout
		await _shot(dir + "/front" + hd[2] + ".png")
		camera.position = hb + Vector3(-5.5, 2.1, 1.6)
		camera.look_at(hb + Vector3(0.4, 1.9, 0))
		await get_tree().create_timer(0.4).timeout
		await _shot(dir + "/door" + hd[2] + ".png")
	# cận BIÊN giáp ranh hai nhà liền kề — soát khối/khung trắng thò sang nhà bên
	camera.position = base + Vector3(-6.0, 2.6, -3.0)
	camera.look_at(base + Vector3(0.3, 2.4, -3.0))
	await get_tree().create_timer(0.4).timeout
	await _shot(dir + "/boundary12.png")
	camera.position = base + Vector3(-6.0, 3.0, 15.0)
	camera.look_at(base + Vector3(0.3, 2.8, 15.0))
	await get_tree().create_timer(0.4).timeout
	await _shot(dir + "/boundary34.png")
	# dàn đạo cụ phố trên sân khấu: xe đạp, xe Cub, chậu cây, bụi chuối (ref-07/08/09)
	var parts3 := preload("res://scripts/hoian_parts.gd")
	var pbase := base2 + Vector3(0, 0, -10)
	parts3.bicycle(self, pbase + Vector3(0, 0, 1.6), 0.0, -0.1)
	parts3.motorbike(self, pbase + Vector3(0, 0, -1.2), 0.0)
	for pk in range(4):
		parts3.pot_plant(self, pbase + Vector3(-1.5, 0, -3.2 + pk * 1.4), pk, 1.0)
	parts3.banana_clump(self, pbase + Vector3(1.6, 0, -4.8), 1.2)
	camera.position = pbase + Vector3(-8.2, 2.4, -1.6)
	camera.look_at(pbase + Vector3(1.2, 0.7, -1.6))
	await get_tree().create_timer(0.4).timeout
	await _shot(dir + "/props.png")
	# phố ban ngày: nhà ban công house03 (x=-21), nhà sân thượng house04 (x=-15), toàn cảnh
	camera.position = Vector3(-18.2, 3.2, 9.4)
	camera.look_at(Vector3(-21.0, 3.4, 14.4))
	await get_tree().create_timer(0.4).timeout
	await _shot(dir + "/balcony.png")
	camera.position = Vector3(-11.7, 5.6, 8.6)
	camera.look_at(Vector3(-15.0, 4.3, 14.4))
	await get_tree().create_timer(0.4).timeout
	await _shot(dir + "/terrace.png")
	camera.position = Vector3(2.0, 2.4, 9.0)
	camera.look_at(Vector3(-20.0, 2.6, 13.8))
	await get_tree().create_timer(0.4).timeout
	await _shot(dir + "/street.png")
	# ---- đêm ngoài phố: Minh bước lên tam cấp căn ref-01 và CẤT ĐÈN ----
	sun.visible = false
	camera.environment = null
	player.position = Vector3(-5.0, 0, 12.7)
	await get_tree().create_timer(1.8).timeout
	camera.position = Vector3(-8.4, 2.7, 10.3)
	camera.look_at(Vector3(-5.0, 1.6, 13.6))
	await get_tree().create_timer(0.3).timeout
	await _shot(dir + "/night-steps.png")
	player.position = Vector3(-5.0, 0.78, 14.05)
	await get_tree().create_timer(1.4).timeout
	camera.position = Vector3(-1.6, 3.0, 11.0)
	camera.look_at(Vector3(-5.0, 1.9, 14.2))
	await get_tree().create_timer(0.3).timeout
	await _shot(dir + "/night-door.png")
	print("houseview ground: street=", world.ground_height(Vector3(-5, 0, 12.0)),
		" steps=", world.ground_height(Vector3(-3, 0, 13.5)),
		" plinth=", world.ground_height(Vector3(-5, 0, 14.15)))
	# Phase 2: phố Nguyễn Thái Học + Lê Lợi/HVT — nhìn về phía Nam
	# Lê Lợi từ trên: camera ở z=14 nhìn xuống phía nam dọc ngõ dọc
	camera.position = Vector3(-19.0, 7.5, 14.0)
	camera.look_at(Vector3(-19.0, 2.0, -10.0))
	await get_tree().create_timer(0.5).timeout
	await _shot(dir + "/p2-lelli.png")
	# NTH chính diện từ phía Bắc: camera đứng phía bắc NTH nhìn vào mặt tiền north row
	camera.position = Vector3(-18.0, 4.5, -22.0)
	camera.look_at(Vector3(-18.0, 3.0, -31.5))
	await get_tree().create_timer(0.5).timeout
	await _shot(dir + "/p2-nth.png")
	# Phase 3: Bạch Đằng bắc ngạn + sông Hoài rộng
	# nhìn từ phía Bắc Bạch Đằng xuống bờ sông
	camera.position = Vector3(-22.0, 5.8, -41.5)
	camera.look_at(Vector3(-22.0, 1.5, -60.0))
	await get_tree().create_timer(0.6).timeout
	await _shot(dir + "/p3-bach-dang.png")
	# thuyền + dây đèn qua sông từ phía Đông
	camera.position = Vector3(36.0, 6.5, -63.0)
	camera.look_at(Vector3(0.0, 0.8, -64.5))
	await get_tree().create_timer(0.6).timeout
	await _shot(dir + "/p3-river.png")
	# Phase 4: Chùa Cầu thật — nhìn từ Đông (Trần Phú) qua mist về phía Tây
	camera.position = Vector3(-29.0, 5.5, 14.5)
	camera.look_at(Vector3(-46.0, 2.5, 11.0))
	await get_tree().create_timer(0.6).timeout
	await _shot(dir + "/p4-chua-cau-east.png")
	# nhìn dọc từ bên cầu tàu (Nam nhìn lên cầu)
	camera.position = Vector3(-46.0, 4.5, 5.5)
	camera.look_at(Vector3(-46.0, 2.0, 11.5))
	await get_tree().create_timer(0.5).timeout
	await _shot(dir + "/p4-chua-cau-south.png")
	# Phase 5: Chợ Hội An — nhìn từ Nam vào nhà lồng
	camera.position = Vector3(-20.0, 6.5, 18.0)
	camera.look_at(Vector3(-20.0, 3.0, 26.0))
	await get_tree().create_timer(0.6).timeout
	await _shot(dir + "/p5-cho-hoi-an.png")
	# Hội quán Phúc Kiến (đỏ son) nhìn chính diện từ Nam
	camera.position = Vector3(30.0, 5.5, 8.0)
	camera.look_at(Vector3(30.0, 2.5, 14.5))
	await get_tree().create_timer(0.6).timeout
	await _shot(dir + "/p5-phuc-kien.png")
	# Hội quán Quảng Đông (cam vàng) nhìn chính diện
	camera.position = Vector3(18.0, 5.5, 8.0)
	camera.look_at(Vector3(18.0, 2.5, 14.5))
	await get_tree().create_timer(0.5).timeout
	await _shot(dir + "/p5-quang-dong.png")
	# Phase 6: Cầu An Hội từ bờ bắc nhìn xuống
	camera.position = Vector3(22.0, 8.0, -50.0)
	camera.look_at(Vector3(22.0, 1.0, -67.0))
	await get_tree().create_timer(0.6).timeout
	await _shot(dir + "/p6-bridge.png")
	# Chợ đêm bờ nam — nhìn từ sông về
	camera.position = Vector3(0.0, 7.5, -76.0)
	camera.look_at(Vector3(0.0, 2.5, -89.0))
	await get_tree().create_timer(0.6).timeout
	await _shot(dir + "/p6-cho-dem.png")
	# Phase 7: chụp đúng trạng thái sau light_up — đèn lồng sáng, zone geo theo chân Minh,
	# đèn sào của Minh là nguồn sáng chính từng khung
	world.light_up()
	# thềm đá nâng ref-10 dọc dãy Bắc — Minh đứng giữa lòng đường (z=11: ngoài rìa
	# near_house để đèn không bị che), góc thấp thấy bậc + chậu trên thềm
	player.position = Vector3(-18.0, 0, 11.0)
	camera.position = Vector3(-13.5, 1.5, 11.2)
	camera.look_at(Vector3(-21.0, 0.9, 14.0))
	await get_tree().create_timer(1.4).timeout
	await _shot(dir + "/p7-sidewalk.png")
	# ngõ hẹp khu cầu — từ phố nhìn qua cổng hẹp, Minh đã lách vào trong hành lang
	player.position = Vector3(-40.0, 0, 10.3)
	camera.position = Vector3(-34.5, 2.1, 11.0)
	camera.look_at(Vector3(-41.5, 1.6, 11.0))
	await get_tree().create_timer(1.4).timeout
	await _shot(dir + "/p7-ngo-hep.png")
	# trong hành lang nhìn ra chân cầu + tượng linh thú (zone ngo_cau — sương đặc)
	camera.position = Vector3(-38.9, 1.7, 11.0)
	camera.look_at(Vector3(-43.0, 1.5, 11.4))
	await get_tree().create_timer(0.6).timeout
	await _shot(dir + "/p7-chan-cau.png")
	# Phase 8: giao lộ Tây Trần Phú→Lê Lợi — nhìn từ phố xuống miệng giao lộ mở
	player.position = Vector3(-20.5, 0, 4.5)
	camera.position = Vector3(-20.3, 2.7, 10.5)
	camera.look_at(Vector3(-19.5, 0.9, -3.0))
	await get_tree().create_timer(1.4).timeout
	await _shot(dir + "/p8-giao-lo.png")
	# nhà tàn tích lot -21 hàng NTH Bắc — Minh đứng giữa lối xuyên
	player.position = Vector3(-21.0, 0, -26.0)
	camera.position = Vector3(-18.6, 2.1, -23.2)
	camera.look_at(Vector3(-21.8, 1.0, -28.0))
	await get_tree().create_timer(1.2).timeout
	await _shot(dir + "/p8-tan-tich.png")
	# bờ sông Hoài — camera giữa bến đá trống (z -48..-52, né thân nhà Bạch Đằng)
	player.position = Vector3(-19.0, 0, -50.5)
	camera.position = Vector3(-26.0, 2.8, -49.5)
	camera.look_at(Vector3(-14.0, 0.6, -51.5))
	await get_tree().create_timer(1.4).timeout
	await _shot(dir + "/p8-bo-song.png")
	# Phase 9: reality rebuild QA — bật ánh sáng ban ngày tạm thời để đánh giá màu + silhouette
	camera.environment = env
	var qa_sun := DirectionalLight3D.new()
	qa_sun.light_color = Color(1.0, 0.97, 0.90)
	qa_sun.light_energy = 2.4
	qa_sun.shadow_enabled = false
	qa_sun.rotation_degrees = Vector3(-50, -35, 0)
	add_child(qa_sun)
	var qa_fill := DirectionalLight3D.new()
	qa_fill.light_color = Color(0.72, 0.82, 1.0)
	qa_fill.light_energy = 0.9
	qa_fill.rotation_degrees = Vector3(-25, 145, 0)
	add_child(qa_fill)
	await get_tree().create_timer(0.5).timeout
	# Chùa Cầu: camera phải ở PHÍA TÂY mist-wall x=-39 (bridge ở x=-46, mist chặn x>-39).
	# Góc Tây-Nam: camera tại x=-51 z=3 — nhìn Đông-Bắc, thấy profile cầu + trụ đá + mái
	player.position = Vector3(-46.0, 0, 9.5)   # player sát cầu → lantern sáng cầu
	# Profile Tây-Nam xa hơn (x=-60) + thấp (y=3) để thấy trụ đá dưới mực nước + full roof arc
	camera.position = Vector3(-60.0, 3.5, 4.0)
	camera.look_at(Vector3(-46.0, 1.8, 11.0))
	await get_tree().create_timer(1.4).timeout
	await _shot(dir + "/p9-chua-cau-sw.png")
	# Cầu từ trong ngõ hẹp (x=-41 đã qua mist) — thấy entry pavilion + entrance corridor
	camera.position = Vector3(-41.0, 2.5, 8.0)
	camera.look_at(Vector3(-46.5, 1.6, 11.0))
	await get_tree().create_timer(0.7).timeout
	await _shot(dir + "/p9-chua-cau-entry.png")
	# Chợ arcade: từ đầu Đông, nhìn dọc arcade về phía Tây — thấy nhịp arcade + awning
	player.position = Vector3(-5.0, 0, 22.0)
	# Đầu Đông, lùi ra 4m để thấy cả chiều sâu arcade + awning
	camera.position = Vector3(4.0, 3.2, 23.0)
	camera.look_at(Vector3(-20.0, 2.5, 23.5))
	await get_tree().create_timer(1.0).timeout
	await _shot(dir + "/p9-cho-corner.png")
	# Mặt tiền Nam: fov rộng hơn để thấy nhiều arcade bays hơn
	camera.fov = 65
	camera.position = Vector3(-20.0, 2.8, 20.0)
	camera.look_at(Vector3(-20.0, 3.2, 23.5))
	await get_tree().create_timer(0.7).timeout
	await _shot(dir + "/p9-cho-facade.png")
	# Quảng Đông chính diện + Phúc Kiến so màu: player gần để lantern chiếu
	player.position = Vector3(24.0, 0, 10.0)
	camera.position = Vector3(18.0, 4.5, 6.5)
	camera.look_at(Vector3(18.0, 2.5, 14.5))
	await get_tree().create_timer(1.2).timeout
	await _shot(dir + "/p9-quang-dong.png")
	camera.position = Vector3(30.0, 4.5, 6.5)
	camera.look_at(Vector3(30.0, 2.5, 14.5))
	await get_tree().create_timer(0.7).timeout
	await _shot(dir + "/p9-phuc-kien.png")
	print("HOUSEVIEW DONE")
	get_tree().quit()


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("shot: ", path)


func _take_debug_shot() -> void:
	_debug_shot_n += 1
	var path := _debug_dir + "/d%03d.png" % _debug_shot_n
	get_viewport().get_texture().get_image().save_png(path)
	var cp := camera.position
	var look := -camera.global_basis.z
	var entry := {
		"n": _debug_shot_n,
		"file": "d%03d.png" % _debug_shot_n,
		"cam": [snappedf(cp.x, 0.1), snappedf(cp.y, 0.1), snappedf(cp.z, 0.1)],
		"look": [snappedf(look.x, 0.01), snappedf(look.y, 0.01), snappedf(look.z, 0.01)],
		"note": ""
	}
	_debug_session.append(entry)
	_debug_note_idx = _debug_session.size() - 1
	print("DEBUG d%03d  cam=%s  look=%s" % [_debug_shot_n, str(cp.snapped(Vector3(0.1,0.1,0.1))), str(look.snapped(Vector3(0.01,0.01,0.01)))])
	# Toast xác nhận
	if _debug_toast_lbl:
		_debug_toast_lbl.text = "✓ d%03d.png — nhập ghi chú bên dưới (hoặc ESC bỏ qua)" % _debug_shot_n
		_debug_toast_lbl.visible = true
		_debug_toast_timer = 6.0
	# Mở note panel
	if _debug_note_panel and _debug_note_edit:
		var lbl: Label = _debug_note_panel.get_node("NoteLbl")
		lbl.text = "Ghi chú cho d%03d  [cam: (%.1f, %.1f, %.1f)  look: (%.2f, %.2f, %.2f)]" % [
			_debug_shot_n, cp.x, cp.y, cp.z, look.x, look.y, look.z]
		_debug_note_edit.text = ""
		_debug_note_panel.visible = true
		_debug_note_edit.grab_focus()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_debug_note_submitted(text: String) -> void:
	if _debug_note_idx >= 0 and _debug_note_idx < _debug_session.size():
		_debug_session[_debug_note_idx]["note"] = text.strip_edges()
	if _debug_note_panel:
		_debug_note_panel.visible = false
	_debug_save_session()
	# Khôi phục capture nếu đang ở free fly
	if free_cam and _debug_mode:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _debug_save_session() -> void:
	var f := FileAccess.open(_debug_dir + "/session.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_debug_session, "\t"))
		f.close()


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
	await _wait_dialogue_only()
	for id in MemoryStallInspectUI.REQUIRED_FOR_KEY:
		memory_stall.inspect_item(id)
	memory_stall._take_key()
	memory_stall.close_panel()
	await _wait_dialogue()
	assert(c1.has_house_key)
	c1._try_descend()
	await _wait_dialogue()
	assert(chapter_no == 1)
	c1._try_unlock_house()
	await _wait_dialogue()
	assert(c1.house_unlocked)
	c1._try_descend()
	await _wait_dialogue()
	assert(chapter_no == 1)
	for id in ["head", "wing_body", "tail_leg"]:
		c1._collect_stencil_part(id)
	enter_puzzle(c1.puzzle, "")
	c1.puzzle.debug_solve()
	await _until(func(): return c1.puzzle.solved, "c1 puzzle")
	await _until(func(): return state == State.PLAY, "c1 exit puzzle")
	c1._take_hoa()
	await _wait_dialogue()
	player.set_color("hoa")
	c1._try_burn()
	await _wait_dialogue()
	assert(c1.basement_open)
	player.position = Vector3(0, 0, -23.5)
	await get_tree().create_timer(0.5).timeout
	assert(chapter_no == 1)
	player.position = c1._basement_pos
	c1._try_descend()
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
	assert(c2.quest_stage == 1)
	chapters[1]._talk_ba()      # bà kể sự tích giếng → cần sen giấy
	await _wait_dialogue()
	assert(c2.quest_stage == 2)
	chapters[1]._hoa_dang_stall()  # lấy sen từ gánh hoa đăng
	await _wait_dialogue()
	assert(c2.quest_stage == 3)
	c2._offer_lotus()           # trả lễ — vệt nước dẫn đường, cổng mở
	await _wait_dialogue()
	assert(c2.quest_stage == 4)
	player.position = Vector3(0, 0, -43.0)
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
	if narrative.name_kept != true:
		push_error("FLOW FAILED: auto dialogue choice did not persist c4_crossing_price")
		get_tree().quit(1)
		return
	if narrative.ending_key() != "loop":
		push_error("FLOW FAILED: before C5 verification, prototype must remain loop-eligible")
		get_tree().quit(1)
		return
	var c5 = chapters[5]
	await _until(func(): return c5.fight_active, "xác minh cuối bắt đầu", 30.0)
	await _wait_dialogue()
	for ph in range(c5.PROOFS.size()):
		player.set_color(c5.PROOFS[ph]["weak"])
		var t := 0.0
		while c5.phase == ph and not c5.defeated and t < 25.0:
			player.position = c5._boss.position + Vector3(3.0, 0, 0)
			player.position.y = 40
			await get_tree().create_timer(0.1).timeout
			t += 0.1
		if c5.phase == ph and not c5.defeated:
			push_error("FLOW TIMEOUT: c5 proof %d" % ph)
			get_tree().quit(1)
			return
		await _wait_dialogue()
	if narrative.ending_key() != "release":
		push_error("FLOW FAILED: verified C5 should unlock release ending, got %s" % narrative.ending_key())
		get_tree().quit(1)
		return
	await _until(func(): return state == State.WON, "ending + credits", 60.0)
	print("FLOW OK — het 5 chuong, choice persisted, outcome=", narrative.ending_key())
	get_tree().quit()


func _wait_dialogue() -> void:
	await get_tree().create_timer(0.4).timeout
	while dialogue.active or (memory_stall != null and memory_stall.active):
		await get_tree().create_timer(0.1).timeout


func _wait_dialogue_only() -> void:
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
