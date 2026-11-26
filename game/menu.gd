extends Control
## Main menu — tactical HUD layout (시안 A). Player card + gold (상단),
## 로고 (좌), 모드 스택 (우), 하단 탭. Launches a mode with a clean run state.

const ACCENT := Color(1.0, 0.48, 0.10)
const PANEL := Color(0.10, 0.13, 0.16)
const PANEL2 := Color(0.12, 0.15, 0.18)
const LINE := Color(0.17, 0.20, 0.24)
const FG := Color(0.92, 0.95, 0.97)
const MUTED := Color(0.55, 0.62, 0.69)
const DIM := Color(0.38, 0.44, 0.50)

var _upd_btn: Button

func _on_update_checked(has_update: bool, latest: int) -> void:
	if _upd_btn == null:
		return
	if has_update:
		_upd_btn.text = "● 업데이트 v%d" % latest
		_upd_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
	else:
		_upd_btn.text = "⟳ 최신"
		_upd_btn.add_theme_color_override("font_color", MUTED)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_backdrop()
	_top_bar()
	_logo()
	_cards()
	_mode_stack()
	_bottom_nav()
	if not Updater.checked.is_connected(_on_update_checked):
		Updater.checked.connect(_on_update_checked)
	Updater.refresh()

# ---- top bar: avatar + name/level, gold ----
func _top_bar() -> void:
	var ava := _panel(Vector2(36, 26), Vector2(58, 58), PANEL2, ACCENT, 2, 10)
	add_child(ava)
	var ai := Label.new(); ai.text = "R"
	ai.add_theme_font_size_override("font_size", 30)
	ai.add_theme_color_override("font_color", ACCENT)
	ai.set_anchors_preset(Control.PRESET_FULL_RECT)
	ai.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ai.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ava.add_child(ai)

	var nm := _label("SOLDIER_01", 26, FG, false); nm.position = Vector2(108, 26); add_child(nm)
	var lv := _label(Profile.title(), 18, ACCENT.lerp(FG, 0.3), false); lv.position = Vector2(110, 58); add_child(lv)

	# gold pill (상점 경제는 2단계 — 자리만)
	var pill := _panel(Vector2(0, 30), Vector2(168, 48), Color(0.08, 0.10, 0.12), LINE, 1, 24)
	pill.anchor_left = 1.0; pill.anchor_right = 1.0
	pill.offset_left = -204; pill.offset_right = -36
	add_child(pill)
	var coin := _panel(Vector2(16, 12), Vector2(24, 24), Color(0.90, 0.68, 0.18), Color(0.66, 0.47, 0.10), 1, 12)
	pill.add_child(coin)
	var gv := _label(str(Missions.coins()), 22, FG, true); gv.position = Vector2(52, 10); pill.add_child(gv)

	# update button (left of gold)
	_upd_btn = Button.new()
	_upd_btn.text = "⟳ 업데이트"; _upd_btn.flat = true; _upd_btn.focus_mode = Control.FOCUS_NONE
	_upd_btn.add_theme_font_size_override("font_size", 20)
	_upd_btn.add_theme_color_override("font_color", MUTED)
	_upd_btn.add_theme_color_override("font_hover_color", FG)
	_upd_btn.anchor_left = 1.0; _upd_btn.anchor_right = 1.0
	_upd_btn.offset_left = -400; _upd_btn.offset_right = -214
	_upd_btn.offset_top = 30; _upd_btn.offset_bottom = 78
	_upd_btn.pressed.connect(func() -> void: Updater.show_dialog())
	add_child(_upd_btn)

# ---- live backdrop: the old quarter with your soldier holding your primary ----
var _bd_cam: Camera3D
var _bd_t := 0.0
const BD_SOLDIER := Vector3(1.0, 0.0, 35.0)

func _backdrop() -> void:
	var svc := SubViewportContainer.new(); svc.stretch = true
	svc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(svc)
	var vp := SubViewport.new(); vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(vp)
	var w := Node3D.new(); vp.add_child(w)
	MapBuilder.backdrop = true
	MapBuilder.build("quarter", w)
	MapBuilder.backdrop = false
	var s := Soldier.new(); w.add_child(s); s.cosmetic = true; s.body = Profile.equipped("body").substr(5); s.gear = Profile.equipped("gear").substr(5); s.setup(Profile.suit_color(), Profile.kit_color())
	s.position = BD_SOLDIER; s.rotation_degrees.y = 55.0
	s.set_weapon(Controls.loadout[0] if Controls.loadout[0] != "knife" else "m4"); s.drive(0.0, true)
	_bd_cam = Camera3D.new(); _bd_cam.fov = 36.0; w.add_child(_bd_cam); _bd_cam.current = true
	_place_cam()
	# shade the sides so the logo / cards (left) and the mode list (right) stay readable
	var g := Gradient.new(); g.set_color(0, Color(0.03, 0.04, 0.05, 0.62)); g.set_color(1, Color(0.03, 0.04, 0.05, 0.92))
	g.add_point(0.42, Color(0.03, 0.04, 0.05, 0.10))
	var gt := GradientTexture2D.new(); gt.gradient = g; gt.width = 256; gt.height = 8
	var tr := TextureRect.new(); tr.texture = gt; tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)

