class_name SortieScreen
extends Control
## 출격 준비 (시안 A안): after picking a mode — map list | bot difficulty | loadout,
## then 출격. Choices persist (Controls.sel_map / bot_diff / loadout).

const ACCENT := Color(1.0, 0.48, 0.10)
const PANEL := Color(0.063, 0.082, 0.102)
const CARD := Color(0.051, 0.071, 0.086)
const LINE := Color(0.122, 0.149, 0.176)
const LINE2 := Color(0.133, 0.165, 0.196)
const SEL_BG := Color(0.118, 0.086, 0.051)
const FG := Color(0.92, 0.95, 0.97)
const MUTED := Color(0.54, 0.60, 0.66)
const SOFT := Color(0.65, 0.71, 0.75)

# maps drawn from their plan (assets/maps/<plan>.json) — see MapPlan
const BOMB_MAPS := [
	{"id": "quarter", "plan": "oldquarter", "name": "구도심", "en": "OLD QUARTER", "size": "110×100m · 5 vs 5", "tag": "지하 통로 · 발코니 · 중앙 고지대", "ready": true, "ground": Color("2a2d31")},
	{"id": "dockside", "plan": "dockside", "name": "항만 창고", "en": "DOCKSIDE", "size": "108×96m · 5 vs 5", "tag": "창고 마당 A · 부두 B · 배수로", "ready": true, "ground": Color("2a2d31")},
	{"id": "facility", "plan": "facility", "name": "연구 시설", "en": "FACILITY", "size": "108×96m · 5 vs 5", "tag": "반응로실 A · 하역장 B · 실내 복도", "ready": true, "ground": Color("2a2d31")},
]
const MAPS := [
	{"id": "downtown", "plan": "downtown", "name": "다운타운", "en": "DOWNTOWN", "size": "72×60m · 4–8명", "tag": "대로 · 지하철 · 주차장 2층", "ready": true, "ground": Color("2a2d31")},
	{"id": "bazaar", "plan": "bazaar", "name": "사막 시장", "en": "BAZAAR", "size": "68×60m · 4–8명", "tag": "광장 · 실내 시장 · 지붕 테라스", "ready": true, "ground": Color("3a3226")},
	{"id": "cell", "plan": "cell", "name": "교도소", "en": "CELLBLOCK", "size": "64×56m · 4–8명", "tag": "감방 복도 · 감시탑 · 운동장 통로", "ready": true, "ground": Color("2a2e33")},
	{"id": "harbor", "plan": "harbor", "name": "컨테이너 항구", "en": "HARBOR", "size": "72×56m · 4–8명", "tag": "컨테이너 미로 · 사무동 옥상", "ready": true, "ground": Color("263038")},
	{"id": "range", "name": "훈련장", "en": "TRAINING", "size": "소형 · 2–8명", "tag": "상자 엄폐 기본 맵", "ready": true,
		"ground": Color("27303a"), "rects": [[8, 14, 12, 18, "46505b"], [78, 14, 12, 18, "46505b"], [42, 36, 16, 26, "55606c"], [14, 66, 12, 18, "46505b"], [74, 66, 12, 18, "46505b"]]},
]
const KIND_COL := {"street": "8c8678", "plaza": "b9b2a6", "siteA": "ff7a1a", "siteB": "f2c14e", "att": "f05a52", "def": "56a8ff",
	"room": "5f5a52", "tunnel": "1d4a63", "water": "1d4a63"}

static func _thumb_rects(m: Dictionary) -> Array:
	if not m.has("plan"): return m["rects"]
	var p = JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/%s.json" % m["plan"]))
	if p == null: return []
	var sx := 100.0 / float(p["W"]); var sy := 100.0 / float(p["H"])
	var out := []
	for sp in p["spaces"]:
		if sp[6] != null and sp[0] == "street": continue   # passages under bridges
		var k := String(sp[0])
		if not KIND_COL.has(k): continue
		out.append([float(sp[1]) * sx, float(sp[2]) * sy, (float(sp[3]) - float(sp[1])) * sx, (float(sp[4]) - float(sp[2])) * sy, KIND_COL[k]])
	for r in p["ramps"]:
		out.append([float(r[0]) * sx, float(r[1]) * sy, (float(r[2]) - float(r[0])) * sx, (float(r[3]) - float(r[1])) * sy, "a09a8c"])
	return out

