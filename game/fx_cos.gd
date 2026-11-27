class_name FxCos
## Shop cosmetics: kill effects (on a target you killed) and bullet tracers.
## Look: soft additive glow sprites (generated textures), twinkling star glints, expanding shock rings,
## particles that shrink + fade with drag. CPU particles only (GL compatibility), every effect < 1.3 s.

const KILLS := ["kill_fire", "kill_bolt", "kill_pixel", "kill_soul", "kill_coin"]
const TRACERS := ["tr_basic", "tr_neon", "tr_flame", "tr_rainbow", "tr_plasma"]

static var _tex := {}

# ---------------------------------------------------------------- generated textures
static func tex(kind: String) -> ImageTexture:
	if _tex.has(kind): return _tex[kind]
	var n := 64
	var im := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := (n - 1) * 0.5
	for y in n:
		for x in n:
			var dx := (x - c) / c; var dy := (y - c) / c
			var d := sqrt(dx * dx + dy * dy)
			var a := 0.0
			match kind:
				"glow": a = pow(clampf(1.0 - d, 0.0, 1.0), 2.2)
				"core": a = pow(clampf(1.0 - d, 0.0, 1.0), 0.8)
				"star":           # 4-point glint + soft centre
					var arm := maxf(pow(clampf(1.0 - absf(dx) * 7.0, 0, 1), 2) * clampf(1.0 - absf(dy), 0, 1),
						pow(clampf(1.0 - absf(dy) * 7.0, 0, 1), 2) * clampf(1.0 - absf(dx), 0, 1))
					a = clampf(arm + pow(clampf(1.0 - d * 2.2, 0, 1), 2), 0, 1)
				"ring": a = pow(clampf(1.0 - absf(d - 0.78) * 7.0, 0.0, 1.0), 1.5)
				"smoke": a = pow(clampf(1.0 - d, 0.0, 1.0), 1.6) * (0.75 + 0.25 * sin(x * 0.7) * cos(y * 0.6))
			im.set_pixel(x, y, Color(1, 1, 1, clampf(a, 0.0, 1.0)))
	_tex[kind] = ImageTexture.create_from_image(im)
	return _tex[kind]

static func glow_mat(t: String = "glow", add := true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if add: m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_texture = tex(t)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.no_depth_test = false; m.disable_receive_shadows = true
	return m

static func ramp(cols: Array) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(range(cols.size()).map(func(i): return float(i) / float(cols.size() - 1)))
	g.colors = PackedColorArray(cols)
	return g

static func shrink(a := 1.0, b := 0.0) -> Curve:
	var cv := Curve.new(); cv.add_point(Vector2(0, a)); cv.add_point(Vector2(1, b)); return cv

static func pop_curve() -> Curve:            # grow fast, then shrink
	var cv := Curve.new(); cv.add_point(Vector2(0, 0.2)); cv.add_point(Vector2(0.15, 1.0)); cv.add_point(Vector2(1, 0.0)); return cv

## one-shot particle burst
static func burst(parent: Node, pos: Vector3, o: Dictionary) -> CPUParticles3D:
	var delay := float(o.get("delay", 0.0))
	if delay > 0.0:                 # create it later (a one-shot switched on late emits only a few particles)
		var o2 := o.duplicate(); o2.erase("delay")
		parent.get_tree().create_timer(delay).timeout.connect(func() -> void: if is_instance_valid(parent): burst(parent, pos, o2))
		return null
	var p := CPUParticles3D.new()
	p.one_shot = true; p.explosiveness = minf(float(o.get("expl", 0.8)), 0.8)    # (near 1.0 CPU one-shots can emit nothing on some frames); p.amount = int(o.get("n", 30))
	p.lifetime = float(o.get("life", 0.8)); p.local_coords = false
	var q := QuadMesh.new(); q.size = Vector2.ONE * float(o.get("size", 0.3)); p.mesh = o.get("mesh", q)
	p.material_override = o.get("mat", glow_mat(String(o.get("tex", "glow"))))
	p.direction = o.get("dir", Vector3.UP); p.spread = float(o.get("spread", 180.0))
	var v: Vector2 = o.get("vel", Vector2(2, 4)); p.initial_velocity_min = v.x; p.initial_velocity_max = v.y
	p.gravity = o.get("grav", Vector3(0, -4, 0))
	var dmp: Vector2 = o.get("damp", Vector2(0, 0)); p.damping_min = dmp.x; p.damping_max = dmp.y
	var sc: Vector2 = o.get("scale", Vector2(0.7, 1.2)); p.scale_amount_min = sc.x; p.scale_amount_max = sc.y
	p.scale_amount_curve = o.get("curve", shrink())
	if o.has("ramp"): p.color_ramp = o["ramp"]
	if o.has("color"): p.color = o["color"]
	if o.has("box"): p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX; p.emission_box_extents = o["box"]
	if o.has("sphere"): p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE; p.emission_sphere_radius = o["sphere"]
	if o.has("spin"): p.angular_velocity_min = -float(o["spin"]); p.angular_velocity_max = float(o["spin"])
	if o.has("rot"): p.angle_min = 0.0; p.angle_max = 360.0
	parent.add_child(p); p.global_position = pos
	p.emitting = true
	parent.get_tree().create_timer(p.lifetime + 0.4).timeout.connect(p.queue_free)
	return p

static func flash(parent: Node, pos: Vector3, c: Color, e := 4.0, r := 6.0, t := 0.18) -> void:
	var l := OmniLight3D.new(); l.light_color = c; l.light_energy = e; l.omni_range = r
	parent.add_child(l); l.global_position = pos
	var tw := l.create_tween(); tw.tween_property(l, "light_energy", 0.0, t); tw.tween_callback(l.queue_free)

## flat ring on the ground that grows and fades (shock wave)
static func shock(parent: Node, pos: Vector3, c: Color, r_end := 2.4, t := 0.45, upright := false) -> void:
	var m := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(1, 1); m.mesh = q
	var mat := glow_mat("ring"); mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED if upright else BaseMaterial3D.BILLBOARD_DISABLED
	mat.albedo_color = c; mat.vertex_color_use_as_albedo = false; m.material_override = mat
	parent.add_child(m); m.global_position = pos
	if not upright: m.rotation_degrees = Vector3(-90, 0, 0)
	m.scale = Vector3.ONE * 0.2
	var tw := m.create_tween().set_parallel(true)
	tw.tween_property(m, "scale", Vector3.ONE * r_end * 2.0, t).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(mat, "albedo_color:a", 0.0, t).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(m.queue_free)

## one glowing sprite that pops and fades (centre flash) - a tweened billboard, not a particle
static func pop(parent: Node, pos: Vector3, c: Color, size := 1.6, t := 0.25) -> void:
	var m := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2.ONE * size * 0.55; m.mesh = q
	var mat := glow_mat("glow"); mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED; mat.vertex_color_use_as_albedo = false
	mat.albedo_color = Color(c.r, c.g, c.b, 0.75); m.material_override = mat
	parent.add_child(m); m.global_position = pos; m.scale = Vector3.ONE * 0.4
	var tw := m.create_tween().set_parallel(true)
	tw.tween_property(m, "scale", Vector3.ONE, t * 0.35).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, t).set_ease(Tween.EASE_IN).set_delay(t * 0.2)
	tw.chain().tween_callback(m.queue_free)

