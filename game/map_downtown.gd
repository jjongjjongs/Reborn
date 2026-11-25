class_name MapDowntown
extends MapBuilder
## 다운타운 (Downtown) — built from the Quaternius modular downtown kit (CC0).
## Designed from the player's side: west = red, east = blue, point-symmetric so
## neither side gets a better spot. Three lanes:
##   north  - side street -> back alley (close range, dumpsters)
##   middle - the avenue: long sight lines broken by wrecked cars and barriers
##   south  - mirrored back alley
## Power positions: the raised plaza (north-west) / loading dock (south-east), and
## the cafe roof (north-east) / store roof (south-west), each reached by stairs and
## each visible from its counterpart, so no spot is safe for long.
## Every point P has a mirror -P (x,z) -> (-x,-z).

const KIT := "res://assets/city/%s.glb"
const HX := 28.0
const HZ := 20.0
var _scenes := {}

func build_downtown() -> Dictionary:
	_env(Color(0.56, 0.66, 0.78), Color(0.78, 0.80, 0.84), 1.05, Vector3(-52, -30, 0), Color(1.0, 0.95, 0.86), 1.2, Color(0.62, 0.66, 0.72), 0.004)
	# collision-only ground (visual = street / sidewalk tiles)
	box(Vector3(0, -0.5, 0), Vector3(HX * 2 + 30, 1, HZ * 2 + 30), Color(0.30, 0.30, 0.31))
	_streets()
	_bounds()
	for s in [1.0, -1.0]:
		_side(s)
	_avenue_cover()
	_bake_colliders()
	return {
		"ffa": _spawns([[-25.5, 0], [25.5, 0], [-21.5, -13.5], [21.5, 13.5], [0, 18], [0, -18], [-13.5, 11], [13.5, -11]]),
		"red": _spawns([[-25.5, 0], [-25.5, -2.6], [-22, -12.5], [-25.5, 2.6]]),
		"blue": _spawns([[25.5, 0], [25.5, 2.6], [22, 12.5], [25.5, -2.6]]),
		"zombie": _spawns([[-25.5, 0], [25.5, 0], [-21.5, -13.5], [21.5, 13.5], [0, 18], [0, -18]]),
		"player": Vector3(0, 1.0, -0.2) }

# ---------------------------------------------------------------- helpers
func piece(name: String, pos: Vector3, yaw := 0.0, scl := 1.0) -> Node3D:
	if not _scenes.has(name):
		_scenes[name] = load(KIT % name)
	var n: Node3D = (_scenes[name] as PackedScene).instantiate()
	n.position = pos
	n.rotation_degrees.y = yaw
	if scl != 1.0: n.scale = Vector3.ONE * scl
	nav.add_child(n)
	_fix_mats(n)
	return n

func _no_shadow(n: Node) -> void:
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children(): _no_shadow(c)

# Quaternius colour-only materials leave metallic at the glTF default (1.0) -> chrome
var _fixed := {}
func _fix_mats(n: Node) -> void:
	if n is MeshInstance3D:
		var mesh: Mesh = (n as MeshInstance3D).mesh
		if mesh:
			for i in mesh.get_surface_count():
				var m = mesh.surface_get_material(i)
				if m is StandardMaterial3D and not _fixed.has(m):
					_fixed[m] = true
					if (m as StandardMaterial3D).albedo_texture == null:
						(m as StandardMaterial3D).vertex_color_use_as_albedo = true   # trees carry colour per vertex
					if (m as StandardMaterial3D).metallic_texture == null:
						(m as StandardMaterial3D).metallic = 0.0
						(m as StandardMaterial3D).roughness = maxf((m as StandardMaterial3D).roughness, 0.6)
	for c in n.get_children():
		_fix_mats(c)

