class_name Weapons
## Weapon table (시안 v2 수치 그대로). Player and bots read from here.
##   dmg      : per bullet (shotgun: per pellet) [min, max]
##   rpm      : rounds per minute (semi-auto guns: max tap rate)
##   auto     : hold to keep firing
##   spread   : [min, max] cone in degrees (hip); bloom = added per shot
##   kick     : camera recoil per shot (deg, upward)
##   speed    : move speed multiplier while held
##   scope    : zoom factor (sniper) ; scoped spread = spread_scoped

const ORDER_PRIMARY := ["ak", "m4", "mp5", "shotgun", "sniper", "rpk"]
const ORDER_SECONDARY := ["pistol", "revolver"]
const ORDER_MELEE := ["knife"]
const SLOT_NAMES := ["주무기", "보조", "근접"]

const W := {
	"ak": {"name": "SC-7", "cls": "돌격소총", "slot": 0, "dmg": [24, 32], "rpm": 600, "auto": true,
		"mag": 30, "reload": 2.0, "spread": [1.2, 8.0], "bloom": 0.8, "kick": 0.9, "speed": 0.95,
		"desc": "한 발이 묵직한 대신 반동이 큼. 중거리 화력형.", "bars": [8, 6, 5, 7, 5, 6]},
	"m4": {"name": "AR-9R", "cls": "돌격소총", "slot": 0, "dmg": [18, 26], "rpm": 670, "auto": true,
		"mag": 30, "reload": 1.8, "spread": [0.8, 6.0], "bloom": 0.55, "kick": 0.5, "speed": 0.97,
		"desc": "반동이 작고 정확. 무난한 기본 소총.", "bars": [6, 7, 7, 4, 4, 6]},
	"mp5": {"name": "SM-7", "cls": "기관단총", "slot": 0, "dmg": [14, 20], "rpm": 860, "auto": true,
		"mag": 30, "reload": 1.6, "spread": [1.5, 8.0], "bloom": 0.45, "kick": 0.3, "speed": 1.05,
		"desc": "빠른 연사·가벼움. 근거리 난전용, 멀면 약함.", "bars": [4, 9, 5, 2, 1, 6]},
	"shotgun": {"name": "펌프 샷건", "cls": "산탄총", "slot": 0, "dmg": [12, 12], "pellets": 8, "rpm": 75, "auto": false,
		"mag": 6, "reload": 3.0, "spread": [4.5, 7.0], "bloom": 0.6, "kick": 2.5, "speed": 0.95,
		"desc": "한 번에 8발 산탄. 가까우면 한 방, 멀면 흩어짐.", "bars": [10, 1, 2, 8, 5, 2]},
	"sniper": {"name": "SR-7L", "cls": "저격소총", "slot": 0, "dmg": [90, 110], "rpm": 50, "auto": false,
		"mag": 5, "reload": 2.6, "spread": [3.5, 9.0], "bloom": 2.0, "kick": 3.5, "speed": 0.88,
		"scope": 2.5, "spread_scoped": 0.1,
		"desc": "몸통 거의 한 방, 머리 한 방. 조준경 2.5배.", "bars": [10, 1, 10, 10, 8, 1]},
	"rpk": {"name": "LMG-76", "cls": "기관총", "slot": 0, "dmg": [20, 28], "rpm": 750, "auto": true,
		"mag": 100, "reload": 3.5, "spread": [2.0, 9.0], "bloom": 0.5, "kick": 0.6, "speed": 0.85,
		"desc": "탄창 100발로 오래 쏨. 무겁고 재장전 3.5초.", "bars": [6, 8, 3, 6, 10, 10]},
	"pistol": {"name": "권총", "cls": "권총", "slot": 1, "dmg": [20, 28], "rpm": 400, "auto": false,
		"mag": 12, "reload": 1.3, "spread": [1.0, 5.0], "bloom": 1.2, "kick": 0.6, "speed": 1.0,
		"desc": "반자동. 주무기 탄이 떨어졌을 때 빠르게 교체.", "bars": [5, 4, 7, 2, 0, 3]},
	"revolver": {"name": "리볼버", "cls": "권총", "slot": 1, "dmg": [45, 55], "rpm": 120, "auto": false,
		"mag": 6, "reload": 2.2, "spread": [0.8, 6.0], "bloom": 2.0, "kick": 1.8, "speed": 1.0,
		"desc": "6발뿐이지만 한 발이 강함. 머리 맞으면 치명.", "bars": [9, 2, 8, 7, 0, 1]},
	"knife": {"name": "대검", "cls": "근접", "slot": 2, "melee": true, "dmg": [50, 50], "back": 100,
		"interval": 0.6, "range": 1.8, "speed": 1.10, "mag": 0,
		"desc": "탄약 없음. 앞에서 찌르면 50, 뒤에서 찌르면 한 방.", "bars": [5, 6, 0, 0, 0, 0]},
	# zombie-mode weapons (shop)
	"dbarrel": {"name": "더블 배럴", "cls": "산탄총", "slot": 0, "zombie": true, "dmg": [14, 14], "pellets": 10, "rpm": 260, "auto": false,
		"mag": 2, "reload": 2.2, "spread": [5.0, 7.5], "bloom": 1.0, "kick": 4.5, "speed": 0.95, "knock": 1.1, "big_flash": true,
		"desc": "2발. 근거리 산탄이 좀비를 뒤로 날려버림.", "bars": [10, 4, 2, 9, 5, 1]},
	# a heavy two-handed swing, hits land at `hit_at` s into the swing
	"axe": {"name": "소방 도끼", "cls": "근접", "slot": 2, "melee": true, "zombie": true, "dmg": [90, 90], "back": 90,
		"interval": 0.8, "range": 2.6, "arc": 50.0, "hits": 2, "hit_at": 0.25, "knock": 4.5, "speed": 1.0, "mag": 0,
		"desc": "넓게 휘둘러 앞의 2마리까지. 사거리 2.6m.", "bars": [9, 3, 0, 0, 0, 0]},
}
const BAR_KEYS := ["데미지", "연사", "정확도", "반동", "무게", "탄창"]
const SWAP_TIME := 0.5

static func get_w(id: String) -> Dictionary:
	return W.get(id, W["m4"])

static func interval(id: String) -> float:
	var w := get_w(id)
	if w.get("melee", false):
		return float(w["interval"])
	return 60.0 / float(w["rpm"])

static func is_melee(id: String) -> bool:
	return bool(get_w(id).get("melee", false))

static func ids_for_slot(slot: int) -> Array:
	return [ORDER_PRIMARY, ORDER_SECONDARY, ORDER_MELEE][slot]

# knife hit: 'back' damage when the attacker stands behind the victim
static func knife_damage(attacker: Node3D, victim: Node3D) -> int:
	var w := get_w("knife")
	var vf := -victim.global_transform.basis.z
	var to_att := attacker.global_position - victim.global_position
	to_att.y = 0.0
	if to_att.length() > 0.01 and vf.dot(to_att.normalized()) < -0.35:
		return int(w["back"])
	return int(w["dmg"][0])
