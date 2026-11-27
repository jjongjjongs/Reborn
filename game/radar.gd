class_name Radar
extends Control
## Top-left radar (replaces the HP bar; HP sits under it). The map image is a
## one-time top-down render of the level; the radar turns with the player so
## "up" is where you look. Teammates always show (live). An enemy shows for a few
## seconds (fading) when you or a teammate sees it, when it shoots at you / a teammate,
## or when it hits or is hit by your side. Zombies always show.
## Bomb mode adds the A/B sites and the planted bomb via `extras`.
## Tapping the radar opens the whole map (north up) with the same markers;
## any tap closes it again.

const R := 104.0               # radar radius (px)
const RANGE := 30.0            # metres from the centre to the rim
const PAD := Vector2(26, 20)

static var overview: Texture2D   # drawn map from the plan (MapPlan); null = render one
var player: Node3D
var bounds := Rect2(-35, -35, 70, 70)
var extras: Callable           # -> Array of {"pos": Vector3, "kind": "A"/"B"/"bomb"}
var _map_tex: Texture2D
var _map_rect: TextureRect
var _mat: ShaderMaterial
var _vp: SubViewport
var _spotted := {}            # enemy -> seconds left on the radar
const SHOW := 3.0             # how long a contact stays (fades over the last second)
const TEAM_SIGHT := 26.0      # teammates report what they can see within this range
static var _contacts := []     # [a, b]: a and b met (a shot at / hit b); filled by bots and the player
var _spot_cd := 0.0
var _font: Font
var _big: Control              # full-screen map overlay

const SHADER := """
shader_type canvas_item;
uniform sampler2D map_tex : filter_linear;
uniform vec2 center;
uniform float rot;
uniform vec2 span;
void fragment() {
	vec2 p = UV - 0.5;
	float d = length(p);
	if (d > 0.5) discard;
	float c = cos(rot); float s = sin(rot);
	vec2 q = vec2(c * p.x - s * p.y, s * p.x + c * p.y);
	vec2 uv = center + q * span;
	vec4 col = texture(map_tex, uv);
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) col = vec4(0.16, 0.18, 0.20, 1.0);
	col.rgb = mix(col.rgb, vec3(0.05, 0.06, 0.07), 0.2);
	COLOR = vec4(col.rgb, 0.9);
}
"""

func setup(p: Node3D, b: Rect2) -> Radar:
	player = p; bounds = b
	return self

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	position = PAD
	size = Vector2(R * 2, R * 2 + 30)
	_map_rect = TextureRect.new()
	_map_rect.size = Vector2(R * 2, R * 2)
	_map_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mat = ShaderMaterial.new()
	var sh := Shader.new(); sh.code = SHADER; _mat.shader = sh
	_map_rect.material = _mat
	add_child(_map_rect)
	_bake.call_deferred()
	Controls.map_open = false
	_big = Control.new()
	_big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_big.set_anchors_preset(Control.PRESET_FULL_RECT)
	_big.visible = false
	_big.draw.connect(_draw_big)
	_contacts.clear()
	_add_big.call_deferred()

func _add_big() -> void:
	var cl := CanvasLayer.new(); cl.layer = 50
	get_parent().add_child(cl)
	cl.add_child(_big)

func _exit_tree() -> void:
	Controls.map_open = false

# one top-down render of the level -> the radar's map image
func _bake() -> void:
	if player == null: return
	if overview != null:
		_map_tex = overview
		_map_rect.texture = _map_tex
		_mat.set_shader_parameter("map_tex", _map_tex)
		_mat.set_shader_parameter("span", Vector2(RANGE * 2.0 / bounds.size.x, RANGE * 2.0 / bounds.size.y))
		return
	_vp = SubViewport.new()
	var aspect := bounds.size.y / bounds.size.x
	_vp.size = Vector2i(1024, int(1024 * aspect))
	_vp.world_3d = player.get_world_3d()
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.transparent_bg = false
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.size = bounds.size.x
	cam.near = 0.5; cam.far = 120.0
	var c := bounds.get_center()
	_vp.add_child(cam)
	add_child(_vp)
	cam.global_transform = Transform3D(Basis.from_euler(Vector3(-PI * 0.5, 0, 0)), Vector3(c.x, 60.0, c.y))
	cam.current = true
	_map_tex = _vp.get_texture()
	_map_rect.texture = _map_tex           # (a TextureRect only draws with a texture set)
	_mat.set_shader_parameter("map_tex", _map_tex)
	_mat.set_shader_parameter("span", Vector2(RANGE * 2.0 / bounds.size.x, RANGE * 2.0 / bounds.size.y))
	# render a few frames (the first one can miss the camera transform), then freeze the image
	for i in 4:
		await get_tree().process_frame
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED

func _yaw() -> float:
	return player.rotation.y

func _to_radar(w: Vector3) -> Variant:
	# world point -> radar pixel (null when outside the rim)
	var d := Vector2(w.x - player.global_position.x, w.z - player.global_position.z) / RANGE * 0.5
	var th := _yaw()
	var p := Vector2(cos(th) * d.x - sin(th) * d.y, sin(th) * d.x + cos(th) * d.y)
	if p.length() > 0.5: return null
	return Vector2(R, R) + p * (R * 2.0)

