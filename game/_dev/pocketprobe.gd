extends SceneTree
## for each point: per direction, what blocks a capsule step and the floor height 1.5 m away
const PTS := [Vector3(48.8, 1.15, 32.6)]
func _initialize() -> void: _run()
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
	var cap := CapsuleShape3D.new(); cap.radius = 0.4; cap.height = 2.15
	var prm := PhysicsShapeQueryParameters3D.new(); prm.shape = cap
	for p: Vector3 in PTS:
		var line := "P(%.1f,%.1f,%.1f):" % [p.x, p.y, p.z]
		for k in 8:
			var a := TAU * k / 8.0; var dv := Vector3(cos(a), 0, sin(a))
			prm.transform = Transform3D(Basis(), p + Vector3(0, 1.15, 0)); prm.motion = dv * 0.9 + Vector3(0, 0.5, 0)
			var r: PackedFloat32Array = space.cast_motion(prm)
			var who := "-"
			if r[0] < 0.95:
				prm.transform = Transform3D(Basis(), p + Vector3(0, 1.15, 0) + prm.motion * r[1])
				var ri = space.get_rest_info(prm)
				if ri: who = String(instance_from_id(ri["collider_id"]).get_parent().name if instance_from_id(ri["collider_id"]).get_parent() else "?") + "@%.1f" % ri["point"].y
			var q := p + dv * 1.5
			var h = space.intersect_ray(PhysicsRayQueryParameters3D.create(q + Vector3(0, 3, 0), q + Vector3(0, -8, 0)))
			line += " [%d %s fl%.1f]" % [k * 45, who, h["position"].y if h else -99.0]
		print(line)
	quit()