# invisible collision box (min/max corners)
func solid(x0: float, z0: float, x1: float, z1: float, h: float, y0 := 0.0) -> void:
	var sb := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new(); bs.size = Vector3(absf(x1 - x0), h, absf(z1 - z0)); col.shape = bs
	sb.add_child(col)
	sb.position = Vector3((x0 + x1) * 0.5, y0 + h * 0.5, (z0 + z1) * 0.5)
	nav.add_child(sb)

func _bake_colliders() -> void:
	var nm := NavigationMesh.new()
	nm.cell_size = 0.25; nm.cell_height = 0.2
	nm.agent_radius = 0.5; nm.agent_height = 1.8; nm.agent_max_climb = 0.35; nm.agent_max_slope = 40.0
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav.navigation_mesh = nm
	nav.bake_navigation_mesh(false)

# a run of 2 m wall pieces from a to b (both on the outer face line); the
# outside is on the left of a->b seen from above (local +Z of the pieces).
# tokens: b brick, w brick window, g shop glass, f shop frame, d doorway, _ opening
func wall_run(a: Vector2, b: Vector2, tokens: String, h := 3.0) -> void:
	var dir := (b - a).normalized()
	var yaw := rad_to_deg(atan2(-dir.y, dir.x))
	var n3 := Vector3(dir.x, 0, dir.y).cross(Vector3.UP)    # piece +Z (outward)
	var inward := -Vector2(n3.x, n3.z)
	var L := a.distance_to(b)
	var cnt := tokens.length()
	var step := L / float(cnt)
	var run_start := -1
	for i in cnt + 1:
		var t := tokens[i] if i < cnt else "d"
		var open := t == "d" or t == "_"
		if not open and run_start < 0: run_start = i
		if open and run_start >= 0:
			# collision for the solid stretch [run_start, i)
			var p0 := a + dir * (run_start * step)
			var p1 := a + dir * (i * step)
			var q0 := p0 + inward * 0.3
			var xs := [p0.x, p1.x, q0.x, q0.x + (p1.x - p0.x)]
			var zs := [p0.y, p1.y, q0.y, q0.y + (p1.y - p0.y)]
			solid(xs.min(), zs.min(), xs.max(), zs.max(), h)
			run_start = -1
		if i == cnt: break
		var c := a + dir * ((i + 0.5) * step)
		var pos := Vector3(c.x, 0, c.y)
		match t:
			"b": piece("brick-plain-3", pos, yaw)
			"w": piece("brick-window-trim", pos, yaw)
			"g": piece("metal-fullwindow", pos, yaw)
			"f": piece("metal-firstfloor-window", pos, yaw)
			"d": piece("doorframe-wooden", pos, yaw)

# ---------------------------------------------------------------- ground
func _tex_mat(tex: String, scale: float, tint := Color.WHITE) -> StandardMaterial3D:
	var key := "tex:" + tex
	if _mats.has(key): return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/city/tex/%s.png" % tex)
	m.albedo_color = tint
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(scale, scale, scale)
	m.roughness = 0.95
	_mats[key] = m
	return m

