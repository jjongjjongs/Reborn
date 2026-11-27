extends SceneTree
## the new bomb planted on site B, seen in a real bomb match (3rd person + a close look)
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame; await process_frame
	if not Profile.owns("bomb_gift"): Profile._d["owned"].append("bomb_gift")
	Profile.equip("bomb_gift")
	print("BOMB equipped ", Profile.equipped("bomb"))
	change_scene_to_file("res://Menu.tscn")
	for i in 40: await process_frame
	var shop = load("res://shop_screen.gd").new(); current_scene.add_child(shop)
	for i in 10: await process_frame
	shop._cat = "bomb"; shop._sel = "bomb_cyber"; shop._refresh()
	for i in 20: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/bomb_shop.png")
	shop.queue_free()
	var C = root.get_node("Controls"); C.reset(); C.team_size = 3; C.sel_map = "dockside"; C.view_fp = false
	change_scene_to_file("res://BombMode.tscn")
	for i in 60: await process_frame
	var sc = current_scene; var pl = sc.player
	for b in sc.get_tree().get_nodes_in_group("bots"): b.process_mode = Node.PROCESS_MODE_DISABLED; b.visible = false
	var site: Vector3 = sc._site_center("B")
	pl.global_position = site + Vector3(0, 0.5, 0)
	for i in 5: await physics_frame
	sc.carrier = pl; sc._plant("B")
	print("BOMB planted skin ", sc._bomb_skin, " at ", sc._bomb_vis.global_position)                                # the real plant call, by the player
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
