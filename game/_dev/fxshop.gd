extends SceneTree
## shop tabs + previews, then the real path: equip -> training range kills + tracers, TDM 6v6 kills
func _initialize() -> void:
	_run()
func _shot(n: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("/tmp/fs_%s.png" % n)
func _run() -> void:
	await process_frame; await process_frame
	for id in ["kill_coin", "tr_plasma"]:
		if not Profile.owns(id): Profile._d["owned"].append(id)
	change_scene_to_file("res://Menu.tscn")
	for i in 40: await process_frame
	var m = current_scene
	var shop = load("res://shop_screen.gd").new(); m.add_child(shop)
	for i in 10: await process_frame
	shop._cat = "killfx"; shop._sel = "kill_coin"; shop._refresh()
	for i in 10: await process_frame
	shop._fx_t = 0.05
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 350: await process_frame
	_shot("shop_kill")
	shop._cat = "tracer"; shop._sel = "tr_flame"; shop._refresh(); shop._fx_t = 0.3
	t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 420: await process_frame
	_shot("shop_tracer")
	shop.queue_free()
	Profile.equip("kill_coin"); Profile.equip("tr_plasma")
	print("EQUIPPED ", Profile.equipped("killfx"), " ", Profile.equipped("tracer"))
	var C = root.get_node("Controls"); C.reset(); C.view_fp = true
	change_scene_to_file("res://Training.tscn")
	for i in 60: await process_frame
	var sc = current_scene; var pl = sc.player
	pl.global_position = Vector3(-3, 0.5, 1.5); pl.face(Vector3(-3, 1.4, -20))
	for i in 20: await process_frame
	C.fire_held = true
	for i in 6: await process_frame
	_shot("range_fire")
	C.fire_held = false
	# a dummy killed by the player in the range
	var d = sc.find_children("*", "TrainingDummy", true, false)
	var tg = sc.find_children("*", "PopupTarget", true, false)
	print("targets ", d.size(), " popups ", tg.size())
	if tg.size() > 0:
		var t = tg[3] if tg.size() > 3 else tg[0]
		t.hit(999, false)
		t0 = Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 350: await process_frame
		_shot("range_kill")
	C.view_fp = false; C.save_settings()
	quit()
