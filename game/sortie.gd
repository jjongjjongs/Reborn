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
	{"id": "quarter", "plan": "oldquarter", "name": "구도심", "en": "OLD QUARTER", "size": "132×120m", "tag": "지하 통로 · 발코니 · 중앙 고지대", "ready": true, "ground": Color("2a2d31")},
	{"id": "dockside", "plan": "dockside", "name": "항만 창고", "en": "DOCKSIDE", "size": "130×115m", "tag": "창고 마당 A · 부두 B · 배수로", "ready": true, "ground": Color("2a2d31")},
	{"id": "temple", "name": "산사", "en": "MOUNTAIN TEMPLE", "size": "140×120m", "tag": "경회루 B · 대웅전 A · 계곡 · 석굴",
		"rects": [[20, 4, 40, 36, "1d4a63"], [45, 18, 45, 36, "d6cfbf"], [18, 52, 70, 26, "b5ab92"], [36, 76, 34, 16, "8c8678"], [58, 30, 10, 8, "ff7a1a"], [16, 18, 18, 14, "f2c14e"]],
		"ready": true, "ground": Color("31402c")},
	{"id": "facility", "plan": "facility", "name": "연구 시설", "en": "FACILITY", "size": "130×115m", "tag": "반응로실 A · 하역장 B · 실내 복도", "ready": true, "ground": Color("2a2d31")},
]
const MAPS := [
	{"id": "downtown", "plan": "downtown_v3", "name": "다운타운", "en": "DOWNTOWN", "size": "82×67m · 6–12명", "tag": "주차 데크 · 실내 로비 · 지하철 터널", "ready": true, "ground": Color("2a2d31")},
	{"id": "bazaar", "plan": "bazaar_v3", "name": "사막 시장", "en": "BAZAAR", "size": "82×67m · 6–12명", "tag": "덮인 시장 · 분수 광장 테라스 · 수로", "ready": true, "ground": Color("3a3226")},
	{"id": "cell", "plan": "cell_v3", "name": "교도소", "en": "CELLBLOCK", "size": "82×67m · 6–12명", "tag": "감방 복도 · 감시탑 운동장 · 탈옥 터널", "ready": true, "ground": Color("2a2e33")},
	{"id": "snipe", "plan": "snipe", "name": "협곡 전초기지", "en": "CANYON OUTPOST · 스나전", "size": "106×72m", "tag": "스나전 · 저격총만 · 발코니 · 능선 · 터널", "ready": true, "ground": Color("3a3226")},
	{"id": "harbor", "plan": "harbor_v3", "name": "컨테이너 항구", "en": "HARBOR", "size": "82×67m · 6–12명", "tag": "창고 실내 · 컨테이너 야적장 · 크레인 부두", "ready": true, "ground": Color("263038")},
]
const ZOMBIE_MAPS := [
	{"id": "reststop", "plan": "zombie_reststop", "name": "폐휴게소", "en": "REST STOP", "size": "64×56m · 좀비 전용", "tag": "편의점 농성 · 주유소 지붕 · 모텔 · 주차장 순환로", "ready": true, "ground": Color("2b2a2e")},
]
const TRAIN_MAPS := [
	{"id": "range", "name": "훈련장", "en": "TRAINING", "size": "64×54m · 혼자", "tag": "사격장 · 더미 · 무기 보관대 · 킬하우스 · 이동 코스",
		"rects": [[27, 2, 46, 48, "8c8678"], [27, 54, 46, 17, "5f5a52"], [2, 22, 26, 34, "b9b2a6"], [74, 20, 22, 30, "b9b2a6"], [74, 60, 22, 22, "a09a8c"], [32, 88, 36, 8, "f05a52"]], "ready": true, "ground": Color("2a2d31")},
]
const MINI_MAPS := [
	{"id": "jump1", "name": "구름 계단", "en": "CLOUD STEPS", "size": "5 스테이지 · 혼자", "tag": "기초 점프 · 좁은 길 · 움직이는 발판 · 사라지는 발판 · 정상 탑",
		"rects": [[44, 88, 12, 12, "e9e4d8"], [42, 64, 16, 22, "ff9a3c"], [40, 44, 22, 18, "3cc6c0"], [38, 26, 24, 16, "9b6cf0"], [40, 10, 20, 14, "ffd23c"], [44, 0, 12, 9, "ffc83a"]], "ready": true, "ground": Color("9cc4ee")},
]
const KIND_COL := {"street": "8c8678", "plaza": "b9b2a6", "siteA": "ff7a1a", "siteB": "f2c14e", "att": "f05a52", "def": "56a8ff",
	"room": "5f5a52", "tunnel": "1d4a63", "water": "1d4a63"}