var title := ""
var subtitle := ""
var scene := ""
var kind := ""          # survival / dm / team

var _map_box: GridContainer
var _diff_box: VBoxContainer
var _detail: GridContainer
var _slots: VBoxContainer
var _summary: Label

func setup(t: String, sub: String, sc: String, k: String) -> SortieScreen:
	title = t; subtitle = sub; scene = sc; kind = k
	return self

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new(); bg.color = Color(0.043, 0.055, 0.071)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	if not _map_ready(Controls.sel_map): Controls.sel_map = "quarter" if kind == "bomb" else "downtown"

	# --- top bar ---
	var back := _btn("‹ 메뉴", 20, Vector2(28, 18), Vector2(110, 48))
	back.add_theme_stylebox_override("normal", _sb(Color(0, 0, 0, 0), Color(0.17, 0.2, 0.235), 1, 10))
	back.pressed.connect(func() -> void: Sfx.play("ui"); queue_free())
	add_child(back)
	var eyebrow := _label("SORTIE · 출격 준비", 13, MUTED); eyebrow.position = Vector2(158, 16); add_child(eyebrow)
	var tl := _label(title, 28, FG); tl.position = Vector2(156, 34); add_child(tl)
	var sl := _label(subtitle, 18, MUTED)
	sl.position = Vector2(166 + tl.get_minimum_size().x, 44); add_child(sl)
	var mem := _label("마지막 선택을 기억합니다", 15, MUTED)
	mem.anchor_left = 1.0; mem.anchor_right = 1.0; mem.offset_left = -300; mem.offset_right = -28; mem.offset_top = 32
	mem.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; add_child(mem)

	# --- columns ---
	var col_y := 84.0
	var col_h := 520.0
	var c1 := _panel(Vector2(28, col_y), Vector2(548, col_h)); add_child(c1)
	var h1 := _label("맵", 20, FG); h1.position = Vector2(16, 12); c1.add_child(h1)
	var h1b := _label("%d개" % _maps().size(), 14, MUTED); h1b.position = Vector2(46, 17); c1.add_child(h1b)
	_map_box = GridContainer.new(); _map_box.columns = 2
	_map_box.position = Vector2(16, 48)
	_map_box.add_theme_constant_override("h_separation", 10)
	_map_box.add_theme_constant_override("v_separation", 10)
	c1.add_child(_map_box)

	var c2 := _panel(Vector2(592, col_y), Vector2(300, col_h)); add_child(c2)
	var h2 := _label("좀비 강도" if kind == "survival" else "봇 난이도", 20, FG); h2.position = Vector2(16, 12); c2.add_child(h2)
	_diff_box = VBoxContainer.new(); _diff_box.position = Vector2(16, 48); _diff_box.size = Vector2(268, 300)
	_diff_box.add_theme_constant_override("separation", 8)
	c2.add_child(_diff_box)
	_detail = GridContainer.new(); _detail.columns = 2
	_detail.position = Vector2(16, 368); _detail.size = Vector2(268, 120)
	_detail.add_theme_constant_override("v_separation", 6)
	c2.add_child(_detail)

	var c3 := Panel.new()
	c3.add_theme_stylebox_override("panel", _sb(PANEL, LINE, 1, 14))
	c3.position = Vector2(908, col_y); c3.size = Vector2(344, col_h)
	c3.anchor_right = 1.0; c3.offset_right = -28
	add_child(c3)
	var h3 := _label("장비", 20, FG); h3.position = Vector2(16, 12); c3.add_child(h3)
	_slots = VBoxContainer.new(); _slots.position = Vector2(16, 48)
	_slots.add_theme_constant_override("separation", 8)
	c3.add_child(_slots)
	var chg := Button.new(); chg.text = "장비 변경 ›"; chg.focus_mode = Control.FOCUS_NONE
	chg.add_theme_font_size_override("font_size", 18)
	chg.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	for k in ["normal", "hover", "pressed"]: chg.add_theme_stylebox_override(k, _sb(Color(0, 0, 0, 0), ACCENT, 1, 10))
	chg.anchor_left = 0.0; chg.anchor_right = 1.0; chg.anchor_top = 1.0; chg.anchor_bottom = 1.0
	chg.offset_left = 16; chg.offset_right = -16; chg.offset_top = -66; chg.offset_bottom = -16
	chg.pressed.connect(func() -> void:
		Sfx.play("ui")
		var lo := LoadoutScreen.new()
		lo.tree_exited.connect(_refresh)
		add_child(lo))
	c3.add_child(chg)

	# --- bottom bar ---
	var line := ColorRect.new(); line.color = Color(0.1, 0.125, 0.15)
	line.anchor_right = 1.0; line.anchor_top = 1.0; line.anchor_bottom = 1.0
	line.offset_left = 28; line.offset_right = -28; line.offset_top = -100; line.offset_bottom = -99
	add_child(line)
	var cap := _label("이번 판", 13, MUTED)
	cap.anchor_top = 1.0; cap.anchor_bottom = 1.0; cap.offset_left = 30; cap.offset_top = -88; add_child(cap)
	_summary = _label("", 20, FG)
	_summary.anchor_top = 1.0; _summary.anchor_bottom = 1.0; _summary.offset_left = 30; _summary.offset_top = -66
	add_child(_summary)
	var go := Button.new(); go.text = "출격 ›"; go.focus_mode = Control.FOCUS_NONE
	go.add_theme_font_size_override("font_size", 26)
	go.add_theme_color_override("font_color", Color(0.08, 0.05, 0.02))
	go.add_theme_color_override("font_hover_color", Color(0.08, 0.05, 0.02))
	go.add_theme_color_override("font_pressed_color", Color(0.08, 0.05, 0.02))
	for k in ["normal", "hover", "pressed"]: go.add_theme_stylebox_override(k, _sb(ACCENT, ACCENT, 0, 12))
	go.anchor_left = 1.0; go.anchor_right = 1.0; go.anchor_top = 1.0; go.anchor_bottom = 1.0
	go.offset_left = -328; go.offset_right = -28; go.offset_top = -86; go.offset_bottom = -22
	go.pressed.connect(_launch)
	add_child(go)
	_refresh()

