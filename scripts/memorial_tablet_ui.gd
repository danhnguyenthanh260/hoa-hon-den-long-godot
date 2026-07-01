extends CanvasLayer

signal closed(attempted_name: String, attempts: int)

const REFUSAL_LINES := [
	"Nét mực không ăn. Như thể tên này chưa từng thuộc về ai còn sống.",
	"Chữ vừa hiện đã nhòe, tan vào gỗ như chưa từng viết.",
	"Bài vị lạnh dần dưới tay. Nó không nhận cái tên này.",
]

var active := false
var attempts := 0
var _last_attempted := ""

var _root: Control
var _name_edit: LineEdit
var _feedback: RichTextLabel


func _ready() -> void:
	_build_ui()
	visible = false


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.01, 0.015, 0.88)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)

	var panel := PanelContainer.new()
	panel.size = Vector2(640, 360)
	panel.position = Vector2(320, 180)
	_root.add_child(panel)

	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(600, 340)
	panel.add_child(col)

	var title := Label.new()
	title.text = "BÀI VỊ TRỐNG"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.78, 0.42))
	col.add_child(title)

	var hint := Label.new()
	hint.text = "Khắc một cái tên lên bài vị này."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color(0.75, 0.72, 0.66))
	col.add_child(hint)

	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Gõ tên..."
	_name_edit.custom_minimum_size = Vector2(560, 40)
	_name_edit.text_submitted.connect(func(_t: String) -> void: _try_inscribe())
	col.add_child(_name_edit)

	var actions := HBoxContainer.new()
	col.add_child(actions)
	var inscribe_button := Button.new()
	inscribe_button.text = "Khắc tên"
	inscribe_button.pressed.connect(_try_inscribe)
	actions.add_child(inscribe_button)
	var close_button := Button.new()
	close_button.text = "Rời bàn thờ"
	close_button.pressed.connect(close_panel)
	actions.add_child(close_button)

	_feedback = RichTextLabel.new()
	_feedback.bbcode_enabled = true
	_feedback.custom_minimum_size = Vector2(600, 140)
	_feedback.text = "[i]Bài vị trống trơn, chờ một cái tên.[/i]"
	col.add_child(_feedback)


func open_panel() -> void:
	active = true
	visible = true
	_name_edit.text = ""
	_name_edit.grab_focus()


func _try_inscribe() -> void:
	var typed := _name_edit.text.strip_edges()
	if typed.is_empty():
		return
	_last_attempted = typed
	attempts += 1
	var line: String = REFUSAL_LINES[mini(attempts - 1, REFUSAL_LINES.size() - 1)]
	_feedback.text = "[b]%s[/b]\n\n%s" % [typed, line]
	_name_edit.text = ""


func close_panel() -> void:
	active = false
	visible = false
	closed.emit(_last_attempted, attempts)
