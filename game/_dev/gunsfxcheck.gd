extends SceneTree
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset()
	change_scene_to_file("res://Training.tscn")
	for i in 40: await process_frame
	var pl = current_scene.player; var S = root.get_node("Sfx")
	var played := []
	for id in ["m4", "ak", "mp5", "shotgun", "sniper", "rpk", "pistol", "revolver"]:
		var slot := int(Weapons.get_w(id)["slot"]); C.loadout[slot] = id; pl._ammo[id] = 3; pl._equip(slot, true)
		for i in 3: await process_frame
		pl._shoot(Weapons.get_w(id))
		var p0 = S._pool[(S._pi - 1 + S._pool.size()) % S._pool.size()]
		var shot_ok: bool = S._pool.any(func(p): return p.stream == S.stream("shot_" + id))
		for i in 40: await process_frame
		pl._ammo[id] = 0; pl._start_reload()
		var p1 = S._pool[(S._pi - 1 + S._pool.size()) % S._pool.size()]
		played.append("%s shot %s reload %s" % [id, shot_ok, p1.stream == S.stream("rel_" + id)])
		for i in 10: await process_frame
	for p in played: print("SFX ", p)
	# a bot firing uses its gun's sound
	quit()
