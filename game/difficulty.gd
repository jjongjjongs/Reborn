class_name Difficulty
## Bot difficulty (출격 준비 화면 A안). Bots read the selected level from
## Controls.bot_diff; wave survival uses the same 4 steps as "좀비 강도".
const IDS := ["rook", "reg", "vet", "elite"]
const L := {
	"rook":  {"name": "신병",   "short": "느리게 반응 · 길게 갈기고 반동 못 잡음",       "color": Color(0.21, 0.83, 0.61),
		"react": 0.62, "spread": 5.5, "dmg": 1.0, "tactics": 0.3,
		"turn": 290.0, "head": 0.0, "burst_lo": 6.0, "burst_hi": 10.0, "burst_far": 6.0, "climb": 0.15, "tactics_txt": "거의 안 씀",
		"hear_shot": 12.0, "hear_step": 0.0, "memory": 3.0, "share": 0.0, "flank": 0.0,
		"cover": 0.0, "hide_hp": 0.0, "hide_ammo": 0.0, "retreat_hp": 0.0,
		"z_hp": 0.75, "z_dmg": 0.7, "z_spd": 0.9, "z_short": "약하고 느린 좀비"},
	"reg":   {"name": "정규",   "short": "엄폐물에서 싸움 · 끊어 쏨",       "color": Color(0.34, 0.66, 1.0),
		"react": 0.42, "spread": 4.0, "dmg": 1.0, "tactics": 1.0,
		"turn": 400.0, "head": 0.0, "burst_lo": 3.0, "burst_hi": 7.0, "burst_far": 4.0, "climb": 0.08, "tactics_txt": "가끔",
		"hear_shot": 22.0, "hear_step": 0.0, "memory": 6.0, "share": 0.0, "flank": 0.15,
		"cover": 1.0, "hide_hp": 0.0, "hide_ammo": 0.0, "retreat_hp": 0.0,
		"z_hp": 1.0, "z_dmg": 1.0, "z_spd": 1.0, "z_short": "기본 좀비"},
	"vet":   {"name": "베테랑", "short": "내밀어 쏘고 숨어서 장전 · 소리를 들음",   "color": Color(1.0, 0.60, 0.30),
		"react": 0.28, "spread": 2.6, "dmg": 1.0, "tactics": 1.4,
		"turn": 540.0, "head": 0.15, "burst_lo": 4.0, "burst_hi": 7.0, "burst_far": 3.0, "climb": 0.04, "tactics_txt": "자주",
		"hear_shot": 32.0, "hear_step": 8.0, "memory": 10.0, "share": 1.0, "flank": 0.35,
		"cover": 2.0, "hide_hp": 60.0, "hide_ammo": 0.5, "retreat_hp": 25.0,
		"z_hp": 1.3, "z_dmg": 1.3, "z_spd": 1.08, "z_short": "단단하고 아픈 좀비"},
	"elite": {"name": "엘리트", "short": "머리를 노림 · 자리를 바꾸고 우회함", "color": Color(0.94, 0.35, 0.32),
		"react": 0.18, "spread": 1.6, "dmg": 1.0, "tactics": 1.8,
		"turn": 740.0, "head": 0.45, "burst_lo": 5.0, "burst_hi": 8.0, "burst_far": 2.0, "climb": 0.02, "tactics_txt": "적극적",
		"hear_shot": 42.0, "hear_step": 12.0, "memory": 15.0, "share": 2.0, "flank": 0.55,
		"cover": 3.0, "hide_hp": 75.0, "hide_ammo": 0.7, "retreat_hp": 25.0,
		"z_hp": 1.6, "z_dmg": 1.6, "z_spd": 1.15, "z_short": "빠르고 강한 좀비"},
}

static func cur() -> Dictionary:
	return L.get(Controls.bot_diff, L["reg"])

static func v(key: String) -> float:
	return float(cur()[key])
