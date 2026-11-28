extends SceneTree
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 1; C.sel_map = "temple"
	change_scene_to_file("res://BombMode.tscn")
	for i in 30: await process_frame
	var sc = current_scene
	var S = load("res://soldier.gd"); var P = load("res://profile.gd")
	S.bake_bots = true
	var s = S.new(); s.body = "scout"; s.lod = true
	var sk: Array = P.skins_of("scout"); s.skin = P.skin_mats(sk[1 % sk.size()])
	sc.add_child(s); s.setup(Color(0.3, 0.5, 1.0))
	for mi in s.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null: continue
		if m.mesh.get_surface_count() == 1 and m.skin != null:
			var a0 := m.mesh.surface_get_arrays(0); var vc0 = a0[Mesh.ARRAY_COLOR]
			print("BAKED n ", (a0[0] as PackedVector3Array).size(), " fmt ", m.mesh.surface_get_format(0), " colors ", vc0.size() if vc0 != null else -1)
			if vc0 != null:
				for k in [0, 1276, 1276 + 1000, 1276 + 3232 + 100, 4508 + 300]: print("  v", k, " ", vc0[k])
			print("  override ", m.material_override)
			continue
		if m.mesh.get_surface_count() < 2: continue
		for si in m.mesh.get_surface_count():
			var mat := m.get_active_material(si) as StandardMaterial3D
			var a := m.mesh.surface_get_arrays(si); var vc = a[Mesh.ARRAY_COLOR]
			var avg := Color(0,0,0)
			if vc != null:
				for q in vc: avg += q
				avg /= float(vc.size())
			print("%2d %-14s alb %s vcsrgb %s vc %s n %d" % [si, mat.resource_name if mat else "-", mat.albedo_color if mat else "", mat.vertex_color_is_srgb if mat else "", avg if vc != null else "none", (a[0] as PackedVector3Array).size()])
	quit()
