class_name UpgradeShop
extends Control
## M4 in-run upgrade shop. Visible during prep; spend points on escalating
## upgrades (PVENET2 model). Buttons are GUI (TouchInput is suppressed while
## the shop is open via Controls.shop_open), so taps are clean.

const UPG := [
	{"id": "atk", "name": "공격력 ↑", "effect": "데미지 +10%/레벨", "base": 60, "mul": 1.5, "max": 10},
	{"id": "spd", "name": "이동속도 ↑", "effect": "이동 +5%/레벨", "base": 50, "mul": 1.5, "max": 6},
	{"id": "hp", "name": "최대체력 ↑", "effect": "HP +25/레벨", "base": 70, "mul": 1.5, "max": 8},
	{"id": "wp", "name": "무기레벨 ↑", "effect": "탄창+2·재장전-5%", "base": 80, "mul": 1.6, "max": 5},
	{"id": "heal", "name": "긴급 치료", "effect": "HP 즉시 +50%", "base": 100, "mul": 1.0, "max": -1},
]

var _rows: Array = []   # [{btn, upg}]
var _title: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := ColorRect.new()
	panel.color = Color(0.05, 0.07, 0.09, 0.92)
	panel.anchor_left = 0.5; panel.anchor_right = 0.5; panel.anchor_top = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -300; panel.offset_right = 300; panel.offset_top = -260; panel.offset_bottom = 260
	add_child(panel)

	var vb := VBoxContainer.new()
	vb.anchor_left = 0.5; vb.anchor_right = 0.5; vb.anchor_top = 0.5; vb.anchor_bottom = 0.5
	vb.offset_left = -290; vb.offset_right = 290; vb.offset_top = -250; vb.offset_bottom = 250
	vb.add_theme_constant_override("separation", 10)
	add_child(vb)

	_title = Label.new()
	_title.text = "강화 상점"
	_title.add_theme_font_size_override("font_size", 34)
	_title.add_theme_color_override("font_color", Color(1.0, 0.72, 0.38))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_title)

	for upg in UPG:
		var b := Button.new()
		b.add_theme_font_size_override("font_size", 26)
		b.custom_minimum_size = Vector2(0, 74)
		b.pressed.connect(_buy.bind(upg))
		vb.add_child(b)
		_rows.append({"btn": b, "upg": upg})

	visible = false

func _lv(id: String) -> int:
	match id:
		"atk": return Controls.atk_lv
		"spd": return Controls.spd_lv
		"hp": return Controls.hp_lv
		"wp": return Controls.wp_lv
	return 0

func _cost(upg: Dictionary) -> int:
	if upg["id"] == "heal":
		return int(upg["base"])
	return int(float(upg["base"]) * pow(float(upg["mul"]), _lv(upg["id"])))

func _maxed(upg: Dictionary) -> bool:
	var mx := int(upg["max"])
	return mx >= 0 and _lv(upg["id"]) >= mx

func _buy(upg: Dictionary) -> void:
	if _maxed(upg):
		return
	var c := _cost(upg)
	if Controls.points < c:
		return
	Controls.points -= c
	match upg["id"]:
		"atk": Controls.atk_lv += 1; Controls.dmg_mult += 0.10
		"spd": Controls.spd_lv += 1; Controls.speed_mult += 0.05
		"hp": Controls.hp_lv += 1; Controls.hp_max += 25; Controls.hp += 25
		"wp": Controls.wp_lv += 1; Controls.ammo_max += 2; Controls.reload_mult *= 0.95
		"heal": Controls.hp = mini(Controls.hp_max, Controls.hp + int(Controls.hp_max * 0.5))

func _process(_dt: float) -> void:
	var show_shop: bool = Controls.prep_left >= 0.0 and not Controls.cleared
	if show_shop != visible:
		visible = show_shop
		Controls.shop_open = show_shop
		if show_shop:
			Controls.move = Vector2.ZERO
			Controls.fire_held = false
	if not visible:
		return
	_title.text = "강화 상점 · ◆ %d · 준비 %d" % [Controls.points, ceili(Controls.prep_left)]
	for r in _rows:
		var upg: Dictionary = r["upg"]
		var b: Button = r["btn"]
		var lv := _lv(upg["id"])
		var lvtxt := ("" if upg["id"] == "heal" else "  Lv %d" % lv)
		if _maxed(upg):
			b.text = "%s%s   —   최대" % [upg["name"], lvtxt]
			b.disabled = true
		else:
			var c := _cost(upg)
			b.text = "%s%s    %s    ◆%d" % [upg["name"], lvtxt, upg["effect"], c]
			b.disabled = Controls.points < c
