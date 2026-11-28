extends SceneTree
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset()
	change_scene_to_file("res://Main.tscn")
	for i in 40: await process_frame
	var sc = current_scene; var pl = sc.player
	for w in sc.find_children("*", "WaveManager", true, false): w.process_mode = Node.PROCESS_MODE_DISABLED
	var mgr = sc.find_children("*", "WaveManager", true, false)[0]; mgr._wave = 0; mgr._spawn_one()
	var z = sc.get_tree().get_nodes_in_group("zombie")[0]; z.player = null; z._warmup = 99.0
	C.loadout[2] = "knife"; pl._equip(2, true)
	z.global_position = pl.global_position - pl.global_transform.basis.z * 1.3
	for i in 5: await process_frame
	var h0 = z.hp; pl._stab()
	for i in 5: await process_frame
	print("KNIFE zombie hp ", h0, " -> ", z.hp)
	quit()
