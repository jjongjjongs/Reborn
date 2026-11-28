extends SceneTree
## real path: earn coins -> buy the zombie weapons in the shop -> wave survival sortie -> loadout picks them ->
## launch -> the player really holds them (3rd + 1st person) -> a PvP sortie gets the normal loadout back
func _initialize() -> void: _run()
func _shot(n: String) -> void:
	for i in 6: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/zr_%s.png" % n)
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); var M = load("res://missions.gd"); var P = load("res://profile.gd")
	M.earn(3000)
	for id in ["zw_axe", "zw_dbarrel", "zw_flamer"]: print("BUY ", id, " ", P.buy(id) or P.owns(id))
	change_scene_to_file("res://Menu.tscn")
	for i in 30: await process_frame
	var sh = load("res://shop_screen.gd").new(); current_scene.add_child(sh)
	for i in 10: await process_frame
	sh._cat = "zweapon"; sh._sel = "zw_flamer"; sh._refresh()
	await _shot("shop")
	sh.queue_free()
	var so = load("res://sortie.gd").new().setup("웨이브 서바이벌", "PvE · 좀비 방어", "res://Main.tscn", "survival")
	current_scene.add_child(so)
	for i in 10: await process_frame
	print("ZMODE ", C.zmode, " loadout ", C.loadout)
	var lo = load("res://loadout.gd").new(); so.add_child(lo)
	for i in 10: await process_frame
	lo._tab = 0; lo._pick = "flamer"; lo._refresh(); lo._equip_btn.pressed.emit()
	await _shot("loadout_primary")
	lo._tab = 2; lo._pick = "axe"; lo._refresh(); lo._equip_btn.pressed.emit()
	await _shot("loadout_melee")
	lo.queue_free()
	for i in 5: await process_frame
	so._refresh()
	await _shot("sortie")
	print("PICKED ", C.loadout)
	C.view_fp = false
	so._launch()
	for i in 60: await process_frame
	var pl = current_scene.player
	print("IN GAME loadout ", C.loadout, " holding ", C.weapon_id, " body weapon ", pl._soldier.weapon)
	for w in current_scene.find_children("*", "WaveManager", true, false): w.process_mode = Node.PROCESS_MODE_DISABLED
	C.prep_left = -1.0
	for u in current_scene.find_children("*", "UpgradeShop", true, false): u.visible = false; u.process_mode = Node.PROCESS_MODE_DISABLED
	var t := 0
	var wm = load("res://wave_manager.gd")
	for k in 3:                                  # a few zombies without running the wave timer
		var mgr = current_scene.find_children("*", "WaveManager", true, false)[0]
		mgr._wave = 0; mgr._spawn_one()
	var fwd: Vector3 = -pl.global_transform.basis.z; fwd.y = 0; fwd = fwd.normalized()
	for z in current_scene.get_tree().get_nodes_in_group("zombie"):
		z.player = null; z._warmup = 99.0; z.hp = 99999.0
		z.global_position = pl.global_position + fwd * randf_range(3.5, 6.0) + fwd.cross(Vector3.UP) * randf_range(-1.0, 1.0)
	for k in 14:
		pl._shoot(Weapons.get_w("flamer")); await process_frame
	await _shot("game_tp_flamer")
	C.view_fp = true
	for i in 20: await process_frame
	for k in 14:
		pl._shoot(Weapons.get_w("flamer")); await process_frame
	await _shot("game_fp_flamer")
	pl._equip(2, true)
	for i in 20: await process_frame
	print("MELEE holding ", C.weapon_id)
	await _shot("game_fp_axe")
	C.view_fp = false
	for i in 20: await process_frame
	await _shot("game_tp_axe")
	# back to the menu and into a PvP sortie: normal loadout again, zombie weapons not offered
	paused = false
	change_scene_to_file("res://Menu.tscn")
	for i in 30: await process_frame
	var so2 = load("res://sortie.gd").new().setup("팀 데스매치", "봇", "res://TeamDeathmatch.tscn", "team")
	current_scene.add_child(so2)
	for i in 10: await process_frame
	print("PVP zmode ", C.zmode, " loadout ", C.loadout, " primaries offered ", Weapons.ids_for_slot(0, C.zmode))
	quit()