func _place_cam() -> void:
	var a := sin(_bd_t * 0.18) * 0.35            # slow sway around the soldier
	var off := Vector3(-4.2 * cos(a), 1.35 + sin(_bd_t * 0.13) * 0.06, 0.3 - 4.2 * sin(a) * 0.5)
	_bd_cam.position = BD_SOLDIER + off
	_bd_cam.look_at(BD_SOLDIER + Vector3(0.0, 1.05, 0.55), Vector3.UP)

func _process(dt: float) -> void:
	if _bd_cam:
		_bd_t += dt
		_place_cam()

# ---- logo (left) ----
func _logo() -> void:
	var k1 := _label("MINI", 58, FG, true); k1.position = Vector2(72, 190); add_child(k1)
	var k2 := _label("SOLDIER", 58, ACCENT, true); k2.position = Vector2(72, 254); add_child(k2)
	var dog := _label("OFFLINE · SOLO OPS", 18, MUTED, true); dog.position = Vector2(78, 332); add_child(dog)
	var ver := _label("v%d · %s" % [int(ProjectSettings.get_setting("application/config/build_code", 0)), str(ProjectSettings.get_setting("application/config/version", ""))], 16, DIM, false)
	ver.position = Vector2(78, 360); add_child(ver)

# ---- cards (bottom left): today's missions + last match ----
func _cards() -> void:
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 10)
	box.position = Vector2(72, 396); box.custom_minimum_size = Vector2(400, 0); add_child(box)
	var ms := Missions.today()
	var done := 0
	for x in ms: if x["done"]: done += 1
	var p := _card_panel(); box.add_child(p)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 4); p.add_child(v)
	var h := HBoxContainer.new()
	var t := _label("오늘의 임무", 15, ACCENT, false); t.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h.add_child(t)
	h.add_child(_label("%d / %d 완료" % [done, ms.size()], 14, MUTED, false)); v.add_child(h)
	for x in ms:
		var r := HBoxContainer.new(); r.add_theme_constant_override("separation", 8)
		var nm := _label(("✓ " if x["done"] else "") + String(x["text"]), 17, Color(0.45, 0.85, 0.6) if x["done"] else FG, false)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL; r.add_child(nm)
		r.add_child(_label("%d/%d" % [int(x["have"]), int(x["goal"])], 15, MUTED, false))
		r.add_child(_label("◆%d" % int(x["coin"]), 15, Color(0.95, 0.75, 0.3), false))
		v.add_child(r)
		var pb := ProgressBar.new(); pb.max_value = float(x["goal"]); pb.value = float(x["have"]); pb.show_percentage = false
		pb.custom_minimum_size = Vector2(0, 4)
		pb.add_theme_stylebox_override("background", _sb(Color(0.15, 0.18, 0.21), Color(0, 0, 0, 0), 0, 2))
		pb.add_theme_stylebox_override("fill", _sb(Color(0.45, 0.85, 0.6) if x["done"] else ACCENT, Color(0, 0, 0, 0), 0, 2))
		v.add_child(pb)
	var last := Missions.last()
	var p2 := _card_panel(); box.add_child(p2)
	var v2 := VBoxContainer.new(); v2.add_theme_constant_override("separation", 2); p2.add_child(v2)
	var h2 := HBoxContainer.new()
	var t2 := _label("최근 기록", 15, ACCENT, false); t2.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h2.add_child(t2)
	h2.add_child(_label("최고 웨이브 %d · 처치 %d" % [Controls.best_wave, Controls.best_kills], 14, MUTED, false)); v2.add_child(h2)
	if last.is_empty():
		v2.add_child(_label("아직 기록이 없습니다 — 첫 판을 시작해 보세요", 17, MUTED, false))
	else:
		v2.add_child(_label("%s · %s" % [last["mode"], last["map"]], 18, FG, false))
		v2.add_child(_label(String(last["result"]), 15, MUTED, false))

func _card_panel() -> PanelContainer:
	var p := PanelContainer.new()
	var sb := _sb(Color(0.07, 0.09, 0.11, 0.86), LINE, 1, 12); sb.set_content_margin_all(12)
	p.add_theme_stylebox_override("panel", sb)
	return p

