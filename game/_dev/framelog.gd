extends SceneTree
## headless: wall time of every frame from load through the round start; prints the spikes
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 6; C.sel_map = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "temple"; C.view_fp = false
	change_scene_to_file("res://BombMode.tscn")
	await process_frame
	var last := Time.get_ticks_usec(); var worst := []; var sum := 0.0
	for i in 900:
		await process_frame
		var now := Time.get_ticks_usec(); var dt := (now - last) / 1000.0; last = now
		if i == 3:
			for p in current_scene.find_children("*", "PrepLoadout", true, false): p.queue_free()
		if i > 2: sum += dt; worst.append([dt, i])
	worst.sort_custom(func(a, b): return a[0] > b[0])
	print("FRAMES avg %.2f ms  MapIntel ready %s" % [sum / 897.0, load("res://map_intel.gd").ready])
	for w in worst.slice(0, 6): print("  spike %.1f ms at frame %d" % w)
	quit()
