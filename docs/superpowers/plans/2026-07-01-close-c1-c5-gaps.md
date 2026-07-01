# Đóng 5 Gap Sản Xuất C1-C5 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Đóng 5 gap đã xác định trong buổi audit code C1-C5 (2026-07-01): bài vị C3 từ chối nhận tên, phản chiếu (reflection) render thật dùng chung C2/C5, nghi lễ bà hàng nước + evidence puzzle Chim Lạc ở C1, logic mâu thuẫn radio-vs-giếng ở C2, và xác nhận lại gate `--flow` sau khi sửa.

**Architecture:** Mở rộng `NarrativeState` với sổ mâu thuẫn (`contradictions`) dùng chung. Thêm 2 component tái sử dụng: `memorial_tablet_ui.gd` (CanvasLayer nhập tên bị từ chối, rập khuôn theo `memory_stall_inspect_ui.gd`) và `reflection_pool.gd` (Node3D bọc `SubViewport` + `Camera3D` gương, loại người chơi khỏi ảnh phản chiếu qua render layer riêng). C1/C2/C3/C5 chỉ gọi vào 2 component này thay vì tự implement lại. Toàn bộ state mới đi qua `narrative.add_evidence` / `narrative.record_contradiction` sẵn có để giữ tương thích checkpoint.

**Tech Stack:** Godot 4.5, GDScript thuần, không asset ngoài. Test theo convention sẵn có của project: `extends SceneTree`, in `"X OK"` + `quit(0)` khi pass, `push_error` + `quit(1)` khi fail, chạy qua `Godot_v4.5-stable_win64_console.exe --headless --script res://scripts/tests/test_X.gd`. Theo quyết định của user: viết test `.gd` cho state/logic thuần (narrative, evidence, contradiction, cull_mask/toán học của reflection), KHÔNG viết test cho phần hình ảnh/render pixel thật — phần đó xác nhận bằng mắt ở Task 10.

**Phạm vi đã chốt với user:** cả 5 gap, theo đúng thứ tự ưu tiên đã đề xuất (C3 bài vị → reflection dùng chung → C1 ritual/evidence → C2 contradiction → re-run flow). Task 1 là bước nền nhỏ (mở rộng `NarrativeState`) đặt trước vì cả Task 3 và Task 8 đều cần nó.

---

## Ghi chú phát hiện thêm (không phải gap đã duyệt, nhưng sửa kèm vì đụng đúng vùng code)

Khi đọc `main.gd` để nắm cách `_flow_test()` lái C1, phát hiện dòng 1294 gọi `c1.intro_beat()` — hàm này **không tồn tại** trong `c1.gd` (chỉ có `enter_beat()`). Đây nhiều khả năng là tàn dư sau một lần đổi tên hàm. Task 7 sẽ sửa luôn vì đang chỉnh đúng vùng C1 của `_flow_test()`. Lưu ý: đây KHÔNG được xác nhận là nguyên nhân gate `--flow` bị treo hơn 5 phút khi audit ban đầu (đã thử kill process khi đó) — nguyên nhân treo nhiều khả năng là render headless không GPU với scene ngày càng nặng (baseline cũ 70.8s trước khi có mesh rig 21-xương + PBR full C1 + lantern). Task 10 sẽ xác nhận lại trên máy có GPU.

---

### Task 1: Mở rộng NarrativeState — sổ mâu thuẫn dùng chung

**Files:**
- Modify: `scripts/narrative_state.gd`
- Test: `scripts/tests/test_narrative_state.gd`

- [ ] **Step 1: Viết test cho `record_contradiction` (sẽ fail vì hàm chưa tồn tại)**

Thêm vào cuối `scripts/tests/test_narrative_state.gd`, và gọi từ `_init()`:

```gdscript
func _init() -> void:
	_test_unique_evidence()
	_test_choice_and_endings()
	_test_round_trip()
	_test_invalid_load_is_atomic()
	_test_contradiction_ledger()
	if failures.is_empty():
		print("NARRATIVE STATE OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
```

Thêm hàm test mới ở cuối file:

```gdscript
func _test_contradiction_ledger() -> void:
	var state := NarrativeState.new()
	var before_trust := state.trust_voice
	_check(state.record_contradiction("c2_well_vs_radio_shortcut", "radio bao bo qua nhung gieng cho bang chung"), "first contradiction insert failed")
	_check(not state.record_contradiction("c2_well_vs_radio_shortcut", "duplicate"), "duplicate contradiction was accepted")
	_check(state.contradictions.size() == 1, "contradiction ledger size is wrong")
	_check(state.trust_voice < before_trust, "recording a contradiction did not reduce voice trust")

	var restored := NarrativeState.new()
	_check(restored.load_dict(state.to_dict()), "narrative state with contradictions did not round-trip")
	_check(restored.contradictions.size() == 1, "contradictions did not survive save/load round-trip")
	_check(restored.contradictions.has("c2_well_vs_radio_shortcut"), "restored contradiction id changed")
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `.\tools\Godot_v4.5-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_narrative_state.gd`
Expected: FAIL — báo lỗi `Invalid call. Nonexistent function 'record_contradiction'`.

- [ ] **Step 3: Thêm field + hàm vào NarrativeState**

Trong `scripts/narrative_state.gd`, thêm field ngay sau dòng 18 (`var choices: Dictionary = {}`):

```gdscript
var contradictions: Dictionary = {}
```

Thêm hàm mới ngay sau `record_refusal()` (sau dòng 51):

```gdscript
func record_contradiction(contradiction_id: String, description: String) -> bool:
	if contradiction_id.is_empty() or contradictions.has(contradiction_id):
		return false
	contradictions[contradiction_id] = {"description": description}
	adjust_trust(-15)
	return true
```

Sửa `to_dict()` — thêm key mới vào dictionary trả về (sau dòng `"choices": choices.duplicate(true),`):

```gdscript
		"choices": choices.duplicate(true),
		"contradictions": contradictions.duplicate(true),
	}
