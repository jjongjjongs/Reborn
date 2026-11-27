extends SceneTree
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 6; C.sel_map = "temple"
	change_scene_to_file("res://BombMode.tscn")
	for i in 60: await process_frame
	var sc = current_scene
	for b in sc.get_tree().get_nodes_in_group("bots").slice(0, 2):
		var n := 0; var s := 0; var sh := 0; var names := []
		for mi in b.find_children("*", "MeshInstance3D", true, false):
			var g := mi as MeshInstance3D
			if not g.is_visible_in_tree() or g.mesh == null: continue
			n += 1; s += g.mesh.get_surface_count(); if g.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF: sh += g.mesh.get_surface_count()
			names.append("%s:%d" % [g.name, g.mesh.get_surface_count()])
		print(b.name, " lod ", b.get("lod"), " meshes ", n, " surfaces ", s, " shadow surfaces ", sh, " ", names)
	quit()
