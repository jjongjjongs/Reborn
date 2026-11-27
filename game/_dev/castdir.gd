extends SceneTree
## cast the player capsule from P along D; print what it hits
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
	for cs in sc.player.find_children("*", "CollisionShape3D", true, false): print("player shape ", cs.shape, " ", cs.shape.get("radius"), " ", cs.shape.get("height"), " at ", cs.position)
	var cap := CapsuleShape3D.new(); cap.radius = 0.45; cap.height = 2.15
	var prm := PhysicsShapeQueryParameters3D.new(); prm.shape = cap
	var p := Vector3(-8.8, 7.03 + 1.1, -41.5); var d := Vector3(0.847, 0, -0.531)
	for up in [0.0, 0.1, 0.3]:
		prm.transform = Transform3D(Basis(), p + Vector3(0, up, 0)); prm.motion = d * 3.0
		var r: PackedFloat32Array = space.cast_motion(prm)
		var info := ""
		if r[0] < 1.0:
			prm.transform = Transform3D(Basis(), p + Vector3(0, up, 0) + d * 3.0 * r[1]); prm.motion = Vector3.ZERO
			var ri = space.get_rest_info(prm)
			if ri: var o = instance_from_id(ri["collider_id"]); info = "%s/%s at %s normal %s" % [o.get_parent().name if o.get_parent() else "", o.name, ri["point"], ri["normal"]]
		print("up ", up, " safe ", r[0], " ", info)
	quit()
