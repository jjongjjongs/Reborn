extends SceneTree
## pairs per class: left = parts as imported, right = baked into one surface (bots). same skin, real map light
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset(); C.team_size = 1; C.sel_map = "temple"; C.view_fp = false
	change_scene_to_file("res://BombMode.tscn")
	for i in 40: await process_frame
	var sc = current_scene; var pl = sc.player
	for p in sc.find_children("*", "PrepLoadout", true, false): p.queue_free()
	for b in sc.get_tree().get_nodes_in_group("bots"): b.process_mode = Node.PROCESS_MODE_DISABLED; b.visible = false
	pl.process_mode = Node.PROCESS_MODE_DISABLED
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var S = load("res://soldier.gd"); var P = load("res://profile.gd")
	var base: Vector3 = pl.global_position
	var fwd := -cam.global_transform.basis.z; fwd.y = 0; fwd = fwd.normalized(); var right := fwd.cross(Vector3.UP)
	var i := 0
	for c in S.CLASSES:
		for bake in [false, true]:
			S.bake_bots = bake
			var s = S.new(); s.body = c; s.lod = true
			var sk: Array = P.skins_of(c); s.skin = P.skin_mats(sk[1 % sk.size()])
			print("mk ", c, " ", bake); sc.add_child(s); s.setup(Color(0.3, 0.5, 1.0)); print("ok")
			s.global_position = base + fwd * 4.5 + right * (-6.3 + i * 1.4)
			s.look_at(s.global_position - fwd, Vector3.UP)
			i += 1
	pl.visible = false
	for k in 30: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/bakecmp.png")
	quit()
