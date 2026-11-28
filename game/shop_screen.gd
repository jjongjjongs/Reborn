class_name ShopScreen
extends Control
## 상점: cosmetics bought with the ◆ coins from daily missions. Categories (left),
## item cards (middle, rarity colour by price), 3D try-on preview of your soldier
## (right) with buy / equip. Cosmetic only — no stat effects.
## 오늘의 상점: a free daily gift + 5 offers at 20% off (they rotate every day, but
## everything stays buyable at full price in its category — no fear of missing out).
## 무기 도색 also lists weapon mastery: 50 kills (knife 15) with a weapon = its gold
## finish; every weapon gold = 다마스커스. Mastery rewards are never sold.

const ACCENT := Color(1.0, 0.48, 0.10)
const FG := Color(0.92, 0.95, 0.97)
const MUTED := Color(0.55, 0.62, 0.69)
const PANEL := Color(0.063, 0.082, 0.102)
const CARD := Color(0.051, 0.071, 0.086)
const LINE := Color(0.133, 0.165, 0.196)
const OK := Color(0.45, 0.85, 0.6)

var _cat := "today"
var _sel := ""                 # item shown in the preview
var _cats_box: VBoxContainer
var _grid: GridContainer
var _coins: Label
var _name: Label
var _btn: Button
var _soldier: Soldier
var _vp: SubViewport
var _vpc: SubViewportContainer
var _cam: Camera3D
var _gun_pv: Node3D

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
	var csc := ScrollContainer.new(); csc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; cp.add_child(csc)
	fat_scrollbar(csc)
	_cats_box = VBoxContainer.new(); _cats_box.add_theme_constant_override("separation", 8)
	_cats_box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN; csc.add_child(_cats_box)   # buttons stop short of the scroll bar
	var gp := _panel(Vector2(264, 96), Vector2(mid_w, h))
	var sc := ScrollContainer.new(); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; gp.add_child(sc)
	fat_scrollbar(sc)
	_grid = GridContainer.new(); _grid.columns = maxi(2, int((mid_w - 28) / 206.0))
	_grid.add_theme_constant_override("h_separation", 10); _grid.add_theme_constant_override("v_separation", 10)
	sc.add_child(_grid)
	var rx := 264 + mid_w + 16
	_panel(Vector2(rx, 96), Vector2(right_w, h))
	var svc := SubViewportContainer.new(); _vpc = svc; svc.stretch = true; svc.position = Vector2(rx + 20, 110); svc.size = Vector2(right_w - 40, h - 160)
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(svc)
	_vp = SubViewport.new(); _vp.own_world_3d = true; _vp.transparent_bg = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS; svc.add_child(_vp)
	_cam = Camera3D.new(); _cam.fov = 34.0; _vp.add_child(_cam)
	var l := DirectionalLight3D.new(); l.rotation_degrees = Vector3(-40, -150, 0); _vp.add_child(l)
	var l2 := DirectionalLight3D.new(); l2.rotation_degrees = Vector3(-30, 30, 0); l2.light_energy = 0.6; _vp.add_child(l2)
	var we := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.8, 0.82, 0.86); we.environment = e; _vp.add_child(we)
	_name = _lbl("", 22, FG); _name.position = Vector2(rx + 20, 96 + h - 136); add_child(_name)
	_btn = Button.new(); _btn.focus_mode = Control.FOCUS_NONE; _btn.add_theme_font_size_override("font_size", 24)
	_btn.position = Vector2(rx + 20, 96 + h - 84); _btn.size = Vector2(right_w - 40, 64)
	_btn.pressed.connect(_on_btn); add_child(_btn)
	_sel = Profile.offers()[0] if not Profile.offers().is_empty() else Profile.equipped("suit")
	_refresh()

func _close() -> void:
	queue_free()

