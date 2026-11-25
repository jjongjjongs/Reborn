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
const R_TINY := 58.0
const KEYS := ["fire", "jump", "reload", "crouch", "nade"]
const CANCEL_R := 64.0

var _font: Font
var _touch := {}          # finger index -> role string
var _m_idx := -1
var _m_origin := Vector2.ZERO
var _m_knob := Vector2.ZERO
var _look := {}           # finger index -> last position (look-driving fingers)
var _nade_idx := -1      # finger holding the grenade button (aims too)
var _last_state := ""

func _ready() -> void:
	_font = ThemeDB.fallback_font

func _process(_dt: float) -> void:
	# While the shop is open input is ignored; a finger released during that time
	# would leave stale state. Keep everything cleared so it's fresh on close.
	if Controls.shop_open and (_m_idx != -1 or not _touch.is_empty() or not _look.is_empty()):
		_m_idx = -1
		_touch.clear()
		_look.clear()
		Controls.move = Vector2.ZERO
		Controls.fire_held = false
		Controls.nade_aiming = false
		_nade_idx = -1
		queue_redraw()
	# redraw when state changes outside of touch events (throw consumed by the
	# player, grenade count, crouch toggled) or while the cancel zone is live
	var st := "%s|%d|%s|%s" % [Controls.nade_aiming, Controls.grenades, Controls.crouched, Controls.nade_over_cancel]
	if st != _last_state or Controls.nade_aiming:
		_last_state = st
		queue_redraw()

func _base_radius(key: String) -> float:
	match key:
		"fire": return R_FIRE
		"crouch", "nade": return R_TINY
	return R_SMALL

func _default_center(key: String, s: Vector2) -> Vector2:
	var lh := Controls.left_handed
	var fx := 150.0 if lh else s.x - 150.0        # fire / jump column
	var rx := 370.0 if lh else s.x - 370.0        # reload (toward center)
	match key:
		"fire": return Vector2(fx, s.y - 160.0)
		"jump": return Vector2(fx, s.y - 380.0)
		"reload": return Vector2(rx, s.y - 160.0)
		"crouch": return Vector2(330.0 if lh else s.x - 330.0, s.y - 330.0)
		"nade": return Vector2(560.0 if lh else s.x - 560.0, s.y - 150.0)
	return Vector2.ZERO

func _cancel_center() -> Vector2:
	var s := get_viewport().get_visible_rect().size
	return Vector2(s.x * 0.5, s.y * 0.17)

# center + radius per button, honoring custom HUD layout (fractions of screen)
func _layout() -> Dictionary:
	var s := get_viewport().get_visible_rect().size
	var out := {}
	for key in KEYS:
		var c: Vector2
		var r := _base_radius(key)
		if Controls.hud_layout.has(key):
			var d: Dictionary = Controls.hud_layout[key]
			c = Vector2(float(d.get("x", 0.5)) * s.x, float(d.get("y", 0.5)) * s.y)
			r *= float(d.get("s", 1.0))
		else:
			c = _default_center(key, s)
		out[key] = {"c": c, "r": r}
	return out

func _role_at(pos: Vector2) -> String:
	var L := _layout()
	for key in KEYS:
		if pos.distance_to(L[key]["c"]) <= float(L[key]["r"]):
			return key
	var on_left := pos.x < get_viewport().get_visible_rect().size.x * 0.5
	# move stick lives on the opposite side from the action buttons
	if on_left == (not Controls.left_handed):
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
			elif role == "crouch":
				Controls.request_crouch()
			elif role == "nade":
				if Controls.grenades > 0 and _nade_idx == -1:
					Controls.nade_aiming = true
					Controls.nade_over_cancel = false
					_nade_idx = t.index
					_look[t.index] = t.position   # grenade finger also aims
				else:
					role = "none"
			_touch[t.index] = role
			queue_redraw()
		else:
			var role: String = _touch.get(t.index, "none")
			if role == "move" and t.index == _m_idx:
				_m_idx = -1; Controls.move = Vector2.ZERO
			elif role == "fire":
				Controls.fire_held = _has_other("fire", t.index)
			elif role == "nade" and t.index == _nade_idx:
				if Controls.nade_aiming:
					if t.position.distance_to(_cancel_center()) <= CANCEL_R:
						Controls.nade_aiming = false          # released on ✕ = cancel
					else:
						Controls.request_throw()
				Controls.nade_over_cancel = false
				_nade_idx = -1
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
		if d.index == _nade_idx:
			Controls.nade_over_cancel = d.position.distance_to(_cancel_center()) <= CANCEL_R
		if _look.has(d.index):
			Controls.look += (d.position - _look[d.index]) * LOOK_SENS * Controls.look_sens
			_look[d.index] = d.position

