class_name MapPlan
extends MapOldTown
## Maps modelled in Blender from a plan (assets/maps/<id>.json, drawn as ASCII in
## tools/blender/maps) by the multi-level column mesher: rooms inside buildings,
## tunnels under streets, bridges/catwalks, raised floors, crates and containers.
## Here: load the model, add collisions, smooth ramp colliders over the stepped
## stairs, spawns (FFA / teams / bomb) and bomb sites when the plan has them.

const ENVS := {   # theme -> sky, ambient, sun rotation, sun colour, sun energy, fog
	"old": [Color(0.62, 0.72, 0.84), Color(0.80, 0.80, 0.82), Vector3(-52, -35, 0), Color(1.0, 0.94, 0.84), 1.2, Color(0.70, 0.74, 0.80)],
	"desert": [Color(0.74, 0.78, 0.84), Color(0.86, 0.80, 0.72), Vector3(-58, -25, 0), Color(1.0, 0.90, 0.74), 1.35, Color(0.86, 0.80, 0.70)],
	"prison": [Color(0.58, 0.64, 0.70), Color(0.74, 0.76, 0.78), Vector3(-48, 30, 0), Color(0.96, 0.96, 0.94), 1.1, Color(0.62, 0.66, 0.70)],
	"harbor": [Color(0.60, 0.72, 0.84), Color(0.76, 0.80, 0.86), Vector3(-42, -60, 0), Color(1.0, 0.92, 0.82), 1.15, Color(0.66, 0.74, 0.82)],
	"city": [Color(0.60, 0.70, 0.82), Color(0.78, 0.80, 0.84), Vector3(-55, 40, 0), Color(1.0, 0.95, 0.88), 1.2, Color(0.68, 0.72, 0.78)],
	"base": [Color(0.64, 0.72, 0.80), Color(0.82, 0.80, 0.76), Vector3(-50, -50, 0), Color(1.0, 0.94, 0.84), 1.2, Color(0.74, 0.76, 0.76)],
	"dusk": [Color(0.42, 0.36, 0.44), Color(0.56, 0.54, 0.60), Vector3(-18, -70, 0), Color(1.0, 0.62, 0.38), 1.0, Color(0.40, 0.42, 0.40), 0.016],
	"lab": [Color(0.66, 0.72, 0.78), Color(0.80, 0.82, 0.84), Vector3(-60, -15, 0), Color(0.96, 0.97, 1.0), 1.15, Color(0.70, 0.74, 0.78)],
}
var plan := {}
var _hw := 55.0
var _hh := 50.0

func build_plan(file: String) -> Dictionary:
	plan = JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/%s.json" % file))
	_hw = float(plan["W"]) * 0.5; _hh = float(plan["H"]) * 0.5
	_bx = _hw; _bz = _hh
	var e: Array = ENVS.get(String(plan.get("theme", "old")), ENVS["old"])
	_env(e[0], e[1], 1.0, e[2], e[3], e[4], e[5], float(e[6]) if e.size() > 6 else 0.006)
	var model: Node3D = (load("res://assets/maps/%s.gltf" % file) as PackedScene).instantiate()
	nav.add_child(model)
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var nm := String(m.name)
		if nm == "Quarter":
			m.create_trimesh_collision()
		else:
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if nm == "Detail": _awning_cols(m)
			if nm == "Windows" or nm == "Detail": _interiors(m, nm == "Detail")
	# stairs are drawn as steps but walked as smooth slopes (solid wedges)
	for r in plan["ramps"]:
		_wedge(float(r[0]), float(r[1]), float(r[2]), float(r[3]), float(r[4]), float(r[5]), String(r[6]))
	# keep everyone inside
	var w := _hw + 1.0; var h := _hh + 1.0
	solid(-w, -h, w, -_hh, 30); solid(-w, _hh, w, h, 30)
	solid(-w, -_hh, -_hw, _hh, 30); solid(_hw, -_hh, w, _hh, 30)
	_plan_props()
	if String(plan.get("name", "")) == "zombie_reststop": _reststop_props()
	Radar.overview = _overview()
	var bomb := plan.has("siteA") and plan.has("siteB")
	if bomb:
		_site_mark("A", _wp(_centroid(plan["siteA"])) + Vector3(0, 0.06, 0), Vector2(0, 0))
		_site_mark("B", _wp(_centroid(plan["siteB"])) + Vector3(0, 0.06, 0), Vector2(0, 0))
	if String(plan.get("name", "")) != "zombie_reststop" and not MapBuilder.backdrop: _auto_routes()
	_bake_colliders()
	var att: Array[Vector3] = []
	for p in plan["att_spawns"]: att.append(_wp(p) + Vector3(0, 1.0, 0))
	var def: Array[Vector3] = []
	for p in plan["def_spawns"]: def.append(_wp(p) + Vector3(0, 1.0, 0))
	var ffa: Array[Vector3] = []
	for p in plan.get("ffa_spawns", []): ffa.append(_wp(p) + Vector3(0, 1.0, 0))
	if ffa.is_empty(): ffa = att + def
	var zs: Array[Vector3] = []
	for p in plan.get("zombie_spawns", []): zs.append(_wp(p) + Vector3(0, 1.0, 0))
	if zs.is_empty(): zs = ffa
	var out := {"att": att, "def": def, "red": att, "blue": def, "ffa": ffa, "zombie": zs,
		"player": att[0] if bomb else ffa[0], "bounds": Rect2(-_hw, -_hh, _hw * 2.0, _hh * 2.0),
		"mid": _wp(plan["mid"]) + Vector3(0, 0.5, 0)}
	if bomb:
		out["site_a"] = _rect_of(plan["siteA"]); out["site_b"] = _rect_of(plan["siteB"])
		out["site_a_poly"] = _poly(plan["siteA"]); out["site_b_poly"] = _poly(plan["siteB"])
	return out

