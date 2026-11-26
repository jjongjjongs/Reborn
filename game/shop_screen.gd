class_name ShopScreen
extends Control
## 상점: cosmetics bought with the ◆ coins from daily missions. Categories (left),
## item cards (middle, rarity colour by price), 3D try-on preview of your soldier
## (right) with buy / equip. Cosmetic only — no stat effects.

const ACCENT := Color(1.0, 0.48, 0.10)
const FG := Color(0.92, 0.95, 0.97)
const MUTED := Color(0.55, 0.62, 0.69)
const PANEL := Color(0.063, 0.082, 0.102)
const CARD := Color(0.051, 0.071, 0.086)
const LINE := Color(0.133, 0.165, 0.196)
const OK := Color(0.45, 0.85, 0.6)

var _cat := "suit"
var _sel := ""                 # item shown in the preview
var _cats_box: VBoxContainer
var _grid: GridContainer
var _coins: Label
var _name: Label
var _btn: Button
var _soldier: Soldier
var _vp: SubViewport

static func rarity(price: int) -> Array:   # [name, colour]
	if price <= 120: return ["일반", Color(0.62, 0.66, 0.70)]
	if price <= 150: return ["희귀", Color(0.35, 0.62, 1.0)]
	if price <= 250: return ["영웅", Color(0.70, 0.45, 1.0)]
	return ["전설", Color(1.0, 0.72, 0.25)]

func _sb(bg: Color, bd: Color, bw: int, r := 12, m := 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color = bg; s.border_color = bd; s.set_border_width_all(bw); s.set_corner_radius_all(r)
	s.set_content_margin_all(m); return s

func _lbl(t: String, fs: int, c: Color) -> Label:
	var l := Label.new(); l.text = t; l.add_theme_font_size_override("font_size", fs); l.add_theme_color_override("font_color", c)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE; return l

func _panel(pos: Vector2, sz: Vector2) -> PanelContainer:
	var p := PanelContainer.new(); p.position = pos; p.size = sz
	p.add_theme_stylebox_override("panel", _sb(PANEL, LINE, 1, 14, 14)); add_child(p); return p

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new(); bg.color = Color(0.043, 0.055, 0.071); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var back := Button.new(); back.text = "‹ 메뉴"; back.focus_mode = Control.FOCUS_NONE
	back.add_theme_font_size_override("font_size", 20); back.position = Vector2(28, 18); back.size = Vector2(110, 48)
	for k in ["normal", "hover", "pressed"]: back.add_theme_stylebox_override(k, _sb(Color(0, 0, 0, 0), LINE, 1))
	back.pressed.connect(func() -> void: Sfx.play("ui"); _close())
	add_child(back)
	var t := _lbl("상점", 28, FG); t.position = Vector2(156, 14); add_child(t)
	var s := _lbl("오늘의 임무로 모은 ◆ 코인으로 외형을 꾸밉니다 · 능력치에는 영향 없음", 15, MUTED); s.position = Vector2(158, 60); add_child(s)
	var pill := PanelContainer.new(); pill.add_theme_stylebox_override("panel", _sb(Color(0.08, 0.10, 0.12), LINE, 1, 22, 10))
	_coins = _lbl("", 22, Color(1.0, 0.8, 0.35)); pill.add_child(_coins)
	pill.anchor_left = 1.0; pill.anchor_right = 1.0; pill.offset_left = -170; pill.offset_right = -28; pill.offset_top = 20
	add_child(pill)

	var vs := get_viewport_rect().size
	var right_w := 412.0
	var mid_w := vs.x - 28 - 220 - 16 - 16 - right_w - 28
	var h := vs.y - 96 - 20
	var cp := _panel(Vector2(28, 96), Vector2(220, h))
	_cats_box = VBoxContainer.new(); _cats_box.add_theme_constant_override("separation", 8); cp.add_child(_cats_box)
	var gp := _panel(Vector2(264, 96), Vector2(mid_w, h))
	var sc := ScrollContainer.new(); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; gp.add_child(sc)
	_grid = GridContainer.new(); _grid.columns = maxi(2, int((mid_w - 28) / 206.0))
	_grid.add_theme_constant_override("h_separation", 10); _grid.add_theme_constant_override("v_separation", 10)
	sc.add_child(_grid)
	var rx := 264 + mid_w + 16
	_panel(Vector2(rx, 96), Vector2(right_w, h))
	var svc := SubViewportContainer.new(); svc.stretch = true; svc.position = Vector2(rx + 20, 110); svc.size = Vector2(right_w - 40, h - 160)
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(svc)
	_vp = SubViewport.new(); _vp.own_world_3d = true; _vp.transparent_bg = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS; svc.add_child(_vp)
	var cam := Camera3D.new(); cam.fov = 34.0; _vp.add_child(cam)
	cam.position = Vector3(-1.5, 1.25, -2.6); cam.look_at_from_position(cam.position, Vector3(0.0, 0.95, -0.1))
	var l := DirectionalLight3D.new(); l.rotation_degrees = Vector3(-40, -150, 0); _vp.add_child(l)
	var l2 := DirectionalLight3D.new(); l2.rotation_degrees = Vector3(-30, 30, 0); l2.light_energy = 0.6; _vp.add_child(l2)
	var we := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.8, 0.82, 0.86); we.environment = e; _vp.add_child(we)
	_name = _lbl("", 22, FG); _name.position = Vector2(rx + 20, 96 + h - 136); add_child(_name)
	_btn = Button.new(); _btn.focus_mode = Control.FOCUS_NONE; _btn.add_theme_font_size_override("font_size", 24)
	_btn.position = Vector2(rx + 20, 96 + h - 84); _btn.size = Vector2(right_w - 40, 64)
	_btn.pressed.connect(_on_btn); add_child(_btn)
	_sel = Profile.equipped(_cat)
	_refresh()