```

Sửa `_apply_dict_unchecked()` — thêm dòng sau `choices = Dictionary(data.get("choices", {})).duplicate(true)`:

```gdscript
	choices = Dictionary(data.get("choices", {})).duplicate(true)
	contradictions = Dictionary(data.get("contradictions", {})).duplicate(true)
```

- [ ] **Step 4: Chạy lại test, xác nhận pass**

Run: `.\tools\Godot_v4.5-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_narrative_state.gd`
Expected: `NARRATIVE STATE OK`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/narrative_state.gd scripts/tests/test_narrative_state.gd
git commit -m "feat(narrative): them so mau thuan (contradictions) dung chung cho C2/C5"
```

---

### Task 2: `memorial_tablet_ui.gd` — bài vị từ chối nhận tên

**Files:**
- Create: `scripts/memorial_tablet_ui.gd`
- Test: `scripts/tests/test_memorial_tablet_ui.gd`

- [ ] **Step 1: Viết test trước (sẽ fail vì file chưa tồn tại)**

Tạo `scripts/tests/test_memorial_tablet_ui.gd`:

```gdscript
extends SceneTree

const MemorialTabletUI := preload("res://scripts/memorial_tablet_ui.gd")

var failures: Array[String] = []
var closed_seen := false
var closed_name := ""
var closed_attempts := -1


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ui := MemorialTabletUI.new()
	root.add_child(ui)
	await process_frame
	ui.closed.connect(func(attempted_name: String, attempts: int) -> void:
		closed_seen = true
		closed_name = attempted_name
		closed_attempts = attempts
	)
	ui.open_panel()
	_check(ui.active, "memorial tablet did not open")
	_check(ui.attempts == 0, "attempts should start at zero")

	ui._name_edit.text = "Minh"
	ui._try_inscribe()
	_check(ui.attempts == 1, "first inscribe attempt was not counted")
	_check(ui._name_edit.text == "", "input field was not cleared after refusal")

	ui._name_edit.text = "Minh"
	ui._try_inscribe()
	_check(ui.attempts == 2, "second inscribe attempt was not counted")

	ui.close_panel()
	_check(closed_seen, "closed signal not emitted")
	_check(closed_name == "Minh", "closed signal did not report last attempted name")
	_check(closed_attempts == 2, "closed signal did not report attempt count")
	ui.queue_free()

	if failures.is_empty():
		print("MEMORIAL TABLET UI OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `.\tools\Godot_v4.5-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_memorial_tablet_ui.gd`
Expected: FAIL — `Cannot find file 'res://scripts/memorial_tablet_ui.gd'` hoặc lỗi parse tương đương (script chưa tồn tại).

- [ ] **Step 3: Tạo `scripts/memorial_tablet_ui.gd`**

Rập khuôn cấu trúc `scripts/memory_stall_inspect_ui.gd` (CanvasLayer full-screen, PanelContainer giữa màn hình):

```gdscript
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
```

- [ ] **Step 4: Chạy lại test, xác nhận pass**

Run: `.\tools\Godot_v4.5-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_memorial_tablet_ui.gd`
Expected: `MEMORIAL TABLET UI OK`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/memorial_tablet_ui.gd scripts/tests/test_memorial_tablet_ui.gd
git commit -m "feat(c3): them memorial_tablet_ui — bai vi tu choi nhan ten"
```

---

### Task 3: Nối bài vị vào C3 + main.gd + flow test

**Files:**
- Modify: `scripts/main.gd`
- Modify: `scripts/c3.gd`
- Test: `scripts/tests/test_c1_progression.gd` không đổi; verify thủ công qua `--flow` (Step 4 dưới)

- [ ] **Step 1: Wire `main.gd` — preload, biến, mở/đóng panel**

Thêm const ngay dưới dòng khai báo `MemoryStallInspectUI` (dòng 9):

```gdscript
const MemorialTabletUI := preload("res://scripts/memorial_tablet_ui.gd")
```

Thêm biến ngay dưới `var memory_stall: CanvasLayer` (dòng 40):

```gdscript
var memorial_tablet: CanvasLayer
```

Thêm biến ngay dưới `var _memory_stall_owner = null` (dòng 68):

```gdscript
var _memorial_tablet_owner = null
```

Trong `_ready()`, ngay sau khối wiring `memory_stall` (dòng 98-100: `memory_stall = MemoryStallInspectUI.new()` ... `memory_stall.closed.connect(_on_memory_stall_closed)`), thêm:

```gdscript
	memorial_tablet = MemorialTabletUI.new()
	add_child(memorial_tablet)
	memorial_tablet.closed.connect(_on_memorial_tablet_closed)
```

Ngay sau hàm `_on_memory_stall_closed()` (kết thúc ở dòng 331), thêm 2 hàm mới:

```gdscript
func open_memorial_tablet(owner) -> void:
	_memorial_tablet_owner = owner
	state = State.DIALOGUE
	ui.show_prompt("")
	memorial_tablet.open_panel()


func _on_memorial_tablet_closed(attempted_name: String, attempts: int) -> void:
	if state == State.DIALOGUE:
		state = State.PLAY
	if _memorial_tablet_owner != null and _memorial_tablet_owner.has_method("on_memorial_tablet_closed"):
		_memorial_tablet_owner.on_memorial_tablet_closed(attempted_name, attempts)
	_memorial_tablet_owner = null
	_save_checkpoint()
```

Trong `_unhandled_input()`, sửa dòng 483 để chặn input khi bài vị đang mở (giống hệt cách memory_stall đã làm):

```gdscript
	if memory_stall != null and memory_stall.active:
		return
	if memorial_tablet != null and memorial_tablet.active:
		return
```

- [ ] **Step 2: Thêm bài vị vào c3.gd**

Trong `scripts/c3.gd`, thêm biến mới ngay dưới `var _photo: MeshInstance3D` (dòng 20):

```gdscript
var _tablet: MeshInstance3D
var tablet_attempts := 0
```

Trong `build()`, ngay sau dòng dựng `_photo` (dòng 44: `_photo = Build.box(...)`), thêm bài vị cạnh ảnh thờ:

```gdscript
	_tablet = Build.box(self, Vector3(0.22, 0.42, 0.04), O + Vector3(0.9, 1.15, -8.78), Build.mat(Color(0.16, 0.12, 0.08)))
```

