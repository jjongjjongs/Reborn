extends SceneTree
## headless: script cost over a live 6v6 round + node count (does something pile up?)
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 6; C.sel_map = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "temple"; C.view_fp = false
	change_scene_to_file("res://BombMode.tscn")
	for i in 30: await process_frame
	var sc = current_scene
	for p in sc.find_children("*", "PrepLoadout", true, false): p.queue_free()
	for blk in 30:
		var pr := 0.0; var ph := 0.0
		for i in 60:
			await process_frame
			pr += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0; ph += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		print("T%3ds proc %.2f phys %.2f nodes %d objs %d" % [blk, pr / 60, ph / 60, Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_COUNT)])
	quit()
