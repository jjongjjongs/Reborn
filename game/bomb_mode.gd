extends Node3D
## Bomb defusal (폭파미션): 5 vs 5 rounds. Attackers carry one bomb, plant it on
## site A or B (hold 3 s inside the marked area); it explodes 40 s later unless a
## defender defuses it (hold 6 s next to it). No respawn within a round. 7 round
## wins take the match; sides swap after round 6. Red = the player's team.

const ROUND_TIME := 105.0
const PREP := 5.0
const PLANT := 3.0
const FUSE := 40.0
const DEFUSE := 6.0
const WIN := 7
const HALF := 6
const END_DELAY := 4.0
const TEAM_SIZE := 5
const BLAST_R := 14.0
const RED := 0
const BLUE := 1

var player: PlayerBody
var cam: Camera3D
var info := {}
var bots: Array = []
var att_team := RED
var score := [0, 0]
var round_no := 0
var state := "prep"          # prep / live / end / over
var t := 0.0
var bomb_state := "carried"  # carried (every attacker has one) / planted / gone
var carrier: Node3D = null
var bomb_pos := Vector3.ZERO
var bomb_t := 0.0
var plant_prog := 0.0
var defuse_prog := 0.0
var defuser: Node3D = null
var plan_site := "A"
var _bomb_vis: Node3D
var _bomb_light: OmniLight3D
var _bomb_tag: Label3D
var _spec: Node3D = null
# hud
var _hp_fill: ColorRect
var _score_lbl: Label
var _time_lbl: Label
var _alive_lbl: Label
var _banner: Label
var _carry_lbl: Label
var _result: Control
var _banner_t := 0.0

func _ready() -> void:
	if not Controls.sel_map in ["quarter", "dockside", "facility", "oldtown"]:
		Controls.sel_map = "quarter"
	info = MapBuilder.build(Controls.sel_map, self)
	player = PlayerBody.new()
	player.team = RED
	player.position = (info["att"] as Array)[0]
	player.died.connect(_on_died.bind(player))
	add_child(player)
	cam = Camera3D.new(); cam.fov = 65.0; cam.current = true
	add_child(cam)
	_build_bomb()
	_build_hud()
	Pause.arm()
	await get_tree().physics_frame
	await get_tree().physics_frame
	for i in TEAM_SIZE - 1:
		_make_bot(RED, "아군 %d" % (i + 1), Color(0.86, 0.40, 0.33))
	for i in TEAM_SIZE:
		_make_bot(BLUE, "적군 %d" % (i + 1), Color(0.33, 0.55, 0.88))
	await get_tree().physics_frame
	_start_round()

func _make_bot(team: int, nm: String, tint: Color) -> void:
	var b := BotPlayer.new()
	b.team = team; b.bot_name = nm; b.tint = tint
	b.engage_range = 22.0
	b.position = Vector3(randf_range(-3, 3), 1, randf_range(-3, 3))
	b.died.connect(_on_died.bind(b))
	add_child(b)
	bots.append(b)

# ---------------------------------------------------------------- round flow
func _members(team: int) -> Array:
	var out: Array = []
	if team == RED: out.append(player)
	for b in bots:
		if b.team == team: out.append(b)
	return out

func _alive(team: int) -> Array:
	return _members(team).filter(func(n): return n.alive)

func _start_round() -> void:
	round_no += 1
	state = "prep"; t = PREP
	bomb_state = "carried"; plant_prog = 0.0; defuse_prog = 0.0; defuser = null
	_bomb_vis.visible = false; _bomb_tag.visible = false; _bomb_light.visible = false
	var def_team := 1 - att_team
	var att_sp: Array = info["att"]; var def_sp: Array = info["def"]
	var k := 0
	for n in _members(att_team):
		n.respawn_at(att_sp[k % att_sp.size()]); k += 1
	k = 0
	for n in _members(def_team):
		n.respawn_at(def_sp[k % def_sp.size()]); k += 1
	for n in _members(RED) + _members(BLUE):
		n.invuln_t = 0.0; n.visible = true
		if n is BotPlayer:
			n.frozen = true; n.busy = false
		else:
			n.frozen = true
	carrier = null
	plan_site = "A" if randf() < 0.5 else "B"
	_assign_objectives()
	var role := "공격" if att_team == RED else "수비"
	_show_banner("라운드 %d · %s" % [round_no, role], PREP)

