class_name Grenade
extends RigidBody3D
## Frag grenade: bounces, explodes FUSE seconds after the throw. Damage falls off
## from DMG_MAX at the center to DMG_MIN at RADIUS and is blocked by cover (line
## of sight from the blast). Team rules: no damage to the thrower's teammates;
## the thrower takes SELF_MULT of the damage.

const FUSE := 2.5
const RADIUS := 4.0
const DMG_MAX := 100.0
const DMG_MIN := 20.0
const SELF_MULT := 0.5
const SPEED := 14.0          # player throw speed (m/s)
const G := 9.8

var thrower: Node = null
var team := -1
var _t := 0.0
var _done := false

static func spawn(parent: Node, origin: Vector3, vel: Vector3, by: Node) -> Grenade:
	var g := Grenade.new()
	g.thrower = by
	g.team = int(by.team) if by != null and "team" in by else -1
	parent.add_child(g)
	g.global_position = origin
	g.linear_velocity = vel
	g.angular_velocity = Vector3(randf_range(-8, 8), randf_range(-8, 8), randf_range(-8, 8))
	if by is PhysicsBody3D:
		g.add_collision_exception_with(by)
	return g

func _ready() -> void:
	mass = 0.4
	linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	linear_damp = 0.0                     # match the trajectory preview (no drag)
	angular_damp = 1.5
	continuous_cd = true
	var pm := PhysicsMaterial.new(); pm.bounce = 0.32; pm.friction = 0.7
	physics_material_override = pm
	var col := CollisionShape3D.new()
	var sh := SphereShape3D.new(); sh.radius = 0.09
	col.shape = sh; add_child(col)
	var vis := Grenade.mesh(); vis.scale = Vector3.ONE * 1.5   # readable in flight
	add_child(vis)

static func mesh() -> Node3D:
	# olive body + dark lever/cap, ~10 cm
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 0.075; sm.height = 0.17; body.mesh = sm
	var m := StandardMaterial3D.new(); m.albedo_color = Color(0.30, 0.36, 0.22); m.roughness = 0.8
	body.material_override = m
	root.add_child(body)
	var cap := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 0.03; cm.bottom_radius = 0.035; cm.height = 0.05
	cap.mesh = cm; cap.position = Vector3(0, 0.095, 0)
	var dm := StandardMaterial3D.new(); dm.albedo_color = Color(0.12, 0.12, 0.13)
	cap.material_override = dm
	root.add_child(cap)
	var lever := MeshInstance3D.new()
	var lm := BoxMesh.new(); lm.size = Vector3(0.02, 0.09, 0.025); lever.mesh = lm
	lever.position = Vector3(0.05, 0.06, 0); lever.material_override = dm
	root.add_child(lever)
	return root

func _physics_process(dt: float) -> void:
	_t += dt
	if _t >= FUSE and not _done:
		_done = true
		_explode()

func _explode() -> void:
	var at := global_position + Vector3(0, 0.15, 0)
	var space := get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var sh := SphereShape3D.new(); sh.radius = RADIUS
	q.shape = sh
	q.transform = Transform3D(Basis.IDENTITY, at)
	q.exclude = [get_rid()]
	var seen := {}
	for r in space.intersect_shape(q, 48):
		var c = r["collider"]
		if c == null or seen.has(c) or not c.has_method("hit"):
			continue
		seen[c] = true
		var center: Vector3 = (c as Node3D).global_position + Vector3(0, 0.9, 0)
		var d := at.distance_to(center)
		if d > RADIUS:
			continue
		# cover: the first thing between the blast and the target must be the target
		var ray := PhysicsRayQueryParameters3D.create(at, center)
		ray.exclude = [get_rid()]
		var h := space.intersect_ray(ray)
		if h and h["collider"] != c:
			continue
		var dmg := lerpf(DMG_MAX, DMG_MIN, clampf(d / RADIUS, 0.0, 1.0))
		if c == thrower:
			c.hit(int(dmg * SELF_MULT), false, null)        # self damage, no kill credit
		elif team != -1 and "team" in c and int(c.team) == team:
			continue                                         # teammates are safe
		else:
			c.hit(int(dmg), false, thrower)
	_fx(at)
	queue_free()

func _fx(at: Vector3) -> void:
	var root := get_tree().current_scene
	if root == null: return
	var ball := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 1.0; sm.height = 2.0; ball.mesh = sm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.0, 0.62, 0.18, 0.85)
	ball.material_override = m
	root.add_child(ball)
	ball.global_position = at
	ball.scale = Vector3.ONE * 0.3
	var light := OmniLight3D.new(); light.light_color = Color(1.0, 0.7, 0.35)
	light.light_energy = 6.0; light.omni_range = 9.0
	root.add_child(light); light.global_position = at + Vector3(0, 0.6, 0)
	var tw := root.create_tween().set_parallel(true)
	tw.tween_property(ball, "scale", Vector3.ONE * RADIUS * 0.8, 0.28)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.35)
	tw.tween_property(light, "light_energy", 0.0, 0.35)
	tw.chain().tween_callback(func() -> void:
		ball.queue_free(); light.queue_free())
	Sfx.play_at("boom", at)
	# shake/vibrate scaled by how close the local player is
	var p: Node3D = null
	for n in get_tree().get_nodes_in_group("combatant"):
		if n is PlayerBody: p = n
	var near := 1.0
	if p: near = clampf(1.0 - p.global_position.distance_to(at) / 18.0, 0.0, 1.0)
	if near > 0.0:
		Controls.add_shake(0.7 * near)
		Controls.vibrate(int(60 + 140 * near))

# ---- ballistics shared by the preview and the bots ----
static func simulate(space: PhysicsDirectSpaceState3D, origin: Vector3, vel: Vector3, exclude: Array, max_t := 3.0) -> Dictionary:
	# returns {"points": PackedVector3Array, "hit": Vector3, "landed": bool}
	var pts := PackedVector3Array([origin])
	var p := origin
	var v := vel
	var dt := 0.04
	var t := 0.0
	while t < max_t:
		var np := p + v * dt
		v.y -= G * dt
		var ray := PhysicsRayQueryParameters3D.create(p, np)
		ray.exclude = exclude
		var h := space.intersect_ray(ray)
		if h:
			pts.append(h["position"])
			return {"points": pts, "hit": h["position"], "landed": true}
		pts.append(np)
		p = np
		t += dt
	return {"points": pts, "hit": p, "landed": false}

static func lob_velocity(from: Vector3, to: Vector3) -> Vector3:
	# fixed-flight-time lob (used by bots): farther -> longer air time
	var flat := Vector2(to.x - from.x, to.z - from.z).length()
	var t := clampf(flat / 11.0, 0.7, 1.6)
	var v := (to - from) / t
	v.y = (to.y - from.y + 0.5 * G * t * t) / t
	return v
