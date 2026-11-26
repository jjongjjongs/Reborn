class_name RecordsScreen
extends Control
## 기록: career stats kept on this device (Profile) — totals, per mode, kills per
## weapon and the recent matches.

const ACCENT := Color(1.0, 0.48, 0.10)
const FG := Color(0.92, 0.95, 0.97)
const MUTED := Color(0.55, 0.62, 0.69)
const PANEL := Color(0.063, 0.082, 0.102)
const LINE := Color(0.133, 0.165, 0.196)

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
	back.pressed.connect(func() -> void: Sfx.play("ui"); queue_free())
	add_child(back)
	var t := _lbl("기록", 28, FG); t.position = Vector2(156, 14); add_child(t)
	var s := _lbl("이 기기에 저장된 전적 · 오프라인", 15, MUTED); s.position = Vector2(158, 60); add_child(s)

	var vs := get_viewport_rect().size
	var S := func(k: String) -> float: return Profile.stat(k)
	var matches: float = S.call("matches"); var wins: float = S.call("wins"); var kills: float = S.call("kill"); var deaths: float = S.call("deaths")
	var hits: float = S.call("hits"); var heads: float = S.call("headshot"); var secs: float = S.call("time")
	var tops := [["총 판수", "%d" % matches], ["승률", "%d%%" % roundi(100.0 * wins / matches) if matches > 0 else "—"],
		["처치", _num(kills)], ["K/D", "%.2f" % (kills / maxf(1.0, deaths))],
		["헤드샷 비율", "%d%%" % roundi(100.0 * heads / hits) if hits > 0 else "—"],
		["플레이 시간", "%d시간 %d분" % [int(secs / 3600.0), int(fmod(secs, 3600.0) / 60.0)]]]
	var top := HBoxContainer.new(); top.position = Vector2(28, 96); top.add_theme_constant_override("separation", 12); add_child(top)
	var cw := (vs.x - 56 - 12 * 5) / 6.0
	for st in tops:
		var p := PanelContainer.new(); p.custom_minimum_size = Vector2(cw, 96); p.add_theme_stylebox_override("panel", _sb(PANEL, LINE, 1, 14, 14))
		var v := VBoxContainer.new(); p.add_child(v); v.add_child(_lbl(st[0], 15, MUTED)); v.add_child(_lbl(st[1], 30, FG)); top.add_child(p)

	var y := 208.0; var h := vs.y - y - 20
	var w1 := (vs.x - 56 - 32) * 0.36; var w2 := (vs.x - 56 - 32) * 0.28; var w3 := (vs.x - 56 - 32) - w1 - w2
	# per mode
	var mp := _panel(Vector2(28, y), Vector2(w1, h))
	var mv := VBoxContainer.new(); mv.add_theme_constant_override("separation", 12); mp.add_child(mv)
	mv.add_child(_lbl("모드별", 20, FG))
	var modes := [
		["웨이브 서바이벌", "%d판 · 클리어 %d · 최고 웨이브 %d" % [S.call("m_웨이브 서바이벌"), S.call("w_웨이브 서바이벌"), maxf(S.call("best_wave"), Controls.best_wave)], "웨이브 서바이벌"],
		["데스매치", "%d판 · 1위 %d" % [S.call("m_데스매치"), S.call("w_데스매치")], "데스매치"],
		["팀 데스매치", "%d판 · 승리 %d" % [S.call("m_팀 데스매치"), S.call("w_팀 데스매치")], "팀 데스매치"],
		["폭파미션", "%d판 · 승리 %d · 설치 %d · 해체 %d" % [S.call("m_폭파미션"), S.call("w_폭파미션"), S.call("plant"), S.call("defuse")], "폭파미션"],
		["훈련", "쓰러뜨린 표적 %d" % S.call("target"), ""]]
	for r in modes:
		var hb := HBoxContainer.new(); hb.add_theme_constant_override("separation", 10)
		var a := _lbl(r[0], 18, FG); a.custom_minimum_size = Vector2(160, 0); hb.add_child(a)
		var b := _lbl(r[1], 15, MUTED); b.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hb.add_child(b)
		if r[2] != "":
			var m: float = S.call("m_" + r[2])
			var bar := ProgressBar.new(); bar.max_value = 1; bar.value = S.call("w_" + r[2]) / m if m > 0 else 0.0
			bar.show_percentage = false; bar.custom_minimum_size = Vector2(70, 8); bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			bar.add_theme_stylebox_override("background", _sb(Color(0.15, 0.18, 0.21), Color(0, 0, 0, 0), 0, 4, 0))
			bar.add_theme_stylebox_override("fill", _sb(ACCENT, ACCENT, 0, 4, 0)); hb.add_child(bar)
		mv.add_child(hb)
	# kills per weapon
	var wp := _panel(Vector2(28 + w1 + 16, y), Vector2(w2, h))
	var wv := VBoxContainer.new(); wv.add_theme_constant_override("separation", 8); wp.add_child(wv)
	wv.add_child(_lbl("무기별 처치", 20, FG))
	var rows := []
	for id in Weapons.ORDER_PRIMARY + Weapons.ORDER_SECONDARY + Weapons.ORDER_MELEE:
		rows.append([Weapons.get_w(id)["name"], S.call("k_" + id)])
	rows.sort_custom(func(a, b): return a[1] > b[1])
	var mx: float = maxf(1.0, rows[0][1])
	for r in rows:
		var hb := HBoxContainer.new(); var a := _lbl(r[0], 16, FG); a.custom_minimum_size = Vector2(110, 0); hb.add_child(a)
		var bar := ColorRect.new(); bar.color = ACCENT if r[1] > 0 else LINE
		bar.custom_minimum_size = Vector2(maxf(4.0, (w2 - 200) * r[1] / mx), 12); bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER; hb.add_child(bar)
		hb.add_child(_lbl("  %d" % r[1], 15, MUTED)); wv.add_child(hb)
	# recent matches
	var rp := _panel(Vector2(28 + w1 + w2 + 32, y), Vector2(w3, h))
	var sc := ScrollContainer.new(); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; rp.add_child(sc)
	var rv := VBoxContainer.new(); rv.add_theme_constant_override("separation", 6); rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL; sc.add_child(rv)
	rv.add_child(_lbl("최근 경기", 20, FG))
	var rec := Profile.recent()
	if rec.is_empty():
		rv.add_child(_lbl("아직 기록이 없습니다", 16, MUTED))
	for r in rec:
		var hb := HBoxContainer.new(); hb.add_theme_constant_override("separation", 10)
		var tag := PanelContainer.new()
		tag.add_theme_stylebox_override("panel", _sb(Color(0.13, 0.30, 0.20) if r.get("win", false) else Color(0.32, 0.13, 0.12), Color(0, 0, 0, 0), 0, 6, 4))
		var tl := _lbl(String(r.get("tag", "")), 14, FG); tl.custom_minimum_size = Vector2(46, 0); tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.add_child(tl); hb.add_child(tag)
		var a := _lbl("%s · %s" % [r.get("mode", ""), r.get("map", "")], 16, FG); a.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hb.add_child(a)
		hb.add_child(_lbl(String(r.get("result", "")), 14, MUTED)); rv.add_child(hb)

func _num(v: float) -> String:
	var s := str(int(v))
	var out := ""
	for i in s.length():
		if i > 0 and (s.length() - i) % 3 == 0: out += ","
		out += s[i]
	return out