Trong `build()`, ngay sau dòng đăng ký interact `_take_moc` (dòng 85: `m.add_interact(O + Vector3(-0.9, 0, -8.0), ...)`), thêm:

```gdscript
	m.add_interact(O + Vector3(0.9, 0, -8.78), 1.8, "Bài vị trống trên bàn thờ", Callable(self, "_try_inscribe_tablet"), false)
```

Ở cuối file (sau `func update(...)`, trước `func clamp_player(...)`), thêm 2 hàm:

```gdscript
func _try_inscribe_tablet() -> void:
	m.open_memorial_tablet(self)


func on_memorial_tablet_closed(_attempted_name: String, attempts: int) -> void:
	tablet_attempts = attempts
	if attempts > 0 and not m.narrative.evidence.has("c3_tablet_refuses_name"):
		m.narrative.add_evidence(
			"c3_tablet_refuses_name",
			"Bài vị từ chối nhận bất cứ cái tên nào Minh khắc lên — kể cả tên của chính mình."
		)
```

- [ ] **Step 3: Cập nhật `_flow_test()` trong main.gd để lái qua bài vị mới**

Tìm khối C3 hiện tại (khoảng dòng 1354-1360):

```gdscript
	var c3 = chapters[3]
	c3._take_moc()
	await _wait_dialogue()
	player.set_color("moc")
	c3._try_grow()
```

Sửa thành (chèn bước bài vị giữa `_take_moc()` và `_try_grow()`):

```gdscript
	var c3 = chapters[3]
	c3._take_moc()
	await _wait_dialogue()
	c3._try_inscribe_tablet()
	memorial_tablet._name_edit.text = "Minh"
	memorial_tablet._try_inscribe()
	memorial_tablet.close_panel()
	await _wait_dialogue()
	if c3.tablet_attempts != 1:
		push_error("FLOW FAILED: bai vi phai ghi nhan 1 lan thu khac ten, got %d" % c3.tablet_attempts)
		get_tree().quit(1)
		return
	if not narrative.evidence.has("c3_tablet_refuses_name"):
		push_error("FLOW FAILED: bai vi tu choi ten phai ghi evidence")
		get_tree().quit(1)
		return
	player.set_color("moc")
	c3._try_grow()
```

Sửa `_wait_dialogue()` (dòng 1423-1426) để đợi cả bài vị đóng lại, không riêng `memory_stall`:

```gdscript
func _wait_dialogue() -> void:
	await get_tree().create_timer(0.4).timeout
	while dialogue.active or (memory_stall != null and memory_stall.active) or (memorial_tablet != null and memorial_tablet.active):
		await get_tree().create_timer(0.1).timeout
```

- [ ] **Step 4: Parse-check bằng editor import (không chạy full `--flow` ở bước này — máy này không có GPU, xem Task 10)**

Run: `.\tools\Godot_v4.5-stable_win64_console.exe --headless --path . --editor --quit`
Expected: không có dòng `SCRIPT ERROR` / `Parse Error` nào liên quan `main.gd`, `c3.gd`.

- [ ] **Step 5: Commit**

```bash
git add scripts/main.gd scripts/c3.gd
git commit -m "feat(c3): noi bai vi tu choi ten vao C3 + main.gd + flow test"
```

---

### Task 4: `reflection_pool.gd` — component phản chiếu dùng chung

**Files:**
- Create: `scripts/reflection_pool.gd`
- Modify: `scripts/player.gd`
- Test: `scripts/tests/test_reflection_pool.gd`

**Thiết kế (đọc trước khi code):** `SubViewport` với `own_world_3d = false` sẽ render CHUNG World3D với viewport chính — nghĩa là không cần dựng lại environment/ánh sáng, chỉ cần đặt một `Camera3D` khác trong viewport đó, lấy gương của camera chính qua mặt phẳng nước (Y cố định). Người chơi bị loại khỏi ảnh phản chiếu bằng render layer riêng: player được gắn thêm bit layer 2 (không bỏ layer 1 mặc định, nên camera chính vẫn thấy player bình thường); camera phản chiếu có `cull_mask` loại trừ đúng bit đó. Đây là phản chiếu render THẬT (viewport texture thật), không phải shader mirror chuẩn theo từng pixel — chấp nhận được vì mesh nước ở đây phẳng nhỏ và game vốn đã theo phong cách stylized/procedural (xem `README.md` mục "Trần đồ họa hiện tại").

- [ ] **Step 1: Viết test trước (sẽ fail vì file chưa tồn tại)**

Tạo `scripts/tests/test_reflection_pool.gd`:

```gdscript
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
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `.\tools\Godot_v4.5-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_reflection_pool.gd`
Expected: FAIL — file `reflection_pool.gd` chưa tồn tại.

- [ ] **Step 3: Tạo `scripts/reflection_pool.gd`**

```gdscript
# Vũng nước/giếng phản chiếu bằng camera gương thật trong SubViewport (dùng chung
# World3D, không dựng lại môi trường). Người chơi bị loại khỏi ảnh phản chiếu qua
# render layer riêng — xem player.gd REFLECTION_EXCLUDE_LAYER_BIT (phải khớp giá trị).
extends Node3D

const REFLECTION_EXCLUDE_LAYER_BIT := 2

var _viewport: SubViewport
var _cam: Camera3D
var _main_camera: Camera3D
var _mirror_y := 0.0
var _delay_frames := 0
var _history: Array[Vector3] = []


func setup(main_camera: Camera3D, mirror_world_y: float, size := Vector2i(512, 512), delay_frames := 0) -> void:
	_main_camera = main_camera
	_mirror_y = mirror_world_y
	_delay_frames = delay_frames
	_viewport = SubViewport.new()
	_viewport.size = size
	_viewport.own_world_3d = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	_cam = Camera3D.new()
	_cam.cull_mask = ((1 << 20) - 1) & ~(1 << (REFLECTION_EXCLUDE_LAYER_BIT - 1))
	_cam.current = false
	_viewport.add_child(_cam)


func texture() -> ViewportTexture:
	return _viewport.get_texture()


