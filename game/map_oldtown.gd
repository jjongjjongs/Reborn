class_name MapOldTown
extends MapDowntown
## 구시가지 (Old Town) — bomb defusal map, 100 x 80 m. North (-Z) = defenders
## (town hall), south (+Z) = attackers (station square).
##   A  : church square (open plaza, fountain, arcade on its east edge)
##   B  : covered market hall (stalls, 3 doors)
##   mid: arcade avenue -> bell-tower square, which links to both sites
## Attack routes: A alley (west), covered passage (mid -> alley), mid avenue,
## canal bridge (B approach). Defenders rotate behind both sites on the
## town-hall street. See the 시안 for the plan this follows.

const W := 50.0
const D := 40.0

func build_oldtown() -> Dictionary:
	_bx = W; _bz = D
	_env(Color(0.60, 0.68, 0.80), Color(0.80, 0.80, 0.82), 1.0, Vector3(-48, -25, 0), Color(1.0, 0.94, 0.84), 1.2, Color(0.66, 0.70, 0.76), 0.004)
	box(Vector3(0, -0.5, 0), Vector3(W * 2 + 30, 1, D * 2 + 30), Color(0.3, 0.3, 0.3))
	var cobble := _tex_mat("T_Concrete_Asphalt_BaseColor", 0.3, Color(0.86, 0.82, 0.76))
	var plaza := _tex_mat("T_MarbleFloor_BaseColor", 0.25, Color(0.86, 0.84, 0.80))
	slab(-W, -D, W, D, 0.0, cobble)
	slab(-44, -22, -20, -2, 0.03, plaza)          # church square
	slab(-8, -20, 8, -2, 0.03, plaza)             # bell-tower square
	_bounds_old()
	_buildings()
	_site_a()
	_market()
	_canal()
	_passage()
	_props()
	_windows_flush()
	_bake_colliders()
	var att := _spawns([[-8, 34], [-4, 36], [0, 34], [4, 36], [8, 34]])
	var def := _spawns([[-8, -27], [-4, -28.5], [0, -27], [4, -28.5], [8, -27]])
	return {"att": att, "def": def, "red": att, "blue": def, "ffa": att + def,
		"zombie": att + def, "player": att[0], "bounds": Rect2(-W, -D, W * 2, D * 2),
		"site_a": Rect2(-38, -16, 12, 10), "site_b": Rect2(22, -20, 14, 10), "mid": Vector3(0, 0.5, -16)}

# ---------------------------------------------------------------- building helpers
func _bounds_old() -> void:
	solid(-W - 1, -D - 1, W + 1, -D, 14); solid(-W - 1, D, W + 1, D + 1, 14)
	solid(-W - 1, -D, -W, D, 14); solid(W, -D, W + 1, D, 14)

# ---------------------------------------------------------------- layout
func _buildings() -> void:
	house(-10, -40, 10, -31, 10, 1)            # town hall (defenders)
	house(10, -40, 50, -32, 11, 0)             # north-east row (street to the market's north door below it)
	house(-30, -40, -10, -31, 9, 3)            # north-west filler
	house(-50, -22, -44, 40, 9, 2, false)      # west edge row
	house(44, -28, 50, 40, 9, 2, false)        # east edge row
	house(-18, -20, -8, -12, 7, 3)             # between defenders and the A link
	house(-18, -4, -6, 16, 9, 0)               # mid west block (A link south side)
	house(8, -20, 14, -14, 7, 1)               # between defenders and the B link
	house(6, -8, 14, 16, 9, 2)                 # mid east block
	house(20, -2, 44, 12, 8, 1)                # east block (south of the market)
	house(-44, -2, -24, 30, 9, 3)              # south-west quarter (A alley west side)
	house(-18, 20, -6, 26, 8, 2)               # below the covered passage
	house(6, 16, 14, 26, 8, 0)                 # mid south-east
	house(20, 16, 44, 30, 9, 3)                # south of the canal
	house(-44, 30, -12, 40, 8, 1)              # station row west
	house(24, 30, 44, 40, 8, 2)                # station row east
	house(12, 36, 24, 40, 6, 0)
	# church (tall, with a tower) north-west of the square
	house(-50, -40, -30, -22, 12, 1)
	house(-38, -36, -32, -24, 20, 1, false)    # church tower
	# bell tower in the middle square
	house(-4, -12, 4, -6, 15, 3)
	var bell := MeshInstance3D.new(); var bb := BoxMesh.new(); bb.size = Vector3(5, 2.5, 3.2); bell.mesh = bb
	bell.material_override = _tex_mat("T_Trim_BaseColor", 0.4); bell.position = Vector3(0, 16.2, -9); nav.add_child(bell)

