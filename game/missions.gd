class_name Missions
extends RefCounted
## 오늘의 임무: three missions drawn at random for each calendar day (the date
## seeds the draw, so the day's set is stable and works offline). Progress comes
## from play events (Missions.add); a finished mission pays its coins at once.
## Also keeps the coin total and the last match summary for the main menu.

const PATH := "user://missions.json"
const TEMPLATES := [
	{"id": "kill", "text": "처치 %d회", "n": [10, 15, 20, 25], "coin": 40},
	{"id": "headshot", "text": "헤드샷 %d회", "n": [5, 8, 10], "coin": 50},
	{"id": "knife_kill", "text": "대검으로 처치 %d회", "n": [1, 2, 3], "coin": 60},
	{"id": "win", "text": "아무 모드에서 승리 %d회", "n": [1, 2], "coin": 60},
	{"id": "match", "text": "아무 모드 %d판 플레이", "n": [2, 3], "coin": 30},
	{"id": "wave", "text": "웨이브 서바이벌 %d웨이브 도달", "n": [3, 4, 5], "coin": 50, "max": true},
	{"id": "plant", "text": "폭탄 설치 %d회", "n": [1, 2], "coin": 50},
	{"id": "defuse", "text": "폭탄 해체 %d회", "n": [1], "coin": 60},
	{"id": "target", "text": "훈련에서 표적 %d개 쓰러뜨리기", "n": [15, 25], "coin": 30},
]

static var _data := {}
static var _loaded := false

static func _today() -> String:
	return Time.get_date_string_from_system()

static func _load() -> void:
	if _loaded and _data.get("day", "") == _today(): return
	_loaded = true
	var d = null
	if FileAccess.file_exists(PATH):
		d = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	_data = d if d is Dictionary else {}
	if not _data.has("coins"): _data["coins"] = 0
	if _data.get("day", "") != _today():
		_data["day"] = _today()
		_data["list"] = _draw(_today())
		_save()

static func _draw(day: String) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("mini-soldier-" + day)
	var pool := TEMPLATES.duplicate()
	var out := []
	for i in 3:
		var t: Dictionary = pool.pop_at(rng.randi_range(0, pool.size() - 1))
		if t["id"] in ["plant", "defuse"]:   # at most one bomb-only mission a day
			pool = pool.filter(func(x): return not (x["id"] in ["plant", "defuse"]))
		var n: int = t["n"][rng.randi_range(0, t["n"].size() - 1)]
		out.append({"id": t["id"], "text": String(t["text"]) % n, "goal": n, "have": 0,
			"coin": int(t["coin"]) + (10 if n >= int(t["n"][-1]) else 0), "done": false, "max": t.get("max", false)})
	return out

static func _save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(_data))

## a play event: kill / headshot / knife_kill / win / match / plant / defuse / target (+n),
## wave (value = the wave reached; keeps the best of the day)
static func add(id: String, n := 1) -> void:
	_load()
	if id == "wave": Profile.best("best_wave", n)
	elif id != "match" and id != "win": Profile.bump(id, n)
	if id == "kill": Profile.bump("k_%s" % Controls.weapon_id, n)
	var changed := false
	for m in _data["list"]:
		if m["id"] != id or m["done"]: continue
		m["have"] = maxi(int(m["have"]), n) if m.get("max", false) else int(m["have"]) + n
		if int(m["have"]) >= int(m["goal"]):
			m["have"] = int(m["goal"]); m["done"] = true
			_data["coins"] = int(_data["coins"]) + int(m["coin"])
		changed = true
	if changed: _save()

static func today() -> Array:
	_load()
	return _data["list"]

static func coins() -> int:
	_load()
	return int(_data["coins"])

static func earn(n: int) -> void:
	_load()
	_data["coins"] = int(_data["coins"]) + n
	_save()

static func spend(n: int) -> bool:
	_load()
	if int(_data["coins"]) < n: return false
	_data["coins"] = int(_data["coins"]) - n
	_save()
	return true

## last finished match for the 최근 기록 card (+ career stats)
static func record(mode: String, map_name: String, result: String, win := false, tag := "") -> void:
	_load()
	_data["last"] = {"mode": mode, "map": map_name, "result": result}
	_save()
	Profile.match_done(mode, map_name, result, win, tag if tag != "" else ("승리" if win else "패배"))

static func last() -> Dictionary:
	_load()
	return _data.get("last", {})
