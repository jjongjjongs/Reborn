class_name MapBuilder
extends RefCounted
## Builds the selected map. Every playable map is now modelled in Blender from a
## plan (see MapPlan / tools/blender/maps); only the training ground (range) and
## the old code-built Old Town are still made here.
## build() returns spawn lists: {"ffa", "red", "blue", "zombie": Array[Vector3], "player": Vector3}

var root: Node3D
var nav: NavigationRegion3D
var _mats := {}
var _grain: ImageTexture

static func build(id: String, parent: Node3D) -> Dictionary:
	var b := MapBuilder.new()
	b.root = parent
	match id:
		"quarter", "dockside", "facility", "downtown", "bazaar", "cell", "harbor":
			var m := MapPlan.new()
			m.root = parent
			return m.build_plan("oldquarter" if id == "quarter" else id)
		"oldtown":
			var o := MapOldTown.new()
			o.root = parent
			return o.build_oldtown()
	return b._range()

# ------------------------------------------------------------------ helpers
func _env(bg: Color, ambient: Color, amb_e: float, sun_rot: Vector3, sun_col: Color, sun_e: float, fog: Color, fog_d: float) -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = sun_rot; sun.light_energy = sun_e; sun.light_color = sun_col
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL   # one shadow pass (mobile)
	root.add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = bg
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient; env.ambient_light_energy = amb_e
	env.fog_enabled = fog_d > 0.0; env.fog_light_color = fog; env.fog_density = fog_d
	we.environment = env
	root.add_child(we)
	nav = NavigationRegion3D.new()
	root.add_child(nav)

func _bake() -> void:
	var nm := NavigationMesh.new()
	nm.cell_size = 0.25; nm.cell_height = 0.25
	nm.agent_radius = 0.5; nm.agent_height = 1.8; nm.agent_max_climb = 0.4; nm.agent_max_slope = 40.0
	nav.navigation_mesh = nm
	nav.bake_navigation_mesh(false)

func _grain_tex() -> ImageTexture:
	if _grain == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
		var rng := RandomNumberGenerator.new(); rng.seed = 7
		for y in 64:
			for x in 64:
				var v := rng.randf_range(0.84, 1.0)
				img.set_pixel(x, y, Color(v, v, v))
		_grain = ImageTexture.create_from_image(img)
	return _grain

func mat(c: Color, grain := true) -> StandardMaterial3D:
	var key := "%s|%s" % [c.to_html(), grain]
	if _mats.has(key): return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	if grain:
		m.albedo_texture = _grain_tex()
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(0.6, 0.6, 0.6)
	_mats[key] = m
	return m

# solid box: center + size (+ yaw in degrees). collide=false -> decoration only
func box(center: Vector3, size: Vector3, c: Color, yaw := 0.0, collide := true, grain := true) -> Node3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size; m.mesh = bm
	m.material_override = mat(c, grain)
	if not collide:
		m.position = center; m.rotation_degrees.y = yaw
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if size.y < 0.15 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		nav.add_child(m)
		return m
	var sb := StaticBody3D.new()
	sb.add_child(m)
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new(); bs.size = size; col.shape = bs
	sb.add_child(col)
	sb.position = center; sb.rotation_degrees.y = yaw
	nav.add_child(sb)
	return sb

# box from min corner (x,z) to max corner, standing on y0, height h
func block(x0: float, z0: float, x1: float, z1: float, h: float, c: Color, y0 := 0.0) -> Node3D:
	return box(Vector3((x0 + x1) * 0.5, y0 + h * 0.5, (z0 + z1) * 0.5), Vector3(absf(x1 - x0), h, absf(z1 - z0)), c)

func cyl(center: Vector3, r: float, h: float, c: Color, collide := true) -> void:
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = r; cm.bottom_radius = r; cm.height = h
	cm.radial_segments = 12
	m.mesh = cm; m.material_override = mat(c)
	if not collide:
		m.position = center; nav.add_child(m); return
	var sb := StaticBody3D.new(); sb.add_child(m)
	var col := CollisionShape3D.new()
	var cs := CylinderShape3D.new(); cs.radius = r; cs.height = h; col.shape = cs
	sb.add_child(col); sb.position = center
	nav.add_child(sb)

