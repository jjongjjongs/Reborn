extends SceneTree
func _initialize() -> void:
	_run()
func _run() -> void:
	var C = root.get_node("Controls")
	change_scene_to_file("res://Menu.tscn")
	for i in 20: await process_frame
	var s = load("res://sortie.gd").new().setup("팀 데스매치", "3 vs 3 · 봇", "res://TeamDeathmatch.tscn", "team")
	current_scene.add_child(s)
	for i in 20: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/so_team.png")
	s.queue_free()
	var s2 = load("res://sortie.gd").new().setup("웨이브 서바이벌", "PvE · 좀비 방어", "res://Main.tscn", "survival")
	current_scene.add_child(s2)
	C.bot_diff = "elite"; C.wave_mode = 0; s2._refresh()
	for i in 20: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/so_surv.png")
	quit()
