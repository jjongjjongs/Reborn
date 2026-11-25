class_name MapBuilder
extends RefCounted
## Builds the selected map in code (original layouts, no external assets):
##   range  훈련장       - the original box arena
##   bazaar 사막 시장    - mud-brick blocks, 3 alleys, central market, 2 sniper roofs (ramps)
##   cell   교도소       - cell rows + main corridor, yard with barriers, mess hall
##   harbor 컨테이너 항구 - quay, container rows (some stacked, ramps on top), warehouse, crane
## build() returns spawn lists: {"ffa", "red", "blue", "zombie": Array[Vector3], "player": Vector3}

var root: Node3D
var nav: NavigationRegion3D
var _mats := {}
var _grain: ImageTexture

static func build(id: String, parent: Node3D) -> Dictionary:
	var b := MapBuilder.new()
	b.root = parent
	match id:
		"bazaar": return b._bazaar()
		"cell": return b._cell()
		"harbor": return b._harbor()
	return b._range()

# ------------------------------------------------------------------ helpers
func _env(bg: Color, ambient: Color, amb_e: float, sun_rot: Vector3, sun_col: Color, sun_e: float, fog: Color, fog_d: float) -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = sun_rot; sun.light_energy = sun_e; sun.light_color = sun_col
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
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
		"player": Vector3(0, 1.5, 0)}

# ------------------------------------------------------------------ 사막 시장
func _bazaar() -> Dictionary:
	_env(Color(0.50, 0.62, 0.74), Color(0.62, 0.60, 0.58), 0.45, Vector3(-48, -35, 0), Color(1.0, 0.90, 0.74), 1.0, Color(0.70, 0.66, 0.58), 0.006)
	var sand := Color(0.52, 0.43, 0.30)
	var wall_a := Color(0.66, 0.54, 0.38)
	var wall_b := Color(0.60, 0.48, 0.33)
	var wall_c := Color(0.70, 0.59, 0.44)
	var trim := Color(0.45, 0.34, 0.22)
	ground(46, 46, sand)
	perimeter(46, 46, 6.0, trim)
	# buildings (x0, z0, x1, z1, height, colour)
	var houses := [
		[-23, -23, -9.2, -11, 5.0, wall_a], [-6.4, -23, 5.5, -14.7, 4.0, wall_c], [9.2, -23, 23, -9.2, 4.5, wall_b],
		[-23, -5.5, -12.9, 6.4, 4.0, wall_c], [12.9, -3.7, 23, 6.4, 5.0, wall_a],
		[-23, 11, -7.4, 23, 4.5, wall_b], [-2.8, 12, 5.5, 23, 4.0, wall_a], [9.2, 11, 23, 23, 5.5, wall_c],
	]
	for h in houses:
		block(h[0], h[1], h[2], h[3], h[4], h[5])
		_house_details(h[0], h[1], h[2], h[3], h[4], trim)
	# sniper roofs: ramps up the NE block (west face) and the SW block (north face)
	ramp(Vector3(8.3, 0, -5.6), Vector3(8.3, 4.5, -15.0), 1.8, trim)
	_parapet(9.2, -23, 23, -9.2, 4.5, trim, "w", -15.0)
	ramp(Vector3(-8.6, 0, 10.1), Vector3(-17.6, 4.5, 10.1), 1.8, trim)
	_parapet(-23, 11, -7.4, 23, 4.5, trim, "n", -17.6)
	# central market: fountain + four stalls with awnings
	cyl(Vector3(0, 0.4, -0.5), 1.7, 0.8, Color(0.62, 0.58, 0.52))
	cyl(Vector3(0, 1.1, -0.5), 0.35, 0.8, Color(0.55, 0.50, 0.44))
	var cloth := [Color(0.72, 0.22, 0.18), Color(0.20, 0.42, 0.62), Color(0.28, 0.52, 0.30), Color(0.82, 0.62, 0.18)]
	var stalls := [Vector3(-3.6, 0, -3.8), Vector3(3.6, 0, -3.8), Vector3(-3.6, 0, 2.8), Vector3(3.6, 0, 2.8)]
	for i in 4:
		_stall(stalls[i], cloth[i], 90.0 if i % 2 == 0 else -90.0)
	# alley cover
	for p in [Vector3(-7.5, 0, -8.2), Vector3(-6.6, 0, -7.4), Vector3(7.4, 0, 8.8), Vector3(12.0, 0, -4.6),
			Vector3(-22.0, 0, 9.6), Vector3(17.5, 0, 7.4), Vector3(-15.4, 0, -6.8), Vector3(1.6, 0, -11.5), Vector3(-1.8, 0, 8.4)]:
		crate(p, 1.0, randf_range(-12, 12))
	crate(Vector3(-6.6, 1.0, -7.4), 0.8, 20.0)
	for p in [Vector3(6.6, 0, 8.4), Vector3(-15.0, 0, -9.6), Vector3(20.0, 0, -6.2), Vector3(-4.6, 0, -11.8), Vector3(3.6, 0, 9.6)]:
		barrel(p, Color(0.45, 0.33, 0.22))
	# low mud walls in the side streets
	block(14.0, 8.0, 16.6, 8.6, 1.1, wall_b)
	block(-20.5, -8.8, -19.9, -6.4, 1.1, wall_b)
	block(-3.0, 7.0, -1.0, 7.5, 1.1, wall_b)
	_bake()
	return {"ffa": _spawns([[0, 8], [0, -9.5], [-20, 8], [19, 8.7], [-18, -8.3], [19, -6.5], [-10.6, -8.2], [11, 8.7]]),
		"red": _spawns([[-20, 8], [-11.5, 7.6], [-18, -8.3], [-10.6, -8.6]]),
		"blue": _spawns([[19, -6.5], [11, -6.8], [19, 8.7], [11.2, 8.8]]),
		"zombie": _spawns([[-20, 8], [19, 8.7], [-18, -8.3], [19, -6.5], [0, -9.5], [7.4, 4.0]]),
		"player": Vector3(0, 1.0, 8.0)}