static func map_name(id: String) -> String:
	for m in BOMB_MAPS + MAPS + TRAIN_MAPS + ZOMBIE_MAPS + MINI_MAPS:
		if m["id"] == id: return m["name"]
	return id

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
var _view_btns: Array = []   # [1인칭, 3인칭]
var _count_box: HBoxContainer
var _wave_box: HBoxContainer
var _wave_info: Panel

func setup(t: String, sub: String, sc: String, k: String) -> SortieScreen:
	title = t; subtitle = sub; scene = sc; kind = k
	return self

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new(); bg.color = Color(0.043, 0.055, 0.071)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	if not _map_ready(Controls.sel_map): Controls.sel_map = {"bomb": "quarter", "training": "range", "survival": "reststop", "minigame": "jump1"}.get(kind, "downtown")

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
	# maps scroll inside their own box (above the 인원 row when there is one)
	var msc := ScrollContainer.new(); msc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	msc.position = Vector2(16, 48)
	msc.size = Vector2(548 - 16 - 8, (col_h - 48 - 130) if kind in ["team", "bomb", "dm"] else (180.0 if kind == "survival" else col_h - 60))
	ShopScreen.fat_scrollbar(msc)
	c1.add_child(msc)
	_map_box = GridContainer.new(); _map_box.columns = 2
	_map_box.add_theme_constant_override("h_separation", 10)
	_map_box.add_theme_constant_override("v_separation", 10)
	msc.add_child(_map_box)
	# players: 팀전 / 폭파 3v3..6v6, 데스매치 6..12 (fewer = lighter on the phone)
	if kind in ["team", "bomb", "dm"]:
		var hl := _label("인원", 20, FG); hl.position = Vector2(16, col_h - 118); c1.add_child(hl)
		var hs := _label("인원이 많으면 폰이 무거워질 수 있어요", 13, MUTED); hs.position = Vector2(70, col_h - 112); c1.add_child(hs)
		_count_box = HBoxContainer.new(); _count_box.position = Vector2(16, col_h - 84); _count_box.add_theme_constant_override("separation", 10)
		c1.add_child(_count_box)

	# survival: how many waves (5 / 10 / 15 / endless) and what it pays
	if kind == "survival":
		_wave_info = Panel.new(); _wave_info.add_theme_stylebox_override("panel", _sb(CARD, LINE2, 1, 10))
		_wave_info.position = Vector2(16, 236); _wave_info.size = Vector2(516, 150); c1.add_child(_wave_info)
		var wl := _label("웨이브", 20, FG); wl.position = Vector2(16, col_h - 118); c1.add_child(wl)
		var ws := _label("길수록 좀비가 많고 강해져요", 13, MUTED); ws.position = Vector2(90, col_h - 112); c1.add_child(ws)
		_wave_box = HBoxContainer.new(); _wave_box.position = Vector2(16, col_h - 84); _wave_box.add_theme_constant_override("separation", 10)
		c1.add_child(_wave_box)

	var c2 := _panel(Vector2(592, col_y), Vector2(300, col_h)); add_child(c2)
	var h2 := _label({"survival": "좀비 강도", "training": "훈련 안내", "minigame": "코스 안내"}.get(kind, "봇 난이도"), 20, FG); h2.position = Vector2(16, 12); c2.add_child(h2)
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
	c3.visible = kind != "minigame"          # no weapons in the minigames
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

	# view: first / third person (remembered, applies to every mode)
	var vbox := HBoxContainer.new(); vbox.add_theme_constant_override("separation", 8)
	vbox.anchor_left = 0.5; vbox.anchor_right = 0.5; vbox.anchor_top = 1.0; vbox.anchor_bottom = 1.0
	vbox.offset_left = -250; vbox.offset_right = 200; vbox.offset_top = -84; vbox.offset_bottom = -24
	var vl := _label("시점", 20, MUTED); vl.custom_minimum_size = Vector2(56, 0)
	vl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; vbox.add_child(vl)
	for t in [["1인칭", true, "총구 시점 · 몰입"], ["3인칭", false, "어깨 너머 · 시야 넓음"]]:
		var b := Button.new(); b.focus_mode = Control.FOCUS_NONE; b.custom_minimum_size = Vector2(180, 60)
		var l1 := _label(t[0], 20, FG); l1.position = Vector2(14, 4); l1.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(l1)
		var l2 := _label(t[2], 13, SOFT); l2.position = Vector2(14, 32); l2.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(l2)
		var fp: bool = t[1]
		b.pressed.connect(func() -> void: Sfx.play("ui"); Controls.view_fp = fp; _refresh())
		vbox.add_child(b); _view_btns.append(b)
	add_child(vbox)
	_refresh()