func update(_delta: float) -> void:
	if _main_camera == null or _cam == null:
		return
	var origin: Vector3 = _main_camera.global_position
	var mirrored_origin := Vector3(origin.x, 2.0 * _mirror_y - origin.y, origin.z)
	var look_dir: Vector3 = -_main_camera.global_transform.basis.z
	var mirrored_look_dir := Vector3(look_dir.x, -look_dir.y, look_dir.z)
	var applied_origin := mirrored_origin
	if _delay_frames > 0:
		_history.append(mirrored_origin)
		if _history.size() > _delay_frames + 1:
			_history.pop_front()
		applied_origin = _history[0]
	_cam.global_position = applied_origin
	var up := Vector3.UP if absf(mirrored_look_dir.normalized().y) < 0.95 else Vector3.RIGHT
	_cam.look_at_from_position(applied_origin, applied_origin + mirrored_look_dir, up)
```

- [ ] **Step 4: Chạy lại test, xác nhận pass**

Run: `.\tools\Godot_v4.5-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_reflection_pool.gd`
Expected: `REFLECTION POOL OK`, exit 0.

- [ ] **Step 5: Gắn render layer loại-trừ vào player.gd**

Trong `scripts/player.gd`, thêm const ngay dưới `const ARM_REST_DROP := 0.95` (dòng 18):

```gdscript
const REFLECTION_EXCLUDE_LAYER_BIT := 2   # phải khớp reflection_pool.gd
```

Thêm hàm mới ngay sau `_disable_shadow_casting()` (kết thúc ở dòng 265):

```gdscript
func _tag_reflection_exclude(node: Node) -> void:
	if node is VisualInstance3D:
		node.layers = node.layers | (1 << (REFLECTION_EXCLUDE_LAYER_BIT - 1))
	for child in node.get_children():
		_tag_reflection_exclude(child)
```

Trong `_ready()`, ngay sau khối:

```gdscript
	if USE_MESH_BODY and _build_mesh_body():
		_use_mesh = true
```

(dòng 257-258), thêm:

```gdscript
	_tag_reflection_exclude(self)
```

Đặt sau khối trên (không phải trước) để bao phủ cả thân primitive lẫn thân mesh Đường-2, bất kể nhánh nào chạy.

- [ ] **Step 6: Parse-check**

Run: `.\tools\Godot_v4.5-stable_win64_console.exe --headless --path . --editor --quit`
Expected: không có `SCRIPT ERROR` liên quan `player.gd`.

- [ ] **Step 7: Commit**

```bash
git add scripts/reflection_pool.gd scripts/tests/test_reflection_pool.gd scripts/player.gd
git commit -m "feat(reflection): them reflection_pool dung chung + loai player khoi anh phan chieu"
```

---

### Task 5: Nối reflection vào giếng C2

**Files:**
- Modify: `scripts/c2.gd`

- [ ] **Step 1: Preload + biến**

Thêm const ngay dưới `const GhostWalker := preload("res://scripts/ghost_walker.gd")` (dòng 7):

```gdscript
const ReflectionPool := preload("res://scripts/reflection_pool.gd")
```

Thêm biến ngay dưới `var _well_orb: Node3D` (dòng 24):

```gdscript
var _well_reflection: ReflectionPool
var _right_well_water: MeshInstance3D
```

- [ ] **Step 2: Bắt lấy mesh nước của giếng phải + gắn ReflectionPool**

Trong `build()`, sửa vòng lặp giếng đôi (dòng 51-66) để lưu lại mesh nước bên phải (`sx == 2.2`):

```gdscript
	for sx in [-2.2, 2.2]:
		var stone := Build.mat(Color(0.24, 0.24, 0.26), 0.95)
		for rot in range(4):
			var ang := rot * PI / 2.0
			var rim := Build.box(self, Vector3(1.5, 0.6, 0.18), Vector3(sx, 0.3, -27.0) + Vector3(cos(ang), 0, sin(ang)) * 0.66, stone)
			rim.rotation.y = -ang
		var water := Build.box(self, Vector3(1.15, 0.02, 1.15), Vector3(sx, 0.5, -27.0), null)
		var wmat := StandardMaterial3D.new()
		wmat.albedo_color = Color(0.02, 0.06, 0.08)
		wmat.metallic = 0.9
		wmat.roughness = 0.06
		water.material_override = wmat
		if sx > 0:
			_right_well_water = water
		# khung gỗ + đòn ngang treo gàu
		for px in [-0.8, 0.8]:
			Build.cyl(self, 0.05, 0.06, 2.1, Vector3(sx + px, 1.05, -27.0), Build.mat(Color(0.16, 0.11, 0.07)), 8)
		Build.cyl(self, 0.04, 0.04, 1.8, Vector3(sx, 2.05, -27.0), Build.mat(Color(0.16, 0.11, 0.07)), 8).rotation.z = PI / 2.0
```

(Chỉ thêm 2 dòng `if sx > 0: _right_well_water = water` — phần còn lại giữ nguyên, chép lại đầy đủ ở trên để rõ vị trí chèn.)

Ngay sau vòng lặp giếng đôi và trước dòng dựng `glow` (dòng 67-69: `# ánh sáng dưới giếng phải...`), thêm:

```gdscript
	_well_reflection = ReflectionPool.new()
	add_child(_well_reflection)
	_well_reflection.setup(m.camera, 0.5, Vector2i(384, 384), 8)
	var refl_mat := StandardMaterial3D.new()
	refl_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	refl_mat.albedo_texture = _well_reflection.texture()
	refl_mat.emission_enabled = true
	refl_mat.emission_texture = _well_reflection.texture()
	refl_mat.emission_energy_multiplier = 0.9
	_right_well_water.material_override = refl_mat
```

- [ ] **Step 3: Cập nhật mỗi frame**

Trong `func update(delta: float) -> void:` (dòng 269), thêm dòng đầu tiên trong thân hàm:

```gdscript
func update(delta: float) -> void:
	if _well_reflection != null:
		_well_reflection.update(delta)
	_time += delta
```

(Giữ nguyên toàn bộ phần thân hàm còn lại phía sau `_time += delta`.)

