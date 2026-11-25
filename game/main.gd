extends Node3D
## M3 world: NavMesh arena + wave manager + player HP + wave/points HUD.

var player: PlayerBody
var cam: Camera3D
var _ammo_lbl: Label
var _wave_lbl: Label
var _pts_lbl: Label
var _hp_fill: ColorRect
const HP_W := 360.0

func _ready() -> void:
	_build_world()
	_build_player()
	_build_camera()
	_build_hud()
	Pause.arm()
	var wm := WaveManager.new()
	wm.arena = self
	wm.player = player
	add_child(wm)

func _build_world() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -40, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)

	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.08, 0.10)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.5, 0.55)
	env.ambient_light_energy = 0.7
	env.fog_enabled = true
	env.fog_light_color = Color(0.07, 0.1, 0.12)
	env.fog_density = 0.01
	we.environment = env
	add_child(we)

	var nav := NavigationRegion3D.new()
	add_child(nav)
	_add_box(nav, Vector3(70, 1, 70), Vector3(0, -0.5, 0), Color(0.12, 0.14, 0.13))
	for p in [Vector3(8, 1, 4), Vector3(-9, 1, -3), Vector3(4, 1, -10), Vector3(-6, 1, 9)]:
		_add_box(nav, Vector3(2, 2, 2), p, Color(0.2, 0.22, 0.25))
	var nm := NavigationMesh.new()
	nm.cell_size = 0.25
	nm.cell_height = 0.25
	nm.agent_radius = 0.5
	nm.agent_height = 1.8
	nm.agent_max_climb = 0.4
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
	sb.add_child(col)
	sb.position = pos
	parent.add_child(sb)

func _build_player() -> void:
	player = PlayerBody.new()
	player.position = Vector3(0, 1.5, 0)
	player.died.connect(func(_a): Controls.end_run(false))
	add_child(player)

func _build_camera() -> void:
	cam = Camera3D.new()
	cam.fov = 65.0
	cam.current = true
	cam.position = Vector3(0, 2, 5)
	add_child(cam)

func _process(_dt: float) -> void:
	if player:
		var b := Basis.from_euler(Vector3(deg_to_rad(player.aim_pitch), deg_to_rad(player.aim_yaw), 0))
		var fwd := -b.z
		var pivot := player.global_position + Vector3(0, 1.4, 0)
		var want := pivot - fwd * 4.0 + b.x * 0.7 + Vector3(0, 0.3, 0)
		cam.global_position = cam.global_position.lerp(want, 0.35)
		cam.look_at(pivot + fwd * 12.0, Vector3.UP)
	if _ammo_lbl:
		_ammo_lbl.text = ("재장전…" if Controls.reloading else "%d / %d" % [Controls.ammo, Controls.ammo_max])
	if _pts_lbl:
		_pts_lbl.text = "◆ %d" % Controls.points
	if _wave_lbl:
		if Controls.cleared:
			_wave_lbl.text = "클리어!"
		elif Controls.prep_left >= 0.0:
			_wave_lbl.text = "다음 웨이브 %d · 준비 %d" % [Controls.wave + 1, ceili(Controls.prep_left)]
		else:
			_wave_lbl.text = "웨이브 %d / %d · 남은 %d" % [Controls.wave, Controls.wave_total, Controls.zombies_left]
	if _hp_fill:
		_hp_fill.size.x = HP_W * float(Controls.hp) / float(Controls.hp_max)

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

	# wave status (top center)
	_wave_lbl = Label.new()
	_wave_lbl.text = "준비"
	_wave_lbl.add_theme_font_size_override("font_size", 34)
	_wave_lbl.add_theme_color_override("font_color", Color(1.0, 0.72, 0.38))
	_wave_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_lbl.anchor_left = 0.0; _wave_lbl.anchor_right = 1.0
	_wave_lbl.offset_top = 22
	_wave_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_wave_lbl)

	# points (top right)
	_pts_lbl = _mk_label("◆ 0", 32, Vector2.ZERO)
	_pts_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.35))
	_pts_lbl.anchor_left = 1.0; _pts_lbl.anchor_right = 1.0
	_pts_lbl.offset_left = -340; _pts_lbl.offset_right = -104; _pts_lbl.offset_top = 22   # left of pause
	_pts_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	layer.add_child(_pts_lbl)

	# HP bar (top left)
	layer.add_child(_mk_label("체력", 22, Vector2(28, 18)))
	var hp_bg := ColorRect.new()
	hp_bg.color = Color(0, 0, 0, 0.55)
	hp_bg.position = Vector2(28, 52); hp_bg.size = Vector2(HP_W, 26)
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hp_bg)
	_hp_fill = ColorRect.new()
	_hp_fill.color = Color(0.88, 0.30, 0.25)
	_hp_fill.position = Vector2(28, 52); _hp_fill.size = Vector2(HP_W, 26)
	_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_hp_fill)

	_ammo_lbl = _mk_label("30 / 30", 36, Vector2.ZERO)
	_ammo_lbl.anchor_left = 1.0; _ammo_lbl.anchor_right = 1.0
	_ammo_lbl.offset_left = -470; _ammo_lbl.offset_top = -330; _ammo_lbl.offset_right = -270
	_ammo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	layer.add_child(_ammo_lbl)

	# in-run upgrade shop (shows itself during prep)
	layer.add_child(UpgradeShop.new())
	# run-end result overlay (shows itself on game over)
	layer.add_child(ResultScreen.new())

func _mk_label(txt: String, size: int, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", size)
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
