extends SceneTree
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	change_scene_to_file("res://Main.tscn")
	for i in 900: await process_frame
	var z := current_scene.get_tree().get_nodes_in_group("zombie").size()
	print("ZCHECK zombies ", z, " phys ms ", Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	quit()
