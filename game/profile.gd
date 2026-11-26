class_name Profile
extends RefCounted
## Player profile kept on this device (user://profile.json):
##  - cosmetics: catalogue, owned items, what is equipped (bought with mission ◆ coins)
##  - career stats for the 기록 tab (totals, per mode, kills per weapon, recent matches)
## Cosmetics never change stats.

const PATH := "user://profile.json"

# ---------------------------------------------------------------- catalogue
const CATS := [["body", "캐릭터"], ["gear", "머리 장비"], ["suit", "병사 위장복"], ["kit", "헬멧·조끼 색"], ["finish", "무기 도색"], ["title", "칭호"]]
const ITEMS := [
	# body: the soldier model (same skeleton / animations)
	{"id": "body_mini", "cat": "body", "name": "꼬마 병사", "price": 0},
	{"id": "body_swat", "cat": "body", "name": "꼬마 SWAT", "price": 300},
	# gear: head gear on the mini
	{"id": "gear_helmet", "cat": "gear", "name": "고글 헬멧", "price": 0},
	{"id": "gear_beret", "cat": "gear", "name": "베레모", "price": 150},
	{"id": "gear_mask", "cat": "gear", "name": "방독면", "price": 250},
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
	# finish: every gun the player holds (pat = procedural pattern in skin.gdshader)
	{"id": "fin_none", "cat": "finish", "name": "기본", "price": 0, "col": Color(0, 0, 0, 0)},
	{"id": "fin_desert", "cat": "finish", "name": "사막 도색", "price": 120, "col": Color(0.72, 0.62, 0.44), "metal": 0.1},
	{"id": "fin_arctic", "cat": "finish", "name": "설원 도색", "price": 150, "col": Color(0.86, 0.88, 0.90), "metal": 0.1},
	{"id": "fin_carbon", "cat": "finish", "name": "카본", "price": 150, "col": Color(0.10, 0.10, 0.11), "col2": Color(0.24, 0.24, 0.26), "pat": 5},
	{"id": "fin_crimson", "cat": "finish", "name": "크림슨", "price": 200, "col": Color(0.55, 0.08, 0.08), "metal": 0.5},
	{"id": "fin_woodland", "cat": "finish", "name": "숲 위장", "price": 200, "col": Color(0.40, 0.48, 0.28), "col2": Color(0.24, 0.28, 0.16), "pat": 1},
	{"id": "fin_digital", "cat": "finish", "name": "디지털 블루", "price": 250, "col": Color(0.35, 0.48, 0.66), "col2": Color(0.18, 0.26, 0.40), "pat": 2},
	{"id": "fin_tiger", "cat": "finish", "name": "타이거", "price": 250, "col": Color(1.0, 0.55, 0.10), "col2": Color(0.10, 0.08, 0.06), "pat": 3},
	{"id": "fin_fade", "cat": "finish", "name": "노을 그라데이션", "price": 300, "col": Color(0.95, 0.35, 0.55), "col2": Color(0.25, 0.45, 1.0), "pat": 7},
	{"id": "fin_neon", "cat": "finish", "name": "네온 라인", "price": 300, "col": Color(0.08, 0.09, 0.11), "col2": Color(0, 0, 0), "pat": 6},
	# mastery only (never sold): gold per weapon at MASTERY kills, damascus when every weapon is gold
	{"id": "fin_damascus", "cat": "finish", "name": "다마스커스", "price": -1, "mastery": true, "col": Color(0.80, 0.80, 0.82), "col2": Color(0.38, 0.38, 0.42), "pat": 4},
	# title: shown under the name in the menu
	{"id": "tt_rookie", "cat": "title", "name": "신병", "price": 0},
	{"id": "tt_sniper", "cat": "title", "name": "명사수", "price": 120},
	{"id": "tt_demo", "cat": "title", "name": "폭파 전문가", "price": 150},
	{"id": "tt_hunter", "cat": "title", "name": "좀비 사냥꾼", "price": 150},
	{"id": "tt_ghost", "cat": "title", "name": "그림자", "price": 200},
	{"id": "tt_legend", "cat": "title", "name": "전설의 병사", "price": 300},
]
const DEFAULT_EQUIP := {"body": "body_mini", "gear": "gear_helmet", "suit": "suit_orange", "kit": "kit_brown", "finish": "fin_none", "title": "tt_rookie"}

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
	if id == "fin_damascus": return mastered_count() >= Weapons.ORDER_PRIMARY.size() + Weapons.ORDER_SECONDARY.size() + Weapons.ORDER_MELEE.size()
	return int(item(id).get("price", 1)) == 0 or id in _d["owned"]

