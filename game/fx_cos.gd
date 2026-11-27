class_name FxCos
## Shop cosmetics: kill effects (on a target you killed) and bullet tracers. CPU particles only
## (GL compatibility renderer), short (< 1.2 s) and few particles so a 12-player match stays smooth.

const KILLS := ["kill_fire", "kill_bolt", "kill_pixel", "kill_soul", "kill_coin"]
const TRACERS := ["tr_basic", "tr_neon", "tr_flame", "tr_rainbow", "tr_plasma"]

static func _mat(c: Color, glow := 2.0, alpha := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	if alpha < 1.0: m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = glow > 0.0; m.emission = c; m.emission_energy_multiplier = glow
	m.vertex_color_use_as_albedo = true
	return m

static func _burst(parent: Node, pos: Vector3, mesh: Mesh, mat: Material, n: int, vel: Vector2, life: float,
		grav := Vector3(0, -9.8, 0), spread := 180.0, dir := Vector3.UP, ramp: Gradient = null, scl := Vector2(1, 1)) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.one_shot = true; p.explosiveness = 0.92; p.amount = n; p.lifetime = life
	p.mesh = mesh; p.material_override = mat
	p.direction = dir; p.spread = spread; p.initial_velocity_min = vel.x; p.initial_velocity_max = vel.y
	p.gravity = grav; p.scale_amount_min = scl.x; p.scale_amount_max = scl.y
	if ramp: p.color_ramp = ramp
	parent.add_child(p); p.global_position = pos; p.emitting = true
	parent.get_tree().create_timer(life + 0.3).timeout.connect(p.queue_free)
	return p

static func _flash(parent: Node, pos: Vector3, c: Color, e := 4.0, r := 6.0, t := 0.12) -> void:
	var l := OmniLight3D.new(); l.light_color = c; l.light_energy = e; l.omni_range = r
	parent.add_child(l); l.global_position = pos
	parent.get_tree().create_timer(t).timeout.connect(l.queue_free)

static func _fade(c: Color) -> Gradient:
	var g := Gradient.new(); g.set_color(0, c); g.set_color(1, Color(c.r, c.g, c.b, 0.0)); return g

## a target died at `pos` (its feet): play the equipped kill effect
static func kill(id: String, parent: Node, pos: Vector3) -> void:
	var c := pos + Vector3(0, 1.1, 0)
	match id:
		"kill_fire":           # fireworks: two coloured spark bursts + a white pop
			var sm := SphereMesh.new(); sm.radius = 0.11; sm.height = 0.22; sm.radial_segments = 6; sm.rings = 3
			for k in 2:
				var col: Color = [Color(1.0, 0.35, 0.25), Color(0.35, 0.8, 1.0)][k]
				var g := Gradient.new(); g.set_color(0, Color.WHITE); g.add_point(0.25, col); g.set_color(1, Color(col.r, col.g, col.b, 0.0))
				_burst(parent, c + Vector3(0, 0.9 + 0.5 * k, 0), sm, _mat(col, 3.0), 70, Vector2(3.0, 6.0), 1.1, Vector3(0, -6, 0), 180.0, Vector3.UP, g)
			_flash(parent, c + Vector3(0, 1.2, 0), Color(1, 0.8, 0.6), 5.0, 8.0, 0.15)
		"kill_bolt":           # lightning from above + sparks on the ground
			var pts := [c + Vector3(0, 9, 0)]
			for i in 6: pts.append(pts[-1] + Vector3(randf_range(-0.7, 0.7), -1.5, randf_range(-0.7, 0.7)))
			pts[-1] = pos + Vector3(0, 0.05, 0)
			for i in pts.size() - 1:
				var a: Vector3 = pts[i]; var b: Vector3 = pts[i + 1]
				var m := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.16, 0.16, a.distance_to(b)); m.mesh = bm
				m.material_override = _mat(Color(0.75, 0.85, 1.0), 6.0); parent.add_child(m)
				m.global_position = (a + b) * 0.5; m.look_at(b, Vector3.RIGHT)
				parent.get_tree().create_timer(0.22).timeout.connect(m.queue_free)
			var bx := BoxMesh.new(); bx.size = Vector3(0.12, 0.12, 0.12)
			_burst(parent, pos + Vector3(0, 0.1, 0), bx, _mat(Color(0.7, 0.85, 1.0), 4.0), 40, Vector2(2.0, 4.5), 0.6, Vector3(0, -9, 0), 70.0, Vector3.UP, _fade(Color(0.8, 0.9, 1.0)))
			_flash(parent, c, Color(0.7, 0.8, 1.0), 8.0, 12.0, 0.18)
		"kill_pixel":          # the body breaks into flying cubes
			var bx := BoxMesh.new(); bx.size = Vector3(0.24, 0.24, 0.24)
			var g := Gradient.new(); g.set_color(0, Color(1.0, 0.55, 0.2)); g.add_point(0.6, Color(1.0, 0.85, 0.3)); g.set_color(1, Color(1.0, 0.9, 0.5, 0.0))
			var p := _burst(parent, c, bx, _mat(Color(1.0, 0.6, 0.25), 1.5), 70, Vector2(1.2, 3.2), 1.2, Vector3(0, 1.5, 0), 180.0, Vector3.UP, g, Vector2(0.6, 1.4))
			p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX; p.emission_box_extents = Vector3(0.3, 0.8, 0.2)
			p.angular_velocity_min = -360.0; p.angular_velocity_max = 360.0
		"kill_soul":           # a little ghost floats up and fades
			var gh := Node3D.new(); parent.add_child(gh); gh.global_position = c + Vector3(0, 0.4, 0)
			var body := MeshInstance3D.new(); var cap := CapsuleMesh.new(); cap.radius = 0.4; cap.height = 1.25; body.mesh = cap
			body.material_override = _mat(Color(0.85, 0.95, 1.0), 1.2, 0.65); gh.add_child(body)
			for sx in [-0.1, 0.1]:
				var e := MeshInstance3D.new(); var es := SphereMesh.new(); es.radius = 0.08; es.height = 0.16; e.mesh = es
				e.material_override = _mat(Color(0.05, 0.08, 0.15), 0.0); e.position = Vector3(sx * 1.4, 0.22, -0.36); gh.add_child(e)
			var tw := parent.create_tween().set_parallel(true)
			tw.tween_property(gh, "global_position", gh.global_position + Vector3(0, 2.4, 0), 1.1).set_ease(Tween.EASE_OUT)
			tw.tween_property(body.material_override, "albedo_color:a", 0.0, 1.1).set_ease(Tween.EASE_IN)
			tw.chain().tween_callback(gh.queue_free)
			var sm := SphereMesh.new(); sm.radius = 0.08; sm.height = 0.16
			_burst(parent, c, sm, _mat(Color(0.8, 0.95, 1.0), 2.0), 18, Vector2(0.3, 0.9), 1.0, Vector3(0, 1.2, 0), 180.0, Vector3.UP, _fade(Color(0.85, 0.95, 1.0)))
		"kill_coin":           # gold coins spray up and bounce away
			var cy := CylinderMesh.new(); cy.top_radius = 0.17; cy.bottom_radius = 0.17; cy.height = 0.04; cy.radial_segments = 12
			var cm := _mat(Color(1.0, 0.78, 0.2), 1.2)
			var p := _burst(parent, c + Vector3(0, 0.4, 0), cy, cm, 50, Vector2(3.0, 5.5), 1.2, Vector3(0, -12, 0), 35.0, Vector3.UP, null)
			p.angular_velocity_min = -540.0; p.angular_velocity_max = 540.0
			_flash(parent, c, Color(1.0, 0.85, 0.4), 3.0, 6.0, 0.15)

