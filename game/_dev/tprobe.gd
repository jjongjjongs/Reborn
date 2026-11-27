extends SceneTree
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 3; C.sel_map = "temple"
	change_scene_to_file("res://BombMode.tscn")
	for i in 30: await process_frame
	var sp = current_scene.get_world_3d().direct_space_state
	for z in [14.0, 13.0, 12.0, 11.0, 10.0, 8.0, 6.0, 4.0, 2.0]:
		var line := ""
		for x in [9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0]:
			var h = sp.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, 30, z), Vector3(x, -5, z)))
			var y: float = (h["position"] as Vector3).y if h else -99.0
			var nm: String = String(h["collider"].get_parent().name if h else "-").substr(0, 8)
			line += "%6.2f %-8s " % [y, nm]
		print("Z %5.1f  %s" % [z, line])
	quit()
