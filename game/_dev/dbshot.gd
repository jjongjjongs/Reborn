extends SceneTree
## 시안: double barrel on the real player (zombie mode): 2 shots at close zombies + break-action reload; 3rd person side + 1st person
var C; var pl; var sc; var game_cam: Camera3D
func _initialize() -> void: _run()
func _put_zombies() -> void:
	var zs: Array = sc.get_tree().get_nodes_in_group("zombie")
	var fwd: Vector3 = -pl.global_transform.basis.z; fwd.y = 0; fwd = fwd.normalized()
	var right := fwd.cross(Vector3.UP)
	for i in zs.size():
		var z = zs[i]
		if i < 2:
			z.player = null; z._warmup = 99.0; z.hp = 99999.0; z._stagger = 0.0
			z.global_position = pl.global_position + fwd * (3.2 + i * 1.2) + right * (0.3 - i * 0.9)
			z.look_at(pl.global_position, Vector3.UP); z.velocity = Vector3.ZERO
		else: z.queue_free()
func _shots(tag: String) -> void:
	_put_zombies()
	pl._ammo["dbarrel"] = 2; C.spread_deg = 5.0
	for i in 20: await process_frame
	Engine.time_scale = 0.15
	var k := 0
	for shot in 2:
		var zs: Array = sc.get_tree().get_nodes_in_group("zombie"); var p0: Array = zs.map(func(z): return z.global_position)
		var shot_cam: Camera3D = root.get_viewport().get_camera_3d()
		if tag == "side": game_cam.current = true
		pl._fire_cd = 0.0; pl._shoot(Weapons.get_w("dbarrel"))
		shot_cam.current = true
		sc.get_tree().create_timer(0.5).timeout.connect(func() -> void:
			for i in zs.size(): if is_instance_valid(zs[i]): print("KNOCK zombie %d moved %.2f m" % [i, (zs[i].global_position - p0[i]).length()]))
		var t0 := Time.get_ticks_msec()
		for dt in [0.0, 0.05, 0.14, 0.3]:
			while (Time.get_ticks_msec() - t0) * 0.15 / 1000.0 < dt: await process_frame
			root.get_viewport().get_texture().get_image().save_png("/tmp/db_%s_%d.png" % [tag, k]); k += 1
		for i in 8: await process_frame
	pl._start_reload()
	var t1 := Time.get_ticks_msec()
	for dt in [0.12, 0.35, 0.8, 1.6]:
		while (Time.get_ticks_msec() - t1) * 0.15 / 1000.0 < dt: await process_frame
		root.get_viewport().get_texture().get_image().save_png("/tmp/db_%s_%d.png" % [tag, k]); k += 1
	Engine.time_scale = 1.0
	for i in 60: await process_frame
func _run() -> void:
	await process_frame
	C = root.get_node("Controls"); C.reset(); C.view_fp = false
	change_scene_to_file("res://Main.tscn")
	for i in 40: await process_frame
	sc = current_scene; pl = sc.player
	var t := 0
	while sc.get_tree().get_nodes_in_group("zombie").size() < 2 and t < 900: await process_frame; t += 1
	for w in sc.find_children("*", "WaveManager", true, false): w.process_mode = Node.PROCESS_MODE_DISABLED
	var g = pl.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-10, 20, -4), Vector3(-10, -5, -4)))
	pl.global_position = g["position"] + Vector3(0, 0.1, 0); pl.velocity = Vector3.ZERO
	C.loadout[0] = "dbarrel"; pl._equip(0, true)
	for i in 40: await process_frame
	for p in pl._soldier.find_children("*", "CPUParticles3D", true, false): p.queue_free()
	var fwd: Vector3 = -pl.global_transform.basis.z; fwd.y = 0; fwd = fwd.normalized()
	var right := fwd.cross(Vector3.UP)
	game_cam = root.get_viewport().get_camera_3d()
	var cam := Camera3D.new(); sc.add_child(cam); cam.fov = 45
	cam.global_position = pl.global_position + right * 5.2 + fwd * 1.9 + Vector3(0, 1.5, 0)
	cam.look_at(pl.global_position + fwd * 1.9 + Vector3(0, 1.0, 0), Vector3.UP); cam.current = true
	await _shots("side")
	game_cam.current = true
	C.view_fp = true
	for i in 30: await process_frame
	await _shots("fp")
	quit()
