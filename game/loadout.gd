class_name LoadoutScreen
extends Control
## Menu '장비' tab (시안 v2): soldier preview holding the picked weapon + the four
## slots on the left; slot tabs, weapon cards and a comparison against the equipped
## weapon on the right. 장착 saves the loadout (Controls.loadout, persisted).

const ACCENT := Color(1.0, 0.48, 0.10)
const PANEL := Color(0.10, 0.13, 0.16)
const LINE := Color(0.17, 0.20, 0.24)
const FG := Color(0.92, 0.95, 0.97)
const MUTED := Color(0.55, 0.62, 0.69)
const DIM := Color(0.38, 0.44, 0.50)
const OK := Color(0.21, 0.83, 0.61)
const BAD := Color(0.94, 0.36, 0.32)

var _tab := 0
var _pick := ""
var _soldier: Soldier
var _cards: GridContainer
var _tabs: Array[Button] = []
var _name_lbl: Label
var _cls_lbl: Label
var _desc_lbl: Label
var _slots_box: HBoxContainer
var _cmp: GridContainer
var _equip_btn: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new(); bg.color = Color(0.05, 0.06, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	_build_left()
	_build_right()
	_pick = Controls.loadout[_tab]
	_refresh()

# ---- left: preview + slots ----
func _build_left() -> void:
	var back := Button.new(); back.text = "‹ 장비"; back.flat = true; back.focus_mode = Control.FOCUS_NONE
	back.add_theme_font_size_override("font_size", 28)
	back.add_theme_color_override("font_color", FG)
	back.position = Vector2(28, 18)
	back.pressed.connect(func() -> void: Sfx.play("ui"); queue_free())
	add_child(back)

	var box := Panel.new()
	box.position = Vector2(28, 80); box.size = Vector2(470, 560)
	box.add_theme_stylebox_override("panel", _sb(PANEL, LINE, 1, 14))
	add_child(box)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.position = Vector2(10, 10); svc.size = Vector2(450, 380)
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(svc)
	var vp := SubViewport.new()
	vp.own_world_3d = true; vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(vp)
	var cam := Camera3D.new(); cam.fov = 36.0
	vp.add_child(cam)
	# whole figure incl. helmet / hood / antenna, a little room above (same framing as the shop)
	cam.position = Vector3(-1.75, 1.3, -3.2); cam.look_at_from_position(cam.position, Vector3(0.05, 0.98, -0.15))
	var l := DirectionalLight3D.new(); l.rotation_degrees = Vector3(-40, -150, 0); vp.add_child(l)
	var l2 := DirectionalLight3D.new(); l2.rotation_degrees = Vector3(-30, 30, 0); l2.light_energy = 0.6; vp.add_child(l2)
	var we := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.8, 0.82, 0.86)
	we.environment = e; vp.add_child(we)
	_soldier = Soldier.new(); vp.add_child(_soldier)
	_soldier.cosmetic = true
	_soldier.body = Profile.equipped("body").substr(5); _soldier.gear = Profile.equipped("gear").substr(5); _soldier.skin = Profile.skin_mats(Profile.equipped("skin"))
	_soldier.wfx = Profile.equipped("wfx"); _soldier.cfx = Profile.equipped("cfx"); _soldier.fx_preview = true
	_soldier.setup(Profile.suit_color(), Profile.kit_color())
	_soldier.drive(0.0, true)

	_name_lbl = _label("", 34, FG); _name_lbl.position = Vector2(24, 392); box.add_child(_name_lbl)
	_cls_lbl = _label("", 20, MUTED); _cls_lbl.position = Vector2(26, 436); box.add_child(_cls_lbl)
	_slots_box = HBoxContainer.new()
	_slots_box.position = Vector2(20, 480); _slots_box.size = Vector2(430, 60)
	_slots_box.add_theme_constant_override("separation", 6)
	box.add_child(_slots_box)

