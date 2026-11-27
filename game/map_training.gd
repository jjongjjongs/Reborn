class_name MapTraining
extends MapBuilder
## 훈련장 v2 (64 x 54 m, built in code): concrete compound with
##   north  shooting range: lanes 1-6, distance marks 10/20/30 m, baffles, earth berm, paper targets,
##          steel plates, a target on a rail
##   centre dummy area (rubber mat, sandbags)       south  lobby + armory shelf (weapons in a row)
##   west   plywood kill house (START pad, civilian card)   east  movement course + grenade pit
## build_training() returns spots the training mode fills with interactive things.

const TX := "res://assets/maps/tex/%s.png"
var _texm := {}

func tex(name: String, tint := Color(1, 1, 1), scale := 0.25) -> StandardMaterial3D:
	var k := "%s|%s|%s" % [name, tint, scale]
	if _texm.has(k): return _texm[k]
	var m := StandardMaterial3D.new(); m.albedo_texture = load(TX % name); m.albedo_color = tint
	m.uv1_triplanar = true; m.uv1_world_triplanar = true; m.uv1_scale = Vector3.ONE * scale; m.roughness = 0.92
	_texm[k] = m
	return m

func flat(c: Color, rough := 0.8, metal := 0.0) -> StandardMaterial3D:
	var k := "f|%s|%s|%s" % [c, rough, metal]
	if _texm.has(k): return _texm[k]
	var m := StandardMaterial3D.new(); m.albedo_color = c; m.roughness = rough; m.metallic = metal
	_texm[k] = m
	return m

## a box with its own material (collide = solid)
func sbox(c: Vector3, s: Vector3, m: Material, yaw := 0.0, collide := true) -> Node3D:
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = s; mi.mesh = bm; mi.material_override = m
	if not collide:
		mi.position = c; mi.rotation_degrees.y = yaw
		if s.y < 0.1: mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		nav.add_child(mi); return mi
	var sb := StaticBody3D.new(); sb.add_child(mi)
	var col := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = s; col.shape = bs; sb.add_child(col)
	sb.position = c; sb.rotation_degrees.y = yaw
	nav.add_child(sb)
	return sb

func scyl(c: Vector3, r: float, h: float, m: Material, collide := true) -> void:
	var mi := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = r; cm.bottom_radius = r; cm.height = h
	cm.radial_segments = 12; mi.mesh = cm; mi.material_override = m
	if not collide:
		mi.position = c; nav.add_child(mi); return
	var sb := StaticBody3D.new(); sb.add_child(mi)
	var col := CollisionShape3D.new(); var cs := CylinderShape3D.new(); cs.radius = r; cs.height = h; col.shape = cs
	sb.add_child(col); sb.position = c; nav.add_child(sb)

func text(t: String, p: Vector3, size := 64, col := Color(1, 1, 1), flat_on_floor := false, yaw := 0.0, outline := true) -> Label3D:
	var l := Label3D.new(); l.text = t; l.font_size = size; l.pixel_size = 0.01; l.modulate = col
	l.outline_size = 8 if outline else 0; l.outline_modulate = Color(0, 0, 0, 0.5); l.position = p
	l.double_sided = false
	if flat_on_floor: l.rotation_degrees = Vector3(-90, yaw, 0)
	else: l.rotation_degrees.y = yaw
	nav.add_child(l)
	return l

func sandbags(a: Vector3, n: int) -> void:
	var m := tex("T_Dirt_BaseColor", Color(0.80, 0.74, 0.56), 1.5)
	for r in 2:
		for i in n:
			var b := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.5; sm.height = 1.0
			sm.radial_segments = 10; sm.rings = 5; b.mesh = sm; b.material_override = m
			b.position = a + Vector3(i * 0.56 + (r % 2) * 0.28, 0.12 + r * 0.22, 0)
			b.scale = Vector3(0.62, 0.26, 0.40)
			nav.add_child(b)
	sbox(a + Vector3(n * 0.28, 0.3, 0), Vector3(n * 0.56 + 0.3, 0.6, 0.4), flat(Color(0, 0, 0)), 0.0, true).get_child(0).visible = false

func tyres(p: Vector3, n: int) -> void:
	var m := flat(Color(0.08, 0.08, 0.09), 0.95)
	for i in n:
		var t := MeshInstance3D.new(); var tm := TorusMesh.new(); tm.inner_radius = 0.22; tm.outer_radius = 0.42
		tm.rings = 12; tm.ring_segments = 8; t.mesh = tm; t.material_override = m
		t.position = p + Vector3(0, 0.1 + i * 0.2, 0); nav.add_child(t)
	var sb := StaticBody3D.new(); var col := CollisionShape3D.new(); var cs := CylinderShape3D.new(); cs.radius = 0.42; cs.height = n * 0.2
	col.shape = cs; sb.add_child(col); sb.position = p + Vector3(0, n * 0.1, 0); nav.add_child(sb)