func _launch() -> void:
	Sfx.play("ui")
	Controls.save_settings()
	Controls.reset()
	get_tree().change_scene_to_file(scene)

func _maps() -> Array:
	return BOMB_MAPS if kind == "bomb" else MAPS

func _map_ready(id: String) -> bool:
	for m in _maps():
		if m["id"] == id: return bool(m["ready"])
	return false

func _refresh() -> void:
	if not is_inside_tree(): return
	# maps
	for c in _map_box.get_children(): c.queue_free()
	for m in _maps():
		_map_box.add_child(_map_card(m))
	# difficulty
	for c in _diff_box.get_children(): c.queue_free()
	var surv := kind == "survival"
	for id in Difficulty.IDS:
		var d: Dictionary = Difficulty.L[id]
		var on: bool = id == Controls.bot_diff
		var b := Button.new(); b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(268, 64)
		for k in ["normal", "hover", "pressed"]: b.add_theme_stylebox_override(k, _sb(SEL_BG if on else CARD, ACCENT if on else LINE2, 2 if on else 1, 10))
		var pip := ColorRect.new(); pip.color = d["color"]; pip.size = Vector2(10, 10); pip.position = Vector2(14, 16)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(pip)
		var n := _label(d["name"], 18, FG); n.position = Vector2(32, 5); b.add_child(n)
		var sh := _label(d["z_short"] if surv else d["short"], 13, SOFT); sh.position = Vector2(14, 34); b.add_child(sh)
		var did: String = id
		b.pressed.connect(func() -> void: Sfx.play("ui"); Controls.bot_diff = did; _refresh())
		_diff_box.add_child(b)
	for c in _detail.get_children(): c.queue_free()
	var cd := Difficulty.cur()
	var rows := []
	if surv:
		rows = [["좀비 체력", "×%.2f" % cd["z_hp"]], ["좀비 공격력", "×%.2f" % cd["z_dmg"]], ["좀비 속도", "×%.2f" % cd["z_spd"]]]
	else:
		rows = [["반응 속도", "%.2f초" % cd["react"]], ["명중 퍼짐", "%.1f°" % cd["spread"]],
			["봇 화력", "%d%%" % roundi(cd["dmg"] * 100.0)], ["수류탄·칼", cd["tactics_txt"]]]
	for r in rows:
		var a := _label(r[0], 14, MUTED); a.custom_minimum_size = Vector2(134, 0); _detail.add_child(a)
		var v := _label(r[1], 14, FG); v.custom_minimum_size = Vector2(134, 0)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; _detail.add_child(v)
	# loadout slots
	for c in _slots.get_children(): c.queue_free()
	var names := ["주무기", "보조", "근접", "투척"]
	for i in 4:
		var row := Panel.new(); row.custom_minimum_size = Vector2(310, 62)
		row.add_theme_stylebox_override("panel", _sb(CARD, LINE2, 1, 10))
		var k := _label(names[i], 13, MUTED); k.position = Vector2(12, 22); row.add_child(k)
		var nm := ""
		var sub := ""
		if i == 3:
			nm = "수류탄 ×%d" % Controls.NADE_MAX; sub = "반경 4m"
		else:
			var w := Weapons.get_w(Controls.loadout[i])
			nm = w["name"]
			sub = "뒤에서 한 방" if w.get("melee", false) else "%s · %d발" % [w["cls"], w["mag"]]
		var v1 := _label(nm, 18, FG); v1.position = Vector2(68, 7); row.add_child(v1)
		var v2 := _label(sub, 12, MUTED); v2.position = Vector2(68, 34); row.add_child(v2)
		_slots.add_child(row)
	# summary
	var mname := ""
	for m in _maps():
		if m["id"] == Controls.sel_map: mname = m["name"]
	var who := "웨이브 5" if surv else ("3 vs 3" if kind == "team" else ("5 vs 5 · 7승" if kind == "bomb" else "개인전 6명"))
	_summary.text = "%s · %s · %s" % [mname, Difficulty.cur()["name"], who]