# ---- right: tabs, cards, comparison, equip ----
func _build_right() -> void:
	var x0 := 520.0
	var tabs := HBoxContainer.new()
	tabs.position = Vector2(x0, 80)
	tabs.add_theme_constant_override("separation", 8)
	add_child(tabs)
	for i in 3:
		var b := Button.new(); b.text = ["주무기", "보조무기", "근접무기"][i]
		b.focus_mode = Control.FOCUS_NONE; b.custom_minimum_size = Vector2(150, 50)
		b.add_theme_font_size_override("font_size", 22)
		var idx := i
		b.pressed.connect(func() -> void:
			Sfx.play("ui"); _tab = idx; _pick = Controls.loadout[idx]; _refresh())
		tabs.add_child(b); _tabs.append(b)

	_cards = GridContainer.new(); _cards.columns = 3
	_cards.position = Vector2(x0, 144)
	_cards.add_theme_constant_override("h_separation", 10)
	_cards.add_theme_constant_override("v_separation", 10)
	add_child(_cards)

	_desc_lbl = _label("", 19, MUTED)
	_desc_lbl.position = Vector2(x0, 330); _desc_lbl.size = Vector2(700, 30)
	add_child(_desc_lbl)
	_cmp = GridContainer.new(); _cmp.columns = 4
	_cmp.position = Vector2(x0, 366)
	_cmp.add_theme_constant_override("h_separation", 12)
	_cmp.add_theme_constant_override("v_separation", 6)
	add_child(_cmp)

	_equip_btn = Button.new(); _equip_btn.focus_mode = Control.FOCUS_NONE
	_equip_btn.custom_minimum_size = Vector2(230, 60)
	_equip_btn.position = Vector2(x0, 580)
	_equip_btn.add_theme_font_size_override("font_size", 26)
	_equip_btn.pressed.connect(func() -> void:
		Sfx.play("ui"); Controls.set_loadout(_tab, _pick); _refresh())
	add_child(_equip_btn)

func _refresh() -> void:
	var w := Weapons.get_w(_pick)
	_soldier.set_weapon(_pick)
	_name_lbl.text = w["name"]
	_cls_lbl.text = w["cls"]
	for i in 3:
		_tabs[i].add_theme_stylebox_override("normal", _sb(Color(0.16, 0.11, 0.05) if i == _tab else PANEL, ACCENT if i == _tab else LINE, 2 if i == _tab else 1, 10))
		_tabs[i].add_theme_stylebox_override("hover", _tabs[i].get_theme_stylebox("normal"))
		_tabs[i].add_theme_stylebox_override("pressed", _tabs[i].get_theme_stylebox("normal"))
		_tabs[i].add_theme_color_override("font_color", FG if i == _tab else MUTED)
	# slots
	for c in _slots_box.get_children(): c.queue_free()
	var slot_txt := ["주무기", "보조", "근접", "투척"]
	for i in 4:
		var nm: String = "수류탄 ×%d" % Controls.NADE_MAX if i == 3 else str(Weapons.get_w(Controls.loadout[i])["name"])
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", _sb(Color(0.08, 0.10, 0.12), ACCENT if i == _tab else LINE, 1, 8))
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 0)
		var a := _label(slot_txt[i], 14, DIM); a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var b := _label(nm, 16, FG); b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.clip_text = true
		v.add_child(a); v.add_child(b); p.add_child(v)
		_slots_box.add_child(p)
	# cards
	for c in _cards.get_children(): c.queue_free()
	var ids: Array = Weapons.ids_for_slot(_tab, Controls.zmode)
	_cards.columns = 3 if ids.size() <= 6 else 4          # zombie weapons added: one more column, same two rows
	for id in ids:
		var cw := Weapons.get_w(id)
		var b := Button.new(); b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(226, 82) if _cards.columns == 3 else Vector2(168, 82)
		var sel: bool = id == _pick
		var eq: bool = id == Controls.loadout[_tab]
		var st := _sb(Color(0.16, 0.11, 0.05) if sel else PANEL, ACCENT if sel else LINE, 2 if sel else 1, 10)
		for k in ["normal", "hover", "pressed"]: b.add_theme_stylebox_override(k, st)
		b.text = "%s\n%s" % [cw["name"], ("장착 중" if eq else (("좀비 전용 · " if Weapons.is_zombie(id) else "") + String(cw["cls"])))]
		b.add_theme_font_size_override("font_size", 22 if _cards.columns == 3 else 18)
		b.add_theme_color_override("font_color", FG)
		b.add_theme_color_override("font_hover_color", FG)
		var wid: String = id
		b.pressed.connect(func() -> void: Sfx.play("ui"); _pick = wid; _refresh())
		_cards.add_child(b)
	# comparison vs equipped
	_desc_lbl.text = w["desc"]
	for c in _cmp.get_children(): c.queue_free()
	var cur := Weapons.get_w(Controls.loadout[_tab])
	for r in _rows(w, cur):
		_cmp.add_child(_label(r[0], 19, MUTED))
		var bar := Control.new(); bar.custom_minimum_size = Vector2(260, 22)
		var track := ColorRect.new(); track.color = Color(0.13, 0.16, 0.19); track.size = Vector2(260, 10); track.position = Vector2(0, 7)
		var fill := ColorRect.new(); fill.color = BAD if r[4] else ACCENT
		fill.size = Vector2(26.0 * float(r[1]), 10); fill.position = Vector2(0, 7)
		bar.add_child(track); bar.add_child(fill)
		_cmp.add_child(bar)
		_cmp.add_child(_label(r[2], 19, FG))
		_cmp.add_child(_label(r[3][0], 19, r[3][1]))
	var eq_now: bool = _pick == Controls.loadout[_tab]
	_equip_btn.text = "장착 중" if eq_now else "장착"
	_equip_btn.disabled = eq_now
	var est := _sb(ACCENT if not eq_now else Color(0.2, 0.22, 0.25), ACCENT if not eq_now else LINE, 1, 12)
	for k in ["normal", "hover", "pressed", "disabled"]: _equip_btn.add_theme_stylebox_override(k, est)
	_equip_btn.add_theme_color_override("font_color", Color(0.08, 0.05, 0.02))
	_equip_btn.add_theme_color_override("font_disabled_color", MUTED)

