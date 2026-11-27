extends SceneTree
## autopilot through the static stages of 점프맵: steer to each block, jump near the edge.
## Prints whether every checkpoint / the finish is reached without falling.
var C
func _initialize() -> void:
	_run()
func _go(pl, sc, tgt: Vector3, half: float, max_frames := 400) -> bool:
	for i in max_frames:
		await physics_frame
		var p: Vector3 = pl.global_position
		var d := Vector2(tgt.x - p.x, tgt.z - p.z)
		if d.length() < 0.35 and pl.is_on_floor() and absf(p.y - tgt.y) < 0.4: C.move = Vector2.ZERO; return true
		pl.aim_yaw = rad_to_deg(atan2(-d.x, -d.y))
		C.move = Vector2(0, -1) if d.length() > 0.3 else Vector2.ZERO
		# like a player: jump at the edge (no floor just ahead), or right before a step up
		if pl.is_on_floor() and d.length() > 0.5:
			var fw := Vector3(d.x, 0, d.y).normalized()
			var ahead: Vector3 = p + fw * 0.5
			var q := PhysicsRayQueryParameters3D.create(ahead + Vector3(0, 0.3, 0), ahead + Vector3(0, -0.8, 0))
			q.exclude = [pl.get_rid()]
			var no_floor: bool = pl.get_world_3d().direct_space_state.intersect_ray(q).is_empty()
			if no_floor or (tgt.y - p.y > 0.3 and d.length() < half + 1.2): C.request_jump()
		if sc._falls > 0: return false
	return false
func _run() -> void:
	await process_frame; await process_frame
	C = root.get_node("Controls"); C.reset(); C.view_fp = false
	Profile._load(); Profile._d.erase("best_jump1")          # as on a fresh install: first clear
	print("COINS before ", Missions.coins())
	change_scene_to_file("res://JumpMap.tscn")
	for i in 60: await process_frame
	var sc = current_scene; var pl = sc.player
	var legs := [
		["S1", [[Vector3(0, 0, -7), 1.5], [Vector3(0, 0.5, -11), 1.5], [Vector3(2.5, 1.0, -15), 1.3], [Vector3(0.2, 1.5, -19.5), 1.5], [Vector3(0, 1.5, -25), 2.0]]],
		["S2", [[Vector3(0, 1.5, -28), 0.3], [Vector3(0, 1.5, -33.35), 0.3], [Vector3(5.5, 1.5, -33.35), 0.3], [Vector3(5.5, 1.5, -39.4), 0.3], [Vector3(5.5, 2.0, -42), 0.65], [Vector3(3.5, 2.6, -44.6), 0.65], [Vector3(1.5, 3.2, -47.2), 0.65], [Vector3(-0.5, 3.8, -49.8), 0.65], [Vector3(-0.5, 3.8, -54.5), 2.0]]],
	]
	for leg in legs:
		var ok := true
		for wp in leg[1]:
			if not await _go(pl, sc, wp[0], wp[1]): ok = false; print("RUN %s FAILED at %s (pos %s, falls %d)" % [leg[0], wp[0], pl.global_position, sc._falls]); break
		if ok: print("RUN %s ok -> checkpoint %d, time %.1f" % [leg[0], sc._cp, sc._t])
	# stage 4 + 5 from checkpoint 3
	pl.global_position = Vector3(0, 8.6, -80.2); pl.velocity = Vector3.ZERO; sc._cp = 3; sc._falls = 0
	for i in 20: await physics_frame
	var s4 := [[Vector3(1.2, 7.8, -84.6), 1.1], [Vector3(-1.2, 7.8, -88.4), 1.1], [Vector3(1.0, 7.8, -92.2), 1.1], [Vector3(-0.8, 7.8, -96.0), 1.1], [Vector3(0.6, 7.8, -99.8), 1.1], [Vector3(0, 7.8, -104.4), 2.0]]
	var ok4 := true
	for wp in s4:
		if not await _go(pl, sc, wp[0], wp[1], 200): ok4 = false; print("RUN S4 FAILED at %s (pos %s)" % [wp[0], pl.global_position]); break
	if ok4: print("RUN S4 ok -> checkpoint %d" % sc._cp)
	var ok5 := true
	for i in 11:
		var a := deg_to_rad(-45.0 * i)
		var t := Vector3(sin(a) * 4.6, 8.4 + 0.62 * i, -113.0 + cos(a) * 4.6)
		if not await _go(pl, sc, t, 0.9, 300): ok5 = false; print("RUN S5 FAILED at pad %d %s (pos %s)" % [i, t, pl.global_position]); break
	if ok5:
		await _go(pl, sc, Vector3(0, 15.6, -113.0), 2.2, 300)
		for i in 10: await physics_frame
		print("RUN S5 ok -> finished %s, pos %s" % [sc._done, pl.global_position])
		print("COINS after ", Missions.coins(), " (reward ", Missions.last_reward, ")")
		for i in 20: await process_frame
		root.get_viewport().get_texture().get_image().save_png("/tmp/jump_finish.png")
	quit()
