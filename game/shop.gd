class_name UpgradeShop
extends Control
## In-run upgrade shop shown during the prep phase between waves. Card layout:
## header (title + points pill), prep timer bar, and one card per upgrade with
## an icon, level pips, effect text and a buy button (dimmed when unaffordable,
## "최대" when maxed). Two columns of cards. While open (Controls.shop_open) the
## fight HUD (buttons, weapon chips, crosshair, radar) is hidden and touches are ignored.

const UPG := [
	{"id": "atk", "name": "공격력", "effect": "데미지 +10% / 레벨", "base": 60, "mul": 1.5, "max": 10},
	{"id": "spd", "name": "이동속도", "effect": "이동 +5% / 레벨", "base": 50, "mul": 1.5, "max": 6},
	{"id": "hp", "name": "최대체력", "effect": "HP +25 / 레벨", "base": 70, "mul": 1.5, "max": 8},
	{"id": "wp", "name": "무기레벨", "effect": "탄창 +2 · 재장전 -5%", "base": 80, "mul": 1.6, "max": 5},
	{"id": "nade", "name": "수류탄", "effect": "수류탄 +1 (최대 5개)", "base": 40, "mul": 1.0, "max": -1},
	{"id": "heal", "name": "긴급 치료", "effect": "HP 즉시 +50%", "base": 100, "mul": 1.0, "max": -1},
]
const NADE_CAP := 5
const PANEL_W := 1120.0      # two columns of cards; shrinks to the screen
const COLS := 2
const PREP_MAX := 9.0

const C_ACCENT := Color(1.0, 0.48, 0.10)
const C_OK := Color(0.21, 0.83, 0.61)
const C_PANEL := Color(0.08, 0.11, 0.14, 0.97)
const C_CARD := Color(0.11, 0.14, 0.17)
const C_LINE := Color(0.18, 0.22, 0.26)
const C_FG := Color(0.92, 0.95, 0.97)
const C_DIM := Color(0.50, 0.57, 0.63)

var _panel: PanelContainer
var _pts: Label
var _hp: Label
var _timer_bar: ProgressBar
var _timer_lbl: Label
var _rows: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _sb(C_PANEL, C_LINE, 1, 18, 18))
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 7)
	_panel.add_child(v)

	# header: title + points pill
	var head := HBoxContainer.new()
	var t := Label.new(); t.text = "강화 상점"
	t.add_theme_font_size_override("font_size", 34)
	t.add_theme_color_override("font_color", C_FG)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", _sb(Color(0.05, 0.07, 0.09), C_LINE, 1, 22, 10))
	_pts = Label.new(); _pts.add_theme_font_size_override("font_size", 26)
	_pts.add_theme_color_override("font_color", Color(1.0, 0.8, 0.35))
	pill.add_child(_pts)
	# HP lives here while the shop is open (the radar + HP bar are hidden then)
	var hpp := PanelContainer.new()
	hpp.add_theme_stylebox_override("panel", _sb(Color(0.05, 0.07, 0.09), C_LINE, 1, 22, 10))
	_hp = Label.new(); _hp.add_theme_font_size_override("font_size", 22)
	_hp.add_theme_color_override("font_color", Color(1.0, 0.55, 0.5))
	hpp.add_child(_hp)
	head.add_child(hpp)
	var gap := Control.new(); gap.custom_minimum_size = Vector2(8, 0); head.add_child(gap)
	head.add_child(pill)
	v.add_child(head)

	# prep timer
	var tr := HBoxContainer.new(); tr.add_theme_constant_override("separation", 12)
	var tl := Label.new(); tl.text = "다음 웨이브까지"
	tl.add_theme_font_size_override("font_size", 20); tl.add_theme_color_override("font_color", C_DIM)
	tr.add_child(tl)
	_timer_bar = ProgressBar.new()
	_timer_bar.min_value = 0.0; _timer_bar.max_value = PREP_MAX; _timer_bar.show_percentage = false
	_timer_bar.custom_minimum_size = Vector2(0, 10)
	_timer_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_timer_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_timer_bar.add_theme_stylebox_override("background", _sb(Color(0.04, 0.06, 0.08), C_LINE, 1, 5, 0))
	_timer_bar.add_theme_stylebox_override("fill", _sb(C_ACCENT, C_ACCENT, 0, 5, 0))
	tr.add_child(_timer_bar)
	_timer_lbl = Label.new(); _timer_lbl.add_theme_font_size_override("font_size", 22)
	_timer_lbl.add_theme_color_override("font_color", C_FG)
	tr.add_child(_timer_lbl)
	v.add_child(tr)

	var grid := GridContainer.new(); grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	for upg in UPG:
		var cd := _card(upg)
		cd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(cd)

	visible = false
	_relayout()
	get_viewport().size_changed.connect(_relayout)