## a bullet tracer a -> b in the equipped style
static func tracer(id: String, parent: Node, a: Vector3, b: Vector3, hold := 0.0) -> void:
	var L := a.distance_to(b)
	if L < 0.01: return
	var life := hold if hold > 0.0 else 0.05
	var seg := func(p0: Vector3, p1: Vector3, w: float, col: Color, glow: float, alpha := 1.0) -> void:
		var m := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(w, w, p0.distance_to(p1)); m.mesh = bm
		m.material_override = _mat(col, glow, alpha); parent.add_child(m)
		m.global_position = (p0 + p1) * 0.5; m.look_at(p1, Vector3.UP)
		parent.get_tree().create_timer(life).timeout.connect(m.queue_free)
	match id:
		"tr_neon":             # thin hot core + soft cyan glow
			seg.call(a, b, 0.018, Color(0.85, 1.0, 1.0), 4.0)
			seg.call(a, b, 0.09, Color(0.1, 0.8, 1.0), 2.0, 0.35)
		"tr_flame":            # thick orange streak + embers
			seg.call(a, b, 0.05, Color(1.0, 0.55, 0.12), 3.0)
			seg.call(a, b, 0.13, Color(1.0, 0.3, 0.05), 1.5, 0.3)
			var sm := SphereMesh.new(); sm.radius = 0.035; sm.height = 0.07; sm.radial_segments = 6; sm.rings = 3
			var p := _burst(parent, (a + b) * 0.5, sm, _mat(Color(1.0, 0.5, 0.1), 3.0), 18, Vector2(0.2, 0.8), 0.45 + hold, Vector3(0, 1.5, 0), 180.0, Vector3.UP, _fade(Color(1.0, 0.6, 0.2)))
			p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX; p.emission_box_extents = Vector3(0.05, 0.05, L * 0.5)
			p.look_at_from_position((a + b) * 0.5, b, Vector3.UP)
		"tr_rainbow":          # six coloured pieces end to end
			var cols := [Color("ff4d4d"), Color("ffa63d"), Color("ffe14d"), Color("5be37d"), Color("4db8ff"), Color("b06bff")]
			for i in 6:
				seg.call(a.lerp(b, i / 6.0), a.lerp(b, (i + 1) / 6.0), 0.04, cols[i], 2.5)
		"tr_plasma":           # purple bolt with a bright head
			seg.call(a, b, 0.03, Color(0.75, 0.4, 1.0), 3.0)
			seg.call(a, b, 0.11, Color(0.55, 0.2, 1.0), 1.5, 0.3)
			var h := MeshInstance3D.new(); var hs := SphereMesh.new(); hs.radius = 0.12; hs.height = 0.24; h.mesh = hs
			h.material_override = _mat(Color(0.9, 0.7, 1.0), 5.0); parent.add_child(h); h.global_position = b
			parent.get_tree().create_timer(life + 0.03).timeout.connect(h.queue_free)
		_:                     # tr_basic: the current yellow streak
			seg.call(a, b, 0.03, Color(1, 0.85, 0.4), 1.5)
