class_name TeamTags
extends Node3D
## Who is who, at a glance (all modes):
##  - every teammate: a blue arrow + name above the head, seen through walls
##  - an enemy under the crosshair (in plain sight): red arrow + name
## Created by the Radar, so every mode with a radar gets it.

const ALLY := Color(0.35, 0.75, 1.0)
const ENEMY := Color(1.0, 0.28, 0.22)
const HEAD := 2.45            # marker height above the feet (m)
var player: Node3D
var _tags := {}               # combatant -> [arrow Sprite3D, name Label3D]
static var _arrow: ImageTexture

static func _arrow_tex() -> ImageTexture:
	if _arrow: return _arrow
	var n := 64
	var im := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			# downward triangle with a dark outline
			var t := float(y) / (n - 1)                     # 0 top .. 1 tip
			var half := (1.0 - t) * 0.5 * (n - 1)
			var dx := absf(x - (n - 1) * 0.5)
			if t < 0.92 and dx <= half:
				var edge := minf(half - dx, minf(float(y) - 2.0, (0.92 - t) * n))
				im.set_pixel(x, y, Color(1, 1, 1, 1) if edge > 4.0 else Color(0.05, 0.05, 0.06, 1))
	_arrow = ImageTexture.create_from_image(im)
	return _arrow

func _on_my_side(n) -> bool:
	var pt: int = int(player.team) if "team" in player else -1
	return pt != -1 and "team" in n and int(n.team) == pt

func _make(col: Color, nm: String) -> Array:
	var sp := Sprite3D.new()
	sp.texture = _arrow_tex(); sp.modulate = col
	sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED; sp.no_depth_test = true; sp.fixed_size = true
	sp.pixel_size = 0.0006; sp.render_priority = 10; sp.shaded = false
	add_child(sp)
	var lb := Label3D.new()
	lb.text = nm; lb.modulate = col; lb.outline_modulate = Color(0, 0, 0, 0.85); lb.outline_size = 10
	lb.font_size = 40; lb.pixel_size = 0.0012; lb.fixed_size = true
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED; lb.no_depth_test = true; lb.render_priority = 10
	add_child(lb)
	return [sp, lb]

func _process(_dt: float) -> void:
	if player == null or not is_instance_valid(player): return
	var cam := get_viewport().get_camera_3d()
	# enemy under the crosshair, in plain sight
	var aimed: Node3D = null
	if cam and "alive" in player and player.alive:
		var mid := get_viewport().get_visible_rect().size * 0.5
		var best := 70.0
		for n in get_tree().get_nodes_in_group("combatant"):
			if n == player or not n.alive or _on_my_side(n): continue
			var hp: Vector3 = (n as Node3D).global_position + Vector3(0, 1.2, 0)
			if cam.is_position_behind(hp): continue
			var d := cam.unproject_position(hp).distance_to(mid)
			if d < best: best = d; aimed = n
		if aimed:
			var q := PhysicsRayQueryParameters3D.create(cam.global_position, aimed.global_position + Vector3(0, 1.2, 0))
			if player is CollisionObject3D: q.exclude = [(player as CollisionObject3D).get_rid()]
			var h := get_world_3d().direct_space_state.intersect_ray(q)
			if not (h.is_empty() or h["collider"] == aimed): aimed = null
	var live := {}
	for n in get_tree().get_nodes_in_group("combatant"):
		if n == player or not is_instance_valid(n): continue
		var ally := _on_my_side(n)
		var show: bool = n.alive and (ally or n == aimed)
		if not show:
			if _tags.has(n): for x in _tags[n]: x.visible = false
			continue
		live[n] = true
		if not _tags.has(n): _tags[n] = _make(ALLY if ally else ENEMY, String(n.get("bot_name")) if "bot_name" in n else "")
		var col := ALLY if ally else ENEMY
		var p: Vector3 = (n as Node3D).global_position
		var t: Array = _tags[n]
		t[0].visible = true; t[1].visible = true
		t[0].modulate = col; t[1].modulate = col
		t[0].global_position = p + Vector3(0, HEAD, 0)
		t[1].global_position = p + Vector3(0, HEAD + 0.42, 0)
		if cam:                      # far allies: arrow only (names would clutter)
			t[1].visible = not ally or cam.global_position.distance_to(p) < 22.0
	for n in _tags.keys():
		if not is_instance_valid(n):
			for x in _tags[n]: if is_instance_valid(x): x.queue_free()
			_tags.erase(n)
