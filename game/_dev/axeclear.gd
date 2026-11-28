extends SceneTree
## head clearance over the swing: closest axe point (haft + head, 30 samples) to the head sphere centre, every body
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset()
	change_scene_to_file("res://Main.tscn")
	for i in 40: await process_frame
	var S = load("res://soldier.gd")
	for c in S.CLASSES:
		var s = S.new(); s.body = c; current_scene.add_child(s); s.setup(Color.BLUE); s.set_weapon("axe")
		for i in 3: await process_frame
		var worst := 9.0; var at := 0.0
		for k in 41:
			var sv := k / 40.0
			s._axe_last = Basis(); s._kick = 1.0 - sv if sv > 0.0 else 0.0
			Engine.time_scale = 0.0
			await process_frame
			var hc: Vector3 = s._bone_s(s._tgt.find_bone("Head")) + Vector3(0, S.AXE_HEAD_UP, 0)
			var L: float = s._len()
			for j in 30:
				var q: Vector3 = s._gun_s * Vector3(0, -0.06 * L * float(j >= 20), lerpf(0.5 - 0.0, 0.5 - 0.8, j / 29.0) * L)
				var d := q.distance_to(hc)
				if d < worst: worst = d; at = sv
		Engine.time_scale = 1.0
		print("CLEAR %-7s closest %.3f (sphere %.2f) at s=%.2f" % [c, worst, S.AXE_HEAD_R, at])
		s.queue_free()
	quit()