func _launch() -> void:
	Sfx.play("ui")
	Controls.save_settings()
	Controls.reset()
	get_tree().change_scene_to_file(scene)

func _maps() -> Array:
	if kind == "training": return TRAIN_MAPS
	if kind == "minigame": return MINI_MAPS
	if kind == "survival": return ZOMBIE_MAPS
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
	# difficulty (training: what the range offers instead)
	for c in _diff_box.get_children(): c.queue_free()
	for c in _detail.get_children(): c.queue_free()
	if kind == "minigame":
		for r in [["5 스테이지", "기초 → 좁은 길 → 이동 → 사라짐 → 탑"], ["체크포인트", "초록 발판 · 떨어지면 여기서 다시"], ["발판 색", "보라 이동 · 파랑 점프대 · 노랑 사라짐"],
				["기록", "출발 발판을 떠나면 시작 · 최고 기록 저장"], ["완주 보상", "◆30 · 첫 완주 +50 · 최고 기록 경신 +20"]]:
			var card := Panel.new(); card.custom_minimum_size = Vector2(268, 64)
			card.add_theme_stylebox_override("panel", _sb(CARD, LINE2, 1, 10))
			var n := _label(r[0], 18, FG); n.position = Vector2(14, 6); card.add_child(n)
			var sh := _label(r[1], 13, SOFT); sh.position = Vector2(14, 36); card.add_child(sh)
			_diff_box.add_child(card)
	if kind == "training":
		for r in [["사격장", "10–30m 종이 표적 · 철판 · 이동 표적"], ["더미 구역", "피해 숫자 · 정지 / 좌우 이동 / 앉음"], ["무기 보관대", "다가가서 버튼으로 바로 교체"],
				["킬하우스 · 이동 코스", "START 발판부터 기록 측정"]]:
			var card := Panel.new(); card.custom_minimum_size = Vector2(268, 64)
			card.add_theme_stylebox_override("panel", _sb(CARD, LINE2, 1, 10))
			var n := _label(r[0], 18, FG); n.position = Vector2(14, 6); card.add_child(n)
			var sh := _label(r[1], 13, SOFT); sh.position = Vector2(14, 36); card.add_child(sh)
			_diff_box.add_child(card)
		for r in [["표적 체력", "100"], ["헤드샷", "머리 부분"], ["민간인 사격", "+3초"], ["나가기", "일시정지 메뉴"]]:
			var a := _label(r[0], 14, MUTED); a.custom_minimum_size = Vector2(134, 0); _detail.add_child(a)
			var v := _label(r[1], 14, FG); v.custom_minimum_size = Vector2(134, 0)
			v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; _detail.add_child(v)
	var surv := kind == "survival"
	for id in (Difficulty.IDS if not kind in ["training", "minigame"] else []):
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
	var cd := Difficulty.cur()
	var rows := []
	if kind in ["training", "minigame"]:
		pass
	elif surv:
		rows = [["좀비 체력", "×%.2f" % cd["z_hp"]], ["좀비 공격력", "×%.2f" % cd["z_dmg"]], ["좀비 속도", "×%.2f" % cd["z_spd"]]]
	else:
		rows = [["반응 속도", "%.2f초" % cd["react"]], ["명중 퍼짐", "%.1f°" % cd["spread"]],
			["봇 화력", "%d%%" % roundi(cd["dmg"] * 100.0)], ["수류탄·칼", cd["tactics_txt"]]]
	for r in rows:
		var a := _label(r[0], 14, MUTED); a.custom_minimum_size = Vector2(134, 0); _detail.add_child(a)
		var v := _label(r[1], 14, FG); v.custom_minimum_size = Vector2(134, 0)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; _detail.add_child(v)
	# player count
	if _count_box:
		for c in _count_box.get_children(): c.queue_free()
		var opts := [6, 8, 10, 12] if kind == "dm" else [3, 4, 5, 6]
		for n in opts:
			var on: bool = n == (Controls.dm_count if kind == "dm" else Controls.team_size)
			var b := Button.new(); b.focus_mode = Control.FOCUS_NONE; b.custom_minimum_size = Vector2(120, 60)
			b.text = ("%d명" % n) if kind == "dm" else ("%d vs %d" % [n, n])
			b.add_theme_font_size_override("font_size", 20)
			b.add_theme_color_override("font_color", FG)
			for k in ["normal", "hover", "pressed"]: b.add_theme_stylebox_override(k, _sb(SEL_BG if on else CARD, ACCENT if on else LINE2, 2 if on else 1, 10))
			var nn: int = n
			b.pressed.connect(func() -> void:
				Sfx.play("ui")
				if kind == "dm": Controls.dm_count = nn
				else: Controls.team_size = nn
				_refresh())
			_count_box.add_child(b)
	if _wave_box: _refresh_waves()
	# view toggle
	for i in _view_btns.size():
		var on: bool = (i == 0) == Controls.view_fp
		for k in ["normal", "hover", "pressed"]:
			(_view_btns[i] as Button).add_theme_stylebox_override(k, _sb(SEL_BG if on else CARD, ACCENT if on else LINE2, 2 if on else 1, 10))
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
	var who := "혼자 · 5 스테이지 · 기록 도전" if kind == "minigame" else "혼자 · 사격장 · 더미 · 기록 측정" if kind == "training" else ("무한 웨이브" if Controls.wave_mode == 0 else "%d 웨이브" % Controls.wave_mode) if surv else ("%d vs %d" % [Controls.team_size, Controls.team_size] if kind == "team" else ("%d vs %d · 7승" % [Controls.team_size, Controls.team_size] if kind == "bomb" else "개인전 %d명" % Controls.dm_count))
	_summary.text = ("%s · %s" % [mname, who]) if kind in ["training", "minigame"] else ("%s · %s · %s" % [mname, Difficulty.cur()["name"], who])

