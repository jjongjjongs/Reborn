extends SceneTree
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset()
	change_scene_to_file("res://Training.tscn")
	for i in 50: await process_frame
	var pl = current_scene.player
	var ds = current_scene.find_children("*", "", true, false).filter(func(n): return n is TrainingDummy)
	print("DUMMIES ", ds.size())
	var d = ds[0]
	C.loadout[2] = "knife"; pl._equip(2, true)
	var to: Vector3 = d.global_position - pl.global_position; to.y = 0
	pl.global_position = d.global_position - to.normalized() * 1.2
	pl.face(d.global_position + Vector3(0, 1.0, 0))
	for i in 10: await process_frame
	var hp0 = d.get("hp"); var log0 = d.get("_total")
	var hits := [0]
	var orig = d.hit
	pl._stab()
	for i in 10: await process_frame
	print("KNIFE dummy hp before ", hp0, " after ", d.get("hp"))
	quit()
