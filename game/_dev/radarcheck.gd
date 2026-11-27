extends SceneTree
## team radar: allies always, enemies only after contact with our side (seen / shot at / hit), fading
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame; await process_frame
	change_scene_to_file("res://TeamDeathmatch.tscn")
	for i in 30: await process_frame
	var sc = current_scene
	var rad: Radar = sc.find_children("*", "Radar", true, false)[0]
	for k in 6:
		for i in 120: await process_frame
		var allies := 0; var enemies := 0
		for n in sc.get_tree().get_nodes_in_group("combatant"):
			if n == rad.player or not n.alive: continue
			if rad._is_enemy(n): enemies += 1
			else: allies += 1
		print("RADAR t=%d allies=%d (all drawn) enemies=%d shown=%d" % [k, allies, enemies, rad._spotted.size()])
		root.get_viewport().get_texture().get_image().save_png("/tmp/radar_%d.png" % k)
	quit()
