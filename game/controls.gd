extends Node
## Autoload input bus. HUD/touch write here; player/camera/HUD read here.

var move: Vector2 = Vector2.ZERO    # left stick, x=right, y=up(negative)
var look: Vector2 = Vector2.ZERO    # right-drag aim delta, consumed per frame
var fire_held: bool = false         # fire button down
var _jump: bool = false
var _reload: bool = false

# shared readouts for HUD
var spread_deg: float = 1.0
var ammo: int = 30
var ammo_max: int = 30
var reloading: bool = false
var hits: int = 0

func request_jump() -> void:
	_jump = true

func consume_jump() -> bool:
	if _jump:
		_jump = false
		return true
	return false

func request_reload() -> void:
	_reload = true

func consume_reload() -> bool:
	if _reload:
		_reload = false
		return true
	return false

func consume_look() -> Vector2:
	var l := look
	look = Vector2.ZERO
	return l
