class_name PrepLoadout
extends Control
## 폭파미션: weapon change during each round's prep time. Opens by itself when a
## round's prep starts, closes on 확인 / when the round goes live; a chip at the
## top lets you reopen it while prep lasts. Picking a card switches that slot at
## once (full magazine) and saves the loadout for later matches too. While open
## the fight HUD is hidden (Controls.shop_open), like the wave upgrade shop.

const ACCENT := Color(1.0, 0.48, 0.10)
const FG := Color(0.92, 0.95, 0.97)
const MUTED := Color(0.54, 0.60, 0.66)
const LINE := Color(0.17, 0.20, 0.24)

var mode: Node            # BombMode (state / t / PREP / player)
var _panel: PanelContainer
var _chip: Button
var _time_lbl: Label
var _bar: ProgressBar
var _cards := {}          # id -> PanelContainer
var _open := false
var _last_state := ""

func setup(m: Node) -> PrepLoadout:
	mode = m
	return self

func _sb(bg: Color, bd: Color, bw: int, r := 10, m := 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color = bg; s.border_color = bd; s.set_border_width_all(bw); s.set_corner_radius_all(r)
	s.set_content_margin_all(m); return s

func _lbl(t: String, fs: int, c: Color) -> Label:
	var l := Label.new(); l.text = t; l.add_theme_font_size_override("font_size", fs); l.add_theme_color_override("font_color", c)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _sb(Color(0.06, 0.08, 0.10, 0.94), Color(0.18, 0.22, 0.26), 1, 16, 10))
	_panel.anchor_left = 0.5; _panel.anchor_right = 0.5; _panel.anchor_top = 1.0; _panel.anchor_bottom = 1.0
	_panel.offset_left = -545; _panel.offset_right = 545; _panel.offset_top = -350; _panel.offset_bottom = -18
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 10); _panel.add_child(v)
	var head := HBoxContainer.new(); head.add_theme_constant_override("separation", 12)
	var tt := _lbl("장비 교체", 28, FG); tt.size_flags_horizontal = Control.SIZE_EXPAND_FILL; head.add_child(tt)
	_time_lbl = _lbl("", 20, Color(1.0, 0.72, 0.38)); _time_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; head.add_child(_time_lbl)
	var ok := Button.new(); ok.text = "  확인  "; ok.focus_mode = Control.FOCUS_NONE
	ok.add_theme_font_size_override("font_size", 20)
	for k in ["normal", "hover", "pressed"]: ok.add_theme_stylebox_override(k, _sb(ACCENT, ACCENT, 0))
	for k in ["font_color", "font_hover_color", "font_pressed_color"]: ok.add_theme_color_override(k, Color(0.08, 0.05, 0.02))
	ok.pressed.connect(func() -> void: Sfx.play("ui"); _set_open(false))
	head.add_child(ok)
	v.add_child(head)
	_bar = ProgressBar.new(); _bar.show_percentage = false; _bar.custom_minimum_size = Vector2(0, 8)
	_bar.add_theme_stylebox_override("background", _sb(Color(0.04, 0.06, 0.08), LINE, 1, 4, 0))
	_bar.add_theme_stylebox_override("fill", _sb(ACCENT, ACCENT, 0, 4, 0))
	v.add_child(_bar)
	for rowset in [[["주무기", 0]], [["보조", 1], ["근접", 2]]]:
		var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 8)
		for row in rowset:
			var l := _lbl(row[0], 18, MUTED); l.custom_minimum_size = Vector2(70, 0)
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			h.add_child(l)
			for id in Weapons.ids_for_slot(int(row[1])): h.add_child(_card(id, int(row[1])))
		v.add_child(h)
	v.add_child(_lbl("고른 무기는 바로 적용 · 탄창은 가득 찬 상태 · 출격 장비에도 저장", 14, MUTED))
	_chip = Button.new(); _chip.focus_mode = Control.FOCUS_NONE
	_chip.add_theme_font_size_override("font_size", 22)
	for k in ["normal", "hover", "pressed"]: _chip.add_theme_stylebox_override(k, _sb(Color(0.118, 0.086, 0.051, 0.92), ACCENT, 2, 22))
	_chip.add_theme_color_override("font_color", FG)
	_chip.anchor_left = 0.5; _chip.anchor_right = 0.5
	_chip.offset_left = -120; _chip.offset_right = 120; _chip.offset_top = 150; _chip.offset_bottom = 200
	_chip.pressed.connect(func() -> void: Sfx.play("ui"); _set_open(true))
	add_child(_chip)
	_panel.visible = false; _chip.visible = false

func _card(id: String, slot: int) -> Control:
	var w: Dictionary = Weapons.get_w(id)
	var b := Button.new(); b.focus_mode = Control.FOCUS_NONE; b.custom_minimum_size = Vector2(150, 92)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 2); v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.position = Vector2(10, 6); b.add_child(v)
	v.add_child(_lbl(w["name"], 18, FG))
	v.add_child(_lbl(w["cls"] + (" · %d발" % int(w["mag"]) if int(w.get("mag", 0)) > 0 else ""), 12, MUTED))
	var bars: Array = w.get("bars", [5, 5])
	for k in 2:
		var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 4); row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(_lbl(["위력", "연사"][k], 11, MUTED))
		var bg := ColorRect.new(); bg.color = Color(0.15, 0.18, 0.21); bg.custom_minimum_size = Vector2(90, 5)
		bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER; bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var fg := ColorRect.new(); fg.name = "fill"; fg.size = Vector2(9.0 * float(bars[k]), 5); fg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.add_child(fg); row.add_child(bg); v.add_child(row)
	b.pressed.connect(_pick.bind(id, slot))
	_cards[id] = b
	return b

func _pick(id: String, slot: int) -> void:
	Sfx.play("ui")
	Controls.loadout[slot] = id
	Controls.save_settings()
	var p = mode.player
	if p:
		p._ammo[id] = p._mag_of(id)
		if Controls.slot == slot: p._equip(slot, true)
		else: p._sync_hud()
	_restyle()

func _restyle() -> void:
	for id in _cards:
		var on: bool = id in Controls.loadout
		var b: Button = _cards[id]
		for k in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(k, _sb(Color(0.118, 0.086, 0.051) if on else Color(0.07, 0.09, 0.11), ACCENT if on else LINE, 2 if on else 1))
		for f in b.find_children("fill", "ColorRect", true, false):
			(f as ColorRect).color = ACCENT if on else Color(0.7, 0.75, 0.8)

func _set_open(on: bool) -> void:
	_open = on
	_panel.visible = on
	Controls.shop_open = on
	if on:
		Controls.move = Vector2.ZERO; Controls.fire_held = false
		_restyle()

func _process(_dt: float) -> void:
	if mode == null: return
	var st: String = mode.state
	var prep: bool = st == "prep" and mode.player != null and mode.player.alive
	if st != _last_state:
		_last_state = st
		if st == "prep": _set_open(true)          # every round's prep opens it once
	if not prep and _open: _set_open(false)
	_chip.visible = prep and not _open
	if prep:
		var left := maxf(0.0, float(mode.t))
		_bar.max_value = float(mode.PREP); _bar.value = left
		_time_lbl.text = "라운드 시작까지 %d초" % ceili(left)
		_chip.text = "장비 교체  %d초" % ceili(left)

func _exit_tree() -> void:
	Controls.shop_open = false
