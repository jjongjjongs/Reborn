extends SceneTree
## 시안: wave count picker (5 / 10 / 15 / 무한) + rewards on the survival sortie screen (mock overlay only)
const ACCENT := Color("ff8a1f"); const FG := Color(0.94, 0.94, 0.95); const MUTED := Color(0.6, 0.62, 0.66); const SOFT := Color(0.78, 0.8, 0.83)
const CARD := Color(0.09, 0.1, 0.12); const SEL := Color(0.16, 0.1, 0.05); const LINE := Color(0.22, 0.24, 0.28); const GOLD := Color("ffd166")
func _sb(bg: Color, bd: Color, w: int, r: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color = bg; s.border_color = bd; s.set_border_width_all(w); s.set_corner_radius_all(r); return s
func _l(t: String, sz: int, c: Color) -> Label:
	var l := Label.new(); l.text = t; l.add_theme_font_size_override("font_size", sz); l.add_theme_color_override("font_color", c); return l
func _initialize() -> void: _run()
func _mock(s: Node, sel: int) -> Control:
	var root_c := Control.new(); root_c.set_anchors_preset(Control.PRESET_FULL_RECT); root_c.mouse_filter = Control.MOUSE_FILTER_IGNORE; s.add_child(root_c)
	var c1 := Vector2(28, 84)
	# reward breakdown (in the map column, under the map list)
	var box := Panel.new(); box.add_theme_stylebox_override("panel", _sb(CARD, LINE, 1, 10)); box.position = c1 + Vector2(16, 236); box.size = Vector2(516, 150); root_c.add_child(box)
	var rows: Array = [
		[["웨이브 클리어", "웨이브마다 +12"], ["처치", "+1 · 최대 40"], ["완주 보너스", "+60"], ["완주 시 최대", "◆160"]],
		[["웨이브 클리어", "웨이브마다 +12"], ["처치", "+1 · 최대 80"], ["완주 보너스", "+150"], ["완주 시 최대", "◆350"]],
		[["웨이브 클리어", "웨이브마다 +12"], ["처치", "+1 · 최대 120"], ["완주 보너스", "+300"], ["완주 시 최대", "◆600"]],
		[["1–15 웨이브", "15 웨이브 모드와 같음 (최대 ◆600)"], ["16 웨이브부터", "웨이브마다 +40, 매 웨이브 +5씩 증가"], ["20·25·30…", "5웨이브마다 +100"], ["예) 20 웨이브 클리어", "◆1,000"]]][sel]
	var t := _l("보상" + ("  ·  끝까지 버티기" if sel == 3 else "  ·  중간에 쓰러지면 완주 보너스 없음"), 16, FG); t.position = Vector2(14, 10); box.add_child(t)
	for i in rows.size():
		var a := _l(rows[i][0], 14, MUTED); a.position = Vector2(14, 42 + i * 26); box.add_child(a)
		var v := _l(rows[i][1], 14, GOLD if i == 3 else FG); v.position = Vector2(170, 42 + i * 26); box.add_child(v)
	# wave picker row (same place as the 인원 row in team modes)
	var hl := _l("웨이브", 20, FG); hl.position = c1 + Vector2(16, 520 - 118); root_c.add_child(hl)
	var hs := _l("길수록 좀비가 많고 강해져요", 13, MUTED); hs.position = c1 + Vector2(90, 520 - 112); root_c.add_child(hs)
	var opts := [["5", "◆160"], ["10", "◆350"], ["15", "◆600"], ["무한", "15 이후 +40↑"]]
	for i in 4:
		var b := Panel.new(); b.add_theme_stylebox_override("panel", _sb(SEL if i == sel else CARD, ACCENT if i == sel else LINE, 2 if i == sel else 1, 10))
		b.position = c1 + Vector2(16 + i * 128, 520 - 84); b.size = Vector2(118, 64); root_c.add_child(b)
		var n := _l(opts[i][0] + (" 웨이브" if i < 3 else ""), 18, FG); n.position = Vector2(12, 6); b.add_child(n)
		var r := _l(opts[i][1], 13, GOLD); r.position = Vector2(12, 36); b.add_child(r)
	return root_c
func _run() -> void:
	var C = root.get_node("Controls")
	change_scene_to_file("res://Menu.tscn")
	for i in 20: await process_frame
	var s = load("res://sortie.gd").new().setup("웨이브 서바이벌", "PvE · 좀비 방어", "res://Main.tscn", "survival")
	current_scene.add_child(s)
	C.bot_diff = "veteran"; s._refresh()
	for sel in [1, 3]:
		var m := _mock(s, sel)
		var sum: Label = null
		for l in s.find_children("*", "Label", true, false):
			if (l as Label).text.ends_with("웨이브 5"): sum = l
		if sum: sum.text = sum.text.replace("웨이브 5", ["5 웨이브", "10 웨이브", "15 웨이브", "무한 웨이브"][sel])
		for i in 20: await process_frame
		root.get_viewport().get_texture().get_image().save_png("/tmp/wavemock_%d.png" % sel)
		m.queue_free()
		if sum: sum.text = sum.text.replace(["5 웨이브", "10 웨이브", "15 웨이브", "무한 웨이브"][sel], "웨이브 5")
	var j = load("res://sortie.gd").new().setup("미니게임", "점프맵 · 기록 도전", "res://JumpMap.tscn", "minigame")
	s.queue_free(); current_scene.add_child(j)
	for i in 20: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/jumpsortie.png")
	quit()
