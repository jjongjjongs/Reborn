extends SceneTree
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame; await process_frame
	var C = root.get_node("Controls"); C.team_size = 6; C.dm_count = 12
	change_scene_to_file("res://Menu.tscn")
	for i in 60: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/so_menu.png")
	var m = current_scene
	for k in [["팀 데스매치", "team", "res://TeamDeathmatch.tscn"], ["데스매치", "dm", "res://Deathmatch.tscn"], ["폭파미션", "bomb", "res://BombMode.tscn"]]:
		var s = SortieScreen.new().setup(k[0], "", k[2], k[1]); m.add_child(s)
		for i in 12: await process_frame
		root.get_viewport().get_texture().get_image().save_png("/tmp/so_%s.png" % k[1])
		s.queue_free()
	quit()
