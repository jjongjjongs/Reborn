extends Node3D
## 미니게임 · 점프맵 "구름 계단" (original course). Structure taken from how obby / KZ climb maps
## are built: a safe start pad + timer, five stages that each teach one thing before testing it,
## a green checkpoint after every stage (falling = back to the last checkpoint, never further),
## colour-coded blocks (orange normal / teal narrow / purple moving / blue bounce / yellow
## crumbling / gold finish), rest pads between hard parts, and the next goal always in sight.
## Player jump: 8 m/s up, 20 m/s² -> 1.6 m high, ~4 m far at full speed; gaps here are 1–2.5 m.

const KILL_Y := -9.0
const BOUNCE_V := 14.0
const STAGES := ["기초 점프", "좁은 길", "움직이는 발판", "사라지는 발판", "정상 탑"]
const COL := {"start": Color("e9e4d8"), "s1": Color("ff9a3c"), "s2": Color("3cc6c0"), "move": Color("9b6cf0"),
	"bounce": Color("3a8dff"), "crumb": Color("ffd23c"), "cp": Color("2fbf5b"), "s5": Color("f4efe6"), "gold": Color("ffc83a")}

var player: PlayerBody
var cam: Camera3D
var _cp := 0                       # last checkpoint reached (0 = start)
var _cps: Array = []               # [centre Vector3 (top), half size Vector2, name]
var _movers: Array = []            # [body, a, b, period, phase]
var _bounce: Array = []            # [centre top, half size]
var _crumbs: Array = []            # [body, mesh, state, t]
var _goal := Vector3.ZERO
var _t := -1.0                     # run time (-1 = not started)
var _falls := 0
var _done := false
var _hud: Label
var _sub: Label
var _toast: Label
var _toast_t := 0.0
var _time := 0.0
var _touch: Control

func _ready() -> void:
	Controls.sel_map = "jump1"
	_env()
	_course()
	player = PlayerBody.new()
	player.position = Vector3(0, 1.0, 2.0)
	add_child(player)
	cam = Camera3D.new(); cam.fov = 65.0; cam.current = true
	add_child(cam)
	_build_hud()
	Pause.arm()
	await get_tree().physics_frame
	await get_tree().physics_frame
	if player.has_method("_equip"): player._equip(2, true)     # knife out: hands free, full speed

# ---------------------------------------------------------------- world
func _env() -> void:
	var we := WorldEnvironment.new(); var e := Environment.new()
	var sky := Sky.new(); var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("4f8fe0"); sm.sky_horizon_color = Color("bcd8f5")
	sm.ground_horizon_color = Color("d9e8f7"); sm.ground_bottom_color = Color("eaf2fb")
	sky.sky_material = sm; e.sky = sky; e.background_mode = Environment.BG_SKY
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color("aab8cc"); e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.fog_enabled = true; e.fog_light_color = Color("cfe0f2"); e.fog_density = 0.0016; e.fog_sky_affect = 0.0
	we.environment = e; add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_energy = 1.0; sun.shadow_enabled = true; add_child(sun)
	# sea of clouds far below (the fall zone)
	var cl := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(600, 600); cl.mesh = pm
	var cm := StandardMaterial3D.new(); cm.albedo_color = Color("dfeaf6"); cm.roughness = 1.0
	cl.material_override = cm; cl.position = Vector3(0, -28, -60); add_child(cl)
	for i in 40:                                  # puffy cloud lumps
		var m := MeshInstance3D.new(); var s := SphereMesh.new()
		var r := randf_range(4.0, 9.0); s.radius = r; s.height = r * 1.1; m.mesh = s; m.material_override = cm
		m.position = Vector3(randf_range(-80, 80), -28.5, randf_range(-180, 50)); add_child(m)

