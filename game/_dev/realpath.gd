extends SceneTree
## no test overrides: what the player actually gets
func _initialize() -> void:
	_run()
func _shot(n: String) -> void:
	for i in 12: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/real_%s.png" % n)
func _run() -> void:
	await process_frame; await process_frame
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: Profile.equip(a[0])            # the shop's own equip call
	print("TEST_BODY '", Soldier.test_body, "' equipped ", Profile.equipped("body"))
	change_scene_to_file("res://Menu.tscn")
	for i in 60: await process_frame
	await _shot("menu")
	var m = current_scene
	var lo = LoadoutScreen.new(); m.add_child(lo)
	await _shot("loadout")
	lo.queue_free()
	var C = root.get_node("Controls")
	C.reset(); C.view_fp = false; C.loadout[0] = "m4"
	change_scene_to_file("res://Training.tscn")
	for i in 60: await process_frame
	var sc = current_scene; var pl = sc.player
	print("PLAYER body ", pl._soldier.body)
	pl.global_position = Vector3(-3, 0.5, 4); pl.face(Vector3(-3, 1.4, -20))
	await _shot("tp")
	C.view_fp = true
	for i in 30: await process_frame
	await _shot("fp")
	for slot in [1, 2]:                        # sidearm and knife from the real loadout
		pl._equip(slot, true)
		for i in 45: await process_frame
		await _shot("fp_%d" % slot)
		C.view_fp = false
		for i in 30: await process_frame
		await _shot("tp_%d" % slot)
		C.view_fp = true
	C.view_fp = false; C.save_settings()
	quit()
