extends SceneTree
func _initialize() -> void:
	_run()
func _shot(n: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("/tmp/fs2_%s.png" % n)
func _wait(ms: int) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < ms: await process_frame
func _run() -> void:
	await process_frame; await process_frame
	for id in ["wfx_spark", "cfx_flame"]:
		if not Profile.owns(id): Profile._d["owned"].append(id)
	Profile.equip("wfx_spark"); Profile.equip("cfx_flame")
	change_scene_to_file("res://Menu.tscn")
	await _wait(1500)
	_shot("menu")
	var m = current_scene
	var shop = load("res://shop_screen.gd").new(); m.add_child(shop)
	for i in 10: await process_frame
	shop._cat = "wfx"; shop._sel = "wfx_ember"; shop._refresh()
	await _wait(1200); _shot("shop_wfx")
	shop._cat = "cfx"; shop._sel = "cfx_petal"; shop._refresh()
	await _wait(1200); _shot("shop_cfx")
	shop.queue_free()
	var C = root.get_node("Controls"); C.reset(); C.view_fp = false
	change_scene_to_file("res://Training.tscn")
	for i in 60: await process_frame
	var sc = current_scene; var pl = sc.player
	pl.global_position = Vector3(-3, 0.5, 6); pl.face(Vector3(-3, 1.4, -20))
	await _wait(500)
	C.move = Vector2(0, -1)
	await _wait(900)
	_shot("run3p")
	C.move = Vector2.ZERO
	C.view_fp = true
	await _wait(1200)
	_shot("fp")
	C.view_fp = false; C.save_settings()
	quit()