func _site_a() -> void:
	# church square: fountain, planters, a parked van, benches, low hedge walls
	cyl(Vector3(-32, 0.45, -11), 2.3, 0.9, Color(0.66, 0.64, 0.60))
	cyl(Vector3(-32, 1.5, -11), 0.5, 1.4, Color(0.60, 0.58, 0.54))
	for p in [[-41, -18], [-24, -18], [-41, -5], [-27, -4.5]]:
		piece("sidewalk-planter", Vector3(p[0], 0.0, p[1]))
		solid(p[0] - 1.0, p[1] - 0.9, p[0] + 1.0, p[1] + 0.9, 0.55)
	_tree(Vector3(-41, 0, -18)); _tree(Vector3(-24, 0, -18))
	var hedge := Color(0.30, 0.42, 0.24)
	box(Vector3(-36.5, 0.55, -3.2), Vector3(5.0, 1.1, 0.8), hedge)
	box(Vector3(-25.0, 0.55, -13.5), Vector3(0.8, 1.1, 4.0), hedge)
	var van := piece("car-suv", Vector3(-40.5, 0, -10.5), 10.0)
	_car_col(Vector3(-40.5, 0, -10.5), 10.0)
	crate(Vector3(-28.5, 0, -7.5), 1.1, 15.0); crate(Vector3(-28.5, 1.1, -7.5), 0.8, 40.0)
	# arcade (east edge of the square): pillars + roof
	for z in range(-20, -1, 4):
		box(Vector3(-19.4, 2.1, z), Vector3(0.7, 4.2, 0.7), Color(0.84, 0.80, 0.72))
	var ar := MeshInstance3D.new(); var ab := BoxMesh.new(); ab.size = Vector3(3.4, 0.4, 19.0); ar.mesh = ab
	ar.material_override = _tex_mat("T_Trim_BaseColor", 0.4); ar.position = Vector3(-19.6, 4.4, -11.0)
	nav.add_child(ar)
	solid(-21.3, -20.5, -17.9, -1.5, 0.4, 4.2)
	_site_mark("A", Vector3(-32, 0.06, -11), Vector2(12, 10))

