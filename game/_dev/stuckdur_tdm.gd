extends SceneTree
## longest time any bot stays within 1.5 m while it wants to go somewhere (not fighting, not busy, objective > 2.5 m)
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame; await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 6; C.sel_map = OS.get_cmdline_user_args()[0]; C.bot_diff = "reg"
	change_scene_to_file("res://TeamDeathmatch.tscn")
	for i in 30: await process_frame
	var sc = current_scene
	var anchor := {}; var since := {}; var worst := 0.0; var where := []
	for step in 90:                                   # 90 x 0.5 s
		for i in 30: await physics_frame
		var now := step * 0.5
		for b in sc.get_tree().get_nodes_in_group("bots"):
			var p: Vector3 = b.global_position
			var wants: bool = b.alive and true and not b._engaged() and not b.get("busy")
			if not wants or not anchor.has(b) or (anchor[b] as Vector3).distance_to(p) > 1.5:
				anchor[b] = p; since[b] = now; continue
			var d: float = now - float(since[b])
			if d > worst: worst = d; where = [p, b.bot_name]
	print("WORST stuck %.1f s at %s" % [worst, where])
	quit()
