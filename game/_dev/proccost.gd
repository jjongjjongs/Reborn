extends SceneTree
## script cost per frame during the first seconds of a round (everyone leaving spawn). arg: variant
func _initialize() -> void: _run()
func _run() -> void:
	var v: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "all"
	await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 6; C.sel_map = "temple"; C.view_fp = false
	change_scene_to_file("res://BombMode.tscn")
	for i in 30: await process_frame
	var sc = current_scene
	for p in sc.find_children("*", "PrepLoadout", true, false): p.queue_free()
	if v == "nosoldier":
		for s in sc.find_children("*", "Soldier", true, false): s.set_process(false)
	if v == "notags":
		for s in sc.find_children("*", "TeamTags", true, false): s.set_process(false)
	if v == "noradar":
		for s in sc.find_children("*", "Radar", true, false): s.set_process(false)
	if v == "nobotlogic":
		for b in sc.get_tree().get_nodes_in_group("bots"): b.set_physics_process(false)
	var pr := 0.0; var ph := 0.0; var n := 0; var worst := 0.0
	for i in 240:
		await process_frame
		var p: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		pr += p; ph += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0; n += 1; worst = maxf(worst, p)
	print("COST %-11s process %.1f ms  physics %.1f ms  worst process %.1f" % [v, pr / n, ph / n, worst])
	quit()