- [ ] **Step 4: Parse-check + chạy lại gate C1 progression (không đụng C2 nhưng dùng chung Main) để chắc không phá import**

Run: `.\tools\Godot_v4.5-stable_win64_console.exe --headless --path . --editor --quit`
Expected: không có `SCRIPT ERROR` liên quan `c2.gd`.

- [ ] **Step 5: Commit**

```bash
git add scripts/c2.gd
git commit -m "feat(c2): giong phai dung ReflectionPool — phan chieu that, tre 8 khung, loai bong Minh"
```

---

### Task 6: Nối reflection vào vũng nước C5

**Files:**
- Modify: `scripts/c5.gd`

- [ ] **Step 1: Preload + biến**

Thêm const ngay dưới `const Build := preload("res://scripts/build.gd")` (dòng 5):

```gdscript
const ReflectionPool := preload("res://scripts/reflection_pool.gd")
```

Thêm biến ngay dưới `var _ground_done := false` (dòng 15):

```gdscript
var _puddle_reflection: ReflectionPool
```

- [ ] **Step 2: Gắn vào vũng nước đen**

Trong `build()`, sửa khối dựng vũng nước (dòng 100-107):

```gdscript
	# 1. Vũng nước đen (Water)
	var puddle = Build.cyl(self, 0.7, 0.7, 0.02, C + Vector3(3.0, -0.38, -5.0), null, 12)
	var pmat = StandardMaterial3D.new()
	pmat.albedo_color = Color(0.01, 0.02, 0.03)
	pmat.metallic = 0.9
	pmat.roughness = 0.05
	_puddle_reflection = ReflectionPool.new()
	add_child(_puddle_reflection)
	_puddle_reflection.setup(m.camera, C.y - 0.38, Vector2i(384, 384), 0)
	pmat.albedo_texture = _puddle_reflection.texture()
	pmat.emission_enabled = true
	pmat.emission_texture = _puddle_reflection.texture()
	pmat.emission_energy_multiplier = 0.5
	puddle.material_override = pmat
```

- [ ] **Step 3: Cập nhật mỗi frame**

Trong `func update(delta: float) -> void:` (dòng 226), thêm dòng đầu:

```gdscript
func update(delta: float) -> void:
	if _puddle_reflection != null:
		_puddle_reflection.update(delta)
	_time += delta
```

- [ ] **Step 4: Parse-check**

Run: `.\tools\Godot_v4.5-stable_win64_console.exe --headless --path . --editor --quit`
Expected: không có `SCRIPT ERROR` liên quan `c5.gd`.

- [ ] **Step 5: Commit**

```bash
git add scripts/c5.gd
git commit -m "feat(c5): vung nuoc dung ReflectionPool — nuoc khong nhan bong Minh la anh render that"
```

---

### Task 7: C1 — nghi lễ rót trà + evidence puzzle Chim Lạc + sửa `intro_beat` lỗi thời

**Files:**
- Modify: `scripts/c1.gd`
- Modify: `scripts/main.gd`
- Test: `scripts/tests/test_c1_progression.gd`

- [ ] **Step 1: Viết test trước cho nghi lễ rót trà (sẽ fail)**

Trong `scripts/tests/test_c1_progression.gd`, ngay sau dòng `var c1 = game.chapters[1]` (dòng 20) và trước `c1._try_descend()` (dòng 22), chèn:

```gdscript
	_check(not c1._tea_offered, "tea ritual should not start pre-offered")
	c1._offer_tea()
	await _settle(game)
	_check(not c1._tea_offered, "tea ritual should require talking to Ba first")

	c1._talk_ba()
	await _settle(game)
	c1._offer_tea()
	await _settle(game)
	_check(c1._tea_offered, "tea ritual was not recorded after offering tea")
	_check(game.narrative.evidence.has("c1_tea_ritual"), "tea ritual did not record evidence")
```

Sau dòng `_check(c1.bird_puzzle_solved, "C1 bird puzzle solved state missing")` (dòng 51), thêm:

```gdscript
	_check(game.narrative.evidence.has("c1_bird_stencil_memory_repaired"), "bird stencil puzzle did not record memory-repair evidence")
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `.\tools\Godot_v4.5-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_c1_progression.gd`
Expected: FAIL — `Invalid get index '_tea_offered'` (biến/hàm chưa tồn tại).

- [ ] **Step 3: Thêm nghi lễ rót trà vào c1.gd**

Thêm biến ngay dưới `var _ba_talked := false` — LƯU Ý: `_ba_talked` hiện đang khai báo ngay trước hàm `_talk_ba()` ở dòng 235 (không phải đầu file); thêm biến mới cạnh nó:

```gdscript
var _ba_talked := false
var _tea_offered := false
```

Sửa toàn bộ hàm `_talk_ba()` (dòng 236-253) thành:

```gdscript
func _talk_ba() -> void:
	if m.chapters[2].quest_stage == 1:
		m.chapters[2].ba_lore()
		return
	if not _ba_talked:
		_ba_talked = true
		m.say([
			["Bà Hàng Nước", "Trà còn nóng đó, cậu nhỏ. Ngồi xuống đi. Bà chờ khách... lâu lắm rồi."],
			["Minh", "Bà ơi... quán này đóng cửa từ khi cháu còn bé mà?"],
			["Bà Hàng Nước", "Đóng? À... phải. Bà cũng nhớ là có đóng. Nhưng cậu nhỏ này, NHỚ với CÒN — hai chữ đó ở phố này bây giờ là một đấy."],
			["Bà Hàng Nước", "Rót cho bà một chén đi. Khách tới quán, phải tự tay rót trước — bà không còn sức bưng ấm nữa."],
		], func(): m.ui.set_objective("Rót trà mời bà hàng nước"))
	elif not _tea_offered:
		m.say([["Bà Hàng Nước", "Ấm trà vẫn chờ đó, cậu nhỏ."]])
	elif not stall_inspected:
		m.open_memory_stall(self)
	elif puzzle.solved and _orb != null:
		m.say([["Bà Hàng Nước", "Đem lửa của bà đi. Đằng nào bà cũng không còn ai để pha trà."]])
	else:
		m.say([["Bà Hàng Nước", "Nhà sau quán không tự mở. Chim trong nhà cũng không tự bay."]])


