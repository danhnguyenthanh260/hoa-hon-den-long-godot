extends SceneTree

const BirdStencilPuzzle := preload("res://scripts/bird_stencil_puzzle.gd")

var failures: Array[String] = []
var callback_seen := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var puzzle := BirdStencilPuzzle.new()
	root.add_child(puzzle)
	puzzle.setup(Vector3(0, 1.2, 0), -2.0)
	puzzle.solved_callback = func() -> void:
		callback_seen = true
	await process_frame

	_check(puzzle.required_part_count() == 3, "puzzle must require exactly three stencil parts")
	puzzle.collect_and_place_part("head")
	puzzle.set_part_angle("head", 0.0)
	_check(not puzzle.complete_if_ready(), "puzzle solved with only head part")
	puzzle.collect_and_place_part("wing_body")
	puzzle.set_part_angle("wing_body", 0.0)
	puzzle.collect_and_place_part("tail_leg")
	puzzle.set_part_angle("tail_leg", 0.50)
	_check(not puzzle.complete_if_ready(), "puzzle solved with misaligned tail/leg layer")
	puzzle.set_part_angle("tail_leg", 0.0)
	_check(puzzle.complete_if_ready(), "puzzle did not solve after all three layers aligned")
	_check(callback_seen, "solved callback was not called")
	puzzle.queue_free()

	if failures.is_empty():
		print("BIRD STENCIL PUZZLE OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
