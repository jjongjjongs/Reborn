class_name ResultScreen
extends Control
## M5 run-end overlay: victory/defeat, stats, local best, restart. Processes
## while the tree is paused (set at game over) so its button still works.

const PANEL_W := 680.0
const PANEL_H := 520.0

var _panel: ColorRect
var _title: Label
var _stats: Label
var _best: Label
var _btn: Button
var _menu_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_panel = ColorRect.new()
	_panel.color = Color(0.05, 0.07, 0.09, 0.96)
	add_child(_panel)

	_title = _lbl(44, Color(1.0, 0.72, 0.38))
	_stats = _lbl(30, Color(0.92, 0.94, 0.92))
	_best = _lbl(26, Color(0.75, 0.82, 0.55))
	add_child(_title); add_child(_stats); add_child(_best)

	_btn = Button.new()
	_btn.text = "다시 시작"
	_btn.add_theme_font_size_override("font_size", 32)
	_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_btn.pressed.connect(_restart)
	add_child(_btn)

	_menu_btn = Button.new()
	_menu_btn.text = "메뉴"
	_menu_btn.add_theme_font_size_override("font_size", 26)
	_menu_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_menu_btn.pressed.connect(func() -> void:
		Controls.reset(); get_tree().paused = false; get_tree().change_scene_to_file("res://Menu.tscn"))
	add_child(_menu_btn)

	visible = false
	_relayout()
	get_viewport().size_changed.connect(_relayout)

func _lbl(size: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _relayout() -> void:
	var vp := get_viewport().get_visible_rect().size
	var x := (vp.x - PANEL_W) * 0.5
	var y := (vp.y - PANEL_H) * 0.5
	# full-screen cover so the frozen HUD/game doesn't show through
	_panel.position = Vector2.ZERO; _panel.size = vp
	_title.position = Vector2(x, y + 36); _title.size = Vector2(PANEL_W, 60)
	_stats.position = Vector2(x, y + 140); _stats.size = Vector2(PANEL_W, 200)
	_best.position = Vector2(x, y + 350); _best.size = Vector2(PANEL_W, 80)
	_btn.position = Vector2(x + PANEL_W * 0.5 - 150, y + PANEL_H - 150)
	_btn.size = Vector2(300, 66)
	_menu_btn.position = Vector2(x + PANEL_W * 0.5 - 120, y + PANEL_H - 72)
	_menu_btn.size = Vector2(240, 54)

func _fmt_time(t: float) -> String:
	var s := int(t)
	return "%d:%02d" % [s / 60, s % 60]

func _process(_dt: float) -> void:
	if Controls.game_over and not visible:
		visible = true
		_title.text = "승리!" if Controls.victory else "전멸"
		_stats.text = "처치 %d · 헤드샷 %d\n생존 %s\n도달 웨이브 %d / %d\n포인트 %d" % [
			Controls.kills, Controls.headshots, _fmt_time(Controls.run_time),
			Controls.wave, Controls.wave_total, Controls.points]
		var b := "최고 기록 — 웨이브 %d · 처치 %d · %s" % [
			Controls.best_wave, Controls.best_kills, _fmt_time(Controls.best_time)]
		if Controls.new_best:
			b = "★ 신기록! ★\n" + b
		_best.text = b

func _restart() -> void:
	Controls.reset()
	get_tree().paused = false
	get_tree().reload_current_scene()