func _go_live() -> void:
	state = "live"; t = ROUND_TIME
	for n in _members(RED) + _members(BLUE):
		n.frozen = false

func _end_round(winner: int, why: String) -> void:
	if state == "end" or state == "over": return
	state = "end"; t = END_DELAY
	score[winner] += 1
	for b in bots: b.busy = false
	Controls.act_label = ""; Controls.act_progress = 0.0
	var who := "레드" if winner == RED else "블루"
	_show_banner("%s 승리 — %s" % [who, why], END_DELAY)
	Sfx.play("ui")

func _next() -> void:
	if score[RED] >= WIN or score[BLUE] >= WIN:
		_end_match(); return
	if round_no == HALF:
		att_team = 1 - att_team
		_show_banner("공수 교대!", 2.0)
	_start_round()

# ---------------------------------------------------------------- per frame
func _process(dt: float) -> void:
	_camera()
	_hud(dt)
	if state == "over": return
	t -= minf(dt, 0.1)        # a loading hitch must not eat the prep time
	match state:
		"prep":
			if t <= 0.0: _go_live()
		"end":
			if t <= 0.0: _next()
		"live":
			_live(dt)

func _live(dt: float) -> void:
	var def_team := 1 - att_team
	# plant: every attacker carries a bomb; the first one planted counts
	Controls.act_label = ""
	if bomb_state == "carried":
		if carrier != null and (not carrier.alive or _site_at(carrier.global_position) == ""):
			if carrier is BotPlayer: carrier.busy = false
			carrier = null; plant_prog = 0.0
		if player.alive and player.team == att_team and _site_at(player.global_position) != "":
			Controls.act_label = "설치"
			if Controls.act_held and Controls.move.length() < 0.2:
				if carrier != player:
					if carrier is BotPlayer: carrier.busy = false
					carrier = player; plant_prog = 0.0
				plant_prog += dt / PLANT
			elif carrier == player:
				carrier = null; plant_prog = 0.0
		if carrier == null:
			for b in bots:
				if b.alive and b.team == att_team and _site_at(b.global_position) != "" and not _enemy_near(b, 10.0):
					carrier = b; b.busy = true; plant_prog = 0.0; break
		elif carrier is BotPlayer:
			plant_prog += dt / PLANT
		if carrier != null and plant_prog >= 1.0:
			_plant(_site_at(carrier.global_position))
	# defuse
	if bomb_state == "planted":
		bomb_t -= dt
		_bomb_light.visible = fmod(bomb_t, 1.0 if bomb_t > 10.0 else 0.35) < 0.15
		if defuser != null and (not defuser.alive or defuser.global_position.distance_to(bomb_pos) > 2.0):
			if defuser is BotPlayer: defuser.busy = false
			defuser = null; defuse_prog = 0.0
		if player.alive and player.team == def_team and player.global_position.distance_to(bomb_pos) < 1.8:
			Controls.act_label = "해체"
			if Controls.act_held and Controls.move.length() < 0.2:
				defuser = player; defuse_prog += dt / DEFUSE
			elif defuser == player:
				defuser = null; defuse_prog = 0.0
		if defuser == null:
			for b in bots:
				if b.alive and b.team == def_team and b.global_position.distance_to(bomb_pos) < 1.6 and not _enemy_near(b, 9.0):
					defuser = b; b.busy = true; break
		elif defuser is BotPlayer:
			defuse_prog += dt / DEFUSE
		if defuse_prog >= 1.0:
			if defuser == player: Missions.add("defuse")
			_bomb_light.visible = false
			bomb_state = "gone"
			_end_round(def_team, "폭탄 해체")
			return
		if bomb_t <= 0.0:
			_explode()
			_end_round(att_team, "폭탄 폭발")
			return
	Controls.act_progress = defuse_prog if bomb_state == "planted" else plant_prog
	# eliminations / time
	if _alive(def_team).is_empty():
		_end_round(att_team, "수비 전멸"); return
	if _alive(att_team).is_empty() and bomb_state != "planted":
		_end_round(def_team, "공격 전멸"); return
	if t <= 0.0 and bomb_state != "planted":
		_end_round(def_team, "시간 종료")