# ---- mode stack (right) ----
func _mode_stack() -> void:
	_mode("웨이브 서바이벌", "PvE · 좀비 방어", "res://Main.tscn", 196, true, "survival")
	_mode("데스매치", "개인전 · 봇", "res://Deathmatch.tscn", 282, false, "dm")
	_mode("팀 데스매치", "3 vs 3 · 봇", "res://TeamDeathmatch.tscn", 368, false, "team")
	_mode("폭파미션", "5 vs 5 · 폭탄 설치/해체", "res://BombMode.tscn", 454, false, "bomb")
	_mode("훈련", "훈련장 · 표적 사격", "res://Training.tscn", 540, false, "training")

func _mode(title: String, subtitle: String, scene: String, y: float, primary: bool, kind: String) -> void:
	var p := Control.new()
	p.anchor_left = 1.0; p.anchor_right = 1.0
	p.offset_left = -600; p.offset_right = -40
	p.offset_top = y; p.offset_bottom = y + 76
	add_child(p)
	var bgp := Panel.new()
	bgp.set_anchors_preset(Control.PRESET_FULL_RECT)
	bgp.add_theme_stylebox_override("panel", _sb(PANEL if not primary else Color(0.16, 0.11, 0.05), ACCENT if primary else LINE, 2 if primary else 1, 12))
	p.add_child(bgp)
	var ic := _panel(Vector2(16, 12), Vector2(52, 52), Color(0.07, 0.09, 0.11), ACCENT if primary else LINE, 1, 9)
	p.add_child(ic)
	var icon := ModeIcon.new()
	icon.kind = kind
	icon.col = ACCENT if primary else Color(0.85, 0.90, 0.95)
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	ic.add_child(icon)
	var t := _label(title, 28, FG, false); t.position = Vector2(86, 10); p.add_child(t)
	var s := _label(subtitle, 18, DIM, false); s.position = Vector2(88, 44); p.add_child(s)
	var arr := _label("›", 34, ACCENT, true)
	arr.anchor_left = 1.0; arr.anchor_right = 1.0; arr.position = Vector2(0, 0)
	arr.offset_left = -48; arr.offset_right = -18; arr.offset_top = 16
	p.add_child(arr)
	var btn := Button.new()
	btn.flat = true; btn.focus_mode = Control.FOCUS_NONE
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.pressed.connect(func() -> void:
		Sfx.play("ui")
		add_child(SortieScreen.new().setup(title, subtitle, scene, kind)))
	p.add_child(btn)

# ---- bottom nav ----
func _bottom_nav() -> void:
	var bar := HBoxContainer.new()
	bar.anchor_left = 0.0; bar.anchor_right = 1.0; bar.anchor_top = 1.0; bar.anchor_bottom = 1.0
	bar.offset_left = 40; bar.offset_right = -40; bar.offset_top = -64; bar.offset_bottom = -12
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 10)
	add_child(bar)
	for i in ["출격", "상점", "장비", "기록", "설정"]:
		var b := Button.new(); b.text = i; b.flat = true; b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 22)
		b.add_theme_color_override("font_color", FG if i == "출격" else DIM)
		b.add_theme_color_override("font_hover_color", FG)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if i == "설정":
			b.pressed.connect(func() -> void: Sfx.play("ui"); Settings.open())
		elif i == "장비":
			b.add_theme_color_override("font_color", ACCENT)
			b.pressed.connect(func() -> void: Sfx.play("ui"); add_child(LoadoutScreen.new()))
		elif i == "상점":
			b.add_theme_color_override("font_color", ACCENT)
			b.pressed.connect(func() -> void:
				Sfx.play("ui")
				var sh := ShopScreen.new()
				sh.tree_exited.connect(func() -> void:     # rebuild: coins + what the soldier wears
					if is_inside_tree(): get_tree().change_scene_to_file.call_deferred("res://Menu.tscn"))
				add_child(sh))
		elif i == "기록":
			b.add_theme_color_override("font_color", ACCENT)
			b.pressed.connect(func() -> void: Sfx.play("ui"); add_child(RecordsScreen.new()))
		else:
			b.pressed.connect(func() -> void: Sfx.play("ui"))
		bar.add_child(b)

# ---- helpers ----
func _label(txt: String, size: int, col: Color, bold: bool) -> Label:
	var l := Label.new(); l.text = txt
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func _panel(pos: Vector2, sz: Vector2, bg: Color, border: Color, bw: int, rad: int) -> Panel:
	var p := Panel.new()
	p.position = pos; p.size = sz
	p.add_theme_stylebox_override("panel", _sb(bg, border, bw, rad))
	return p

func _sb(bg: Color, border: Color, bw: int, rad: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(bw); s.border_color = border
	s.set_corner_radius_all(rad)
	return s