func _house_details(x0: float, z0: float, x1: float, z1: float, h: float, trim: Color) -> void:
	# roof lip + dark window/door insets on the faces that face the streets (visual only)
	box(Vector3((x0 + x1) * 0.5, h + 0.08, (z0 + z1) * 0.5), Vector3(absf(x1 - x0) + 0.3, 0.16, absf(z1 - z0) + 0.3), trim, 0.0, false)
	var dark := Color(0.16, 0.12, 0.09)
	var faces := [[x0, z0, x1, z0, Vector3(0, 0, -1)], [x0, z1, x1, z1, Vector3(0, 0, 1)],
		[x0, z0, x0, z1, Vector3(-1, 0, 0)], [x1, z0, x1, z1, Vector3(1, 0, 0)]]
	for f in faces:
		var a := Vector3(f[0], 0, f[1]); var b := Vector3(f[2], 0, f[3])
		var n: Vector3 = f[4]
		if absf(a.x) > 22.5 and absf(b.x) > 22.5: continue      # against the outer wall
		if absf(a.z) > 22.5 and absf(b.z) > 22.5: continue
		var L := a.distance_to(b)
		var cnt := int(L / 3.2)
		for i in cnt:
			var p := a.lerp(b, (i + 0.5) / float(cnt)) + n * 0.03
			var along_x := absf(n.z) > 0.5
			var sz := Vector3(0.9, 1.0, 0.06) if along_x else Vector3(0.06, 1.0, 0.9)
			if i == cnt / 2 and L > 7.0:   # a doorway
				sz = Vector3(1.3, 2.1, 0.06) if along_x else Vector3(0.06, 2.1, 1.3)
				box(p + Vector3(0, 1.05, 0), sz, dark, 0.0, false, false)
			elif h > 4.2:
				box(p + Vector3(0, h - 1.5, 0), sz, dark, 0.0, false, false)

