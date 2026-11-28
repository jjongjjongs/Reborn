extends SceneTree
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 1; C.sel_map = OS.get_cmdline_user_args()[0]
	change_scene_to_file("res://BombMode.tscn")
	for i in 30: await process_frame
	for r in current_scene.find_children("*", "NavigationRegion3D", true, false):
		var nm: NavigationMesh = r.navigation_mesh
		print("NAV ", OS.get_cmdline_user_args()[0], " polys ", nm.get_polygon_count(), " verts ", nm.vertices.size())
	var b = current_scene.get_tree().get_nodes_in_group("bots")
	var map = current_scene.get_world_3d().navigation_map
	var t := Time.get_ticks_usec()
	for i in 20: NavigationServer3D.map_get_path(map, Vector3(0, 1, 50), Vector3(30, 8, -20), true)
	print("PATH ms ", (Time.get_ticks_usec() - t) / 20000.0)
	quit()