func _process(dt: float) -> void:
	visible = not Controls.shop_open
	if player == null or not is_instance_valid(player): return
	var gp := player.global_position
	_mat.set_shader_parameter("center", Vector2((gp.x - bounds.position.x) / bounds.size.x, (gp.z - bounds.position.y) / bounds.size.y))
	_mat.set_shader_parameter("rot", -_yaw())
	for n in _spotted.keys():
		_spotted[n] = float(_spotted[n]) - dt
		if _spotted[n] <= 0.0 or not is_instance_valid(n) or not n.alive: _spotted.erase(n)
	_spot_cd -= dt
	if _spot_cd <= 0.0:
		_spot_cd = 0.2
		_update_spotted()
	Controls.radar_rect = Rect2(get_global_transform_with_canvas() * Vector2.ZERO, Vector2(R * 2, R * 2) * get_global_transform_with_canvas().get_scale())
	if Controls.map_open and not player.get("alive"):
		Controls.map_open = false
	_big.visible = Controls.map_open
	if _big.visible: _big.queue_redraw()
	queue_redraw()

func _is_enemy(n: Node) -> bool:
	var pt: int = int(player.team) if "team" in player else -1
	if pt == -1: return true
	return "team" in n and int(n.team) != pt

## a met b (a fired at b, or one hit the other): each becomes visible to the other's side
static func contact(a, b) -> void:
	if a == null or b == null or not is_instance_valid(a) or not is_instance_valid(b): return
	_contacts.append([a, b])
	if _contacts.size() > 64: _contacts = _contacts.slice(-64)

func _on_my_side(n) -> bool:
	if n == player: return true
	var pt: int = int(player.team) if "team" in player else -1
	return pt != -1 and is_instance_valid(n) and "team" in n and int(n.team) == pt

func _update_spotted() -> void:
	var space := player.get_world_3d().direct_space_state
	# eyes on our side: me (radar range) and every living teammate (shorter range)
	var eyes := [[player, RANGE * 1.2]]
	for n in get_tree().get_nodes_in_group("combatant"):
		if n != player and "alive" in n and n.alive and _on_my_side(n): eyes.append([n, TEAM_SIGHT])
	for n in get_tree().get_nodes_in_group("combatant"):
		if n == player or not ("alive" in n and n.alive) or not _is_enemy(n): continue
		var tgt: Vector3 = (n as Node3D).global_position + Vector3(0, 1.2, 0)
		for e in eyes:
			var eye: Vector3 = (e[0] as Node3D).global_position + Vector3(0, 1.5, 0)
			if eye.distance_to(tgt) > float(e[1]): continue
			var q := PhysicsRayQueryParameters3D.create(eye, tgt)
			q.exclude = [(e[0] as CollisionObject3D).get_rid()] if e[0] is CollisionObject3D else []
			var h := space.intersect_ray(q)
			if h.is_empty() or h["collider"] == n:
				_spotted[n] = SHOW; break
	# shots / hits between an enemy and our side
	for c in _contacts:
		var a = c[0]; var b = c[1]
		if not (is_instance_valid(a) and is_instance_valid(b)): continue
		if _on_my_side(b) and _is_enemy(a): _spotted[a] = SHOW
		if _on_my_side(a) and _is_enemy(b): _spotted[b] = SHOW
	_contacts.clear()

func _draw() -> void:
	var c := Vector2(R, R)
	draw_arc(c, R, 0.0, TAU, 64, Color(1.0, 0.6, 0.25, 0.75), 2.5, true)
	draw_arc(c, R * 0.5, 0.0, TAU, 48, Color(1, 1, 1, 0.10), 1.0, true)
	if player == null or not is_instance_valid(player): return
	# extras (sites, bomb)
	if extras.is_valid():
		for e in extras.call():
			var p = _to_radar(e["pos"])
			if p == null: continue
			match e["kind"]:
				"A", "B":
					var col := Color(1.0, 0.55, 0.15) if e["kind"] == "A" else Color(0.98, 0.78, 0.25)
					draw_string(_font, (p as Vector2) + Vector2(-7, 8), e["kind"], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, col)
				"bomb":
					if fmod(Time.get_ticks_msec() / 1000.0, 0.8) < 0.5:
						draw_circle(p, 7.0, Color(1.0, 0.2, 0.15))
	# people
	for n in get_tree().get_nodes_in_group("combatant"):
		if n == player or not ("alive" in n and n.alive): continue
		var p = _to_radar((n as Node3D).global_position)
		if p == null: continue
		if _is_enemy(n):
			if _spotted.has(n): draw_circle(p, 5.5, Color(1.0, 0.25, 0.2, clampf(float(_spotted[n]), 0.0, 1.0)))
		else:
			draw_circle(p, 5.0, Color(0.35, 0.75, 1.0))
			draw_arc(p, 5.0, 0.0, TAU, 12, Color(1, 1, 1, 0.7), 1.2)
	for z in get_tree().get_nodes_in_group("zombie"):
		var p = _to_radar((z as Node3D).global_position)
		if p != null: draw_circle(p, 5.0, Color(1.0, 0.3, 0.2))
	# the player: arrow pointing up
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -9), c + Vector2(7, 7), c + Vector2(0, 3), c + Vector2(-7, 7)]), Color(1, 1, 1))
	# HP under the radar
	var hp := float(Controls.hp) / float(maxi(1, Controls.hp_max))
	var y := R * 2.0 + 8.0
	draw_rect(Rect2(0, y, R * 2.0, 12), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(0, y, R * 2.0 * hp, 12), Color(0.88, 0.30, 0.25) if hp > 0.3 else Color(1.0, 0.18, 0.15))
	draw_string(_font, Vector2(R * 2.0 + 8, y + 12), "%d" % Controls.hp, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.9))


