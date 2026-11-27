extends SceneTree
## walk the 산사 routes for real (player body, physics): does each one get where it should?
var C; var sc; var pl
func _initialize() -> void:
	_run()
func _shot(n: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("/tmp/tw_%s.png" % n)
func _ground(x: float, z: float) -> float:
	var h = pl.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, 40, z), Vector3(x, -10, z)))
	return (h["position"] as Vector3).y if h else 0.0
func _walk(name: String, pts: Array, want_y: float) -> void:
	var s: Vector2 = pts[0]
	pl.global_position = Vector3(s.x, _ground(s.x, s.y) + 0.3, s.y); pl.velocity = Vector3.ZERO
	for i in 10: await physics_frame
	var ok := true
	for k in range(1, pts.size()):
		var t: Vector2 = pts[k]; var n := 0
		while true:
			await physics_frame; n += 1
			var p: Vector3 = pl.global_position
			var d := Vector2(t.x - p.x, t.y - p.z)
			if d.length() < 0.7: break
			pl.aim_yaw = rad_to_deg(atan2(-d.x, -d.y)); C.move = Vector2(0, -1)
			if n > 600: ok = false; break
		if not ok: break
	C.move = Vector2.ZERO
	for i in 10: await physics_frame
	var p2: Vector3 = pl.global_position
	print("WALK %-10s %s  end (%.1f, %.2f, %.1f)  want y %.1f  %s" % [name, "ok " if ok else "STUCK", p2.x, p2.y, p2.z, want_y, "HEIGHT OK" if absf(p2.y - want_y) < 0.6 else "HEIGHT WRONG"])
func _run() -> void:
	await process_frame; await process_frame
	C = root.get_node("Controls"); C.reset(); C.team_size = 3; C.sel_map = "temple"; C.view_fp = false
	change_scene_to_file("res://BombMode.tscn")
	for i in 30: await process_frame
	sc = current_scene; pl = sc.player
	for b in sc.get_tree().get_nodes_in_group("bots"): b.process_mode = Node.PROCESS_MODE_DISABLED; b.visible = false
	for p in sc.find_children("*", "PrepLoadout", true, false): p.queue_free()
	sc.state = "live"; pl.frozen = false
	for i in 10: await process_frame
	for i in 420: await physics_frame        # prep ends and the round start moves everyone first
	await _walk("manseru", [Vector2(30, 3), Vector2(30, -14)], 7.2)
	await _walk("main", [Vector2(2, 48), Vector2(-6, 42), Vector2(-6, 30), Vector2(12, 12), Vector2(14, 1.5), Vector2(30, 0), Vector2(30, -14), Vector2(29, -18)], 7.2)
	_shot("a_yard")
	await _walk("cave", [Vector2(-19, 18), Vector2(9, -7.5)], 7.2)
	await _walk("valley", [Vector2(-36, 48), Vector2(-42, 30), Vector2(-44, 14), Vector2(-45, -2), Vector2(-39.5, -8.5)], 4.8)
	await _walk("to_B", [Vector2(-38.3, -10.2), Vector2(-35.6, -20.7), Vector2(-36.5, -23.5)], 4.8)
	_shot("b_bridge")
	await _walk("tun_cross", [Vector2(-9.8, -1.0), Vector2(0.8, 11.0)], 2.4)       # must NOT get over the tunnel (expect STUCK, y ~2.4..3)
	await _walk("tun_back", [Vector2(14.0, -11.5), Vector2(9.0, -7.0), Vector2(0.0, 1.0)], 5.6)   # into the top mouth: inside, not on the roof
	await _walk("meadow", [Vector2(-20, -2), Vector2(-14, 4), Vector2(0, -6), Vector2(-10, -12)], 2.4)
	await _walk("cave_out", [Vector2(-20.2, 19.0), Vector2(-18, 17), Vector2(9, -7), Vector2(13, -10.5), Vector2(20, -14)], 7.2)
	await _walk("ridge_out", [Vector2(57, 12), Vector2(55, -8), Vector2(54.5, -11), Vector2(50, -16)], 7.2)
	await _walk("north_st", [Vector2(-21, -33), Vector2(-18.5, -35.4), Vector2(-2.9, -45.2), Vector2(0, -47)], 7.2)
	await _walk("stair4", [Vector2(-33, 9), Vector2(-26, -6), Vector2(-27, -10)], 4.8)
	await _walk("stream1", [Vector2(-60, 15), Vector2(-51, 14)], 0.0)
	await _walk("stream1b", [Vector2(-51, 14), Vector2(-60, 15)], 0.0)
	await _walk("stream2", [Vector2(-58, 35), Vector2(-44, 36)], 0.0)
	await _walk("stream2b", [Vector2(-44, 36), Vector2(-58, 35)], 0.0)
	await _walk("gh_stair", [Vector2(-53.43, -27.87), Vector2(-53.26, -26.07), Vector2(-43.75, -23.70), Vector2(-42.66, -23.95), Vector2(-42.00, -26.57)], 9.56)
	pl.aim_yaw += 160.0; pl.aim_pitch = -12.0
	for i in 20: await process_frame
	_shot("deck")
	await _walk("ridge", [Vector2(22, 47), Vector2(50, 32), Vector2(57, 12), Vector2(55, -9)], 7.2)
	quit()
