class_name CrossHair
extends Control
## Center crosshair; gap grows with Controls.spread_deg (dynamic accuracy).

func _process(_dt: float) -> void:
	queue_redraw()

func _draw() -> void:
	var vs := get_viewport().get_visible_rect().size
	var c := vs * 0.5
	if Controls.scoped:
		# scope view: black outside a circle + fine reticle
		var r := vs.y * 0.46
		var big := vs.length()
		draw_arc(c, r + big * 0.5, 0.0, TAU, 96, Color(0, 0, 0, 0.96), big, true)
		draw_arc(c, r, 0.0, TAU, 96, Color(0.1, 0.1, 0.1), 6.0, true)
		var rc := Color(0.05, 0.05, 0.05, 0.9)
		draw_line(c - Vector2(r, 0), c + Vector2(r, 0), rc, 1.5)
		draw_line(c - Vector2(0, r), c + Vector2(0, r), rc, 1.5)
		draw_circle(c, 2.0, Color(0.9, 0.2, 0.15))
		return
	if Weapons.is_melee(Controls.weapon_id):
		draw_circle(c, 3.0, Color(1.0, 0.70, 0.35, 0.9))
		return
	var gap := 6.0 + Controls.spread_deg * 5.0
	var len := 12.0
	var col := Color(1.0, 0.70, 0.35, 0.9)
	var wdt := 2.0
	draw_line(c + Vector2(-gap - len, 0), c + Vector2(-gap, 0), col, wdt)
	draw_line(c + Vector2(gap, 0), c + Vector2(gap + len, 0), col, wdt)
	draw_line(c + Vector2(0, -gap - len), c + Vector2(0, -gap), col, wdt)
	draw_line(c + Vector2(0, gap), c + Vector2(0, gap + len), col, wdt)
	draw_circle(c, 1.5, col)
