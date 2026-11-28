extends SceneTree
## headless: physics cost after the round starts with one group of temple colliders switched off
func _initialize() -> void: _run()
func _run() -> void:
	var v: String = OS.get_cmdline_user_args()[0]
	await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 6; C.sel_map = "temple"; C.view_fp = false
	change_scene_to_file("res://BombMode.tscn")
	for i in 30: await process_frame
	var sc = current_scene
	for p in sc.find_children("*", "PrepLoadout", true, false): p.queue_free()
	var off := 0
	for sb in sc.find_children("*", "StaticBody3D", true, false):
		var pn := String(sb.get_parent().name)
		var hit := false
		if v == "buildings": hit = pn.begins_with("Col_Buildings")
		elif v == "stone": hit = pn.begins_with("Col_Stone") or pn.begins_with("Col_Rocks") or pn.begins_with("Col_Walls")
		elif v == "boxes": hit = not pn.begins_with("Col_")
		if hit: (sb as StaticBody3D).collision_layer = 0; off += 1
	var ph := 0.0; var pr := 0.0
	for i in 60 * 4: await process_frame          # prep
	for i in 60 * 6:
		await process_frame
		ph += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0; pr += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	print("PHYS %-10s off %d  phys %.2f  proc %.2f" % [v, off, ph / 360, pr / 360])
	quit()
