class_name Radar
extends Control
## Top-left radar (replaces the HP bar; HP sits under it). The map image is a
## one-time top-down render of the level; the radar turns with the player so
## "up" is where you look. Teammates always show; enemies only while spotted
## (in your line of sight) or for a moment after they fire. Zombies always show.
## Bomb mode adds the A/B sites and the planted bomb via `extras`.

const R := 104.0               # radar radius (px)
const RANGE := 30.0            # metres from the centre to the rim
const PAD := Vector2(26, 20)

var player: Node3D
var bounds := Rect2(-35, -35, 70, 70)
var extras: Callable           # -> Array of {"pos": Vector3, "kind": "A"/"B"/"bomb"}
var _map_tex: Texture2D
var _map_rect: TextureRect
var _mat: ShaderMaterial
var _vp: SubViewport
var _spotted := {}
var _spot_cd := 0.0
var _font: Font

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
	col.rgb = mix(col.rgb, vec3(0.05, 0.06, 0.07), 0.35);
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

# one top-down render of the level -> the radar's map image
func _bake() -> void:
	if player == null: return
	_vp = SubViewport.new()
	var aspect := bounds.size.y / bounds.size.x
	_vp.size = Vector2i(512, int(512 * aspect))
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
	if player == null or not is_instance_valid(player): return
	var gp := player.global_position
	_mat.set_shader_parameter("center", Vector2((gp.x - bounds.position.x) / bounds.size.x, (gp.z - bounds.position.y) / bounds.size.y))
	_mat.set_shader_parameter("rot", -_yaw())
	_spot_cd -= dt
	if _spot_cd <= 0.0:
		_spot_cd = 0.2
		_update_spotted()
	queue_redraw()

func _is_enemy(n: Node) -> bool:
	var pt: int = int(player.team) if "team" in player else -1
	if pt == -1: return true
	return "team" in n and int(n.team) != pt

func _update_spotted() -> void:
	var space := player.get_world_3d().direct_space_state
	var eye := player.global_position + Vector3(0, 1.5, 0)
	for n in get_tree().get_nodes_in_group("combatant"):
		if n == player or not ("alive" in n and n.alive) or not _is_enemy(n): continue
		var tgt: Vector3 = (n as Node3D).global_position + Vector3(0, 1.2, 0)
		if eye.distance_to(tgt) > RANGE * 1.2:
			_spotted.erase(n); continue
		var q := PhysicsRayQueryParameters3D.create(eye, tgt)
		q.exclude = [player.get_rid()]
		var h := space.intersect_ray(q)
		var seen: bool = h.is_empty() or h["collider"] == n
		var fired: bool = "last_shot_t" in n and Time.get_ticks_msec() / 1000.0 - float(n.last_shot_t) < 1.5
		if seen or fired: _spotted[n] = 1.0
		else: _spotted.erase(n)

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
			if _spotted.has(n): draw_circle(p, 5.5, Color(1.0, 0.25, 0.2))
		else:
			draw_circle(p, 5.0, Color(0.35, 0.75, 1.0))
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