const GOLD := Color("ffd166")
func _refresh_waves() -> void:
	for c in _wave_box.get_children(): c.queue_free()
	for c in _wave_info.get_children(): c.queue_free()
	for wm in Controls.WAVE_MODES:
		var on: bool = wm == Controls.wave_mode
		var b := Button.new(); b.focus_mode = Control.FOCUS_NONE; b.custom_minimum_size = Vector2(118, 64)
		for k in ["normal", "hover", "pressed"]: b.add_theme_stylebox_override(k, _sb(SEL_BG if on else CARD, ACCENT if on else LINE2, 2 if on else 1, 10))
		var n := _label("무한" if wm == 0 else "%d 웨이브" % wm, 18, FG); n.position = Vector2(12, 6); b.add_child(n)
		var r := _label("15 이후 +40↑" if wm == 0 else "◆%d" % Controls.wave_reward(wm, wm, 9999, true), 13, GOLD); r.position = Vector2(12, 36); b.add_child(r)
		var ww: int = wm
		b.pressed.connect(func() -> void: Sfx.play("ui"); Controls.wave_mode = ww; _refresh())
		_wave_box.add_child(b)
	var wm2: int = Controls.wave_mode
	var rows: Array
	if wm2 == 0:
		rows = [["1–15 웨이브", "15 웨이브 모드와 같음 (최대 ◆%d)" % Controls.wave_reward(15, 15, 9999, true)], ["16 웨이브부터", "웨이브마다 +40, 매 웨이브 +5씩 증가"],
			["20·25·30…", "5웨이브마다 +100"], ["예) 20 웨이브 클리어", "◆%d" % Controls.wave_reward(0, 20, 9999, false)]]
	else:
		rows = [["웨이브 클리어", "웨이브마다 +12"], ["처치", "+1 · 최대 %d" % (wm2 * 8)], ["완주 보너스", "+%d" % int(Controls.WAVE_CLEAR_BONUS[wm2])],
			["완주 시 최대", "◆%d" % Controls.wave_reward(wm2, wm2, 9999, true)]]
	var t := _label("보상  ·  " + ("끝까지 버티기" if wm2 == 0 else "중간에 쓰러지면 완주 보너스 없음"), 16, FG); t.position = Vector2(14, 10); _wave_info.add_child(t)
	for i in rows.size():
		var a := _label(rows[i][0], 14, MUTED); a.position = Vector2(14, 42 + i * 26); _wave_info.add_child(a)
		var v := _label(rows[i][1], 14, GOLD if i == 3 else FG); v.position = Vector2(170, 42 + i * 26); _wave_info.add_child(v)

