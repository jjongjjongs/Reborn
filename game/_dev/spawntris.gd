extends SceneTree
## triangles / draw calls at both spawns of the 산사, bots moving, looking toward the middle
func _initialize() -> void: _run()
func _info() -> String:
	for i in 10: await process_frame
	return "tris %d calls %d" % [RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)]
func _run() -> void:
	await process_frame
	var S = load("res://soldier.gd")
	if OS.get_cmdline_user_args().has("nobake"): S.bake_bots = false
	var C = root.get_node("Controls"); C.reset(); C.team_size = 6; C.sel_map = "temple"; C.view_fp = false
	change_scene_to_file("res://BombMode.tscn")
	for i in 40: await process_frame
	var sc = current_scene; var pl = sc.player
	for p in sc.find_children("*", "PrepLoadout", true, false): p.queue_free()
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/temple.json"))
	var nb := 0; var nt := 0
	for b in sc.get_tree().get_nodes_in_group("bots"):
		for mi in b.find_children("*", "MeshInstance3D", true, false):
			if (mi as MeshInstance3D).skin != null and mi.mesh: nt += 1; if mi.mesh.get_surface_count() == 1: nb += 1
	print("BAKED bodies %d / %d  flag %s" % [nb, nt, S.bake_bots])
	var mid := Vector3(d["mid"][0], d["mid"][1], d["mid"][2])
	for side in ["att", "def"]:
		var p0 := Vector3(d[side][0][0], d[side][0][1], d[side][0][2])
		var bots: Array = sc.get_tree().get_nodes_in_group("bots")
		for i in bots.size(): bots[i].global_position = p0 + Vector3((i % 4) * 1.5 - 2, 0.3, (i / 4) * 1.5 - 2)
		pl.global_position = p0 + Vector3(0, 0.3, 0); pl.velocity = Vector3.ZERO
		var dv := mid - p0; pl.aim_yaw = rad_to_deg(atan2(-dv.x, -dv.z)); pl.aim_pitch = 0.0
		print("SPAWN %s  %s" % [side, await _info()])
		root.get_viewport().get_texture().get_image().save_png("/tmp/spawn_%s%s.png" % [side, "_nobake" if not S.bake_bots else ""])
	quit()
