class_name WaveManager
extends Node
## M3 wave flow: prep countdown -> spawn a scheduled batch -> wait for clear ->
## prep next (escalating) -> ... -> cleared. Kills/clears feed Controls.points.

const PREP := 9.0
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
var zones: ZoneGates           # survival maps that open up area by area

const MAX_ALIVE := 26          # long waves trickle in: never more than this many at once (phones)

## wave n (0-based): the hand-made five, then more / tougher / faster each wave
static func wave_def(n: int) -> Dictionary:
	if n < WAVES.size(): return WAVES[n]
	var k := n - WAVES.size() + 1
	return {"count": mini(22 + 3 * k, 60), "interval": maxf(0.25, 0.5 - 0.02 * k),
		"hp_mul": 1.35 + 0.08 * k, "spd_mul": minf(1.45, 1.2 + 0.025 * k)}

func _ready() -> void:
	Controls.wave_total = Controls.wave_mode          # 0 = endless
	_start_prep()

func _start_prep() -> void:
	_state = "prep"
	_prep = PREP
	Controls.prep_left = PREP
	if zones:
		zones.open_for_wave(_wave + 2)       # the area for the coming wave opens now
		spawn_points = zones.spawns()

func _start_wave() -> void:
	_wave += 1
	if Controls.wave_mode > 0 and _wave >= Controls.wave_mode:
		_state = "done"
		Controls.cleared = true
		Controls.prep_left = -1.0
		Controls.end_run(true)
		return
	Controls.wave = _wave + 1
	Controls.prep_left = -1.0
	var cur: Dictionary = wave_def(_wave)
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
			if _spawn_cd <= 0.0 and _to_spawn > 0 and _alive < MAX_ALIVE:
				_spawn_one()
				_to_spawn -= 1
				_spawn_cd = float(wave_def(_wave)["interval"])
				if _to_spawn == 0:
					_state = "fighting"
			Controls.zombies_left = _alive + _to_spawn
		"fighting":
			Controls.zombies_left = _alive + _to_spawn
			if _alive <= 0:
				Controls.points += CLEAR_BONUS
				_start_prep()

func _spawn_one() -> void:
	var cur: Dictionary = wave_def(_wave)
	var z := Zombie.new()
	z.hp_scale = float(cur["hp_mul"])
	z.spd_scale = float(cur["spd_mul"])
	z.player = player
	z.respawn_pts = spawn_points
	# a free spot near a spawn point (zombies spawned inside each other get shoved through the floor)
	var base: Vector3 = spawn_points[randi() % spawn_points.size()]
	var pos := base
	for tries in 10:
		pos = base + Vector3(randf_range(-1.6, 1.6), 0.0, randf_range(-1.6, 1.6))
		var free := true
		for o in arena.get_tree().get_nodes_in_group("zombie"):
			if Vector2((o as Node3D).global_position.x - pos.x, (o as Node3D).global_position.z - pos.z).length() < 1.0:
				free = false; break
		if free: break
	z.position = pos
	z.died.connect(_on_zombie_died)
	arena.add_child(z)
	_alive += 1

func _on_zombie_died() -> void:
	_alive -= 1
