extends Node3D
## Mode A: free-for-all deathmatch vs bots. Everyone targets the nearest living
## opponent; kills score; dead combatants respawn; first to KILL_TARGET wins.

const N_BOTS := 5
const KILL_TARGET := 20
const RESPAWN_DELAY := 3.0

var player: PlayerBody
var cam: Camera3D
var _over := false
var _spawns: Array[Vector3] = [
	Vector3(16, 1.3, 0), Vector3(-16, 1.3, 0), Vector3(0, 1.3, -18), Vector3(0, 1.3, 18),
	Vector3(14, 1.3, -14), Vector3(-14, 1.3, 14), Vector3(14, 1.3, 14), Vector3(-14, 1.3, -14),
]
var _bots: Array = []
var _player_resp := 0.0
var _hp_fill: ColorRect
var _top_lbl: Label
var _score_lbl: Label
var _respawn_lbl: Label
var _result: Control

func _ready() -> void:
	_build_world()
	player = PlayerBody.new()
	player.position = _spawns[0]
	player.died.connect(_on_died.bind(player))
	add_child(player)
	cam = Camera3D.new(); cam.fov = 65.0; cam.current = true; cam.position = Vector3(0, 2, 5)
	add_child(cam)
	_build_hud()
	Pause.arm()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_spawn_bots()

func _build_world() -> void:
	var info := MapBuilder.build(Controls.sel_map, self)
	_spawns = info["ffa"]

func _add_box(parent: Node, size: Vector3, pos: Vector3, c: Color) -> void:
	var sb := StaticBody3D.new()
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size; m.mesh = bm
	var mt := StandardMaterial3D.new(); mt.albedo_color = c; m.material_override = mt
	sb.add_child(m)
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new(); bs.size = size; col.shape = bs
	sb.add_child(col); sb.position = pos; parent.add_child(sb)

func _spawn_bots() -> void:
	var tints := [Color(0.82, 0.32, 0.30), Color(0.30, 0.55, 0.85), Color(0.55, 0.40, 0.80),
		Color(0.30, 0.70, 0.45), Color(0.80, 0.60, 0.25)]
	for i in N_BOTS:
		var b := BotPlayer.new()
		b.bot_name = "봇 %d" % (i + 1)
		b.tint = tints[i % tints.size()]
		b.position = _free_spawn()
		b.died.connect(_on_died.bind(b))
		add_child(b)
		_bots.append(b)

func _free_spawn() -> Vector3:
	# the spawn point farthest from any living combatant (avoid spawning on top)
	var best := _spawns[0]
	var best_clear := -1.0
	for sp in _spawns:
		var clear := 1e9
		for c in get_tree().get_nodes_in_group("combatant"):
			if c != null and "alive" in c and c.alive:
				clear = minf(clear, sp.distance_to((c as Node3D).global_position))
		if clear > best_clear:
			best_clear = clear; best = sp
	return best

func _on_died(attacker, victim) -> void:
	if _over:
		return
	if victim == player:
		_player_resp = RESPAWN_DELAY
	# credit the killer
	var killer_kills := -1
	if attacker == player:
		Controls.kills += 1
		killer_kills = Controls.kills
	elif attacker is BotPlayer and attacker != victim:
		attacker.kills += 1
		killer_kills = attacker.kills
	if killer_kills >= KILL_TARGET:
		_end_match(attacker)
		return
	# respawn the victim after a delay (pick a clear spawn at that moment)
	get_tree().create_timer(RESPAWN_DELAY).timeout.connect(func() -> void:
		if not _over and is_instance_valid(victim):
			victim.respawn_at(_free_spawn()))

func _leader() -> Array:   # [name, kills]
	var best_name := "나"
	var best := Controls.kills
	for b in _bots:
		if b.kills > best:
			best = b.kills; best_name = b.bot_name
	return [best_name, best]

