extends SceneTree
## first-person review sheet: every weapon, HUD hidden, same spot
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame; await process_frame
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: Soldier.test_body = a[0]
	var C = root.get_node("Controls")
	C.reset(); C.view_fp = true
	change_scene_to_file("res://Training.tscn")
	for i in 50: await process_frame
	var sc = current_scene; var pl = sc.player
	for l in sc.find_children("*", "CanvasLayer", true, false): l.visible = false
	pl.global_position = Vector3(-3, 0.5, 1.5); pl.face(Vector3(-3, 1.4, -20))
	var ids := ["m4", "ak", "mp5", "shotgun", "sniper", "rpk", "pistol", "revolver", "knife"]
	var k := 0
	for id in ids:
		var slot := 2 if id == "knife" else (1 if id in ["pistol", "revolver"] else 0)
		C.loadout[slot] = id
		pl._ammo[id] = pl._mag_of(id)
		pl._equip(slot, true)
		for i in 45: await process_frame
		root.get_viewport().get_texture().get_image().save_png("/tmp/fpall_%d.png" % k); k += 1
	C.view_fp = false; C.loadout = ["m4", "pistol", "knife"]; C.save_settings()
	quit()