# readable top-down map for the radar / full map: drawn from the plan, not rendered
# (walkable = light, buildings = dark, covered rooms / tunnels / stairs / raised floors marked)
const OV_PX := 8.0
func _overview() -> ImageTexture:
	var W := float(plan["W"]); var H := float(plan["H"])
	var img := Image.create(int(W * OV_PX), int(H * OV_PX), false, Image.FORMAT_RGBA8)
	img.fill(Color(0.17, 0.18, 0.20))
	var col := {"street": Color(0.60, 0.60, 0.58), "plaza": Color(0.66, 0.65, 0.61), "att": Color(0.70, 0.52, 0.50),
		"def": Color(0.50, 0.58, 0.72), "siteA": Color(0.86, 0.60, 0.36), "siteB": Color(0.86, 0.74, 0.40),
		"room": Color(0.42, 0.41, 0.40), "tunnel": Color(0.30, 0.40, 0.50), "water": Color(0.16, 0.30, 0.40)}
	var R := func(x0: float, y0: float, x1: float, y1: float, c: Color) -> void:
		img.fill_rect(Rect2i(int(x0 * OV_PX), int(y0 * OV_PX), int(ceil((x1 - x0) * OV_PX)), int(ceil((y1 - y0) * OV_PX))), c)
	# covered spaces first (rooms, tunnels, passages under bridges), open ground over them
	for sp in plan["spaces"]:
		if sp[6] != null:
			var k := String(sp[0])
			R.call(sp[1], sp[2], sp[3], sp[4], col.get(k, col["room"]) if k != "street" else col["room"])
	for sp in plan["spaces"]:
		if sp[6] == null:
			var c: Color = col.get(String(sp[0]), col["street"])
			var z := float(sp[5])
			if z > 0.3:   # raised floor: lighter + outlined
				R.call(sp[1], sp[2], sp[3], sp[4], c.darkened(0.45))
				R.call(float(sp[1]) + 0.25, float(sp[2]) + 0.25, float(sp[3]) - 0.25, float(sp[4]) - 0.25, c.lightened(minf(0.45, z * 0.1)))
			else:
				R.call(sp[1], sp[2], sp[3], sp[4], c)
	for r in plan["ramps"]:   # stairs: stripes across the slope
		var x0 := float(r[0]); var y0 := float(r[1]); var x1 := float(r[2]); var y1 := float(r[3])
		R.call(x0, y0, x1, y1, Color(0.52, 0.52, 0.50))
		var along_x: bool = r[6] in ["e", "w"]
		var n := int((x1 - x0 if along_x else y1 - y0) / 0.5)
		for i in n:
			if i % 2 == 0: continue
			if along_x: R.call(x0 + i * 0.5, y0, x0 + i * 0.5 + 0.25, y1, Color(0.38, 0.38, 0.37))
			else: R.call(x0, y0 + i * 0.5, x1, y0 + i * 0.5 + 0.25, Color(0.38, 0.38, 0.37))
	for b in plan["blocks"]:
		var k := String(b[5]) if b.size() > 5 else "crate"
		var c := Color(0.42, 0.32, 0.22) if k == "crate" else (Color(0.36, 0.38, 0.40) if k == "barrier" else Color(0.30, 0.34, 0.40))
		R.call(b[0], b[1], float(b[0]) + float(b[2]), float(b[1]) + float(b[3]), c.darkened(0.3))
		R.call(float(b[0]) + 0.2, float(b[1]) + 0.2, float(b[0]) + float(b[2]) - 0.2, float(b[1]) + float(b[3]) - 0.2, c)
	for pr in plan.get("props", []):
		if pr[0] == "car":
			var w := 1.9 if float(pr[3]) == 0.0 else 4.3; var h := 4.3 if float(pr[3]) == 0.0 else 1.9
			R.call(float(pr[1]) - w * 0.5, float(pr[2]) - h * 0.5, float(pr[1]) + w * 0.5, float(pr[2]) + h * 0.5, Color(0.30, 0.32, 0.36))
	return ImageTexture.create_from_image(img)

