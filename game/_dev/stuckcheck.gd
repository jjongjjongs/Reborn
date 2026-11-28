extends SceneTree
## bots that stop moving for 8 s while alive (not planting / defusing / holding a site) = stuck spots
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame; await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 6; C.sel_map = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "temple"; C.bot_diff = "reg"
	change_scene_to_file("res://BombMode.tscn")
	for i in 30: await process_frame
	var sc = current_scene
	var hist := {}; var stuck := {}
	for step in 45:                                   # ~45 x 1 s of game time
		for i in 60: await physics_frame
		for b in sc.get_tree().get_nodes_in_group("bots"):
			if not b.alive or sc.state != "live": hist.erase(b); continue
			var p: Vector3 = b.global_position
			var h: Array = hist.get(b, [])
			h.append(p); if h.size() > 8: h.pop_front()
			hist[b] = h
			var wants: bool = b.objective != Vector3.INF and Vector2(b.objective.x - p.x, b.objective.z - p.z).length() > 2.5 and not b._engaged()
			if h.size() == 8 and (h[0] as Vector3).distance_to(p) < 1.5 and not b.get("busy") and wants:
				var key := "%d,%d" % [int(p.x / 3), int(p.z / 3)]
				if not stuck.has(key): stuck[key] = [p, b.bot_name, sc.round_no, b.objective, "vel %.2f fin %s next %.2f tries %d tgt %s eng %s frozen %s" % [Vector2(b.velocity.x, b.velocity.z).length(), b._agent.is_navigation_finished(), b._agent.get_next_path_position().distance_to(p), b._tries, b._target != null, b._engaged(), b.frozen]]
	print("STUCK spots %d" % stuck.size())
	for k in stuck: print("  ", stuck[k])
	print("ROUNDS ", sc.round_no, " score ", sc.score)
	quit()