# try-on soldier: equipped look, with the previewed item swapped in
func _rebuild_preview() -> void:
	# weapon finishes: close-up on the gun; everything else: the whole soldier
	if _cat == "bomb" or String(Profile.item(_sel).get("cat", "")) == "bomb":
		# bomb skins: the bomb on its own, slowly turning
		if _gun_pv: _gun_pv.queue_free(); _gun_pv = null
		if _soldier: _soldier.queue_free(); _soldier = null
		_cam.fov = 30.0; _cam.look_at_from_position(Vector3(0.9, 11.4, 2.6), Vector3(0, 10.25, 0))
		_gun_pv = Node3D.new(); _gun_pv.position = Vector3(0, 10.0, 0); _vp.add_child(_gun_pv)
		var bm: Node3D = (load("res://assets/bomb/bomb.glb") as PackedScene).instantiate()
		bm.scale = Vector3.ONE * 2.2; _gun_pv.add_child(bm)
		Profile.apply_bomb_skin(bm, _sel if String(Profile.item(_sel).get("cat", "")) == "bomb" else Profile.equipped("bomb"))
		return
	var zw := String(Profile.item(_sel).get("cat", "")) == "zweapon"
	var gun_view := _cat == "finish" or _sel.begins_with("gold:") or String(Profile.item(_sel).get("cat", "")) == "finish" or zw
	if _gun_pv: _gun_pv.queue_free(); _gun_pv = null
	if gun_view:
		# the weapon on its own, side on, slowly turning (see the pattern / colour clearly)
		_cam.fov = 30.0; _cam.position = Vector3(0, 10.0, 2.1); _cam.look_at_from_position(_cam.position, Vector3(0, 10.0, 0))
		var wid2: String = _sel.substr(5) if _sel.begins_with("gold:") else (String(Profile.item(_sel)["wid"]) if zw else (Controls.loadout[0] if Controls.loadout[0] != "knife" and not Weapons.is_zombie(Controls.loadout[0]) else "m4"))
		var g: Node3D = (load("res://assets/guns/%s.glb" % wid2) as PackedScene).instantiate()
		var ab := AABB(); var first := true
		for mi in g.find_children("*", "MeshInstance3D", true, false):
			var bx: AABB = (mi as MeshInstance3D).get_aabb(); ab = bx if first else ab.merge(bx); first = false
		var sc := 1.1 / maxf(ab.size.x, 0.001)
		_gun_pv = Node3D.new(); _gun_pv.position = Vector3(0, 10.0, 0); _vp.add_child(_gun_pv)
		_gun_pv.add_child(g); g.scale = Vector3.ONE * sc; g.position = -ab.get_center() * sc
		if not zw: Profile.apply_finish(g, "fin_gold" if _sel.begins_with("gold:") else (_sel if String(Profile.item(_sel).get("cat", "")) == "finish" else ""), wid2)
		if zw: _zw_info(String(Profile.item(_sel)["wid"]))
		elif _zw_lbl: _zw_lbl.visible = false
	else:
		_cam.fov = 34.0; _cam.position = Vector3(-1.7, 1.35, -3.3); _cam.look_at_from_position(_cam.position, Vector3(0.0, 1.05, -0.1))   # whole soldier incl. the mini's big helmet
	if _soldier: _soldier.queue_free()
	var suit := Profile.suit_color(); var kit := Profile.kit_color(); var fin := Profile.equipped("finish")
	var bd := Profile.equipped("body").substr(5); var gr := Profile.equipped("gear").substr(5)
	var sk := Profile.skin_mats(Profile.equipped("skin"))
	var wid: String = Controls.loadout[0] if Controls.loadout[0] != "knife" else "m4"
	var it := Profile.item(_sel)
	if _sel.begins_with("gold:"):
		wid = _sel.substr(5); fin = "fin_gold"
	else:
		match String(it.get("cat", "")):
			"suit": suit = it["col"]
			"kit": kit = it["col"]
			"finish": fin = _sel
			"body": bd = _sel.substr(5); sk = Profile.skin_mats(Profile.skin_id(_sel))
			"skin": bd = String(it["body"]).substr(5); sk = Profile.skin_mats(_sel)
	_soldier = Soldier.new(); _soldier.body = bd; _soldier.gear = gr; _soldier.skin = sk; _vp.add_child(_soldier)
	_soldier.wfx = _sel if String(it.get("cat", "")) == "wfx" else Profile.equipped("wfx")
	_soldier.cfx = _sel if String(it.get("cat", "")) == "cfx" else Profile.equipped("cfx")
	_soldier.fx_preview = true
	_soldier.setup(suit, kit)
	_soldier.set_weapon(wid)
	if fin == Profile.equipped("finish") and not _sel.begins_with("gold:") and String(it.get("cat", "")) != "finish":
		Profile.apply_finish(_soldier._wmodel, "", wid)
	else:
		Profile.apply_finish(_soldier._wmodel, fin, wid)
	_soldier.drive(0.0, true)

