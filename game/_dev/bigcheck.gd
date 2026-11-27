extends SceneTree
## 6 vs 6 / 12-player smoke test on every widened map: bot count, nobody falls out, fights happen
func _initialize() -> void:
	_run()
func _one(scene: String, map: String, frames: int) -> void:
	var C = root.get_node("Controls")
	C.sel_map = map
	change_scene_to_file(scene)
	for i in 30: await process_frame
	var sc = current_scene
	var bots := sc.get_tree().get_nodes_in_group("bots")
	var t0 := Time.get_ticks_msec()
	for i in frames: await physics_frame
	var dt := (Time.get_ticks_msec() - t0) / 1000.0
	var out := 0; var minx := 1e9; var maxx := -1e9; var lods := 0
	for b in sc.get_tree().get_nodes_in_group("bots"):
		var p: Vector3 = b.global_position
		if p.y < -6.0: out += 1
		minx = minf(minx, p.x); maxx = maxf(maxx, p.x)
		if b._soldier and b._soldier.lod: lods += 1
	var kills := 0
	if "_score" in sc: kills = int(sc._score[0]) + int(sc._score[1])
	print("BIG %s %s bots=%d lod=%d fell=%d spread_x=%.0f kills/score=%s sim=%.1fs" % [scene.get_file(), map, bots.size(), lods, out, maxx - minx, str(sc.get("_score")), dt])
	root.get_viewport().get_texture().get_image().save_png("/tmp/big_%s_%s.png" % [scene.get_file().get_basename(), map])
func _run() -> void:
	await process_frame; await process_frame
	var C = root.get_node("Controls")
	C.reset(); C.view_fp = false; C.team_size = 6; C.dm_count = 12
	for m in ["downtown", "bazaar", "cell", "harbor"]:
		await _one("res://TeamDeathmatch.tscn", m, 900)
	await _one("res://Deathmatch.tscn", "downtown", 900)
	for m in ["quarter", "dockside", "facility"]:
		await _one("res://BombMode.tscn", m, 900)
	quit()
