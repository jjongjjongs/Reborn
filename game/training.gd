extends Node3D
## 훈련 모드 (훈련장 v2): shooting range with paper / steel / moving targets, dummies that show
## damage numbers, an armory shelf (walk up, tap the centre button to swap), a timed kill house
## (blue civilian card = +3 s) and a timed movement course. Stats on the lobby board.

var player: PlayerBody
var cam: Camera3D
var _info := {}
var _lbl: Label
var _sub: Label
var _swap_btn: Button
var _swap_id := ""
var _timer_lbl: Label
var _rail_t: PopupTarget
var _kh: Array = []                 # kill house targets
var _kh_down := {}
var _kh_t := -1.0                   # running time (-1 = not running)
var _kh_pen := 0.0
var _kh_best := 0.0
var _co_t := -1.0
var _co_best := 0.0
var _board: Label3D
var _t := 0.0

func _ready() -> void:
	Controls.sel_map = "range"
	_info = MapBuilder.build("range", self)
	player = PlayerBody.new()
	player.position = _info.get("player", Vector3(0, 1.5, 0))
	add_child(player)
	player.rotation_degrees.y = 0.0
	cam = Camera3D.new(); cam.fov = 65.0; cam.current = true
	add_child(cam)
	_build_hud()
	Pause.arm()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_place()

func _target_at(p: Vector3, yaw := 0.0) -> PopupTarget:
	var t := PopupTarget.new(); add_child(t)
	t.global_position = p; t.rotation_degrees.y = yaw
	return t

func _place() -> void:
	for p in _info.get("range_targets", []): _target_at(p)
	var rail: Array = _info.get("rail", [])
	if rail.size() == 2: _rail_t = _target_at(rail[0])
	for pl in _info.get("plates", []):
		var sp := SteelPlate.new(); sp.radius = pl[1]; add_child(sp); sp.global_position = pl[0]
	var ds: Array = _info.get("dummies", [])
	for i in ds.size():
		var d := TrainingDummy.new(); d.mode = i; add_child(d); d.global_position = ds[i]
	for k in _info.get("kh_targets", []):
		_kh.append(_target_at(k[0], k[1]))
	if _info.has("kh_civ"):
		var c := CivilianCard.new(); add_child(c); c.global_position = _info["kh_civ"][0]
		c.shot.connect(func() -> void:
			if _kh_t >= 0.0: _kh_pen += 3.0; _flash_timer("민간인 사격 +3초"))
	if _info.has("board"):
		_board = Label3D.new(); _board.font_size = 40; _board.pixel_size = 0.01; _board.outline_size = 0
		_board.modulate = Color(0.85, 0.95, 1.0); _board.rotation_degrees.y = 180.0
		add_child(_board); _board.global_position = (_info["board"] as Vector3) + Vector3(0, 1.95, 0.45)

func _process(dt: float) -> void:
	if player: CamRig.follow(cam, player)
	_t += dt
	var acc := 100.0 * Controls.hits / maxf(Controls.shots, 1.0)
	if _lbl:
		_lbl.text = "명중 %d · 명중률 %d%% · 헤드샷 %d · 쓰러뜨림 %d" % [Controls.hits, roundi(acc) if Controls.shots > 0 else 0, Controls.headshots, Controls.kills]
	if _rail_t:
		var r: Array = _info["rail"]
		_rail_t.global_position = (r[0] as Vector3).lerp(r[1], 0.5 + 0.5 * sin(_t * 0.45))
	_armory()
	_killhouse(dt)
	_course(dt)
	if _board:
		_board.text = "오늘의 기록\n명중률 %s\n헤드샷 %d\n킬하우스 최고 %s\n이동 코스 최고 %s" % [
			("%d%%" % roundi(acc)) if Controls.shots > 0 else "-", Controls.headshots,
			("%.1f초" % _kh_best) if _kh_best > 0.0 else "-", ("%.1f초" % _co_best) if _co_best > 0.0 else "-"]

# ---- armory: walk up to a weapon on the shelf -> centre button swaps it in
func _armory() -> void:
	var best := ""; var bd := 1.3
	if player and player.alive:
		for a in _info.get("armory", []):
			var d := Vector2(player.global_position.x - a["pos"].x, player.global_position.z - a["pos"].z)
			if absf(d.x) < bd and absf(d.y) < 1.6: bd = absf(d.x); best = a["id"]
	if best != "" and best in Controls.loadout: best = ""            # already carrying it
	if best != _swap_id:
		_swap_id = best
		_swap_btn.visible = best != ""
		if best != "":
			var w := Weapons.get_w(best)
			_swap_btn.text = "%s로 교체\n%s · %s" % [w["name"], ["주무기", "보조무기", "근접"][int(w["slot"])], w["cls"]]

func _do_swap() -> void:
	if _swap_id == "": return
	var w := Weapons.get_w(_swap_id)
	var slot := int(w["slot"])
	Sfx.play("reload")
	Controls.loadout[slot] = _swap_id
	Controls.save_settings()
	player._ammo[_swap_id] = player._mag_of(_swap_id)
	player._equip(slot, true)
	_swap_id = ""; _swap_btn.visible = false