func _refresh() -> void:
	_coins.text = "◆ %d" % Missions.coins()
	for c in _cats_box.get_children(): c.queue_free()
	for c in [["today", "오늘의 상점"]] + Profile.CATS:
		var on: bool = c[0] == _cat
		var b := Button.new(); b.text = c[1]; b.alignment = HORIZONTAL_ALIGNMENT_LEFT; b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(150, 56); b.add_theme_font_size_override("font_size", 19)
		for k in ["normal", "hover", "pressed"]: b.add_theme_stylebox_override(k, _sb(Color(0.118, 0.086, 0.051) if on else CARD, ACCENT if on else LINE, 2 if on else 1))
		var cid: String = c[0]
		b.pressed.connect(func() -> void: Sfx.play("ui"); _cat = cid; _sel = Profile.offers()[0] if cid == "today" else (Profile.items(cid)[0]["id"] if cid == "zweapon" else Profile.equipped(cid)); _refresh())
		_cats_box.add_child(b)
	_cats_box.add_child(_lbl("\n오늘의 임무 3개를\n모두 깨면 하루 ◆ 120~180", 14, MUTED))
	for c in _grid.get_children(): c.queue_free()
	if _cat == "today":
		_grid.add_child(_gift_card())
		for id in Profile.offers(): _grid.add_child(_card(Profile.item(id)))
	else:
		for it in Profile.items(_cat): _grid.add_child(_card(it))
		if _cat == "finish":
			for w in Weapons.ORDER_PRIMARY + Weapons.ORDER_SECONDARY + Weapons.ORDER_MELEE: _grid.add_child(_gold_card(w))
	var col := ACCENT
	if _sel.begins_with("gold:"):
		var w := _sel.substr(5)
		_name.text = "금장 · %s" % Weapons.get_w(w)["name"]
		if not Profile.mastered(w):
			_btn.text = "숙련 %d / %d 처치" % [Profile.stat("k_" + w), Profile.mastery_goal(w)]; col = Color(0.3, 0.3, 0.32)
		elif Profile.gold_on(w):
			_btn.text = "금장 끄기"; col = Color(0.2, 0.26, 0.3)
		else:
			_btn.text = "금장 켜기"; col = OK
	else:
		var sel := Profile.item(_sel)
		var scat := String(sel.get("cat", ""))
		_name.text = String(sel.get("name", ""))
		var owned := Profile.owns(_sel)
		var equipped := Profile.equipped(scat) == _sel
		var price := Profile.price_today(_sel)
		if sel.has("body") and not Profile.owns(String(sel["body"])):
			_btn.text = "%s 먼저 구매" % String(Profile.item(String(sel["body"])).get("name", "캐릭터")); col = Color(0.3, 0.3, 0.32)
		elif scat == "zweapon" and owned:
			_btn.text = "보유 · 좀비 모드 장비에서 선택"; col = Color(0.2, 0.26, 0.3)
		elif equipped:
			_btn.text = "장착 중"; col = Color(0.2, 0.26, 0.3)
		elif owned:
			_btn.text = "장착하기"; col = OK
		elif sel.get("mastery", false):
			_btn.text = "숙련 무기 %d / 9" % Profile.mastered_count(); col = Color(0.3, 0.3, 0.32)
		else:
			_btn.text = "◆ %d  구매" % price
			if Missions.coins() < price: _btn.text = "◆ %d  (코인 부족)" % price; col = Color(0.3, 0.3, 0.32)
	for k in ["normal", "hover", "pressed", "disabled"]: _btn.add_theme_stylebox_override(k, _sb(col, col, 0))
	for k in ["font_color", "font_hover_color", "font_pressed_color"]: _btn.add_theme_color_override(k, Color(0.08, 0.05, 0.02) if col != Color(0.2, 0.26, 0.3) else FG)
	_rebuild_preview()

