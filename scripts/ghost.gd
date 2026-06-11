# Hồn Ma Phai Nhạt — một khoảng người bị xóa, nuốt ánh sáng quanh nó.
# Sợ một màu khắc nó: chiếu đúng màu trong tầm thì nó tan đi một lúc.
extends Node3D

const Build := preload("res://scripts/build.gd")

var weak_color := "hoa"
var home := Vector3.ZERO
var caught_callback: Callable    # gọi khi chạm người chơi
var player: Node3D

var _time := 0.0
var _dissolved := 0.0
var _blobs: Array = []
var _neg_light: OmniLight3D


func setup(p_home: Vector3, p_weak: String, p_player: Node3D, p_caught: Callable) -> void:
	home = p_home
	weak_color = p_weak
	player = p_player
	caught_callback = p_caught
	position = home

	var void_mat := StandardMaterial3D.new()
	void_mat.albedo_color = Color(0.01, 0.005, 0.02, 0.88)
	void_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	void_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(5):
		var b := Build.ball(self, 0.22 + 0.06 * (i % 3), 0.5 + 0.1 * (i % 2),
			Vector3(sin(i * 2.1) * 0.14, 0.5 + i * 0.22, cos(i * 1.7) * 0.1), void_mat)
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_blobs.append(b)
	# đốm tím lập lòe quanh nó — thứ duy nhất cho biết nó ở đâu
	for i in range(4):
		var spark := Build.ball(self, 0.025, 0.05,
			Vector3(sin(i * 1.6) * 0.45, 0.6 + i * 0.3, cos(i * 1.6) * 0.45),
			Build.emis(Color(0.6, 0.3, 0.9), Color(0.55, 0.25, 0.95), 2.2))
		spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rim := OmniLight3D.new()
	rim.light_color = Color(0.45, 0.2, 0.8)
	rim.light_energy = 0.5
	rim.omni_range = 3.0
	rim.position.y = 0.9
	add_child(rim)

	# nó NUỐT ánh sáng — đèn âm
	_neg_light = OmniLight3D.new()
	_neg_light.light_color = Color(1, 1, 1)
	_neg_light.light_energy = 1.6
	_neg_light.light_negative = true
	_neg_light.omni_range = 4.0
	_neg_light.position.y = 0.9
	add_child(_neg_light)


func _process(delta: float) -> void:
	_time += delta
	if _dissolved > 0.0:
		_dissolved -= delta
		visible = false
		if _dissolved <= 0.0:
			visible = true
			position = home
		return
	if player == null:
		return
	var to_player := player.position - position
	to_player.y = 0
	var d := to_player.length()
	# bị chiếu đúng màu khắc -> tan
	if d < 5.0 and player.current_color == weak_color:
		_dissolved = 16.0
		return
	if d < 6.5 and d > 0.01:
		position += to_player.normalized() * 1.1 * delta
	else:
		position.x = home.x + sin(_time * 0.4) * 1.4
		position.z = home.z + cos(_time * 0.31) * 1.4
	# nhịp thở của khối bóng
	for i in range(_blobs.size()):
		var b: MeshInstance3D = _blobs[i]
		b.scale = Vector3.ONE * (1.0 + 0.18 * sin(_time * 2.2 + i * 1.3))
	_neg_light.light_energy = 1.6 + sin(_time * 3.1) * 0.4
	if d < 1.0 and caught_callback.is_valid():
		_dissolved = 4.0
		caught_callback.call()
