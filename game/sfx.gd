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
	_bank["step"] = _make_step(0)
	_bank["step2"] = _make_step(1)
	_bank["jump"] = _make_jump()
	_bank["land"] = _make_land()
	_bank["key"] = _make_tone(1480.0, 0.07, 0.0)        # bomb keypad while planting
	_bank["beep"] = _make_tone(2200.0, 0.11, 0.0)       # planted bomb tick
	_bank["armed"] = _make_tone(1200.0, 0.32, 1.6)      # rising chirp: bomb planted
	_bank["defuse"] = _make_click()                     # wire / tool clicks while defusing
	_bank["defused"] = _make_tone(900.0, 0.35, -0.6)    # falling tone: defused
	_bank["ding"] = _make_ding()                        # steel plate hit
	# zombie weapons
	_bank["axe_swing"] = _make_whoosh(0.28, 0.55)
	_bank["axe_hit"] = _make_chop()
	_bank["dbarrel"] = _make_boomstick()
	_bank["break"] = _make_break()
	_bank["flame"] = _make_flame()
	_bank["nail"] = _make_nail()
	_bank["twang"] = _make_twang()
	_bank["zap"] = _make_zap()
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

## positional: full volume within `unit` metres, fading with distance, silent past `max_d`
## (gunshots carry far, footsteps only nearby, the bomb beeps across a site)
const RANGE := {"shot": [9.0, 90.0], "boom": [14.0, 120.0], "step": [2.2, 24.0], "step2": [2.2, 24.0],
	"jump": [2.5, 24.0], "land": [2.5, 26.0], "key": [2.0, 30.0], "beep": [4.0, 70.0], "armed": [5.0, 80.0],
	"defuse": [2.0, 26.0], "defused": [5.0, 70.0], "ding": [8.0, 80.0]}
func play_at(name: String, pos: Vector3, vol_db: float = 0.0) -> void:
	if not Controls.sfx_on or not _bank.has(name):
		return
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var r: Array = RANGE.get(name, [8.0, 60.0])
	var cam := tree.root.get_viewport().get_camera_3d()
	if cam and cam.global_position.distance_to(pos) > float(r[1]): return
	var p := AudioStreamPlayer3D.new()
	p.stream = _bank[name]; p.volume_db = vol_db
	p.unit_size = float(r[0]); p.max_distance = float(r[1])
	p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	tree.current_scene.add_child(p)
	p.global_position = pos
	p.play()
	p.finished.connect(p.queue_free)

# ---- zombie weapons ----------------------------------------------------------
## one-pole low-pass over white noise: k small = darker
func _lp(s: PackedFloat32Array, k: float) -> PackedFloat32Array:
	var y := 0.0
	for i in s.size(): y += (s[i] - y) * k; s[i] = y
	return s

## heavy blade cutting the air: band of noise swelling and fading, pitch of the hiss rising through the swing
func _make_whoosh(dur: float, peak: float) -> AudioStreamWAV:
	var n := _n(dur); var s := PackedFloat32Array(); s.resize(n)
	var y := 0.0; var y2 := 0.0
	for i in n:
		var t := float(i) / RATE; var u := t / dur
		var env := pow(sin(PI * clampf(u / peak * 0.5 if u < peak else 0.5 + (u - peak) / (1.0 - peak) * 0.5, 0.0, 1.0)), 2.0)
		var k := 0.04 + 0.22 * u
		y += (randf_range(-1.0, 1.0) - y) * k; y2 += (y - y2) * k
		s[i] = (y - y2) * env * 3.2
	return _wav(s)

## axe biting in: low wet thud + short crack
func _make_chop() -> AudioStreamWAV:
	var n := _n(0.26); var s := PackedFloat32Array(); s.resize(n)
	var y := 0.0
	for i in n:
		var t := float(i) / RATE
		y += (randf_range(-1.0, 1.0) - y) * 0.25
		var thud := sin(t * TAU * (95.0 - t * 120.0)) * exp(-t * 18.0)
		var crack := randf_range(-1.0, 1.0) * exp(-t * 90.0)
		s[i] = thud * 0.9 + y * exp(-t * 26.0) * 0.8 + crack * 0.5
	return _wav(s)

