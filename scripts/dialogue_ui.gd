# Hộp thoại: tên nhân vật + chữ chạy kiểu máy đánh chữ + lựa chọn.
# Dòng thoại: ["Tên", "lời"] — tên chứa "(nghĩ)" sẽ in nghiêng xám.
# Lựa chọn: {"choice": [["nhãn 1", [dòng...]], ["nhãn 2", [dòng...]]]}
extends CanvasLayer

signal finished

const CHAR_RATE := 38.0

var _font: SystemFont
var _root: Control
var _name_label: Label
var _text_label: RichTextLabel
var _hint_label: Label
var _choice_box: VBoxContainer
var _lines: Array = []
var _index := 0
var _shown := 0.0
var _waiting_choice := false
var _auto_timer := 0.0
var active := false
var auto_advance := false   # chế độ test: tự tua thoại, tự chọn đáp án 1


func _ready() -> void:
	layer = 20
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Segoe UI", "Arial"])

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)

	var panel := ColorRect.new()
	panel.color = Color(0.015, 0.02, 0.05, 0.86)
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 140
	panel.offset_right = -140
	panel.offset_top = -190
	panel.offset_bottom = -36
	_root.add_child(panel)

	var border := ReferenceRect.new()
	border.border_color = Color(1.0, 0.82, 0.29, 0.4)
	border.border_width = 1.0
	border.editor_only = false
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(border)

	_name_label = Label.new()
	_name_label.add_theme_font_override("font", _font)
	_name_label.add_theme_font_size_override("font_size", 19)
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.29))
	_name_label.position = Vector2(26, 14)
	panel.add_child(_name_label)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.add_theme_font_override("normal_font", _font)
	_text_label.add_theme_font_override("italics_font", _font)
	_text_label.add_theme_font_size_override("normal_font_size", 19)
	_text_label.add_theme_font_size_override("italics_font_size", 19)
	_text_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_text_label.offset_left = 26
	_text_label.offset_top = 50
	_text_label.offset_right = -26
	_text_label.offset_bottom = -14
	panel.add_child(_text_label)

	_hint_label = Label.new()
	_hint_label.text = "E ▸"
	_hint_label.add_theme_font_override("font", _font)
	_hint_label.add_theme_font_size_override("font_size", 15)
	_hint_label.add_theme_color_override("font_color", Color(0.95, 0.87, 0.69, 0.6))
	_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint_label.position = Vector2(-60, -34)
	panel.add_child(_hint_label)

	_choice_box = VBoxContainer.new()
	_choice_box.set_anchors_preset(Control.PRESET_CENTER)
	_choice_box.add_theme_constant_override("separation", 10)
	_root.add_child(_choice_box)


func start(lines: Array) -> void:
	_lines = lines.duplicate()
	_index = 0
	_shown = 0.0
	active = true
	_root.visible = true
	_show_current()


func _show_current() -> void:
	_waiting_choice = false
	_choice_box.visible = false
	for c in _choice_box.get_children():
		c.queue_free()
	if _index >= _lines.size():
		_finish()
		return
	var line = _lines[_index]
	if line is Dictionary and line.has("choice"):
		_present_choice(line["choice"])
		return
	var speaker: String = line[0]
	var is_thought := speaker.contains("(nghĩ)")
	_name_label.text = speaker
	_name_label.add_theme_color_override("font_color",
		Color(0.6, 0.68, 0.8) if is_thought else Color(1.0, 0.82, 0.29))
	if is_thought:
		_text_label.text = "[i][color=#aab4c8]" + line[1] + "[/color][/i]"
	else:
		_text_label.text = "[color=#f2e8d0]" + line[1] + "[/color]"
	_shown = 0.0
	_text_label.visible_characters = 0


func _present_choice(options: Array) -> void:
	_waiting_choice = true
	_name_label.text = ""
	_text_label.text = ""
	_choice_box.visible = true
	for i in range(options.size()):
		var l := Label.new()
		l.text = "[%d]  %s" % [i + 1, options[i][0]]
		l.add_theme_font_override("font", _font)
		l.add_theme_font_size_override("font_size", 22)
		l.add_theme_color_override("font_color", Color(1.0, 0.82, 0.29))
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		l.add_theme_constant_override("outline_size", 8)
		_choice_box.add_child(l)


func _finish() -> void:
	active = false
	_root.visible = false
	finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if _waiting_choice:
			var pick := -1
			if event.keycode == KEY_1:
				pick = 0
			elif event.keycode == KEY_2:
				pick = 1
			if pick >= 0:
				var options: Array = _lines[_index]["choice"]
				if pick < options.size():
					var branch: Array = options[pick][1]
					var rest := _lines.slice(_index + 1)
					_lines = branch + rest
					_index = 0
					_show_current()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			if _text_label.visible_characters < _text_label.get_total_character_count():
				_text_label.visible_characters = _text_label.get_total_character_count()
			else:
				_index += 1
				_show_current()
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not active:
		return
	if _waiting_choice:
		if auto_advance:
			var options: Array = _lines[_index]["choice"]
			var branch: Array = options[0][1]
			_lines = branch + _lines.slice(_index + 1)
			_index = 0
			_show_current()
		return
	if _text_label.visible_characters < _text_label.get_total_character_count():
		_shown += delta * (CHAR_RATE * 20.0 if auto_advance else CHAR_RATE)
		_text_label.visible_characters = int(_shown)
	elif auto_advance:
		_auto_timer += delta
		if _auto_timer > 0.15:
			_auto_timer = 0.0
			_index += 1
			_show_current()