func _active(role: String) -> bool:
	return _touch.values().has(role)

func _draw() -> void:
	var L := _layout()
	_draw_btn(L["fire"]["c"], float(L["fire"]["r"]), "사격", _active("fire"), Color(1.0, 0.36, 0.22))
	_draw_btn(L["jump"]["c"], float(L["jump"]["r"]), "점프", _active("jump"), Color(0.8, 0.85, 0.9))
	_draw_btn(L["reload"]["c"], float(L["reload"]["r"]), "장전", _active("reload"), Color(0.8, 0.85, 0.9))
	var cr_c := Color(0.56, 0.76, 1.0)
	_draw_btn(L["crouch"]["c"], float(L["crouch"]["r"]), "서기" if Controls.crouched else "앉기",
		Controls.crouched or _active("crouch"), cr_c, 28)
	var has := Controls.grenades > 0
	var nc := Color(1.0, 0.55, 0.2) if has else Color(0.5, 0.52, 0.55)
	_draw_btn(L["nade"]["c"], float(L["nade"]["r"]), "수류탄", Controls.nade_aiming, nc, 24)
	var bc: Vector2 = L["nade"]["c"] + Vector2(float(L["nade"]["r"]) * 0.72, float(L["nade"]["r"]) * 0.72)
	draw_circle(bc, 19.0, Color(0.05, 0.06, 0.08, 0.95))
	draw_arc(bc, 19.0, 0.0, TAU, 24, nc, 2.0, true)
	var cnt := "×%d" % Controls.grenades
	var csz := _font.get_string_size(cnt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
	draw_string(_font, bc - Vector2(csz.x * 0.5, -7.0), cnt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, nc)
	if Controls.nade_aiming:
		var cc := _cancel_center()
		var over := Controls.nade_over_cancel
		draw_circle(cc, CANCEL_R, Color(0.89, 0.29, 0.23, 0.45 if over else 0.18))
		draw_arc(cc, CANCEL_R, 0.0, TAU, 40, Color(0.95, 0.4, 0.35, 0.9), 3.0, true)
		var ct := "✕ 취소"
		var tsz := _font.get_string_size(ct, HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
		draw_string(_font, cc - Vector2(tsz.x * 0.5, -9.0), ct, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 1, 1, 0.95))
	if _m_idx != -1:
		draw_circle(_m_origin, MOVE_RADIUS, Color(1, 1, 1, 0.06))
		draw_arc(_m_origin, MOVE_RADIUS, 0.0, TAU, 48, Color(1.0, 0.61, 0.24, 0.5), 3.0, true)
		draw_circle(_m_knob, KNOB, Color(1.0, 0.61, 0.24, 0.65))

func _draw_btn(center: Vector2, radius: float, label: String, pressed: bool, tint: Color, fsize := 34) -> void:
	var fill := Color(tint.r, tint.g, tint.b, 0.35 if pressed else 0.16)
	draw_circle(center, radius, fill)
	draw_arc(center, radius, 0.0, TAU, 40, Color(tint.r, tint.g, tint.b, 0.8), 3.0, true)
	var sz := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	draw_string(_font, center - Vector2(sz.x * 0.5, -fsize * 0.35), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(1, 1, 1, 0.95))
