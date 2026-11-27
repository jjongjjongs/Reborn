class_name Difficulty
## Bot difficulty (출격 준비 화면 A안). Bots read the selected level from
## Controls.bot_diff; wave survival uses the same 4 steps as "좀비 강도".
const IDS := ["rook", "reg", "vet", "elite"]
const L := {
	"rook":  {"name": "신병",   "short": "느리고 자주 빗나감",       "color": Color(0.21, 0.83, 0.61),
		"react": 0.50, "spread": 6.0, "dmg": 0.35, "tactics": 0.3, "tactics_txt": "거의 안 씀",
		"hear_shot": 12.0, "hear_step": 0.0, "memory": 3.0, "share": 0.0, "flank": 0.0,
		"z_hp": 0.75, "z_dmg": 0.7, "z_spd": 0.9, "z_short": "약하고 느린 좀비"},
	"reg":   {"name": "정규",   "short": "지금 게임의 봇 수준",       "color": Color(0.34, 0.66, 1.0),
		"react": 0.30, "spread": 4.5, "dmg": 0.45, "tactics": 1.0, "tactics_txt": "가끔",
		"hear_shot": 22.0, "hear_step": 0.0, "memory": 6.0, "share": 0.0, "flank": 0.15,
		"z_hp": 1.0, "z_dmg": 1.0, "z_spd": 1.0, "z_short": "기본 좀비"},
	"vet":   {"name": "베테랑", "short": "빨리 반응하고 엄폐를 씀",   "color": Color(1.0, 0.60, 0.30),
		"react": 0.20, "spread": 3.0, "dmg": 0.55, "tactics": 1.4, "tactics_txt": "자주",
		"hear_shot": 32.0, "hear_step": 8.0, "memory": 10.0, "share": 1.0, "flank": 0.35,
		"z_hp": 1.3, "z_dmg": 1.3, "z_spd": 1.08, "z_short": "단단하고 아픈 좀비"},
	"elite": {"name": "엘리트", "short": "헤드샷을 노림 · 돌진 많음", "color": Color(0.94, 0.35, 0.32),
		"react": 0.12, "spread": 2.0, "dmg": 0.65, "tactics": 1.8, "tactics_txt": "적극적",
		"hear_shot": 42.0, "hear_step": 12.0, "memory": 15.0, "share": 2.0, "flank": 0.55,
		"z_hp": 1.6, "z_dmg": 1.6, "z_spd": 1.15, "z_short": "빠르고 강한 좀비"},
}

static func cur() -> Dictionary:
	return L.get(Controls.bot_diff, L["reg"])

static func v(key: String) -> float:
	return float(cur()[key])
