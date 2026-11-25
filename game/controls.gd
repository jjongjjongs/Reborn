extends Node
## Autoload singleton. The HUD writes here; the player reads here.
## Keeps input wiring decoupled from scene structure.

var move: Vector2 = Vector2.ZERO   # x: right, y: up = negative (screen-space)
var _jump: bool = false

func request_jump() -> void:
	_jump = true

func consume_jump() -> bool:
	if _jump:
		_jump = false
		return true
	return false
