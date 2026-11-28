extends SceneTree
## 시안: flamethrower on the real player (zombie mode): ~1.5 s of fire at three zombies, then they burn; 3rd person side + 1st person
var C; var pl; var sc; var game_cam: Camera3D
func _initialize() -> void: _run()
func _put_zombies() -> void:
	var zs: Array = sc.get_tree().get_nodes_in_group("zombie")
	var fwd: Vector3 = -pl.global_transform.basis.z; fwd.y = 0; fwd = fwd.normalized()
	var right := fwd.cross(Vector3.UP)
	for i in zs.size():
		var z = zs[i]
		if i < 3:
			z.player = null; z._warmup = 99.0; z.hp = 99999.0; z._stagger = 0.0; z._burn = 0.0
			z.global_position = pl.global_position + fwd * (3.5 + i * 1.6) + right * (0.5 - i * 0.6)
			z.look_at(pl.global_position, Vector3.UP); z.velocity = Vector3.ZERO
		else: z.queue_free()
func _fire_strip(tag: String, view_cam: Camera3D) -> void:
	_put_zombies()
	var zs: Array = sc.get_tree().get_nodes_in_group("zombie")
	var fwd: Vector3 = -pl.global_transform.basis.z; fwd.y = 0; fwd = fwd.normalized(); var rt := fwd.cross(Vector3.UP)
	var offs := [Vector3.ZERO, rt * 1.2 + fwd * 2.6, -rt * 0.8 + fwd * 5.4]       # spread out: the chain has to jump
	for i in zs.size(): zs[i].global_position = pl.global_position + fwd * 4.5 + offs[i]; zs[i].hp = 99999.0
	var dz: Vector3 = zs[0].global_position - pl.global_position; pl.aim_yaw = rad_to_deg(atan2(-dz.x, -dz.z)); pl.aim_pitch = -4.0
	pl._ammo["tesla"] = 20
	for i in 25: await process_frame
	var p0: Array = zs.map(func(z): return z.global_position); var h0: Array = zs.map(func(z): return z.hp)
	game_cam.current = true
	pl._shoot(Weapons.get_w("tesla"))
	if view_cam: view_cam.current = true
	var shots := 1
	var k := 0; var t0 := Time.get_ticks_msec()
	var marks := [0.03, 0.09, 0.2, 0.47, 0.52, 0.7, 0.93, 1.6]
	while k < marks.size():
		await process_frame
		var tt := (Time.get_ticks_msec() - t0) / 1000.0
		if shots < 3 and tt >= shots * 0.45:
			game_cam.current = true; pl._shoot(Weapons.get_w("tesla")); shots += 1
			if view_cam: view_cam.current = true
		if tt >= float(marks[k]):
			root.get_viewport().get_texture().get_image().save_png("/tmp/ts_%s_%d.png" % [tag, k]); k += 1
	for i in zs.size(): print("ZAP %s zombie %d damage %d moved %.2f m" % [tag, i, int(h0[i] - zs[i].hp), (zs[i].global_position - p0[i]).length()])
	for i in 60: await process_frame
func _run() -> void:
	await process_frame
	C = root.get_node("Controls"); C.reset(); C.view_fp = false
	change_scene_to_file("res://Main.tscn")
	for i in 40: await process_frame
	sc = current_scene; pl = sc.player
	var t := 0
	while sc.get_tree().get_nodes_in_group("zombie").size() < 3 and t < 900: await process_frame; t += 1
	for w in sc.find_children("*", "WaveManager", true, false): w.process_mode = Node.PROCESS_MODE_DISABLED
	var g = pl.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-10, 20, -4), Vector3(-10, -5, -4)))
	pl.global_position = g["position"] + Vector3(0, 0.1, 0); pl.velocity = Vector3.ZERO
	C.loadout[0] = "tesla"; pl._ammo["tesla"] = 20; pl._equip(0, true)
	for i in 40: await process_frame
	for p in pl._soldier.find_children("*", "CPUParticles3D", true, false): p.queue_free()
	game_cam = root.get_viewport().get_camera_3d()
	var fwd: Vector3 = -pl.global_transform.basis.z; fwd.y = 0; fwd = fwd.normalized()
	var right := fwd.cross(Vector3.UP)
	var cam := Camera3D.new(); sc.add_child(cam); cam.fov = 50
	cam.global_position = pl.global_position + right * 9.5 + fwd * 5.0 + Vector3(0, 2.6, 0)
	cam.look_at(pl.global_position + fwd * 5.0 + Vector3(0, 1.0, 0), Vector3.UP); cam.current = true
	await _fire_strip("side", cam)
	game_cam.current = true
	C.view_fp = true
	for i in 30: await process_frame
	await _fire_strip("fp", null)
	quit()
