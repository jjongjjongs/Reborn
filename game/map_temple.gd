class_name MapTemple
extends MapPlan
## 산사 (mountain temple) bomb map, modelled in Blender (tools/blender/build_temple.py + export_temple.py):
## a curved valley of stone terraces, A = 대웅전 yard (top), B = 경회루 on the pond (north-west).
## Here: load the model, collisions for every Col_* mesh, trunk colliders for the trees inside the
## valley, an invisible wall round the valley outline, spawns / sites from temple.json, navmesh.

func build_temple() -> Dictionary:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/temple.json"))
	_hw = 70.0; _hh = 60.0; _bx = _hw; _bz = _hh
	_env(Color(0.62, 0.74, 0.88), Color(0.78, 0.80, 0.80), 1.0, Vector3(-50, -40, 0), Color(1.0, 0.95, 0.86), 1.25, Color(0.72, 0.80, 0.84), 0.004)
	var model: Node3D = (load("res://assets/maps/temple.gltf") as PackedScene).instantiate()
	nav.add_child(model)
	_batch_trees(model)
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var nm := String(m.name)
		if nm.begins_with("Col_"):
			m.create_trimesh_collision()
		else:
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if nm.begins_with("Vis_Steps") or nm.begins_with("Vis_Water") else m.cast_shadow
		if nm.begins_with("Col_Terrain") or nm.begins_with("Col_Walls"):      # baked colour lives in the vertex colours
			for si in m.mesh.get_surface_count():
				var sm := m.mesh.surface_get_material(si) as StandardMaterial3D
				if sm: var dm := sm.duplicate() as StandardMaterial3D; dm.vertex_color_use_as_albedo = true; dm.albedo_color = Color.WHITE; m.set_surface_override_material(si, dm)
		if nm.begins_with("Vis_Water"):
			var wm := StandardMaterial3D.new(); wm.albedo_color = Color(0.22, 0.46, 0.56, 0.78); wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			wm.roughness = 0.05; wm.metallic = 0.35; wm.metallic_specular = 0.9
			wm.cull_mode = BaseMaterial3D.CULL_DISABLED                 # the surface was exported facing down: show both sides
			m.material_override = wm
	# tree trunks inside the valley block bullets and players
	for t in d["trunks"]:
		var sb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var cy := CylinderShape3D.new(); cy.radius = 0.35; cy.height = 8.0
		cs.shape = cy; sb.add_child(cs); sb.position = Vector3(t[0], float(t[1]) + 4.0, t[2]); nav.add_child(sb)
	# keep everyone in the valley: invisible walls along the outline, a little outside it
	var ol: Array = d["outline"]
	for i in ol.size() - 1:
		var a := Vector2(ol[i][0], ol[i][1]); var b := Vector2(ol[i + 1][0], ol[i + 1][1])
		var L := a.distance_to(b)
		if L < 0.05: continue
		var c := (a + b) * 0.5; var dir := (b - a) / L
		var sb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bx := BoxShape3D.new(); bx.size = Vector3(L + 0.6, 40.0, 1.0)
		cs.shape = bx; sb.add_child(cs); sb.position = Vector3(c.x, 15.0, c.y); sb.rotation.y = -atan2(dir.y, dir.x); nav.add_child(sb)
	Radar.overview = load("res://assets/maps/temple_overview.png")
	var ac: Array = d["site_a_c"]; var bc: Array = d["site_b_c"]
	_site_mark("A", Vector3(ac[0], float(ac[1]) + 0.06, ac[2]), Vector2(14, 10))
	_site_mark("B", Vector3(bc[0], float(bc[1]) + 0.06, bc[2]), Vector2(16, 12))
	_bake_colliders()
	if not MapBuilder.backdrop:
		MapIntel.analyze(nav.get_world_3d(), Rect2(-_hw, -_hh, _hw * 2.0, _hh * 2.0))
	var att: Array[Vector3] = []; for p in d["att"]: att.append(Vector3(p[0], p[1], p[2]))
	var def: Array[Vector3] = []; for p in d["def"]: def.append(Vector3(p[0], p[1], p[2]))
	var pa := PackedVector2Array(); for p in d["site_a"]: pa.append(Vector2(p[0], p[1]))
	var pb := PackedVector2Array(); for p in d["site_b"]: pb.append(Vector2(p[0], p[1]))
	var mid: Array = d["mid"]
	return {"att": att, "def": def, "red": att, "blue": def, "ffa": att + def, "zombie": att + def, "player": att[0],
		"bounds": Rect2(-_hw, -_hh, _hw * 2.0, _hh * 2.0), "mid": Vector3(mid[0], mid[1], mid[2]),
		"site_a": _rect_poly(pa), "site_b": _rect_poly(pb), "site_a_poly": pa, "site_b_poly": pb}

func _rect_poly(p: PackedVector2Array) -> Rect2:
	var r := Rect2(p[0], Vector2.ZERO)
	for q in p: r = r.expand(q)
	return r

## ~530 trees were one draw call per tree and material (over 1200 calls looking up the valley from the
## attackers' start): put every tree of the same mesh into one MultiMesh (a handful of calls)
func _batch_trees(model: Node3D) -> void:
	var by_mesh := {}
	for mi in model.find_children("Vis_Tree*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if not by_mesh.has(m.mesh): by_mesh[m.mesh] = []
		by_mesh[m.mesh].append(m.global_transform if m.is_inside_tree() else (model.transform * m.transform))
		m.queue_free()
	for mesh in by_mesh:
		var xs: Array = by_mesh[mesh]
		var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.mesh = mesh; mm.instance_count = xs.size()
		for i in xs.size(): mm.set_instance_transform(i, xs[i])
		var mmi := MultiMeshInstance3D.new(); mmi.multimesh = mm
		nav.add_child(mmi)
