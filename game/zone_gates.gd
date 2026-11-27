class_name ZoneGates
extends Node3D
## Survival: the map opens up one area per wave. Each locked area sits behind
## barricades (solid, baked into the navmesh so zombies path around them); before
## the wave that opens it the barricades drop, the navmesh is re-baked and that
## area's zombie spawns join the pool.

# per plan: zones in opening order (zone 0 is open from the start). cells are 2 m
# ASCII-plan cells; gates are [x0, y0, x1, y1) cell rects, spawns are cells.
const ZONES := {
	"zombie_reststop": [
		{"name": "주유소 · 편의점", "spawns": [[1, 1], [30, 2]], "gates": []},
		{"name": "주차장", "spawns": [[1, 18], [23, 24]],
			"gates": [[12, 17, 14, 18], [7, 17, 10, 18], [22, 17, 24, 18]]},
		{"name": "정비소", "spawns": [[3, 10]], "gates": [[6, 7, 7, 9], [6, 13, 7, 15]]},
		{"name": "모텔 뒷길", "spawns": [[30, 13], [1, 26], [15, 26], [30, 26]],
			"gates": [[29, 3, 31, 4], [28, 5, 29, 6], [28, 13, 29, 14], [28, 21, 29, 22], [4, 25, 6, 26], [14, 25, 16, 26], [20, 25, 22, 26]]},
	],
}

var zones: Array = []
var opened := 0                 # zones [0, opened] are open
var _nav: NavigationRegion3D
var _hw := 0.0
var _hh := 0.0
var _gates := {}                # zone index -> Array[Node3D]
var _toast: Label
var _toast_t := 0.0

static func has_zones(plan: String) -> bool:
	return ZONES.has(plan)

func setup(plan: String, nav: NavigationRegion3D, bounds: Rect2) -> ZoneGates:
	zones = ZONES.get(plan, [])
	_nav = nav
	_hw = -bounds.position.x; _hh = -bounds.position.y
	for zi in range(1, zones.size()):
		var list: Array = []
		for g in zones[zi]["gates"]:
			list.append(_gate(g, zi))
		_gates[zi] = list
	if _nav and not MapBuilder.backdrop:
		_nav.bake_navigation_mesh(false)       # locked areas are off the navmesh from the start
	var layer := CanvasLayer.new(); layer.layer = 5; add_child(layer)
	_toast = Label.new()
	_toast.add_theme_font_size_override("font_size", 36)
	_toast.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55))
	_toast.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.anchor_left = 0.0; _toast.anchor_right = 1.0; _toast.anchor_top = 0.62; _toast.anchor_bottom = 0.62
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE; _toast.visible = false
	layer.add_child(_toast)
	return self

func _cell_world(c: Array) -> Vector3:
	return Vector3(float(c[0]) * 2.0 + 1.0 - _hw, 1.0, float(c[1]) * 2.0 + 1.0 - _hh)

## zombie spawn points of every open zone
func spawns() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for zi in range(0, mini(opened + 1, zones.size())):
		for c in zones[zi]["spawns"]: out.append(_cell_world(c))
	return out

## open the area for this (1-based) wave: wave 2 -> zone 1, ...
func open_for_wave(wave: int) -> void:
	var zi := wave - 1
	if zi <= opened or zi >= zones.size(): return
	opened = zi
	for g in _gates.get(zi, []):
		var n := g as Node3D
		for c in n.find_children("*", "CollisionShape3D", true, false): (c as CollisionShape3D).disabled = true
		var t := n.create_tween()
		t.tween_property(n, "position:y", -3.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_callback(n.queue_free)
	_gates.erase(zi)
	get_tree().create_timer(0.9).timeout.connect(func() -> void:
		if is_instance_valid(_nav): _nav.bake_navigation_mesh(true))
	Sfx.play("ui")
	_toast.text = "새 구역 개방 · %s" % zones[zi]["name"]
	_toast.visible = true; _toast_t = 3.5

func _process(dt: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= dt
		_toast.modulate.a = clampf(_toast_t, 0.0, 1.0)
		if _toast_t <= 0.0: _toast.visible = false

# a plank barricade filling the cell rect, with hazard stripes and the wave that opens it
func _gate(g: Array, zi: int) -> Node3D:
	var x0 := float(g[0]) * 2.0 - _hw; var z0 := float(g[1]) * 2.0 - _hh
	var x1 := float(g[2]) * 2.0 - _hw; var z1 := float(g[3]) * 2.0 - _hh
	var size := Vector3(x1 - x0, 3.0, z1 - z0)
	var along_x := size.x >= size.z
	var thick := 0.35
	if along_x: size.z = thick
	else: size.x = thick
	var root := StaticBody3D.new()
	root.position = Vector3((x0 + x1) * 0.5, 0.0, (z0 + z1) * 0.5)
	var col := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = size; col.shape = bs
	col.position.y = size.y * 0.5; root.add_child(col)
	var wood := StandardMaterial3D.new(); wood.albedo_color = Color(0.42, 0.30, 0.18); wood.roughness = 0.95
	var dark := StandardMaterial3D.new(); dark.albedo_color = Color(0.24, 0.17, 0.10)
	var yel := StandardMaterial3D.new(); yel.albedo_color = Color(0.95, 0.75, 0.10)
	var span := size.x if along_x else size.z
	var box := func(c: Vector3, s: Vector3, m: Material) -> void:
		var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = s if along_x else Vector3(s.z, s.y, s.x)
		mi.mesh = bm; mi.material_override = m
		mi.position = c if along_x else Vector3(c.z, c.y, c.x)
		root.add_child(mi)
	for i in 5:   # horizontal planks with small gaps
		box.call(Vector3(0, 0.35 + i * 0.58, 0), Vector3(span + 0.2, 0.46, 0.12), wood)
	for s in [-1.0, 1.0]:   # posts
		box.call(Vector3(s * (span * 0.5 - 0.1), 1.5, 0.0), Vector3(0.18, 3.0, 0.3), dark)
	box.call(Vector3(0, 1.55, 0.09), Vector3(span * 0.9, 0.22, 0.04), yel)
	box.call(Vector3(0, 1.55, -0.09), Vector3(span * 0.9, 0.22, 0.04), yel)
	for side in [1.0, -1.0]:
		var lb := Label3D.new(); lb.text = "웨이브 %d 개방" % (zi + 1); lb.font_size = 44; lb.pixel_size = 0.01
		lb.modulate = Color(1, 0.95, 0.8); lb.outline_size = 8; lb.double_sided = false
		var off := Vector3(0, 2.35, 0.1 * side)
		lb.position = off if along_x else Vector3(off.z, off.y, off.x)
		lb.rotation_degrees.y = (0.0 if side > 0 else 180.0) + (0.0 if along_x else 90.0)
		root.add_child(lb)
	_nav.add_child(root)
	return root