## double barrel: a big boom - crack, low body, long rumbling tail
func _make_boomstick() -> AudioStreamWAV:
	var n := _n(0.65); var s := PackedFloat32Array(); s.resize(n)
	var y := 0.0
	for i in n:
		var t := float(i) / RATE
		y += (randf_range(-1.0, 1.0) - y) * (0.5 - 0.4 * minf(t / 0.3, 1.0))
		var crack := randf_range(-1.0, 1.0) * exp(-t * 60.0)
		var body := sin(t * TAU * (70.0 - t * 30.0)) * exp(-t * 9.0)
		s[i] = clampf(crack * 0.9 + y * exp(-t * 6.0) * 1.4 + body * 0.9, -1.0, 1.0)
	return _wav(s)

## break-action reload: lever clack + barrels dropping open, two shells thunking in, snapping shut
func _make_break() -> AudioStreamWAV:
	var n := _n(1.2); var s := PackedFloat32Array(); s.resize(n)
	var hits := [[0.0, 1.0, 2400.0], [0.06, 0.8, 900.0], [0.45, 0.5, 1300.0], [0.62, 0.5, 1250.0], [1.0, 1.0, 1800.0], [1.03, 0.6, 700.0]]
	for i in n:
		var t := float(i) / RATE; var v := 0.0
		for h in hits:
			var dt: float = t - float(h[0])
			if dt >= 0.0 and dt < 0.08:
				v += (randf_range(-1.0, 1.0) * 0.6 + sin(dt * TAU * float(h[2])) * 0.5) * exp(-dt * 70.0) * float(h[1])
		s[i] = v * 0.8
	return _wav(s)

## flamethrower: a seamless 1 s loop of low roaring noise with crackles (played looped while firing)
func _make_flame() -> AudioStreamWAV:
	var n := _n(1.0); var s := PackedFloat32Array(); s.resize(n)
	var y := 0.0; var y2 := 0.0
	for i in n:
		var t := float(i) / RATE
		y += (randf_range(-1.0, 1.0) - y) * 0.09; y2 += (y - y2) * 0.02
		var rumble := 0.75 + 0.25 * sin(t * TAU * 7.0) * sin(t * TAU * 3.0)
		var crackle := randf_range(-1.0, 1.0) * (1.0 if randf() < 0.004 else 0.0)
		s[i] = (y * 2.2 + y2 * 3.0) * rumble + crackle * 0.6
	var fade := _n(0.05)                   # cross-fade the ends so the loop has no click
	for i in fade:
		var a := float(i) / fade
		s[i] = s[i] * a + s[n - fade + i] * (1.0 - a)
	var w := _wav(s.slice(0, n - fade))
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD; w.loop_begin = 0; w.loop_end = n - fade
	return w

## nail gun: pneumatic "tchk" - a sharp metallic snap and a short burst of air
func _make_nail() -> AudioStreamWAV:
	var n := _n(0.14); var s := PackedFloat32Array(); s.resize(n)
	var y := 0.0
	for i in n:
		var t := float(i) / RATE
		y += (randf_range(-1.0, 1.0) - y) * 0.6
		var snap := (sin(t * TAU * 2600.0) * 0.5 + sin(t * TAU * 3900.0) * 0.3) * exp(-t * 110.0)
		var air := y * exp(-t * 35.0) * (1.0 if t > 0.01 else 0.3)
		var thud := sin(t * TAU * 180.0) * exp(-t * 60.0)
		s[i] = snap * 0.8 + air * 0.6 + thud * 0.5
	return _wav(s)

