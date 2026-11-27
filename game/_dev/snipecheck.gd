extends SceneTree
## 스나전: everyone on sniper rifles, a real 6v6 run, then views from the power spots
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame; await process_frame
	var C = root.get_node("Controls")
	C.reset(); C.view_fp = false; C.team_size = 6; C.sel_map = "snipe"
	var keep = C.loadout[0]
	change_scene_to_file("res://TeamDeathmatch.tscn")
	for i in 30: await process_frame
	var sc = current_scene; var pl = sc.player
	var w := {}
	for b in sc.get_tree().get_nodes_in_group("bots"): w[b.loadout[0]] = int(w.get(b.loadout[0], 0)) + 1
	print("SNIPE player primary %s, bots %s" % [C.loadout[0], w])
	for i in 1500: await physics_frame
	var fell := 0
	for b in sc.get_tree().get_nodes_in_group("bots"):
		if b.global_position.y < -6: fell += 1
	print("SNIPE score %s fell %d" % [str(sc._score), fell])
	if Radar.overview: Radar.overview.get_image().save_png("/tmp/snipe_overview.png")
	# views (third person camera follows the player): balcony, ridge, mid dune, tunnel
	for b in sc.get_tree().get_nodes_in_group("bots"): b.process_mode = Node.PROCESS_MODE_DISABLED; b.visible = false
	var spots := [["balcony", Vector3(-35.0, 4.4, -6.0)], ["ridge", Vector3(-24.0, 3.6, -31.0)], ["dune", Vector3(-22.0, 2.3, -12.0)],
		["tower", Vector3(-15.0, 4.4, 17.0)], ["tunnel", Vector3(-24.0, -2.0, 24.0)], ["room", Vector3(-5.0, 1.0, 1.5)]]
	for s in spots:
		var p: Vector3 = s[1]
		pl.global_position = p; pl.velocity = Vector3.ZERO
		var tgt := Vector3(30.0, 0.0, 0.0) if s[0] != "tunnel" else Vector3(30.0, 0.0, 24.0)
		pl.aim_yaw = rad_to_deg(atan2(-(tgt.x - p.x), -(tgt.z - p.z))); pl.aim_pitch = -3.0
		for i in 25: await process_frame
		root.get_viewport().get_texture().get_image().save_png("/tmp/snipe_%s.png" % s[0])
	change_scene_to_file("res://Menu.tscn")
	for i in 10: await process_frame
	print("SNIPE restored primary %s (was %s), lock '%s'" % [C.loadout[0], keep, C.lock_primary])
	quit()
