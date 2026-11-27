extends SceneTree
## 시안: red outline on enemies, blue on allies, in a real team match (downtown)
func _initialize() -> void:
	_run()
func _shot(n: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("/tmp/ol_%s.png" % n)
func _run() -> void:
	await process_frame; await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 3; C.sel_map = "downtown"; C.view_fp = false
	change_scene_to_file("res://TeamDeathmatch.tscn")
	for i in 40: await process_frame
	var sc = current_scene; var pl = sc.player
	for b in sc.get_tree().get_nodes_in_group("bots"): b.process_mode = Node.PROCESS_MODE_DISABLED
	var bots: Array = sc.get_tree().get_nodes_in_group("bots")
	var allies := bots.filter(func(b): return b.team == pl.team)
	var enemies := bots.filter(func(b): return b.team != pl.team)
	# a clear stretch of street: the player looks down it
	var base := Vector3(-30, 0.05, -3.0)
	pl.global_position = base; pl.velocity = Vector3.ZERO
	pl.aim_yaw = -90.0; pl.aim_pitch = -4.0
	var fwd := Vector3(1, 0, 0)
	var spots := [[allies[0], Vector3(3.0, 0, 1.8)], [allies[1], Vector3(4.5, 0, -1.6)], [enemies[0], Vector3(9.0, 0, 0.6)], [enemies[1], Vector3(13.0, 0, -1.4)], [enemies[2], Vector3(17.0, 0, 1.2)]]
	for s in spots:
		var b: Node3D = s[0]; b.global_position = base + s[1]
		b.look_at(base + Vector3(0, 0, s[1].z * 0.2), Vector3.UP) if b.team != pl.team else b.look_at(base + s[1] + fwd * 5.0, Vector3.UP)
	for i in 20: await process_frame
	_shot("none")
	for b in bots:
		b._soldier.set_outline(Color(0.3, 0.6, 1.0) if b.team == pl.team else Color(1.0, 0.18, 0.15))
	for i in 10: await process_frame
	_shot("tp")
	C.view_fp = true
	for i in 30: await process_frame
	_shot("fp")
	C.view_fp = false
	quit()
