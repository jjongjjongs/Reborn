extends SceneTree
## 점프맵: menu entry, sortie screen, each stage, a real bounce-pad jump and a fall -> checkpoint
func _initialize() -> void:
	_run()
func _shot(n: String) -> void:
	for i in 10: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/jump_%s.png" % n)
func _run() -> void:
	await process_frame; await process_frame
	change_scene_to_file("res://Menu.tscn")
	for i in 60: await process_frame
	await _shot("menu")
	var m = current_scene
	m.add_child(SortieScreen.new().setup("미니게임", "점프맵 · 기록 도전", "res://JumpMap.tscn", "minigame"))
	await _shot("sortie")
	var C = root.get_node("Controls")
	C.reset(); C.view_fp = false
	change_scene_to_file("res://JumpMap.tscn")
	for i in 60: await process_frame
	var sc = current_scene; var pl = sc.player
	await _shot("start")
	var spots := [[Vector3(0, 1.6, -21), -10.0], [Vector3(-0.5, 3.9, -52.5), 0.0], [Vector3(0, 7.9, -78.5), 0.0], [Vector3(0, 7.9, -102.5), 0.0], [Vector3(3.5, 9.6, -108.6), 30.0]]
	for i in spots.size():
		pl.global_position = spots[i][0]; pl.velocity = Vector3.ZERO
		pl.aim_yaw = spots[i][1]; pl.aim_pitch = -12.0
		await _shot("stage%d" % (i + 1))
	pl.global_position = Vector3(0, 1.0, 1.0); pl.aim_yaw = 0.0; pl.aim_pitch = -8.0
	C.view_fp = true
	await _shot("fp")
	C.view_fp = false
	# real bounce: stand on the pad, hold forward
	pl.global_position = Vector3(0, 4.3, -70.8); pl.velocity = Vector3.ZERO; pl.aim_yaw = 0.0
	for i in 20: await physics_frame
	C.move = Vector2(0, -1)
	var top := -99.0
	for i in 150:
		await physics_frame
		top = maxf(top, pl.global_position.y)
	C.move = Vector2.ZERO
	print("BOUNCE peak %.2f landed at %s on_floor %s (ledge top 7.8)" % [top, pl.global_position, pl.is_on_floor()])
	# fall off -> respawn at the last checkpoint
	pl.global_position = Vector3(20, 2, -60)
	for i in 120: await physics_frame
	print("FALL respawned at %s cp %d falls %d" % [pl.global_position, sc._cp, sc._falls])
	quit()
