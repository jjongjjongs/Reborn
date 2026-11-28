extends SceneTree
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 6; C.sel_map = OS.get_cmdline_user_args()[0]; C.view_fp = false
	change_scene_to_file("res://BombMode.tscn")
	for i in 30: await process_frame
	var sc = current_scene
	for p in sc.find_children("*", "PrepLoadout", true, false): p.queue_free()
	var B = load("res://bot.gd")
	for i in 240: await process_frame
	B.PROF.clear()
	var cnt := [0]
	for b in sc.get_tree().get_nodes_in_group("bots"): b._agent.path_changed.connect(func(): cnt[0] += 1)
	var map = sc.get_world_3d().navigation_map; var it0: int = NavigationServer3D.map_get_iteration_id(map)
	for i in 360: await process_frame
	print("PATHCHANGES per frame %.2f  map iterations %d" % [cnt[0] / 360.0, NavigationServer3D.map_get_iteration_id(map) - it0])
	var t := Time.get_ticks_usec(); var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/temple.json"))
	var ks: Array = B.PROF.keys(); ks.sort_custom(func(a, b): return B.PROF[a] > B.PROF[b])
	for k in ks: print("PROF %-10s %.2f ms/frame" % [k, B.PROF[k] / 1000.0 / 360.0])
	quit()