func _offer_tea() -> void:
	if not _ba_talked:
		m.say([["Minh (nghĩ)", "Ấm trà không phải của tôi để tự ý rót."]])
		return
	if _tea_offered:
		m.open_memory_stall(self)
		return
	_tea_offered = true
	m.narrative.add_evidence("c1_tea_ritual", "Minh nghiêng ấm, rót một chén đầy mời bà hàng nước — nghi lễ đầu tiên của đêm.")
	m.say([
		["Minh (nghĩ)", "Tôi nghiêng ấm. Trà rót ra vẫn nóng, vẫn thơm — như chưa từng nguội suốt hai mươi năm."],
		["Bà Hàng Nước", "...Cảm ơn cậu nhỏ. Lâu lắm rồi mới có người rót trước, không đợi bà mời."],
	], func(): m.open_memory_stall(self))
```

Thêm interact mới ngay sau dòng đăng ký `_talk_ba` (dòng 106: `m.add_interact(Vector3(-4.7, 0, -5.5), 2.2, "Bà hàng nước / mở quầy ký ức", Callable(self, "_talk_ba"), false)`):

```gdscript
	m.add_interact(Vector3(-4.4, 0, -6.3), 1.8, "Rót trà mời bà — nghi lễ đầu tiên", Callable(self, "_offer_tea"), false)
```

- [ ] **Step 4: Gắn evidence vào puzzle Chim Lạc**

Trong `_on_puzzle_solved()` (dòng 323-331), thêm dòng đầu tiên trong thân hàm:

```gdscript
func _on_puzzle_solved() -> void:
	bird_puzzle_solved = true
	m.narrative.add_evidence("c1_bird_stencil_memory_repaired", "Ba mảnh giấy dó ghép đúng hình Chim Lạc — một ký ức bị xé lẻ của phố được ghép lại.")
	m.ui.play_chime()
	m.world.light_up()
	m.exit_puzzle_after(1.8)
	m.ui.toast("Chim Lạc đã rõ hình. Ấn Hỏa dưới nền nhà nứt ra.")
	_orb = Build.color_orb(self, _basement_pos + Vector3(0.8, 1.1, -0.35), Color(1.0, 0.3, 0.1))
	m.add_interact(_basement_pos + Vector3(0.8, 0, -0.35), 1.8, "Nhận SẮC HỎA từ ấn nứt", Callable(self, "_take_hoa"), true)
	m.ui.set_objective("Nhận SẮC HỎA cạnh giếng khô trong căn nhà.")
```

- [ ] **Step 5: Chạy lại test, xác nhận pass**

Run: `.\tools\Godot_v4.5-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_c1_progression.gd`
Expected: `C1 PROGRESSION OK`, exit 0.

- [ ] **Step 6: Sửa `_flow_test()` trong main.gd — dùng đúng hàm `enter_beat`, lái qua nghi lễ trà**

Tìm khối đầu `_flow_test()` (dòng 1293-1297):

```gdscript
	var c1 = chapters[1]
	c1.intro_beat()
	await _wait_dialogue()
	c1._talk_ba()
	await _wait_dialogue_only()
```

Sửa thành:

```gdscript
	var c1 = chapters[1]
	c1.enter_beat()
	await _wait_dialogue()
	c1._talk_ba()
	await _wait_dialogue()
	c1._offer_tea()
	await _wait_dialogue_only()
```

Giữ nguyên phần theo sau (khối `for id in MemoryStallInspectUI.REQUIRED_FOR_KEY: memory_stall.inspect_item(id)` ...).

- [ ] **Step 7: Parse-check**

Run: `.\tools\Godot_v4.5-stable_win64_console.exe --headless --path . --editor --quit`
Expected: không có `SCRIPT ERROR` liên quan `c1.gd`, `main.gd`.

- [ ] **Step 8: Commit**

```bash
git add scripts/c1.gd scripts/main.gd scripts/tests/test_c1_progression.gd
git commit -m "feat(c1): nghi le rot tra cho ba hang nuoc + evidence puzzle Chim Lac; fix goi ham intro_beat sai ten trong flow test"
```

---

### Task 8: C2 — logic mâu thuẫn radio-vs-giếng

**Files:**
- Modify: `scripts/c2.gd`

- [ ] **Step 1: Sửa `_look_well()` để tách callback ra hàm riêng có ghi contradiction**

Hàm hiện tại (dòng 150-174):

```gdscript
var _looked := false
func _look_well() -> void:
	if not _child_talked:
		m.say([["Minh (nghĩ)", "Nước giếng đen như mực mài. Có ánh gì le lói rất sâu... để sau. Đi tiếp cái đã."]])
		return
	if _looked:
		return
	_looked = true
	m.say([
		["Minh (nghĩ)", "Mặt nước theo chậm hơn một nhịp. Tôi nghiêng đầu — bóng dưới kia vẫn đứng yên."],
		["Minh (nghĩ)", "Một gợn sóng chạy qua. Chỗ lẽ ra là mặt tôi lại mở ra PHỐ — còn sáng đèn, nguyên vẹn, đông người... lộn ngược."],
		["Minh (nghĩ)", "Đáy giếng đang giữ cái phố mà tôi nhớ."],
		["Đứa Trẻ Soi Giếng", "Anh thấy chưa. Anh lấy một ít về đi — nước ở đây nhớ dai lắm."],
	], func(): m.remote_voice(
		"c2_well_contradiction",
		0.36,
		[
			"Rời giếng đi. Cái dưới nước chỉ nhại lại ký ức của cậu thôi.",
			["Minh (nghĩ)", "Không. Nó không nhại. Nó chậm hơn tôi — và chỗ đáng lẽ là mặt tôi lại là một con phố nguyên vẹn."],
		],
		func(): _spawn_thuy(),
		-12,
		"well_reflection",
		"Well reflection lags behind the player and shows the intact inverted town instead of Minh's face."
	))