## a scroll bar a thumb can actually grab: 30 px wide track, 22 px rounded handle, wide touch target;
## dragging the list itself scrolls too
static func fat_scrollbar(sc: ScrollContainer) -> void:
	sc.scroll_deadzone = 8
	var vb := sc.get_v_scroll_bar()
	vb.custom_minimum_size.x = 30
	var track := StyleBoxFlat.new(); track.bg_color = Color(1, 1, 1, 0.06); track.set_corner_radius_all(15)
	track.content_margin_left = 4; track.content_margin_right = 4
	var grab := StyleBoxFlat.new(); grab.bg_color = Color(1, 1, 1, 0.55); grab.set_corner_radius_all(11)
	var grab_hl := grab.duplicate() as StyleBoxFlat; grab_hl.bg_color = Color(1.0, 0.6, 0.25, 0.9)
	vb.add_theme_stylebox_override("scroll", track)
	vb.add_theme_stylebox_override("scroll_focus", track)
	vb.add_theme_stylebox_override("grabber", grab)
	vb.add_theme_stylebox_override("grabber_highlight", grab_hl)
	vb.add_theme_stylebox_override("grabber_pressed", grab_hl)

func _card(it: Dictionary) -> Control:
	var id: String = it["id"]
	var cat := String(it["cat"])
	var price := int(it["price"])
	var locked: bool = it.has("body") and not Profile.owns(String(it["body"]))     # skin of a character you don't have
	var owned := Profile.owns(id) and not locked
	var equipped := (Profile.skin_id(String(it["body"])) == id and not locked) if cat == "skin" else Profile.equipped(cat) == id
	var mast: bool = it.get("mastery", false)
	var rar: Array = ["숙련", Color(1.0, 0.85, 0.4)] if mast else rarity(price)
	var b := Button.new(); b.focus_mode = Control.FOCUS_NONE; b.custom_minimum_size = Vector2(196, 150)
	var bd: Color = ACCENT if equipped else (Color(1, 1, 1, 0.85) if id == _sel else LINE)
	for k in ["normal", "hover", "pressed"]: b.add_theme_stylebox_override(k, _sb(Color(0.118, 0.086, 0.051) if equipped else CARD, bd, 2 if (equipped or id == _sel) else 1))
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 5); v.position = Vector2(10, 10); v.size = Vector2(176, 130)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(v)
	var sw := ColorRect.new(); sw.custom_minimum_size = Vector2(176, 56); sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var c: Color = it.get("col", Color(0, 0, 0, 0))
	if cat == "title":
		sw.color = Color(0.09, 0.11, 0.13)
		var tl := _lbl(String(it["name"]), 20, rar[1]); tl.position = Vector2(8, 16); sw.add_child(tl)
	elif cat == "body" or cat == "gear":
		sw.color = Color(0.10, 0.13, 0.16)
		var sub: String = {"body_rookie": "기본 · 고글 헬멧, 플레이트 캐리어", "body_scout": "전술 모자 · 가벼운 체스트 리그", "body_tech": "무전기 배낭 · 팔 단말기",
			"body_sniper": "후드 · 마스크 · 길리 스카프", "body_heavy": "중장갑 · 어깨 보호대 · 탄띠"}.get(id, "")
		var tl := _lbl(sub, 13, MUTED); tl.position = Vector2(8, 20); sw.add_child(tl)
	elif cat == "zweapon":
		sw.color = Color(0.16, 0.08, 0.06)
		var w := Weapons.get_w(String(it["wid"]))
		var tl := _lbl("좀비 모드 전용 · " + String(w["cls"]), 13, Color(1.0, 0.6, 0.35)); tl.position = Vector2(8, 8); sw.add_child(tl)
		var t2 := _lbl(["주무기", "보조", "근접"][int(w["slot"])], 13, MUTED); t2.position = Vector2(8, 28); sw.add_child(t2)
	elif cat == "skin":                 # the skin's main colours side by side (base = the character's own look)
		var mats: Dictionary = it.get("mats", {})
		var cols := [mats.get("R_Helmet", Color(0.42, 0.42, 0.36)), mats.get("R_Gear", Color(0.55, 0.48, 0.36)), mats.get("R_Uniform", Color(0.36, 0.38, 0.28)), mats.get("R_Accent", mats.get("R_Sleeve", Color(0.3, 0.3, 0.3)))]
		sw.color = Color(0.10, 0.13, 0.16)
		for k in 4:
			var st := ColorRect.new(); st.color = cols[k]; st.mouse_filter = Control.MOUSE_FILTER_IGNORE
			st.size = Vector2(44, 52); st.position = Vector2(k * 44, 0); sw.add_child(st)
	elif c.a == 0.0:
		sw.color = Color(0.22, 0.24, 0.26)
	else:
		sw.color = c
		if it.has("pat"):     # hint the pattern with the second colour
			for k in 5:
				var st := ColorRect.new(); st.color = it.get("col2", Color.BLACK); st.mouse_filter = Control.MOUSE_FILTER_IGNORE
				st.size = Vector2(12, 52); st.position = Vector2(14 + k * 34, 0); st.rotation = 0.35; sw.add_child(st)
			sw.clip_contents = true
	var bar := ColorRect.new(); bar.color = rar[1]; bar.size = Vector2(176, 4); bar.position = Vector2(0, 52); bar.mouse_filter = Control.MOUSE_FILTER_IGNORE; sw.add_child(bar)
	v.add_child(sw)
	var top := HBoxContainer.new(); top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var n := _lbl(it["name"], 17, FG); n.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(n)
	top.add_child(_lbl(rar[0] if price > 0 else "", 12, rar[1])); v.add_child(top)
	var today := Profile.price_today(id)
	var tag := "캐릭터 필요" if locked else ("장착 중" if equipped else ("보유" if owned else ("숙련 보상" if mast else ("◆ %d" % today))))
	var tl := _lbl(tag, 15, OK if owned else Color(1.0, 0.8, 0.35))
	if not owned and not mast and today < price:
		var hb := HBoxContainer.new(); hb.mouse_filter = Control.MOUSE_FILTER_IGNORE; hb.add_child(tl)
		hb.add_child(_lbl("  ◆%d  -20%%" % price, 13, Color(1.0, 0.45, 0.35))); v.add_child(hb)
	else:
		v.add_child(tl)
	b.pressed.connect(func() -> void: Sfx.play("ui"); _sel = id; _refresh())
	return b

