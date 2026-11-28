class_name Profile
extends RefCounted
## Player profile kept on this device (user://profile.json):
##  - cosmetics: catalogue, owned items, what is equipped (bought with mission ◆ coins)
##  - career stats for the 기록 tab (totals, per mode, kills per weapon, recent matches)
## Cosmetics never change stats.

const PATH := "user://profile.json"

# ---------------------------------------------------------------- catalogue
const CATS := [["zweapon", "좀비 무기"], ["body", "캐릭터"], ["skin", "캐릭터 스킨"], ["killfx", "킬 이펙트"], ["tracer", "탄환 효과"], ["wfx", "무기 효과"], ["cfx", "캐릭터 효과"], ["bomb", "폭탄 스킨"], ["suit", "완장 색"], ["finish", "무기 도색"], ["title", "칭호"]]
const ITEMS := [
	# zombie-mode weapons: owned, then picked in the wave survival loadout (no "equip" here)
	{"id": "zw_axe", "cat": "zweapon", "wid": "axe", "name": "소방 도끼", "price": 500},
	{"id": "zw_dbarrel", "cat": "zweapon", "wid": "dbarrel", "name": "더블 배럴", "price": 800},
	{"id": "zw_flamer", "cat": "zweapon", "wid": "flamer", "name": "화염방사기", "price": 1500},
	# body: the soldier model (same skeleton / animations)
	# the five concept-sheet characters, all built in Blender (tools/blender/build_mini_v3.py -- CLASS)
	{"id": "body_rookie", "cat": "body", "name": "루키 어썰트", "price": 0},
	{"id": "body_scout", "cat": "body", "name": "스위프트 스카우트", "price": 400},
	{"id": "body_tech", "cat": "body", "name": "테크 서포트", "price": 400},
	{"id": "body_sniper", "cat": "body", "name": "섀도 스나이퍼", "price": 500},
	{"id": "body_heavy", "cat": "body", "name": "헤비 거너", "price": 500},
	# killfx: effect on a target you kill / tracer: your bullet trails (FxCos)
	{"id": "kill_none", "cat": "killfx", "name": "없음", "price": 0, "col": Color(0.25, 0.27, 0.3)},
	{"id": "kill_fire", "cat": "killfx", "name": "불꽃놀이", "price": 200, "col": Color(1.0, 0.35, 0.3), "col2": Color(0.3, 0.85, 1.0), "pat": 5},
	{"id": "kill_bolt", "cat": "killfx", "name": "번개", "price": 250, "col": Color(0.45, 0.65, 1.0), "col2": Color(0.95, 0.97, 1.0), "pat": 5},
	{"id": "kill_pixel", "cat": "killfx", "name": "픽셀 붕괴", "price": 250, "col": Color(1.0, 0.55, 0.2), "col2": Color(0.25, 0.25, 0.28), "pat": 5},
	{"id": "kill_soul", "cat": "killfx", "name": "유령", "price": 300, "col": Color(0.55, 0.85, 1.0), "col2": Color(0.9, 0.97, 1.0), "pat": 5},
	{"id": "kill_coin", "cat": "killfx", "name": "코인 분수", "price": 400, "col": Color(1.0, 0.78, 0.22), "col2": Color(1.0, 0.95, 0.7), "pat": 5},
	{"id": "tr_basic", "cat": "tracer", "name": "기본", "price": 0, "col": Color(1.0, 0.85, 0.4)},
	{"id": "tr_neon", "cat": "tracer", "name": "네온 블루", "price": 150, "col": Color(0.1, 0.75, 1.0), "col2": Color(0.9, 1.0, 1.0), "pat": 5},
	{"id": "tr_flame", "cat": "tracer", "name": "불꽃", "price": 200, "col": Color(1.0, 0.45, 0.08), "col2": Color(1.0, 0.85, 0.4), "pat": 5},
	{"id": "tr_rainbow", "cat": "tracer", "name": "무지개", "price": 300, "col": Color(1.0, 0.3, 0.3), "col2": Color(0.3, 0.7, 1.0), "pat": 7},
	{"id": "tr_plasma", "cat": "tracer", "name": "플라스마", "price": 300, "col": Color(0.6, 0.25, 1.0), "col2": Color(0.95, 0.85, 1.0), "pat": 5},
	# wfx: particles on your gun / cfx: particles on your character (FxCos)
	{"id": "wfx_none", "cat": "wfx", "name": "없음", "price": 0, "col": Color(0.25, 0.27, 0.3)},
	{"id": "wfx_ember", "cat": "wfx", "name": "불씨", "price": 200, "col": Color(1.0, 0.5, 0.12), "col2": Color(1.0, 0.85, 0.45), "pat": 5},
	{"id": "wfx_spark", "cat": "wfx", "name": "전기 스파크", "price": 250, "col": Color(0.35, 0.65, 1.0), "col2": Color(0.92, 0.97, 1.0), "pat": 5},
	{"id": "wfx_frost", "cat": "wfx", "name": "서리", "price": 250, "col": Color(0.75, 0.92, 1.0), "col2": Color(0.45, 0.7, 0.9), "pat": 5},
	{"id": "wfx_void", "cat": "wfx", "name": "공허", "price": 300, "col": Color(0.42, 0.12, 0.7), "col2": Color(0.8, 0.5, 1.0), "pat": 5},
	{"id": "wfx_gold", "cat": "wfx", "name": "금빛 반짝임", "price": 300, "col": Color(1.0, 0.8, 0.3), "col2": Color(1.0, 0.95, 0.7), "pat": 5},
	{"id": "cfx_none", "cat": "cfx", "name": "없음", "price": 0, "col": Color(0.25, 0.27, 0.3)},
	{"id": "cfx_flame", "cat": "cfx", "name": "불꽃 발자국", "price": 250, "col": Color(1.0, 0.45, 0.08), "col2": Color(1.0, 0.85, 0.4), "pat": 5},
	{"id": "cfx_stardust", "cat": "cfx", "name": "별가루 꼬리", "price": 250, "col": Color(0.75, 0.8, 1.0), "col2": Color(1.0, 0.9, 1.0), "pat": 5},
	{"id": "cfx_aura", "cat": "cfx", "name": "푸른 오라", "price": 300, "col": Color(0.3, 0.7, 1.0), "col2": Color(0.7, 0.9, 1.0), "pat": 5},
	{"id": "cfx_petal", "cat": "cfx", "name": "꽃잎", "price": 300, "col": Color(1.0, 0.55, 0.75), "col2": Color(1.0, 0.85, 0.9), "pat": 5},
	{"id": "cfx_shadow", "cat": "cfx", "name": "그림자 연기", "price": 350, "col": Color(0.35, 0.1, 0.6), "col2": Color(0.75, 0.45, 1.0), "pat": 5},
	# bomb: your bomb's look in 폭파미션 (material -> colour; tools/blender/build_bomb.py material names)
	{"id": "bomb_base", "cat": "bomb", "name": "기본", "price": 0, "col": Color("5a5e48"), "col2": Color("2f3328"), "pat": 5, "mats": {}},
	{"id": "bomb_desert", "cat": "bomb", "name": "사막 위장", "price": 200, "col": Color("b89e70"), "col2": Color("d98040"), "pat": 5, "mats": {"B_Case": Color(0.72, 0.62, 0.44), "B_Case2": Color(0.55, 0.46, 0.32), "B_Charge": Color(0.85, 0.50, 0.25), "B_Tape": Color(0.42, 0.33, 0.22), "B_Panel": Color(0.35, 0.30, 0.24), "B_Screen": Color(1.00, 0.60, 0.15)}},
	{"id": "bomb_cyber", "cat": "bomb", "name": "네온 사이버", "price": 300, "col": Color("14141a"), "col2": Color("1ae6f2"), "pat": 5, "mats": {"B_Case": Color(0.08, 0.08, 0.10), "B_Case2": Color(0.05, 0.05, 0.07), "B_Charge": Color(0.15, 0.16, 0.20), "B_Tape": Color(0.10, 0.90, 0.95), "B_Screen": Color(0.20, 0.95, 1.00), "B_Stripe": Color(1.00, 0.20, 0.80), "B_WireA": Color(1.00, 0.20, 0.80), "B_WireB": Color(0.10, 0.90, 1.00), "B_LED": Color(0.20, 0.90, 1.00)}},
	{"id": "bomb_gift", "cat": "bomb", "name": "파티 선물", "price": 300, "col": Color("d92630"), "col2": Color("ffd933"), "pat": 5, "mats": {"B_Case": Color(0.85, 0.15, 0.18), "B_Case2": Color(0.60, 0.08, 0.10), "B_Charge": Color(0.95, 0.25, 0.30), "B_Tape": Color(1.00, 0.85, 0.20), "B_Panel": Color(0.10, 0.45, 0.25), "B_Screen": Color(1.00, 1.00, 0.85), "B_Stripe": Color(1.00, 1.00, 1.00), "B_WireA": Color(1.00, 0.85, 0.20), "B_WireB": Color(0.20, 0.75, 0.35)}},
	{"id": "bomb_gold", "cat": "bomb", "name": "황금", "price": 400, "col": Color("f2bf40"), "col2": Color("fff2db"), "pat": 5, "mats": {"B_Case": Color(0.95, 0.75, 0.25), "B_Case2": Color(0.70, 0.52, 0.15), "B_Charge": Color(0.98, 0.95, 0.86), "B_Tape": Color(0.85, 0.65, 0.20), "B_Panel": Color(0.12, 0.10, 0.08), "B_Screen": Color(1.00, 0.75, 0.25), "B_Stripe": Color(0.12, 0.10, 0.08)}, "metal": true},
	# suit: the player's armband / patch colour (the "Team" material of every character)
	{"id": "suit_orange", "cat": "suit", "name": "기본 주황", "price": 0, "col": Color(0.95, 0.62, 0.24)},
	{"id": "suit_desert", "cat": "suit", "name": "사막", "price": 120, "col": Color(0.78, 0.68, 0.48)},
	{"id": "suit_wood", "cat": "suit", "name": "숲 위장", "price": 150, "col": Color(0.40, 0.50, 0.30)},
	{"id": "suit_urban", "cat": "suit", "name": "도시 회색", "price": 150, "col": Color(0.55, 0.58, 0.62)},
	{"id": "suit_night", "cat": "suit", "name": "야간 남색", "price": 200, "col": Color(0.22, 0.27, 0.42)},
	{"id": "suit_snow", "cat": "suit", "name": "설원 흰색", "price": 250, "col": Color(0.88, 0.90, 0.92)},
	{"id": "suit_crimson", "cat": "suit", "name": "진홍", "price": 250, "col": Color(0.70, 0.18, 0.16)},
	{"id": "suit_tiger", "cat": "suit", "name": "타이거 주황", "price": 300, "col": Color(1.0, 0.50, 0.08)},
	# skin: per character colour set (material -> sRGB colour); only for a character you own
	{"id": "skin_rookie_base", "cat": "skin", "body": "body_rookie", "name": "루키 · 기본", "price": 0, "mats": {}},
	{"id": "skin_rookie_desert", "cat": "skin", "body": "body_rookie", "name": "루키 · 사막 폭풍", "price": 250, "mats": {"R_Uniform": Color(0.70, 0.60, 0.44), "R_Sleeve": Color(0.78, 0.69, 0.52), "R_Gear": Color(0.56, 0.46, 0.31), "R_Gear2": Color(0.47, 0.38, 0.25), "R_Helmet": Color(0.66, 0.57, 0.41), "R_Boot": Color(0.45, 0.36, 0.26)}},
	{"id": "skin_rookie_urban", "cat": "skin", "body": "body_rookie", "name": "루키 · 도시 작전", "price": 250, "mats": {"R_Uniform": Color(0.40, 0.42, 0.46), "R_Sleeve": Color(0.55, 0.57, 0.60), "R_Gear": Color(0.22, 0.23, 0.25), "R_Gear2": Color(0.17, 0.18, 0.20), "R_Helmet": Color(0.25, 0.26, 0.29), "R_Boot": Color(0.15, 0.15, 0.16)}},
	{"id": "skin_scout_base", "cat": "skin", "body": "body_scout", "name": "스카우트 · 기본", "price": 0, "mats": {}},
	{"id": "skin_scout_jungle", "cat": "skin", "body": "body_scout", "name": "스카우트 · 정글 레인저", "price": 250, "mats": {"R_Uniform": Color(0.24, 0.33, 0.19), "R_Sleeve": Color(0.36, 0.43, 0.26), "R_Gear": Color(0.31, 0.37, 0.22), "R_Gear2": Color(0.25, 0.30, 0.18), "R_Helmet": Color(0.28, 0.38, 0.22), "R_Accent": Color(0.10, 0.78, 0.66)}},
	{"id": "skin_scout_street", "cat": "skin", "body": "body_scout", "name": "스카우트 · 스트리트", "price": 250, "mats": {"R_Uniform": Color(0.14, 0.14, 0.16), "R_Sleeve": Color(0.86, 0.86, 0.83), "R_Gear": Color(0.21, 0.21, 0.23), "R_Gear2": Color(0.15, 0.15, 0.17), "R_Helmet": Color(0.88, 0.88, 0.86), "R_Boot": Color(0.85, 0.85, 0.83), "R_Accent": Color(0.12, 0.75, 0.75)}},
	{"id": "skin_tech_base", "cat": "skin", "body": "body_tech", "name": "테크 · 기본", "price": 0, "mats": {}},
	{"id": "skin_tech_hivis", "cat": "skin", "body": "body_tech", "name": "테크 · 공병 하이비즈", "price": 250, "mats": {"R_Uniform": Color(0.30, 0.32, 0.34), "R_Sleeve": Color(0.42, 0.44, 0.46), "R_Gear": Color(0.95, 0.72, 0.12), "R_Gear2": Color(0.88, 0.56, 0.10), "R_Helmet": Color(0.96, 0.78, 0.18)}},
	{"id": "skin_tech_cyber", "cat": "skin", "body": "body_tech", "name": "테크 · 사이버 옵스", "price": 250, "mats": {"R_Uniform": Color(0.12, 0.13, 0.16), "R_Sleeve": Color(0.20, 0.22, 0.26), "R_Gear": Color(0.17, 0.18, 0.21), "R_Gear2": Color(0.11, 0.12, 0.14), "R_Helmet": Color(0.15, 0.16, 0.19), "R_Accent": Color(0.10, 0.92, 0.95), "R_Lens": Color(0.10, 0.85, 0.95)}},
	{"id": "skin_sniper_base", "cat": "skin", "body": "body_sniper", "name": "스나이퍼 · 기본", "price": 0, "mats": {}},
	{"id": "skin_sniper_snow", "cat": "skin", "body": "body_sniper", "name": "스나이퍼 · 설원 고스트", "price": 250, "mats": {"R_Uniform": Color(0.85, 0.87, 0.88), "R_Sleeve": Color(0.92, 0.93, 0.94), "R_Gear": Color(0.74, 0.76, 0.78), "R_Gear2": Color(0.64, 0.66, 0.68), "R_Helmet": Color(0.90, 0.91, 0.92), "R_Ghillie1": Color(0.90, 0.92, 0.92), "R_Ghillie2": Color(0.76, 0.79, 0.80), "R_Ghillie3": Color(0.97, 0.97, 0.97), "R_Dark": Color(0.80, 0.82, 0.84)}},
	{"id": "skin_sniper_dune", "cat": "skin", "body": "body_sniper", "name": "스나이퍼 · 사막 유령", "price": 250, "mats": {"R_Uniform": Color(0.66, 0.56, 0.40), "R_Sleeve": Color(0.74, 0.64, 0.47), "R_Gear": Color(0.55, 0.45, 0.31), "R_Gear2": Color(0.47, 0.38, 0.26), "R_Helmet": Color(0.70, 0.60, 0.43), "R_Ghillie1": Color(0.70, 0.60, 0.42), "R_Ghillie2": Color(0.56, 0.45, 0.30), "R_Ghillie3": Color(0.80, 0.70, 0.52), "R_Dark": Color(0.42, 0.34, 0.25)}},
	{"id": "skin_heavy_base", "cat": "skin", "body": "body_heavy", "name": "헤비 · 기본", "price": 0, "mats": {}},
	{"id": "skin_heavy_riot", "cat": "skin", "body": "body_heavy", "name": "헤비 · 진압대", "price": 250, "mats": {"R_Uniform": Color(0.12, 0.12, 0.13), "R_Sleeve": Color(0.19, 0.19, 0.20), "R_Gear": Color(0.15, 0.15, 0.16), "R_Gear2": Color(0.10, 0.10, 0.11), "R_Helmet": Color(0.13, 0.13, 0.14), "R_Pauldron": Color(0.16, 0.16, 0.17), "R_Accent": Color(0.88, 0.12, 0.10)}},
	{"id": "skin_heavy_arctic", "cat": "skin", "body": "body_heavy", "name": "헤비 · 북극 강습", "price": 250, "mats": {"R_Uniform": Color(0.82, 0.84, 0.86), "R_Sleeve": Color(0.66, 0.68, 0.70), "R_Gear": Color(0.60, 0.63, 0.66), "R_Gear2": Color(0.50, 0.53, 0.56), "R_Helmet": Color(0.86, 0.87, 0.89), "R_Pauldron": Color(0.88, 0.89, 0.90), "R_Boot": Color(0.30, 0.31, 0.33)}},
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
const DEFAULT_EQUIP := {"body": "body_rookie", "gear": "gear_helmet", "suit": "suit_orange", "kit": "kit_brown", "finish": "fin_none", "title": "tt_rookie", "killfx": "kill_none", "tracer": "tr_basic", "wfx": "wfx_none", "cfx": "cfx_none", "bomb": "bomb_base"}

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
	if not _d.get("rookie_default", false):      # v98: Rookie Assault becomes the default body (once, for existing saves too)
		_d["rookie_default"] = true; _d["equip"]["body"] = "body_rookie"; save()
	if item(String(_d["equip"]["body"])).is_empty():   # v107: removed bodies (mini / swat / Tripo rookie) -> Rookie
		_d["equip"]["body"] = "body_rookie"; save()
	# v111: the helmet / vest colour items (kit_*) never worked on the new characters: removed, coins refunded
	const KIT_PRICE := {"kit_olive": 120, "kit_black": 150, "kit_tan": 150, "kit_navy": 200, "kit_white": 250}
	var refund := 0
	for id in _d["owned"].duplicate():
		if String(id).begins_with("kit_"):
			refund += int(KIT_PRICE.get(id, 0)); _d["owned"].erase(id)
	if refund > 0:
		Missions.earn(refund); _d["kit_refund"] = refund; save()
	if not _d.has("gold_kept"):                    # v119: primaries now need 250 kills; golds already earned stay
		var kept := []
		for w in Weapons.ORDER_PRIMARY:
			if int(_d["stats"].get("k_" + w, 0)) >= MASTERY: kept.append(w)
		_d["gold_kept"] = kept; save()
	if not owns(String(_d["equip"]["body"])):           # v108: only the Rookie is free; the others are bought in the shop
		_d["equip"]["body"] = "body_rookie"; save()

## nickname (main menu, top left); 2..12 characters
static func nick() -> String:
	_load()
	return String(_d.get("nick", "SOLDIER_01"))

static func set_nick(n: String) -> bool:
	n = n.strip_edges()
	if n.length() < 2 or n.length() > 12: return false
	_load(); _d["nick"] = n; save()
	return true

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
	if cat == "zweapon": return ""
	if cat == "skin": return skin_id(equipped("body"))
	return String(_d["equip"].get(cat, DEFAULT_EQUIP[cat]))

static func buy(id: String) -> bool:
	_load()
	var it := item(id)
	if it.is_empty() or owns(id) or int(it["price"]) <= 0: return false
	if it.has("body") and not owns(String(it["body"])): return false     # skins: buy the character first
	if not Missions.spend(price_today(id)): return false
	_d["owned"].append(id)
	save()
	return true

static func equip(id: String) -> void:
	_load()
	var it := item(id)
	if it.is_empty() or not owns(id) or it["cat"] == "zweapon": return
	if it["cat"] == "skin":
		if not owns(String(it["body"])): return
		_d["equip"]["skin_" + String(it["body"]).substr(5)] = id
		_d["equip"]["body"] = it["body"]          # wearing a skin = wearing that character
	else:
		_d["equip"][it["cat"]] = id
	save()

## the skin equipped for a character ("body_scout" -> "skin_scout_jungle")
static func skin_id(body_id: String) -> String:
	_load()
	var cls := body_id.substr(5)
	return String(_d["equip"].get("skin_" + cls, "skin_%s_base" % cls))

## material colours of a skin (empty = the character's own palette)
static func skin_mats(skin: String) -> Dictionary:
	return item(skin).get("mats", {})

## every skin of a character, for bots
static func skins_of(cls: String) -> Array:
	return ITEMS.filter(func(it): return it["cat"] == "skin" and it["body"] == "body_" + cls).map(func(it): return it["id"])

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
const MASTERY := 50          # kills with a sidearm for its gold finish (knife: 15)
const MASTERY_PRIMARY := 250 # kills with a primary weapon for its gold finish (v119: was 50)
static func mastery_goal(wid: String) -> int:
	if wid == "knife": return 15
	if wid in Weapons.ORDER_SECONDARY: return MASTERY          # sidearms stay at 50
	return MASTERY_PRIMARY                                     # rifles / SMG / shotgun / sniper / LMG: 250
static func mastered(wid: String) -> bool:
	_load()
	if wid in _d.get("gold_kept", []): return true             # unlocked under the old 50-kill rule: keep it
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
	var pool: Array = ITEMS.filter(func(it): return int(it["price"]) > 0 and not (it["id"] in exclude) and (not it.has("body") or owns(String(it["body"]))))
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

## recolour a bomb model (assets/bomb/bomb.glb) with a bomb skin
static func apply_bomb_skin(model: Node, id: String) -> void:
	var it := item(id)
	var mats: Dictionary = it.get("mats", {})
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var g := mi as MeshInstance3D
		for si in g.mesh.get_surface_count():
			var m := g.mesh.surface_get_material(si) as StandardMaterial3D
			if m == null or not mats.has(m.resource_name): continue
			var d := m.duplicate() as StandardMaterial3D
			d.albedo_color = mats[m.resource_name]
			if d.emission_enabled: d.emission = mats[m.resource_name]
			if it.get("metal", false) and m.resource_name in ["B_Case", "B_Case2", "B_Tape"]: d.metallic = 0.9; d.roughness = 0.28
			g.set_surface_override_material(si, d)

## the screen colour of a bomb skin (for the countdown digits)
static func bomb_screen_col(id: String) -> Color:
	return item(id).get("mats", {}).get("B_Screen", Color(0.55, 1.0, 0.6))