func _mat(c: Color, glow := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = c; m.roughness = 0.55
	if glow > 0.0: m.emission_enabled = true; m.emission = c; m.emission_energy_multiplier = glow
	return m

## a block whose TOP is at `top` (centre x/z), size (x, h, z); returns [body, mesh]
func _block(top: Vector3, size: Vector3, c: Color, body: PhysicsBody3D = null, glow := 0.0) -> Array:
	var b: PhysicsBody3D = body if body else StaticBody3D.new()
	b.position = top - Vector3(0, size.y * 0.5, 0)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = size; mi.mesh = bm
	mi.material_override = _mat(c, glow); b.add_child(mi)
	var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = size; cs.shape = sh; b.add_child(cs)
	# darker rim so the edge reads against the sky
	var rim := MeshInstance3D.new(); var rb := BoxMesh.new(); rb.size = Vector3(size.x + 0.04, 0.08, size.z + 0.04); rim.mesh = rb
	rim.material_override = _mat(c.darkened(0.35)); rim.position = Vector3(0, size.y * 0.5 - 0.04, 0); b.add_child(rim)
	add_child(b)
	return [b, mi]

func _sign(p: Vector3, text: String, c := Color.WHITE, size := 54) -> Label3D:
	var l := Label3D.new(); l.text = text; l.font_size = size; l.pixel_size = 0.012; l.modulate = c
	l.outline_size = 14; l.outline_modulate = Color(0, 0, 0, 0.7); l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	l.position = p; add_child(l); return l

func _checkpoint(top: Vector3, hx: float, hz: float, name: String) -> void:
	_block(top, Vector3(hx * 2, 0.6, hz * 2), COL["cp"].darkened(0.15))
	var pole := MeshInstance3D.new(); var cy := CylinderMesh.new(); cy.top_radius = 0.06; cy.bottom_radius = 0.06; cy.height = 2.6
	pole.mesh = cy; pole.material_override = _mat(Color("e8e8e8")); pole.position = top + Vector3(hx - 0.4, 1.3, -hz + 0.4); add_child(pole)
	var flag := MeshInstance3D.new(); var fb := BoxMesh.new(); fb.size = Vector3(0.9, 0.55, 0.04); flag.mesh = fb
	flag.material_override = _mat(COL["cp"], 0.4); flag.position = top + Vector3(hx - 0.4 - 0.47, 2.3, -hz + 0.4); add_child(flag)
	_cps.append([top, Vector2(hx, hz), name, _sign(top + Vector3(0, 3.0, -hz + 0.3), name, Color("bff5d0"), 44)])

func _course() -> void:
	# ---- start pad (timer starts when you leave it) ----
	_block(Vector3(0, 0, 0), Vector3(8, 1.0, 8), COL["start"])
	_cps.append([Vector3(0, 0, 0), Vector2(4, 4), "출발"])
	_sign(Vector3(0, 3.0, -3.6), "구름 계단 · START", Color("ffe2b8"), 60)
	# ---- stage 1: plain jumps, small gaps and steps up (teach the jump) ----
	for b in [[0, 0.0, -7.0, 3.0], [0, 0.5, -11.0, 3.0], [2.5, 1.0, -15.0, 2.6], [0.2, 1.5, -19.5, 3.0]]:
		_block(Vector3(b[0], b[1], b[2]), Vector3(b[3], 1.0, b[3]), COL["s1"])
	_checkpoint(Vector3(0, 1.5, -25.0), 2.5, 2.0, "체크포인트 1 · 좁은 길")
	# ---- stage 2: narrow beams (zig-zag), then rising posts ----
	_block(Vector3(0, 1.5, -30.0), Vector3(0.7, 0.6, 6.0), COL["s2"])
	_block(Vector3(2.75, 1.5, -33.35), Vector3(6.2, 0.6, 0.7), COL["s2"])
	_block(Vector3(5.5, 1.5, -36.7), Vector3(0.7, 0.6, 6.0), COL["s2"])
	for b in [[5.5, 2.0, -42.0], [3.5, 2.6, -44.6], [1.5, 3.2, -47.2], [-0.5, 3.8, -49.8]]:
		_block(Vector3(b[0], b[1], b[2]), Vector3(1.3, 1.0, 1.3), COL["s2"])
	_checkpoint(Vector3(-0.5, 3.8, -54.5), 2.5, 2.0, "체크포인트 2 · 움직이는 발판")
	# ---- stage 3: moving platforms, then a bounce pad up to a high ledge ----
	_mover(Vector3(-3.5, 3.8, -59.5), Vector3(3.5, 3.8, -59.5), 3.2, 0.0)
	_mover(Vector3(0.0, 3.8, -63.0), Vector3(0.0, 3.8, -67.5), 2.8, 1.4)
	_block(Vector3(0, 3.8, -71.5), Vector3(3.2, 1.0, 3.2), COL["s1"])
	_block(Vector3(0, 3.82, -71.5), Vector3(2.2, 0.06, 2.2), COL["bounce"], null, 0.5)
	_bounce.append([Vector3(0, 3.8, -71.5), Vector2(1.6, 1.6)])
	_sign(Vector3(0, 5.6, -71.5), "점프대 ↑", Color("bcd9ff"), 40)
	_block(Vector3(0, 7.8, -75.8), Vector3(4.0, 1.0, 3.0), COL["s1"])
	_checkpoint(Vector3(0, 7.8, -80.2), 2.5, 2.0, "체크포인트 3 · 사라지는 발판")
	# ---- stage 4: crumbling tiles (shake, fall, come back) ----
	for b in [[1.2, -84.6], [-1.2, -88.4], [1.0, -92.2], [-0.8, -96.0], [0.6, -99.8]]:
		_crumb(Vector3(b[0], 7.8, b[1]))
	_checkpoint(Vector3(0, 7.8, -104.4), 2.5, 2.0, "체크포인트 4 · 정상 탑")
	# ---- stage 5: spiral pads round the summit tower ----
	var c := Vector3(0, 0, -113.0)
	var pil := MeshInstance3D.new(); var cy := CylinderMesh.new(); cy.top_radius = 2.2; cy.bottom_radius = 2.6; cy.height = 30.0
	pil.mesh = cy; pil.material_override = _mat(Color("a89c88")); pil.position = c + Vector3(0, 15.6 - 15.0, 0); add_child(pil)
	var pb := StaticBody3D.new(); var pcs := CollisionShape3D.new(); var psh := CylinderShape3D.new(); psh.radius = 2.2; psh.height = 30.0
	pcs.shape = psh; pb.add_child(pcs); pb.position = pil.position; add_child(pb)
	for i in 11:
		var a := deg_to_rad(-45.0 * i)
		var p := c + Vector3(sin(a) * 4.6, 8.4 + 0.62 * i, cos(a) * 4.6)
		_block(p, Vector3(1.8, 0.5, 1.8), COL["s5"] if i % 2 == 0 else COL["s1"])
	# finish: the top of the tower
	_goal = c + Vector3(0, 15.6, 0)
	var gm := MeshInstance3D.new(); var tm := TorusMesh.new(); tm.inner_radius = 1.5; tm.outer_radius = 1.75
	gm.mesh = tm; gm.material_override = _mat(COL["gold"], 0.8); gm.rotation_degrees = Vector3(90, 0, 0)
	gm.position = _goal + Vector3(0, 2.0, 0); add_child(gm)
	var top := MeshInstance3D.new(); var tc := CylinderMesh.new(); tc.top_radius = 2.25; tc.bottom_radius = 2.25; tc.height = 0.12
	top.mesh = tc; top.material_override = _mat(COL["gold"], 0.3); top.position = _goal + Vector3(0, 0.06, 0); add_child(top)
	_sign(_goal + Vector3(0, 4.2, 0), "FINISH", Color("ffe08a"), 70)

func _mover(a: Vector3, b: Vector3, period: float, phase: float) -> void:
	var body := AnimatableBody3D.new(); body.sync_to_physics = true
	_block(a, Vector3(3.0, 0.8, 3.0), COL["move"], body)
	_movers.append([body, a - Vector3(0, 0.4, 0), b - Vector3(0, 0.4, 0), period, phase])

func _crumb(top: Vector3) -> void:
	var r := _block(top, Vector3(2.2, 0.5, 2.2), COL["crumb"])
	_crumbs.append([r[0], r[1], 0, 0.0, top])     # state 0 solid / 1 shaking / 2 gone

# ---------------------------------------------------------------- play
func _physics_process(dt: float) -> void:
	_time += dt
	for m in _movers:
		var k := 0.5 - 0.5 * cos(TAU * (_time + float(m[4])) / float(m[3]))
		(m[0] as Node3D).global_position = (m[1] as Vector3).lerp(m[2], k)
	if player == null: return
	var p := player.global_position
	var on_floor := player.is_on_floor()
	# bounce pads
	for b in _bounce:
		if on_floor and absf(p.x - b[0].x) < b[1].x and absf(p.z - b[0].z) < b[1].y and absf(p.y - b[0].y) < 0.3:
			player.velocity.y = BOUNCE_V
			Sfx.play("ui")
	# crumbling tiles: shake 0.6 s after you land, gone for 2.5 s
	for c in _crumbs:
		var top: Vector3 = c[4]
		if c[2] == 0 and on_floor and absf(p.x - top.x) < 1.15 and absf(p.z - top.z) < 1.15 and absf(p.y - top.y) < 0.3:
			c[2] = 1; c[3] = 0.6
		elif c[2] == 1:
			c[3] -= dt
			(c[1] as Node3D).position = Vector3(randf_range(-0.04, 0.04), 0, randf_range(-0.04, 0.04))
			if c[3] <= 0.0:
				c[2] = 2; c[3] = 2.5; (c[0] as Node3D).visible = false
				((c[0] as Node).get_child(1) as CollisionShape3D).set_deferred("disabled", true)
		elif c[2] == 2:
			c[3] -= dt
			if c[3] <= 0.0:
				c[2] = 0; (c[0] as Node3D).visible = true; (c[1] as Node3D).position = Vector3.ZERO
				((c[0] as Node).get_child(1) as CollisionShape3D).set_deferred("disabled", false)
	if _done: return
	# timer: starts the moment you leave the start pad
	if _t < 0.0 and (absf(p.x) > 4.0 or absf(p.z) > 4.0): _t = 0.0
	if _t >= 0.0: _t += dt
	# checkpoints (checked by position every frame, so a fast run can't skip one)
	for i in range(_cp + 1, _cps.size()):
		var cp: Array = _cps[i]
		var ct: Vector3 = cp[0]
		if absf(p.x - ct.x) <= cp[1].x and absf(p.z - ct.z) <= cp[1].y and p.y > ct.y - 0.3 and p.y < ct.y + 2.0:
			_cp = i; _show_toast("✓ " + String(cp[2]).split(" · ")[0]); Sfx.play("reload")
			for j in range(1, i + 1):           # signs of reached checkpoints go away (no overlap with the next)
				if (_cps[j] as Array).size() > 3: (_cps[j][3] as Node3D).visible = false
	# fall -> last checkpoint
	if p.y < KILL_Y:
		_falls += 1
		_respawn()
	# finish
	if Vector2(p.x - _goal.x, p.z - _goal.z).length() < 2.2 and p.y > _goal.y - 0.3:
		_finish()

func _respawn() -> void:
	var cp: Array = _cps[_cp]
	player.velocity = Vector3.ZERO
	player.global_position = (cp[0] as Vector3) + Vector3(0, 1.0, 0)
	if _cp == 0: _t = -1.0

func _process(_dt: float) -> void:
	if player: CamRig.follow(cam, player)
	var stage := clampi(_cp + 1, 1, 5)
	var best := float(Profile._d.get("best_jump1", 0.0))
	if _hud:
		_hud.text = "%s  ·  %d / 5 %s  ·  낙하 %d" % [_fmt(maxf(_t, 0.0)), stage, STAGES[stage - 1], _falls]
		_sub.text = "최고 기록 %s  ·  떨어지면 마지막 체크포인트에서 다시 시작" % (_fmt(best) if best > 0.0 else "-")
	if _toast_t > 0.0:
		_toast_t -= _dt
		_toast.modulate.a = clampf(_toast_t, 0.0, 1.0)

func _fmt(s: float) -> String:
	return "%d:%04.1f" % [int(s) / 60, fmod(s, 60.0)]

func _show_toast(t: String) -> void:
	_toast.text = t; _toast_t = 1.8

func _finish() -> void:
	_done = true
	var best := float(Profile._d.get("best_jump1", 0.0))
	var new_best := best <= 0.0 or _t < best
	if new_best: Profile._d["best_jump1"] = _t; Profile.save()
	Missions.record("미니게임 · 점프맵", "구름 계단", "완주 %s · 낙하 %d" % [_fmt(_t), _falls], true, "", 0)
	Sfx.play("reload")
	var layer := CanvasLayer.new(); layer.layer = 40; add_child(layer)
	var bg := ColorRect.new(); bg.color = Color(0.02, 0.03, 0.05, 0.72); bg.set_anchors_preset(Control.PRESET_FULL_RECT); layer.add_child(bg)
	var v := VBoxContainer.new(); v.set_anchors_preset(Control.PRESET_CENTER); v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.position = Vector2(-260, -170); v.size = Vector2(520, 340); v.add_theme_constant_override("separation", 14); layer.add_child(v)
	for row in [["완주!", 56, Color("ffd36b")], ["기록 %s%s" % [_fmt(_t), "  · 최고 기록!" if new_best else ""], 32, Color.WHITE],
			["낙하 %d회 · 최고 %s" % [_falls, _fmt(minf(_t, best) if best > 0.0 else _t)], 24, Color(1, 1, 1, 0.7)]]:
		var l := Label.new(); l.text = row[0]; l.add_theme_font_size_override("font_size", row[1]); l.add_theme_color_override("font_color", row[2])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(l)
	var hb := HBoxContainer.new(); hb.alignment = BoxContainer.ALIGNMENT_CENTER; hb.add_theme_constant_override("separation", 16); v.add_child(hb)
	for b in [["다시 하기", "again"], ["메뉴로", "menu"]]:
		var bt := Button.new(); bt.text = b[0]; bt.custom_minimum_size = Vector2(200, 64); bt.add_theme_font_size_override("font_size", 26)
		bt.focus_mode = Control.FOCUS_NONE
		var what: String = b[1]
		bt.pressed.connect(func() -> void:
			Sfx.play("ui")
			if what == "again": get_tree().reload_current_scene()
			else: get_tree().change_scene_to_file("res://Menu.tscn"))
		hb.add_child(bt)
	if _touch: _touch.visible = false          # result window: no control buttons over it

func _build_hud() -> void:
	var layer := CanvasLayer.new(); add_child(layer)
	var touch := TouchInput.new(); touch.set_anchors_preset(Control.PRESET_FULL_RECT); touch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	touch.move_only = true                     # no weapons here: stick + a big jump button
	layer.add_child(touch); _touch = touch
	_hud = Label.new(); _hud.add_theme_font_size_override("font_size", 32)
	_hud.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	_hud.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75)); _hud.add_theme_constant_override("outline_size", 8)
	_hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _hud.anchor_right = 1.0; _hud.offset_top = 18
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE; layer.add_child(_hud)
	_sub = Label.new(); _sub.add_theme_font_size_override("font_size", 17); _sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	_sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6)); _sub.add_theme_constant_override("outline_size", 6)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _sub.anchor_right = 1.0; _sub.offset_top = 60
	_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE; layer.add_child(_sub)
	_toast = Label.new(); _toast.add_theme_font_size_override("font_size", 40); _toast.add_theme_color_override("font_color", Color("7dffa8"))
	_toast.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8)); _toast.add_theme_constant_override("outline_size", 10)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _toast.anchor_right = 1.0; _toast.offset_top = 150
	_toast.modulate.a = 0.0; _toast.mouse_filter = Control.MOUSE_FILTER_IGNORE; layer.add_child(_toast)
	# back to the last checkpoint (stuck / want a retry)
	var rb := Button.new(); rb.text = "↺ 체크포인트"; rb.focus_mode = Control.FOCUS_NONE
	rb.add_theme_font_size_override("font_size", 20); rb.anchor_left = 1.0; rb.anchor_right = 1.0
	rb.offset_left = -360; rb.offset_right = -200; rb.offset_top = 16; rb.offset_bottom = 64
	rb.pressed.connect(func() -> void: Sfx.play("ui"); _respawn()); layer.add_child(rb)
