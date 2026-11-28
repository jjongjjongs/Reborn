extends SceneTree
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset(); C.view_fp = true
	change_scene_to_file("res://Main.tscn")
	for i in 40: await process_frame
	var sc = current_scene; var pl = sc.player
	for w in sc.find_children("*", "WaveManager", true, false): w.process_mode = Node.PROCESS_MODE_DISABLED
	var mgr = sc.find_children("*", "WaveManager", true, false)[0]; mgr._wave = 0; mgr._spawn_one()
	for u in sc.find_children("*", "UpgradeShop", true, false): u.visible = false
	C.prep_left = -1.0
	var g = pl.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-10, 20, -4), Vector3(-10, -5, -4)))
	pl.global_position = g["position"] + Vector3(0, 0.1, 0)
	C.loadout[1] = "nailgun"; pl._ammo["nailgun"] = 40; pl._equip(1, true)
	for i in 20: await process_frame
	var z = sc.get_tree().get_nodes_in_group("zombie")[0]
	var fwd: Vector3 = -pl.global_transform.basis.z; fwd.y = 0; fwd = fwd.normalized()
	z.player = null; z._warmup = 99.0; z.hp = 99999.0
	z.global_position = pl.global_position + fwd * 3.0; z.look_at(pl.global_position, Vector3.UP)
	pl.aim_pitch = -8.0
	for i in 10: await process_frame
	for k in 6:
		C.spread_deg = 1.0; pl._shoot(Weapons.get_w("nailgun")); await process_frame
	for i in 10: await process_frame
	for n in z.find_children("*", "MeshInstance3D", false, false):
		print("NAIL at ", n.global_position, " scale ", n.global_transform.basis.get_scale(), " zpos ", z.global_position, " zscale ", z.global_transform.basis.get_scale())
	var cc := Camera3D.new(); sc.add_child(cc); cc.fov = 40
	cc.global_position = z.global_position - fwd * 2.4 + fwd.cross(Vector3.UP) * 1.8 + Vector3(0, 1.4, 0)
	cc.look_at(z.global_position - fwd * 0.3 + Vector3(0, 1.0, 0), Vector3.UP); cc.current = true
	for i in 6: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/ng_close.png")
	quit()