# parapet on a roof, with a gap where the ramp arrives
func _parapet(x0: float, z0: float, x1: float, z1: float, h: float, c: Color, gap_side: String, gap_at: float) -> void:
	var t := 0.3; var ph := 0.7
	var gs := 1.2   # half gap
	for side in ["n", "s", "w", "e"]:
		var segs := []
		match side:
			"n": segs = [[x0, z0, x1, z0 + t]]
			"s": segs = [[x0, z1 - t, x1, z1]]
			"w": segs = [[x0, z0, x0 + t, z1]]
			"e": segs = [[x1 - t, z0, x1, z1]]
		for s in segs:
			if side == gap_side:
				if side == "w" or side == "e":
					block(s[0], s[1], s[2], gap_at - gs, ph, c, h)
					block(s[0], gap_at + gs, s[2], s[3], ph, c, h)
				else:
					block(s[0], s[1], gap_at - gs, s[3], ph, c, h)
					block(gap_at + gs, s[1], s[2], s[3], ph, c, h)
			else:
				block(s[0], s[1], s[2], s[3], ph, c, h)

func _stall(p: Vector3, cloth: Color, yaw: float) -> void:
	var wood := Color(0.45, 0.32, 0.20)
	box(p + Vector3(0, 0.45, 0), Vector3(2.2, 0.9, 1.0), wood, yaw)
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	for o in [Vector3(-1.05, 0, -0.9), Vector3(1.05, 0, -0.9), Vector3(-1.05, 0, 0.45), Vector3(1.05, 0, 0.45)]:
		box(p + b * o + Vector3(0, 1.25, 0), Vector3(0.1, 2.5, 0.1), wood, yaw)
	box(p + b * Vector3(0, 0, -0.22) + Vector3(0, 2.55, 0), Vector3(2.5, 0.06, 1.8), cloth, yaw, false, false)

