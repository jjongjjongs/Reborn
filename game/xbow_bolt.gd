class_name XbowBolt
extends Node3D
## explosive crossbow bolt: flies (fast, a little drop), sticks where it hits - in a zombie it rides along -
## blinks red for `fuse` s, then blows up: damage falling off over `radius`, zombies thrown back, fireball,
## sparks, smoke, a ring on the ground, a light flash, the boom, screen shake by distance
const SPEED := 42.0
const GRAV := 6.0
var vel := Vector3.ZERO
var by: Node
var dmg_max := 140.0
var dmg_min := 35.0
var radius := 3.0
var fuse := 0.5
var _stuck := false
var _t := 0.0
var _life := 0.0
var _light: OmniLight3D
var _ex: Array[RID] = []

static func fire(parent: Node, at: Vector3, dir: Vector3, shooter: Node) -> XbowBolt:
	var b := XbowBolt.new(); b.vel = dir.normalized() * SPEED; b.by = shooter
	if shooter is CollisionObject3D: b._ex = [(shooter as CollisionObject3D).get_rid()]
	parent.add_child(b); b.global_position = at
	return b

func _ready() -> void:
	var shaft := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.012; cm.bottom_radius = 0.012; cm.height = 0.55; cm.radial_segments = 8
	var sm := StandardMaterial3D.new(); sm.albedo_color = Color(0.7, 0.72, 0.75); sm.metallic = 0.7; cm.material = sm; shaft.mesh = cm
	shaft.rotation_degrees = Vector3(90, 0, 0); shaft.position = Vector3(0, 0, 0.2); add_child(shaft)
	var head := MeshInstance3D.new(); var hm := CylinderMesh.new(); hm.top_radius = 0.035; hm.bottom_radius = 0.035; hm.height = 0.1; hm.radial_segments = 12
	var rm := StandardMaterial3D.new(); rm.albedo_color = Color(0.85, 0.12, 0.08); rm.emission_enabled = true; rm.emission = Color(0.5, 0.05, 0.02); hm.material = rm
	head.mesh = hm; head.rotation_degrees = Vector3(90, 0, 0); head.position = Vector3(0, 0, -0.08); add_child(head)
	var fl := MeshInstance3D.new(); var qm := QuadMesh.new(); qm.size = Vector2(0.07, 0.12); fl.mesh = qm
	var om := StandardMaterial3D.new(); om.albedo_color = Color(1.0, 0.55, 0.1); om.cull_mode = BaseMaterial3D.CULL_DISABLED; qm.material = om
	fl.position = Vector3(0, 0.03, 0.42); fl.rotation_degrees = Vector3(0, 90, 0); add_child(fl)
	_light = OmniLight3D.new(); _light.light_color = Color(1.0, 0.15, 0.1); _light.omni_range = 2.5; _light.light_energy = 0.0
	_light.position = Vector3(0, 0, -0.08); add_child(_light)
	for c in get_children(): if c is GeometryInstance3D: (c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _physics_process(dt: float) -> void:
	_life += dt
	if _stuck:
		_t += dt
		var blink := fmod(_t, 0.12) < 0.06
		_light.light_energy = 3.0 if blink else 0.3
		if _t >= fuse: _explode()
		return
	if _life > 4.0: _explode(); return
	vel.y -= GRAV * dt
	var to := global_position + vel * dt
	var q := PhysicsRayQueryParameters3D.create(global_position, to); q.exclude = _ex
	var h := get_world_3d().direct_space_state.intersect_ray(q)
	if h:
		var d := vel.normalized()
		global_position = (h["position"] as Vector3) - d * 0.12
		look_at(global_position + d, Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT)
		var col = h["collider"]
		if col is Node3D and col.has_method("hit"):           # rides along in the zombie
			var gt := global_transform; get_parent().remove_child(self); (col as Node3D).add_child(self); global_transform = gt
			col.hit(20, false, by)
		_stuck = true; Sfx.play_at("ding", global_position, -6.0)
		return
	look_at(to, Vector3.UP if absf(vel.normalized().y) < 0.95 else Vector3.RIGHT)
	global_position = to

func _explode() -> void:
	var at := global_position
	var sc := get_tree().current_scene
	var space := get_world_3d().direct_space_state
	var qs := PhysicsShapeQueryParameters3D.new(); var sh := SphereShape3D.new(); sh.radius = radius; qs.shape = sh
	qs.transform = Transform3D(Basis.IDENTITY, at)
	var seen := {}
	var hits: Array = space.intersect_shape(qs, 48)
	var bodies: Array[RID] = []                     # walls hide a zombie from the blast, other zombies do not
	for r in hits:
		if r["collider"] != null and r["collider"].has_method("hit"): bodies.append(r["rid"])
	for r in hits:
		var c = r["collider"]
		if c == null or seen.has(c) or not c.has_method("hit") or c == by: continue
		seen[c] = true
		var center: Vector3 = (c as Node3D).global_position + Vector3(0, 0.9, 0)
		var d := at.distance_to(center)
		if d > radius + 0.4: continue
		var ray := PhysicsRayQueryParameters3D.create(at, center); ray.exclude = bodies
		if not space.intersect_ray(ray).is_empty(): continue
		c.hit(int(lerpf(dmg_max, dmg_min, clampf(d / radius, 0.0, 1.0)) * Controls.dmg_mult), false, by)
		if c.has_method("knock"):
			var push: Vector3 = center - at; push.y = 0.0
			c.knock(push.normalized() * lerpf(9.0, 3.0, clampf(d / radius, 0.0, 1.0)) + Vector3(0, 0, 0), 0.45)
	_fx(sc, at)
	queue_free()

static func _fx(sc: Node, at: Vector3) -> void:
	# fireball: a glowing ball that swells to ~2/3 of the radius and burns out over half a second
	var ball := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 1.0; sm.height = 2.0; sm.radial_segments = 20; sm.rings = 10; ball.mesh = sm
	var m := StandardMaterial3D.new(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD                       # glows over the scene instead of an opaque bubble
	m.rim_enabled = false; m.albedo_color = Color(1.0, 0.75, 0.35, 0.7); ball.material_override = m; ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sc.add_child(ball); ball.global_position = at + Vector3(0, 0.4, 0); ball.scale = Vector3.ONE * 0.3
	var tw := ball.create_tween().set_parallel(true)
	tw.tween_property(ball, "scale", Vector3.ONE * 1.4, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(m, "albedo_color", Color(0.8, 0.25, 0.05, 0.0), 0.3).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(ball.queue_free)
	FxCos.pop(sc, at, Color(1.0, 0.9, 0.6), 4.0, 0.25)
	# billowing fire: big soft sprites thrown out, braking, then rising as they cool
	FxCos.burst(sc, at + Vector3(0, 0.3, 0), {"n": 60, "life": 1.0, "size": 1.3, "mat": FxCos.glow_mat("glow"), "dir": Vector3.UP, "spread": 180.0, "vel": Vector2(4.0, 8.0),
		"grav": Vector3(0, 3.0, 0), "damp": Vector2(8, 11), "rot": true, "spin": 2.0, "scale": Vector2(0.7, 1.5), "expl": 0.8,
		"ramp": FxCos.ramp([Color(1, 0.95, 0.7, 1.0), Color(1, 0.6, 0.15, 0.9), Color(0.8, 0.2, 0.05, 0.5), Color(0.2, 0.1, 0.05, 0.0)])})
	FxCos.burst(sc, at, {"n": 24, "life": 0.7, "size": 0.08, "dir": Vector3.UP, "spread": 80.0, "vel": Vector2(6.0, 12.0),
		"grav": Vector3(0, -14, 0), "color": Color(1.0, 0.8, 0.4)})
	FxCos.burst(sc, at + Vector3(0, 0.8, 0), {"n": 12, "life": 1.6, "size": 1.1, "mat": FxCos.glow_mat("glow"), "dir": Vector3.UP, "spread": 50.0,
		"vel": Vector2(1.0, 2.5), "grav": Vector3(0, 1.0, 0), "damp": Vector2(1, 2), "scale": Vector2(1.0, 2.2), "color": Color(0.35, 0.3, 0.28, 0.35), "delay": 0.15})   # warm haze (dark sprites read as holes)
	FxCos.shock(sc, at + Vector3(0, 0.08, 0), Color(1.0, 0.75, 0.4, 0.8), 3.0, 0.4)
	FxCos.flash(sc, at + Vector3(0, 0.6, 0), Color(1.0, 0.7, 0.35), 7.0, 10.0, 0.35)
	Sfx.play_at("boom", at)
	var p: Node3D = null
	for n in sc.get_tree().get_nodes_in_group("combatant"):
		if n is PlayerBody: p = n
	var near := 1.0
	if p: near = clampf(1.0 - p.global_position.distance_to(at) / 18.0, 0.0, 1.0)
	if near > 0.0: Controls.add_shake(0.6 * near); Controls.vibrate(int(50 + 120 * near))
