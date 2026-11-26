class_name Profile
extends RefCounted
## Player profile kept on this device (user://profile.json):
##  - cosmetics: catalogue, owned items, what is equipped (bought with mission ◆ coins)
##  - career stats for the 기록 tab (totals, per mode, kills per weapon, recent matches)
## Cosmetics never change stats.

const PATH := "user://profile.json"

# ---------------------------------------------------------------- catalogue
const CATS := [["suit", "병사 위장복"], ["kit", "헬멧·조끼"], ["finish", "무기 도색"], ["title", "칭호"]]
const ITEMS := [
	# suit: the uniform colour (sleeves / trousers)
	{"id": "suit_orange", "cat": "suit", "name": "기본 주황", "price": 0, "col": Color(0.95, 0.62, 0.24)},
	{"id": "suit_desert", "cat": "suit", "name": "사막", "price": 120, "col": Color(0.78, 0.68, 0.48)},
	{"id": "suit_wood", "cat": "suit", "name": "숲 위장", "price": 150, "col": Color(0.40, 0.50, 0.30)},
	{"id": "suit_urban", "cat": "suit", "name": "도시 회색", "price": 150, "col": Color(0.55, 0.58, 0.62)},
	{"id": "suit_night", "cat": "suit", "name": "야간 남색", "price": 200, "col": Color(0.22, 0.27, 0.42)},
	{"id": "suit_snow", "cat": "suit", "name": "설원 흰색", "price": 250, "col": Color(0.88, 0.90, 0.92)},
	{"id": "suit_crimson", "cat": "suit", "name": "진홍", "price": 250, "col": Color(0.70, 0.18, 0.16)},
	{"id": "suit_tiger", "cat": "suit", "name": "타이거 주황", "price": 300, "col": Color(1.0, 0.50, 0.08)},
	# kit: helmet + plate carrier
	{"id": "kit_brown", "cat": "kit", "name": "기본 갈색", "price": 0, "col": Color(0, 0, 0, 0)},
	{"id": "kit_olive", "cat": "kit", "name": "올리브", "price": 120, "col": Color(0.30, 0.34, 0.22)},
	{"id": "kit_black", "cat": "kit", "name": "전술 블랙", "price": 150, "col": Color(0.10, 0.10, 0.11)},
	{"id": "kit_tan", "cat": "kit", "name": "코요테 탄", "price": 150, "col": Color(0.55, 0.45, 0.30)},
	{"id": "kit_navy", "cat": "kit", "name": "네이비", "price": 200, "col": Color(0.14, 0.18, 0.30)},
	{"id": "kit_white", "cat": "kit", "name": "설원", "price": 250, "col": Color(0.80, 0.82, 0.84)},
	# finish: every gun the player holds
	{"id": "fin_none", "cat": "finish", "name": "기본", "price": 0, "col": Color(0, 0, 0, 0)},
	{"id": "fin_carbon", "cat": "finish", "name": "카본 블랙", "price": 150, "col": Color(0.07, 0.07, 0.08), "metal": 0.2},
	{"id": "fin_desert", "cat": "finish", "name": "사막 도색", "price": 150, "col": Color(0.72, 0.62, 0.44), "metal": 0.1},
	{"id": "fin_arctic", "cat": "finish", "name": "설원 도색", "price": 200, "col": Color(0.86, 0.88, 0.90), "metal": 0.1},
	{"id": "fin_crimson", "cat": "finish", "name": "크림슨", "price": 250, "col": Color(0.55, 0.08, 0.08), "metal": 0.5},
	{"id": "fin_gold", "cat": "finish", "name": "금장", "price": 300, "col": Color(0.85, 0.66, 0.20), "metal": 0.9},
	# title: shown under the name in the menu
	{"id": "tt_rookie", "cat": "title", "name": "신병", "price": 0},
	{"id": "tt_sniper", "cat": "title", "name": "명사수", "price": 120},
	{"id": "tt_demo", "cat": "title", "name": "폭파 전문가", "price": 150},
	{"id": "tt_hunter", "cat": "title", "name": "좀비 사냥꾼", "price": 150},
	{"id": "tt_ghost", "cat": "title", "name": "그림자", "price": 200},
	{"id": "tt_legend", "cat": "title", "name": "전설의 병사", "price": 300},
]
const DEFAULT_EQUIP := {"suit": "suit_orange", "kit": "kit_brown", "finish": "fin_none", "title": "tt_rookie"}

