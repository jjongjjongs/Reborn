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
var _crouch: bool = false
var crouched: bool = false        # mirrors the player's stance (HUD label)
# grenade: hold button = aiming, release = throw (or cancel over the ✕ zone)
const NADE_MAX := 2
var grenades: int = NADE_MAX
var nade_aiming: bool = false
var nade_over_cancel: bool = false
var _nade_throw: bool = false
var shake: float = 0.0
# bomb defusal: context action button (설치 / 해체), hold to progress
var act_label: String = ""
var act_held: bool = false
var map_open := false            # full map overlay (tap the radar)
var radar_rect := Rect2()        # radar circle on screen, for the tap test
var act_progress: float = 0.0            # camera shake amount (decays)

# --- weapon / player ---
# loadout (persisted, chosen in the menu 장비 tab): primary / secondary / melee
var loadout: Array = ["m4", "pistol", "knife"]
var bot_diff: String = "reg"      # 출격 준비: bot difficulty (persisted)
var sel_map: String = "downtown"     # 출격 준비: map (persisted)
var slot: int = 0                 # active slot (HUD chip)
var weapon_id: String = "m4"      # active weapon (mirrors the player)
var slot_ammo: Array = [30, 12, 0]   # HUD chip numbers per slot
var slot_mag: Array = [30, 12, 0]
var swapping: bool = false
var _swap_to: int = -1
var scoped: bool = false          # sniper scope on
var _scope: bool = false
var mag_bonus: int = 0            # shop "weapon" upgrade
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

# --- settings (persisted) ---
var sfx_on: bool = true
var vibrate_on: bool = true
var sniper_hold: bool = true    # sniper: press fire = scope in, release = shoot (then scope out)
var look_sens: float = 1.0      # 0.4 .. 2.0 multiplier
var view_fp := false            # 1인칭 (true) / 3인칭 (false), chosen on the sortie screen
var scope_sens: float = 0.5     # 0.2 .. 1.5 extra multiplier while looking through a scope
var left_handed: bool = false
var hud_layout: Dictionary = {}
# default button layout (fractions of the screen + size scale), taken from the
# arrangement the player settled on (다운타운 screenshots)
const DEFAULT_LAYOUT := {
	"fire":   {"x": 0.8925, "y": 0.780, "s": 1.00},
	"jump":   {"x": 0.9385, "y": 0.553, "s": 0.78},
	"crouch": {"x": 0.8590, "y": 0.555, "s": 0.88},
	"reload": {"x": 0.7740, "y": 0.883, "s": 0.83},
	"nade":   {"x": 0.6825, "y": 0.894, "s": 0.81},
	"scope":  {"x": 0.8590, "y": 0.330, "s": 0.90},
}   # "fire"/"jump"/"reload" -> {x,y (frac), s (scale)}

func reset_hud() -> void:
	hud_layout.clear()
	save_settings()

func vibrate(ms: int = 40) -> void:
	if vibrate_on:
		Input.vibrate_handheld(ms)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_best()

func _process(dt: float) -> void:
	if not game_over:
		run_time += dt
	shake = maxf(0.0, shake - dt * 2.5)

func request_jump() -> void: _jump = true
func consume_jump() -> bool:
	if _jump: _jump = false; return true
	return false

func request_crouch() -> void: _crouch = true
func consume_crouch() -> bool:
	if _crouch: _crouch = false; return true
	return false

func request_throw() -> void: _nade_throw = true
func consume_throw() -> bool:
	if _nade_throw: _nade_throw = false; return true
	return false

func add_shake(a: float) -> void:
	shake = minf(1.0, shake + a)

func shake_offset() -> Vector3:
	if shake <= 0.001: return Vector3.ZERO
	return Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * shake * 0.25

func request_swap(i: int) -> void: _swap_to = i
func consume_swap() -> int:
	var i := _swap_to
	_swap_to = -1
	return i

