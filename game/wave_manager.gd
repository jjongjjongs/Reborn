class_name WaveManager
extends Node
## M3 wave flow: prep countdown -> spawn a scheduled batch -> wait for clear ->
## prep next (escalating) -> ... -> cleared. Kills/clears feed Controls.points.

const PREP := 6.0
const CLEAR_BONUS := 50
const WAVES := [
	{"count": 6, "interval": 0.9, "hp_mul": 1.0, "spd_mul": 1.0},
	{"count": 9, "interval": 0.8, "hp_mul": 1.0, "spd_mul": 1.05},
	{"count": 13, "interval": 0.7, "hp_mul": 1.1, "spd_mul": 1.1},
	{"count": 16, "interval": 0.6, "hp_mul": 1.2, "spd_mul": 1.15},
	{"count": 22, "interval": 0.5, "hp_mul": 1.35, "spd_mul": 1.2},
]

var arena: Node3D
var player: Node3D
var spawn_points: Array[Vector3] = [
	Vector3(17, 0.1, 0), Vector3(-17, 0.1, 0),
	Vector3(0, 0.1, -19), Vector3(0, 0.1, 19),
	Vector3(15, 0.1, -15), Vector3(-15, 0.1, 15),
]

var _state := "prep"
var _wave := -1
var _to_spawn := 0
var _spawn_cd := 0.0
var _alive := 0
var _prep := PREP

func _ready() -> void:
	Controls.wave_total = WAVES.size()
	_start_prep()

func _start_prep() -> void:
	_state = "prep"
	_prep = PREP
	Controls.prep_left = PREP

func _start_wave() -> void:
	_wave += 1
	if _wave >= WAVES.size():
		_state = "done"
		Controls.cleared = true
		Controls.prep_left = -1.0
		return
	Controls.wave = _wave + 1
	Controls.prep_left = -1.0
	var cur: Dictionary = WAVES[_wave]
	_to_spawn = int(cur["count"])
	_spawn_cd = 0.3
	_state = "spawning"

func _process(dt: float) -> void:
	match _state:
		"prep":
			_prep -= dt
			Controls.prep_left = maxf(0.0, _prep)
			if _prep <= 0.0:
				_start_wave()
		"spawning":
			_spawn_cd -= dt
			if _spawn_cd <= 0.0 and _to_spawn > 0:
				_spawn_one()
				_to_spawn -= 1
				_spawn_cd = float(WAVES[_wave]["interval"])
				if _to_spawn == 0:
					_state = "fighting"
			Controls.zombies_left = _alive + _to_spawn
		"fighting":
			Controls.zombies_left = _alive + _to_spawn
			if _alive <= 0:
				Controls.points += CLEAR_BONUS
				_start_prep()

func _spawn_one() -> void:
	var cur: Dictionary = WAVES[_wave]
	var z := Zombie.new()
	z.hp_scale = float(cur["hp_mul"])
	z.spd_scale = float(cur["spd_mul"])
	z.player = player
	z.position = spawn_points[randi() % spawn_points.size()]
	z.died.connect(_on_zombie_died)
	arena.add_child(z)
	_alive += 1

func _on_zombie_died() -> void:
	_alive -= 1
