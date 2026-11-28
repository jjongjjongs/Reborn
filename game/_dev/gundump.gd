extends SceneTree
func _initialize() -> void: _run()
func _run() -> void:
	await process_frame
	var S = root.get_node("Sfx"); var out: String = OS.get_cmdline_user_args()[0]
	for id in ["m4", "ak", "mp5", "shotgun", "sniper", "rpk", "pistol", "revolver"]:
		# the shot, (pump / bolt), then the reload: one file per gun to listen to
		var parts: Array = [S.stream("shot_" + id)]
		if id == "shotgun": parts.append(S.stream("pump"))
		if id == "sniper": parts.append(S.stream("bolt"))
		parts.append(S.stream("rel_" + id))
		var d := PackedByteArray()
		for p in parts:
			d.append_array((p as AudioStreamWAV).data)
			var gap := PackedByteArray(); gap.resize(int(22050 * 0.35) * 2); d.append_array(gap)
		var w := AudioStreamWAV.new(); w.format = AudioStreamWAV.FORMAT_16_BITS; w.mix_rate = 22050; w.data = d
		w.save_to_wav(out + "/gun_" + id + ".wav")
	quit()