# floor height of the open space at a plan point (props stand on it)
func _floor_at(x: float, y: float) -> float:
	var z := 0.0
	for sp in plan["spaces"]:
		if sp[6] == null and x >= float(sp[1]) and x < float(sp[3]) and y >= float(sp[2]) and y < float(sp[4]):
			z = float(sp[5])
	return z

const CARS := ["car-normalcar1", "car-normalcar2", "car-suv", "car-taxi", "car-sportscar"]

func _plan_props() -> void:
	var theme := String(plan.get("theme", "old"))
	var k := 0
	for pr in plan.get("props", []):
		k += 1
		var x := float(pr[1]); var y := float(pr[2])
		var p := Vector3(x - _hw, _floor_at(x, y), y - _hh)
		var to_mid := atan2(-p.x, -p.z)
		match String(pr[0]):
			"lamp":
				if theme == "desert":
					cyl(p + Vector3(0, 1.4, 0), 0.08, 2.8, Color(0.38, 0.27, 0.18))
					box(p + Vector3(0, 2.9, 0), Vector3(0.34, 0.42, 0.34), Color(1.0, 0.86, 0.55), 0.0, false, false)
				else:
					piece("streetlight-single", p, rad_to_deg(snappedf(to_mid, PI * 0.5)))
					solid(p.x - 0.15, p.z - 0.15, p.x + 0.15, p.z + 0.15, 4.0, p.y)
			"tree":
				if theme == "desert": _palm(p, k)
				else:
					_tree(p)
					solid(p.x - 0.2, p.z - 0.2, p.x + 0.2, p.z + 0.2, 3.0, p.y)
			"car":
				var yaw := float(pr[3]) + (180.0 if k % 2 == 0 else 0.0)
				piece(CARS[k % CARS.size()], p, yaw)
				_car_col(p, yaw)
			"barrel":
				var cols := [Color(0.30, 0.42, 0.52), Color(0.62, 0.22, 0.16), Color(0.36, 0.44, 0.26)]
				barrel(p + Vector3(-0.35, 0, -0.3), cols[k % 3])
				barrel(p + Vector3(0.45, 0, 0.1), cols[(k + 1) % 3])
				if k % 2 == 0: barrel(p + Vector3(-0.2, 0, 0.55), cols[(k + 2) % 3])

