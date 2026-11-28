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
		if i < 3:
			z.player = null; z._warmup = 99.0; z.hp = 99999.0; z._stagger = 0.0
			z.global_position = pl.global_position + fwd * (3.2 + i * 1.2) + right * (0.3 - i * 0.9)
			z.look_at(pl.global_position, Vector3.UP); z.velocity = Vector3.ZERO
		else: z.queue_free()
func _shots(tag: String) -> void:
	_put_zombies()
	var zs: Array = sc.get_tree().get_nodes_in_group("zombie")
	var fwd: Vector3 = -pl.global_transform.basis.z; fwd.y = 0; fwd = fwd.normalized()
	for i in zs.size(): zs[i].global_position = pl.global_position + fwd * (3.5 + i * 1.3)       # in a line: pierce shows
	pl._ammo["nailgun"] = 40; pl.aim_pitch = -6.0
	var dz: Vector3 = zs[0].global_position - pl.global_position; pl.aim_yaw = rad_to_deg(atan2(-dz.x, -dz.z))
	for i in 20: await process_frame
	var k := 0; var t0 := Time.get_ticks_msec(); var next := 0.0
	var marks := [0.12, 0.3, 0.55, 0.8, 1.1, 1.6, 2.2, 3.0]
	while k < marks.size():
		await process_frame
		var t := (Time.get_ticks_msec() - t0) / 1000.0
		if t < 1.2 and t >= next:
			next += 0.12
			var shot_cam: Camera3D = root.get_viewport().get_camera_3d()
			if tag == "side": game_cam.current = true
			C.spread_deg = 1.5; pl._shoot(Weapons.get_w("nailgun"))
			shot_cam.current = true
		if t >= float(marks[k]):
			root.get_viewport().get_texture().get_image().save_png("/tmp/ng_%s_%d.png" % [tag, k]); k += 1
	var stuck := 0
	for z in zs: stuck += z.find_children("*", "MeshInstance3D", false, false).size()
	print("NAILS stuck in zombies: ", stuck)
	if tag == "side":                       # close-up of the nails left in the first zombie
		var z0: Node3D = zs[0]
		var cc := Camera3D.new(); sc.add_child(cc); cc.fov = 35
		var zf: Vector3 = (pl.global_position - z0.global_position); zf.y = 0; zf = zf.normalized()
		cc.global_position = z0.global_position + zf * 2.4 + zf.cross(Vector3.UP) * 1.8 + Vector3(0, 1.4, 0)
		cc.look_at(z0.global_position + zf * 0.3 + Vector3(0, 1.0, 0), Vector3.UP); cc.current = true
		for i in 6: await process_frame
		root.get_viewport().get_texture().get_image().save_png("/tmp/ng_close.png")
		cc.queue_free(); game_cam.current = true
	for i in 30: await process_frame
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
	C.loadout[1] = "nailgun"; pl._equip(1, true)
	for i in 40: await process_frame
	for p in pl._soldier.find_children("*", "CPUParticles3D", true, false): p.queue_free()
	var fwd: Vector3 = -pl.global_transform.basis.z; fwd.y = 0; fwd = fwd.normalized()
	var right := fwd.cross(Vector3.UP)
	game_cam = root.get_viewport().get_camera_3d()
	var cam := Camera3D.new(); sc.add_child(cam); cam.fov = 45
	cam.global_position = pl.global_position + right * 6.5 + fwd * 3.2 + Vector3(0, 1.6, 0)
	cam.look_at(pl.global_position + fwd * 3.2 + Vector3(0, 1.0, 0), Vector3.UP); cam.current = true
	await _shots("side")
	game_cam.current = true
	C.view_fp = true
	for i in 30: await process_frame
	await _shots("fp")
	quit()
