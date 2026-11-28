extends SceneTree
## headless: which script types cost process time during a live 6v6 round (toggle each off in turn)
func _initialize() -> void: _run()
func _avg(n: int) -> float:
	var t := 0.0
	for i in n:
		await process_frame
		t += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0 + Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	return t / n
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 6; C.sel_map = "temple"; C.view_fp = false
	change_scene_to_file("res://BombMode.tscn")
	for i in 30: await process_frame
	var sc = current_scene
	for p in sc.find_children("*", "PrepLoadout", true, false): p.queue_free()
	var by := {}
	for n in sc.find_children("*", "", true, false):
		if n.get_script() == null: continue
		if not (n.is_processing() or n.is_physics_processing()): continue
		var k: String = (n.get_script() as Script).resource_path.get_file()
		if not by.has(k): by[k] = []
		by[k].append(n)
	for a in root.get_children():
		if a != sc and a.get_script(): var k2: String = "autoload:" + a.name; by[k2] = [a]
	var base := await _avg(120)
	print("BASE %.2f ms" % base)
	for k in by:
		var st := []
		for n in by[k]: st.append([n, n.is_processing(), n.is_physics_processing()]); n.set_process(false); n.set_physics_process(false)
		var v := await _avg(90)
		for e in st: e[0].set_process(e[1]); e[0].set_physics_process(e[2])
		print("OFF %-28s x%-3d  %.2f ms  (saves %.2f)" % [k, by[k].size(), v, base - v])
		await _avg(20)
	quit()
