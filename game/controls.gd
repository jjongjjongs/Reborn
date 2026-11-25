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
var kills: int = 0
var hp: int = 100
var hp_max: int = 100
# wave + economy
var points: int = 0
var wave: int = 0
var wave_total: int = 5
var zombies_left: int = 0
var prep_left: float = -1.0   # >=0 while in prep countdown
var cleared: bool = false
# upgrades (applied multipliers + levels)
var dmg_mult: float = 1.0
var speed_mult: float = 1.0
var reload_mult: float = 1.0
var atk_lv: int = 0
var spd_lv: int = 0
var hp_lv: int = 0
var wp_lv: int = 0
var shop_open: bool = false

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