func _site_at(p: Vector3) -> String:
	if info.has("site_a_poly"):
		if Geometry2D.is_point_in_polygon(Vector2(p.x, p.z), info["site_a_poly"]): return "A"
		if Geometry2D.is_point_in_polygon(Vector2(p.x, p.z), info["site_b_poly"]): return "B"
		return ""
	if (info["site_a"] as Rect2).has_point(Vector2(p.x, p.z)): return "A"
	if (info["site_b"] as Rect2).has_point(Vector2(p.x, p.z)): return "B"
	return ""

func _enemy_near(n: Node3D, r: float) -> bool:
	for e in _alive(1 - n.team):
		if e.global_position.distance_to(n.global_position) < r:
			return true
	return false

func _plant(site: String) -> void:
	bomb_state = "planted"; bomb_t = FUSE; plant_prog = 0.0
	if carrier == player: Missions.add("plant")
	bomb_pos = carrier.global_position
	if carrier is BotPlayer: carrier.busy = false
	_place_bomb(true)
	_show_banner("폭탄 설치됨 — %s 사이트" % site, 2.5)
	Sfx.play("reload")
	_assign_objectives()

func _explode() -> void:
	bomb_state = "gone"
	_bomb_vis.visible = false; _bomb_light.visible = false; _bomb_tag.visible = false
	for n in _members(RED) + _members(BLUE):
		if n.alive and n.global_position.distance_to(bomb_pos) < BLAST_R:
			n.hit(999, false, null)
	var ball := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 1.0; sm.height = 2.0; ball.mesh = sm
	var m := StandardMaterial3D.new(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.albedo_color = Color(1.0, 0.6, 0.2, 0.9)
	ball.material_override = m; add_child(ball); ball.global_position = bomb_pos + Vector3(0, 1, 0)
	ball.scale = Vector3.ONE * 0.5
	var tw := create_tween().set_parallel(true)
	tw.tween_property(ball, "scale", Vector3.ONE * BLAST_R, 0.5)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.7)
	tw.chain().tween_callback(ball.queue_free)
	Sfx.play_at("boom", bomb_pos)
	Controls.add_shake(1.0); Controls.vibrate(300)

# ---------------------------------------------------------------- bots
func _site_center(s: String) -> Vector3:
	var r: Rect2 = info["site_a"] if s == "A" else info["site_b"]
	var c := r.get_center()
	var y := 0.5
	# sample the ground height (the new maps have hills)
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(c.x, 30, c.y), Vector3(c.x, -5, c.y))
	var h := space.intersect_ray(q)
	if h: y = h["position"].y + 0.5
	return Vector3(c.x, y, c.y)

func _assign_objectives() -> void:
	var def_team := 1 - att_team
	var other := "B" if plan_site == "A" else "A"
	var mid: Vector3 = info.get("mid", Vector3(0, 0.5, -15))
	var ab: Array = _members(att_team).filter(func(n): return n is BotPlayer)
	var db: Array = _members(def_team).filter(func(n): return n is BotPlayer)
	match bomb_state:
		"planted":
			var i := 0
			for b in ab:
				var a := TAU * float(i) / maxf(1.0, ab.size())
				b.objective = bomb_pos + Vector3(cos(a), 0, sin(a)) * 6.0; i += 1
			for b in db: b.objective = bomb_pos
		_:
			var i := 0
			for b in ab:
				if i < 3: b.objective = _site_center(plan_site) + _jit(2.5)
				elif i == 3: b.objective = _site_center(other) + _jit(3.0)
				else: b.objective = mid + _jit(3.0)
				i += 1
			_defense(db, mid)

func _defense(db: Array, mid: Vector3) -> void:
	var spots := [_site_center("A") + Vector3(-3, 0, -3), _site_center("B") + Vector3(3, 0, -3),
		_site_center("A") + Vector3(4, 0, 2), _site_center("B") + Vector3(-4, 0, 2), mid]
	for i in db.size():
		db[i].objective = spots[i % spots.size()] + _jit(1.5)

func _jit(r: float) -> Vector3:
	return Vector3(randf_range(-r, r), 0, randf_range(-r, r))

# ---------------------------------------------------------------- deaths
func _on_died(attacker, victim) -> void:
	if attacker == player and victim != player:
		Controls.kills += 1
		Missions.add("kill"); if Controls.weapon_id == "knife": Missions.add("knife_kill")

