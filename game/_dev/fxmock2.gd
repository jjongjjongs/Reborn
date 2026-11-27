extends SceneTree
## 시안: weapon effects (close-up on the gun, 3rd person + 1st person in the range) and
## character effects (soldier running past, dark studio + in the range)
var studio: Node3D
func _initialize() -> void:
	_run()
func _shot(n: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("/tmp/fx2_%s.png" % n)
func _wait(ms: int) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < ms: await process_frame
func _studio() -> Node3D:
	var s := Node3D.new(); root.add_child(s)
	var we := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.09, 0.11, 0.14); e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.63, 0.7); e.ambient_light_energy = 0.7; we.environment = e; s.add_child(we)
	var l := DirectionalLight3D.new(); l.rotation_degrees = Vector3(-40, -150, 0); s.add_child(l)
	var l2 := DirectionalLight3D.new(); l2.rotation_degrees = Vector3(-30, 30, 0); l2.light_energy = 0.5; s.add_child(l2)
	var fl := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(40, 40); fl.mesh = pm
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color(0.16, 0.18, 0.21); fl.material_override = fm; s.add_child(fl)
	return s
func _run() -> void:
	await process_frame; await process_frame
	var C = root.get_node("Controls"); C.reset()
	studio = _studio()
	var cam := Camera3D.new(); cam.fov = 30.0; studio.add_child(cam); cam.current = true
	# ---- weapon effects: the gun on its own (like the shop's gun view), side on
	var holder := Node3D.new(); studio.add_child(holder); holder.position = Vector3(0, 1.3, 0)
	var g: Node3D = (load("res://assets/guns/m4.glb") as PackedScene).instantiate(); holder.add_child(g)
	var ab := AABB(); var first := true
	for mi in g.find_children("*", "MeshInstance3D", true, false):
		var bx: AABB = (mi as MeshInstance3D).get_aabb(); ab = bx if first else ab.merge(bx); first = false
	var L := 0.82; var sc := L / maxf(ab.size.x, 0.001)
	g.rotation.y = PI * 0.5; g.scale = Vector3.ONE * sc; g.position = -(Basis(Vector3.UP, PI * 0.5) * (ab.get_center() * sc))
	cam.fov = 34.0
	cam.look_at_from_position(Vector3(1.25, 1.5, 0.25), Vector3(0, 1.32, 0.0))
	for id in ["wfx_none"] + FxCos.WEAPONS_FX:
		var f := FxCos.weapon_fx(id, holder, L)
		holder.rotation.y = 0.0
		var t0 := Time.get_ticks_msec(); var last := t0
		while Time.get_ticks_msec() - t0 < 1300:
			await process_frame
			holder.rotation.y = sin((Time.get_ticks_msec() - t0) / 1000.0 * 1.2) * 0.12
		_shot(id)
		f.queue_free()
		for i in 3: await process_frame
	holder.queue_free()
	# ---- character effects: soldier running across, camera from the side
	cam.fov = 40.0
	for id in FxCos.CHARS_FX:
		var c := Soldier.new(); c.body = "rookie"; c._nade = Node3D.new(); c.add_child(c._nade); studio.add_child(c); c.setup(Color(0.3, 0.55, 0.9)); c.set_weapon("m4")
		c.global_position = Vector3(-3.0, 0, 0); c.rotation.y = -PI * 0.5
		var f := FxCos.char_fx(id, c)
		c.drive(1.0, false)
		var t0 := Time.get_ticks_msec(); var last := t0
		while Time.get_ticks_msec() - t0 < 900:
			await process_frame
			var now := Time.get_ticks_msec(); c.global_position.x += 4.5 * (now - last) / 1000.0; last = now
			cam.look_at_from_position(Vector3(c.global_position.x - 0.9, 1.5, 3.3), Vector3(c.global_position.x - 1.0, 0.8, 0))
		_shot(id)
		c.queue_free()
		for i in 5: await process_frame
	quit()
