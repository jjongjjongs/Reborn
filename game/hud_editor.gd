extends Control
## HUD button layout editor. Grid overlay + drag to move + size slider.
## Edits fire/jump/reload/crouch/nade/scope (move stick stays dynamic; the scope
## key only shows in play with a scoped weapon, but is always placeable here). Saves fractions to
## Controls.hud_layout. Launched from Settings; returns to the menu.

const BASE := {"fire": 100.0, "jump": 66.0, "reload": 66.0, "crouch": 58.0, "nade": 58.0, "scope": 54.0}
const LABELS := {"fire": "사격", "jump": "점프", "reload": "장전", "crouch": "앉기", "nade": "수류탄", "scope": "조준경"}
const KEYS := ["fire", "jump", "reload", "crouch", "nade", "scope"]

var _layout := {}          # key -> {x,y (frac 0..1), s (scale)}
var _sel := "fire"
var _drag := ""
var _snap := false
var _slider: HSlider
var _font: Font

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = ThemeDB.fallback_font
	_init_layout()
	_build_bar()

func _init_layout() -> void:
	var s := size
	for key in KEYS:
		if Controls.hud_layout.has(key):
			var d: Dictionary = Controls.hud_layout[key]
			_layout[key] = {"x": float(d.get("x", 0.5)), "y": float(d.get("y", 0.5)), "s": float(d.get("s", 1.0))}
		elif Controls.DEFAULT_LAYOUT.has(key):
			_layout[key] = (Controls.DEFAULT_LAYOUT[key] as Dictionary).duplicate()
		else:
			var c := _default_center(key, s)
			_layout[key] = {"x": c.x / s.x, "y": c.y / s.y, "s": 1.0}

func _default_center(key: String, s: Vector2) -> Vector2:
	var lh := Controls.left_handed
	var fx := 150.0 if lh else s.x - 150.0
	var rx := 370.0 if lh else s.x - 370.0
	match key:
		"fire": return Vector2(fx, s.y - 160.0)
		"jump": return Vector2(fx, s.y - 380.0)
		"reload": return Vector2(rx, s.y - 160.0)
		"crouch": return Vector2(330.0 if lh else s.x - 330.0, s.y - 330.0)
		"nade": return Vector2(560.0 if lh else s.x - 560.0, s.y - 150.0)
		"scope": return Vector2(s.x * 0.785, s.y * 0.32)
	return s * 0.5

func _center(key: String) -> Vector2:
	return Vector2(_layout[key]["x"] * size.x, _layout[key]["y"] * size.y)

func _radius(key: String) -> float:
	return BASE[key] * float(_layout[key]["s"])

func _hit(pos: Vector2) -> String:
	for key in KEYS:
		if pos.distance_to(_center(key)) <= _radius(key):
			return key
	return ""

func _commit() -> void:
	Controls.hud_layout = _layout.duplicate(true)

func _gui_input(event: InputEvent) -> void:
	var pos := Vector2.ZERO
	var pressed := false
	var released := false
	var moving := false
	if event is InputEventScreenTouch:
		pos = (event as InputEventScreenTouch).position
		pressed = (event as InputEventScreenTouch).pressed
		released = not pressed
	elif event is InputEventMouseButton:
		pos = (event as InputEventMouseButton).position
		pressed = (event as InputEventMouseButton).pressed
		released = not pressed
	elif event is InputEventScreenDrag:
		pos = (event as InputEventScreenDrag).position; moving = true
	elif event is InputEventMouseMotion and (event as InputEventMouseMotion).button_mask != 0:
		pos = (event as InputEventMouseMotion).position; moving = true
	else:
		return

	if pressed:
		var hit := _hit(pos)
		if hit != "":
			_sel = hit; _drag = hit
			if _slider: _slider.set_value_no_signal(float(_layout[hit]["s"]))
			queue_redraw()
	elif released:
		if _drag != "":
			_commit()
		_drag = ""
	elif moving and _drag != "":
		var fx := clampf(pos.x / size.x, 0.05, 0.95)
		var fy := clampf(pos.y / size.y, 0.05, 0.95)
		if _snap:
			fx = roundf(fx / 0.025) * 0.025
			fy = roundf(fy / 0.025) * 0.025
		_layout[_drag]["x"] = fx
		_layout[_drag]["y"] = fy
		queue_redraw()