# ---- jump routes: crate staircases up to low roofs, found from a 1 m height map of the built level
static var climb_links := false
static var route_spots: Array = []   # last built map's routes (dev screenshots)      # survival: zombies climb the routes (bots do not use them)
const STEP_MAX := 1.25                # jump reaches 1.6 m
func _auto_routes(want := 3, max_rise := 7.0) -> void:
	var sp := nav.get_world_3d().direct_space_state
	var x0 := -_hw + 1.0; var z0 := -_hh + 1.0
	var nx := int(_hw * 2.0) - 2; var nz := int(_hh * 2.0) - 2
	var H := PackedFloat32Array(); H.resize(nx * nz)
	for j in nz:
		for i in nx:
			var p := Vector3(x0 + i + 0.5, 40.0, z0 + j + 0.5)
			var h := sp.intersect_ray(PhysicsRayQueryParameters3D.create(p, p + Vector3(0, -60, 0)))
			H[j * nx + i] = h["position"].y if h else -99.0
	var at := func(i: int, j: int) -> float: return H[j * nx + i] if i >= 0 and j >= 0 and i < nx and j < nz else -99.0
	var spawns: Array = []
	for k in ["att_spawns", "def_spawns", "ffa_spawns"]:
		for q in plan.get(k, []): spawns.append(_wp(q))
	var cands: Array = []
	var dbg := {"rise": 0, "flatroof": 0, "ground": 0, "spawn": 0}
	for j in range(2, nz - 2):
		for i in range(2, nx - 2):
			var hg: float = at.call(i, j)
			if hg < -1.0 or hg > 1.5: continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var hr: float = at.call(i + d.x, j + d.y)
				var rise := hr - hg
				if rise < 2.8 or rise > max_rise: continue
				dbg["rise"] += 1
				if absf(at.call(i + d.x * 2, j + d.y * 2) - hr) > 0.25 or absf(at.call(i + d.x * 3, j + d.y * 3) - hr) > 0.25: continue
				dbg["flatroof"] += 1
				var tg := Vector2i(-d.y, d.x)
				var smax := STEP_MAX if max_rise < 8.0 else 1.38
				var steps := int(ceil(rise / smax)) - 1
				var gtol := 0.12 if max_rise < 8.0 else 0.3
				var ok := true
				for t in range(0, steps + 1):          # flat open ground beside the wall, roof all along
					for o in range(0, 3 if max_rise > 8.0 else 4):
						if absf(at.call(i + tg.x * t - d.x * o, j + tg.y * t - d.y * o) - hg) > gtol: ok = false
					if absf(at.call(i + tg.x * t + d.x, j + tg.y * t + d.y) - hr) > 0.25: ok = false
					if not ok: break
				if not ok: continue
				dbg["ground"] += 1
				var wp := Vector3(x0 + i + 0.5, hg, z0 + j + 0.5)
				var near := false
				for q in spawns:
					if Vector2(q.x - wp.x, q.z - wp.z).length() < 4.0: near = true
				if near: continue
				cands.append({"p": wp, "n": Vector3(d.x, 0, d.y), "t": Vector3(tg.x, 0, tg.y), "rise": rise, "steps": steps})
	cands.sort_custom(func(a, b) -> bool: return absf(a["rise"] - 4.2) < absf(b["rise"] - 4.2))
	var picked: Array = []
	for c in cands:
		var far := true
		for q in picked:
			if (q["p"] as Vector3).distance_to(c["p"]) < 18.0: far = false
		if far: picked.append(c)
		if picked.size() >= want: break
	if picked.size() < 2 and max_rise < 10.0:      # tall-city maps: allow scaffolds up to ~10 m
		_auto_routes(want, 10.6); return
	for c in picked: _crate_stairs(c, sp)
	route_spots = picked
	print("ROUTES ", plan.get("name", ""), " candidates ", cands.size(), " placed ", picked.size(), " max ", max_rise, " ", dbg)