# one flat slab with a kit texture (instead of dozens of tiles)
func slab(x0: float, z0: float, x1: float, z1: float, y: float, m: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(absf(x1 - x0), 0.04, absf(z1 - z0)); mi.mesh = bm
	mi.material_override = m
	mi.position = Vector3((x0 + x1) * 0.5, y - 0.02, (z0 + z1) * 0.5)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	nav.add_child(mi)

func _streets() -> void:
	var asphalt := _tex_mat("T_Concrete_Asphalt_BaseColor", 0.25, Color(0.78, 0.78, 0.80))
	var walk := _tex_mat("T_Concrete_BaseColor", 0.33)
	slab(-HX, -HZ, HX, HZ, 0.0, asphalt)                  # everything is street level...
	slab(-HX, 3.0, HX, 5.6, 0.02, walk)                   # ...with sidewalks along the avenue
	slab(-HX, -5.6, HX, -3.0, 0.02, walk)
	var curb := mat(Color(0.62, 0.62, 0.60))
	for z in [3.0, -3.0]:
		box(Vector3(0, 0.03, z), Vector3(HX * 2, 0.06, 0.2), Color(0.62, 0.62, 0.60), 0.0, false)
	# centre line (double yellow) + crosswalks
	var yel := Color(0.85, 0.70, 0.18)
	for z in [-0.12, 0.12]:
		box(Vector3(0, 0.025, z), Vector3(HX * 2 - 2, 0.01, 0.1), yel, 0.0, false, false)
	piece("decal-crosswalk", Vector3(-13.4, 0.15, 0.0), 90.0)
	piece("decal-crosswalk", Vector3(13.4, 0.15, 0.0), 90.0)
	for x in [-20.0, -6.0, 6.0, 20.0]:
		piece("prop-manholecover", Vector3(x, 0.0, 1.4 * sign(x)))

func _bounds() -> void:
	# collision walls on the play edges + backdrop buildings outside them
	solid(-HX - 1, -HZ - 1, HX + 1, -HZ, 12)
	solid(-HX - 1, HZ, HX + 1, HZ + 1, 12)
	solid(-HX - 1, -HZ, -HX, HZ, 12)
	solid(HX, -HZ, HX + 1, HZ, 12)
	# backdrop: real buildings where the avenue points (most looked at), simple
	# textured blocks elsewhere (one draw call each) so the skyline stays closed
	_no_shadow(piece("building-medium-2-001", Vector3(-HX - 0.6, 0, 6.5), 90.0))
	_no_shadow(piece("building-medium-2-001", Vector3(HX + 0.6, 0, -6.5), 270.0))
	var brick := _tex_mat("T_RedBrick_BaseColor", 0.5)
	var conc := _tex_mat("T_Concrete_BaseColor", 0.3, Color(0.85, 0.82, 0.76))
	var blocks := [[-HX - 14, -HZ - 14, -HX, -2.0, 16.0, brick], [HX, 2.0, HX + 14, HZ + 14, 16.0, brick],
		[-HX, -HZ - 12, -4, -HZ, 13.0, conc], [-4, -HZ - 12, HX + 14, -HZ, 19.0, brick],
		[4, HZ, HX, HZ + 12, 13.0, conc], [-HX - 14, HZ, 4, HZ + 12, 19.0, brick],
		[-HX - 14, 14.0, -HX, HZ, 16.0, conc], [HX, -HZ, HX + 14, -14.0, 16.0, conc]]
	for b in blocks:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new(); bm.size = Vector3(b[2] - b[0], b[4], b[3] - b[1]); mi.mesh = bm
		mi.material_override = b[5]
		mi.position = Vector3((b[0] + b[2]) * 0.5, b[4] * 0.5, (b[1] + b[3]) * 0.5)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		nav.add_child(mi)
	# end-of-avenue barricades (the avenue leaves the map)
	for s in [-1.0, 1.0]:
		for z in [-2.2, 0.0, 2.2]:
			box(Vector3(s * (HX - 0.6), 0.55, z), Vector3(0.6, 1.1, 2.0), Color(0.78, 0.76, 0.72))

# ---------------------------------------------------------------- one half (s = 1 north, -1 south mirror)
func _side(s: float) -> void:
	var P := func(x: float, z: float) -> Vector3: return Vector3(x * s, 0, z * s)
	var V2 := func(x: float, z: float) -> Vector2: return Vector2(x * s, z * s)
	var yaw0 := 0.0 if s > 0 else 180.0
	# A) corner building (solid, prebuilt) on the far side, x -28..-16 / z 6..20
	piece("building-small-1", P.call(-22.77, 8.3), yaw0 + 180.0)
	var a0: Vector3 = P.call(-28.0, 6.0); var a1: Vector3 = P.call(-15.6, 20.0)
	solid(minf(a0.x, a1.x), minf(a0.z, a1.z), maxf(a0.x, a1.x), maxf(a0.z, a1.z), 14)
	# B) raised plaza x -12..-1, z 7..16, height 1.0, stairs down to the avenue and to the alley
	var b0: Vector3 = P.call(-12.0, 7.0); var b1: Vector3 = P.call(-1.0, 16.0)
	block(minf(b0.x, b1.x), minf(b0.z, b1.z), maxf(b0.x, b1.x), maxf(b0.z, b1.z), 1.0, Color(0.52, 0.50, 0.47))
	for x in [-8.0, -6.0]:
		piece("stairs-entrance-concrete", P.call(x, 5.0), yaw0 + 180.0)
	ramp(P.call(-7.0, 4.95), P.call(-7.0, 7.0) + Vector3(0, 1.0, 0), 4.0, Color(0.70, 0.68, 0.64))
	for x in [-5.0, -3.0]:
		piece("stairs-entrance-concrete", P.call(x, 18.0), yaw0)
	ramp(P.call(-4.0, 18.05), P.call(-4.0, 16.0) + Vector3(0, 1.0, 0), 4.0, Color(0.70, 0.68, 0.64))
	# plaza furniture: low walls (cover) along the avenue edge, planters, trees, a bench
	var lw := Color(0.50, 0.47, 0.43)
	for seg in [[-12.0, -9.2], [-4.8, -1.0]]:
		var c0: Vector3 = P.call(seg[0], 7.0); var c1: Vector3 = P.call(seg[1], 7.5)
		block(minf(c0.x, c1.x), minf(c0.z, c1.z), maxf(c0.x, c1.x), maxf(c0.z, c1.z), 1.0, lw, 1.0)
	for p in [[-10.5, 10.5], [-2.8, 13.0], [-9.0, 14.5]]:
		piece("sidewalk-planter", P.call(p[0], p[1]) + Vector3(0, 1.0, 0), yaw0)
		var q: Vector3 = P.call(p[0], p[1])
		solid(q.x - 1.0, q.z - 0.9, q.x + 1.0, q.z + 0.9, 0.55, 1.0)
	_tree(P.call(-10.5, 10.5) + Vector3(0, 1.5, 0))
	_tree(P.call(-2.8, 13.0) + Vector3(0, 1.5, 0))
	box(P.call(-6.0, 12.0) + Vector3(0, 1.45, 0), Vector3(2.4, 0.9, 0.9), Color(0.40, 0.30, 0.22))   # kiosk counter
	# C) cafe (enterable) x 2..14, z 7..17, roof 3.2 m with parapet, outside stairs on the east side
	_shop(s)
	# D) backyard x 16..28, z 7..20: dumpsters, pallets, a low wall; route avenue <-> alley
	var dump := Color(0.22, 0.38, 0.28)
	for p in [[19.5, 9.0, 0.0], [24.5, 15.5, 90.0]]:
		box(P.call(p[0], p[1]) + Vector3(0, 0.7, 0), Vector3(2.0, 1.4, 1.2), dump, p[2])
	for p in [[22.0, 11.5], [18.0, 16.5]]:
		crate(P.call(p[0], p[1]), 1.1, 12.0)
	var w0: Vector3 = P.call(16.5, 12.6); var w1: Vector3 = P.call(21.0, 13.1)
	block(minf(w0.x, w1.x), minf(w0.z, w1.z), maxf(w0.x, w1.x), maxf(w0.z, w1.z), 1.1, Color(0.55, 0.30, 0.24))
	piece("prop-acunit", P.call(16.3, 9.0) + Vector3(0, 1.6, 0), yaw0 + 90.0)
	# street furniture along this sidewalk
	for x in [-20.0, -10.6, 9.0, 20.0]:
		piece("streetlight-double", P.call(x, 5.2), yaw0, 4.2)
		var l: Vector3 = P.call(x, 5.2)
		solid(l.x - 0.2, l.z - 0.2, l.x + 0.2, l.z + 0.2, 4.0)
	piece("trafficlight", P.call(-15.6, 5.0), yaw0 + 180.0, 4.5)
	for x in [-0.5, 0.5, 15.6]:
		_no_shadow(piece("prop-bollard", P.call(x, 5.4), 0.0, 1.0))
	piece("sign-stop", P.call(-11.2, 5.3), yaw0 + 180.0, 4.0)

func _shop(s: float) -> void:
	var V2 := func(x: float, z: float) -> Vector2: return Vector2(x * s, z * s)
	var P := func(x: float, z: float) -> Vector3: return Vector3(x * s, 0, z * s)
	var yaw0 := 0.0 if s > 0 else 180.0
	# walls: outside is to the left of a->b (counter-clockwise when s = 1 seen from +Y? -> pick order per side)
	# front (faces the avenue, z = 7): x 2 -> 14
	wall_run(V2.call(14.0, 7.0), V2.call(2.0, 7.0), "bggdggb" if false else "ggdggb")
	wall_run(V2.call(2.0, 7.0), V2.call(2.0, 17.0), "bwdwb")       # west: door to the side street
	wall_run(V2.call(2.0, 17.0), V2.call(14.0, 17.0), "bbdbwb")    # north: back door to the alley
	wall_run(V2.call(14.0, 17.0), V2.call(14.0, 7.0), "bbbbb")     # east (stairs outside)
	# floor + roof slab (walkable) + parapet with a gap where the stairs arrive
	var f0: Vector3 = P.call(2.2, 7.2); var f1: Vector3 = P.call(13.8, 16.8)
	slab(minf(f0.x, f1.x), minf(f0.z, f1.z), maxf(f0.x, f1.x), maxf(f0.z, f1.z), 0.06, _tex_mat("T_MarbleFloor_BaseColor", 0.5))
	var r0: Vector3 = P.call(2.0, 7.0); var r1: Vector3 = P.call(14.0, 17.0)
	block(minf(r0.x, r1.x), minf(r0.z, r1.z), maxf(r0.x, r1.x), maxf(r0.z, r1.z), 0.25, Color(0.42, 0.42, 0.44), 3.0)
	# parapet: cornice pieces sitting on the roof edge (cover when on top)
	var edges := [[V2.call(14.0, 7.0), V2.call(2.0, 7.0), ""], [V2.call(2.0, 7.0), V2.call(2.0, 17.0), ""],
		[V2.call(2.0, 17.0), V2.call(14.0, 17.0), ""], [V2.call(14.0, 17.0), V2.call(14.0, 7.0), "gap"]]
	for e in edges:
		var a: Vector2 = e[0]; var b: Vector2 = e[1]
		var dir := (b - a).normalized()
		var yaw := rad_to_deg(atan2(-dir.y, dir.x))
		var n := int(a.distance_to(b) / 2.0)
		var a3 := a + (dir * 4.0 if e[2] == "gap" else Vector2.ZERO)
		var mid := (a3 + b) * 0.5
		var inw := -Vector2(Vector3(dir.x, 0, dir.y).cross(Vector3.UP).x, Vector3(dir.x, 0, dir.y).cross(Vector3.UP).z)
		var pc := mid + inw * 0.2
		var pm := MeshInstance3D.new()
		var pb := BoxMesh.new(); pb.size = Vector3(a3.distance_to(b), 0.9, 0.4); pm.mesh = pb
		pm.material_override = _tex_mat("T_RedBrick_BaseColor", 0.5)
		pm.position = Vector3(pc.x, 3.25 + 0.45, pc.y); pm.rotation_degrees.y = yaw
		nav.add_child(pm)
		# collision for the parapet
		var inward := -Vector2(Vector3(dir.x, 0, dir.y).cross(Vector3.UP).x, Vector3(dir.x, 0, dir.y).cross(Vector3.UP).z)
		var a2 := a + (dir * 4.0 if e[2] == "gap" else Vector2.ZERO)
		var q := a2 + inward * 0.4
		var xs := [a2.x, b.x, q.x, q.x + (b.x - a2.x)]
		var zs := [a2.y, b.y, q.y, q.y + (b.y - a2.y)]
		solid(xs.min(), zs.min(), xs.max(), zs.max(), 1.0, 3.25)
	# outside stairs on the east wall: from the backyard (z 8) up to the roof corner (z 15)
	ramp(P.call(15.1, 8.0), P.call(15.1, 15.2) + Vector3(0, 3.25, 0), 1.9, Color(0.35, 0.36, 0.38))
	var st: Vector3 = P.call(15.1, 16.1)
	block(minf(st.x - 0.95 * s, st.x + 0.95 * s), minf(st.z - 0.9 * s, st.z + 0.9 * s), maxf(st.x - 0.95 * s, st.x + 0.95 * s), maxf(st.z - 0.9 * s, st.z + 0.9 * s), 3.25, Color(0.35, 0.36, 0.38))
	# interior: tables (low cover) + a counter along the back
	var wood := Color(0.42, 0.30, 0.20)
	for p in [[5.0, 10.0], [9.0, 10.0], [5.0, 13.5]]:
		box(P.call(p[0], p[1]) + Vector3(0, 0.38, 0), Vector3(1.2, 0.76, 1.2), wood)
	box(P.call(10.5, 15.6) + Vector3(0, 0.55, 0), Vector3(5.0, 1.1, 0.8), Color(0.30, 0.22, 0.16))
	piece("prop-acunit", P.call(8.0, 7.0) + Vector3(0, 3.3, 0) + Vector3(0, 0, -0.6 * s), yaw0 + 180.0)
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.86, 0.66); lamp.light_energy = 1.6; lamp.omni_range = 9.0
	lamp.position = P.call(8.0, 12.0) + Vector3(0, 2.6, 0)
	nav.add_child(lamp)