func _close() -> void:
	queue_free()

# try-on soldier: equipped look, with the previewed item swapped in
func _rebuild_preview() -> void:
	if _soldier: _soldier.queue_free()
	var suit := Profile.suit_color(); var kit := Profile.kit_color(); var fin := Profile.equipped("finish")
	var it := Profile.item(_sel)
	match String(it.get("cat", "")):
		"suit": suit = it["col"]
		"kit": kit = it["col"]
		"finish": fin = _sel
	_soldier = Soldier.new(); _vp.add_child(_soldier)
	_soldier.setup(suit, kit)
	_soldier.set_weapon(Controls.loadout[0] if Controls.loadout[0] != "knife" else "m4")
	Profile.apply_finish(_soldier._wmodel, fin)
	_soldier.drive(0.0, true)

func _refresh() -> void:
	_coins.text = "◆ %d" % Missions.coins()
	for c in _cats_box.get_children(): c.queue_free()
	for c in Profile.CATS:
		var on: bool = c[0] == _cat
		var b := Button.new(); b.text = c[1]; b.alignment = HORIZONTAL_ALIGNMENT_LEFT; b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(190, 56); b.add_theme_font_size_override("font_size", 19)
		for k in ["normal", "hover", "pressed"]: b.add_theme_stylebox_override(k, _sb(Color(0.118, 0.086, 0.051) if on else CARD, ACCENT if on else LINE, 2 if on else 1))
		var cid: String = c[0]
		b.pressed.connect(func() -> void: Sfx.play("ui"); _cat = cid; _sel = Profile.equipped(cid); _refresh())
		_cats_box.add_child(b)
	_cats_box.add_child(_lbl("\n오늘의 임무 3개를\n모두 깨면 하루 ◆ 120~180", 14, MUTED))
	for c in _grid.get_children(): c.queue_free()
	for it in Profile.items(_cat): _grid.add_child(_card(it))
	var sel := Profile.item(_sel)
	_name.text = String(sel.get("name", ""))
	var owned := Profile.owns(_sel)
	var equipped := Profile.equipped(_cat) == _sel
	var price := int(sel.get("price", 0))
	var col := ACCENT
	if equipped:
		_btn.text = "장착 중"; col = Color(0.2, 0.26, 0.3)
	elif owned:
		_btn.text = "장착하기"; col = OK
	else:
		_btn.text = "◆ %d  구매" % price
		if Missions.coins() < price: _btn.text = "◆ %d  (코인 부족)" % price; col = Color(0.3, 0.3, 0.32)
	for k in ["normal", "hover", "pressed", "disabled"]: _btn.add_theme_stylebox_override(k, _sb(col, col, 0))
	for k in ["font_color", "font_hover_color", "font_pressed_color"]: _btn.add_theme_color_override(k, Color(0.08, 0.05, 0.02) if col != Color(0.2, 0.26, 0.3) else FG)
	_rebuild_preview()

func _card(it: Dictionary) -> Control:
	var id: String = it["id"]
	var price := int(it["price"])
	var owned := Profile.owns(id)
	var equipped := Profile.equipped(_cat) == id
	var rar := rarity(price)
	var b := Button.new(); b.focus_mode = Control.FOCUS_NONE; b.custom_minimum_size = Vector2(196, 150)
	var bd: Color = ACCENT if equipped else (Color(1, 1, 1, 0.85) if id == _sel else LINE)
	for k in ["normal", "hover", "pressed"]: b.add_theme_stylebox_override(k, _sb(Color(0.118, 0.086, 0.051) if equipped else CARD, bd, 2 if (equipped or id == _sel) else 1))
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 5); v.position = Vector2(10, 10); v.size = Vector2(176, 130)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(v)
	var sw := ColorRect.new(); sw.custom_minimum_size = Vector2(176, 56); sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var c: Color = it.get("col", Color(0, 0, 0, 0))
	if _cat == "title":
		sw.color = Color(0.09, 0.11, 0.13)
		var tl := _lbl("「%s」" % it["name"], 18, rar[1]); tl.position = Vector2(8, 16); sw.add_child(tl)
	elif c.a == 0.0:
		sw.color = Color(0.36, 0.30, 0.24) if _cat == "kit" else Color(0.22, 0.24, 0.26)
	else:
		sw.color = c
	var bar := ColorRect.new(); bar.color = rar[1]; bar.size = Vector2(176, 4); bar.position = Vector2(0, 52); bar.mouse_filter = Control.MOUSE_FILTER_IGNORE; sw.add_child(bar)
	v.add_child(sw)
	var top := HBoxContainer.new(); top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var n := _lbl(it["name"], 17, FG); n.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(n)
	top.add_child(_lbl(rar[0] if price > 0 else "", 12, rar[1])); v.add_child(top)
	var tag := "장착 중" if equipped else ("보유" if owned else "◆ %d" % price)
	v.add_child(_lbl(tag, 15, OK if owned else Color(1.0, 0.8, 0.35)))
	b.pressed.connect(func() -> void: Sfx.play("ui"); _sel = id; _refresh())
	return b

func _on_btn() -> void:
	if Profile.equipped(_cat) == _sel: return
	if Profile.owns(_sel):
		Profile.equip(_sel); Sfx.play("ui")
	elif Profile.buy(_sel):
		Profile.equip(_sel); Sfx.play("reload")
	_refresh()
