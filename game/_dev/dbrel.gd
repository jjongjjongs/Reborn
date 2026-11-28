extends SceneTree
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	var C = root.get_node("Controls"); C.reset(); C.view_fp = true
	change_scene_to_file("res://Main.tscn")
	for i in 40: await process_frame
	var pl = current_scene.player
	C.loadout[0] = "dbarrel"; pl._equip(0, true)
	for i in 40: await process_frame
	var vm = current_scene.find_children("*", "ViewModel", true, false)
	if vm.is_empty(): vm = root.find_children("*", "ViewModel", true, false)
	print("VM count ", vm.size())
	pl._ammo["dbarrel"] = 0; pl._start_reload()
	for i in 40:
		await process_frame
		if i % 8 == 0 and vm.size() > 0: print("REL i%d vis %s reload_k %.2f raise %.2f holder %s swapping %s" % [i, vm[0].visible, vm[0]._reload_k, vm[0]._raise, vm[0]._holder.position, C.swapping])
	quit()
