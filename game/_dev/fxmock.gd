extends SceneTree
## 시안: kill effects (3 moments each) and tracers, in the training range
func _initialize() -> void:
	_run()
func _shot(n: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("/tmp/fx_%s.png" % n)
func _run() -> void:
	await process_frame; await process_frame
	var C = root.get_node("Controls"); C.reset(); C.view_fp = false
	change_scene_to_file("res://Training.tscn")
	for i in 60: await process_frame
	var sc = current_scene; var pl = sc.player
	for l in sc.find_children("*", "CanvasLayer", true, false): l.visible = false
	C.view_fp = true
	pl.global_position = Vector3(-3, 0.5, 1.5); pl.face(Vector3(-3, 1.4, -20))
	for i in 30: await process_frame
	var cam := root.get_viewport().get_camera_3d()
	var f: Vector3 = -cam.global_transform.basis.z; f.y = 0; f = f.normalized()
	var tgt: Vector3 = cam.global_position + f * 6.0
	var h = sc.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(tgt + Vector3(0, 3, 0), tgt + Vector3(0, -6, 0)))
	if h: tgt = h["position"]
	print("TARGET ", tgt)
	for id in FxCos.KILLS:
		var s := Soldier.new(); s.body = "scout"; s.lod = true; sc.add_child(s); s.setup(Color(0.3, 0.55, 0.9))
		s.global_position = tgt; s.look_at(Vector3(cam.global_position.x, tgt.y, cam.global_position.z), Vector3.UP); s.rotate_y(PI)
		for i in 8: await process_frame
		_shot("%s_pre" % id)
		s.visible = false
		Engine.time_scale = 0.2
		FxCos.kill(id, sc, tgt)
		var waits := [2, 5, 9]
		for k in 3:
			for i in waits[k]: await process_frame
			_shot("%s_%d" % [id, k])
		Engine.time_scale = 1.0
		s.queue_free()
		for i in 60: await process_frame
	# tracers: first person, a long shot down the range
	for id in FxCos.TRACERS:
		var a: Vector3 = cam.global_transform * Vector3(0.14, -0.12, -0.6)
		var b: Vector3 = cam.global_transform * Vector3(0.0, 0.0, -28.0)
		FxCos.tracer(id, sc, a, b, 1.0)
		var a2: Vector3 = cam.global_transform * Vector3(0.14, -0.12, -0.6)
		FxCos.tracer(id, sc, a2, cam.global_transform * Vector3(1.2, 0.3, -24.0), 1.0)
		for i in 8: await process_frame
		_shot(id)
		for i in 80: await process_frame
	C.view_fp = false; C.save_settings()
	quit()