func _draw() -> void:
	# grid
	var step := size.x / 40.0
	var gc := Color(1, 1, 1, 0.06)
	var x := 0.0
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), gc, 1.0)
		x += step
	var y := 0.0
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), gc, 1.0)
		y += step
	# buttons
	for key in ["scope", "nade", "crouch", "reload", "jump", "fire"]:
		var c := _center(key)
		var r := _radius(key)
		var tint := Color(1.0, 0.36, 0.22) if key == "fire" else Color(0.8, 0.85, 0.9)
		draw_circle(c, r, Color(tint.r, tint.g, tint.b, 0.18))
		draw_arc(c, r, 0.0, TAU, 48, tint, 3.0, true)
		if key == _sel:
			draw_arc(c, r + 7.0, 0.0, TAU, 48, Color(1.0, 0.61, 0.24), 2.5, true)
		var fs := 30 if BASE[key] > 60.0 else 24
		var sz := _font.get_string_size(LABELS[key], HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string(_font, c - Vector2(sz.x * 0.5, -fs * 0.35), LABELS[key],
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.95))

func _build_bar() -> void:
	var bar := PanelContainer.new()
	bar.anchor_left = 0.5; bar.anchor_right = 0.5; bar.anchor_top = 0.0
	bar.offset_left = -360; bar.offset_right = 360; bar.offset_top = 16; bar.offset_bottom = 84
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.06, 0.09, 0.12, 0.95)
	sb.set_border_width_all(1); sb.border_color = Color(0.18, 0.22, 0.26); sb.set_corner_radius_all(12)
	sb.set_content_margin_all(10)
	bar.add_theme_stylebox_override("panel", sb)
	add_child(bar)
	var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 14)
	bar.add_child(h)
	var t := Label.new(); t.text = "HUD 편집"; t.add_theme_font_size_override("font_size", 22)
	t.add_theme_color_override("font_color", Color(1.0, 0.72, 0.38))
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(t)
	var sl := Label.new(); sl.text = "크기"; sl.add_theme_font_size_override("font_size", 18)
	sl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; h.add_child(sl)
	_slider = HSlider.new()
	_slider.min_value = 0.6; _slider.max_value = 1.7; _slider.step = 0.05
	_slider.value = float(_layout[_sel]["s"])
	_slider.custom_minimum_size = Vector2(160, 30)
	_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_slider.value_changed.connect(func(v: float) -> void:
		_layout[_sel]["s"] = v; queue_redraw())
	h.add_child(_slider)
	var snap := CheckButton.new(); snap.text = "격자"; snap.button_pressed = false; snap.focus_mode = Control.FOCUS_NONE
	snap.toggled.connect(func(on: bool) -> void: _snap = on)
	h.add_child(snap)
	h.add_child(_btn("리셋", _on_reset))
	h.add_child(_btn("완료", _on_done, true))

func _on_reset() -> void:
	Controls.reset_hud()
	_init_layout()
	if _slider:
		_slider.set_value_no_signal(float(_layout[_sel]["s"]))
	queue_redraw()

func _on_done() -> void:
	_commit()
	Controls.save_settings()
	Sfx.play("ui")
	get_tree().change_scene_to_file("res://Menu.tscn")

func _btn(txt: String, cb: Callable, pri := false) -> Button:
	var b := Button.new(); b.text = txt; b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 20)
	if pri:
		b.add_theme_color_override("font_color", Color(1.0, 0.72, 0.38))
	b.pressed.connect(cb)
	return b