func _map_card(m: Dictionary) -> Button:
	var on: bool = m["id"] == Controls.sel_map
	var ready: bool = m["ready"]
	var b := Button.new(); b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(240, 162)
	for k in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(k, _sb(SEL_BG if on else CARD, ACCENT if on else LINE2, 2 if on else 1, 12))
	var th := ColorRect.new(); th.color = m["ground"]
	th.position = Vector2(2, 2); th.size = Vector2(236, 92); th.mouse_filter = Control.MOUSE_FILTER_IGNORE
	th.clip_contents = true
	b.add_child(th)
	for r in _thumb_rects(m):
		var rr := ColorRect.new(); rr.color = Color(str(r[4])); rr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rr.position = Vector2(float(r[0]) * 2.36, float(r[1]) * 0.92)
		rr.size = Vector2(float(r[2]) * 2.36, float(r[3]) * 0.92)
		th.add_child(rr)
	var en := _label(m["en"], 11, Color(1, 1, 1, 0.8)); en.position = Vector2(8, 4); th.add_child(en)
	if not ready:
		var dim := ColorRect.new(); dim.color = Color(0, 0, 0, 0.55); dim.size = th.size
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE; th.add_child(dim)
		var soon := _label("제작 예정", 18, FG); soon.position = Vector2(84, 34); th.add_child(soon)
	var nm := _label(m["name"], 17, FG if ready else MUTED); nm.position = Vector2(12, 98); b.add_child(nm)
	var sz := _label(m["size"], 12 if String(m["size"]).length() <= 12 else 11, MUTED); sz.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sz.custom_minimum_size = Vector2(120, 0); b.add_child(sz); sz.position = Vector2(110, 102)
	# tag line: wraps to a second line inside the card (it used to run past the card's edge)
	var tg := _label(_wrap_dots(String(m["tag"]), 12, 216.0), 12, SOFT if ready else MUTED)
	b.add_child(tg); tg.position = Vector2(12, 121)
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

## too long for one line: break at the last " · " that still fits (Godot would split a Korean word mid-syllable)
func _wrap_dots(t: String, sz: int, w: float) -> String:
	var f: Font = ThemeDB.fallback_font
	if f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x <= w: return t
	var parts := t.split(" · "); var line := ""
	for i in parts.size():
		var nxt := parts[i] if line == "" else line + " · " + parts[i]
		if line != "" and f.get_string_size(nxt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > w:
			return line + " ·\n" + " · ".join(parts.slice(i))
		line = nxt
	return t

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
