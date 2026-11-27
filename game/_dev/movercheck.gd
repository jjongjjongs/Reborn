extends SceneTree
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame; await process_frame
	root.get_node("Controls").reset()
	change_scene_to_file("res://JumpMap.tscn")
	for i in 60: await process_frame
	var sc = current_scene; var pl = sc.player
	var m: Node3D = sc._movers[0][0]
	pl.global_position = m.global_position + Vector3(0, 1.0, 0); pl.velocity = Vector3.ZERO
	var xs := []
	for k in 8:
		for i in 30: await physics_frame
		xs.append("%.1f/%.1f(%.1f)" % [pl.global_position.x, m.global_position.x, pl.global_position.y])
	print("MOVER ride player/platform x (player y): ", xs, " falls ", sc._falls)
	quit()
