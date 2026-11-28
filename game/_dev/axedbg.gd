extends SceneTree
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset(); C.view_fp = false
	change_scene_to_file("res://Main.tscn")
	for i in 40: await process_frame
	var pl = current_scene.player
	C.loadout[2] = "axe"; pl._equip(2, true)
	for i in 20: await process_frame
	var s = pl._soldier
	print("DBG weapon ", s.weapon, " len ", s._len(), " gun_k ", s.gun_k, " wdef ", s._wdef)
	var ab: AABB = s._model_aabb(s._wmodel)
	print("DBG model aabb ", ab, " model scale ", s._wmodel.transform.basis.get_scale(), " gun vis ", s._gun.visible)
	var hr = s._bone_s(s._arm["Hand.R"]); var hl = s._bone_s(s._arm["Hand.L"])
	print("DBG hands R ", hr, " L ", hl, " grip ", s._gun_s * s._anchor("grip"), " fore ", s._gun_s * s._anchor("fore"))
	pl._stab()
	for i in 6: await process_frame
	print("DBG kick ", s._kick, " hands R ", s._bone_s(s._arm["Hand.R"]), " grip ", s._gun_s * s._anchor("grip"))
	quit()
