extends SceneTree
## triangles + draw calls in view as the player walks out of the attackers' start. arg: map
func _initialize() -> void: _run()
func _run() -> void:
	var m: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "temple"
	await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 6; C.sel_map = m; C.view_fp = false
	change_scene_to_file("res://BombMode.tscn")
	for i in 40: await process_frame
	var sc = current_scene; var pl = sc.player
	for p in sc.find_children("*", "PrepLoadout", true, false): p.queue_free()
	for b in sc.get_tree().get_nodes_in_group("bots"): b.set_physics_process(false)
	var st: Vector3 = pl.global_position
	var yaw: float = deg_to_rad(pl.aim_yaw)
	var d := Vector2(-sin(yaw), -cos(yaw))
	var mx := 0
	for k in 8:
		pl.global_position = st + Vector3(d.x, 0, d.y) * k * 3.0 + Vector3(0, 0.3, 0); pl.velocity = Vector3.ZERO
		pl.aim_yaw = rad_to_deg(atan2(-d.x, -d.y)); pl.aim_pitch = 0.0
		for i in 8: await process_frame
		var tri := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		mx = max(mx, tri)
		print("PRIM %s step %d  tris %d  calls %d  objs %d" % [m, k, tri, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)])
	quit()
