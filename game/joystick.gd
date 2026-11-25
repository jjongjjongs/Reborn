class_name TouchInput
extends Control
## Manual multi-touch (no GUI buttons so every finger is independent):
##   left half            -> move stick
##   right open area      -> look / aim
##   fire zone (hold)     -> fires AND, while held, dragging that finger aims
##                           (standard mobile-FPS "hold fire + slide to aim")
##   jump / reload zones  -> one-shot actions
## Any finger on the look area OR the fire button drives aiming (tracked in _look).

const MOVE_RADIUS := 150.0
const KNOB := 50.0
const LOOK_SENS := 0.25
const R_FIRE := 100.0
const R_SMALL := 66.0

var _font: Font
var _touch := {}          # finger index -> role string
var _m_idx := -1
var _m_origin := Vector2.ZERO
var _m_knob := Vector2.ZERO
var _look := {}           # finger index -> last position (look-driving fingers)

func _ready() -> void:
	_font = ThemeDB.fallback_font

func _centers() -> Dictionary:
	var s := get_viewport().get_visible_rect().size
	return {
		"fire": Vector2(s.x - 150.0, s.y - 160.0),
		"jump": Vector2(s.x - 150.0, s.y - 380.0),
		"reload": Vector2(s.x - 370.0, s.y - 160.0),
	}

func _role_at(pos: Vector2) -> String:
	var c := _centers()
	if pos.distance_to(c["fire"]) <= R_FIRE:
		return "fire"
	if pos.distance_to(c["jump"]) <= R_SMALL:
		return "jump"
	if pos.distance_to(c["reload"]) <= R_SMALL:
		return "reload"
	if pos.x < get_viewport().get_visible_rect().size.x * 0.5:
		return "move"
	return "look"

func _has_other(role: String, except_idx: int) -> bool:
	for k in _touch.keys():
		if k != except_idx and _touch[k] == role:
			return true
	return false

func _input(event: InputEvent) -> void:
	if Controls.shop_open:
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			var role := _role_at(t.position)
			if role == "move":
				if _m_idx != -1:
					role = "none"
				else:
					_m_idx = t.index; _m_origin = t.position; _m_knob = t.position
			elif role == "look":
				_look[t.index] = t.position
			elif role == "fire":
				Controls.fire_held = true
				_look[t.index] = t.position   # fire finger also aims
			elif role == "jump":
				Controls.request_jump()
			elif role == "reload":
				Controls.request_reload()
			_touch[t.index] = role
			queue_redraw()
		else:
			var role: String = _touch.get(t.index, "none")
			if role == "move" and t.index == _m_idx:
				_m_idx = -1; Controls.move = Vector2.ZERO
			elif role == "fire":
				Controls.fire_held = _has_other("fire", t.index)
			_look.erase(t.index)
			_touch.erase(t.index)
			queue_redraw()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _m_idx:
			var off: Vector2 = d.position - _m_origin
			if off.length() > MOVE_RADIUS:
				off = off.normalized() * MOVE_RADIUS
			_m_knob = _m_origin + off
			Controls.move = off / MOVE_RADIUS
			queue_redraw()
		if _look.has(d.index):
			Controls.look += (d.position - _look[d.index]) * LOOK_SENS
			_look[d.index] = d.position

func _active(role: String) -> bool:
	return _touch.values().has(role)

func _draw() -> void:
	var c := _centers()
	_draw_btn(c["fire"], R_FIRE, "사격", _active("fire"), Color(1.0, 0.36, 0.22))
	_draw_btn(c["jump"], R_SMALL, "점프", _active("jump"), Color(0.8, 0.85, 0.9))
	_draw_btn(c["reload"], R_SMALL, "장전", _active("reload"), Color(0.8, 0.85, 0.9))
	if _m_idx != -1:
		draw_circle(_m_origin, MOVE_RADIUS, Color(1, 1, 1, 0.06))
		draw_arc(_m_origin, MOVE_RADIUS, 0.0, TAU, 48, Color(1.0, 0.61, 0.24, 0.5), 3.0, true)
		draw_circle(_m_knob, KNOB, Color(1.0, 0.61, 0.24, 0.65))

func _draw_btn(center: Vector2, radius: float, label: String, pressed: bool, tint: Color) -> void:
	var fill := Color(tint.r, tint.g, tint.b, 0.35 if pressed else 0.16)
	draw_circle(center, radius, fill)
	draw_arc(center, radius, 0.0, TAU, 40, Color(tint.r, tint.g, tint.b, 0.8), 3.0, true)
	var fsize := 34
	var sz := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	draw_string(_font, center - Vector2(sz.x * 0.5, -fsize * 0.35), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(1, 1, 1, 0.95))
