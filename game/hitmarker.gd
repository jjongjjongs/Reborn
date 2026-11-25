class_name HitMarker
extends Control
## Classic 4-tick FPS hitmarker drawn at screen center. pop() on a landed hit.

var t := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func pop() -> void:
	t = 1.0
	visible = true
	queue_redraw()

func _process(dt: float) -> void:
	if t > 0.0:
		t = maxf(0.0, t - dt * 3.2)
		queue_redraw()
		if t <= 0.0:
			visible = false

func _draw() -> void:
	var c := size * 0.5
	var col := Color(1, 1, 1, t)
	var g := 7.0
	var l := 13.0
	var w := 3.0
	draw_line(c + Vector2(g, g), c + Vector2(g + l, g + l), col, w)
	draw_line(c + Vector2(-g, g), c + Vector2(-g - l, g + l), col, w)
	draw_line(c + Vector2(g, -g), c + Vector2(g + l, -g - l), col, w)
	draw_line(c + Vector2(-g, -g), c + Vector2(-g - l, -g - l), col, w)