```

Sửa dòng `func(): _spawn_thuy(),` thành `Callable(self, "_confirm_well_contradiction"),`, và thêm hàm mới ngay sau `_look_well()`:

```gdscript
var _looked := false
func _look_well() -> void:
	if not _child_talked:
		m.say([["Minh (nghĩ)", "Nước giếng đen như mực mài. Có ánh gì le lói rất sâu... để sau. Đi tiếp cái đã."]])
		return
	if _looked:
		return
	_looked = true
	m.say([
		["Minh (nghĩ)", "Mặt nước theo chậm hơn một nhịp. Tôi nghiêng đầu — bóng dưới kia vẫn đứng yên."],
		["Minh (nghĩ)", "Một gợn sóng chạy qua. Chỗ lẽ ra là mặt tôi lại mở ra PHỐ — còn sáng đèn, nguyên vẹn, đông người... lộn ngược."],
		["Minh (nghĩ)", "Đáy giếng đang giữ cái phố mà tôi nhớ."],
		["Đứa Trẻ Soi Giếng", "Anh thấy chưa. Anh lấy một ít về đi — nước ở đây nhớ dai lắm."],
	], func(): m.remote_voice(
		"c2_well_contradiction",
		0.36,
		[
			"Rời giếng đi. Cái dưới nước chỉ nhại lại ký ức của cậu thôi.",
			["Minh (nghĩ)", "Không. Nó không nhại. Nó chậm hơn tôi — và chỗ đáng lẽ là mặt tôi lại là một con phố nguyên vẹn."],
		],
		Callable(self, "_confirm_well_contradiction"),
		-12,
		"well_reflection",
		"Well reflection lags behind the player and shows the intact inverted town instead of Minh's face."
	))


func _confirm_well_contradiction() -> void:
	m.narrative.record_contradiction(
		"c2_well_vs_radio_shortcut",
		"Trạm Bốn bảo bỏ qua giếng vì nó 'chỉ nhại ký ức', nhưng giếng cho thấy phố nguyên vẹn lộn ngược — chi tiết mà radio không thể biết nếu nó chỉ đang nhại lại trí nhớ của Minh."
	)
	_spawn_thuy()
```

- [ ] **Step 2: Viết test trước cho hành vi mới**

Vì `_look_well()` cần `_child_talked = true` trước, và cần một `Main` instance đầy đủ (dùng `m.remote_voice`/`m.narrative`), thêm assertion vào `scripts/tests/test_c1_progression.gd` là sai chỗ (đó là file C1) — tạo test tích hợp riêng nhẹ cho C2 thay vì mở rộng C1. Tạo `scripts/tests/test_c2_well_contradiction.gd`:

```gdscript
extends SceneTree

