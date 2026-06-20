extends CanvasLayer

signal closed(inspected_ids: Array, key_taken: bool)

const REQUIRED_FOR_KEY := ["tea_pot", "debt_book", "incense_bowl", "brass_key", "lotus_paper"]
const ITEMS := {
	"tea_pot": {
		"title": "Ấm trà còn nóng",
		"clue": "Nước còn nóng, nhưng quán như đã đóng từ lâu.",
	},
	"debt_book": {
		"title": "Sổ nợ trà",
		"clue": "Nợ trà: người gánh đèn, chưa ghi tên.",
	},
	"incense_bowl": {
		"title": "Bát nhang nguội",
		"clue": "Ba ngày không ai cắm nhang. Tro vẫn ấm.",
	},
	"brass_key": {
		"title": "Chìa khóa đồng",
		"clue": "Nhà sau quán. Không mở từ mùa nước lớn.",
	},
	"lotus_paper": {
		"title": "Giấy hoa đăng",
		"clue": "Nếu không nhớ tên, thả đèn thay lời gọi.",
	},
	"flood_mark": {
		"title": "Ngấn lũ trên cột",
		"clue": "Ngấn lũ cao quá đầu người, nhưng không ai nhắc tới trận lũ.",
	},
}

var active := false
var inspected := {}
var key_taken := false

var _root: Control
var _title: Label
var _portrait: Label
var _clue: RichTextLabel
var _progress: Label
var _key_button: Button
var _buttons := {}


func _ready() -> void:
	_build_ui()
	visible = false


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.015, 0.01, 0.86)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)

	var panel := PanelContainer.new()
	panel.size = Vector2(980, 540)
	panel.position = Vector2(150, 90)
	_root.add_child(panel)

	var cols := HBoxContainer.new()
	cols.custom_minimum_size = Vector2(960, 520)
	panel.add_child(cols)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(310, 500)
	cols.add_child(left)

	_title = Label.new()
	_title.text = "QUẦY KÝ ỨC"
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_color", Color(1.0, 0.78, 0.42))
	left.add_child(_title)

	_portrait = Label.new()
	_portrait.text = "    /\\\n  _/  \\_\n /______\\\n   ████\n  ██████\n  áo nâu, khói đèn\n  che gần hết mặt"
	_portrait.add_theme_font_size_override("font_size", 22)
	_portrait.add_theme_color_override("font_color", Color(0.78, 0.65, 0.43))
	_portrait.custom_minimum_size = Vector2(280, 250)
	left.add_child(_portrait)

	var hint := Label.new()
	hint.text = "Bà không kể thẳng. Quầy tự kể bằng những thứ còn nóng, còn nợ, còn tro."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color(0.75, 0.72, 0.66))
	left.add_child(hint)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(620, 500)
	cols.add_child(right)

	var item_grid := GridContainer.new()
	item_grid.columns = 2
	right.add_child(item_grid)
	for id in ITEMS.keys():
		var btn := Button.new()
		btn.text = ITEMS[id]["title"]
		btn.custom_minimum_size = Vector2(280, 42)
		btn.pressed.connect(func() -> void: inspect_item(id))
		item_grid.add_child(btn)
		_buttons[id] = btn

	_clue = RichTextLabel.new()
	_clue.bbcode_enabled = true
	_clue.fit_content = false
	_clue.custom_minimum_size = Vector2(600, 180)
	_clue.text = "[i]Chọn một vật trên quầy.[/i]"
	right.add_child(_clue)

	_progress = Label.new()
	_progress.add_theme_color_override("font_color", Color(0.86, 0.78, 0.6))
	right.add_child(_progress)

	var actions := HBoxContainer.new()
	right.add_child(actions)
	_key_button = Button.new()
	_key_button.text = "Nhận chìa khóa nhà sau quán"
	_key_button.disabled = true
	_key_button.pressed.connect(_take_key)
	actions.add_child(_key_button)

	var close_button := Button.new()
	close_button.text = "Rời quầy"
	close_button.pressed.connect(close_panel)
	actions.add_child(close_button)
	_refresh()


func open_panel() -> void:
	active = true
	visible = true
	_refresh()


func inspect_item(id: String) -> void:
	if not ITEMS.has(id):
		return
	inspected[id] = true
	var item: Dictionary = ITEMS[id]
	_clue.text = "[b]%s[/b]\n\n%s" % [item["title"], item["clue"]]
	_refresh()


func has_inspected(id: String) -> bool:
	return inspected.has(id)


func required_inspected_count() -> int:
	var n := 0
	for id in REQUIRED_FOR_KEY:
		if inspected.has(id):
			n += 1
	return n


func has_required_clues() -> bool:
	return required_inspected_count() >= REQUIRED_FOR_KEY.size()


func can_take_key() -> bool:
	return has_required_clues()


func _take_key() -> void:
	if not can_take_key():
		return
	key_taken = true
	_clue.text = "[b]Chìa khóa đồng[/b]\n\nChìa nằm dưới đáy khay. Bà không đưa. Bà chỉ ngồi yên như đã chờ đúng bàn tay này."
	_refresh()


func close_panel() -> void:
	active = false
	visible = false
	closed.emit(inspected.keys(), key_taken)


func _refresh() -> void:
	if _progress == null:
		return
	_progress.text = "Manh mối chính: %d / %d" % [required_inspected_count(), REQUIRED_FOR_KEY.size()]
	if _key_button != null:
		_key_button.disabled = not can_take_key() or key_taken
		_key_button.text = "Đã nhận chìa khóa nhà sau quán" if key_taken else "Nhận chìa khóa nhà sau quán"
	for id in _buttons.keys():
		var btn: Button = _buttons[id]
		btn.text = ("✓ " if inspected.has(id) else "") + ITEMS[id]["title"]
