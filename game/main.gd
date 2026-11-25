extends Node3D
## M0 world builder: floor + obstacles + light + player + follow camera + touch HUD.
## Everything built in code to keep scene files trivial for hand-authoring/CI.

var player: CharacterBody3D
var cam: Camera3D

func _ready() -> void:
	_build_world()
	_build_player()
	_build_camera()
	_build_hud()

func _build_world() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -40.0, 0.0)
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
	env.fog_density = 0.012
	we.environment = env
	add_child(we)

	_add_box(Vector3(60, 1, 60), Vector3(0, -0.5, 0), Color(0.12, 0.14, 0.13))
	for p in [Vector3(7, 1, 4), Vector3(-8, 1, -3), Vector3(3, 1, -9), Vector3(-5, 1, 8)]:
		_add_box(Vector3(2, 2, 2), p, Color(0.2, 0.22, 0.25))

func _add_box(size: Vector3, pos: Vector3, c: Color) -> void:
	var sb := StaticBody3D.new()
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	var mt := StandardMaterial3D.new()
	mt.albedo_color = c
	m.material_override = mt
	sb.add_child(m)
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	col.shape = bs
	sb.add_child(col)
	sb.position = pos
	add_child(sb)

func _build_player() -> void:
	player = (preload("res://player.gd") as GDScript).new()
	player.position = Vector3(0, 1.5, 0)
	add_child(player)

func _build_camera() -> void:
	cam = Camera3D.new()
	cam.fov = 60.0
	cam.current = true
	cam.position = Vector3(0, 6, 8)
	add_child(cam)

func _process(_dt: float) -> void:
	if player == null:
		return
	var target := player.global_position
	cam.global_position = cam.global_position.lerp(target + Vector3(0, 6, 8), 0.15)
	cam.look_at(target + Vector3(0, 1, 0), Vector3.UP)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var joy := (preload("res://joystick.gd") as GDScript).new()
	joy.set_anchors_preset(Control.PRESET_FULL_RECT)
	joy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(joy)

	var jump := Button.new()
	jump.text = "점프"
	jump.add_theme_font_size_override("font_size", 44)
	jump.anchor_left = 1.0
	jump.anchor_top = 1.0
	jump.anchor_right = 1.0
	jump.anchor_bottom = 1.0
	jump.offset_left = -260.0
	jump.offset_top = -260.0
	jump.offset_right = -40.0
	jump.offset_bottom = -40.0
	jump.pressed.connect(func() -> void: Controls.request_jump())
	layer.add_child(jump)

	var lbl := Label.new()
	lbl.text = "리본 · M0 — 이동 / 점프 테스트"
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.position = Vector2(28, 22)
	layer.add_child(lbl)
