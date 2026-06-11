# Vòng lặp game + máy trạng thái: intro -> play -> puzzle -> won.
# Chạy với "-- --autoplay" để bot tự chơi qua game và chụp screenshot vào res://shots/.
extends Node3D

const GameWorld := preload("res://scripts/world.gd")
const PlayerCharacter := preload("res://scripts/player.gd")
const LanternPuzzle := preload("res://scripts/puzzle.gd")
const GameUI := preload("res://scripts/game_ui.gd")

enum State { INTRO, PLAY, PUZZLE, WON }

const WALK_CAM_OFFSET := Vector3(0, 3.2, 5.6)
const PUZZLE_CAM_POS := Vector3(1.6, 2.4, -12.4)
const PUZZLE_LOOK := Vector3(3.2, 1.7, -20)
const WIN_CAM_POS := Vector3(0, 1.7, -21.2)
const WIN_LOOK := Vector3(0, 0.2, -29.5)
const INTERACT_DIST := 2.8

var state: int = State.INTRO
var world: Node3D
var player: Node3D
var puzzle: Node3D
var ui: CanvasLayer
var camera: Camera3D
var cam_look := Vector3(0, 1.3, 7)


func _ready() -> void:
	world = GameWorld.new()
	add_child(world)
	player = PlayerCharacter.new()
	add_child(player)
	player.position = Vector3(0, 0, 7)
	puzzle = LanternPuzzle.new()
	puzzle.solved_callback = Callable(self, "_on_solved")
	add_child(puzzle)
	ui = GameUI.new()
	add_child(ui)
	camera = Camera3D.new()
	camera.fov = 60
	add_child(camera)
	camera.position = Vector3(0, 3.4, 13)
	camera.current = true
	if OS.get_cmdline_user_args().has("--autoplay"):
		_autoplay()


func _unhandled_input(event: InputEvent) -> void:
	if state == State.INTRO:
		var clicked: bool = event is InputEventMouseButton and event.is_pressed()
		var keyed: bool = event is InputEventKey and event.is_pressed()
		if clicked or keyed:
			_start()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_interact()
		elif event.keycode == KEY_R and state == State.WON:
			get_tree().reload_current_scene()


func _start() -> void:
	if state != State.INTRO:
		return
	state = State.PLAY
	ui.hide_intro()


func _interact() -> void:
	if state == State.PLAY and not puzzle.solved and player.position.distance_to(puzzle.stand_pos()) < INTERACT_DIST:
		state = State.PUZZLE
		puzzle.active = true
		ui.show_prompt(false)
		ui.show_hint(true)
	elif state == State.PUZZLE and not puzzle.solved:
		state = State.PLAY
		puzzle.active = false
		ui.show_hint(false)


func _on_solved() -> void:
	ui.play_chime()
	ui.show_hint(false)
	ui.toast("Ký ức đã được thắp sáng! Cánh cổng đang mở...")
	world.open_gate()
	world.light_up()
	await get_tree().create_timer(1.8).timeout
	if state == State.PUZZLE:
		state = State.PLAY
	puzzle.active = false


func _process(delta: float) -> void:
	match state:
		State.PLAY:
			player.update_move(delta, Callable(world, "clamp_player"))
			var near: bool = not puzzle.solved and player.position.distance_to(puzzle.stand_pos()) < INTERACT_DIST
			ui.show_prompt(near)
			if player.position.z < -22.5:
				state = State.WON
				ui.show_win()
		State.PUZZLE:
			puzzle.update_puzzle(delta)
	world.update_world(delta)
	_update_camera(delta)


func _update_camera(delta: float) -> void:
	var desired: Vector3
	var look: Vector3
	if state == State.PUZZLE:
		desired = PUZZLE_CAM_POS
		look = PUZZLE_LOOK
	elif state == State.WON:
		desired = WIN_CAM_POS
		look = WIN_LOOK
	else:
		desired = player.position + WALK_CAM_OFFSET
		look = player.position + Vector3(0, 1.3, 0)
	var t := 1.0 - pow(0.001, delta)
	camera.position = camera.position.lerp(desired, t)
	cam_look = cam_look.lerp(look, t)
	camera.look_at(cam_look)


# ---- bot tự chơi + chụp màn hình để kiểm tra hình ảnh ----

func _autoplay() -> void:
	var dir := ProjectSettings.globalize_path("res://shots")
	DirAccess.make_dir_recursive_absolute(dir)
	await get_tree().create_timer(1.2).timeout
	await _shot(dir + "/01-intro.png")
	_start()
	await get_tree().create_timer(1.0).timeout
	await _shot(dir + "/02-alley.png")
	player.position = Vector3(3.2, 0, -14.8)
	await get_tree().create_timer(0.8).timeout
	await _shot(dir + "/03-near-lantern.png")
	_interact()
	await get_tree().create_timer(1.4).timeout
	await _shot(dir + "/04-puzzle.png")
	puzzle.angle = 0.4
	await get_tree().create_timer(0.4).timeout
	await _shot(dir + "/04b-shadow-near.png")
	puzzle.angle = 0.05
	await get_tree().create_timer(1.0).timeout
	await _shot(dir + "/05-solved.png")
	await get_tree().create_timer(2.5).timeout
	await _shot(dir + "/06-gate-open.png")
	player.position = Vector3(0, 0, -21.0)
	await get_tree().create_timer(0.8).timeout
	await _shot(dir + "/06b-river.png")
	player.position = Vector3(0, 0, -23.0)
	await get_tree().create_timer(0.8).timeout
	await _shot(dir + "/07-win.png")
	print("AUTOPLAY DONE state=", state, " solved=", puzzle.solved)
	get_tree().quit()


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("shot: ", path)
