extends SceneTree
## walk the player out of the attackers' start with the real match running; log frame spikes + draw calls
var C; var pl
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	C = root.get_node("Controls"); C.reset(); C.team_size = 6; C.sel_map = "temple"; C.view_fp = false
	change_scene_to_file("res://BombMode.tscn")
	for i in 60: await process_frame
	var sc = current_scene; pl = sc.player
	for p in sc.find_children("*", "PrepLoadout", true, false): p.queue_free()
	var pts := [Vector2(2, 48), Vector2(-6, 42), Vector2(-6, 30), Vector2(12, 12), Vector2(14, 1.5), Vector2(30, 0)]
	print("start ", pl.global_position)
	var log := []
	var last := Time.get_ticks_usec()
	for k in range(1, pts.size()):
		var t: Vector2 = pts[k]; var n := 0
		while n < 900:
			await process_frame; n += 1
			var now := Time.get_ticks_usec(); var dt := (now - last) / 1000.0; last = now
			var p: Vector3 = pl.global_position
			var d := Vector2(t.x - p.x, t.y - p.z)
			log.append([dt, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), p, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0])
			if d.length() < 0.8: break
			pl.aim_yaw = rad_to_deg(atan2(-d.x, -d.y)); C.move = Vector2(0, -1)
	C.move = Vector2.ZERO
	var med: Array = log.map(func(e): return e[0]); med.sort()
	print("frames ", log.size(), " median ms ", med[med.size() / 2])
	var idx := range(log.size()); idx.sort_custom(func(a, b): return log[a][0] > log[b][0])
	for i in idx.slice(0, 15): print("SPIKE f%d %.0f ms  calls %d  proc %.1f phys %.1f at %s" % [i, log[i][0], log[i][1], log[i][3], log[i][4], log[i][2]])
	for i in range(0, log.size(), 40): print("  f%d %.0fms calls %d at %s" % [i, log[i][0], log[i][1], log[i][2]])
	quit()
