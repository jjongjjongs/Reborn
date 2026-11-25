extends Node
## Autoload: input bus + run state + local best-record save.

const SAVE_PATH := "user://reborn_save.json"

# --- input ---
var move: Vector2 = Vector2.ZERO
var look: Vector2 = Vector2.ZERO
var fire_held: bool = false
var _jump: bool = false
var _reload: bool = false
var spread_deg: float = 1.0

# --- weapon / player ---
var ammo: int = 30
var ammo_max: int = 30
var reloading: bool = false
var hp: int = 100
var hp_max: int = 100

# --- run stats ---
var hits: int = 0
var kills: int = 0
var headshots: int = 0
var points: int = 0
var run_time: float = 0.0

# --- wave ---
var wave: int = 0
var wave_total: int = 5
var zombies_left: int = 0
var prep_left: float = -1.0
var cleared: bool = false

# --- upgrades ---
var dmg_mult: float = 1.0
var speed_mult: float = 1.0
var reload_mult: float = 1.0
var atk_lv: int = 0
var spd_lv: int = 0
var hp_lv: int = 0
var wp_lv: int = 0
var shop_open: bool = false

# --- run end + best ---
var game_over: bool = false
var victory: bool = false
var new_best: bool = false
var best_wave: int = 0
var best_kills: int = 0
var best_time: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_best()

func _process(dt: float) -> void:
	if not game_over:
		run_time += dt

func request_jump() -> void: _jump = true
func consume_jump() -> bool:
	if _jump: _jump = false; return true
	return false

func request_reload() -> void: _reload = true
func consume_reload() -> bool:
	if _reload: _reload = false; return true
	return false

func consume_look() -> Vector2:
	var l := look
	look = Vector2.ZERO
	return l

func end_run(win: bool) -> void:
	if game_over:
		return
	game_over = true
	victory = win
	new_best = false
	if wave > best_wave:
		best_wave = wave; new_best = true
	if kills > best_kills:
		best_kills = kills; new_best = true
	if run_time > best_time:   # longest survival (win or lose)
		best_time = run_time; new_best = true
	_save_best()
	get_tree().paused = true

func reset() -> void:
	move = Vector2.ZERO; look = Vector2.ZERO; fire_held = false
	_jump = false; _reload = false; spread_deg = 1.0
	ammo = 30; ammo_max = 30; reloading = false
	hp = 100; hp_max = 100
	hits = 0; kills = 0; headshots = 0; points = 0; run_time = 0.0
	wave = 0; zombies_left = 0; prep_left = -1.0; cleared = false
	dmg_mult = 1.0; speed_mult = 1.0; reload_mult = 1.0
	atk_lv = 0; spd_lv = 0; hp_lv = 0; wp_lv = 0; shop_open = false
	game_over = false; victory = false; new_best = false

func _load_best() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) == TYPE_DICTIONARY:
		best_wave = int(data.get("best_wave", 0))
		best_kills = int(data.get("best_kills", 0))
		best_time = float(data.get("best_time", 0.0))

func _save_best() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"best_wave": best_wave, "best_kills": best_kills, "best_time": best_time,
	}))
	f.close()
