class_name TouchInput
extends Control
## Unified touch: left half = move joystick, right half = look/aim drag.
## Uses _unhandled_input so on-screen Buttons (fire/jump/reload) consume their
## own touches first and never fight movement or aiming. Multi-touch by index.

const RADIUS := 150.0
const KNOB := 50.0
const LOOK_SENS := 0.25   # degrees per pixel

# move finger
var _m_active := false
var _m_idx := -1
var _m_origin := Vector2.ZERO
var _m_knob := Vector2.ZERO
# look finger
var _l_idx := -1
var _l_last := Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	var w := get_viewport().get_visible_rect().size.x
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			if t.position.x < w * 0.5 and not _m_active:
				_m_active = true; _m_idx = t.index
				_m_origin = t.position; _m_knob = t.position
				queue_redraw()
			elif t.position.x >= w * 0.5 and _l_idx == -1:
				_l_idx = t.index; _l_last = t.position
		else:
			if t.index == _m_idx:
				_m_active = false; _m_idx = -1
				Controls.move = Vector2.ZERO
				queue_redraw()
			elif t.index == _l_idx:
				_l_idx = -1
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _m_idx and _m_active:
			var off: Vector2 = d.position - _m_origin
			if off.length() > RADIUS:
				off = off.normalized() * RADIUS
			_m_knob = _m_origin + off
			Controls.move = off / RADIUS
			queue_redraw()
		elif d.index == _l_idx:
			Controls.look += (d.position - _l_last) * LOOK_SENS
			_l_last = d.position

func _draw() -> void:
	if not _m_active:
		return
	draw_circle(_m_origin, RADIUS, Color(1, 1, 1, 0.06))
	draw_arc(_m_origin, RADIUS, 0.0, TAU, 48, Color(1.0, 0.61, 0.24, 0.5), 3.0, true)
	draw_circle(_m_knob, KNOB, Color(1.0, 0.61, 0.24, 0.65))
