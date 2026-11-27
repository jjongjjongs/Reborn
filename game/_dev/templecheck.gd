extends SceneTree
## 산사 in a real 6v6 bomb match: load, bots move / fight / don't fall out, views from the player
func _initialize() -> void:
	_run()
func _shot(n: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("/tmp/tm_%s.png" % n)
func _run() -> void:
	await process_frame; await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 6; C.sel_map = "temple"; C.view_fp = false
	var t0 := Time.get_ticks_msec()
	change_scene_to_file("res://BombMode.tscn")
	for i in 30: await process_frame
	print("TM load %.1fs" % ((Time.get_ticks_msec() - t0) / 1000.0))
	var sc = current_scene; var pl = sc.player
	var nm = sc.find_children("*", "NavigationRegion3D", true, false)
	print("TM nav polys ", nm[0].navigation_mesh.get_polygon_count() if nm.size() > 0 and nm[0].navigation_mesh else -1)
	await _shot("spawn")
	var start := {}
	for b in sc.get_tree().get_nodes_in_group("bots"): start[b] = b.global_position
	for i in 1500: await physics_frame
	var moved := 0; var fell := 0; var far := 0.0
	for b in sc.get_tree().get_nodes_in_group("bots"):
		var d: float = b.global_position.distance_to(start.get(b, b.global_position))
		if d > 5.0: moved += 1
		far = maxf(far, d)
		if b.global_position.y < -5: fell += 1
	print("TM bots moved %d / %d, max %.0f m, fell %d, round %d, score %s" % [moved, start.size(), far, fell, sc.round_no, str(sc.score) if "score" in sc else "?"])
	await _shot("live")
	quit()
