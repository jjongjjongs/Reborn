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
		"atk": _atk()
		"spd": _spd()
		"hp": _heart()
		"wp": _ammo()
		"heal": _plus()
		"nade": _nade()
		"bomb": _bomb()
		"training": _target()

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

func _atk() -> void:   # sword: blade, guard, grip
	draw_line(_p(8, 16), _p(20, 4), col, _w() * 1.2, true)
	draw_line(_p(5, 12), _p(12, 19), col, _w(), true)
	draw_line(_p(8, 16), _p(3, 21), col, _w() * 1.2, true)

func _spd() -> void:   # lightning bolt
	draw_polyline(PackedVector2Array([_p(14, 2), _p(5, 13), _p(12, 13), _p(10, 22), _p(19, 10), _p(12, 10), _p(14, 2)]), col, _w(), true)

func _heart() -> void:
	var pts := PackedVector2Array()
	for i in 41:
		var t := TAU * float(i) / 40.0
		var x := 16.0 * pow(sin(t), 3)
		var y := 13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t)
		pts.append(_p(12 + x * 0.55, 11 - y * 0.55))
	draw_polyline(pts, col, _w(), true)

func _ammo() -> void:  # bullet
	draw_polyline(PackedVector2Array([_p(9, 21), _p(9, 9), _p(12, 3), _p(15, 9), _p(15, 21), _p(9, 21)]), col, _w(), true)
	draw_line(_p(9, 17), _p(15, 17), col, _w(), true)

func _plus() -> void:
	draw_line(_p(12, 4), _p(12, 20), col, _w() * 1.3, true)
	draw_line(_p(4, 12), _p(20, 12), col, _w() * 1.3, true)

func _nade() -> void:  # grenade: round body, cap, lever, pin ring
	draw_arc(_p(11, 15), minf(size.x, size.y) * 0.27, 0.0, TAU, 32, col, _w(), true)
	draw_line(_p(9, 7), _p(14, 7), col, _w() * 1.2, true)
	draw_polyline(PackedVector2Array([_p(14, 7), _p(19, 9), _p(19, 14)]), col, _w(), true)
	draw_arc(_p(7, 5), minf(size.x, size.y) * 0.08, 0.0, TAU, 16, col, _w() * 0.8, true)

func _bomb() -> void:  # charge pack: box, timer face, wire
	var pts := PackedVector2Array([_p(4, 9), _p(20, 9), _p(20, 20), _p(4, 20), _p(4, 9)])
	draw_polyline(pts, col, _w(), true)
	draw_arc(_p(12, 14.5), minf(size.x, size.y) * 0.13, 0.0, TAU, 24, col, _w() * 0.9, true)
	draw_line(_p(12, 14.5), _p(12, 12.3), Color(1.0, 0.48, 0.1), _w() * 0.9, true)
	draw_polyline(PackedVector2Array([_p(16, 9), _p(17, 5), _p(21, 3)]), col, _w() * 0.9, true)

func _target() -> void:   # range target: rings + post
	var c := _p(12, 10)
	var r := minf(size.x, size.y) * 0.28
	draw_arc(c, r, 0.0, TAU, 32, col, _w(), true)
	draw_arc(c, r * 0.55, 0.0, TAU, 24, col, _w(), true)
	draw_circle(c, _w() * 1.1, Color(1.0, 0.48, 0.1))
	draw_line(_p(12, 10) + Vector2(0, r), _p(12, 22), col, _w(), true)