static func equipped(cat: String) -> String:
	_load()
	return String(_d["equip"].get(cat, DEFAULT_EQUIP[cat]))

static func buy(id: String) -> bool:
	_load()
	var it := item(id)
	if it.is_empty() or owns(id) or int(it["price"]) <= 0: return false
	if not Missions.spend(price_today(id)): return false
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

const GOLD := {"id": "fin_gold", "name": "금장", "col": Color(0.85, 0.66, 0.20), "metal": 0.9}

## the finish a weapon wears: its mastery gold if switched on, else the equipped finish
static func finish_for(wid: String) -> Dictionary:
	_load()
	if wid != "" and wid in _d["equip"].get("gold", []) and mastered(wid): return GOLD
	return item(equipped("finish"))

## paint a weapon model (fin_id: preview a finish; "fin_gold" = mastery gold)
static func apply_finish(model: Node, fin_id := "", wid := "") -> void:
	if model == null: return
	var it: Dictionary = GOLD if fin_id == "fin_gold" else (item(fin_id) if fin_id != "" else finish_for(wid))
	if it.is_empty() or Color(it.get("col", Color(0, 0, 0, 0))).a == 0.0: return
	var mat: Material
	if it.has("pat"):
		for mi in model.find_children("*", "MeshInstance3D", true, false):
			var sm := ShaderMaterial.new(); sm.shader = load("res://skin.gdshader")
			sm.set_shader_parameter("pattern", int(it["pat"])); sm.set_shader_parameter("scale", 6.0)
			sm.set_shader_parameter("obj_size", (mi as MeshInstance3D).get_aabb().size)
			sm.set_shader_parameter("c1", it["col"]); sm.set_shader_parameter("c2", it.get("col2", Color.BLACK))
			(mi as MeshInstance3D).material_override = sm
		return
	var m := StandardMaterial3D.new()
	m.albedo_color = it["col"]; m.metallic = float(it.get("metal", 0.3)); m.roughness = 0.35 if m.metallic > 0.5 else 0.6
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = m

# ---------------------------------------------------------------- weapon mastery (gold)
const MASTERY := 50          # kills with a weapon for its gold finish (knife: 15)
static func mastery_goal(wid: String) -> int:
	return 15 if wid == "knife" else MASTERY
static func mastered(wid: String) -> bool:
	return stat("k_" + wid) >= mastery_goal(wid)
static func mastered_count() -> int:
	var n := 0
	for w in Weapons.ORDER_PRIMARY + Weapons.ORDER_SECONDARY + Weapons.ORDER_MELEE:
		if mastered(w): n += 1
	return n
static func gold_on(wid: String) -> bool:
	_load()
	return wid in _d["equip"].get("gold", [])
static func toggle_gold(wid: String) -> void:
	_load()
	if not mastered(wid): return
	var g: Array = _d["equip"].get("gold", [])
	if wid in g: g.erase(wid)
	else: g.append(wid)
	_d["equip"]["gold"] = g
	save()

# ---------------------------------------------------------------- today's shop + free gift
const OFFERS := 5
const DISCOUNT := 0.8         # today's offers: 20% off
const GIFT := 20              # free coins once a day

static func _day() -> String:
	return Time.get_date_string_from_system()

static func _draw_offers(day: String, exclude: Array) -> Array:
	var rng := RandomNumberGenerator.new(); rng.seed = hash("shop-" + day)
	var pool: Array = ITEMS.filter(func(it): return int(it["price"]) > 0 and not (it["id"] in exclude))
	var out := []
	while out.size() < OFFERS and not pool.is_empty():
		out.append(pool.pop_at(rng.randi_range(0, pool.size() - 1))["id"])
	return out

## today's 5 offers: drawn once a day from what you don't own yet, skipping
## yesterday's offers so the shop never repeats two days running
static func offers() -> Array:
	_load()
	if _d.get("offers_day", "") != _day():
		var y := Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()) - 86400)
		var excl: Array = _d["owned"].duplicate() + _draw_offers(y, _d["owned"])
		var got := _draw_offers(_day(), excl)
		if got.size() < OFFERS: got = _draw_offers(_day(), _d["owned"])     # small pool left: allow repeats
		_d["offers"] = got; _d["offers_day"] = _day(); save()
	return _d["offers"]

static func price_today(id: String) -> int:
	var p := int(item(id).get("price", 0))
	if id in offers(): return int(round(p * DISCOUNT / 10.0)) * 10
	return p

static func gift_ready() -> bool:
	_load()
	return _d.get("gift_day", "") != _day()

static func claim_gift() -> bool:
	if not gift_ready(): return false
	_d["gift_day"] = _day(); save()
	Missions.earn(GIFT)
	return true

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