# ------------------------------------------------------------------ 교도소
func _cell() -> Dictionary:
	_env(Color(0.30, 0.34, 0.38), Color(0.62, 0.65, 0.70), 0.8, Vector3(-60, 25, 0), Color(0.92, 0.95, 1.0), 1.0, Color(0.32, 0.35, 0.38), 0.008)
	var floor_c := Color(0.36, 0.37, 0.38)
	var concrete := Color(0.58, 0.59, 0.60)
	var cell_c := Color(0.68, 0.66, 0.60)
	var dark := Color(0.22, 0.23, 0.25)
	var yard_c := Color(0.34, 0.40, 0.30)
	ground(40, 35, floor_c)
	box(Vector3(-10, 0.01, 8.75), Vector3(20, 0.02, 17.5), yard_c, 0.0, false)          # yard surface
	perimeter(40, 35, 4.5, concrete)
	var bars := Color(0.18, 0.19, 0.21)
	# row A cells along the north wall: z -17.5..-12.5, 8 cells of 5 m
	_cell_row(-20.0, 20.0, -17.5, -12.5, true, cell_c, bars)
	# row B cells: two groups with a crossing in the middle, z -8..-2 (fronts face north)
	_cell_row(-20.0, -5.0, -2.0, -8.0, false, cell_c, bars)
	_cell_row(5.0, 20.0, -2.0, -8.0, false, cell_c, bars)
	# corridor clutter
	crate(Vector3(-12.0, 0, -10.2), 0.9)
	box(Vector3(9.0, 0.5, -10.4), Vector3(2.2, 1.0, 0.8), dark)          # cart
	barrel(Vector3(14.5, 0, -9.6), Color(0.30, 0.34, 0.40))
	# guard desk at the crossing
	box(Vector3(0, 0.55, -5.4), Vector3(2.6, 1.1, 0.9), Color(0.40, 0.34, 0.28))
	# yard (west, z 0..17.5): concrete barriers, bench, a hoop
	for p in [[-15.5, 4.0, 0.0], [-9.0, 6.5, 90.0], [-4.0, 3.2, 0.0], [-14.0, 12.0, 90.0], [-6.0, 13.5, 0.0], [-10.0, 9.8, 0.0]]:
		box(Vector3(p[0], 0.55, p[1]), Vector3(2.4, 1.1, 0.5), concrete, p[2])
	box(Vector3(-18.6, 0.25, 9.0), Vector3(0.6, 0.5, 3.0), Color(0.45, 0.35, 0.25))
	box(Vector3(-2.0, 1.6, 16.6), Vector3(0.16, 3.2, 0.16), dark)
	box(Vector3(-2.0, 3.0, 16.2), Vector3(1.2, 0.8, 0.06), Color(0.85, 0.85, 0.85), 0.0, false)
	# divider wall yard | mess hall at x = 2, doorways at z 4..6 and 11..13
	block(1.7, 0.0, 2.3, 4.0, 3.2, concrete)
	block(1.7, 6.0, 2.3, 11.0, 3.2, concrete)
	block(1.7, 13.0, 2.3, 17.5, 3.2, concrete)
	# mess hall north wall (z = 0.8) with door at x 9..11
	block(2.3, 0.5, 9.0, 1.1, 3.2, concrete)
	block(11.0, 0.5, 20.0, 1.1, 3.2, concrete)
	box(Vector3(11.0, 0.01, 9.2), Vector3(17.4, 0.02, 16.4), Color(0.46, 0.44, 0.40), 0.0, false)   # tiled floor
	for row in [4.2, 8.4, 12.6]:
		for col in [5.8, 11.0, 16.2]:
			box(Vector3(col, 0.4, row), Vector3(3.2, 0.8, 1.1), Color(0.55, 0.56, 0.58))
	box(Vector3(18.8, 0.55, 15.0), Vector3(1.0, 1.1, 4.0), Color(0.62, 0.63, 0.65))       # serving counter
	# yard wall-top lights (visual)
	for x in [-18.0, -10.0, -2.0]:
		box(Vector3(x, 4.6, 17.3), Vector3(0.6, 0.2, 0.3), Color(0.95, 0.92, 0.75), 0.0, false, false)
	_bake()
	return {"ffa": _spawns([[-16, 14], [-8, 15.5], [16, 14], [16, 5], [-17, -10], [17, -10], [0, -10], [-16, 2.5]]),
		"red": _spawns([[-16, 14], [-10, 15.5], [-17, 6.5], [-12, 2.0]]),
		"blue": _spawns([[16, 14], [16, 5.5], [8.4, 14.8], [13.5, 2.6]]),
		"zombie": _spawns([[-17, -10], [17, -10], [0, -10], [16, 14], [-16, 14], [16, 5]]),
		"player": Vector3(-8.0, 1.0, 8.0)}

# a row of cells between x0..x1; z_back = the solid back wall line, z_front = the barred front
func _cell_row(x0: float, x1: float, z_back: float, z_front: float, _north: bool, c: Color, bars: Color) -> void:
	var h := 3.0
	var t := 0.3
	var zb := minf(z_back, z_front); var zf := maxf(z_back, z_front)
	var front_z := z_front
	# back wall
	if not _north:
		block(x0, z_back - t, x1, z_back, h, c)
	var n := int(roundf((x1 - x0) / 5.0))
	var w := (x1 - x0) / float(n)
	for i in n + 1:
		var x := x0 + i * w
		block(x - t * 0.5, zb, x + t * 0.5, zf, h, c)          # side walls
	for i in n:
		var cx := x0 + (i + 0.5) * w
		# front: wall stubs left/right of a 1.4 m door, bars above the stubs (visual)
		var fz0 := front_z - t * 0.5 if _north else front_z - t * 0.5
		block(x0 + i * w, fz0, cx - 0.7, fz0 + t, h, c)
		block(cx + 0.7, fz0, x0 + (i + 1) * w, fz0 + t, h, c)
		box(Vector3(cx, h - 0.35, fz0 + t * 0.5), Vector3(1.4, 0.7, t), c)            # lintel
		for k in 5:
			box(Vector3(cx - 0.56 + k * 0.28, 1.15, fz0 + t * 0.5), Vector3(0.05, 2.3, 0.05), bars, 0.0, false, false)
		# bunk inside each cell
		var inner := lerpf(zb, zf, 0.3 if _north else 0.7)
		box(Vector3(cx + w * 0.25, 0.4, inner), Vector3(1.0, 0.8, 1.9), Color(0.40, 0.36, 0.30))

