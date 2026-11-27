extends SceneTree
## screenshots of the 산사 fixes from the player's third-person camera (real BombMode)
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 3; C.sel_map = "temple"; C.view_fp = false
	change_scene_to_file("res://BombMode.tscn")
	for i in 60: await process_frame
	var sc = current_scene; var pl = sc.player
	for p in sc.find_children("*", "PrepLoadout", true, false): p.queue_free()
	for b in sc.get_tree().get_nodes_in_group("bots"): b.process_mode = Node.PROCESS_MODE_DISABLED; b.visible = false
	var shots := [["tunnel_exit", Vector3(2.0, 0, -0.75), -48.0, -6.0], ["tunnel_in", Vector3(-14.0, 0, 13.5), 132.0, 4.0], ["tunnel_side", Vector3(-15, 0, -4), -125.0, 2.0],
		["stream", Vector3(-50, 0, 28), 25.0, -6.0], ["meadow", Vector3(-46, 0, 2.5), -80.0, -4.0], ["gh_stair", Vector3(-47, 0, -18), 10.0, 4.0]]
	for s in shots:
		var p: Vector3 = s[1]
		var h = pl.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, 30, p.z), Vector3(p.x, -10, p.z)))
		if s[0] == "tunnel_exit" or s[0] == "tunnel_in": h = pl.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, p.y + 9.0 if s[0] == "tunnel_exit" else 5.0, p.z), Vector3(p.x, -10, p.z)))
		pl.global_position = (h["position"] as Vector3) + Vector3(0, 0.1, 0); pl.velocity = Vector3.ZERO
		pl.aim_yaw = s[2]; pl.aim_pitch = s[3]
		for i in 30: await process_frame
		root.get_viewport().get_texture().get_image().save_png("/tmp/tf_%s.png" % s[0])
		print("SHOT ", s[0], " at ", pl.global_position)
	quit()
