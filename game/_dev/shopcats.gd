extends SceneTree
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	change_scene_to_file("res://Menu.tscn")
	for i in 40: await process_frame
	var shop = load("res://shop_screen.gd").new(); current_scene.add_child(shop)
	for i in 10: await process_frame
	shop._cat = "title"; shop._sel = "tt_rookie"; shop._refresh()
	for i in 10: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/shopcats.png")
	quit()
