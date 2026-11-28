extends SceneTree
## real path: wave mode from the sortie setting -> Main.tscn; zombies are killed off fast to run the waves
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); var CS = load("res://controls.gd")
	for m in [5, 10, 15]: print("REWARD mode %d full clear %d  died after 3 cleared (30 kills) %d" % [m, CS.wave_reward(m, m, 999, true), CS.wave_reward(m, 3, 30, false)])
	for w in [14, 15, 16, 20, 25]: print("REWARD endless cleared %d (999 kills) %d" % [w, CS.wave_reward(0, w, 999, false)])
	var mode: int = int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size() > 0 else 10
	C.reset(); C.wave_mode = mode
	change_scene_to_file("res://Main.tscn")
	for i in 30: await process_frame
	var pl = current_scene.find_children("*", "Player", true, false)
	var t0 := Time.get_ticks_msec(); var maxalive := 0
	while not C.game_over and Time.get_ticks_msec() - t0 < 240000:
		await process_frame
		var zs := current_scene.get_tree().get_nodes_in_group("zombie")
		maxalive = maxi(maxalive, zs.size())
		C.hp = 100
		for z in zs:
			if not z.is_queued_for_deletion() and randf() < 0.05: z.hit(99999, false)
		if mode == 0 and C.wave >= 17: break
	print("RUN mode %d  wave %d / total %d  over %s win %s  max alive %d  reward %d" % [mode, C.wave, C.wave_total, C.game_over, C.victory, maxalive, load("res://missions.gd").last_reward])
	quit()