# ---------------------------------------------------------------- full map (tap the radar)
var _big_rect := Rect2()

func _big_pt(w: Vector3) -> Vector2:
	var u := (w.x - bounds.position.x) / bounds.size.x
	var v := (w.z - bounds.position.y) / bounds.size.y
	return _big_rect.position + Vector2(u, v) * _big_rect.size

func _draw_big() -> void:
	if _map_tex == null or player == null or not is_instance_valid(player): return
	var vs := _big.size
	_big.draw_rect(Rect2(Vector2.ZERO, vs), Color(0.02, 0.03, 0.04, 0.86))
	# fit the map (keeping its shape) into the screen, leaving room for the title
	var avail := Rect2(Vector2(vs.x * 0.06, 64), Vector2(vs.x * 0.88, vs.y - 110))
	var k := minf(avail.size.x / bounds.size.x, avail.size.y / bounds.size.y)
	var sz := bounds.size * k
	_big_rect = Rect2(avail.position + (avail.size - sz) * 0.5, sz)
	_big.draw_texture_rect(_map_tex, _big_rect, false, Color(1, 1, 1, 0.95))
	_big.draw_rect(_big_rect, Color(1.0, 0.6, 0.25, 0.8), false, 2.0)
	_big.draw_string(_font, Vector2(_big_rect.position.x, 46), "전체 지도", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 1, 1, 0.95))
	_big.draw_string(_font, Vector2(_big_rect.end.x - 220, 46), "아무 곳이나 눌러 닫기", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.6))
	_big.draw_string(_font, Vector2(_big_rect.get_center().x - 6, _big_rect.position.y - 6), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.7))
	if extras.is_valid():
		for e in extras.call():
			var p := _big_pt(e["pos"])
			match e["kind"]:
				"A", "B":
					var col := Color(1.0, 0.55, 0.15) if e["kind"] == "A" else Color(0.98, 0.78, 0.25)
					_big.draw_circle(p, 22.0, Color(col.r, col.g, col.b, 0.22))
					_big.draw_string(_font, p + Vector2(-10, 11), e["kind"], HORIZONTAL_ALIGNMENT_LEFT, -1, 32, col)
				"bomb":
					if fmod(Time.get_ticks_msec() / 1000.0, 0.8) < 0.5:
						_big.draw_circle(p, 9.0, Color(1.0, 0.2, 0.15))
	for n in get_tree().get_nodes_in_group("combatant"):
		if n == player or not ("alive" in n and n.alive): continue
		var p := _big_pt((n as Node3D).global_position)
		if _is_enemy(n):
			if _spotted.has(n): _big.draw_circle(p, 7.0, Color(1.0, 0.25, 0.2, clampf(float(_spotted[n]), 0.0, 1.0)))
		else:
			_big.draw_circle(p, 7.0, Color(0.35, 0.75, 1.0))
			_big.draw_arc(p, 7.0, 0.0, TAU, 16, Color(1, 1, 1, 0.8), 1.5)
	for z in get_tree().get_nodes_in_group("zombie"):
		_big.draw_circle(_big_pt((z as Node3D).global_position), 6.0, Color(1.0, 0.3, 0.2))
	# me: white arrow pointing where I look
	var me := _big_pt(player.global_position)
	var pts := PackedVector2Array()
	for q in [Vector2(0, -1.4), Vector2(0.85, 0.85), Vector2(0, 0.35), Vector2(-0.85, 0.85)]:
		pts.append(me + (q * 11.0).rotated(-_yaw()))
	_big.draw_colored_polygon(pts, Color(1, 1, 1))
	_big.draw_arc(me, 15.0, 0.0, TAU, 24, Color(1, 1, 1, 0.5), 1.5)
	# legend
	var ly := _big_rect.end.y + 26
	var lx := _big_rect.position.x
	for it in [["나", Color(1, 1, 1)], ["아군", Color(0.35, 0.75, 1.0)], ["발견된 적", Color(1.0, 0.25, 0.2)]]:
		_big.draw_circle(Vector2(lx + 6, ly - 6), 6.0, it[1])
		_big.draw_string(_font, Vector2(lx + 18, ly), it[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(1, 1, 1, 0.8))
		lx += 120
