# Hồn dân phố đã phai — mesh AI được auto-rig (rig_glb.py), bước đi chậm rãi
# theo waypoint, một tay vẫn giữ vành nón như ngày họ còn sống.
extends Node3D

const BONE_NAMES := ["hips", "spine", "chest", "head", "thighL", "shinL", "footL", "thighR", "shinR", "footR"]

var speed := 0.55
var waypoints: Array = []
var _wp := 0
var _t := 0.0
var _skel: Skeleton3D
var _bones := {}
var _base_y := 0.0


func setup(path: String, height: float, pts: Array) -> void:
	waypoints = pts
	var scene := load(path)
	if scene == null:
		return
	var inst: Node3D = scene.instantiate()
	add_child(inst)
	# chất ma: trắng mờ phát sáng nhẹ, không đổ bóng
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.85, 0.9, 1.0, 0.5)
	gm.emission_enabled = true
	gm.emission = Color(0.5, 0.6, 0.95)
	gm.emission_energy_multiplier = 0.45
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var aabb := AABB()
	var first := true
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var a: AABB = mi.global_transform * mi.get_aabb()
		aabb = a if first else aabb.merge(a)
		first = false
		mi.material_override = gm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not first:
		var k := height / aabb.size.y
		inst.scale = Vector3.ONE * k
		inst.position.y = -(aabb.position.y - global_position.y) * k
	var skels := inst.find_children("*", "Skeleton3D", true, false)
	if skels.size() > 0:
		_skel = skels[0]
		for n in BONE_NAMES:
			_bones[n] = _skel.find_bone(n)
	if waypoints.size() > 0:
		position = waypoints[0]
	_base_y = position.y


func _process(delta: float) -> void:
	_t += delta * 3.0
	if waypoints.size() > 1:
		var target: Vector3 = waypoints[_wp]
		var d := target - position
		d.y = 0
		if d.length() < 0.35:
			_wp = (_wp + 1) % waypoints.size()
		else:
			position += d.normalized() * speed * delta
			rotation.y = lerp_angle(rotation.y, atan2(d.x, d.z) + PI, 1.0 - pow(0.01, delta))
	position.y = _base_y + absf(sin(_t)) * 0.025
	if _skel == null:
		return
	var sw := sin(_t) * 0.38
	_pose("thighL", sw)
	_pose("thighR", -sw)
	_pose("shinL", maxf(0.0, sin(_t - 0.7)) * 0.6)
	_pose("shinR", maxf(0.0, sin(_t - 0.7 + PI)) * 0.6)
	_pose("spine", sin(_t * 2.0) * 0.025)
	_pose("head", sin(_t * 0.5) * 0.04)


func _pose(bone: String, ang: float) -> void:
	var idx: int = _bones.get(bone, -1)
	if idx >= 0:
		_skel.set_bone_pose_rotation(idx, Quaternion(Vector3.RIGHT, ang))