## the player killed `victim`: play the equipped kill effect where it fell
static func my_kill(victim: Node3D) -> void:
	if victim == null or not is_instance_valid(victim) or not victim.is_inside_tree(): return
	var id := Profile.equipped("killfx")
	if id == "kill_none" or id == "": return
	var col: Color = victim.get("tint") if victim.get("tint") is Color else Color(0.85, 0.45, 0.2)
	kill(id, victim.get_tree().current_scene, victim.global_position, col)

# ---------------------------------------------------------------- kill effects
## a target died at `pos` (its feet). `col` = a colour of the victim (pixel break-up)
static func kill(id: String, parent: Node, pos: Vector3, col := Color(0.35, 0.55, 0.9)) -> void:
	var c := pos + Vector3(0, 1.1, 0)
	match id:
		"kill_fire":           # fireworks: a rocket goes up, two shells burst (red + cyan) with glitter
			var top := c + Vector3(0, 2.2, 0)
			burst(parent, c, {"n": 14, "size": 0.18, "vel": Vector2(6.5, 7.0), "spread": 4.0, "grav": Vector3(0, -3, 0), "life": 0.35, "expl": 0.0,
				"ramp": ramp([Color(1, 0.9, 0.7, 1), Color(1, 0.6, 0.3, 0)])})
			for k in 2:
				var cc: Color = [Color(1.0, 0.32, 0.28), Color(0.3, 0.85, 1.0)][k]
				var at := top + Vector3(0.6 * (k * 2 - 1), 0.3 * k, 0)
				var d := 0.32 + 0.14 * k
				burst(parent, at, {"n": 70, "size": 0.2, "tex": "core", "vel": Vector2(3.5, 5.0), "damp": Vector2(3.0, 4.0), "grav": Vector3(0, -2.2, 0), "life": 1.1, "delay": d,
					"curve": shrink(1.0, 0.3), "ramp": ramp([Color(1, 1, 1, 1), cc, cc, Color(cc.r, cc.g, cc.b, 0.0)])})
				burst(parent, at, {"n": 40, "size": 0.55, "vel": Vector2(3.5, 5.0), "damp": Vector2(3.0, 4.0), "grav": Vector3(0, -2.2, 0), "life": 0.9, "delay": d,
					"ramp": ramp([Color(cc.r, cc.g, cc.b, 0.6), Color(cc.r, cc.g, cc.b, 0.0)])})
				burst(parent, at, {"n": 18, "size": 0.32, "tex": "star", "vel": Vector2(1.0, 3.0), "damp": Vector2(2, 3), "grav": Vector3(0, -1.2, 0), "life": 1.2, "delay": d + 0.25,
					"curve": pop_curve(), "ramp": ramp([Color(1, 1, 0.9, 1), Color(1, 0.95, 0.7, 0)]), "rot": true})
				parent.get_tree().create_timer(d).timeout.connect(func() -> void:
					if is_instance_valid(parent): pop(parent, at, cc, 2.4, 0.3); flash(parent, at, cc, 5.0, 9.0, 0.3))
		"kill_bolt":           # forked lightning from the sky, ground shock ring, sparks, scorch
			var pts := [c + Vector3(randf_range(-1, 1), 10, 0)]
			for i in 7: pts.append(pts[-1] + Vector3(randf_range(-0.7, 0.7), -1.35, randf_range(-0.5, 0.5)))
			pts[-1] = pos + Vector3(0, 0.05, 0)
			_bolt_line(parent, pts, 0.07, 0.5)
			for f in 2:                     # two side forks
				var s: Vector3 = pts[3 + f * 2]
				_bolt_line(parent, [s, s + Vector3(randf_range(-1.5, 1.5), -1.0, randf_range(-1, 1)), s + Vector3(randf_range(-2, 2), -2.2, randf_range(-1.2, 1.2))], 0.035, 0.35)
			shock(parent, pos + Vector3(0, 0.06, 0), Color(0.55, 0.75, 1.0), 2.6, 0.5)
			pop(parent, pos + Vector3(0, 0.4, 0), Color(0.7, 0.85, 1.0), 3.0, 0.35)
			burst(parent, pos + Vector3(0, 0.15, 0), {"n": 46, "size": 0.14, "vel": Vector2(3, 7), "spread": 75.0, "grav": Vector3(0, -14, 0), "life": 0.7,
				"ramp": ramp([Color(1, 1, 1, 1), Color(0.5, 0.75, 1.0, 1), Color(0.3, 0.5, 1.0, 0)])})
			flash(parent, c + Vector3(0, 2, 0), Color(0.75, 0.85, 1.0), 9.0, 14.0, 0.35)
			_scorch(parent, pos)
		"kill_pixel":          # the body breaks into shaded cubes in its own colours that tumble down and shrink
			var cols := [col, col.lightened(0.25), col.darkened(0.3), Color(0.95, 0.8, 0.65), Color(0.2, 0.2, 0.22)]
			for k in cols.size():
				var cube := BoxMesh.new(); cube.size = Vector3.ONE * 0.16
				var cm := StandardMaterial3D.new(); cm.albedo_color = cols[k]; cm.roughness = 0.6
				cm.emission_enabled = true; cm.emission = cols[k]; cm.emission_energy_multiplier = 0.25
				burst(parent, c, {"mesh": cube, "mat": cm, "n": 14, "vel": Vector2(1.5, 3.8), "spread": 70.0, "grav": Vector3(0, -9, 0), "life": 1.2,
					"box": Vector3(0.3, 0.75, 0.2), "scale": Vector2(0.6, 1.5), "spin": 400.0, "rot": true, "curve": shrink(1.0, 0.0)})
			pop(parent, c, Color(1, 1, 1), 2.0, 0.2)
			burst(parent, pos + Vector3(0, 0.2, 0), {"n": 10, "size": 0.9, "tex": "smoke", "vel": Vector2(0.3, 0.9), "spread": 80.0, "grav": Vector3(0, 0.4, 0), "life": 1.0,
				"curve": pop_curve(), "ramp": ramp([Color(0.9, 0.9, 0.9, 0.5), Color(0.7, 0.7, 0.7, 0.0)]), "mat": glow_mat("smoke", false)})
		"kill_soul":           # a small ghost with a wavy tail drifts up, sparkles trailing behind
			var gh := Node3D.new(); parent.add_child(gh); gh.global_position = c + Vector3(0, 0.2, 0)
			var body := MeshInstance3D.new(); var sp := SphereMesh.new(); sp.radius = 0.34; sp.height = 0.62; body.mesh = sp
			var bm := StandardMaterial3D.new(); bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			bm.albedo_color = Color(0.78, 0.9, 1.0, 0.72); bm.rim_enabled = false; body.material_override = bm; gh.add_child(body)
			var tail := MeshInstance3D.new(); var cn := CylinderMesh.new(); cn.top_radius = 0.33; cn.bottom_radius = 0.02; cn.height = 0.6; tail.mesh = cn
			tail.material_override = bm; tail.position = Vector3(0, -0.36, 0); gh.add_child(tail)
			var halo := MeshInstance3D.new(); var hq := QuadMesh.new(); hq.size = Vector2(1.6, 1.6); halo.mesh = hq
			var hm := glow_mat("glow"); hm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED; hm.vertex_color_use_as_albedo = false
			hm.albedo_color = Color(0.4, 0.75, 1.0, 0.45); halo.material_override = hm; gh.add_child(halo)
			for sx in [-0.11, 0.11]:
				var e := MeshInstance3D.new(); var es := SphereMesh.new(); es.radius = 0.055; es.height = 0.13; e.mesh = es
				var em := StandardMaterial3D.new(); em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; em.albedo_color = Color(0.1, 0.15, 0.3)
				e.material_override = em; e.position = Vector3(sx, 0.06, -0.3); gh.add_child(e)
			var trail := CPUParticles3D.new(); trail.amount = 24; trail.lifetime = 0.7; trail.local_coords = false
			var tq := QuadMesh.new(); tq.size = Vector2.ONE * 0.22; trail.mesh = tq; trail.material_override = glow_mat("star")
			trail.direction = Vector3.DOWN; trail.spread = 40.0; trail.initial_velocity_min = 0.2; trail.initial_velocity_max = 0.6
			trail.gravity = Vector3.ZERO; trail.scale_amount_curve = pop_curve(); trail.angle_max = 360.0
			trail.color_ramp = ramp([Color(0.8, 0.95, 1.0, 1), Color(0.5, 0.8, 1.0, 0)]); trail.position = Vector3(0, -0.4, 0)
			gh.add_child(trail)
			gh.scale = Vector3.ONE * 0.3
			var cam := parent.get_viewport().get_camera_3d()
			if cam: gh.look_at(Vector3(cam.global_position.x, gh.global_position.y, cam.global_position.z), Vector3.UP); gh.rotate_y(PI)
			var tw := gh.create_tween().set_parallel(true)
			tw.tween_property(gh, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(gh, "global_position:y", gh.global_position.y + 2.6, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw.tween_method(func(t: float) -> void: if is_instance_valid(body): body.position.x = sin(t * 9.0) * 0.12; tail.rotation.z = sin(t * 9.0 + 1.0) * 0.35, 0.0, 1.3, 1.3)
			tw.tween_property(bm, "albedo_color:a", 0.0, 0.45).set_delay(0.85)
			tw.tween_property(hm, "albedo_color:a", 0.0, 0.45).set_delay(0.85)
			tw.chain().tween_callback(gh.queue_free)
			pop(parent, c, Color(0.5, 0.8, 1.0), 1.6, 0.25)
			shock(parent, pos + Vector3(0, 0.06, 0), Color(0.55, 0.9, 1.0), 1.6, 0.6)
		"kill_coin":           # shiny gold coins fountain up and spin, star glints and a gold flash
			var cy := CylinderMesh.new(); cy.top_radius = 0.13; cy.bottom_radius = 0.13; cy.height = 0.035; cy.radial_segments = 16
			var gm := StandardMaterial3D.new(); gm.albedo_color = Color(1.0, 0.78, 0.25); gm.metallic = 0.9; gm.roughness = 0.25
			gm.emission_enabled = true; gm.emission = Color(1.0, 0.7, 0.2); gm.emission_energy_multiplier = 0.45
			burst(parent, c + Vector3(0, 0.3, 0), {"mesh": cy, "mat": gm, "n": 34, "vel": Vector2(4.0, 6.5), "spread": 28.0, "grav": Vector3(0, -13, 0),
				"life": 1.25, "spin": 720.0, "rot": true, "scale": Vector2(0.8, 1.2), "curve": shrink(1.0, 0.6), "expl": 0.75})
			burst(parent, c + Vector3(0, 0.8, 0), {"n": 22, "size": 0.38, "tex": "star", "vel": Vector2(1.5, 3.5), "grav": Vector3(0, -1.5, 0), "life": 1.0,
				"curve": pop_curve(), "rot": true, "ramp": ramp([Color(1, 0.95, 0.7, 1), Color(1, 0.8, 0.3, 0)]), "expl": 0.6})
			pop(parent, c, Color(1.0, 0.8, 0.3), 2.4, 0.3)
			flash(parent, c, Color(1.0, 0.8, 0.4), 4.0, 7.0, 0.3)
			var lb := Label3D.new(); lb.text = "+◆"; lb.font_size = 72; lb.pixel_size = 0.006; lb.modulate = Color(1.0, 0.85, 0.35)
			lb.outline_size = 12; lb.outline_modulate = Color(0.35, 0.2, 0.0); lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED; lb.no_depth_test = true
			parent.add_child(lb); lb.global_position = c + Vector3(0, 1.1, 0)
			var tw := lb.create_tween().set_parallel(true)
			tw.tween_property(lb, "global_position:y", lb.global_position.y + 0.9, 1.0).set_ease(Tween.EASE_OUT)
			tw.tween_property(lb, "modulate:a", 0.0, 0.4).set_delay(0.6)
			tw.chain().tween_callback(lb.queue_free)

static func _bolt_line(parent: Node, pts: Array, w: float, t: float) -> void:
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]; var b: Vector3 = pts[i + 1]
		for layer in 2:                          # white-hot core + wide blue glow
			var m := MeshInstance3D.new(); var bm := BoxMesh.new()
			var ww := w if layer == 0 else w * 3.0
			bm.size = Vector3(ww, ww, a.distance_to(b) + ww); m.mesh = bm
			var mat := StandardMaterial3D.new(); mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			mat.albedo_color = Color(1, 1, 1, 1) if layer == 0 else Color(0.35, 0.55, 1.0, 0.28)
			m.material_override = mat; parent.add_child(m)
			m.global_position = (a + b) * 0.5; m.look_at(b, Vector3.RIGHT)
			var tw := m.create_tween()
			tw.tween_property(mat, "albedo_color:a", 0.0, t).set_delay(0.06).set_ease(Tween.EASE_IN)
			tw.tween_callback(m.queue_free)

static func _scorch(parent: Node, pos: Vector3) -> void:
	var m := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(1.8, 1.8); m.mesh = q
	var mat := StandardMaterial3D.new(); mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = tex("glow"); mat.albedo_color = Color(0.05, 0.05, 0.08, 0.75); m.material_override = mat
	parent.add_child(m); m.global_position = pos + Vector3(0, 0.03, 0); m.rotation_degrees = Vector3(-90, 0, 0)
	var tw := m.create_tween(); tw.tween_property(mat, "albedo_color:a", 0.0, 1.0).set_delay(0.6); tw.tween_callback(m.queue_free)

# ---------------------------------------------------------------- tracers
## a bullet tracer a -> b in the equipped style; `hold` keeps it on screen (shop preview)
static func tracer(id: String, parent: Node, a: Vector3, b: Vector3, hold := 0.0) -> void:
	var L := a.distance_to(b)
	if L < 0.01: return
	var life := 0.09 + hold
	var seg := func(p0: Vector3, p1: Vector3, w: float, col: Color) -> void:
		var m := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(w, w, p0.distance_to(p1)); m.mesh = bm
		var mat := StandardMaterial3D.new(); mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD; mat.albedo_color = col
		m.material_override = mat; parent.add_child(m)
		m.global_position = (p0 + p1) * 0.5; m.look_at(p1, Vector3.UP)
		var tw := m.create_tween(); tw.tween_property(mat, "albedo_color:a", 0.0, 0.09).set_delay(hold); tw.tween_callback(m.queue_free)
	var hit := func(col: Color, n: int) -> void:      # small glow + sparks where it lands
		pop(parent, b, col, 0.6, 0.12 + hold * 0.3)
		burst(parent, b, {"n": n, "size": 0.08, "vel": Vector2(1.5, 3.5), "grav": Vector3(0, -8, 0), "life": 0.3 + hold * 0.3,
			"ramp": ramp([Color(1, 1, 1, 1), Color(col.r, col.g, col.b, 0)])})
	match id:
		"tr_neon":             # white-hot core inside a cyan glow
			seg.call(a, b, 0.016, Color(0.9, 1.0, 1.0, 1.0)); seg.call(a, b, 0.07, Color(0.1, 0.75, 1.0, 0.55)); seg.call(a, b, 0.16, Color(0.0, 0.5, 1.0, 0.18))
			hit.call(Color(0.2, 0.8, 1.0), 6)
		"tr_flame":            # orange streak, red haze, embers drifting up along it
			seg.call(a, b, 0.03, Color(1.0, 0.9, 0.5, 1.0)); seg.call(a, b, 0.1, Color(1.0, 0.45, 0.08, 0.5)); seg.call(a, b, 0.2, Color(1.0, 0.2, 0.0, 0.15))
			var p := burst(parent, (a + b) * 0.5, {"n": 22, "size": 0.12, "vel": Vector2(0.2, 0.7), "grav": Vector3(0, 1.4, 0), "life": 0.5 + hold,
				"box": Vector3(0.04, 0.04, L * 0.5), "expl": 1.0, "ramp": ramp([Color(1, 0.9, 0.4, 1), Color(1, 0.4, 0.1, 0.8), Color(0.6, 0.1, 0.0, 0)])})
			p.look_at_from_position((a + b) * 0.5, b, Vector3.UP)
			hit.call(Color(1.0, 0.5, 0.1), 8)
		"tr_rainbow":          # smooth band of colours along the shot
			var cols := [Color("ff4d4d"), Color("ff9a3d"), Color("ffe14d"), Color("5be37d"), Color("4db8ff"), Color("8f6bff"), Color("ff6bd5")]
			var n := 14
			for i in n:
				var t0 := float(i) / n; var t1 := float(i + 1) / n
				var k := t0 * (cols.size() - 1); var cc: Color = (cols[int(k)] as Color).lerp(cols[mini(int(k) + 1, cols.size() - 1)], k - int(k))
				seg.call(a.lerp(b, t0), a.lerp(b, t1), 0.035, Color(cc.r, cc.g, cc.b, 1.0)); seg.call(a.lerp(b, t0), a.lerp(b, t1), 0.11, Color(cc.r, cc.g, cc.b, 0.3))
			hit.call(Color(1, 0.6, 1.0), 8)
		"tr_plasma":           # violet bolt with a twisting light trail and a bright impact orb + ring
			seg.call(a, b, 0.025, Color(0.95, 0.85, 1.0, 1.0)); seg.call(a, b, 0.1, Color(0.6, 0.25, 1.0, 0.5))
			var right := (b - a).cross(Vector3.UP).normalized(); var up := right.cross(b - a).normalized()
			var prev := a
			for i in range(1, 17):
				var t := float(i) / 16.0
				var q := a.lerp(b, t) + (right * cos(t * 22.0) + up * sin(t * 22.0)) * 0.06
				seg.call(prev, q, 0.02, Color(0.85, 0.5, 1.0, 0.8)); prev = q
			pop(parent, b, Color(0.8, 0.5, 1.0), 1.1, 0.2 + hold * 0.3)
			shock(parent, b, Color(0.8, 0.5, 1.0), 0.5, 0.25 + hold * 0.3, true)
		_:                     # tr_basic: the current yellow streak, softer
			seg.call(a, b, 0.025, Color(1, 0.92, 0.6, 1.0)); seg.call(a, b, 0.07, Color(1, 0.7, 0.25, 0.3))

# ---------------------------------------------------------------- weapon / character effects (continuous)
const WEAPONS_FX := ["wfx_ember", "wfx_spark", "wfx_frost", "wfx_void", "wfx_gold"]
const CHARS_FX := ["cfx_flame", "cfx_stardust", "cfx_aura", "cfx_petal", "cfx_shadow"]

## a looping emitter (world-space particles, so they trail behind when the owner moves)
static func emitter(o: Dictionary) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = int(o.get("n", 16)); p.lifetime = float(o.get("life", 0.8)); p.local_coords = false
	var q := QuadMesh.new(); q.size = Vector2.ONE * float(o.get("size", 0.1)); p.mesh = o.get("mesh", q)
	p.material_override = o.get("mat", glow_mat(String(o.get("tex", "glow")), bool(o.get("add", true))))
	p.direction = o.get("dir", Vector3.UP); p.spread = float(o.get("spread", 30.0))
	var v: Vector2 = o.get("vel", Vector2(0.1, 0.4)); p.initial_velocity_min = v.x; p.initial_velocity_max = v.y
	p.gravity = o.get("grav", Vector3(0, 0.3, 0))
	var dmp: Vector2 = o.get("damp", Vector2(0, 0)); p.damping_min = dmp.x; p.damping_max = dmp.y
	var sc: Vector2 = o.get("scale", Vector2(0.6, 1.2)); p.scale_amount_min = sc.x; p.scale_amount_max = sc.y
	p.scale_amount_curve = o.get("curve", pop_curve())
	if o.has("ramp"): p.color_ramp = o["ramp"]
	if o.has("box"): p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX; p.emission_box_extents = o["box"]
	if o.has("ring"):
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING; p.emission_ring_axis = Vector3.UP
		p.emission_ring_radius = float(o["ring"]); p.emission_ring_inner_radius = float(o["ring"]) * 0.8; p.emission_ring_height = 0.02
	if o.has("spin"): p.angular_velocity_min = -float(o["spin"]); p.angular_velocity_max = float(o["spin"])
	if o.has("rot"): p.angle_min = 0.0; p.angle_max = 360.0
	if o.has("pos"): p.position = o["pos"]
	p.emitting = true
	return p

## follows its parent: switches `moving` emitters on only while the owner walks / runs, and
## draws flickering electric arcs for the spark weapon effect
class Follow extends Node3D:
	var moving: Array = []
	var arcs := 0.0                 # gun length for electric arcs (0 = none)
	var arc_col := Color(0.5, 0.8, 1.0)
	var _last := Vector3.ZERO
	var _spd := 0.0
	var _t := 0.0
	func _ready() -> void: _last = global_position
	func _process(dt: float) -> void:
		var p := global_position
		var v := Vector2(p.x - _last.x, p.z - _last.z).length() / maxf(dt, 0.001)
		_last = p
		_spd = lerpf(_spd, v, minf(1.0, dt * 8.0))
		for e in moving:
			if is_instance_valid(e): (e as CPUParticles3D).emitting = _spd > 1.0
		if arcs > 0.0:
			_t -= dt
			if _t <= 0.0:
				_t = randf_range(0.06, 0.2)
				_arc()
	func _arc() -> void:
		var z0 := randf_range(-arcs * 0.45, arcs * 0.3); var n := 4
		var pts: Array = []
		for i in n + 1:
			pts.append(Vector3(randf_range(-0.03, 0.03), randf_range(-0.02, 0.05), z0 - arcs * 0.18 * float(i) / n))
		for i in n:
			var a: Vector3 = global_transform * pts[i]; var b: Vector3 = global_transform * pts[i + 1]
			var m := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.014, 0.014, a.distance_to(b)); m.mesh = bm
			var mat := StandardMaterial3D.new(); mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			mat.albedo_color = Color(0.85, 0.95, 1.0); m.material_override = mat
			get_tree().current_scene.add_child(m) if get_tree().current_scene else add_child(m)
			m.global_position = (a + b) * 0.5
			if a.distance_to(b) > 0.001: m.look_at(b, Vector3.UP)
			get_tree().create_timer(0.06).timeout.connect(m.queue_free)

