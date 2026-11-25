extends Control
## Title / mode select. Launches a mode scene with a clean run state.

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.08, 0.10)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "스페셜솔져 리본"
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(1.0, 0.62, 0.24))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left = 0.5; title.anchor_right = 0.5; title.anchor_top = 0.28
	title.offset_left = -400; title.offset_right = 400; title.offset_top = 0
	add_child(title)

	var sub := Label.new()
	sub.text = "오프라인 · 모드 선택"
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", Color(0.65, 0.72, 0.78))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.anchor_left = 0.5; sub.anchor_right = 0.5; sub.anchor_top = 0.28
	sub.offset_left = -400; sub.offset_right = 400; sub.offset_top = 72
	add_child(sub)

	_mode_button("PvE 웨이브 서바이벌", 0.5, "res://Main.tscn")
	_mode_button("데스매치 (봇)", 0.62, "res://Deathmatch.tscn")

func _mode_button(txt: String, anchor_y: float, scene: String) -> void:
	var b := Button.new()
	b.text = txt
	b.add_theme_font_size_override("font_size", 34)
	b.custom_minimum_size = Vector2(0, 86)
	b.anchor_left = 0.5; b.anchor_right = 0.5; b.anchor_top = anchor_y; b.anchor_bottom = anchor_y
	b.offset_left = -300; b.offset_right = 300; b.offset_top = 0; b.offset_bottom = 86
	b.pressed.connect(func() -> void:
		Controls.reset()
		get_tree().change_scene_to_file(scene))
	add_child(b)