func _card(upg: Dictionary) -> Control:
	var heal: bool = upg["id"] == "heal"
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _sb(C_CARD, C_LINE, 1, 12, 6))
	var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 14)
	card.add_child(h)

	var ib := PanelContainer.new()
	ib.add_theme_stylebox_override("panel", _sb(Color(0.05, 0.07, 0.09), C_LINE, 1, 9, 0))
	ib.custom_minimum_size = Vector2(44, 44)
	var icon := ModeIcon.new(); icon.kind = upg["id"]
	icon.col = C_OK if heal else C_ACCENT
	icon.custom_minimum_size = Vector2(44, 44)
	ib.add_child(icon)
	h.add_child(ib)

	var mid := VBoxContainer.new(); mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 2)
	var top := HBoxContainer.new(); top.add_theme_constant_override("separation", 10)
	var nm := Label.new(); nm.text = upg["name"]
	nm.add_theme_font_size_override("font_size", 22); nm.add_theme_color_override("font_color", C_FG)
	top.add_child(nm)
	var pips: Array = []
	if not heal:
		var ph := HBoxContainer.new(); ph.add_theme_constant_override("separation", 3)
		ph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		for i in int(upg["max"]):
			var pip := ColorRect.new(); pip.custom_minimum_size = Vector2(14, 6)
			pip.color = C_LINE
			ph.add_child(pip); pips.append(pip)
		top.add_child(ph)
	mid.add_child(top)
	var ef := Label.new(); ef.text = upg["effect"]
	ef.add_theme_font_size_override("font_size", 16); ef.add_theme_color_override("font_color", C_DIM)
	mid.add_child(ef)
	h.add_child(mid)

	var b := Button.new(); b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(128, 50)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 24)
	var bc := C_OK if heal else C_ACCENT
	b.add_theme_stylebox_override("normal", _sb(bc, bc, 0, 10, 8))
	b.add_theme_stylebox_override("hover", _sb(bc.lightened(0.1), bc, 0, 10, 8))
	b.add_theme_stylebox_override("pressed", _sb(bc.darkened(0.15), bc, 0, 10, 8))
	b.add_theme_stylebox_override("disabled", _sb(Color(0.14, 0.17, 0.20), C_LINE, 1, 10, 8))
	b.add_theme_color_override("font_color", Color(0.08, 0.05, 0.02))
	b.add_theme_color_override("font_hover_color", Color(0.08, 0.05, 0.02))
	b.add_theme_color_override("font_pressed_color", Color(0.08, 0.05, 0.02))
	b.add_theme_color_override("font_disabled_color", C_DIM)
	b.pressed.connect(_buy.bind(upg))
	h.add_child(b)
	_rows.append({"btn": b, "upg": upg, "pips": pips, "name": nm})
	return card

func _sb(bg: Color, border: Color, bw: int, rad: int, margin: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border; s.set_border_width_all(bw)
	s.set_corner_radius_all(rad); s.set_content_margin_all(margin)
	return s

func _relayout() -> void:
	var vp := get_viewport().get_visible_rect().size
	# below the wave label; the fight HUD is hidden while the shop is open
	var top := 84.0
	var w := minf(PANEL_W, vp.x - 64.0)
	_panel.position = Vector2((vp.x - w) * 0.5, top)
	_panel.size = Vector2(w, 0)   # height follows the content (header + 3 rows of cards)

func _lv(id: String) -> int:
	match id:
		"atk": return Controls.atk_lv
		"spd": return Controls.spd_lv
		"hp": return Controls.hp_lv
		"wp": return Controls.wp_lv
	return 0

func _cost(upg: Dictionary) -> int:
	if upg["id"] == "heal" or upg["id"] == "nade":
		return int(upg["base"])
	return int(float(upg["base"]) * pow(float(upg["mul"]), _lv(upg["id"])))

func _maxed(upg: Dictionary) -> bool:
	if upg["id"] == "nade":
		return Controls.grenades >= NADE_CAP
	var mx := int(upg["max"])
	return mx >= 0 and _lv(upg["id"]) >= mx

func _buy(upg: Dictionary) -> void:
	if _maxed(upg):
		return
	var c := _cost(upg)
	if Controls.points < c:
		return
	Controls.points -= c
	Sfx.play("ui")
	match upg["id"]:
		"atk": Controls.atk_lv += 1; Controls.dmg_mult += 0.10
		"spd": Controls.spd_lv += 1; Controls.speed_mult += 0.05
		"hp": Controls.hp_lv += 1; Controls.hp_max += 25; Controls.hp += 25
		"wp": Controls.wp_lv += 1; Controls.mag_bonus += 2; Controls.ammo_max += 2; Controls.reload_mult *= 0.95
		"nade": Controls.grenades += 1
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
	_pts.text = "◆ %d" % Controls.points
	_hp.text = "HP %d / %d" % [Controls.hp, Controls.hp_max]
	_timer_bar.value = clampf(Controls.prep_left, 0.0, PREP_MAX)
	_timer_lbl.text = "%d초" % ceili(Controls.prep_left)
	for r in _rows:
		var upg: Dictionary = r["upg"]
		var b: Button = r["btn"]
		var lv := _lv(upg["id"])
		var pips: Array = r["pips"]
		for i in pips.size():
			(pips[i] as ColorRect).color = C_OK if i < lv else C_LINE
		if upg["id"] == "nade":
			r["name"].text = "수류탄  ×%d" % Controls.grenades
		if _maxed(upg):
			b.text = "최대"
			b.disabled = true
		else:
			var c := _cost(upg)
			b.text = "◆ %d" % c
			b.disabled = Controls.points < c
