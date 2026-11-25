extends Control
## Dynamic left-side virtual joystick. Appears where you touch in the left
## half of the screen; writes a -1..1 vector to Controls.move.
## Uses global _input (not _gui_input) and never marks events handled, so the
## jump Button on the right still receives its touches.

const RADIUS := 150.0
const KNOB := 50.0

var _origin := Vector2.ZERO
var _knob := Vector2.ZERO
var _active := false
var _idx := -1

func _input(event: InputEvent) -> void:
	var vw := get_viewport().get_visible_rect().size
	if event is InputEventScreenTouch:
		if event.pressed:
			if not _active and event.position.x < vw.x * 0.5:
				_active = true
				_idx = event.index
				_origin = event.position
				_knob = event.position
				queue_redraw()
		elif event.index == _idx:
			_active = false
			_idx = -1
			Controls.move = Vector2.ZERO
			queue_redraw()
	elif event is InputEventScreenDrag and _active and event.index == _idx:
		var off := event.position - _origin
		if off.length() > RADIUS:
			off = off.normalized() * RADIUS
		_knob = _origin + off
		Controls.move = off / RADIUS
		queue_redraw()

func _draw() -> void:
	if not _active:
		return
	draw_circle(_origin, RADIUS, Color(1, 1, 1, 0.06))
	draw_arc(_origin, RADIUS, 0.0, TAU, 48, Color(1.0, 0.61, 0.24, 0.5), 3.0, true)
	draw_circle(_knob, KNOB, Color(1.0, 0.61, 0.24, 0.65))
