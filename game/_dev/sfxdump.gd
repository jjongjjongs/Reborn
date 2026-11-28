extends SceneTree
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	var S = root.get_node("Sfx")
	var out: String = OS.get_cmdline_user_args()[0]
	for n in ["axe_swing", "axe_hit", "dbarrel", "break", "flame", "nail", "twang", "zap"]:
		var w: AudioStreamWAV = S.stream(n).duplicate()
		if n == "flame":            # three seconds of the loop to listen to
			var d := PackedByteArray(); for i in 3: d.append_array(w.data)
			w.data = d; w.loop_mode = AudioStreamWAV.LOOP_DISABLED
		w.save_to_wav(out + "/" + n + ".wav")
	quit()