## crossbow: a string's twang - low plucked tone that drops a little, wood knock, quick air
func _make_twang() -> AudioStreamWAV:
	var n := _n(0.35); var s := PackedFloat32Array(); s.resize(n)
	var y := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := 140.0 * (1.0 + 0.6 * exp(-t * 30.0))
		var string := (sin(t * TAU * f) + 0.4 * sin(t * TAU * f * 2.0) + 0.2 * sin(t * TAU * f * 3.0)) * exp(-t * 11.0)
		y += (randf_range(-1.0, 1.0) - y) * 0.4
		var knock := sin(t * TAU * 320.0) * exp(-t * 80.0)
		s[i] = string * 0.6 + knock * 0.5 + y * exp(-t * 40.0) * 0.4
	return _wav(s)

## tesla: an electric crack - buzzing square-ish tone with random snaps, quick decay
func _make_zap() -> AudioStreamWAV:
	var n := _n(0.32); var s := PackedFloat32Array(); s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var buzz: float = sign(sin(t * TAU * (120.0 + 40.0 * sin(t * TAU * 30.0)))) * 0.35
		var hiss := randf_range(-1.0, 1.0) * 0.5
		var snap := randf_range(-1.0, 1.0) * (1.0 if randf() < 0.02 else 0.0)
		var crack := randf_range(-1.0, 1.0) * exp(-t * 70.0)
		s[i] = (buzz + hiss + snap) * exp(-t * 9.0) * 0.7 + crack * 0.8
	return _wav(s)

func stream(name: String) -> AudioStream:
	return _bank.get(name)

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

func _make_step(v: int) -> AudioStreamWAV:      # soft scuff + low thud (two variants)
	var n := _n(0.09)
	var s := PackedFloat32Array(); s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp = lerpf(lp, randf_range(-1.0, 1.0), 0.18 if v == 0 else 0.25)
		s[i] = (lp * 1.6 + sin(t * TAU * (70.0 + v * 15.0)) * 0.5) * exp(-t * 48.0) * 0.7
	return _wav(s)

func _make_jump() -> AudioStreamWAV:            # cloth whoosh
	var n := _n(0.18)
	var s := PackedFloat32Array(); s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp = lerpf(lp, randf_range(-1.0, 1.0), 0.08 + t * 0.6)
		s[i] = lp * 1.8 * sin(PI * t / 0.18) * 0.6
	return _wav(s)

func _make_land() -> AudioStreamWAV:            # heavier thud
	var n := _n(0.16)
	var s := PackedFloat32Array(); s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp = lerpf(lp, randf_range(-1.0, 1.0), 0.12)
		s[i] = (lp * 1.4 + sin(t * TAU * 55.0) * 0.9) * exp(-t * 30.0) * 0.8
	return _wav(s)

func _make_tone(f: float, dur: float, glide: float) -> AudioStreamWAV:   # electronic beep (glide: octaves over the tone)
	var n := _n(dur)
	var s := PackedFloat32Array(); s.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		ph += TAU * f * pow(2.0, glide * t / dur) / RATE
		var env := minf(1.0, t * 300.0) * minf(1.0, (dur - t) * 60.0)
		s[i] = (sin(ph) * 0.7 + sin(ph * 2.0) * 0.15) * env * 0.6
	return _wav(s)

func _make_ding() -> AudioStreamWAV:            # struck steel: inharmonic partials, long ring
	var n := _n(0.7)
	var s := PackedFloat32Array(); s.resize(n)
	for i in n:
		var t := float(i) / RATE
		s[i] = (sin(TAU * 1180.0 * t) * 0.5 + sin(TAU * 2950.0 * t) * 0.3 * exp(-t * 6.0) + sin(TAU * 4410.0 * t) * 0.15 * exp(-t * 10.0)) * exp(-t * 5.0) * 0.7
	return _wav(s)

func _make_click() -> AudioStreamWAV:
	var n := _n(0.05)
	var s := PackedFloat32Array(); s.resize(n)
	for i in n:
		var t := float(i) / RATE
		s[i] = (randf_range(-1.0, 1.0) * 0.6 + sin(t * TAU * 3200.0) * 0.4) * exp(-t * 120.0)
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