static var _d := {}
static var _loaded := false

static func _load() -> void:
	if _loaded: return
	_loaded = true
	var d = null
	if FileAccess.file_exists(PATH):
		d = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	_d = d if d is Dictionary else {}
	if not _d.has("owned"): _d["owned"] = []
	if not _d.has("equip"): _d["equip"] = DEFAULT_EQUIP.duplicate()
	for k in DEFAULT_EQUIP:
		if not _d["equip"].has(k): _d["equip"][k] = DEFAULT_EQUIP[k]
	if not _d.has("stats"): _d["stats"] = {}
	if not _d.has("recent"): _d["recent"] = []

static func save() -> void:
	_load()
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(_d))

static func item(id: String) -> Dictionary:
	for it in ITEMS:
		if it["id"] == id: return it
	return {}

static func items(cat: String) -> Array:
	return ITEMS.filter(func(it): return it["cat"] == cat)

static func owns(id: String) -> bool:
	_load()
	return int(item(id).get("price", 1)) == 0 or id in _d["owned"]

static func equipped(cat: String) -> String:
	_load()
	return String(_d["equip"].get(cat, DEFAULT_EQUIP[cat]))

static func buy(id: String) -> bool:
	_load()
	var it := item(id)
	if it.is_empty() or owns(id): return false
	if not Missions.spend(int(it["price"])): return false
	_d["owned"].append(id)
	save()
	return true

static func equip(id: String) -> void:
	_load()
	var it := item(id)
	if it.is_empty() or not owns(id): return
	_d["equip"][it["cat"]] = id
	save()

# colours the player's soldier wears / finish for the player's guns
static func suit_color() -> Color:
	return item(equipped("suit")).get("col", Color(0.95, 0.62, 0.24))

static func kit_color() -> Color:
	return item(equipped("kit")).get("col", Color(0, 0, 0, 0))

static func title() -> String:
	return String(item(equipped("title")).get("name", "신병"))

## paint a weapon model with the equipped finish (or a given one for previews)
static func apply_finish(model: Node, fin_id := "") -> void:
	if model == null: return
	var it := item(fin_id if fin_id != "" else equipped("finish"))
	if it.is_empty() or Color(it.get("col", Color(0, 0, 0, 0))).a == 0.0: return
	var m := StandardMaterial3D.new()
	m.albedo_color = it["col"]; m.metallic = float(it.get("metal", 0.3)); m.roughness = 0.35 if m.metallic > 0.5 else 0.6
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = m

# ---------------------------------------------------------------- career stats
static func stat(key: String) -> float:
	_load()
	return float(_d["stats"].get(key, 0))

static func bump(key: String, n: float = 1.0) -> void:
	_load()
	_d["stats"][key] = float(_d["stats"].get(key, 0)) + n

static func best(key: String, v: float) -> void:
	_load()
	_d["stats"][key] = maxf(float(_d["stats"].get(key, 0)), v)

## a finished match: per-mode counters + the recent list (newest first, 20 kept)
static func match_done(mode: String, map_name: String, result: String, win: bool, tag: String) -> void:
	_load()
	bump("matches"); bump("m_%s" % mode)
	if win: bump("wins"); bump("w_%s" % mode)
	_d["recent"].push_front({"mode": mode, "map": map_name, "result": result, "win": win, "tag": tag})
	while _d["recent"].size() > 20: _d["recent"].pop_back()
	save()

static func recent() -> Array:
	_load()
	return _d["recent"]