## attach a weapon effect to a gun holder (gun -Z = muzzle, centred; L = gun length in metres)
static func weapon_fx(id: String, holder: Node3D, L: float) -> Node3D:
	var f := Follow.new(); f.name = "WeaponFx"
	if id == "" or id == "wfx_none": return f
	var box := Vector3(0.025, 0.03, L * 0.42)
	match id:
		"wfx_ember":             # embers rising off the gun, a warm haze
			f.add_child(emitter({"n": 32, "size": 0.07, "tex": "core", "box": box, "vel": Vector2(0.05, 0.3), "grav": Vector3(0, 0.7, 0), "life": 1.0,
				"ramp": ramp([Color(1, 0.9, 0.5, 1), Color(1, 0.45, 0.1, 1), Color(0.6, 0.1, 0.0, 0)])}))
			f.add_child(emitter({"n": 14, "size": 0.24, "box": box, "vel": Vector2(0.02, 0.1), "grav": Vector3(0, 0.25, 0), "life": 0.8,
				"ramp": ramp([Color(1, 0.4, 0.1, 0.0), Color(1, 0.4, 0.1, 0.35), Color(1, 0.3, 0.05, 0)])}))
		"wfx_spark":             # crackling electric arcs + blue sparks
			f.arcs = L
			f.add_child(emitter({"n": 26, "size": 0.05, "tex": "core", "box": box, "vel": Vector2(0.4, 1.2), "spread": 180.0, "grav": Vector3(0, -2, 0), "life": 0.25,
				"curve": shrink(), "ramp": ramp([Color(1, 1, 1, 1), Color(0.4, 0.7, 1.0, 0)])}))
			f.add_child(emitter({"n": 12, "size": 0.22, "box": box, "vel": Vector2(0.0, 0.05), "grav": Vector3.ZERO, "life": 0.3,
				"ramp": ramp([Color(0.3, 0.6, 1.0, 0.0), Color(0.3, 0.6, 1.0, 0.4), Color(0.3, 0.6, 1.0, 0)])}))
		"wfx_frost":             # cold mist sliding down + ice glints
			f.add_child(emitter({"n": 18, "size": 0.3, "tex": "smoke", "box": box, "vel": Vector2(0.02, 0.1), "grav": Vector3(0, -0.3, 0), "life": 1.2,
				"ramp": ramp([Color(0.8, 0.95, 1.0, 0.0), Color(0.8, 0.95, 1.0, 0.5), Color(0.8, 0.95, 1.0, 0)])}))
			f.add_child(emitter({"n": 12, "size": 0.14, "tex": "star", "box": box, "vel": Vector2(0.0, 0.05), "grav": Vector3.ZERO, "life": 0.7, "rot": true,
				"ramp": ramp([Color(0.9, 1.0, 1.0, 1), Color(0.6, 0.85, 1.0, 0)])}))
		"wfx_void":              # dark violet wisps curling up
			f.add_child(emitter({"n": 20, "size": 0.26, "tex": "smoke", "add": false, "box": box, "vel": Vector2(0.05, 0.2), "grav": Vector3(0, 0.35, 0), "life": 1.1, "spin": 90.0, "rot": true,
				"ramp": ramp([Color(0.4, 0.1, 0.65, 0.0), Color(0.45, 0.12, 0.75, 0.75), Color(0.15, 0.0, 0.3, 0)])}))
			f.add_child(emitter({"n": 14, "size": 0.07, "tex": "core", "box": box, "vel": Vector2(0.05, 0.2), "grav": Vector3(0, 0.4, 0), "life": 0.9,
				"ramp": ramp([Color(0.8, 0.5, 1.0, 1), Color(0.5, 0.2, 1.0, 0)])}))
		"wfx_gold":              # golden glints twinkling on the gun
			f.add_child(emitter({"n": 16, "size": 0.18, "tex": "star", "box": box, "vel": Vector2(0.0, 0.03), "grav": Vector3.ZERO, "life": 0.6, "rot": true,
				"ramp": ramp([Color(1, 0.95, 0.7, 1), Color(1, 0.8, 0.3, 0)])}))
			f.add_child(emitter({"n": 14, "size": 0.05, "tex": "core", "box": box, "vel": Vector2(0.02, 0.12), "grav": Vector3(0, -0.2, 0), "life": 1.0,
				"ramp": ramp([Color(1, 0.85, 0.4, 1), Color(1, 0.7, 0.2, 0)])}))
	holder.add_child(f)
	return f

