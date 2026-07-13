# UI: intro, HUD, mục tiêu, bảng màu Ngũ Hành, prompt, toast, fade, title card, credits, màn thắng.
extends CanvasLayer

const GOLD := Color(1.0, 0.82, 0.29)
const CREAM := Color(0.95, 0.87, 0.69)

var player: Node3D   # main gán sau khi tạo

var _font: SystemFont
var _intro: Control
var _hud: Label
var _objective: Label
var _prompt: Label
var _hint: Label
var _toast: Label
var _win: Control
var _fade: ColorRect
var _title: Label
var _subtitle: Label
var _colors_box: HBoxContainer
var _start_label: Label
var _cinematic_caption: Label
var _skip_hint: Label
var _toast_timer := 0.0
var _pulse_t := 0.0
var _skip_requested := false


func _ready() -> void:
	layer = 10
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Segoe UI", "Arial"])

	_intro = _build_intro()
	add_child(_intro)
	_hud = _label("WASD di chuyển · chuột nhìn quanh · E tương tác · V đổi góc nhìn · 1-5 màu đèn", 14, Color(CREAM.r, CREAM.g, CREAM.b, 0.75), HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_BOTTOM)
	_hud.visible = false
	add_child(_hud)
	_objective = _label("", 16, GOLD, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, 18)
	add_child(_objective)
	_prompt = _label("", 20, CREAM, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_BOTTOM, -70)
	add_child(_prompt)
	_hint = _label("", 20, CREAM, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_BOTTOM, -70)
	_hint.visible = false
	add_child(_hint)
	_toast = _label("", 23, GOLD, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_TOP, 60)
	_toast.visible = false
	add_child(_toast)

	_colors_box = HBoxContainer.new()
	_colors_box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_colors_box.position = Vector2(-250, -46)
	_colors_box.add_theme_constant_override("separation", 10)
	add_child(_colors_box)

	_cinematic_caption = _label("", 22, CREAM, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_BOTTOM, -138)
	_cinematic_caption.visible = false
	add_child(_cinematic_caption)
	_skip_hint = _label("Giữ Space để bỏ qua", 14, Color(CREAM.r, CREAM.g, CREAM.b, 0.72), HORIZONTAL_ALIGNMENT_RIGHT, VERTICAL_ALIGNMENT_TOP, 18)
	_skip_hint.visible = false
	add_child(_skip_hint)

	_win = _build_win()
	_win.visible = false
	add_child(_win)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

	_title = _label("", 46, GOLD, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	_title.modulate.a = 0.0
	add_child(_title)
	_subtitle = _label("", 20, Color(0.85, 0.75, 0.54), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 0.0)
	_subtitle.offset_top = 60
	_subtitle.modulate.a = 0.0
	add_child(_subtitle)


func _label(text: String, size: int, color: Color, halign: int, valign: int, voffset: float = -16.0) -> Label:
	var l := Label.new()
	l.text = text
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.offset_left = 20
	l.offset_right = -20
	if valign == VERTICAL_ALIGNMENT_BOTTOM:
		l.offset_bottom = voffset
	elif valign == VERTICAL_ALIGNMENT_TOP:
		l.offset_top = voffset
	l.horizontal_alignment = halign
	l.vertical_alignment = valign
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 7)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _centered_column(lines: Array, dim_alpha: float = 0.8) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.015, 0.04, dim_alpha)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	for line in lines:
		var l := Label.new()
		l.text = line[0]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", _font)
		l.add_theme_font_size_override("font_size", line[1])
		l.add_theme_color_override("font_color", line[2])
		box.add_child(l)
	return root


func _build_intro() -> Control:
	var root := _centered_column([
		["HỌA HỒN ĐÈN LỒNG", 54, GOLD],
		["— Soul Painter —", 18, Color(0.85, 0.75, 0.54)],
		["", 8, CREAM],
		["\"Đã bao lâu rồi, phố hội không còn ánh lửa?", 16, Color(0.73, 0.66, 0.5)],
		["Khi những câu chuyện xưa bị lãng quên, bóng tối sẽ tìm đến", 16, Color(0.73, 0.66, 0.5)],
		["để lấp đầy những khoảng trống của ký ức...\"", 16, Color(0.73, 0.66, 0.5)],
		["", 8, CREAM],
		["WASD — di chuyển · chuột — nhìn quanh · E — tương tác / thoại · 1-5 — màu Ngũ Hành", 15, CREAM],
	])
	var box: VBoxContainer = root.get_child(1).get_child(0)
	_start_label = Label.new()
	_start_label.text = "Nhấn phím bất kỳ để thắp đèn"
	_start_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_start_label.add_theme_font_override("font", _font)
	_start_label.add_theme_font_size_override("font_size", 18)
	_start_label.add_theme_color_override("font_color", Color(1.0, 0.91, 0.69))
	box.add_child(_start_label)
	return root