# ---------------------------------------------------------------- bomb visual
func _build_bomb() -> void:
	_bomb_vis = Node3D.new(); add_child(_bomb_vis)
	var body := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.45, 0.22, 0.32); body.mesh = bm
	var mm := StandardMaterial3D.new(); mm.albedo_color = Color(0.18, 0.20, 0.16); body.material_override = mm
	body.position.y = 0.11; _bomb_vis.add_child(body)
	var pad := MeshInstance3D.new(); var pb := BoxMesh.new(); pb.size = Vector3(0.18, 0.04, 0.12); pad.mesh = pb
	var pm := StandardMaterial3D.new(); pm.albedo_color = Color(0.9, 0.2, 0.15); pm.emission_enabled = true; pm.emission = Color(0.9, 0.1, 0.05)
	pad.material_override = pm; pad.position.y = 0.24; _bomb_vis.add_child(pad)
	_bomb_light = OmniLight3D.new(); _bomb_light.light_color = Color(1, 0.2, 0.1); _bomb_light.light_energy = 3.0
	_bomb_light.omni_range = 4.0; _bomb_light.position.y = 0.5; _bomb_vis.add_child(_bomb_light)
	_bomb_tag = Label3D.new(); _bomb_tag.text = "폭탄"; _bomb_tag.font_size = 28; _bomb_tag.pixel_size = 0.0012
	_bomb_tag.fixed_size = true
	_bomb_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED; _bomb_tag.no_depth_test = true
	_bomb_tag.modulate = Color(1.0, 0.45, 0.3); _bomb_tag.position.y = 0.9
	_bomb_vis.add_child(_bomb_tag)
	_bomb_vis.visible = false

func _place_bomb(planted: bool) -> void:
	_bomb_vis.global_position = Vector3(bomb_pos.x, 0.0, bomb_pos.z)
	_bomb_vis.visible = true
	_bomb_tag.visible = true
	_bomb_tag.text = "설치된 폭탄" if planted else "폭탄"
	_bomb_light.visible = planted

# ---------------------------------------------------------------- camera (spectate when dead)
func _camera() -> void:
	if player.alive:
		_spec = null
		CamRig.follow(cam, player)
		return
	if _spec == null or not _spec.alive:
		_spec = null
		for n in _alive(RED):
			_spec = n; break
	var focus: Node3D = _spec if _spec else player
	var back := focus.global_transform.basis.z
	var want := focus.global_position + back * 3.8 + Vector3(0, 2.4, 0)
	cam.global_position = cam.global_position.lerp(want, 0.1)
	cam.look_at(focus.global_position + Vector3(0, 1.3, 0), Vector3.UP)
	cam.fov = 65.0

# ---------------------------------------------------------------- HUD
func _show_banner(txt: String, dur: float) -> void:
	_banner.text = txt; _banner.visible = true; _banner_t = dur

func _hud(dt: float) -> void:
	_score_lbl.text = "레드 %d  :  %d 블루" % [score[RED], score[BLUE]]
	if bomb_state == "planted" and state == "live":
		_time_lbl.text = "폭탄 %d" % ceili(maxf(bomb_t, 0.0))
		_time_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3))
	else:
		var s := maxf(t, 0.0) if state == "live" else (ROUND_TIME if state == "prep" else 0.0)
		_time_lbl.text = "%d:%02d" % [int(s) / 60, int(s) % 60]
		_time_lbl.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98))
	var pips := ""
	for n in _members(RED): pips += "●" if n.alive else "○"
	pips += "   "
	for n in _members(BLUE): pips += "●" if n.alive else "○"
	_alive_lbl.text = pips
	var role := "공격" if att_team == RED else "수비"
	if bomb_state == "carried" and att_team == RED and player.alive:
		_carry_lbl.text = "%s · 폭탄 보유 — A·B 사이트 안에서 '설치'를 누르고 있기" % role
	elif not player.alive and state == "live":
		_carry_lbl.text = "관전 중 — 다음 라운드에 부활"
	else:
		_carry_lbl.text = role + (" · 폭탄을 해체하세요" if bomb_state == "planted" and att_team != RED else "")
	if _banner_t > 0.0:
		_banner_t -= dt
		if _banner_t <= 0.0: _banner.visible = false

