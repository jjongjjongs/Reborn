class_name MapOldTown2
extends MapOldTown
## 구시가지 (bomb defusal, v2): modelled in Blender (through the blender-mcp addon)
## from assets/maps/oldtown2.json — streets are carved first and everything else
## is filled with buildings, so the outline follows the streets, not a rectangle.
## 200 x 150 m, west hill +4 m (site A), canal with 4 bridges + an underpass.
## Here: load the model, add collisions, props for cover, spawns and sites.

const GLB := "res://assets/maps/oldtown2.glb"
const PLAN := "res://assets/maps/oldtown2.json"
var plan := {}

func build_oldtown2() -> Dictionary:
	plan = JSON.parse_string(FileAccess.get_file_as_string(PLAN))
	_bx = 100.0; _bz = 75.0
	_env(Color(0.62, 0.72, 0.84), Color(0.80, 0.80, 0.82), 1.0, Vector3(-50, -35, 0), Color(1.0, 0.94, 0.84), 1.2, Color(0.70, 0.74, 0.80), 0.005)
	var model: Node3D = (load(GLB) as PackedScene).instantiate()
	nav.add_child(model)
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var nm := String(m.name)
		if nm.begins_with("col_"):
			m.visible = false
		if nm in ["Floor", "Buildings", "Rails", "Roofs"] or nm.begins_with("col_"):
			m.create_trimesh_collision()
		if nm in ["Windows", "Cornices", "Zones", "Water"]:
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# keep bullets/players inside: a wall around the whole map
	solid(-101, -76, 101, -75, 30); solid(-101, 75, 101, 76, 30)
	solid(-101, -75, -100, 75, 30); solid(100, -75, 101, 75, 30)
	_props()
	_site_mark("A", _wp(_centroid(plan["siteA"])) + Vector3(0, 0.06, 0), Vector2(0, 0))
	_site_mark("B", _wp(_centroid(plan["siteB"])) + Vector3(0, 0.06, 0), Vector2(0, 0))
	_bake_colliders()
	var att: Array[Vector3] = []
	for p in plan["att_spawns"]: att.append(_wp(p) + Vector3(0, 1.0, 0))
	var def: Array[Vector3] = []
	for p in plan["def_spawns"]: def.append(_wp(p) + Vector3(0, 1.0, 0))
	return {"att": att, "def": def, "red": att, "blue": def, "ffa": att + def, "zombie": att + def,
		"player": att[0], "bounds": Rect2(-100, -75, 200, 150),
		"site_a": _rect_of(plan["siteA"]), "site_b": _rect_of(plan["siteB"]),
		"site_a_poly": _poly(plan["siteA"]), "site_b_poly": _poly(plan["siteB"]),
		"mid": _wp(plan["mid"]) + Vector3(0, 0.5, 0)}

# ---------------------------------------------------------------- plan helpers (map metres -> world)
func _seg_d(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
	return p.distance_to(a + ab * t)

func elev_at(x: float, y: float) -> float:
	var hill: Array = plan["hill"]
	var p := Vector2(x, y)
	var pts := PackedVector2Array()
	for q in hill: pts.append(Vector2(q[0], q[1]))
	var d := 1e9
	for i in pts.size():
		d = minf(d, _seg_d(p, pts[i], pts[(i + 1) % pts.size()]))
	var s := d if Geometry2D.is_point_in_polygon(p, pts) else -d
	var t := clampf((s + 4.0) / 8.0, 0.0, 1.0)
	return float(plan["hill_h"]) * (t * t * (3.0 - 2.0 * t))

func _wp(p) -> Vector3:
	return Vector3(float(p[0]) - 100.0, elev_at(float(p[0]), float(p[1])), float(p[1]) - 75.0)

func _centroid(pts: Array) -> Array:
	var cx := 0.0; var cy := 0.0
	for p in pts: cx += float(p[0]); cy += float(p[1])
	return [cx / pts.size(), cy / pts.size()]

func _poly(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts: out.append(Vector2(float(p[0]) - 100.0, float(p[1]) - 75.0))
	return out

func _rect_of(pts: Array) -> Rect2:
	var poly := _poly(pts)
	var r := Rect2(poly[0], Vector2.ZERO)
	for v in poly: r = r.expand(v)
	return r

# ---------------------------------------------------------------- cover & dressing
func _props() -> void:
	# concrete barriers at the chokepoints and in the open squares
	for b in [[100, 107, 0], [95, 112, 35], [95, 82, 90], [107, 71, 0], [41, 69, 15], [64, 60, 60], [31, 110, 70],
			[146, 90, 30], [161, 117, 60], [150, 128, 20], [100, 31, 0], [121, 27, 15], [57, 96, 80], [20, 114, 0]]:
		jersey(_wp(b), b[2])
	# crates inside both sites and along the lanes
	for c in [[45, 50], [55, 56], [51, 45.5], [160, 58], [169, 66], [158, 70], [126, 118], [88, 132], [111, 132], [72, 26], [137, 30]]:
		crate(_wp(c), 1.1, randf_range(-12, 12))
	crate(_wp([45, 50]) + Vector3(0, 1.1, 0), 0.8, 30.0)
	crate(_wp([169, 66]) + Vector3(0, 1.1, 0), 0.8, 20.0)
	# parked / abandoned cars
	for c in [["car-taxi", [36, 118], 60.0], ["car-normalcar1", [128, 135], 85.0], ["car-suv", [20, 119], 10.0],
			["car-cop", [70, 13], 95.0], ["car-sportscar", [93, 73], 20.0], ["car-normalcar2", [170, 86], 170.0]]:
		piece(c[0], _wp(c[1]), c[2])
		_car_col(_wp(c[1]), c[2])
	# street lights along the main streets
	for l in [[90, 134], [62, 129], [40, 117], [29, 92], [28, 76], [112, 134], [140, 131], [162, 116], [170, 92], [100, 118], [104, 60], [96, 24], [128, 26]]:
		var p := _wp(l)
		piece("streetlight-double", p, 0.0, 4.2)
		solid(p.x - 0.2, p.z - 0.2, p.x + 0.2, p.z + 0.2, 4.0, p.y)
	# fountain in the small square, a monument in the bell-tower square
	var f := _wp([22, 116]); cyl(f + Vector3(0, 0.4, 0), 2.0, 0.8, Color(0.66, 0.64, 0.60)); cyl(f + Vector3(0, 1.3, 0), 0.4, 1.2, Color(0.60, 0.58, 0.54))
	var m := _wp([102, 76]); box(m + Vector3(0, 1.0, 0), Vector3(2.4, 2.0, 2.4), Color(0.72, 0.70, 0.66)); box(m + Vector3(0, 3.0, 0), Vector3(1.0, 2.0, 1.0), Color(0.55, 0.52, 0.48))
	# planters on the hill square (A)
	for p in [[33, 44], [66, 40]]:
		_tree(_wp(p))