func _crate_stairs(c: Dictionary, sp: PhysicsDirectSpaceState3D) -> void:
	var n: Vector3 = c["n"]; var t: Vector3 = c["t"]; var p: Vector3 = c["p"]
	# exact wall face: a horizontal ray from the ground cell toward the roof side
	var o := p + Vector3(0, 0.8, 0)
	var h := sp.intersect_ray(PhysicsRayQueryParameters3D.create(o - n * 0.6, o + n * 2.0))
	var face: Vector3 = (h["position"] as Vector3) if h else p + n * 0.5
	face.y = p.y
	var steps: int = c["steps"]; var rise: float = c["rise"]
	var step := rise / float(steps + 1)
	var yaw := rad_to_deg(atan2(-t.z, t.x))
	var wood := Color(0.55, 0.40, 0.24); var band := Color(0.30, 0.21, 0.12)
	if rise > 7.0:                                  # tall: grey scaffold towers instead of crate piles
		wood = Color(0.46, 0.48, 0.50); band = Color(0.86, 0.62, 0.12)
	var start := p - t * 0.0
	var tops: Array = []
	for k in steps:
		var hk := step * float(k + 1)
		var ctr := Vector3(face.x, p.y, face.z) - n * 0.6 + t * (0.55 + 1.12 * k)
		ctr = Vector3(ctr.x, p.y + hk * 0.5, ctr.z)
		box(ctr, Vector3(1.1, hk, 1.2) if absf(t.x) > 0.5 else Vector3(1.1, hk, 1.2), wood, yaw)
		var lv := 1.1
		while lv < hk - 0.2:                     # crate seams
			box(Vector3(ctr.x, p.y + lv, ctr.z), Vector3(1.14, 0.07, 1.24), band, yaw, false, false)
			lv += 1.1
		box(Vector3(ctr.x, p.y + hk - 0.02, ctr.z), Vector3(1.14, 0.06, 1.24), band, yaw, false, false)
		tops.append(Vector3(ctr.x, p.y + hk, ctr.z))
	if climb_links and tops.size() > 0:
		var foot := Vector3(face.x, p.y, face.z) - n * 1.9 + t * 0.55
		var top: Vector3 = (tops[tops.size() - 1] as Vector3) + n * 1.4
		top.y = p.y + rise
		var l := NavigationLink3D.new(); l.bidirectional = true
		l.start_position = foot; l.end_position = top; l.set_meta("via", tops)
		nav.add_child(l)

# windows / shop fronts: swap the flat interior pictures for a traced fake room (interior.gdshader)
static var _int_mats := {}
func _interiors(m: MeshInstance3D, shopfront: bool) -> void:
	var mesh := m.mesh
	if mesh == null: return
	for si in mesh.get_surface_count():
		var mt := mesh.surface_get_material(si)
		if mt == null: continue
		var n := mt.resource_name
		if n != "window" and n != "window_lit": continue
		var key := "%s|%s" % [n, shopfront]
		if not _int_mats.has(key):
			var sm := ShaderMaterial.new(); sm.shader = load("res://interior.gdshader")
			var T := "res://assets/maps/tex/%s.png"
			sm.set_shader_parameter("wall_tex", load(T % "T_RedBrick_BaseColor" if n == "window" else T % "T_Concrete_BaseColor"))
			sm.set_shader_parameter("floor_tex", load(T % "T_MarbleFloor_BaseColor"))
			sm.set_shader_parameter("back_tex", load(T % "T_Concrete_BaseColor"))
			sm.set_shader_parameter("lit_chance", 1.0 if n == "window_lit" else 0.3)
			sm.set_shader_parameter("shop", 1.0 if shopfront else 0.0)
			_int_mats[key] = sm
		m.set_surface_override_material(si, _int_mats[key])

# shop awnings are part of the visual Detail mesh: give just those surfaces a collider so you can stand
# on them (climb from a crate, jump across). Thickened into small slabs so nobody falls through.
func _awning_cols(m: MeshInstance3D) -> void:
	var mesh := m.mesh
	if mesh == null: return
	var xf := m.global_transform
	for si in mesh.get_surface_count():
		var mt := mesh.surface_get_material(si)
		if mt == null or not mt.resource_name.contains("awning"): continue
		var arr := mesh.surface_get_arrays(si)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx = arr[Mesh.ARRAY_INDEX]
		var tris := PackedVector3Array()
		if idx == null or (idx as PackedInt32Array).is_empty():
			for i in v.size(): tris.append(xf * v[i])
		else:
			for i in (idx as PackedInt32Array): tris.append(xf * v[i])
		var sb := StaticBody3D.new()
		for t in range(0, tris.size() - 2, 3):          # each triangle -> a thin prism
			var pts := PackedVector3Array()
			for k in 3:
				pts.append(tris[t + k]); pts.append(tris[t + k] - Vector3(0, 0.12, 0))
			var sh := ConvexPolygonShape3D.new(); sh.points = pts
			var col := CollisionShape3D.new(); col.shape = sh
			sb.add_child(col)
		nav.add_child(sb)