func _gift_card() -> Control:
	var ready := Profile.gift_ready()
	var b := Button.new(); b.focus_mode = Control.FOCUS_NONE; b.custom_minimum_size = Vector2(196, 150)
	for k in ["normal", "hover", "pressed"]: b.add_theme_stylebox_override(k, _sb(Color(0.08, 0.14, 0.10) if ready else CARD, OK if ready else LINE, 2 if ready else 1))
	var v := VBoxContainer.new(); v.position = Vector2(10, 10); v.size = Vector2(176, 130); v.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(v)
	var sw := ColorRect.new(); sw.custom_minimum_size = Vector2(176, 56); sw.color = Color(0.10, 0.16, 0.12); sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gl := _lbl("선물  ◆ %d" % Profile.GIFT, 24, OK); gl.position = Vector2(30, 12); sw.add_child(gl); v.add_child(sw)
	v.add_child(_lbl("무료 일일 선물", 17, FG))
	v.add_child(_lbl("눌러서 받기" if ready else "내일 다시", 15, OK if ready else MUTED))
	b.pressed.connect(func() -> void:
		if Profile.claim_gift(): Sfx.play("reload")
		_refresh())
	return b

func _gold_card(w: String) -> Control:
	var id := "gold:" + w
	var done := Profile.mastered(w)
	var on := Profile.gold_on(w)
	var b := Button.new(); b.focus_mode = Control.FOCUS_NONE; b.custom_minimum_size = Vector2(196, 150)
	var bd: Color = ACCENT if on else (Color(1, 1, 1, 0.85) if id == _sel else LINE)
	for k in ["normal", "hover", "pressed"]: b.add_theme_stylebox_override(k, _sb(Color(0.118, 0.086, 0.051) if on else CARD, bd, 2 if (on or id == _sel) else 1))
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 5); v.position = Vector2(10, 10); v.size = Vector2(176, 130)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(v)
	var sw := ColorRect.new(); sw.custom_minimum_size = Vector2(176, 56); sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sw.color = Color(0.85, 0.66, 0.20) if done else Color(0.30, 0.26, 0.16)
	var bar := ColorRect.new(); bar.color = Color(1.0, 0.85, 0.4); bar.size = Vector2(176, 4); bar.position = Vector2(0, 52); bar.mouse_filter = Control.MOUSE_FILTER_IGNORE; sw.add_child(bar)
	v.add_child(sw)
	var top := HBoxContainer.new(); top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var n := _lbl("금장 · " + String(Weapons.get_w(w)["name"]), 16, FG); n.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(n)
	top.add_child(_lbl("숙련", 12, Color(1.0, 0.85, 0.4))); v.add_child(top)
	var k := int(Profile.stat("k_" + w)); var goal := Profile.mastery_goal(w)
	v.add_child(_lbl(("켜짐" if on else "해금 · 누르면 켜기") if done else "처치 %d / %d" % [mini(k, goal), goal], 15, OK if done else MUTED))
	b.pressed.connect(func() -> void: Sfx.play("ui"); _sel = id; _refresh())
	return b

