extends SceneTree
## the new bomb planted on site B, seen in a real bomb match (3rd person + a close look)
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame; await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 3; C.sel_map = "dockside"; C.view_fp = false
	change_scene_to_file("res://BombMode.tscn")
	for i in 60: await process_frame
	var sc = current_scene; var pl = sc.player
	for b in sc.get_tree().get_nodes_in_group("bots"): b.process_mode = Node.PROCESS_MODE_DISABLED; b.visible = false
	var site: Vector3 = sc._site_center("B")
	sc.bomb_pos = site
	if sc.bomb_state != "planted":
		sc.bomb_state = "planted"; sc.bomb_t = sc.FUSE; sc._place_bomb(true)
	sc.state = "live"
	pl.global_position = site + Vector3(0, 0.5, 3.2); pl.velocity = Vector3.ZERO
	pl.aim_yaw = 0.0; pl.aim_pitch = -28.0
	for i in 90: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/bomb_game.png")
	C.view_fp = true; pl.global_position = site + Vector3(0, 0.5, 1.4); pl.aim_pitch = -40.0
	for i in 40: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/bomb_game_fp.png")
	C.view_fp = false
	# close look (a free camera, like a spectator walking up to it)
	var bp: Vector3 = sc._bomb_vis.global_position
	var cc := Camera3D.new(); sc.add_child(cc); cc.fov = 50.0
	cc.look_at_from_position(bp + Vector3(0.7, 0.75, 1.1), bp + Vector3(0, 0.15, 0)); cc.current = true
	for i in 30: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/bomb_game_close.png")
	quit()
