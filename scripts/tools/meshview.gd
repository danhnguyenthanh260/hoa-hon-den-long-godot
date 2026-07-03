# Xem nhanh 1 mesh glb tĩnh (chưa rig): chụp front/side/3-4 view.
# Chạy: ...turntable... res://scenes/meshview.tscn -- <duong_dan_glb>
extends Node3D


func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.64, 0.66)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.62)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-45), deg_to_rad(30), 0)
	key.light_energy = 1.4
	add_child(key)

	var ua := OS.get_cmdline_user_args()
	var path := "res://assets/models/minh_apose_0.glb"
	for a in ua:
		if a.ends_with(".glb"):
			path = a if a.begins_with("res://") else "res://" + a
	var model := (load(path) as PackedScene).instantiate()
	add_child(model)

	# chuẩn hoá cao 1.7, đặt chân chạm y=0
	var lo := Vector3(1e9, 1e9, 1e9)
	var hi := -lo
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var ab: AABB = mi.get_aabb()
		var g: Transform3D = mi.global_transform
		for ci in range(8):
			var p: Vector3 = g * ab.get_endpoint(ci)
			lo = lo.min(p)
			hi = hi.max(p)
	var h := hi.y - lo.y
	var s := 1.7 / maxf(h, 0.01)
	model.scale = Vector3(s, s, s)
	model.position = Vector3(-(lo.x + hi.x) * 0.5 * s, -lo.y * s, -(lo.z + hi.z) * 0.5 * s)

	var cam := Camera3D.new()
	cam.fov = 45.0
	add_child(cam)

	var dir := ProjectSettings.globalize_path("res://shots/qa/meshview")
	DirAccess.make_dir_recursive_absolute(dir)
	var views := {"front": 0.0, "q34": PI * 0.25, "side": PI * 0.5, "back": PI}
	await get_tree().process_frame
	for name in views:
		model.rotation.y = views[name]
		cam.position = Vector3(0, 0.9, 3.0)
		cam.look_at(Vector3(0, 0.85, 0))
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png(dir + "/%s.png" % name)
	print("MESHVIEW XONG -> ", dir)
	get_tree().quit()
