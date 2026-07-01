extends SceneTree

const ReflectionPool := preload("res://scripts/reflection_pool.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_cam := Camera3D.new()
	root.add_child(main_cam)
	var pool := ReflectionPool.new()
	root.add_child(pool)
	await process_frame
	pool.setup(main_cam, 0.5, Vector2i(64, 64), 3)

	var expected_mask: int = ((1 << 20) - 1) & ~(1 << (ReflectionPool.REFLECTION_EXCLUDE_LAYER_BIT - 1))
	_check(pool._cam.cull_mask == expected_mask, "reflection camera cull_mask does not exclude player layer")
	_check(pool.texture() != null, "reflection pool did not produce a viewport texture")

	main_cam.global_position = Vector3(0, 2.0, 0)
	pool.update(0.016)
	main_cam.global_position = Vector3(1, 2.0, 0)
	pool.update(0.016)
	main_cam.global_position = Vector3(2, 2.0, 0)
	pool.update(0.016)
	main_cam.global_position = Vector3(3, 2.0, 0)
	pool.update(0.016)
	_check(pool._cam.global_position.x < main_cam.global_position.x, "delayed reflection camera did not lag behind main camera")
	_check(is_equal_approx(pool._cam.global_position.y, 2.0 * 0.5 - 2.0), "reflection camera did not mirror around water plane Y")

	main_cam.queue_free()
	pool.queue_free()
	if failures.is_empty():
		print("REFLECTION POOL OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