func request_scope() -> void: _scope = true
func consume_scope() -> bool:
	if _scope: _scope = false; return true
	return false

func set_loadout(i: int, id: String) -> void:
	loadout[i] = id
	save_settings()

func request_reload() -> void: _reload = true
func consume_reload() -> bool:
	if _reload: _reload = false; return true
	return false

func consume_look() -> Vector2:
	var l := look
	look = Vector2.ZERO
	return l

## match over: hide the on-screen controls, crosshair / scope and radar behind the result panel
func hide_play_hud() -> void:
	for n in get_tree().root.find_children("*", "", true, false):
		if n is TouchInput or n is CrossHair or n is Radar: (n as CanvasItem).visible = false

func end_run(win: bool) -> void:
	if game_over:
		return
	game_over = true
	victory = win
	new_best = false
	Missions.add("match"); Missions.add("wave", wave)
	if win: Missions.add("win")
	Missions.record("웨이브 서바이벌", SortieScreen.map_name(sel_map), "%s · 웨이브 %d · 처치 %d" % ["클리어" if win else "전멸", wave, kills], win, "클리어" if win else "전멸",
		wave * 12 + mini(kills, 40) + (60 if win else 0))
	if wave > best_wave:
		best_wave = wave; new_best = true
	if kills > best_kills:
		best_kills = kills; new_best = true
	if run_time > best_time:   # longest survival (win or lose)
		best_time = run_time; new_best = true
	_save_best()
	hide_play_hud()
	get_tree().paused = true

func reset() -> void:
	move = Vector2.ZERO; look = Vector2.ZERO; fire_held = false
	_jump = false; _reload = false; spread_deg = 1.0
	_crouch = false; crouched = false; grenades = NADE_MAX; nade_aiming = false
	nade_over_cancel = false; _nade_throw = false; shake = 0.0
	act_label = ""; act_held = false; act_progress = 0.0
	ammo = 30; ammo_max = 30; reloading = false
	slot = 0; weapon_id = str(loadout[0]); swapping = false; _swap_to = -1
	scoped = false; _scope = false; mag_bonus = 0
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
		sfx_on = bool(data.get("sfx_on", true))
		vibrate_on = bool(data.get("vibrate_on", true))
		sniper_hold = bool(data.get("sniper_hold", true))
		look_sens = clampf(float(data.get("look_sens", 1.0)), 0.4, 2.0)
		scope_sens = clampf(float(data.get("scope_sens", 0.5)), 0.2, 1.5)
		view_fp = bool(data.get("view_fp", false))
		left_handed = bool(data.get("left_handed", false))
		var lo = data.get("loadout", [])
		if typeof(lo) == TYPE_ARRAY and lo.size() == 3:
			for i in 3:
				if Weapons.ids_for_slot(i).has(str(lo[i])): loadout[i] = str(lo[i])
		weapon_id = str(loadout[0])
		bot_diff = str(data.get("bot_diff", "reg"))
		if not ["rook", "reg", "vet", "elite"].has(bot_diff): bot_diff = "reg"
		sel_map = str(data.get("sel_map", "downtown"))
		var hl = data.get("hud_layout", {})
		# layout v2: the new default arrangement replaces older saved layouts once
		if typeof(hl) == TYPE_DICTIONARY and int(data.get("layout_v", 1)) >= 2:
			hud_layout = hl

func save_settings() -> void:
	_save_best()

func _save_best() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"best_wave": best_wave, "best_kills": best_kills, "best_time": best_time,
		"sfx_on": sfx_on, "vibrate_on": vibrate_on, "sniper_hold": sniper_hold,
		"look_sens": look_sens, "scope_sens": scope_sens, "view_fp": view_fp, "left_handed": left_handed,
		"hud_layout": hud_layout, "loadout": loadout,
		"bot_diff": bot_diff, "sel_map": sel_map, "layout_v": 2,
	}))
	f.close()
