extends Node
## Procedural SFX — all sounds are synthesized into AudioStreamWAV buffers at
## startup (no binary assets, stays text-authorable for the no-PC pipeline).
## Player's own weapon/UI play non-positional; bots/zombies/deaths play in 3D.

const RATE := 22050

var _bank := {}          # name -> AudioStreamWAV
var _pool: Array = []    # non-positional AudioStreamPlayer round-robin
var _pi := 0

func _ready() -> void:
	_bank["shot"] = _make_shot()
	_bank["hit"] = _make_hit()
	_bank["hurt"] = _make_hurt()
	_bank["reload"] = _make_reload()
	_bank["die"] = _make_die()
	_bank["ui"] = _make_ui()
	_bank["boom"] = _make_boom()
	_bank["throw"] = _make_throw()
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p); _pool.append(p)

# ---- playback -------------------------------------------------------------
func play(name: String, vol_db: float = 0.0) -> void:
	if not Controls.sfx_on or not _bank.has(name):
		return
	var p: AudioStreamPlayer = _pool[_pi]
	_pi = (_pi + 1) % _pool.size()
	p.stream = _bank[name]; p.volume_db = vol_db; p.play()

func play_at(name: String, pos: Vector3, vol_db: float = 0.0) -> void:
	if not Controls.sfx_on or not _bank.has(name):
		return
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var p := AudioStreamPlayer3D.new()
	p.stream = _bank[name]; p.volume_db = vol_db
	p.unit_size = 8.0; p.max_distance = 60.0
	tree.current_scene.add_child(p)
	p.global_position = pos
	p.play()
	p.finished.connect(p.queue_free)

# ---- synthesis helpers ----------------------------------------------------
func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var v: float = clampf(samples[i], -1.0, 1.0)
		var s := int(v * 32767.0)
		if s < 0:
			s += 65536
		data[i * 2] = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	w.data = data
	return w

func _n(dur: float) -> int:
	return int(dur * RATE)

func _make_shot() -> AudioStreamWAV:
	var n := _n(0.16)
	var s := PackedFloat32Array(); s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 34.0)
		var noise := randf_range(-1.0, 1.0)
		var thump := sin(t * TAU * 90.0) * exp(-t * 22.0)
		s[i] = (noise * 0.8 + thump * 0.6) * env
	return _wav(s)

func _make_hit() -> AudioStreamWAV:
	var n := _n(0.07)
	var s := PackedFloat32Array(); s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 48.0)
		s[i] = sin(t * TAU * 1500.0) * env * 0.7
	return _wav(s)

func _make_hurt() -> AudioStreamWAV:
	var n := _n(0.18)
	var s := PackedFloat32Array(); s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 16.0)
		var f := 320.0 - t * 500.0
		s[i] = (sin(t * TAU * f) * 0.6 + randf_range(-1.0, 1.0) * 0.4) * env
	return _wav(s)

func _make_reload() -> AudioStreamWAV:
	var n := _n(0.30)
	var s := PackedFloat32Array(); s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var click := 0.0
		if t < 0.03:
			click = randf_range(-1.0, 1.0) * exp(-t * 120.0)
		elif t > 0.15 and t < 0.19:
			click = randf_range(-1.0, 1.0) * exp(-(t - 0.15) * 120.0)
		s[i] = click * 0.8
	return _wav(s)

func _make_die() -> AudioStreamWAV:
	var n := _n(0.34)
	var s := PackedFloat32Array(); s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 7.0)
		var f := 260.0 - t * 420.0
		s[i] = (sin(t * TAU * maxf(40.0, f)) * 0.7 + randf_range(-1.0, 1.0) * 0.3) * env
	return _wav(s)

func _make_ui() -> AudioStreamWAV:
	var n := _n(0.06)
	var s := PackedFloat32Array(); s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 30.0)
		s[i] = sin(t * TAU * 880.0) * env * 0.5
	return _wav(s)

func _make_boom() -> AudioStreamWAV:
	# low rumble + noise crack, long decay
	var n := _n(1.1)
	var s := PackedFloat32Array(); s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var noise := randf_range(-1.0, 1.0)
		lp = lp + (noise - lp) * 0.08              # low-passed noise = rumble
		var crack := noise * exp(-t * 30.0)
		var thump := sin(t * TAU * (55.0 - t * 25.0)) * exp(-t * 4.0)
		s[i] = clampf((lp * 2.2 + crack * 0.7 + thump * 0.9) * exp(-t * 2.6), -1.0, 1.0)
	return _wav(s)

func _make_throw() -> AudioStreamWAV:
	# short airy whoosh
	var n := _n(0.22)
	var s := PackedFloat32Array(); s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp = lp + (randf_range(-1.0, 1.0) - lp) * 0.25
		var env := sin(PI * t / 0.22)
		s[i] = lp * env * 0.9
	return _wav(s)