func _map_card(m: Dictionary) -> Button:
	var on: bool = m["id"] == Controls.sel_map
	var ready: bool = m["ready"]
	var b := Button.new(); b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(253, 150)
	for k in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(k, _sb(SEL_BG if on else CARD, ACCENT if on else LINE2, 2 if on else 1, 12))
	var th := ColorRect.new(); th.color = m["ground"]
	th.position = Vector2(2, 2); th.size = Vector2(249, 92); th.mouse_filter = Control.MOUSE_FILTER_IGNORE
	th.clip_contents = true
	b.add_child(th)
	for r in _thumb_rects(m):
		var rr := ColorRect.new(); rr.color = Color(str(r[4])); rr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rr.position = Vector2(float(r[0]) * 2.49, float(r[1]) * 0.92)
		rr.size = Vector2(float(r[2]) * 2.49, float(r[3]) * 0.92)
		th.add_child(rr)
	var en := _label(m["en"], 11, Color(1, 1, 1, 0.8)); en.position = Vector2(8, 4); th.add_child(en)
	if not ready:
		var dim := ColorRect.new(); dim.color = Color(0, 0, 0, 0.55); dim.size = th.size
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE; th.add_child(dim)
		var soon := _label("제작 예정", 18, FG); soon.position = Vector2(84, 34); th.add_child(soon)
	var nm := _label(m["name"], 17, FG if ready else MUTED); nm.position = Vector2(12, 98); b.add_child(nm)
	var sz := _label(m["size"], 12, MUTED); sz.position = Vector2(140, 102); b.add_child(sz)
	var tg := _label(m["tag"], 12, SOFT if ready else MUTED); tg.position = Vector2(12, 124); b.add_child(tg)
	var mid: String = m["id"]
	b.disabled = not ready
	b.pressed.connect(func() -> void: Sfx.play("ui"); Controls.sel_map = mid; _refresh())
	return b

# ---- helpers ----
func _panel(pos: Vector2, sz: Vector2) -> Panel:
	var p := Panel.new(); p.position = pos; p.size = sz
	p.add_theme_stylebox_override("panel", _sb(PANEL, LINE, 1, 14))
	return p

func _btn(t: String, fs: int, pos: Vector2, sz: Vector2) -> Button:
	var b := Button.new(); b.text = t; b.focus_mode = Control.FOCUS_NONE
	b.position = pos; b.size = sz
	b.add_theme_font_size_override("font_size", fs)
	b.add_theme_color_override("font_color", FG)
	return b

func _label(txt: String, sz: int, col: Color) -> Label:
	var l := Label.new(); l.text = txt
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _sb(bg: Color, border: Color, bw: int, rad: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.set_border_width_all(bw); s.border_color = border
	s.set_corner_radius_all(rad)
	return s