# rows: [label, bar 0..10, value text, [delta text, colour], lower-is-better]
func _rows(w: Dictionary, cur: Dictionary) -> Array:
	var same: bool = w["name"] == cur["name"]
	if w.get("melee", false):
		var d0 := int(w["dmg"][0]); var bk := int(w.get("back", d0))
		return [["데미지", int(w["bars"][0]), ("%d (뒤 %d)" % [d0, bk]) if bk != d0 else ("%d · %d마리까지" % [d0, int(w.get("hits", 1))]), ["", FG], false],
			["공격 속도", int(w["bars"][1]), "%.1f초" % float(w["interval"]), ["", FG], false],
			["사거리", int(float(w["range"]) * 1.2), "%.1fm" % float(w["range"]), ["", FG], false], ["무게", 0, "이동 %+d%%" % roundi((float(w["speed"]) - 1.0) * 100.0), ["", FG], true]]
	var out := []
	var dmg_txt := "%d–%d" % [w["dmg"][0], w["dmg"][1]]
	if w.has("pellets"): dmg_txt = "%d×%d발" % [w["dmg"][0], w["pellets"]]
	var vals := [dmg_txt, ("%d/분" % w["rpm"]) if w.get("auto", false) else ("탭 · %d/분" % w["rpm"]),
		("조준경 %.1f°" % w["spread_scoped"]) if w.has("spread_scoped") else ("%.1f°" % w["spread"][0]), "%.1f°" % w["kick"], "%+d%% 속도" % roundi((w["speed"] - 1.0) * 100.0),
		"%d발 · %.1f초" % [w["mag"], w["reload"]]]
	for k in 6:
		var lower: bool = k == 3 or k == 4
		var d: int = int(w["bars"][k]) - int(cur["bars"][k])
		var dt := ["", FG]
		if not same and d != 0:
			var good := (d > 0) != lower
			dt = [("▲ " if d > 0 else "▼ ") + str(absi(d)), OK if good else BAD]
		out.append([Weapons.BAR_KEYS[k], w["bars"][k], vals[k], dt, lower])
	return out

func _label(txt: String, sz: int, col: Color) -> Label:
	var l := Label.new(); l.text = txt
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	return l

func _sb(bg: Color, border: Color, bw: int, rad: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.set_border_width_all(bw); s.border_color = border
	s.set_corner_radius_all(rad)
	s.content_margin_left = 8; s.content_margin_right = 8; s.content_margin_top = 4; s.content_margin_bottom = 4
	return s
