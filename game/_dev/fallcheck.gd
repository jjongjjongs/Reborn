extends SceneTree
## where do bots drop out of the map? log the last grounded spot before y < -4
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame; await process_frame
	var C = root.get_node("Controls")
	C.reset(); C.team_size = 6; C.dm_count = 12; C.sel_map = "downtown"
	change_scene_to_file("res://Deathmatch.tscn")
	for i in 30: await process_frame
	var sc = current_scene
	var last := {}; var spawned := {}; var reported := {}
	for f in 1200:
		await physics_frame
		for b in sc.get_tree().get_nodes_in_group("bots"):
			var p: Vector3 = b.global_position
			if not spawned.has(b): spawned[b] = p
			if b.is_on_floor(): last[b] = [p, f]
			if p.y < -4.5 and not reported.has(b):
				reported[b] = true
				print("DROP %s frame %d spawn %s last_floor %s now %s" % [b.bot_name, f, spawned[b], last.get(b, ["-"])[0], p])
	quit()
