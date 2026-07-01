# Vũng nước/giếng phản chiếu bằng camera gương thật trong SubViewport (dùng chung
# World3D, không dựng lại môi trường). Người chơi bị loại khỏi ảnh phản chiếu qua
# render layer riêng — xem player.gd REFLECTION_EXCLUDE_LAYER_BIT (phải khớp giá trị).
extends Node3D

const REFLECTION_EXCLUDE_LAYER_BIT := 2

var _viewport: SubViewport
var _cam: Camera3D
var _main_camera: Camera3D
var _mirror_y := 0.0
var _delay_frames := 0
var _history: Array[Vector3] = []


func setup(main_camera: Camera3D, mirror_world_y: float, size := Vector2i(512, 512), delay_frames := 0) -> void:
	_main_camera = main_camera
	_mirror_y = mirror_world_y
	_delay_frames = delay_frames
	_viewport = SubViewport.new()
	_viewport.size = size
	_viewport.own_world_3d = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	_cam = Camera3D.new()
	_cam.cull_mask = ((1 << 20) - 1) & ~(1 << (REFLECTION_EXCLUDE_LAYER_BIT - 1))
	_cam.current = false
	_viewport.add_child(_cam)


func texture() -> ViewportTexture:
	return _viewport.get_texture()


func update(_delta: float) -> void:
	if _main_camera == null or _cam == null:
		return
	var origin: Vector3 = _main_camera.global_position
	var mirrored_origin := Vector3(origin.x, 2.0 * _mirror_y - origin.y, origin.z)
	var look_dir: Vector3 = -_main_camera.global_transform.basis.z
	var mirrored_look_dir := Vector3(look_dir.x, -look_dir.y, look_dir.z)
	var applied_origin := mirrored_origin
	if _delay_frames > 0:
		_history.append(mirrored_origin)
		if _history.size() > _delay_frames + 1:
			_history.pop_front()
		applied_origin = _history[0]
	_cam.global_position = applied_origin
	var up := Vector3.UP if absf(mirrored_look_dir.normalized().y) < 0.95 else Vector3.RIGHT
	_cam.look_at_from_position(applied_origin, applied_origin + mirrored_look_dir, up)
