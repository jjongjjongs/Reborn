extends SceneTree
func _initialize() -> void: _run()
func _tris(m: Mesh) -> int:
	var t := 0
	for si in m.get_surface_count():
		var a := m.surface_get_arrays(si)
		t += ((a[Mesh.ARRAY_INDEX] as PackedInt32Array).size() if a[Mesh.ARRAY_INDEX] != null else (a[0] as PackedVector3Array).size()) / 3
	return t
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 2; C.sel_map = "temple"
	change_scene_to_file("res://BombMode.tscn")
	for i in 40: await process_frame
	var b = current_scene.get_tree().get_nodes_in_group("bots")[0]
	for mi in b.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null or not m.is_visible_in_tree(): continue
		print("PART %-22s tris %6d surf %d overlay %s override %s shadow %d parent %s" % [m.name, _tris(m.mesh), m.mesh.get_surface_count(), m.material_overlay != null, m.material_override != null, m.cast_shadow, m.get_parent().name])
	quit()
