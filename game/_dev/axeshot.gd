extends SceneTree
## 시안: fire-axe swing on the real player (zombie mode). frames by swing progress, 3rd person + side + 1st person
var C; var pl; var sc
const MARKS := [0.0, 0.12, 0.22, 0.30, 0.36, 0.45, 0.6, 0.85]
func _initialize() -> void: _run()
func _place_zombies() -> Array:
	var zs: Array = sc.get_tree().get_nodes_in_group("zombie")
	var fwd: Vector3 = -pl.global_transform.basis.z; fwd.y = 0; fwd = fwd.normalized()
	var right := fwd.cross(Vector3.UP)
	var out := []
	for i in zs.size():
		var z = zs[i]
		if i < 2:
			z.player = null; z._warmup = 99.0
			z.global_position = pl.global_position + fwd * (2.1 + i * 0.3) + right * (0.5 - i * 1.1)
			z.look_at(pl.global_position, Vector3.UP); z.velocity = Vector3.ZERO
			z.hp = 99999.0; out.append(z)
		else:
			z.queue_free()
	return out
func _swing_strip(tag: String) -> void:
	_place_zombies()
	for i in 20: await process_frame
	Engine.time_scale = 0.12
	pl._fire_cd = 0.0; pl._stab()
	var k := 0
	while k < MARKS.size():
		await process_frame
		var kick: float = pl._soldier._kick
		var s: float = 1.0 - kick if kick > 0.0 else 1.0
		if s + 0.001 >= float(MARKS[k]):
			root.get_viewport().get_texture().get_image().save_png("/tmp/axe_%s_%d.png" % [tag, k]); k += 1
	Engine.time_scale = 1.0
	for i in 30: await process_frame
func _run() -> void:
	await process_frame
	C = root.get_node("Controls"); C.reset(); C.view_fp = false; C.wave_mode = 5
	change_scene_to_file("res://Main.tscn")
	for i in 40: await process_frame
	sc = current_scene; pl = sc.player if "player" in sc else sc.find_children("*", "PlayerBody", true, false)[0]
	# wait for zombies, freeze the waves
	var t := 0
	while sc.get_tree().get_nodes_in_group("zombie").size() < 2 and t < 900: await process_frame; t += 1
	for w in sc.find_children("*", "WaveManager", true, false): w.process_mode = Node.PROCESS_MODE_DISABLED
	C.loadout[2] = "axe"; pl._equip(2, true)
	# an open spot: nothing within 5 m around at chest height
	var space = pl.get_world_3d().direct_space_state
	var best: Vector3 = pl.global_position; var bs := -1.0
	for gx in range(-14, 15, 2):
		for gz in range(-12, 13, 2):
			var g = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(gx, 20, gz), Vector3(gx, -5, gz)))
			if not g: continue
			var p: Vector3 = g["position"] + Vector3(0, 1.2, 0)
			var free := 9.0
			for a in 12:
				var d := Vector3(cos(a * TAU / 12.0), 0, sin(a * TAU / 12.0))
				var h = space.intersect_ray(PhysicsRayQueryParameters3D.create(p, p + d * 9.0, 1, [pl.get_rid()]))
				if h: free = minf(free, p.distance_to(h["position"]))
			if free > bs: bs = free; best = g["position"]
	print("OPEN spot ", best, " clear ", bs)
	pl.global_position = best + Vector3(0, 0.1, 0); pl.velocity = Vector3.ZERO
	for i in 40: await process_frame
	C.hp = 100
	await _swing_strip("tp")
	# side view: a fixed camera to the player's right
	var cam := Camera3D.new(); sc.add_child(cam)
	var fwd: Vector3 = -pl.global_transform.basis.z; fwd.y = 0; fwd = fwd.normalized()
	var right := fwd.cross(Vector3.UP)
	cam.fov = 45
	cam.global_position = pl.global_position + right * 2.6 + fwd * 3.6 + Vector3(0, 1.3, 0)
	cam.look_at(pl.global_position + fwd * 1.2 + Vector3(0, 1.0, 0), Vector3.UP); cam.current = true
	for p in pl._soldier.find_children("*", "CPUParticles3D", true, false): p.queue_free()
	await _swing_strip("side")
	cam.current = false; cam.queue_free()
	C.view_fp = true
	for i in 30: await process_frame
	await _swing_strip("fp")
	quit()
