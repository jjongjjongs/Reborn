class_name ResultScreen
extends Control
## M5 run-end overlay: victory/defeat, stats, local best, restart. Processes
## while the tree is paused (set at game over) so its button still works.

var _panel: ColorRect
var _box: VBoxContainer
var _title: Label
var _stats: Label
var _coins: Label
var _best: Label
var _btn: Button
var _menu_btn: Button

func _ready() -> void:
	Pause.disarm()
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_panel = ColorRect.new()
	_panel.color = Color(0.05, 0.07, 0.09, 0.97)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)
	# one centred column: title, stats, coins, best, buttons (never overlap, whatever the text length)
	var cc := CenterContainer.new(); add_child(cc); cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_box = VBoxContainer.new(); _box.add_theme_constant_override("separation", 10)
	_box.custom_minimum_size = Vector2(680, 0)
	cc.add_child(_box)
	_title = _lbl(44, Color(1.0, 0.72, 0.38))
	_stats = _lbl(28, Color(0.92, 0.94, 0.92))
	_coins = _lbl(28, Color(1.0, 0.82, 0.30))
	_best = _lbl(22, Color(0.75, 0.82, 0.55))
	for l in [_title, _stats, _coins, _best]: _box.add_child(l)
	var gap := Control.new(); gap.custom_minimum_size = Vector2(0, 8); _box.add_child(gap)

	_btn = Button.new()
	_btn.text = "다시 시작"
	_btn.add_theme_font_size_override("font_size", 30)
	_btn.custom_minimum_size = Vector2(300, 62)
	_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_btn.pressed.connect(_restart)
	_box.add_child(_btn)

	_menu_btn = Button.new()
	_menu_btn.text = "메뉴"
	_menu_btn.add_theme_font_size_override("font_size", 26)
	_menu_btn.custom_minimum_size = Vector2(240, 52)
	_menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_menu_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_menu_btn.pressed.connect(func() -> void:
		Controls.reset(); get_tree().paused = false; get_tree().change_scene_to_file("res://Menu.tscn"))
	_box.add_child(_menu_btn)

	visible = false

func _lbl(size: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _fmt_time(t: float) -> String:
	var s := int(t)
	return "%d:%02d" % [s / 60, s % 60]

func _process(_dt: float) -> void:
	if Controls.game_over and not visible:
		visible = true
		_title.text = "승리!" if Controls.victory else "전멸"
		_stats.text = "처치 %d · 헤드샷 %d · 생존 %s\n도달 웨이브 %d / %s" % [
			Controls.kills, Controls.headshots, _fmt_time(Controls.run_time),
			Controls.wave, "∞" if Controls.wave_total == 0 else str(Controls.wave_total)]
		_coins.text = "획득 코인 +%d" % Missions.last_reward
		var b := "최고 기록 — 웨이브 %d · 처치 %d · %s" % [
			Controls.best_wave, Controls.best_kills, _fmt_time(Controls.best_time)]
		if Controls.new_best:
			b = "★ 신기록! ★  " + b
		_best.text = b

func _restart() -> void:
	Controls.reset()
	get_tree().paused = false
	get_tree().reload_current_scene()
