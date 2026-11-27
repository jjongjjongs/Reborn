extends SceneTree
## map audit: player capsule on a 1.5 m grid; pockets = can't step out in >= 6 of 8 directions;
## off-nav = walkable ground far from the bots' navmesh. Writes /tmp/audit.png on the radar map.
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 3; C.sel_map = "temple"
	change_scene_to_file("res://BombMode.tscn")
	for i in 40: await process_frame
	var sc = current_scene
	for b in sc.get_tree().get_nodes_in_group("bots"): b.process_mode = Node.PROCESS_MODE_DISABLED; b.queue_free()
	sc.player.process_mode = Node.PROCESS_MODE_DISABLED; sc.player.global_position = Vector3(0, -200, 0)
	for i in 5: await physics_frame
	var space = sc.get_world_3d().direct_space_state
	var navmap = sc.get_world_3d().navigation_map
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/temple.json"))
	var ol := PackedVector2Array(); for p in d["outline"]: ol.append(Vector2(p[0], p[1]))
	var cap := CapsuleShape3D.new(); cap.radius = 0.4; cap.height = 2.15
	var prm := PhysicsShapeQueryParameters3D.new(); prm.shape = cap
	var pockets := []; var offnav := []; var n := 0
	var x := -69.0
	while x < 70.0:
		var z := -59.0
		while z < 60.0:
			if Geometry2D.is_point_in_polygon(Vector2(x, z), ol):
				# every floor level at this x,z (pavilion deck, bridge, ground)
				var top := 40.0
				for layer in 3:
					var h = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, top, z), Vector3(x, -10, z)))
					if not h: break
					var gp: Vector3 = h["position"]; top = gp.y - 2.3
					var nm: String = String(h["collider"].get_parent().name)
					if (h["normal"] as Vector3).y < 0.7: continue          # steep: not a floor
					if nm.begins_with("Col_Buildings") and gp.y > 12.0: continue   # roofs
					var up = space.intersect_ray(PhysicsRayQueryParameters3D.create(gp + Vector3(0, 0.05, 0), gp + Vector3(0, 2.5, 0)))
					if up: continue                        # no head room (inside a solid plinth / under a low floor): not a standing spot
					n += 1
					var c := gp + Vector3(0, 1.1, 0)
					prm.transform = Transform3D(Basis(), c)
					if not space.intersect_shape(prm, 1).is_empty(): continue   # no room to stand here
					var free := 0
					for k in 8:
						var a := TAU * k / 8.0
						prm.motion = Vector3(cos(a) * 0.9, 0.5, sin(a) * 0.9)
						var r: PackedFloat32Array = space.cast_motion(prm)
						if r[0] > 0.95: free += 1
					prm.motion = Vector3.ZERO
					if free <= 2: pockets.append([gp, nm, free])
					var np: Vector3 = NavigationServer3D.map_get_closest_point(navmap, gp)
					if np.distance_to(gp) > 1.6: offnav.append([gp, nm])
			z += 1.5
		x += 1.5
	print("AUDIT floor samples %d  pockets %d  off-nav %d" % [n, pockets.size(), offnav.size()])
	for p in pockets: print("  POCKET (%.1f, %.1f, %.1f) on %s free %d" % [p[0].x, p[0].y, p[0].z, p[1], p[2]])
	var img: Image = (load("res://assets/maps/temple_overview.png") as Texture2D).get_image()
	img.convert(Image.FORMAT_RGBA8)
	var W := img.get_width(); var H := img.get_height()
	var dot := func(p: Vector3, c: Color, r: int) -> void:
		var px := int((p.x + 70.0) / 140.0 * W); var py := int((p.z + 60.0) / 120.0 * H)
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if px + dx >= 0 and px + dx < W and py + dy >= 0 and py + dy < H: img.set_pixel(px + dx, py + dy, c)
	for p in offnav: dot.call(p[0], Color(1.0, 0.8, 0.1), 3)
	for p in pockets: dot.call(p[0], Color(1, 0.1, 0.1), 5)
	img.save_png("/tmp/audit.png")
	quit()