# ---- kill house: step on START, knock every target down, civilian = +3 s
func _killhouse(dt: float) -> void:
	if not _info.has("kh_start") or player == null: return
	var on_start := Vector2(player.global_position.x - _info["kh_start"].x, player.global_position.z - _info["kh_start"].z).length() < 1.2
	if _kh_t < 0.0:
		if on_start:
			_kh_t = 0.0; _kh_pen = 0.0; _kh_down.clear()
			for t in _kh: t.hp = PopupTarget.HP
			_flash_timer("킬하우스 시작!")
		return
	_kh_t += dt
	for t in _kh:
		if t._down_t > 0.0: _kh_down[t.get_instance_id()] = true
	_timer_lbl.text = "킬하우스 %.1f초  (%d / %d)%s" % [_kh_t + _kh_pen, _kh_down.size(), _kh.size(), ("  +%d초" % int(_kh_pen)) if _kh_pen > 0.0 else ""]
	_timer_lbl.visible = true
	if _kh_down.size() >= _kh.size():
		var total := _kh_t + _kh_pen
		var rec := _kh_best <= 0.0 or total < _kh_best
		if rec: _kh_best = total
		_kh_t = -1.0
		_flash_timer("킬하우스 완료 %.1f초%s" % [total, "  · 최고 기록!" if rec else ""], 4.0)

# ---- movement course: START pad -> finish pad on the high walkway
func _course(dt: float) -> void:
	if not _info.has("course_start") or player == null: return
	var p := player.global_position
	if _co_t < 0.0:
		if Vector2(p.x - _info["course_start"].x, p.z - _info["course_start"].z).length() < 0.9:
			_co_t = 0.0; _flash_timer("이동 코스 시작!")
		return
	_co_t += dt
	if _kh_t < 0.0:
		_timer_lbl.text = "이동 코스 %.1f초" % _co_t; _timer_lbl.visible = true
	var e: Vector3 = _info["course_end"]
	if Vector2(p.x - e.x, p.z - e.z).length() < 0.9 and p.y > e.y - 0.5:
		var rec := _co_best <= 0.0 or _co_t < _co_best
		if rec: _co_best = _co_t
		_flash_timer("이동 코스 완료 %.1f초%s" % [_co_t, "  · 최고 기록!" if rec else ""], 4.0)
		_co_t = -1.0
	elif _co_t > 90.0:
		_co_t = -1.0

var _msg_t := 0.0
func _flash_timer(msg: String, dur := 2.0) -> void:
	_timer_lbl.text = msg; _timer_lbl.visible = true; _msg_t = dur
	get_tree().create_timer(dur).timeout.connect(func() -> void:
		if _kh_t < 0.0 and _co_t < 0.0: _timer_lbl.visible = false)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var touch := TouchInput.new()
	touch.set_anchors_preset(Control.PRESET_FULL_RECT)
	touch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(touch)
	var cross := CrossHair.new()
	cross.set_anchors_preset(Control.PRESET_FULL_RECT)
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(cross)
	_lbl = Label.new()
	_lbl.add_theme_font_size_override("font_size", 30)
	_lbl.add_theme_color_override("font_color", Color(1.0, 0.72, 0.38))
	_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl.anchor_left = 0.0; _lbl.anchor_right = 1.0; _lbl.offset_top = 22
	_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_lbl)
	_sub = Label.new(); _sub.text = "무기 보관대에서 총 교체 · START 발판에서 기록 측정 · 나가기는 일시정지"
	_sub.add_theme_font_size_override("font_size", 17)
	_sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.anchor_left = 0.0; _sub.anchor_right = 1.0; _sub.offset_top = 62
	_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_sub)
	layer.add_child(Radar.new().setup(player, _info.get("bounds", Rect2(-30, -26, 60, 52))))
	_timer_lbl = Label.new(); _timer_lbl.add_theme_font_size_override("font_size", 34)
	_timer_lbl.add_theme_color_override("font_color", Color(0.55, 1.0, 0.6))
	_timer_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8)); _timer_lbl.add_theme_constant_override("outline_size", 8)
	_timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_lbl.anchor_left = 0.0; _timer_lbl.anchor_right = 1.0; _timer_lbl.offset_top = 96
	_timer_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE; _timer_lbl.visible = false
	layer.add_child(_timer_lbl)
	# centre swap prompt (armory)
	_swap_btn = Button.new(); _swap_btn.focus_mode = Control.FOCUS_NONE; _swap_btn.visible = false
	_swap_btn.add_theme_font_size_override("font_size", 28)
	var ssb := StyleBoxFlat.new(); ssb.bg_color = Color(0.06, 0.08, 0.10, 0.85); ssb.border_color = Color(1.0, 0.55, 0.15)
	ssb.set_border_width_all(3); ssb.set_corner_radius_all(18); ssb.set_content_margin_all(12)
	for k in ["normal", "hover", "pressed"]: _swap_btn.add_theme_stylebox_override(k, ssb)
	_swap_btn.anchor_left = 0.5; _swap_btn.anchor_right = 0.5; _swap_btn.anchor_top = 0.58; _swap_btn.anchor_bottom = 0.58
	_swap_btn.offset_left = -170; _swap_btn.offset_right = 170; _swap_btn.offset_top = 0; _swap_btn.offset_bottom = 104
	_swap_btn.pressed.connect(_do_swap)
	layer.add_child(_swap_btn)
	var panel := PrepLoadout.new().setup(self, "free"); layer.add_child(panel)
	var b := Button.new(); b.text = "  장비  "; b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 22)
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.06, 0.08, 0.10, 0.85); sb.border_color = Color(1.0, 0.48, 0.10)
	sb.set_border_width_all(2); sb.set_corner_radius_all(12); sb.set_content_margin_all(8)
	for k in ["normal", "hover", "pressed"]: b.add_theme_stylebox_override(k, sb)
	b.anchor_left = 1.0; b.anchor_right = 1.0; b.offset_left = -236; b.offset_right = -100; b.offset_top = 20; b.offset_bottom = 72
	b.pressed.connect(func() -> void: Sfx.play("ui"); panel.toggle())
	layer.add_child(b)
