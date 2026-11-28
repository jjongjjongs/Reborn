class_name FlameJet
extends Node3D
## flamethrower stream: lives in the scene, follows the nozzle; `feed(pos, dir)` every fire tick keeps it on
## (it goes out ~0.12 s after the last feed, the particles already in the air keep rolling and fade).
## Layers: white-hot core jet, billowing orange flame that swells and climbs, grey smoke at the tail,
## a flickering cone of fire right at the nozzle, and a light that lights up the ground / walls.
var _core: CPUParticles3D
var _body: CPUParticles3D
var _smoke: CPUParticles3D
var _cone: MeshInstance3D
var _light: OmniLight3D
var _on_t := 0.0
var _fed := false
var _t := 0.0
var fp := false                       # first person: a bit thinner / dimmer near the camera

static func _curve(pts: Array) -> Curve:
	var c := Curve.new(); c.max_value = 4.0
	for p in pts: c.add_point(p)
	return c

func _emitter(n: int, life: float, size: float, add: bool, vel: Vector2, spread: float, damp: Vector2, grav: Vector3, curve: Curve, ramp: Gradient) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = n; p.lifetime = life; p.local_coords = false; p.emitting = false
	var q := QuadMesh.new(); q.size = Vector2.ONE * size; p.mesh = q
	p.material_override = FxCos.glow_mat("glow", add)
	p.direction = Vector3(0, 0, -1); p.spread = spread
	p.initial_velocity_min = vel.x; p.initial_velocity_max = vel.y
	p.damping_min = damp.x; p.damping_max = damp.y; p.gravity = grav
	p.scale_amount_curve = curve; p.color_ramp = ramp
	p.angle_min = 0.0; p.angle_max = 360.0; p.angular_velocity_min = -90.0; p.angular_velocity_max = 90.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE; p.emission_sphere_radius = 0.04
	add_child(p); return p

func _ready() -> void:
	top_level = true
	_core = _emitter(80, 0.34, 0.4, true, Vector2(20, 24), 3.0, Vector2(4, 6), Vector3(0, 1.5, 0),
		_curve([Vector2(0, 0.5), Vector2(0.5, 1.6), Vector2(1, 2.4)]),
		FxCos.ramp([Color(1, 1, 0.9, 0.9), Color(1, 0.85, 0.4, 0.8), Color(1, 0.5, 0.1, 0.4), Color(0.8, 0.2, 0.05, 0.0)]))
	_body = _emitter(150, 0.75, 0.8, true, Vector2(16, 20), 7.0, Vector2(9, 12), Vector3(0, 3.5, 0),
		_curve([Vector2(0, 0.4), Vector2(0.3, 1.5), Vector2(1, 3.8)]),
		FxCos.ramp([Color(1, 0.9, 0.55, 0.0), Color(1, 0.62, 0.15, 0.75), Color(0.95, 0.3, 0.06, 0.55), Color(0.4, 0.08, 0.03, 0.0)]))
	_smoke = _emitter(1, 1.2, 0.9, false, Vector2(15, 18), 10.0, Vector2(9, 11), Vector3(0, 2.2, 0),
		_curve([Vector2(0, 0.5), Vector2(1, 3.5)]),
		FxCos.ramp([Color(0.5, 0.48, 0.46, 0.0), Color(0.5, 0.48, 0.46, 0.0), Color(0.45, 0.43, 0.41, 0.25), Color(0.55, 0.53, 0.5, 0.0)]))
	_smoke.emission_sphere_radius = 0.3; _smoke.position = Vector3(0, 0, -2.5); _smoke.visible = false   # (dark sprites read as holes: the flame tail fades out instead)
	_cone = MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 0.025; cm.bottom_radius = 0.16; cm.height = 1.1; cm.radial_segments = 12; cm.rings = 1; cm.cap_top = false; cm.cap_bottom = false
	_cone.mesh = cm
	var m := StandardMaterial3D.new(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD; m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(1.0, 0.6, 0.2, 0.55); m.albedo_texture = FxCos.tex("glow")
	_cone.material_override = m; _cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_cone); _cone.rotation_degrees = Vector3(-90, 0, 0); _cone.position = Vector3(0, 0, -0.55)
	_light = OmniLight3D.new(); _light.light_color = Color(1.0, 0.55, 0.2); _light.omni_range = 7.0; _light.light_energy = 0.0
	add_child(_light); _light.position = Vector3(0, 0, -2.5)

func feed(pos: Vector3, dir: Vector3) -> void:
	global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT), pos)
	_fed = true

func _process(dt: float) -> void:
	_t += dt; _on_t -= dt
	if _fed: _on_t = maxf(0.14, dt * 1.5); _fed = false       # fed since the last frame: stay lit, whatever the frame rate
	var on := _on_t > 0.0
	_core.emitting = on; _body.emitting = on; _smoke.emitting = on
	_cone.visible = on
	var k := 0.42 if fp else 1.0                      # first person: the flame fills the screen, so much dimmer
	for e in [_core, _body]: (e.material_override as StandardMaterial3D).albedo_color = Color(1, 1, 1, k)
	var fl := 0.8 + 0.35 * sin(_t * 47.0) * sin(_t * 23.0)
	if on: _cone.scale = Vector3(fl, 0.85 + 0.25 * fl, fl) * (0.7 if fp else 1.0)
	_light.light_energy = move_toward(_light.light_energy, (1.4 if fp else 2.8) * fl if on else 0.0, dt * 30.0)