# ------------------------------------------------------------------ 컨테이너 항구
func _harbor() -> Dictionary:
	_env(Color(0.48, 0.52, 0.62), Color(0.70, 0.66, 0.70), 0.75, Vector3(-28, -110, 0), Color(1.0, 0.82, 0.62), 1.15, Color(0.55, 0.55, 0.62), 0.007)
	var asphalt := Color(0.30, 0.32, 0.33)
	var quay := Color(0.50, 0.50, 0.48)
	ground(60, 45, asphalt)
	# water beyond the quay (z < -16): visual plane + invisible wall at the edge
	var water := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(90, 30); water.mesh = pm
	var wm := StandardMaterial3D.new(); wm.albedo_color = Color(0.14, 0.30, 0.40); wm.roughness = 0.2; wm.metallic = 0.3
	water.material_override = wm; water.position = Vector3(0, 0.02, -31.5)
	root.add_child(water)
	box(Vector3(0, 0.03, -18.0), Vector3(60, 0.06, 4.0), quay, 0.0, false)           # quay apron
	box(Vector3(0, 1.5, -16.6), Vector3(62, 3.0, 0.4), Color(0, 0, 0, 0), 0.0, true, false).get_child(0).visible = false
	for x in range(-27, 28, 6):
		cyl(Vector3(x, 0.35, -17.2), 0.25, 0.7, Color(0.20, 0.20, 0.22))           # bollards
	# side and back fences
	var fence := Color(0.38, 0.40, 0.42)
	block(-31, -16.4, -30, 22.5, 4.0, fence)
	block(30, -16.4, 31, 22.5, 4.0, fence)
	# warehouse along the south (z 17..22.5) with open bays
	var wh := Color(0.55, 0.47, 0.38)
	block(-31, 22.5, 31, 23.5, 7.0, wh)
	for seg in [[-30, -19], [-13, -3], [3, 13], [19, 30]]:
		block(seg[0], 17.0, seg[1], 17.6, 6.0, wh)
	box(Vector3(0, 6.2, 20.2), Vector3(60, 0.3, 6.4), Color(0.36, 0.33, 0.30), 0.0, false)   # roof
	for p in [Vector3(-16, 0, 20.0), Vector3(-6, 0, 21.0), Vector3(8, 0, 19.8), Vector3(16.5, 0, 21.0)]:
		crate(p, 1.2, randf_range(-10, 10))
	# containers (6.1 x 2.6 x 2.44)
	var rust := Color(0.62, 0.28, 0.18); var blue := Color(0.18, 0.40, 0.56)
	var green := Color(0.28, 0.46, 0.25); var yellow := Color(0.78, 0.58, 0.18); var grey := Color(0.52, 0.54, 0.56)
	_container(Vector3(-20.9, 0, -9.5), 0.0, rust)
	_container(Vector3(-14.7, 0, -9.5), 0.0, blue)
	_container(Vector3(-14.7, 2.6, -9.5), 0.0, yellow)
	_container(Vector3(-21.0, 0, -4.4), 0.0, green)
	_container(Vector3(-0.0, 0, -6.0), 90.0, green)
	_container(Vector3(-0.0, 0, 0.3), 90.0, grey)
	_container(Vector3(-0.0, 2.6, -6.0), 90.0, rust)
	_container(Vector3(13.0, 0, -10.5), 0.0, yellow)
	_container(Vector3(19.3, 0, -10.5), 0.0, blue)
	_container(Vector3(13.0, 0, 2.0), 0.0, rust)
	_container(Vector3(19.3, 0, 2.0), 0.0, green)
	_container(Vector3(19.3, 2.6, 2.0), 0.0, grey)
	_container(Vector3(-18.6, 0, 9.2), 0.0, blue)
	_container(Vector3(-12.4, 0, 9.2), 0.0, yellow)
	_container(Vector3(-6.2, 0, 9.2), 0.0, rust)
	_container(Vector3(6.6, 0, 12.8), 0.0, grey)
	_container(Vector3(12.8, 0, 12.8), 0.0, green)
	_container(Vector3(19.0, 0, 12.8), 0.0, blue)
	# ramps onto single containers (high ground)
	ramp(Vector3(-29.4, 0, -9.5), Vector3(-23.9, 2.6, -9.5), 1.8, Color(0.42, 0.40, 0.36))
	ramp(Vector3(-12.4, 0, 15.8), Vector3(-12.4, 2.6, 10.4), 1.8, Color(0.42, 0.40, 0.36))
	ramp(Vector3(16.1, 0, -4.4), Vector3(16.1, 2.6, -9.3), 1.8, Color(0.42, 0.40, 0.36))
	# loose cover
	for p in [Vector3(-8.0, 0, -12.5), Vector3(6.0, 0, -12.0), Vector3(-25.5, 0, 2.5), Vector3(25.0, 0, -2.5),
			Vector3(-4.5, 0, 4.2), Vector3(5.0, 0, 6.0), Vector3(25.5, 0, 9.0), Vector3(-26.0, 0, 14.0)]:
		crate(p, 1.1, randf_range(-15, 15))
	for p in [Vector3(-9.4, 0, -12.0), Vector3(7.2, 0, -12.8), Vector3(4.2, 0, 5.2)]:
		barrel(p, Color(0.20, 0.35, 0.52))
	# forklift (cover)
	box(Vector3(-6.0, 0.75, -1.5), Vector3(1.3, 1.5, 2.2), yellow, 25.0)
	# quay crane: legs collide, frame is visual
	var crane := Color(0.80, 0.48, 0.14)
	for p in [Vector3(-8, 5.5, -14.0), Vector3(-2, 5.5, -14.0)]:
		box(p, Vector3(0.6, 11.0, 0.6), crane)
	box(Vector3(-5, 11.2, -14.0), Vector3(7.0, 0.6, 0.8), crane, 0.0, false)
	box(Vector3(-5, 11.8, -20.0), Vector3(0.8, 0.6, 16.0), crane, 0.0, false)
	_bake()
	return {"ffa": _spawns([[-27, 18], [27, 18], [-27, -1], [27, -4], [0, 15], [-8, -13], [8, -13], [0, 6.5]]),
		"red": _spawns([[-27.5, 18], [-27.5, 6], [-27.5, -3], [-25, 15.5]]),
		"blue": _spawns([[27.5, 18], [27.5, 6], [27.5, -4], [25, 15.5]]),
		"zombie": _spawns([[-27, 18], [27, 18], [-27, -1], [27, -4], [-8, -13], [8, -13]]),
		"player": Vector3(0, 1.0, 6.5)}

func _container(base: Vector3, yaw: float, c: Color) -> void:
	var size := Vector3(6.1, 2.6, 2.44)
	box(base + Vector3(0, 1.3, 0), size, c, yaw)
	# corrugation ribs + door end (visual)
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	var rib := c.darkened(0.25)
	for i in 9:
		var x := -2.7 + i * 0.675
		box(base + b * Vector3(x, 1.3, 1.24), Vector3(0.12, 2.4, 0.05), rib, yaw, false, false)
		box(base + b * Vector3(x, 1.3, -1.24), Vector3(0.12, 2.4, 0.05), rib, yaw, false, false)
	box(base + b * Vector3(3.07, 1.3, 0), Vector3(0.05, 2.4, 2.3), c.darkened(0.35), yaw, false, false)
