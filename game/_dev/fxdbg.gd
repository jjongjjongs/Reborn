extends SceneTree
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	change_scene_to_file("res://Training.tscn")
	for i in 30: await process_frame
	var sc = current_scene
	FxCos.kill("kill_pixel", sc, Vector3(0, 0, -5))
	FxCos.kill("kill_fire", sc, Vector3(0, 0, -5))
	for i in 3: await process_frame
	for p in sc.find_children("*", "CPUParticles3D", true, false):
		print("P amount=%d emit=%s life=%.2f mesh=%s pos=%s" % [p.amount, p.emitting, p.lifetime, p.mesh.get_class(), p.global_position])
	await create_timer(0.6).timeout
	for p in sc.find_children("*", "CPUParticles3D", true, false):
		print("P2 amount=%d emit=%s pos=%s" % [p.amount, p.emitting, p.global_position])
	quit()