func _market() -> void:
	# hall x 14..44, z -28..-2, walls 5 m, roof; doors: west (z -14..-10),
	# south (x 15..19), north (x 26..30)
	var h := 5.0
	var wallm := _tex_mat("T_RedBrick_BaseColor", 0.5, Color(0.92, 0.84, 0.76))
	var walls := [[14, -28, 14.4, -14], [14, -10, 14.4, -2],           # west (door z -14..-10)
		[14, -2.4, 15, -2], [19, -2.4, 44, -2],                          # south (door x 15..19)
		[14, -28, 26, -27.6], [30, -28, 44, -27.6],                      # north (door x 26..30)
		[43.6, -28, 44, -2]]                                             # east
	for w in walls:
		var mi := MeshInstance3D.new(); var bm := BoxMesh.new()
		bm.size = Vector3(w[2] - w[0], h, w[3] - w[1]); mi.mesh = bm; mi.material_override = wallm
		mi.position = Vector3((w[0] + w[2]) * 0.5, h * 0.5, (w[1] + w[3]) * 0.5)
		nav.add_child(mi)
		solid(w[0], w[1], w[2], w[3], h)
	# lintels over the doors
	for l in [[14, -14, 14.4, -10], [15, -2.4, 19, -2], [26, -28, 30, -27.6]]:
		box(Vector3((l[0] + l[2]) * 0.5, 4.0, (l[1] + l[3]) * 0.5), Vector3(l[2] - l[0], 2.0, l[3] - l[1]), Color(0.70, 0.62, 0.52))
	# roof + skylight band, interior floor, lights
	var roof := MeshInstance3D.new(); var rb := BoxMesh.new(); rb.size = Vector3(30.4, 0.4, 26.4); roof.mesh = rb
	roof.material_override = _tex_mat("T_Concrete_BaseColor", 0.3, Color(0.45, 0.44, 0.44))
	roof.position = Vector3(29, h + 0.2, -15); nav.add_child(roof)
	solid(14, -28, 44, -2, 0.4, h)
	slab(14.4, -27.6, 43.6, -2.4, 0.04, _tex_mat("T_MarbleFloor_BaseColor", 0.4, Color(0.80, 0.76, 0.70)))
	for p in [Vector3(21, 4.2, -21), Vector3(36, 4.2, -21), Vector3(21, 4.2, -8), Vector3(36, 4.2, -8)]:
		var l := OmniLight3D.new(); l.light_color = Color(1.0, 0.88, 0.70); l.light_energy = 1.4; l.omni_range = 12.0
		l.position = p; nav.add_child(l)
	# stalls (cover) in rows, crates, the counter islands
	var cloth := [Color(0.72, 0.22, 0.18), Color(0.20, 0.42, 0.62), Color(0.28, 0.52, 0.30), Color(0.82, 0.62, 0.18)]
	var stalls := [[19, -24, 0], [19, -17, 0], [39, -24, 180], [39, -17, 180], [26.5, -6.5, 90], [33.5, -6.5, 90]]
	for i in stalls.size():
		var s: Array = stalls[i]
		_stall(Vector3(s[0], 0, s[1]), cloth[i % 4], s[2])
	for p in [[24, -25.5], [33, -12], [28, -13], [41, -11]]:
		crate(Vector3(p[0], 0, p[1]), 1.1, 20.0)
	box(Vector3(29, 0.55, -24.5), Vector3(4.0, 1.1, 1.2), Color(0.40, 0.30, 0.22))
	_site_mark("B", Vector3(29, 0.06, -15), Vector2(14, 10))
	# facade pieces on the B-link side (west wall) for looks
	for z in [-26.0, -20.0, -6.0]:
		piece("brick-window-trim", Vector3(14.0, 0, z), 90.0)
	piece("doorframe-wooden", Vector3(14.0, 0, -12.0), 90.0)

func _canal() -> void:
	# canal x 14..44, z 12..16: water you cannot enter; one 3 m footbridge at x 16..19
	var water := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(30, 4); water.mesh = pm
	var wm := StandardMaterial3D.new(); wm.albedo_color = Color(0.16, 0.34, 0.42); wm.roughness = 0.15; wm.metallic = 0.2
	water.material_override = wm; water.position = Vector3(29, -0.6, 14); nav.add_child(water)
	# banks (thin walls) block walking into the water except over the bridge
	solid(14, 12, 16, 16, 3.0); solid(19, 12, 44, 16, 3.0)
	var stone := Color(0.62, 0.60, 0.56)
	box(Vector3(15.0, 0.25, 14), Vector3(2.0, 0.5, 4.0), stone)
	box(Vector3(31.5, 0.25, 12.15), Vector3(25.0, 0.5, 0.3), stone)
	box(Vector3(31.5, 0.25, 15.85), Vector3(25.0, 0.5, 0.3), stone)
	# bridge deck + rails
	box(Vector3(17.5, 0.05, 14), Vector3(3.2, 0.1, 4.6), Color(0.45, 0.34, 0.24), 0.0, false)   # walkable (no step)
	for x in [15.95, 19.05]:
		box(Vector3(x, 0.6, 14), Vector3(0.12, 1.0, 4.4), Color(0.25, 0.25, 0.27))

func _passage() -> void:
	# covered passage from the mid avenue to the A alley: x -18..-6, z 16..20, roofed
	var roof := MeshInstance3D.new(); var rb := BoxMesh.new(); rb.size = Vector3(12.0, 0.4, 4.4); roof.mesh = rb
	roof.material_override = _tex_mat("T_Concrete_BaseColor", 0.3, Color(0.70, 0.66, 0.60))
	roof.position = Vector3(-12, 3.4, 18); nav.add_child(roof)
	solid(-18, 15.8, -6, 20.2, 0.4, 3.2)
	var l := OmniLight3D.new(); l.light_color = Color(1.0, 0.85, 0.6); l.light_energy = 1.0; l.omni_range = 7.0
	l.position = Vector3(-12, 2.8, 18); nav.add_child(l)
	crate(Vector3(-9.5, 0, 17.0), 1.0, 10.0)

