extends CanvasLayer
## Shared pause button + overlay (autoload). Gameplay modes call Pause.arm() in
## _ready and Pause.disarm() when a result screen takes over. Runs while paused
## (process_mode ALWAYS) so its buttons stay responsive.

var _paused_by_us := false
var _btn: Button
var _overlay: Control
var _quit_box: Control

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	disarm()

func arm() -> void:
	if _btn: _btn.visible = true

func disarm() -> void:
	if _btn: _btn.visible = false
	if _overlay: _overlay.visible = false
	if _paused_by_us:
		get_tree().paused = false
		_paused_by_us = false

func _build() -> void:
	_btn = Button.new()
	_btn.text = "❚❚"
	_btn.add_theme_font_size_override("font_size", 26)
	_btn.focus_mode = Control.FOCUS_NONE
	_btn.anchor_left = 1.0; _btn.anchor_right = 1.0
	_btn.offset_left = -84; _btn.offset_right = -20
	_btn.offset_top = 18; _btn.offset_bottom = 74
	_btn.pressed.connect(_open)
	add_child(_btn)

	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new(); bg.color = Color(0.05, 0.07, 0.09, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(bg)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.anchor_left = 0.5; v.anchor_right = 0.5; v.anchor_top = 0.5; v.anchor_bottom = 0.5
	v.offset_left = -200; v.offset_right = 200; v.offset_top = -150; v.offset_bottom = 150
	v.add_theme_constant_override("separation", 20)
	_overlay.add_child(v)
	var t := Label.new(); t.text = "일시정지"
	t.add_theme_font_size_override("font_size", 46)
	t.add_theme_color_override("font_color", Color(1.0, 0.72, 0.38))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	v.add_child(_menu_btn("계속하기", 34, _resume))
	v.add_child(_menu_btn("설정", 28, func() -> void: Sfx.play("ui"); Settings.open()))
	v.add_child(_menu_btn("메뉴로", 28, _to_menu))
	add_child(_overlay)
	_build_quit_box()

func _menu_btn(txt: String, fs: int, cb: Callable) -> Button:
	var b := Button.new(); b.text = txt
	b.add_theme_font_size_override("font_size", fs)
	b.custom_minimum_size = Vector2(300, 64)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b

func _open() -> void:
	if get_tree().paused:
		return   # already paused by something else (e.g. result/shop)
	Sfx.play("ui")
	get_tree().paused = true
	_paused_by_us = true
	_overlay.visible = true

func _resume() -> void:
	Sfx.play("ui")
	get_tree().paused = false
	_paused_by_us = false
	_overlay.visible = false

func _to_menu() -> void:
	Sfx.play("ui")
	get_tree().paused = false
	_paused_by_us = false
	_overlay.visible = false
	disarm()
	Controls.reset()
	get_tree().change_scene_to_file("res://Menu.tscn")

# ---- Android back button (quit_on_go_back is off) ----
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back()

func _on_back() -> void:
	# close the topmost overlay first
	var eds := get_tree().get_nodes_in_group("hud_editor")
	if not eds.is_empty() and eds[0].get("overlay"):
		eds[0]._on_done(); return
	if Settings.is_open():
		Settings.close(); return
	if Updater.is_open():
		Updater.close_dialog(); return
	if _quit_box.visible:
		get_tree().quit(); return            # second back on the quit prompt = quit
	if _overlay.visible:
		_resume(); return
	var scene := get_tree().current_scene
	var path := scene.scene_file_path if scene else ""
	if path.ends_with("Menu.tscn"):
		# menu sub-screens (출격 준비, 장비): close the topmost one
		var top: Control = null
		for c in scene.get_children():
			if c is SortieScreen or c is LoadoutScreen or c is ShopScreen or c is RecordsScreen: top = c
		if top != null:
			for c in top.get_children():
				if c is LoadoutScreen: top = c
			top.queue_free(); return
		_quit_box.visible = true; return
	if path.ends_with("HudEditor.tscn"):
		if scene.has_method("_on_done"): scene._on_done()
		else: get_tree().change_scene_to_file("res://Menu.tscn")
		return
	if _btn.visible and not get_tree().paused:
		_open(); return                      # in a match: back opens pause
	# result screen / anything else paused: leave to menu
	_to_menu()

func _build_quit_box() -> void:
	_quit_box = Control.new()
	_quit_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_quit_box.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new(); bg.color = Color(0.03, 0.04, 0.06, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_quit_box.add_child(bg)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.anchor_left = 0.5; v.anchor_right = 0.5; v.anchor_top = 0.5; v.anchor_bottom = 0.5
	v.offset_left = -220; v.offset_right = 220; v.offset_top = -120; v.offset_bottom = 120
	v.add_theme_constant_override("separation", 18)
	_quit_box.add_child(v)
	var t := Label.new(); t.text = "게임을 종료할까요?"
	t.add_theme_font_size_override("font_size", 34)
	t.add_theme_color_override("font_color", Color(1.0, 0.72, 0.38))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var h := HBoxContainer.new(); h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 14)
	var cancel := _menu_btn("취소", 26, func() -> void: Sfx.play("ui"); _quit_box.visible = false)
	cancel.custom_minimum_size = Vector2(180, 60)
	var quit := _menu_btn("종료", 26, func() -> void: get_tree().quit())
	quit.custom_minimum_size = Vector2(180, 60)
	quit.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
	h.add_child(cancel); h.add_child(quit)
	v.add_child(h)
	_quit_box.visible = false
	add_child(_quit_box)
