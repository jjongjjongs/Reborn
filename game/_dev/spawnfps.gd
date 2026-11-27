extends SceneTree
## frame cost at the attackers' start, looking up the valley (software GL here: compare before / after only)
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 6; C.sel_map = "temple"; C.view_fp = false
	change_scene_to_file("res://BombMode.tscn")
	for i in 60: await process_frame
	var sc = current_scene
	for p in sc.find_children("*", "PrepLoadout", true, false): p.queue_free()
	var t0 := Time.get_ticks_msec(); var n := 0
	while Time.get_ticks_msec() - t0 < 4000: await process_frame; n += 1
	print("FPS spawn %.1f  draw calls %d  objects %d" % [n / 4.0, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)])
	root.get_viewport().get_texture().get_image().save_png("/tmp/spawnfps.png")
	quit()
