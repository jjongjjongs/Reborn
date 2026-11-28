extends SceneTree
## what the triangles at the attackers' start are made of
func _initialize() -> void: _run()
func _tri() -> String:
	for i in 6: await process_frame
	return "tris %d calls %d" % [RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)]
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 6; C.sel_map = "temple"; C.view_fp = false
	change_scene_to_file("res://BombMode.tscn")
	for i in 40: await process_frame
	var sc = current_scene
	for p in sc.find_children("*", "PrepLoadout", true, false): p.queue_free()
	for b in sc.get_tree().get_nodes_in_group("bots"): b.set_physics_process(false)
	print("SPLIT all            ", await _tri())
	var hulls := sc.find_children("OutlineHull", "MeshInstance3D", true, false)
	for h in hulls: h.visible = false
	print("SPLIT no hulls       ", await _tri(), "  (", hulls.size(), " hulls)")
	for b in sc.get_tree().get_nodes_in_group("bots"): b.visible = false
	print("SPLIT no bots        ", await _tri())
	for l in sc.find_children("*", "DirectionalLight3D", true, false): l.shadow_enabled = false
	print("SPLIT no shadows     ", await _tri())
	for n in sc.find_children("Col_Buildings*", "MeshInstance3D", true, false): n.visible = false
	print("SPLIT no buildings   ", await _tri())
	for n in sc.find_children("Col_Terrain*", "MeshInstance3D", true, false): n.visible = false
	print("SPLIT no terrain     ", await _tri())
	for n in sc.find_children("*", "MultiMeshInstance3D", true, false): n.visible = false
	print("SPLIT no trees       ", await _tri())
	sc.player.visible = false
	print("SPLIT no player      ", await _tri())
	for l in sc.find_children("*", "DirectionalLight3D", true, false): print("sun shadow max dist ", l.directional_shadow_max_distance, " mode ", l.directional_shadow_mode)
	quit()
