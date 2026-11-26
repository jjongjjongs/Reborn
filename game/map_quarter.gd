class_name MapQuarter
extends MapOldTown
## 구도심 (bomb defusal): a dense 110 x 100 m quarter built in Blender from
## assets/maps/oldquarter.json with a multi-level column mesher (rooms inside
## buildings, a tunnel under a street, a balcony over B, a catwalk over mid,
## raised courtyard and docks). Here: load the model, add collisions, smooth
## ramp colliders over the stepped stairs, spawns and sites.

const GLB := "res://assets/maps/oldquarter.glb"
const PLAN := "res://assets/maps/oldquarter.json"
var plan := {}
var _hw := 55.0
var _hh := 50.0

func build_quarter() -> Dictionary:
	plan = JSON.parse_string(FileAccess.get_file_as_string(PLAN))
	_hw = float(plan["W"]) * 0.5; _hh = float(plan["H"]) * 0.5
	_bx = _hw; _bz = _hh
	_env(Color(0.62, 0.72, 0.84), Color(0.80, 0.80, 0.82), 1.0, Vector3(-52, -35, 0), Color(1.0, 0.94, 0.84), 1.2, Color(0.70, 0.74, 0.80), 0.006)
	var model: Node3D = (load(GLB) as PackedScene).instantiate()
	nav.add_child(model)
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var nm := String(m.name)
		if nm == "Quarter":
			m.create_trimesh_collision()
		else:
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# stairs are drawn as steps but walked as smooth slopes (solid wedges)
	for r in plan["ramps"]:
		_wedge(float(r[0]), float(r[1]), float(r[2]), float(r[3]), float(r[4]), float(r[5]), String(r[6]))
	# keep everyone inside
	var w := _hw + 1.0; var h := _hh + 1.0
	solid(-w, -h, w, -_hh, 30); solid(-w, _hh, w, h, 30)
	solid(-w, -_hh, -_hw, _hh, 30); solid(_hw, -_hh, w, _hh, 30)
	_site_mark("A", _wp(_centroid(plan["siteA"])) + Vector3(0, 0.06, 0), Vector2(0, 0))
	_site_mark("B", _wp(_centroid(plan["siteB"])) + Vector3(0, 0.06, 0), Vector2(0, 0))
	_bake_colliders()
	var att: Array[Vector3] = []
	for p in plan["att_spawns"]: att.append(_wp(p) + Vector3(0, 1.0, 0))
	var def: Array[Vector3] = []
	for p in plan["def_spawns"]: def.append(_wp(p) + Vector3(0, 1.0, 0))
	return {"att": att, "def": def, "red": att, "blue": def, "ffa": att + def, "zombie": att + def,
		"player": att[0], "bounds": Rect2(-_hw, -_hh, _hw * 2.0, _hh * 2.0),
		"site_a": _rect_of(plan["siteA"]), "site_b": _rect_of(plan["siteB"]),
		"site_a_poly": _poly(plan["siteA"]), "site_b_poly": _poly(plan["siteB"]),
		"mid": _wp(plan["mid"]) + Vector3(0, 0.5, 0)}

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
