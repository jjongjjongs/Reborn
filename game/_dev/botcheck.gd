extends SceneTree
## bots in a real match: which bodies they wear, from the player's view
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame; await process_frame
	change_scene_to_file("res://TeamDeathmatch.tscn")
	for i in 240: await process_frame
	var sc = current_scene
	var bodies := {}
	for b in sc.get_tree().get_nodes_in_group("bots"):
		var s = b.get("_soldier")
		if s: bodies[s.body] = int(bodies.get(s.body, 0)) + 1
	print("BOTS ", bodies)
	var cam := root.get_viewport().get_camera_3d()
	var bots := sc.get_tree().get_nodes_in_group("bots")
	if bots.size() > 0 and cam:
		var b0: Node3D = bots[0]
		cam.global_position = b0.global_position + Vector3(2.2, 1.6, 2.2); cam.look_at(b0.global_position + Vector3(0, 1.0, 0))
	for i in 4: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/botcheck.png")
	print("FPS ", Engine.get_frames_per_second())
	quit()
