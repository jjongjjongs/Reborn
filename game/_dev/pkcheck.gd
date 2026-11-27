extends SceneTree
## pistol + knife hold close-ups (3P: right side, left side, front-quarter, aiming and ready) for one body
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var a := OS.get_cmdline_user_args()
	var body: String = a[0] if a.size() > 0 else "rookie"
	var w := Node3D.new(); root.add_child(w)
	var l := DirectionalLight3D.new(); l.rotation_degrees = Vector3(-40, 150, 0); w.add_child(l)
	var l2 := DirectionalLight3D.new(); l2.rotation_degrees = Vector3(-25, -30, 0); l2.light_energy = 0.6; w.add_child(l2)
	var we := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.8, 0.82, 0.85)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.9, 0.9, 0.9); e.ambient_light_energy = 0.6; we.environment = e; w.add_child(we)
	var cam := Camera3D.new(); w.add_child(cam); cam.current = true; cam.fov = 32
	var k := 0
	for id in ["pistol", "knife"]:
		for aim in [true, false]:
			var s := Soldier.new(); s.body = body; w.add_child(s); s.setup(Color(0.22, 0.36, 0.72)); s.set_weapon(id)
			for f in 40:
				s.drive(0.0, aim); await process_frame
			var g: Vector3 = s.global_transform * (s._gun_s * s._anchor("grip"))
			for v in [Vector3(1.3, 0.2, 0.0), Vector3(-1.3, 0.2, 0.0), Vector3(0.6, 0.25, -1.1)]:
				cam.position = g + v; cam.look_at(g, Vector3.UP)
				for f in 3: await process_frame
				root.get_viewport().get_texture().get_image().save_png("/tmp/pk_%s_%d.png" % [body, k]); k += 1
			s.queue_free()
	quit()