func _end_match() -> void:
	state = "over"
	Controls.act_label = ""
	Pause.disarm()
	get_tree().paused = true
	_result.visible = true
	var v := _result.get_node("v")
	(v.get_node("t") as Label).text = "승리!" if score[RED] > score[BLUE] else "패배"
	Missions.add("match")
	if score[RED] > score[BLUE]: Missions.add("win")
	Missions.record("폭파미션", SortieScreen.map_name(Controls.sel_map), "%s %d : %d · 처치 %d" % ["승리" if score[RED] > score[BLUE] else "패배", score[RED], score[BLUE], Controls.kills], score[RED] > score[BLUE], "",
		Missions.match_reward(30, Controls.kills, 70, score[RED] > score[BLUE]))
	(v.get_node("s") as Label).text = "레드 %d : %d 블루\n내 처치 %d\n획득 코인 +%d" % [score[RED], score[BLUE], Controls.kills, Missions.last_reward]

func _build_hud() -> void:
	var layer := CanvasLayer.new(); add_child(layer)
	var touch := TouchInput.new(); touch.set_anchors_preset(Control.PRESET_FULL_RECT)
	touch.mouse_filter = Control.MOUSE_FILTER_IGNORE; layer.add_child(touch)
	var cross := CrossHair.new(); cross.set_anchors_preset(Control.PRESET_FULL_RECT)
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE; layer.add_child(cross)
	var radar := Radar.new().setup(player, info.get("bounds", Rect2(-50, -40, 100, 80)))
	radar.extras = func() -> Array:
		var out: Array = [{"pos": _site_center("A"), "kind": "A"}, {"pos": _site_center("B"), "kind": "B"}]
		if bomb_state == "planted": out.append({"pos": bomb_pos, "kind": "bomb"})
		return out
	layer.add_child(radar)
	layer.add_child(PrepLoadout.new().setup(self))     # weapon change during each round's prep
	_carry_lbl = _lbl(20, Color(1.0, 0.75, 0.45)); _carry_lbl.position = Vector2(26, 268); layer.add_child(_carry_lbl)
	_score_lbl = _lbl(28, Color(1.0, 0.72, 0.38), true); _score_lbl.offset_top = 10; layer.add_child(_score_lbl)
	_time_lbl = _lbl(34, Color(0.95, 0.96, 0.98), true); _time_lbl.offset_top = 44; layer.add_child(_time_lbl)
	_alive_lbl = _lbl(20, Color(0.85, 0.88, 0.92), true); _alive_lbl.offset_top = 88; layer.add_child(_alive_lbl)
	_banner = _lbl(46, Color(1.0, 0.85, 0.55), true); _banner.anchor_top = 0.30; _banner.visible = false
	layer.add_child(_banner)
	_build_result(layer)

func _lbl(size: int, col: Color, centered := false) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if centered:
		l.anchor_right = 1.0; l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _build_result(layer: CanvasLayer) -> void:
	_result = Control.new()
	_result.process_mode = Node.PROCESS_MODE_ALWAYS
	_result.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new(); bg.color = Color(0.05, 0.07, 0.09, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT); _result.add_child(bg)
	var v := VBoxContainer.new(); v.name = "v"; v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.anchor_left = 0.5; v.anchor_right = 0.5; v.anchor_top = 0.5; v.anchor_bottom = 0.5
	v.offset_left = -320; v.offset_right = 320; v.offset_top = -180; v.offset_bottom = 180
	v.add_theme_constant_override("separation", 22); _result.add_child(v)
	var tl := Label.new(); tl.name = "t"; tl.add_theme_font_size_override("font_size", 46)
	tl.add_theme_color_override("font_color", Color(1.0, 0.72, 0.38)); tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tl)
	var s := Label.new(); s.name = "s"; s.add_theme_font_size_override("font_size", 30)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(s)
	var btn := Button.new(); btn.text = "다시 시작"; btn.add_theme_font_size_override("font_size", 30)
	btn.custom_minimum_size = Vector2(280, 66); btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.pressed.connect(func() -> void:
		Controls.reset(); get_tree().paused = false; get_tree().reload_current_scene())
	v.add_child(btn)
	var mb := Button.new(); mb.text = "메뉴"; mb.add_theme_font_size_override("font_size", 26)
	mb.custom_minimum_size = Vector2(280, 56); mb.process_mode = Node.PROCESS_MODE_ALWAYS
	mb.pressed.connect(func() -> void:
		Controls.reset(); get_tree().paused = false; get_tree().change_scene_to_file("res://Menu.tscn"))
	v.add_child(mb)
	_result.visible = false
	layer.add_child(_result)