# walkable ramp from a (bottom, on the floor) to b (top surface point)
func ramp(a: Vector3, b: Vector3, width: float, c: Color) -> void:
	var d := b - a
	var L := d.length()
	var t := 0.3
	var basis := Basis.looking_at(d.normalized(), Vector3.UP)
	var center := (a + b) * 0.5 - basis.y * (t * 0.5)
	var sb := StaticBody3D.new()
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(width, t, L + 0.2); m.mesh = bm
	m.material_override = mat(c)
	sb.add_child(m)
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new(); bs.size = bm.size; col.shape = bs
	sb.add_child(col)
	sb.transform = Transform3D(basis, center)
	nav.add_child(sb)

func ground(sx: float, sz: float, c: Color) -> void:
	box(Vector3(0, -0.5, 0), Vector3(sx + 8, 1, sz + 8), c)

func perimeter(sx: float, sz: float, h: float, c: Color) -> void:
	var hx := sx * 0.5; var hz := sz * 0.5
	block(-hx - 1, -hz - 1, hx + 1, -hz, h, c)
	block(-hx - 1, hz, hx + 1, hz + 1, h, c)
	block(-hx - 1, -hz, -hx, hz, h, c)
	block(hx, -hz, hx + 1, hz, h, c)

func crate(p: Vector3, s := 1.0, yaw := 0.0) -> void:
	box(p + Vector3(0, s * 0.5, 0), Vector3(s, s, s), Color(0.55, 0.40, 0.24), yaw)

func barrel(p: Vector3, c := Color(0.32, 0.42, 0.50)) -> void:
	cyl(p + Vector3(0, 0.5, 0), 0.38, 1.0, c)

static func _spawns(pts: Array) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for p in pts: out.append(Vector3(p[0], 1.0, p[1]))
	return out

# ------------------------------------------------------------------ 훈련장
func _range() -> Dictionary:
	_env(Color(0.06, 0.08, 0.10), Color(0.45, 0.5, 0.55), 0.7, Vector3(-55, -40, 0), Color.WHITE, 1.1, Color(0.07, 0.1, 0.12), 0.01)
	box(Vector3(0, -0.5, 0), Vector3(70, 1, 70), Color(0.12, 0.14, 0.13), 0.0, true, false)
	for p in [Vector3(8, 1.5, 4), Vector3(-9, 1.5, -3), Vector3(4, 1.5, -10), Vector3(-6, 1.5, 9),
			Vector3(11, 1.5, -6), Vector3(-11, 1.5, 7), Vector3(0, 1.5, 0)]:
		box(p, Vector3(3, 3, 3), Color(0.2, 0.22, 0.25), 0.0, true, false)
	_bake()
	var ffa := _spawns([[16, 0], [-16, 0], [0, -18], [0, 18], [14, -14], [-14, 14], [14, 14], [-14, -14]])
	return {"ffa": ffa,
		"red": _spawns([[-16, 0], [-14, -9], [-14, 9], [-10, 0]]),
		"blue": _spawns([[16, 0], [14, -9], [14, 9], [10, 0]]),
		"zombie": _spawns([[17, 0], [-17, 0], [0, -19], [0, 19], [15, -15], [-15, 15]]),
		"player": Vector3(0, 1.5, 0), "bounds": Rect2(-35, -35, 70, 70)}

# ------------------------------------------------------------------ 사막 시장
func _stall(p: Vector3, cloth: Color, yaw: float) -> void:
	var wood := Color(0.45, 0.32, 0.20)
	box(p + Vector3(0, 0.45, 0), Vector3(2.2, 0.9, 1.0), wood, yaw)
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	for o in [Vector3(-1.05, 0, -0.9), Vector3(1.05, 0, -0.9), Vector3(-1.05, 0, 0.45), Vector3(1.05, 0, 0.45)]:
		box(p + b * o + Vector3(0, 1.25, 0), Vector3(0.1, 2.5, 0.1), wood, yaw)
	box(p + b * Vector3(0, 0, -0.22) + Vector3(0, 2.55, 0), Vector3(2.5, 0.06, 1.8), cloth, yaw, false, false)

# ------------------------------------------------------------------ 교도소