# 폐휴게소: what makes it read as a highway rest stop (pumps under the canopy, pole sign, shop sign, road paint)
func _reststop_props() -> void:
	var P := func(x: float, y: float, h := 0.0) -> Vector3: return Vector3(x - _hw, h, y - _hh)
	var red := Color(0.72, 0.16, 0.12); var white := Color(0.86, 0.85, 0.80); var grey := Color(0.36, 0.37, 0.38)
	# canopy: columns, striped fascia, pump islands
	for c in [[19.5, 11], [32.5, 11], [19.5, 15], [32.5, 15]]:
		cyl(P.call(c[0], c[1], 1.4), 0.2, 2.8, white)
	for e in [[26.0, 9.9, 16.4, 0.0], [26.0, 16.1, 16.4, 0.0], [17.9, 13.0, 6.4, 90.0]]:
		box(P.call(e[0], e[1], 2.98), Vector3(e[2], 0.22, 0.14), red, e[3], false, false)
		box(P.call(e[0], e[1], 3.17), Vector3(e[2], 0.16, 0.14), white, e[3], false, false)
	for x in [22.5, 26.0, 29.5]:
		box(P.call(x, 13.0, 0.1), Vector3(2.2, 0.2, 1.0), grey, 0.0, true)
		box(P.call(x, 13.0, 0.95), Vector3(0.7, 1.5, 0.5), white, 0.0, true)
		box(P.call(x, 13.0, 1.82), Vector3(0.74, 0.26, 0.54), red, 0.0, false, false)
		box(P.call(x, 12.74, 1.2), Vector3(0.36, 0.3, 0.02), Color(0.10, 0.14, 0.12), 0.0, false, false)   # display
	# tall pole sign by the highway
	cyl(P.call(15.0, 7.0, 4.0), 0.22, 8.0, grey)
	box(P.call(15.0, 7.0, 8.4), Vector3(3.4, 1.8, 0.3), red, 0.0, false, false)
	for side in [-1.0, 1.0]:
		var lb := Label3D.new(); lb.text = "휴게소\n24H"; lb.font_size = 96; lb.pixel_size = 0.01
		lb.modulate = Color(1, 0.96, 0.86); lb.outline_size = 0; lb.line_spacing = -18
		lb.position = P.call(15.0, 7.0 + 0.17 * side, 8.4); lb.rotation_degrees.y = 0.0 if side > 0 else 180.0
		nav.add_child(lb)
	# shop sign over the forecourt door
	box(P.call(32.0, 21.9, 3.75), Vector3(7.0, 0.8, 0.16), Color(0.14, 0.30, 0.22), 0.0, false, false)
	var sl := Label3D.new(); sl.text = "MINI MART"; sl.font_size = 64; sl.pixel_size = 0.01
	sl.modulate = Color(0.95, 0.92, 0.70); sl.outline_size = 0
	sl.position = P.call(32.0, 21.8, 3.75); sl.rotation_degrees.y = 180.0
	nav.add_child(sl)
	# road paint: highway centre dashes, parking stalls behind the shop
	for i in 15:
		box(P.call(4.0 + i * 4.0, 4.0, 0.012), Vector3(2.0, 0.02, 0.18), white, 0.0, false, false)
	for i in 7:
		box(P.call(26.0 + i * 3.0, 38.8, 0.012), Vector3(0.12, 0.02, 4.6), white, 0.0, false, false)
	_reststop_routes()
	# quarantine sandbags beside the gaps in the back wall
	for x in [7.0, 13.0, 27.0, 33.0, 39.0, 45.0]:
		box(P.call(x, 48.6, 0.32), Vector3(2.4, 0.64, 0.9), Color(0.50, 0.44, 0.32), 0.0, true)

