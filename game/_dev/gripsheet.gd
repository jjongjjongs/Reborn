extends SceneTree
## grip review: each body x each weapon, aiming, close side view of both hands + numbers
## (hand bone -> grip / fore anchor distance in body units)
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
	var cam := Camera3D.new(); w.add_child(cam); cam.current = true; cam.fov = 30
	var ids: Array = ["m4", "ak", "mp5", "shotgun", "sniper", "rpk", "pistol", "revolver", "knife"]
	if a.size() > 1: ids = Array(a[1].split(","))
	var k := 0
	for id in ids:
		var s := Soldier.new(); s.body = body; w.add_child(s); s.setup(Color(0.22, 0.36, 0.72)); s.set_weapon(id)
		for f in 40:
			s.drive(0.0, true); await process_frame
		var hr: Vector3 = s.global_transform * ((s._bone_s(s._arm["Hand.R"]) + s._bone_s(s._arm["Middle2.R"])) * 0.5)   # palm centre
		var hl: Vector3 = s.global_transform * ((s._bone_s(s._arm["Hand.L"]) + s._bone_s(s._arm["Middle2.L"])) * 0.5)
		var g: Vector3 = s.global_transform * (s._gun_s * s._anchor("grip"))
		var fo: Vector3 = s.global_transform * (s._gun_s * s._anchor("fore" if s._wdef.has("fore") and s._wdef["kind"] == "long" else "grip"))
		print("GRIP %s %s R-grip %.3f L-fore %.3f" % [body, id, hr.distance_to(g), hl.distance_to(fo)])
		var mid := (hr + hl) * 0.5
		cam.position = mid + Vector3(-1.5, 0.25, -0.2); cam.look_at(mid, Vector3.UP)
		for f in 4: await process_frame
		root.get_viewport().get_texture().get_image().save_png("/tmp/grip_%s_%d.png" % [body, k]); k += 1
		s.queue_free()
	quit()
