class_name UpgradeShop
extends Control
## M4 in-run upgrade shop. Visible during prep; spend points on escalating
## upgrades (PVENET2 model). Buttons are GUI (TouchInput is suppressed while the
## shop is open via Controls.shop_open). Laid out from the viewport size so it
## stays centered regardless of device resolution.

const UPG := [
	{"id": "atk", "name": "공격력 ↑", "effect": "데미지 +10%/레벨", "base": 60, "mul": 1.5, "max": 10},
	{"id": "spd", "name": "이동속도 ↑", "effect": "이동 +5%/레벨", "base": 50, "mul": 1.5, "max": 6},
	{"id": "hp", "name": "최대체력 ↑", "effect": "HP +25/레벨", "base": 70, "mul": 1.5, "max": 8},
	{"id": "wp", "name": "무기레벨 ↑", "effect": "탄창+2·재장전-5%", "base": 80, "mul": 1.6, "max": 5},
	{"id": "heal", "name": "긴급 치료", "effect": "HP 즉시 +50%", "base": 100, "mul": 1.0, "max": -1},
]
const PANEL_W := 640.0
const PANEL_H := 560.0

var _panel: ColorRect
var _vb: VBoxContainer
var _title: Label
var _rows: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = ColorRect.new()
	_panel.color = Color(0.05, 0.07, 0.09, 0.95)
	add_child(_panel)

	_vb = VBoxContainer.new()
	_vb.add_theme_constant_override("separation", 10)
	add_child(_vb)

	_title = Label.new()
	_title.text = "강화 상점"
	_title.add_theme_font_size_override("font_size", 34)
	_title.add_theme_color_override("font_color", Color(1.0, 0.72, 0.38))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vb.add_child(_title)

	for upg in UPG:
		var b := Button.new()
		b.add_theme_font_size_override("font_size", 25)
		b.custom_minimum_size = Vector2(0, 74)
		b.pressed.connect(_buy.bind(upg))
		_vb.add_child(b)
		_rows.append({"btn": b, "upg": upg})

	visible = false
	_relayout()
	get_viewport().size_changed.connect(_relayout)

func _relayout() -> void:
	var vp := get_viewport().get_visible_rect().size
	var x := (vp.x - PANEL_W) * 0.5
	var y := (vp.y - PANEL_H) * 0.5
	_panel.position = Vector2(x, y)
	_panel.size = Vector2(PANEL_W, PANEL_H)
	_vb.position = Vector2(x + 22, y + 20)
	_vb.size = Vector2(PANEL_W - 44, PANEL_H - 40)

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
