extends CanvasLayer
## Settings overlay (autoload). Opened from the menu's 설정 tab and the pause
## overlay. Writes straight to Controls and persists via Controls.save_settings().

var _sheet: Control
var _sens_val: Label
var _ssens_val: Label

func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_sheet.visible = false

func open() -> void:
	_sync()
	_sheet.visible = true

func close() -> void:
	_sheet.visible = false

func _build() -> void:
	_sheet = Control.new()
	_sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sheet.process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new(); bg.color = Color(0.04, 0.06, 0.08, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_sheet.add_child(bg)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5; panel.anchor_right = 0.5; panel.anchor_top = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -280; panel.offset_right = 280; panel.offset_top = -230; panel.offset_bottom = 230
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.12, 0.15); sb.set_border_width_all(1); sb.border_color = Color(0.18, 0.22, 0.26)
	sb.set_corner_radius_all(16); sb.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", sb)
	_sheet.add_child(panel)

	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	var head := HBoxContainer.new()
	var ti := Label.new(); ti.text = "설정"
	ti.add_theme_font_size_override("font_size", 34)
	ti.add_theme_color_override("font_color", Color(1.0, 0.72, 0.38))
	ti.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(ti)
	var x := Button.new(); x.text = "닫기"; x.focus_mode = Control.FOCUS_NONE
	x.add_theme_font_size_override("font_size", 22)
	x.pressed.connect(func() -> void: Sfx.play("ui"); close())
	head.add_child(x)
	v.add_child(head)
	v.add_child(_sep())

	v.add_child(_toggle("효과음", "총성·피격·UI 사운드", Controls.sfx_on, func(on: bool) -> void:
		Controls.sfx_on = on; Controls.save_settings()
		if on: Sfx.play("ui")))
	v.add_child(_toggle("진동", "피격·햅틱", Controls.vibrate_on, func(on: bool) -> void:
		Controls.vibrate_on = on; Controls.save_settings()
		if on: Controls.vibrate(40)))

	v.add_child(_toggle("저격총 누르고 떼서 쏘기", "누르면 조준경 · 떼면 발사 후 조준 해제", Controls.sniper_hold, func(on: bool) -> void:
		Controls.sniper_hold = on; Controls.save_settings()))
	# sensitivity
	var srow := VBoxContainer.new()
	var sh := HBoxContainer.new()
	var sl := Label.new(); sl.text = "시점 감도"; sl.add_theme_font_size_override("font_size", 24)
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sh.add_child(sl)
	_sens_val = Label.new(); _sens_val.add_theme_font_size_override("font_size", 24)
	_sens_val.add_theme_color_override("font_color", Color(1.0, 0.72, 0.38))
	sh.add_child(_sens_val)
	srow.add_child(sh)
	var slider := HSlider.new()
	slider.min_value = 0.4; slider.max_value = 2.0; slider.step = 0.1; slider.value = Controls.look_sens
	slider.custom_minimum_size = Vector2(0, 34)
	slider.value_changed.connect(func(val: float) -> void:
		Controls.look_sens = val; _sens_val.text = "%.1f×" % val; Controls.save_settings())
	srow.add_child(slider)
	v.add_child(srow)
	# scope sensitivity (applies while looking through the sniper scope)
	var srow2 := VBoxContainer.new()
	var sh2 := HBoxContainer.new()
	var sl2 := Label.new(); sl2.text = "조준경 감도"; sl2.add_theme_font_size_override("font_size", 24)
	sl2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sh2.add_child(sl2)
	_ssens_val = Label.new(); _ssens_val.add_theme_font_size_override("font_size", 24)
	_ssens_val.add_theme_color_override("font_color", Color(1.0, 0.72, 0.38))
	sh2.add_child(_ssens_val)
	srow2.add_child(sh2)
	var slider2 := HSlider.new()
	slider2.min_value = 0.2; slider2.max_value = 1.5; slider2.step = 0.05; slider2.value = Controls.scope_sens
	slider2.custom_minimum_size = Vector2(0, 34)
	slider2.value_changed.connect(func(val: float) -> void:
		Controls.scope_sens = val; _ssens_val.text = "%.2f×" % val; Controls.save_settings())
	srow2.add_child(slider2)
	v.add_child(srow2)
	v.add_child(_sep())

	var he := Button.new(); he.text = "HUD 버튼 편집  ›"; he.focus_mode = Control.FOCUS_NONE
	he.alignment = HORIZONTAL_ALIGNMENT_LEFT
	he.add_theme_font_size_override("font_size", 24)
	he.flat = true
	he.pressed.connect(_open_hud_editor)
	v.add_child(he)

	var ver := Label.new()
	ver.text = "버전 %s" % _app_version()
	ver.add_theme_font_size_override("font_size", 18)
	ver.add_theme_color_override("font_color", Color(0.45, 0.52, 0.58))
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(ver)

	add_child(_sheet)

func _open_hud_editor() -> void:
	Sfx.play("ui")
	close()
	var scene := get_tree().current_scene
	var in_menu := scene == null or scene.scene_file_path.ends_with("Menu.tscn")
	if in_menu:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://HudEditor.tscn")
		return
	# in a match (paused): edit on top of it and come back, the match keeps its state
	var cl := CanvasLayer.new(); cl.layer = 97; cl.process_mode = Node.PROCESS_MODE_ALWAYS
	var ed: Control = (load("res://HudEditor.tscn") as PackedScene).instantiate()
	ed.set("overlay", true)
	cl.add_child(ed)
	get_tree().root.add_child(cl)

func _sync() -> void:
	if _sens_val:
		_sens_val.text = "%.1f×" % Controls.look_sens
	if _ssens_val:
		_ssens_val.text = "%.2f×" % Controls.scope_sens

func _toggle(title: String, sub: String, on: bool, cb: Callable) -> Control:
	var row := HBoxContainer.new()
	var left := VBoxContainer.new(); left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 0)
	var t := Label.new(); t.text = title; t.add_theme_font_size_override("font_size", 24)
	left.add_child(t)
	var s := Label.new(); s.text = sub; s.add_theme_font_size_override("font_size", 16)
	s.add_theme_color_override("font_color", Color(0.45, 0.52, 0.58))
	left.add_child(s)
	row.add_child(left)
	var cbx := CheckButton.new(); cbx.button_pressed = on; cbx.focus_mode = Control.FOCUS_NONE
	cbx.toggled.connect(cb)
	row.add_child(cbx)
	return row

func _sep() -> Control:
	var r := ColorRect.new(); r.color = Color(0.18, 0.22, 0.26)
	r.custom_minimum_size = Vector2(0, 1)
	return r

func _app_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "1.9"))

func is_open() -> bool:
	return _sheet != null and _sheet.visible
