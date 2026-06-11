# Toàn bộ UI 2D: màn hình mở đầu, HUD, lời nhắc, thông báo, màn thắng + tiếng chuông.
extends CanvasLayer

const GOLD := Color(1.0, 0.82, 0.29)
const CREAM := Color(0.95, 0.87, 0.69)

var _font: SystemFont
var _intro: Control
var _hud: Label
var _prompt: Label
var _hint: Label
var _toast: Label
var _win: Control
var _start_label: Label
var _toast_timer := 0.0
var _pulse_t := 0.0


func _ready() -> void:
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Segoe UI", "Arial"])

	_intro = _build_intro()
	add_child(_intro)
	_hud = _label("WASD — di chuyển · E — tương tác", 15, CREAM, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_BOTTOM)
	_hud.visible = false
	add_child(_hud)
	_prompt = _label("Nhấn E để thắp sáng ký ức", 21, CREAM, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_BOTTOM, -70)
	_prompt.visible = false
	add_child(_prompt)
	_hint = _label("A / D — xoay đèn lồng cho bóng Chim Lạc khớp với hình mờ trên tường", 21, CREAM, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_BOTTOM, -70)
	_hint.visible = false
	add_child(_hint)
	_toast = _label("", 24, GOLD, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_TOP, 60)
	_toast.visible = false
	add_child(_toast)
	_win = _build_win()
	_win.visible = false
	add_child(_win)


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
	return l


func _centered_column(lines: Array, dim_alpha: float = 0.8) -> Control:
	# lines: mảng [text, size, color]
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
		["— Demo: Ngõ Nhỏ —", 18, Color(0.85, 0.75, 0.54)],
		["", 8, CREAM],
		["\"Đã bao lâu rồi, phố hội không còn ánh lửa?", 16, Color(0.73, 0.66, 0.5)],
		["Khi những câu chuyện xưa bị lãng quên, bóng tối sẽ tìm đến", 16, Color(0.73, 0.66, 0.5)],
		["để lấp đầy những khoảng trống của ký ức...\"", 16, Color(0.73, 0.66, 0.5)],
		["", 8, CREAM],
		["W A S D — di chuyển  ·  E — tương tác  ·  A / D — xoay đèn khi giải đố", 15, CREAM],
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
		["", 120, CREAM],
		["Ký ức phố hội đã được thắp sáng", 42, GOLD],
		["", 8, CREAM],
		["Minh: \"Sư phụ nói... chừng nào lòng người còn mong cầu cái đẹp,", 17, Color(0.85, 0.75, 0.54)],
		["ánh sáng sẽ không bao giờ tắt.\"", 17, Color(0.85, 0.75, 0.54)],
		["", 8, CREAM],
		["Nhấn R để chơi lại", 16, CREAM],
	], 0.45)


func hide_intro() -> void:
	_intro.visible = false
	_hud.visible = true


func show_prompt(v: bool) -> void:
	_prompt.visible = v


func show_hint(v: bool) -> void:
	_hint.visible = v


func toast(msg: String) -> void:
	_toast.text = msg
	_toast.visible = true
	_toast_timer = 3.5


func show_win() -> void:
	_hud.visible = false
	_prompt.visible = false
	_win.visible = true


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			_toast.visible = false
	if _intro.visible:
		_pulse_t += delta
		_start_label.modulate.a = 0.5 + 0.5 * absf(sin(_pulse_t * 2.2))


# hợp âm ngũ cung gợi tiếng đàn tranh
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