## zombie weapon: what it does, over the turning model
var _zw_lbl: Label
func _zw_info(wid: String) -> void:
	if _zw_lbl == null:
		_zw_lbl = _lbl("", 16, FG); _zw_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_zw_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0)); _zw_lbl.add_theme_constant_override("outline_size", 6)
		_vpc.add_child(_zw_lbl); _zw_lbl.position = Vector2(16, 16); _zw_lbl.size = Vector2(_vpc.size.x - 32, 60)
	_zw_lbl.visible = true
	_zw_lbl.text = String(Weapons.get_w(wid)["desc"])

func _on_btn() -> void:
	if _sel.begins_with("gold:"):
		Profile.toggle_gold(_sel.substr(5)); Sfx.play("ui"); _refresh(); return
	var scat := String(Profile.item(_sel).get("cat", ""))
	if Profile.equipped(scat) == _sel: return
	if Profile.owns(_sel):
		Profile.equip(_sel); Sfx.play("ui")
	elif Profile.buy(_sel):
		Profile.equip(_sel); Sfx.play("reload")
	_refresh()


var _fx_t := 0.5
var _fx_shots := 0
func _process(dt: float) -> void:
	if _gun_pv: _gun_pv.rotation.y = sin(Time.get_ticks_msec() / 1000.0 * 0.6) * 0.5
	# effect preview: the try-on soldier fires tracers / gets "killed" with the selected effect, on a loop
	var cat := String(Profile.item(_sel).get("cat", ""))
	if cat in ["killfx", "tracer"] and _soldier and is_instance_valid(_soldier) and _soldier.is_inside_tree():
		_fx_t -= dt
		if _fx_t <= 0.0:
			if cat == "tracer":
				var fwd := -_soldier.global_transform.basis.z
				var a: Vector3 = _soldier.global_position + Vector3(0, 1.32, 0) + fwd * 0.75 + _soldier.global_transform.basis.x * -0.12
				FxCos.tracer(_sel, _vp, a, a + fwd * 14.0 + Vector3(randf_range(-0.4, 0.4), randf_range(-0.2, 0.3), 0), 0.12)
				_soldier.shoot()
				_fx_shots += 1
				_fx_t = 0.16 if _fx_shots % 4 != 0 else 1.0
			else:
				_fx_t = 2.4
				if _sel != "kill_none":
					var sd := _soldier
					sd.visible = false
					FxCos.kill(_sel, _vp, sd.global_position, Color(0.85, 0.45, 0.2))
					get_tree().create_timer(1.5).timeout.connect(func() -> void: if is_instance_valid(sd): sd.visible = true)
