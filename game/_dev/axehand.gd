extends SceneTree
## close-ups of the right hand on the axe (ready / wind-up / impact), plus head clearance numbers over the swing
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
	for p in s.find_children("*", "CPUParticles3D", true, false): p.queue_free()
	var cam := Camera3D.new(); sc.add_child(cam); cam.fov = 28; cam.current = true
	var k := 0
	for sv in [0.0, 0.22, 0.36]:
		Engine.time_scale = 1.0; s._kick = 1.0 - sv if sv > 0.0 else 0.0; Engine.time_scale = 0.0
		for i in 3: await process_frame
		var hp: Vector3 = s.global_transform * s._bone_s(s._arm["Hand.R"])
		for side in [Vector3(1, 0.3, -0.6), Vector3(0.2, 0.2, -1.0)]:
			var d: Vector3 = s.global_transform.basis * side.normalized()
			cam.global_position = hp + d * 0.55; cam.look_at(hp, Vector3.UP)
			for i in 3: await process_frame
			root.get_viewport().get_texture().get_image().save_png("/tmp/axeh_%d.png" % k); k += 1
	Engine.time_scale = 1.0
	quit()
