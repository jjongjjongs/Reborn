extends SceneTree
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	var w := Node3D.new(); root.add_child(w)
	var env := WorldEnvironment.new(); env.environment = Environment.new(); env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.4, 0.45, 0.5); w.add_child(env)
	var cam := Camera3D.new(); w.add_child(cam); cam.position = Vector3(4, 1, 6); cam.look_at(Vector3(4, 1, 0)); cam.current = true
	var j = load("res://flame_jet.gd").new(); w.add_child(j)
	for i in 50:
		j.feed(Vector3(0, 1, 0), Vector3(1, 0, 0))
		await process_frame
		if i == 10 or i == 49:
			var ps = j._core
			print("F%d emitting %s pos %s dir %s vel %s" % [i, ps.emitting, ps.global_position, ps.global_transform.basis * ps.direction, ps.initial_velocity_max])
	root.get_viewport().get_texture().get_image().save_png("/tmp/jet.png")
	quit()