func _build_win() -> Control:
	return _centered_column([
		["Họa hồn — nghĩa là vẽ hồn mình vào trong đèn.", 30, GOLD],
		["", 8, CREAM],
		["Trong một tiệm đèn ở phố hội đêm nay, có một chiếc đèn cổ không ai bán.", 16, Color(0.85, 0.75, 0.54)],
		["Trong lớp giấy dó, thấp thoáng một bóng chim Lạc bay —", 16, Color(0.85, 0.75, 0.54)],
		["và đèn tự sáng, không cần lửa.", 16, Color(0.85, 0.75, 0.54)],
		["", 8, CREAM],
		["Nhấn R để chơi lại", 15, CREAM],
	], 0.6)


func hide_intro() -> void:
	_intro.visible = false
	set_gameplay_hud_visible(true)
	update_colors()


func set_gameplay_hud_visible(visible: bool) -> void:
	_hud.visible = visible
	_objective.visible = visible
	_prompt.visible = visible
	_hint.visible = visible and _hint.text != ""
	_colors_box.visible = visible


func show_cinematic_caption(text: String) -> void:
	_cinematic_caption.text = text
	_cinematic_caption.visible = text != ""


func show_skip_hint(visible: bool) -> void:
	_skip_hint.visible = visible


func request_skip() -> void:
	_skip_requested = true


func _wait_skippable(seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds and not _skip_requested:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	_skip_requested = false


func set_objective(text: String) -> void:
	_objective.text = ("◆ " + text) if text != "" else ""


func show_prompt(text: String) -> void:
	_prompt.text = ("E — " + text) if text != "" else ""


func show_hint(text: String) -> void:
	_hint.text = text
	_hint.visible = text != ""


func toast(msg: String) -> void:
	_toast.text = msg
	_toast.visible = true
	_toast_timer = 3.5


func update_colors() -> void:
	for c in _colors_box.get_children():
		c.queue_free()
	if player == null:
		return
	for id in player.COLOR_ORDER:
		if not player.unlocked.has(id):
			continue
		var def: Dictionary = player.COLOR_DEFS[id]
		var l := Label.new()
		l.text = "%d %s" % [def["num"], def["name"]]
		l.add_theme_font_override("font", _font)
		l.add_theme_font_size_override("font_size", 16)
		var c: Color = def["color"]
		l.add_theme_color_override("font_color", c if player.current_color == id else Color(c.r, c.g, c.b, 0.45))
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		l.add_theme_constant_override("outline_size", 6)
		_colors_box.add_child(l)


func show_win() -> void:
	set_gameplay_hud_visible(false)
	show_cinematic_caption("")
	show_skip_hint(false)
	_prompt.text = ""
	_objective.text = ""
	_win.visible = true


func fade_to(alpha: float, dur: float, color: Color = Color(0, 0, 0)) -> void:
	_fade.color = Color(color.r, color.g, color.b, _fade.color.a)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, dur)
	await tw.finished


func title_card(title: String, subtitle: String) -> void:
	_skip_requested = false
	_title.text = title
	_subtitle.text = subtitle
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_title, "modulate:a", 1.0, 0.8)
	tw.tween_property(_subtitle, "modulate:a", 1.0, 0.8)
	await tw.finished
	await _wait_skippable(2.2)
	var tw2 := create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(_title, "modulate:a", 0.0, 0.8)
	tw2.tween_property(_subtitle, "modulate:a", 0.0, 0.8)
	await tw2.finished


func roll_credits(player_credit_name: String = "Người giữ đèn") -> void:
	_skip_requested = false
	var lines := [
		["HỌA HỒN ĐÈN LỒNG", 40, GOLD],
		["", 10, CREAM],
		["Kịch bản · Thiết kế · Lập trình", 16, Color(0.7, 0.62, 0.48)],
		["%s — người giữ đèn cuối cùng" % player_credit_name, 18, CREAM],
		["", 10, CREAM],
		["Cảm ơn bạn đã thắp lại phố hội.", 18, Color(0.85, 0.75, 0.54)],
	]
	var card := _centered_column(lines, 0.0)
	card.modulate.a = 0.0
	add_child(card)
	var tw := create_tween()
	tw.tween_property(card, "modulate:a", 1.0, 1.2)
	await tw.finished
	await _wait_skippable(3.0)
	var tw2 := create_tween()
	tw2.tween_property(card, "modulate:a", 0.0, 1.0)
	await tw2.finished
	card.queue_free()


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			_toast.visible = false
	if _intro.visible:
		_pulse_t += delta
		_start_label.modulate.a = 0.5 + 0.5 * absf(sin(_pulse_t * 2.2))


func play_chime() -> void:
	var p := AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 2.6
	p.stream = gen
	add_child(p)
	p.play()
	var pb := p.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var notes := [523.25, 587.33, 783.99, 1046.5, 1174.66]
	var frames := int(22050.0 * 2.4)
	for f in range(frames):
		var t := f / 22050.0
		var s := 0.0
		for i in range(notes.size()):
			var t0 := i * 0.13
			if t >= t0:
				s += sin(TAU * notes[i] * (t - t0)) * 0.16 * exp(-(t - t0) * 2.5)
		pb.push_frame(Vector2(s, s))