# simple low-poly street tree (trunk + two leaf clumps); the trunk blocks, leaves don't
func _tree(base: Vector3) -> void:
	cyl(base + Vector3(0, 1.3, 0), 0.16, 2.6, Color(0.36, 0.26, 0.18))
	var leaf := StandardMaterial3D.new(); leaf.albedo_color = Color(0.30, 0.46, 0.22); leaf.roughness = 0.9
	for o in [[Vector3(0, 3.1, 0), 1.5], [Vector3(0.5, 3.9, 0.3), 1.05]]:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new(); sm.radius = o[1]; sm.height = o[1] * 1.7
		sm.radial_segments = 10; sm.rings = 6
		mi.mesh = sm; mi.material_override = leaf
		mi.position = base + (o[0] as Vector3)
		nav.add_child(mi)

func _avenue_cover() -> void:
	# point-symmetric wrecks and barriers; something to hide behind every ~6 m
	var cars := [["car-taxi", Vector3(-6.0, 0, -1.0), 68.0], ["car-cop", Vector3(6.0, 0, 1.0), 248.0],
		["car-normalcar1", Vector3(-17.5, 0, 2.0), 90.0], ["car-suv", Vector3(17.5, 0, -2.0), 270.0],
		["car-sportscar", Vector3(-11.5, 0, -2.0), 95.0], ["car-normalcar2", Vector3(11.5, 0, 2.0), 275.0]]
	for c in cars:
		var n := piece(c[0], c[1], c[2])
		var b := Basis(Vector3.UP, deg_to_rad(c[2]))
		var sb := StaticBody3D.new()
		var col := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = Vector3(1.8, 1.25, 4.1); col.shape = bs
		sb.add_child(col); sb.transform = Transform3D(b, (c[1] as Vector3) + Vector3(0, 0.62, 0))
		nav.add_child(sb)
	var conc := Color(0.80, 0.78, 0.74)
	for p in [[0.0, 0.0, 90.0], [-22.5, -1.6, 15.0], [22.5, 1.6, 15.0]]:
		box(Vector3(p[0], 0.55, p[1]), Vector3(2.6, 1.1, 0.6), conc, p[2])
