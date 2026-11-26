extends Node3D
## M3 world: NavMesh arena + wave manager + player HP + wave/points HUD.

var player: PlayerBody
var _map := {}
var cam: Camera3D
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
	if _map.has("zombie"):
		wm.spawn_points = _map["zombie"]
	add_child(wm)

func _build_world() -> void:
	Controls.sel_map = "reststop"            # survival has its own map(s)
	_map = MapBuilder.build(Controls.sel_map, self)

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
	player.position = _map.get("player", Vector3(0, 1.5, 0))
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
		CamRig.follow(cam, player)
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
	layer.add_child(Radar.new().setup(player, _map.get("bounds", Rect2(-35, -35, 70, 70))))


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