## attach a character effect to a soldier (origin at the feet)
static func char_fx(id: String, who: Node3D) -> Node3D:
	var f := Follow.new(); f.name = "CharFx"
	if id == "" or id == "cfx_none": return f
	match id:
		"cfx_flame":             # burning footprints while running
			var e := emitter({"n": 40, "size": 0.45, "box": Vector3(0.18, 0.02, 0.18), "vel": Vector2(0.2, 0.6), "grav": Vector3(0, 1.6, 0), "life": 0.55,
				"ramp": ramp([Color(1, 0.85, 0.4, 0.9), Color(1, 0.4, 0.05, 0.7), Color(0.5, 0.05, 0.0, 0)])})
			var e2 := emitter({"n": 16, "size": 0.06, "tex": "core", "box": Vector3(0.2, 0.02, 0.2), "vel": Vector2(0.4, 1.2), "grav": Vector3(0, 1.0, 0), "life": 0.8,
				"ramp": ramp([Color(1, 0.9, 0.5, 1), Color(1, 0.4, 0.1, 0)])})
			f.add_child(e); f.add_child(e2); f.moving = [e, e2]
		"cfx_stardust":          # pastel star dust trailing behind
			var e := emitter({"n": 28, "size": 0.18, "tex": "star", "box": Vector3(0.25, 0.4, 0.15), "pos": Vector3(0, 0.6, 0), "vel": Vector2(0.05, 0.3), "grav": Vector3(0, -0.4, 0),
				"life": 0.9, "rot": true, "ramp": ramp([Color(1, 0.9, 1.0, 1), Color(0.7, 0.8, 1.0, 1), Color(1.0, 0.7, 0.9, 0)])})
			f.add_child(e); f.moving = [e]
		"cfx_aura":              # always: a slow blue ring under the feet + rising motes
			f.add_child(emitter({"n": 22, "size": 0.07, "tex": "core", "ring": 0.55, "vel": Vector2(0.15, 0.4), "spread": 5.0, "grav": Vector3(0, 0.5, 0), "life": 1.4,
				"ramp": ramp([Color(0.4, 0.8, 1.0, 0), Color(0.5, 0.85, 1.0, 1), Color(0.3, 0.6, 1.0, 0)])}))
			var ring := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(1.5, 1.5); ring.mesh = q
			var rm := glow_mat("ring"); rm.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED; rm.vertex_color_use_as_albedo = false
			rm.albedo_color = Color(0.35, 0.75, 1.0, 0.7); ring.material_override = rm
			ring.rotation_degrees = Vector3(-90, 0, 0); ring.position = Vector3(0, 0.04, 0); f.add_child(ring)
			var tw := ring.create_tween().set_loops()
			tw.tween_property(ring, "scale", Vector3.ONE * 1.12, 0.9).set_trans(Tween.TRANS_SINE)
			tw.tween_property(ring, "scale", Vector3.ONE * 0.92, 0.9).set_trans(Tween.TRANS_SINE)
		"cfx_petal":             # pink petals swirling off while moving
			var pm := QuadMesh.new(); pm.size = Vector2(0.24, 0.13)
			var mat := glow_mat("core", false)          # oval petals, turning (billboarded so they never go edge-on)
			var e := emitter({"mesh": pm, "mat": mat, "n": 34, "box": Vector3(0.3, 0.5, 0.2), "pos": Vector3(0, 0.8, 0), "vel": Vector2(0.3, 0.8), "spread": 120.0,
				"grav": Vector3(0, -0.6, 0), "life": 1.3, "spin": 300.0, "rot": true, "curve": shrink(1.0, 0.4),
				"ramp": ramp([Color(1, 0.55, 0.75, 1), Color(1, 0.45, 0.7, 1), Color(1, 0.7, 0.85, 0)])})
			f.add_child(e); f.moving = [e]
		"cfx_shadow":            # dark smoke curling from the feet while moving
			var e := emitter({"n": 30, "size": 0.6, "tex": "smoke", "add": false, "box": Vector3(0.2, 0.05, 0.2), "vel": Vector2(0.1, 0.4), "grav": Vector3(0, 0.6, 0),
				"life": 0.9, "spin": 60.0, "rot": true, "ramp": ramp([Color(0.35, 0.1, 0.6, 0.0), Color(0.4, 0.12, 0.7, 0.8), Color(0.1, 0.0, 0.2, 0)])})
			var e2 := emitter({"n": 20, "size": 0.08, "tex": "core", "box": Vector3(0.25, 0.3, 0.2), "pos": Vector3(0, 0.3, 0), "vel": Vector2(0.1, 0.4), "grav": Vector3(0, 0.6, 0), "life": 0.8,
				"ramp": ramp([Color(0.8, 0.4, 1.0, 1), Color(0.5, 0.1, 1.0, 0)])})
			f.add_child(e); f.add_child(e2); f.moving = [e, e2]
	who.add_child(f)
	return f
