extends SceneTree
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	change_scene_to_file("res://Menu.tscn")
	for i in 40: await process_frame
	var shop = load("res://shop_screen.gd").new(); current_scene.add_child(shop)
	for i in 10: await process_frame
	shop._cat = "wfx"; shop._sel = "wfx_ember"; shop._refresh()
	for i in 30: await process_frame
	var s = shop._soldier
	print("DBG wfx=", s.wfx, " weapon=", s.weapon, " node=", s._wfx_node, " gun_vis=", s._gun.visible, " gunpos=", s._gun.global_position)
	for p in s._gun.find_children("*", "CPUParticles3D", true, false):
		print("  P emit=", p.emitting, " amount=", p.amount, " pos=", p.global_position, " vis=", p.is_visible_in_tree())
	quit()
