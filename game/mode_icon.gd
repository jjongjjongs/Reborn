class_name ModeIcon
extends Control
## Small vector icon drawn for menu mode buttons (fills the empty tile).
## kind: "survival" (shield), "dm" (reticle), "team" (two figures).

var kind := "survival"
var col := Color(1.0, 0.72, 0.38)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _p(x: float, y: float) -> Vector2:
	# map a 24x24 design box to the control, centered, 82% scale
	var d: float = minf(size.x, size.y) * 0.82
	var ox := (size.x - d) * 0.5
	var oy := (size.y - d) * 0.5
	return Vector2(ox + x / 24.0 * d, oy + y / 24.0 * d)

func _w() -> float:
	return maxf(2.0, minf(size.x, size.y) * 0.07)

func _draw() -> void:
	match kind:
		"survival": _shield()
		"dm": _reticle()
		"team": _team()

func _shield() -> void:
	var pts := PackedVector2Array([
		_p(12, 2), _p(20, 5), _p(20, 12), _p(12, 21), _p(4, 12), _p(4, 5), _p(12, 2)])
	draw_polyline(pts, col, _w(), true)
	draw_circle(_p(12, 9), _w() * 1.1, col)
	draw_polyline(PackedVector2Array([_p(8.5, 16), _p(12, 11.5), _p(15.5, 16)]), col, _w(), true)

func _reticle() -> void:
	draw_arc(_p(12, 12), minf(size.x, size.y) * 0.28, 0.0, TAU, 40, col, _w(), true)
	for a in [Vector2(12, 2), Vector2(12, 22), Vector2(2, 12), Vector2(22, 12)]:
		var dir := (_p(a.x, a.y) - _p(12, 12)).normalized()
		draw_line(_p(12, 12) + dir * minf(size.x, size.y) * 0.18,
			_p(12, 12) + dir * minf(size.x, size.y) * 0.34, col, _w(), true)
	draw_circle(_p(12, 12), _w() * 0.9, Color(1.0, 0.48, 0.1))

func _team() -> void:
	for cx in [8.0, 16.0]:
		draw_arc(_p(cx, 8), minf(size.x, size.y) * 0.11, 0.0, TAU, 24, col, _w(), true)
		draw_polyline(PackedVector2Array([
			_p(cx - 4, 20), _p(cx - 4, 16), _p(cx, 13), _p(cx + 4, 16), _p(cx + 4, 20)]), col, _w(), true)