func flood(p: Vector3, yaw: float) -> void:
	var metal := flat(Color(0.35, 0.37, 0.40), 0.5, 0.6)
	scyl(p + Vector3(0, 4, 0), 0.1, 8.0, metal)
	sbox(p + Vector3(0, 8.1, 0), Vector3(1.2, 0.4, 0.3), metal, yaw, false)
	var lamp := StandardMaterial3D.new(); lamp.albedo_color = Color(1, 0.97, 0.85); lamp.emission_enabled = true; lamp.emission = Color(1, 0.95, 0.8)
	sbox(p + Vector3(0, 8.0, 0) + Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(0, 0, 0.17), Vector3(1.0, 0.25, 0.04), lamp, yaw, false)

func build_training() -> Dictionary:
	_env(Color(0.60, 0.72, 0.86), Color(0.9, 0.93, 1.0), 0.95, Vector3(-50, -35, 0), Color(1.0, 0.96, 0.9), 1.0, Color(0.72, 0.78, 0.86), 0.004)
	var concrete := tex("T_Concrete_BaseColor", Color(0.66, 0.66, 0.65))
	var asphalt := tex("T_Concrete_Asphalt_BaseColor", Color(0.75, 0.75, 0.75))
	var dirt := tex("T_Dirt_BaseColor", Color(0.85, 0.78, 0.66))
	var mconc := tex("T_MetalConcrete_BaseColor", Color(0.80, 0.82, 0.84))
	var trim := tex("T_Trim_BaseColor", Color(0.9, 0.9, 0.9))
	var ply := tex("T_Concrete_BaseColor", Color(0.86, 0.70, 0.50), 0.6)
	var dark := flat(Color(0.18, 0.19, 0.21))
	var yellow := flat(Color(0.95, 0.72, 0.10))
	var steel := flat(Color(0.55, 0.57, 0.60), 0.35, 0.7)
	var out := {"bounds": Rect2(-32, -27, 64, 54), "player": Vector3(0, 1.0, 19.0)}
	# ground + perimeter
	sbox(Vector3(0, -0.5, 0), Vector3(72, 1, 62), concrete)
	for wl in [[Vector3(0, 2.5, -27), Vector3(64.6, 5, 0.6)], [Vector3(0, 2.5, 27), Vector3(64.6, 5, 0.6)],
			[Vector3(-32, 2.5, 0), Vector3(0.6, 5, 54)], [Vector3(32, 2.5, 0), Vector3(0.6, 5, 54)]]:
		sbox(wl[0], wl[1], mconc)
		sbox(wl[0] + Vector3(0, 2.55, 0), wl[1] * Vector3(1, 0, 1) + Vector3(0.1, 0.12, 0.1), steel, 0.0, false)
	for p in [Vector3(-30.5, 0, 25.5), Vector3(30.5, 0, 25.5), Vector3(-30.5, 0, -10), Vector3(30.5, 0, -10)]:
		flood(p, 0.0 if p.z > 0 else 180.0)
	# ---------------- shooting range
	sbox(Vector3(0, 0.01, -13), Vector3(30, 0.02, 26), asphalt, 0.0, false)
	var lanes: Array = []
	for lane in 6:
		var x := -12.5 + lane * 5.0
		if lane > 0: sbox(Vector3(x - 2.5, 0.6, -5), Vector3(0.25, 1.2, 8), concrete)
		sbox(Vector3(x, 0.55, -0.4), Vector3(4.6, 1.1, 0.8), ply)
		sbox(Vector3(x, 1.12, -0.4), Vector3(4.6, 0.04, 0.8), dark, 0.0, false)
		text(str(lane + 1), Vector3(x, 1.6, -0.02), 80, Color(1, 0.85, 0.3))
		for dz in [10, 20, 30]: text("%dm" % dz, Vector3(x, 0.03, -dz), 54, Color(1, 1, 1, 0.8), true, 0, false)
		lanes.append(Vector3(x, 0, -[10.0, 20.0, 30.0, 20.0, 30.0, 10.0][lane]))
	out["range_targets"] = lanes
	for bz in [-6, -12, -18]:
		sbox(Vector3(0, 3.4, bz), Vector3(30, 0.9, 0.35), flat(Color(0.36, 0.27, 0.19), 0.9))
		for bx in [-15.2, 15.2]: sbox(Vector3(bx, 1.7, bz), Vector3(0.3, 3.4, 0.3), steel)
	var berm := sbox(Vector3(0, 1.4, -25.2), Vector3(30, 3.2, 3.0), dirt)
	berm.rotation_degrees.x = -18
	var plates: Array = []
	for i in 5:
		var x := -10.0 + i * 5.0
		sbox(Vector3(x, 0.6, -22.5), Vector3(0.06, 1.2, 0.06), steel, 0.0, false)
		plates.append([Vector3(x, 1.35, -22.5), 0.22 + (i % 2) * 0.08])
	out["plates"] = plates
	sbox(Vector3(0, 2.2, -15), Vector3(30, 0.06, 0.06), steel, 0.0, false)
	out["rail"] = [Vector3(-13, 0, -15), Vector3(13, 0, -15)]
	text("사격장", Vector3(0, 4.3, -5.8), 90, Color(1, 0.85, 0.4))
	# ---------------- armory (south): cabinet + shelf, a yellow standing zone
	sbox(Vector3(0, 2.5, 26.2), Vector3(24, 5, 1.0), trim)
	sbox(Vector3(0, 0.5, 25.2), Vector3(22, 1.0, 1.2), tex("crate", Color(0.75, 0.62, 0.48), 0.5))
	sbox(Vector3(0, 1.02, 25.2), Vector3(22.2, 0.06, 1.3), flat(Color(0.62, 0.48, 0.32), 0.6), 0.0, false)
	sbox(Vector3(0, 0.012, 23.2), Vector3(22, 0.02, 2.6), yellow, 0.0, false)
	sbox(Vector3(0, 0.018, 23.2), Vector3(21.6, 0.022, 2.2), concrete, 0.0, false)
	text("무기 보관대", Vector3(0, 2.6, 25.65), 80, Color(0.95, 0.95, 0.9), false, 180)
	var guns := ["m4", "ak", "mp5", "shotgun", "sniper", "rpk", "pistol", "revolver", "knife"]
	var arm: Array = []
	for i in guns.size():
		var x := 9.6 - i * 2.4                     # left-to-right when facing the shelf
		sbox(Vector3(x, 1.065, 25.1), Vector3(2.0, 0.03, 0.9), flat(Color(0.70, 0.71, 0.72), 1.0), 0.0, false)
		var g: Node3D = (load("res://assets/guns/%s.glb" % guns[i]) as PackedScene).instantiate(); nav.add_child(g)
		var ab := AABB(); var first := true
		for mi in g.find_children("*", "MeshInstance3D", true, false):
			var bx: AABB = (mi as MeshInstance3D).get_aabb(); ab = bx if first else ab.merge(bx); first = false
			(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var want_len: float = 1.45 if guns[i] in ["sniper", "rpk"] else (0.6 if guns[i] in ["pistol", "revolver", "knife"] else 1.15)
		g.scale = Vector3.ONE * want_len / maxf(maxf(ab.size.x, ab.size.z), 0.01)
		g.rotation_degrees = Vector3(90, 0, 0); g.position = Vector3(x, 1.12, 25.1)
		Profile.apply_finish(g, "", guns[i])
		sbox(Vector3(x, 0.8, 24.58), Vector3(1.4, 0.3, 0.04), flat(Color(0.12, 0.13, 0.14)), 0.0, false)
		text(Weapons.get_w(guns[i])["name"], Vector3(x, 0.8, 24.55), 36, Color(1, 0.9, 0.6), false, 180, false)
		arm.append({"id": guns[i], "pos": Vector3(x, 0, 23.6), "pad": Vector3(x, 1.06, 25.1)})
	out["armory"] = arm
	for k in 3: sbox(Vector3(13.5 + k * 1.1, 1.0, 25.6), Vector3(1.0, 2.0, 0.6), flat(Color(0.26, 0.36, 0.30), 0.5, 0.3))
	out["board"] = Vector3(-14.5, 0, 25.0)
	sbox(Vector3(-14.5, 1.9, 25.6), Vector3(5.0, 2.6, 0.2), dark)
	# ---------------- dummy area
	sbox(Vector3(0, 0.02, 10.5), Vector3(18, 0.04, 8), flat(Color(0.16, 0.17, 0.18), 1.0), 0.0, false)
	sandbags(Vector3(-8.6, 0, 6.6), 28)                    # behind the dummies (north), clear of the range
	out["dummies"] = [Vector3(-6, 0, 8.2), Vector3(0, 0, 8.2), Vector3(6, 0, 8.2)]
	# ---------------- kill house (west)
	for r in [[Vector3(-23, 1.4, -14), Vector3(14, 2.8, 0.15)], [Vector3(-26.5, 1.4, 2), Vector3(7, 2.8, 0.15)], [Vector3(-18.2, 1.4, 2), Vector3(3.6, 2.8, 0.15)],
			[Vector3(-16.1, 1.4, -11), Vector3(0.15, 2.8, 6)], [Vector3(-16.1, 1.4, -1.5), Vector3(0.15, 2.8, 7)], [Vector3(-23, 1.4, -8.5), Vector3(0.15, 2.8, 5)],
			[Vector3(-23, 1.4, 0), Vector3(0.15, 2.8, 4)], [Vector3(-27.5, 1.4, -6), Vector3(9, 2.8, 0.15)]]:
		sbox(r[0], r[1], ply)
		sbox(r[0] + Vector3(0, 1.42, 0), r[1] * Vector3(1, 0, 1) + Vector3(0.06, 0.06, 0.06), flat(Color(0.35, 0.27, 0.2)), 0.0, false)
	out["kh_targets"] = [[Vector3(-20, 0, -10), 30.0], [Vector3(-26, 0, -3), -20.0], [Vector3(-29, 0, -11), 10.0], [Vector3(-19, 0, -4), 60.0]]
	out["kh_civ"] = [Vector3(-24.5, 0, -11), 0.0]
	out["kh_start"] = Vector3(-20.2, 0, 4.0)
	sbox(Vector3(-20.2, 0.02, 4.0), Vector3(2.2, 0.04, 1.2), flat(Color(0.2, 0.75, 0.35)), 0.0, false)
	text("START", Vector3(-20.2, 0.06, 4.0), 60, Color(1, 1, 1), true, 180, false)
	text("킬하우스", Vector3(-23, 3.4, 2.1), 70, Color(1, 0.85, 0.4))
	# ---------------- movement course (east)
	for st in [[Vector3(18, 0, 6), 1.1], [Vector3(20.2, 0, 6), 2.2], [Vector3(22.4, 0, 6), 3.3], [Vector3(24.6, 0, 3.6), 3.3], [Vector3(24.6, 0, 1.2), 4.4]]:
		sbox(Vector3(st[0].x, st[1] * 0.5, st[0].z), Vector3(2.0, st[1], 2.0), ply)
		sbox(Vector3(st[0].x, st[1] + 0.02, st[0].z), Vector3(2.04, 0.04, 2.04), yellow, 0.0, false)
	sbox(Vector3(24.6, 4.3, -3.0), Vector3(1.2, 0.2, 6.5), tex("crate", Color(0.8, 0.7, 0.55), 0.5))
	sbox(Vector3(24.6, 4.42, -5.6), Vector3(1.2, 0.04, 1.2), flat(Color(0.2, 0.75, 0.35)), 0.0, false)
	out["course_start"] = Vector3(15.8, 0, 6.0); out["course_end"] = Vector3(24.6, 4.4, -5.6)
	sbox(Vector3(15.8, 0.02, 6.0), Vector3(1.6, 0.04, 1.6), flat(Color(0.2, 0.75, 0.35)), 0.0, false)
	text("START", Vector3(15.8, 0.06, 6.0), 44, Color(1, 1, 1), true, 180, false)
	text("이동 코스", Vector3(21, 5.6, 6.0), 70, Color(1, 0.85, 0.4))
	for p in [Vector3(16, 0, 1), Vector3(17, 0, -1.5), Vector3(19.2, 0, 0.5)]: tyres(p, 3)
	# ---------------- grenade pit
	sbox(Vector3(22, 0.012, -18), Vector3(13, 0.02, 11), dirt, 0.0, false)
	sandbags(Vector3(15.6, 0, -12.6), 21)
	for r in [2.0, 4.0, 6.0]:
		var ring := MeshInstance3D.new(); var tm := TorusMesh.new(); tm.inner_radius = r - 0.1; tm.outer_radius = r
		tm.rings = 32; tm.ring_segments = 4; ring.mesh = tm; ring.material_override = flat(Color(0.95, 0.95, 0.9))
		ring.position = Vector3(22, 0.03, -19); ring.scale = Vector3(1, 0.05, 1); nav.add_child(ring)
	text("수류탄 연습장", Vector3(22, 0.05, -12.9), 60, Color(1, 1, 1), true, 180)
	if not MapBuilder.backdrop: _bake()
	return out