const Main := preload("res://scripts/main.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := Main.new()
	root.add_child(game)
	await process_frame
	game.dialogue.auto_advance = true
	game.state = game.State.PLAY
	game.ui.hide_intro()
	game.goto_chapter(2)
	await _until(func(): return game.chapter_no == 2 and game.state == game.State.PLAY, "vao C2", game)

	var c2 = game.chapters[2]
	c2._talk_child()
	await _settle(game)
	c2._look_well()
	await _settle(game)

	_check(game.narrative.contradictions.has("c2_well_vs_radio_shortcut"), "well contradiction was not recorded")
	_check(game.narrative.evidence.has("well_reflection"), "well reflection evidence was not recorded")
	_check(c2.has_thuy, "Sac Thuy did not unlock after well contradiction")

	game.queue_free()
	if failures.is_empty():
		print("C2 WELL CONTRADICTION OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _settle(game) -> void:
	for _i in range(20):
		if game.dialogue.active:
			game.dialogue._process(0.25)
		await process_frame


func _until(cond: Callable, label: String, game, timeout_frames := 240) -> void:
	for _i in range(timeout_frames):
		if cond.call():
			return
		if game.dialogue.active:
			game.dialogue._process(0.25)
		await process_frame
	failures.append("timeout: " + label)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
```

- [ ] **Step 3: Chạy test — trước khi sửa `_look_well()` phải fail, sau khi sửa phải pass**

Run: `.\tools\Godot_v4.5-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_c2_well_contradiction.gd`
Expected trước Step 1: FAIL (`contradictions` rỗng vì `_confirm_well_contradiction` chưa tồn tại/chưa được gọi).
Expected sau Step 1: `C2 WELL CONTRADICTION OK`, exit 0.

(Nếu thực thi theo đúng thứ tự TDD, chạy bước này NGAY SAU Step 2 nhưng TRƯỚC khi áp Step 1 để xác nhận fail, rồi áp Step 1 và chạy lại để xác nhận pass — thứ tự liệt kê ở trên gộp lại cho gọn tài liệu.)

- [ ] **Step 4: Thêm gate mới vào `tools/run_quality_gates.ps1`**

Xem Task 9 — gộp việc thêm gate cho `test_c2_well_contradiction.gd`, `test_memorial_tablet_ui.gd`, `test_reflection_pool.gd` vào một chỗ để tránh sửa file gate nhiều lần.

- [ ] **Step 5: Commit**

```bash
git add scripts/c2.gd scripts/tests/test_c2_well_contradiction.gd
git commit -m "feat(c2): ghi nhan mau thuan radio-vs-gieng vao narrative.contradictions"
```

---

### Task 9: Thêm gate mới + cập nhật state tracking của project

**Files:**
- Modify: `tools/run_quality_gates.ps1`
- Modify: `.state/tasks/script-v3-cinematic-rebuild/repos/hoa-hon-den-long-godot.md`
- Modify: `docs/SCRIPT-V3-IMPLEMENTATION-MATRIX.md`

- [ ] **Step 1: Thêm 3 gate mới vào `tools/run_quality_gates.ps1`**

Chèn ngay sau khối gate `'bird stencil puzzle'` (dòng 48-50) và trước khối `'chapter 1 progression locks'` (dòng 52):

```powershell
Run-Gate 'memorial tablet UI' {
    & $GodotPath --headless --path . --script res://scripts/tests/test_memorial_tablet_ui.gd
}

Run-Gate 'reflection pool' {
    & $GodotPath --headless --path . --script res://scripts/tests/test_reflection_pool.gd
}

Run-Gate 'C2 well contradiction' {
    & $GodotPath --headless --path . --script res://scripts/tests/test_c2_well_contradiction.gd
}

```

- [ ] **Step 2: Chạy toàn bộ gate (trừ `--flow`, quá nặng cho máy này — xem Task 10)**

Run: `.\tools\run_quality_gates.ps1 -SkipFlow`
Expected: mọi gate in `GATE PASS: <tên>`, kết thúc `QUALITY GATES OK`. Ghi chú: cảnh báo `ObjectDB instances leaked at exit` sau một số gate là benign (đã ghi trong `.state/` từ trước), không phải fail thật — chỉ fail thật nếu dòng `GATE FAILED: <tên>` xuất hiện.

- [ ] **Step 3: Cập nhật state tracking của project**

Trong `.state/tasks/script-v3-cinematic-rebuild/repos/hoa-hon-den-long-godot.md`, thêm một dòng vào mục "Repo progress > Done" mô tả 5 gap vừa đóng (bài vị C3, reflection dùng chung C2/C5, nghi lễ trà + evidence C1, contradiction C2, gate mới), và cập nhật "Next repo step" sang "chạy `--flow` đầy đủ + QA hình ảnh trên máy có GPU (Task 10 của plan `docs/superpowers/plans/2026-07-01-close-c1-c5-gaps.md`)".

Trong `docs/SCRIPT-V3-IMPLEMENTATION-MATRIX.md`, cập nhật dòng `CC1` (reflection) từ `partial` — ghi rõ giếng C2 và vũng nước C5 nay có reflection render thật (viewport), còn thiếu: gương đồng C4 (không nằm trong scope 5 gap lần này) và QA hình ảnh thật. Cập nhật dòng `C3` từ `fail` lên `partial` — bài vị đã có, "Interior procedural; workshop evidence incomplete" vẫn còn treo.

- [ ] **Step 4: Commit**

```bash
git add tools/run_quality_gates.ps1 .state/tasks/script-v3-cinematic-rebuild/repos/hoa-hon-den-long-godot.md docs/SCRIPT-V3-IMPLEMENTATION-MATRIX.md
git commit -m "chore(qa): them 3 gate moi (bai vi, reflection, C2 contradiction) + cap nhat state tracking"
```

---

### Task 10: Xác nhận thủ công trên máy có GPU (không phải code — user tự chạy)

Máy dùng để audit/plan (môi trường này) không có GPU/display, nên `--flow` từng bị treo >5 phút khi thử chạy audit ban đầu — không loại trừ khả năng đây chỉ là scene quá nặng cho render CPU-only (baseline cũ là 70.8s trước khi có mesh rig + PBR full C1 + lantern). Sau khi 9 task trên xong, cần user tự chạy trên máy thật:

- [ ] **Step 1: Full quality gate kể cả `--flow`**

Run: `.\tools\run_quality_gates.ps1`
Expected: `QUALITY GATES OK`, và log gate `--flow` in ra `FLOW OK — het 5 chuong, choice persisted, outcome=release`.

- [ ] **Step 2: Chơi thật, xác nhận 3 mảng vừa thêm bằng mắt**

Run: `.\tools\Godot_v4.5-stable_win64_console.exe --path .`

Kiểm tra:
1. C1: đứng gần quầy nước, tương tác "Rót trà mời bà" PHẢI xảy ra trước khi quầy ký ức mở được — nếu bấm "Bà hàng nước" trước, bà chỉ nhắc rót trà chứ không mở quầy.
2. C3: tương tác bài vị trên bàn thờ, gõ một tên bất kỳ (kể cả "Minh") — bài vị phải luôn từ chối, không bao giờ chấp nhận.
3. C2: soi giếng bên phải sau khi nói chuyện với đứa trẻ — mặt nước phải là ảnh render thật (không phải mô tả chữ), Minh không xuất hiện trong ảnh phản chiếu, ảnh trễ nhịp so với chuyển động camera.
4. C5: đứng cạnh vũng nước đen với Sắc Thủy, xác nhận vũng nước phản chiếu môi trường xung quanh cầu nhưng không có bóng Minh.

- [ ] **Step 3: Báo lại kết quả**

Nếu có mismatch (ví dụ reflection bị lật ngược, delay quá dài/ngắn, UI bài vị che khuất HUD), ghi lại cụ thể triệu chứng + bước tái hiện để xử lý tiếp — đây là thứ máy audit này không thể tự kiểm chứng được.

---

## Self-review

- **Phạm vi:** cả 5 gap đã duyệt đều có task tương ứng (C3: Task 2-3; reflection dùng chung: Task 4, áp dụng ở Task 5 (C2) và Task 6 (C5); C1 ritual+evidence: Task 7; C2 contradiction: Task 8; re-run flow: Task 10). Task 1 và Task 9 là nền/đóng gói, không phải gap riêng.
- **Placeholder:** không còn `TODO`/`tương tự Task N` — mọi step có code đầy đủ, kể cả các đoạn "sửa dòng X thành Y" đều chép nguyên văn cả khối để không mơ hồ.
- **Type/tên nhất quán đã kiểm tra chéo:** `ReflectionPool.REFLECTION_EXCLUDE_LAYER_BIT` (2) khớp `player.gd` `REFLECTION_EXCLUDE_LAYER_BIT` (2); `open_memorial_tablet`/`_on_memorial_tablet_closed` (main.gd) khớp `on_memorial_tablet_closed` (c3.gd); `record_contradiction` (narrative_state.gd) khớp cách gọi ở c2.gd; `m.narrative.evidence.has(...)` dùng đúng field `evidence: Dictionary` đã có sẵn, không bịa field mới.
- **Rủi ro còn lại ngoài phạm vi 5 gap:** gương đồng C4 (khúc xạ tia trăng) vẫn KHÔNG dùng `ReflectionPool` — đó là một cơ chế puzzle khác (phản xạ tia sáng, không phải ảnh phản chiếu người chơi), không nằm trong 5 gap đã duyệt nên không đụng vào.
