extends SceneTree
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 3; C.sel_map = "temple"
	change_scene_to_file("res://TeamDeathmatch.tscn")
	for i in 40: await process_frame
	var pl = current_scene.player
	C.loadout[0] = "sniper"; pl._ammo["sniper"] = 5; pl._equip(0, true)
	for i in 10: await process_frame
	C.scoped = true
	for i in 30: await process_frame
	print("BEFORE scoped ", C.scoped, " scope_k %.2f" % pl.scope_k)
	pl.hit(999, false, null)
	for i in 30: await process_frame
	print("AFTER DEATH alive ", pl.alive, " scoped ", C.scoped, " scope_k %.2f" % pl.scope_k)
	quit()