# jump routes up to the roofs (jump = 1.6 m): each step is at most ~1.4 m. Zombies get a climb
# link (NavigationLink3D) from the foot of the route to its top, see Zombie._climb.
func _reststop_routes() -> void:
	var wood := Color(0.50, 0.36, 0.22); var green := Color(0.20, 0.36, 0.26); var concrete := Color(0.62, 0.60, 0.56)
	# 1) forecourt -> shop roof: dumpster (1.2) -> wall ledge (2.6) -> roof (4.0)
	box(Vector3(-6.5, 0.6, -7.6), Vector3(1.9, 1.2, 1.2), green)                       # dumpster
	box(Vector3(-6.5, 1.22, -7.6), Vector3(2.0, 0.06, 1.3), Color(0.12, 0.18, 0.14), 0.0, false, false)
	box(Vector3(-6.5, 2.5, -6.4), Vector3(3.0, 0.2, 0.8), concrete)                    # wide ledge
	for x in [-7.8, -5.2]:                                                              # brackets under it
		box(Vector3(x, 2.15, -6.25), Vector3(0.14, 0.5, 0.5), concrete, 0.0, false)
	# 2) shop roof <-> canopy roof: a plank bridge (3.2 -> 4.0)
	ramp(Vector3(-3.0, 3.22, -12.6), Vector3(-3.0, 4.02, -5.4), 1.3, wood)
	# 3) parking: crate (1.1) -> container (2.6)
	box(Vector3(-22.6, 0.55, 13.0), Vector3(1.1, 1.1, 1.1), wood)
	# zombie climb links (foot of the route -> top) and the bridge
	_link(Vector3(-6.5, 0.0, -9.0), Vector3(-6.5, 4.0, -5.0), [Vector3(-6.5, 1.2, -7.9), Vector3(-6.5, 2.6, -6.5)])
	_link(Vector3(-21.2, 0.0, 13.0), Vector3(-25.0, 2.6, 12.5), [Vector3(-22.6, 1.1, 13.0)])

func _link(a: Vector3, b: Vector3, via: Array = []) -> void:
	var l := NavigationLink3D.new()
	l.set_meta("via", via)            # the steps a zombie hops up on (dumpster, ledge, crate)
	l.bidirectional = true
	l.start_position = a; l.end_position = b
	nav.add_child(l)

func _palm(p: Vector3, k: int) -> void:
	var lean := Vector3(0.35 * sin(k), 0, 0.35 * cos(k))
	for i in 5:   # slightly bent trunk from short segments
		var t := float(i) / 5.0
		cyl(p + lean * t * t + Vector3(0, 0.45 + i * 0.9, 0), 0.17 - i * 0.015, 0.95, Color(0.52, 0.40, 0.26), false)
	var top := p + lean + Vector3(0, 4.7, 0)
	var leaf := StandardMaterial3D.new(); leaf.albedo_color = Color(0.32, 0.52, 0.22); leaf.roughness = 0.9
	leaf.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in 7:
		var a := TAU * float(i) / 7.0 + float(k)
		var mi := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(0.7, 2.4); mi.mesh = pm
		mi.material_override = leaf
		mi.position = top + Vector3(sin(a), -0.25, cos(a)) * 1.1
		mi.rotation = Vector3(0.45, a, 0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		nav.add_child(mi)
	solid(p.x - 0.2, p.z - 0.2, p.x + 0.2, p.z + 0.2, 4.0, p.y)

func _wedge(x0: float, y0: float, x1: float, y1: float, zl: float, zh: float, dir: String) -> void:
	var a := Vector3(x0 - _hw, 0, y0 - _hh); var b := Vector3(x1 - _hw, 0, y1 - _hh)
	var pts := PackedVector3Array()
	# corners: height depends on which edge is the top of the slope
	for c in [Vector3(a.x, 0, a.z), Vector3(b.x, 0, a.z), Vector3(b.x, 0, b.z), Vector3(a.x, 0, b.z)]:
		var top := false
		match dir:
			"e": top = is_equal_approx(c.x, b.x)
			"w": top = is_equal_approx(c.x, a.x)
			"s": top = is_equal_approx(c.z, b.z)
			"n": top = is_equal_approx(c.z, a.z)
		pts.append(Vector3(c.x, zl - 0.3, c.z))
		pts.append(Vector3(c.x, zh if top else zl, c.z))
	var sh := ConvexPolygonShape3D.new(); sh.points = pts
	var col := CollisionShape3D.new(); col.shape = sh
	var sb := StaticBody3D.new(); sb.add_child(col)
	nav.add_child(sb)

func _wp(p) -> Vector3:
	return Vector3(float(p[0]) - _hw, 0.0, float(p[1]) - _hh)

func _poly(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts: out.append(Vector2(float(p[0]) - _hw, float(p[1]) - _hh))
	return out

func _centroid(pts: Array) -> Array:
	var cx := 0.0; var cy := 0.0
	for p in pts: cx += float(p[0]); cy += float(p[1])
	return [cx / pts.size(), cy / pts.size()]

func _rect_of(pts: Array) -> Rect2:
	var poly := _poly(pts)
	var r := Rect2(poly[0], Vector2.ZERO)
	for v in poly: r = r.expand(v)
	return r
