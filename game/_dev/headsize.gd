extends SceneTree
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset()
	change_scene_to_file("res://Main.tscn")
	for i in 40: await process_frame
	var S = load("res://soldier.gd")
	for c in S.CLASSES:
		var s = S.new(); s.body = c; current_scene.add_child(s); s.setup(Color.BLUE)
		for i in 3: await process_frame
		var t = s._tgt
		var hb: int = t.find_bone("Head"); var nb: int = t.find_bone("Neck")
		var top := -9.0
		for mi in s.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			if m.skin == null: continue
			var bb: AABB = s.global_transform.affine_inverse() * m.global_transform * m.get_aabb()
			top = maxf(top, bb.end.y)
		print("HEAD %s head %s neck %s top %.2f reach %.2f handback %.3f" % [c, s._bone_s(hb), s._bone_s(nb), top, s._reach("R"), s.hand_back])
		s.queue_free()
	quit()