func _props() -> void:
	# mid avenue arcade pillars (cover) and cars
	for z in [2.0, 8.0, 14.0, 22.0]:
		for x in [-5.2, 5.2]:
			box(Vector3(x, 1.8, z), Vector3(0.7, 3.6, 0.7), Color(0.84, 0.80, 0.72))
	var cars := [["car-taxi", Vector3(-2.2, 0, 5.0), 175.0], ["car-normalcar1", Vector3(2.4, 0, 19.0), 10.0],
		["car-cop", Vector3(-17.0, 0, 28.0), 92.0], ["car-sportscar", Vector3(17.0, 0, 22.0), 2.0],
		["car-normalcar2", Vector3(-3.0, 0, -26.0), 88.0], ["car-suv", Vector3(-21.0, 0, 12.0), 178.0]]
	for c in cars:
		piece(c[0], c[1], c[2])
		_car_col(c[1], c[2])
	# barriers / crates along the lanes
	var conc := Color(0.80, 0.78, 0.74)
	for p in [[0, 27, 0], [-21, 0.5, 90], [17, 6, 90], [-2, -16, 0], [11, -11, 90], [-13, -8, 90], [20, -30, 0], [-22, -27, 0]]:
		jersey(Vector3(p[0], 0, p[1]), p[2])
	for p in [[-22.5, 22], [-19.5, 6], [18.5, 26], [3.5, -3], [-6.5, -22], [12, -24]]:
		crate(Vector3(p[0], 0, p[1]), 1.1, randf_range(-12, 12))
	for p in [Vector3(-6.6, 0, 26.5), Vector3(6.6, 0, 26.5), Vector3(-4.4, 0, -1.2), Vector3(4.4, 0, -1.2), Vector3(-20, 0, -24), Vector3(12, 0, -26)]:
		piece("streetlight-double", p, 0.0, 4.2)
		solid(p.x - 0.2, p.z - 0.2, p.x + 0.2, p.z + 0.2, 4.0)
	# station square furniture (attacker spawn) + town hall steps (defender spawn)
	box(Vector3(0, 0.3, 39.0), Vector3(14, 0.6, 1.6), Color(0.55, 0.53, 0.50))
	for x in [-6.0, 6.0]:
		piece("stairs-entrance-concrete", Vector3(x, 0, -31.0), 180.0)

func _car_col(p: Vector3, yaw: float) -> void:
	var sb := StaticBody3D.new()
	var col := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = Vector3(1.8, 1.25, 4.1); col.shape = bs
	sb.add_child(col); sb.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), p + Vector3(0, 0.62, 0))
	nav.add_child(sb)

# painted site marking: outline + big letter on the ground
func _site_mark(letter: String, c: Vector3, size: Vector2) -> void:
	var col := Color(1.0, 0.55, 0.15) if letter == "A" else Color(0.98, 0.78, 0.25)
	var t := 0.25
	for e in [[Vector3(0, 0, -size.y * 0.5), Vector3(size.x, 0.01, t)], [Vector3(0, 0, size.y * 0.5), Vector3(size.x, 0.01, t)],
			[Vector3(-size.x * 0.5, 0, 0), Vector3(t, 0.01, size.y)], [Vector3(size.x * 0.5, 0, 0), Vector3(t, 0.01, size.y)]]:
		box(c + (e[0] as Vector3), e[1], col, 0.0, false, false)
	var lb := Label3D.new()
	lb.text = letter; lb.font_size = 512; lb.pixel_size = 0.01
	lb.modulate = Color(col.r, col.g, col.b, 0.55); lb.outline_size = 0
	lb.rotation_degrees = Vector3(-90, 0, 0)
	lb.position = c + Vector3(0, 0.03, 0)
	nav.add_child(lb)
