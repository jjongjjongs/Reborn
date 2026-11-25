extends CanvasLayer
## Shared pause button + overlay (autoload). Gameplay modes call Pause.arm() in
## _ready and Pause.disarm() when a result screen takes over. Runs while paused
## (process_mode ALWAYS) so its buttons stay responsive.

var _paused_by_us := false
var _btn: Button
var _overlay: Control

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
	v.add_child(_menu_btn("메뉴로", 28, _to_menu))
	add_child(_overlay)

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
