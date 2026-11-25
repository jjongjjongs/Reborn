extends Node3D
## M1 world: floor + cover + targets + player + aim-follow camera + touch HUD.

var player: PlayerBody
var cam: Camera3D
var _ammo_lbl: Label
var _hit_lbl: Label

func _ready() -> void:
	_build_world()
	_build_player()
	_build_camera()
	_build_hud()

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

	_add_box(Vector3(70, 1, 70), Vector3(0, -0.5, 0), Color(0.12, 0.14, 0.13))
	for p in [Vector3(8, 1, 4), Vector3(-9, 1, -3), Vector3(4, 1, -10), Vector3(-6, 1, 9)]:
		_add_box(Vector3(2, 2, 2), p, Color(0.2, 0.22, 0.25))
	# targets
	for p in [Vector3(6, 0, -12), Vector3(-4, 0, -14), Vector3(0, 0, -18), Vector3(11, 0, -16)]:
		var t := Target.new()
		t.position = p
		add_child(t)

func _add_box(size: Vector3, pos: Vector3, c: Color) -> void:
	var sb := StaticBody3D.new()
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size; m.mesh = bm
	var mt := StandardMaterial3D.new(); mt.albedo_color = c; m.material_override = mt
	sb.add_child(m)
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new(); bs.size = size; col.shape = bs
	sb.add_child(col)
	sb.position = pos
	add_child(sb)

func _build_player() -> void:
	player = PlayerBody.new()
	player.position = Vector3(0, 1.5, 0)
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
	if _hit_lbl:
		_hit_lbl.text = "명중 %d" % Controls.hits

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

	layer.add_child(_mk_label("리본 · M1 — 사격 테스트", 30, Vector2(28, 22)))
	_hit_lbl = _mk_label("명중 0", 34, Vector2(28, 64))
	_hit_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.35))
	layer.add_child(_hit_lbl)

	# (fire / jump / reload are drawn + handled by TouchInput for true multi-touch)
	# ammo label (above-left of fire)
	_ammo_lbl = _mk_label("30 / 30", 36, Vector2.ZERO)
	_ammo_lbl.anchor_left = 1.0; _ammo_lbl.anchor_right = 1.0
	_ammo_lbl.offset_left = -470; _ammo_lbl.offset_top = -330; _ammo_lbl.offset_right = -270
	_ammo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	layer.add_child(_ammo_lbl)

func _mk_label(txt: String, size: int, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", size)
	l.position = pos
	return l
