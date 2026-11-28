class_name SwingTrail
extends MeshInstance3D
## a fading ribbon behind a swung blade: feed it two points a frame (edge inner / outer) while the
## swing is live; each slice fades out over `life` s
var life := 0.16
var col := Color(1.0, 0.97, 0.9, 0.55)
var _pts: Array = []            # [inner, outer, t]
var _im := ImmediateMesh.new()

func _init() -> void:
	top_level = true; mesh = _im
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED; m.vertex_color_use_as_albedo = true
	material_override = m

func add(inner: Vector3, outer: Vector3) -> void:
	_pts.append([inner, outer, 0.0])

func _process(dt: float) -> void:
	for p in _pts: p[2] += dt
	while not _pts.is_empty() and float(_pts[0][2]) > life: _pts.pop_front()
	global_transform = Transform3D.IDENTITY
	_im.clear_surfaces()
	if _pts.size() < 2: return
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for p in _pts:
		var a := clampf(1.0 - float(p[2]) / life, 0.0, 1.0)
		var c := Color(col.r, col.g, col.b, col.a * a * a)
		_im.surface_set_color(Color(c.r, c.g, c.b, 0.0)); _im.surface_add_vertex(p[0])
		_im.surface_set_color(c); _im.surface_add_vertex(p[1])
	_im.surface_end()