func _process(dt: float) -> void:
	if player:
		CamRig.follow(cam, player)
	# respawn countdown overlay
	if _respawn_lbl:
		var dead: bool = player != null and not player.alive and not _over
		if dead:
			_player_resp = maxf(0.0, _player_resp - dt)
			_respawn_lbl.text = "부활까지 %d" % ceili(_player_resp)
		_respawn_lbl.visible = dead
	if _hp_fill:
		_hp_fill.size.x = 360.0 * float(Controls.hp) / float(Controls.hp_max)
	if _score_lbl:
		_score_lbl.text = "나 %d" % Controls.kills
	if _top_lbl and not _over:
		var ld := _leader()
		_top_lbl.text = "데스매치 · 목표 %d · 1위 %s %d" % [KILL_TARGET, ld[0], ld[1]]

func _end_match(winner) -> void:
	_over = true
	Pause.disarm()
	get_tree().paused = true
	var win: bool = (winner == player)
	_result.visible = true
	var r := _result.get_node("v")
	(r.get_node("t") as Label).text = "승리!" if win else "패배"
	var ld := _leader()
	(r.get_node("s") as Label).text = "최종 처치 — 나 %d\n1위 %s · %d킬\n목표 %d 선취" % [
		Controls.kills, ld[0], ld[1], KILL_TARGET]

func _build_hud() -> void:
	var layer := CanvasLayer.new(); add_child(layer)
	var touch := TouchInput.new(); touch.set_anchors_preset(Control.PRESET_FULL_RECT)
	touch.mouse_filter = Control.MOUSE_FILTER_IGNORE; layer.add_child(touch)
	var cross := CrossHair.new(); cross.set_anchors_preset(Control.PRESET_FULL_RECT)
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE; layer.add_child(cross)

	_top_lbl = Label.new()
	_top_lbl.add_theme_font_size_override("font_size", 30)
	_top_lbl.add_theme_color_override("font_color", Color(1.0, 0.72, 0.38))
	_top_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_top_lbl.anchor_right = 1.0; _top_lbl.offset_top = 22
	_top_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_top_lbl)

	_score_lbl = Label.new()
	_score_lbl.text = "나 0"; _score_lbl.add_theme_font_size_override("font_size", 32)
	_score_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.35))
	_score_lbl.anchor_left = 1.0; _score_lbl.anchor_right = 1.0
	_score_lbl.offset_left = -340; _score_lbl.offset_right = -104; _score_lbl.offset_top = 22   # left of pause
	_score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	layer.add_child(_score_lbl)

	var hp_bg := ColorRect.new(); hp_bg.color = Color(0, 0, 0, 0.55)
	hp_bg.position = Vector2(28, 52); hp_bg.size = Vector2(360, 26)
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE; layer.add_child(hp_bg)
	_hp_fill = ColorRect.new(); _hp_fill.color = Color(0.88, 0.30, 0.25)
	_hp_fill.position = Vector2(28, 52); _hp_fill.size = Vector2(360, 26)
	_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE; layer.add_child(_hp_fill)

	_respawn_lbl = Label.new()
	_respawn_lbl.add_theme_font_size_override("font_size", 52)
	_respawn_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
	_respawn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_respawn_lbl.anchor_left = 0.0; _respawn_lbl.anchor_right = 1.0
	_respawn_lbl.anchor_top = 0.42
	_respawn_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_respawn_lbl.visible = false
	layer.add_child(_respawn_lbl)

	_build_result(layer)

func _build_result(layer: CanvasLayer) -> void:
	_result = Control.new()
	_result.process_mode = Node.PROCESS_MODE_ALWAYS
	_result.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := ColorRect.new(); bg.color = Color(0.05, 0.07, 0.09, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT); _result.add_child(bg)
	var v := VBoxContainer.new(); v.name = "v"
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set_anchors_preset(Control.PRESET_CENTER); v.add_theme_constant_override("separation", 22)
	v.anchor_left = 0.5; v.anchor_right = 0.5; v.anchor_top = 0.5; v.anchor_bottom = 0.5
	v.offset_left = -320; v.offset_right = 320; v.offset_top = -180; v.offset_bottom = 180
	_result.add_child(v)
	var t := Label.new(); t.name = "t"; t.add_theme_font_size_override("font_size", 46)
	t.add_theme_color_override("font_color", Color(1.0, 0.72, 0.38)); t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
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
