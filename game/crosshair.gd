class_name CrossHair
extends Control
## Center crosshair; gap grows with Controls.spread_deg (dynamic accuracy).

func _process(_dt: float) -> void:
	queue_redraw()

func _draw() -> void:
	var c := get_viewport().get_visible_rect().size * 0.5
	var gap := 6.0 + Controls.spread_deg * 5.0
	var len := 12.0
	var col := Color(1.0, 0.70, 0.35, 0.9)
	var wdt := 2.0
	draw_line(c + Vector2(-gap - len, 0), c + Vector2(-gap, 0), col, wdt)
	draw_line(c + Vector2(gap, 0), c + Vector2(gap + len, 0), col, wdt)
	draw_line(c + Vector2(0, -gap - len), c + Vector2(0, -gap), col, wdt)
	draw_line(c + Vector2(0, gap), c + Vector2(0, gap + len), col, wdt)
	draw_circle(c, 1.5, col)
