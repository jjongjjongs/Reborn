extends SceneTree
## swing poses frozen at fixed s (time stopped), seen from the right-front and the left side
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset(); C.view_fp = false
	change_scene_to_file("res://Main.tscn")
	for i in 40: await process_frame
	var sc = current_scene; var pl = sc.player
	for w in sc.find_children("*", "WaveManager", true, false): w.process_mode = Node.PROCESS_MODE_DISABLED
	for z in sc.get_tree().get_nodes_in_group("zombie"): z.queue_free()
	for cl in sc.find_children("*", "CanvasLayer", true, false): cl.visible = false
	for cl in root.get_children():
		if cl is CanvasLayer: cl.visible = false
	var g = pl.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-10, 20, -4), Vector3(-10, -5, -4)))
	pl.global_position = g["position"] + Vector3(0, 0.1, 0); pl.velocity = Vector3.ZERO
	C.loadout[2] = "axe"; pl._equip(2, true)
	for i in 30: await process_frame
	var s = pl._soldier
	var fwd: Vector3 = -pl.global_transform.basis.z; fwd.y = 0; fwd = fwd.normalized()
	var right := fwd.cross(Vector3.UP)
	var cam := Camera3D.new(); sc.add_child(cam); cam.fov = 32
	for n in s.get_children():
		if n is Node3D and n != s._swat and n != s._gun and not (n is MeshInstance3D) and n.get_class() != "Node3D" : pass
	for p in s.find_children("*", "CPUParticles3D", true, false): p.queue_free()
	for p in s.find_children("*", "GPUParticles3D", true, false): p.queue_free()
	var space = pl.get_world_3d().direct_space_state
	var views := []
	for v in [["front", right * 2.2 + fwd * 2.6], ["front2", -right * 2.2 + fwd * 2.6], ["side", right * 3.0 + fwd * 0.3], ["side2", -right * 3.0 + fwd * 0.3]]:
		var a: Vector3 = pl.global_position + Vector3(0, 1.0, 0)
		if not space.intersect_ray(PhysicsRayQueryParameters3D.create(a, a + v[1] * 1.15)): views.append(v)
	print("VIEWS ", views.map(func(x): return x[0]))
	for view in [views[0], views[2] if views.size() > 2 else views[0]]:
		cam.global_position = pl.global_position + view[1] + Vector3(0, 1.0, 0)
		cam.look_at(pl.global_position + fwd * 0.4 + Vector3(0, 0.9, 0), Vector3.UP); cam.current = true
		var k := 0
		for sv in [0.0, 0.2, 0.3, 0.36, 0.56, 0.8]:
			Engine.time_scale = 1.0
			s._kick = 1.0 - sv if sv > 0.0 else 0.0
			Engine.time_scale = 0.0
			for i in 4: await process_frame
			root.get_viewport().get_texture().get_image().save_png("/tmp/axep_%s_%d.png" % [view[0], k]); k += 1
		Engine.time_scale = 1.0
	quit()
