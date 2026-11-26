extends Node3D
## 훈련 모드: the training compound with pop-up targets (firing-range lanes at
## 10-30 m, kill house rooms, drill yard, tower). No enemies, no timer; leave from
## the pause menu. Shows hits / headshots / knockdowns.

var player: PlayerBody
var cam: Camera3D
var _info := {}
var _lbl: Label
var _sub: Label
# target spots on the plan (metres; x east, y south) and the direction they face
const SPOTS := [
	[52, 20], [54, 26], [56, 32], [55, 37], [46, 23], [44, 32],      # firing range lanes
	[16, 6], [30, 5], [44, 7], [40, 11], [24, 11],                   # kill house rooms + corridor
	[25, 22], [35, 30], [31, 19], [22, 33],                          # drill yard
	[12, 22], [15, 30], [6, 12],                                     # obstacle course
	[24, 47], [36, 47], [48, 42],                                    # depot / hangar
]

func _ready() -> void:
	Controls.sel_map = "range"
	_info = MapBuilder.build("range", self)
	player = PlayerBody.new()
	player.position = _info.get("player", Vector3(0, 1.5, 0))
	add_child(player)
	cam = Camera3D.new(); cam.fov = 65.0; cam.current = true
	add_child(cam)
	_build_hud()
	Pause.arm()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_place_targets()

func _place_targets() -> void:
	var b: Rect2 = _info["bounds"]
	var space := get_world_3d().direct_space_state
	for s in SPOTS:
		var p := Vector3(b.position.x + float(s[0]), 0.0, b.position.y + float(s[1]))
		var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 8, 0), p + Vector3(0, -6, 0))
		var h := space.intersect_ray(q)
		if h: p.y = h["position"].y
		var t := PopupTarget.new()
		add_child(t)
		t.global_position = p
		# face the player's side of the compound (toward the drill yard centre)
		var c := Vector3(b.get_center().x, p.y, b.get_center().y)
		if p.distance_to(c) > 1.0: t.look_at(c, Vector3.UP)
		t.rotate_y(PI)

func _process(_dt: float) -> void:
	if player: CamRig.follow(cam, player)
	if _lbl:
		_lbl.text = "명중 %d · 헤드샷 %d · 쓰러뜨림 %d" % [Controls.hits, Controls.headshots, Controls.kills]

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
	_sub = Label.new(); _sub.text = "훈련 · 표적은 쓰러지면 다시 일어납니다 · 나가기는 일시정지"
	_sub.add_theme_font_size_override("font_size", 17)
	_sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.anchor_left = 0.0; _sub.anchor_right = 1.0; _sub.offset_top = 62
	_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_sub)
	layer.add_child(Radar.new().setup(player, _info.get("bounds", Rect2(-30, -26, 60, 52))))
