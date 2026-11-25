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
var _hp_fill: ColorRect
var _top_lbl: Label
var _score_lbl: Label
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
	await get_tree().physics_frame
	await get_tree().physics_frame
	_spawn_bots()

func _build_world() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -40, 0); sun.light_energy = 1.1; sun.shadow_enabled = true
	add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.06, 0.08, 0.10)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.5, 0.55); env.ambient_light_energy = 0.7
	env.fog_enabled = true; env.fog_light_color = Color(0.07, 0.1, 0.12); env.fog_density = 0.01
	we.environment = env; add_child(we)
	var nav := NavigationRegion3D.new(); add_child(nav)
	_add_box(nav, Vector3(70, 1, 70), Vector3(0, -0.5, 0), Color(0.12, 0.14, 0.13))
	for p in [Vector3(8, 1.5, 4), Vector3(-9, 1.5, -3), Vector3(4, 1.5, -10), Vector3(-6, 1.5, 9),
			Vector3(11, 1.5, -6), Vector3(-11, 1.5, 7)]:
		_add_box(nav, Vector3(3, 3, 3), p, Color(0.2, 0.22, 0.25))
	var nm := NavigationMesh.new()
	nm.cell_size = 0.25; nm.cell_height = 0.25; nm.agent_radius = 0.5; nm.agent_height = 1.8; nm.agent_max_climb = 0.4
	nav.navigation_mesh = nm
	nav.bake_navigation_mesh(false)

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
		b.position = _spawns[(i + 1) % _spawns.size()]
		b.died.connect(_on_died.bind(b))
		add_child(b)
		_bots.append(b)

func _rand_spawn() -> Vector3:
	return _spawns[randi() % _spawns.size()]

func _on_died(attacker, victim) -> void:
	if _over:
		return
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
	# respawn the victim after a delay
	var sp := _rand_spawn()
	get_tree().create_timer(RESPAWN_DELAY).timeout.connect(func() -> void:
		if not _over and is_instance_valid(victim):
			victim.respawn_at(sp))

func _leader() -> Array:   # [name, kills]
	var best_name := "나"
	var best := Controls.kills
	for b in _bots:
		if b.kills > best:
			best = b.kills; best_name = b.bot_name
	return [best_name, best]

func _process(_dt: float) -> void:
	if player:
		var bb := Basis.from_euler(Vector3(deg_to_rad(player.aim_pitch), deg_to_rad(player.aim_yaw), 0))
		var fwd := -bb.z
		var pivot := player.global_position + Vector3(0, 1.4, 0)
		cam.global_position = cam.global_position.lerp(pivot - fwd * 4.0 + bb.x * 0.7 + Vector3(0, 0.3, 0), 0.35)
		cam.look_at(pivot + fwd * 12.0, Vector3.UP)
	if _hp_fill:
		_hp_fill.size.x = 360.0 * float(Controls.hp) / float(Controls.hp_max)
	if _score_lbl:
		_score_lbl.text = "나 %d" % Controls.kills
	if _top_lbl and not _over:
		var ld := _leader()
		_top_lbl.text = "데스매치 · 목표 %d · 1위 %s %d" % [KILL_TARGET, ld[0], ld[1]]

func _end_match(winner) -> void:
	_over = true
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
	_score_lbl.offset_left = -240; _score_lbl.offset_top = 22
	_score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	layer.add_child(_score_lbl)

	var hp_bg := ColorRect.new(); hp_bg.color = Color(0, 0, 0, 0.55)
	hp_bg.position = Vector2(28, 52); hp_bg.size = Vector2(360, 26)
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE; layer.add_child(hp_bg)
	_hp_fill = ColorRect.new(); _hp_fill.color = Color(0.88, 0.30, 0.25)
	_hp_fill.position = Vector2(28, 52); _hp_fill.size = Vector2(360, 26)
	_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE; layer.add_child(_hp_fill)

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
