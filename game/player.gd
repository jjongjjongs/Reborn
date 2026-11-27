class_name PlayerBody
extends CharacterBody3D
## M1 player: aim-relative movement, look (yaw/pitch), hitscan shooting with
## dynamic accuracy, ammo + reload. Built in code.

const SPEED := 5.0
const JUMP_VELOCITY := 8.0
const GRAVITY := 20.0

# weapon stats come from Weapons (weapons.gd); these are shared rules
const HEAD_MULT := 2.5
const CRIT_CHANCE := 0.08
const CRIT_MULT := 1.8
const BLOOM_RECOVER := 7.0   # deg/sec

signal died(attacker)

const INVULN := 2.0

var alive := true
var invuln_t := 0.0
var team := -1   # -1 = FFA; 0/1 = teams
var _spawn := Vector3.ZERO

var aim_yaw := 0.0     # degrees
var aim_pitch := 0.0   # degrees (camera only)
var _bloom := 0.0
var _ammo := {}            # weapon id -> rounds in the mag
var _swap_t := 0.0
var _fire_was := false
var _steps := Footsteps.new()     # for semi-auto (one shot per press)
var scope_k := 0.0         # 0..1 scope blend (modes read it for the camera)
var _fire_cd := 0.0
var _reload_t := 0.0
var _muzzle: Node3D
var _soldier: Soldier
var _col: CollisionShape3D
var _shape: CapsuleShape3D
var crouched := false
var eye_h := 1.4          # camera pivot height (modes read this)
var aim_h := 1.1          # where bots aim (chest)
var _aim: GrenadeAim
const CROUCH_SPEED := 0.5
const CROUCH_SPREAD := 0.6
const THROW_UP_DEG := 14.0
# grenade aiming: vertical drag changes the throw angle (= range), not the camera
const NADE_PITCH_MIN := -15.0
const NADE_PITCH_MAX := 45.0      # 45 deg = farthest throw
const NADE_PITCH_SENS := 0.6
var nade_pitch := 0.0
var frozen := false        # round prep (bomb defusal): look around only
var _nade_was := false
var _auto_scope := false
var _was_scoped := false   # scoped by holding fire (sniper hold-to-scope); shoot + scope out on release

func _ready() -> void:
	# never inherit a 'platform' velocity from a body we stood on (e.g. another character that respawned far away)
	platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_DO_NOTHING
	add_to_group("combatant")
	_build()
	_spawn = global_position
	face(Vector3.ZERO)
	face_open.call_deferred()
	Controls.hp = Controls.hp_max
	for i in 3:
		var id: String = Controls.loadout[i]
		_ammo[id] = _mag_of(id)
	_equip(Controls.slot, true)

func _wid() -> String:
	return Controls.weapon_id

func _mag_of(id: String) -> int:
	var m := int(Weapons.get_w(id)["mag"])
	return m + Controls.mag_bonus if m > 0 else 0

func _equip(slot: int, instant := false) -> void:
	Controls.slot = slot
	Controls.weapon_id = Controls.loadout[slot]
	Controls.scoped = false
	_reload_t = 0.0; Controls.reloading = false
	_swap_t = 0.0 if instant else Weapons.SWAP_TIME
	Controls.swapping = _swap_t > 0.0
	if _soldier: _soldier.set_weapon(Controls.weapon_id)
	_sync_hud()

func _sync_hud() -> void:
	for i in 3:
		var id: String = Controls.loadout[i]
		Controls.slot_ammo[i] = int(_ammo.get(id, 0))
		Controls.slot_mag[i] = _mag_of(id)
	Controls.ammo = int(_ammo.get(_wid(), 0))
	Controls.ammo_max = _mag_of(_wid())

func hit(dmg: int, _is_head: bool = false, attacker = null) -> void:
	if not alive or invuln_t > 0.0:
		return
	if attacker != null and team != -1 and "team" in attacker and attacker.team == team:
		return   # no friendly fire
	Controls.hp = maxi(0, Controls.hp - dmg)
	Fx.hurt()
	Sfx.play("hurt")
	Controls.vibrate(120)
	if Controls.hp <= 0:
		alive = false
		_cancel_nade()
		if _soldier: _soldier.set_dead(true)
		Sfx.play("die")
		Profile.bump("deaths")
		died.emit(attacker)

func take_damage(dmg: int) -> void:   # melee convenience (zombies)
	hit(dmg, false, null)

# turn the view toward a point (spawns face the middle of the map, not a wall)
func face(target: Vector3) -> void:
	var d := target - global_position
	if Vector2(d.x, d.z).length() < 0.5: return
	aim_yaw = rad_to_deg(atan2(-d.x, -d.z))
	aim_pitch = 0.0
	rotation.y = deg_to_rad(aim_yaw)

# look down the longest open line of sight (leaning toward the map centre), so a
# spawn in a side street starts looking along the street, not into a wall
func face_open() -> void:
	if not is_inside_tree(): return
	var space := get_world_3d().direct_space_state
	var eye := global_position + Vector3(0, 0.6, 0)
	var to_mid := Vector3(-global_position.x, 0, -global_position.z).normalized()
	var best := -1e9; var best_d := Vector3.ZERO
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(sin(a), 0, cos(a))
		var q := PhysicsRayQueryParameters3D.create(eye, eye + d * 40.0)
		q.exclude = [get_rid()]
		var h := space.intersect_ray(q)
		var dist := 40.0 if h.is_empty() else eye.distance_to(h["position"])
		var score := minf(dist, 30.0) + 6.0 * d.dot(to_mid)
		if score > best: best = score; best_d = d
	if best_d != Vector3.ZERO: face(global_position + best_d * 10.0)

func respawn_at(pos: Vector3) -> void:
	alive = true
	invuln_t = INVULN
	Controls.hp = Controls.hp_max
	global_position = pos
	face(Vector3.ZERO)
	face_open()
	velocity = Vector3.ZERO
	visible = true
	Controls.grenades = Controls.NADE_MAX
	for i in 3:
		_ammo[Controls.loadout[i]] = _mag_of(Controls.loadout[i])
	_equip(Controls.slot, true)
	_set_crouch(false)
	if _soldier: _soldier.set_dead(false)

func _build() -> void:
	_soldier = Soldier.new()
	add_child(_soldier)
	_soldier.cosmetic = true
	_soldier.body = Profile.equipped("body").substr(5); _soldier.gear = Profile.equipped("gear").substr(5)
	_soldier.setup(Profile.suit_color(), Profile.kit_color())
	_muzzle = Node3D.new(); _muzzle.position = Vector3(0.22, 1.3, -0.5)
	add_child(_muzzle)
	_col = CollisionShape3D.new()
	_shape = CapsuleShape3D.new(); _shape.radius = 0.4; _shape.height = 2.15
	_col.shape = _shape; _col.position = Vector3(0, 1.075, 0)
	add_child(_col)
	_aim = GrenadeAim.new()
	add_child(_aim)

func _set_crouch(c: bool) -> void:
	crouched = c
	Controls.crouched = c
	# lower hitbox while crouched (cover actually hides you)
	_shape.height = 1.4 if c else 2.15
	_col.position = Vector3(0, 0.7 if c else 1.075, 0)
	aim_h = 0.75 if c else 1.1
	if _soldier: _soldier.set_crouch(c)

func _cancel_nade() -> void:
	Controls.nade_aiming = false
	Controls.consume_throw()
	if _aim: _aim.visible = false
	if _soldier: _soldier.windup(false)

func _throw_origin_vel() -> Array:
	var b := Basis.from_euler(Vector3(deg_to_rad(nade_pitch), deg_to_rad(aim_yaw), 0))
	var dir := -b.z
	var origin := global_position + Vector3(0, 1.55 if not crouched else 1.05, 0) \
		+ global_transform.basis.x * 0.25 + dir * 0.35
	return [origin, dir * Grenade.SPEED]

func _physics_process(delta: float) -> void:
	if not alive:
		return
	if invuln_t > 0.0:
		invuln_t -= delta
		visible = fmod(invuln_t, 0.2) < 0.1
		if invuln_t <= 0.0:
			visible = true
	# look
	if alive and not frozen: Profile.bump("time", delta)
	var l := Controls.consume_look()
	if scope_k > 0.5: l *= Controls.scope_sens      # own sensitivity through the scope
	aim_yaw -= l.x
	var nade_now := Controls.nade_aiming and Controls.grenades > 0
	if nade_now and not _nade_was:
		nade_pitch = clampf(aim_pitch + THROW_UP_DEG, NADE_PITCH_MIN, NADE_PITCH_MAX)
	_nade_was = nade_now
	if nade_now:
		nade_pitch = clampf(nade_pitch - l.y * NADE_PITCH_SENS, NADE_PITCH_MIN, NADE_PITCH_MAX)
	else:
		aim_pitch = clampf(aim_pitch - l.y, -45.0, 45.0)
	rotation.y = deg_to_rad(aim_yaw)

	# move (aim-relative)
	var inp := Controls.move
	var fwd := -transform.basis.z
	var right := transform.basis.x
	var dir := (right * inp.x + fwd * (-inp.y))
	dir.y = 0.0
	if dir.length() > 1.0:
		dir = dir.normalized()
	var spd := 0.0 if frozen else SPEED * Controls.speed_mult * (CROUCH_SPEED if crouched else 1.0) \
		* float(Weapons.get_w(_wid())["speed"]) * (0.6 if Controls.scoped else 1.0)
	velocity.x = dir.x * spd
	velocity.z = dir.z * spd
	if Controls.consume_crouch():
		_set_crouch(not crouched)
	if is_on_floor():
		if Controls.consume_jump() and not frozen:
			if crouched: _set_crouch(false)     # jump while crouched = stand up
			else:
				velocity.y = JUMP_VELOCITY
				_steps.jumped(self, true)
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()
	_steps.update(self, delta, true)

	# weapon swap (HUD chip) / scope toggle
	var sw := Controls.consume_swap()
	if sw >= 0 and sw != Controls.slot:
		_equip(sw)
	if _swap_t > 0.0:
		_swap_t -= delta
		if _swap_t <= 0.0: Controls.swapping = false
	var w := Weapons.get_w(_wid())
	var melee := Weapons.is_melee(_wid())
	if Controls.consume_scope() and w.has("scope"):
		Controls.scoped = not Controls.scoped
	if Controls.scoped != _was_scoped:
		_was_scoped = Controls.scoped
		_keep_aim(Controls.scoped)
	scope_k = move_toward(scope_k, 1.0 if Controls.scoped and alive else 0.0, delta * 6.0)

	# reload
	if _reload_t > 0.0:
		_reload_t -= delta
		if _reload_t <= 0.0:
			_ammo[_wid()] = _mag_of(_wid())
			Controls.reloading = false
			_sync_hud()
	elif Controls.consume_reload() and not melee and int(_ammo.get(_wid(), 0)) < _mag_of(_wid()):
		_start_reload()

	# grenade: hold = aim + trajectory preview, release = throw
	eye_h = lerpf(eye_h, 1.0 if crouched else 1.4, minf(1.0, delta * 10.0))
	var nade_aim := Controls.nade_aiming and Controls.grenades > 0
	if nade_aim:
		var ov: Array = _throw_origin_vel()
		var sim := Grenade.simulate(get_world_3d().direct_space_state, ov[0], ov[1], [get_rid()])
		_aim.show_path(sim["points"], sim["hit"], sim["landed"], Controls.nade_over_cancel)
		_soldier.windup(true)
	else:
		_aim.visible = false
		_soldier.windup(false)
	if Controls.consume_throw() and Controls.grenades > 0:
		var ov2: Array = _throw_origin_vel()
		Grenade.spawn(get_tree().current_scene, ov2[0], ov2[1], self)
		Controls.grenades -= 1
		Controls.nade_aiming = false
		_aim.visible = false
		_soldier.throw()
		Sfx.play("throw")

	# fire (not while holding a grenade / swapping)
	_fire_cd = maxf(0.0, _fire_cd - delta)
	var pressed := Controls.fire_held and not _fire_was
	var released := _fire_was and not Controls.fire_held
	_fire_was = Controls.fire_held
	var want_fire := Controls.fire_held if (melee or bool(w.get("auto", false))) else pressed
	var unscope_after := false
	if Controls.sniper_hold and w.has("scope") and not melee:
		# hold fire = look through the scope, let go = shoot, then the scope closes
		want_fire = false
		if pressed and not Controls.scoped and not frozen and not nade_aim and _reload_t <= 0.0 and _swap_t <= 0.0:
			Controls.scoped = true; _auto_scope = true
		elif pressed and Controls.scoped and not _auto_scope:
			want_fire = true; unscope_after = true      # scoped with the scope key: a tap shoots
		if released and _auto_scope:
			_auto_scope = false
			want_fire = true; unscope_after = true
		if not Controls.scoped: _auto_scope = false
	if want_fire and not frozen and not nade_aim and _fire_cd <= 0.0 and _reload_t <= 0.0 and _swap_t <= 0.0:
		if melee:
			_stab()
			_fire_cd = Weapons.interval(_wid())
		elif int(_ammo.get(_wid(), 0)) > 0:
			_shoot(w)
			_fire_cd = Weapons.interval(_wid())
		else:
			_start_reload()
	if unscope_after: Controls.scoped = false

	# dynamic spread
	var moving := inp.length() > 0.1
	var sp_min: float = w.get("spread", [1.0, 1.0])[0]
	var sp_max: float = w.get("spread", [1.0, 1.0])[1]
	_bloom = maxf(0.0, _bloom - BLOOM_RECOVER * delta)
	var sp := sp_min + (2.0 if moving else 0.0) + _bloom
	if crouched: sp *= CROUCH_SPREAD
	sp = clampf(sp, sp_min * (CROUCH_SPREAD if crouched else 1.0), sp_max)
	if w.has("spread_scoped"):
		sp = lerpf(sp, float(w["spread_scoped"]) + (1.5 if moving else 0.0), scope_k)
	Controls.spread_deg = 0.0 if melee else sp

	# animation
	if _soldier:
		var hspeed := Vector2(velocity.x, velocity.z).length()
		var ratio := hspeed / (SPEED * maxf(0.1, Controls.speed_mult) * (CROUCH_SPEED if crouched else 1.0))
		_soldier.visible = scope_k < 0.5 and not Controls.view_fp   # scoped / 1인칭: no own body
		_soldier.drive(ratio, Controls.fire_held or _reload_t > 0.0)

# the shoulder camera and the scope look from different spots: re-aim so the scope
# opens (and closes) on exactly the point that was under the crosshair
func _keep_aim(to_scope: bool) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null or Controls.view_fp: return
	var from := cam.global_position
	var to := from - cam.global_transform.basis.z * 300.0
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [get_rid()]
	var h := get_world_3d().direct_space_state.intersect_ray(q)
	var t: Vector3 = h["position"] if h else to
	CamRig.match_aim(self, t, 1.0 if to_scope else 0.0)

func _start_reload() -> void:
	if Weapons.is_melee(_wid()): return
	Controls.scoped = false
	_reload_t = float(Weapons.get_w(_wid())["reload"]) * Controls.reload_mult
	Controls.reloading = true
	Sfx.play("reload")

func _shoot(w: Dictionary) -> void:
	_ammo[_wid()] = int(_ammo[_wid()]) - 1
	_sync_hud()
	Sfx.play("shot", -3.0)
	BotPlayer.noise(global_position, self)
	if _soldier: _soldier.shoot()
	_bloom = minf(_bloom + float(w["bloom"]), float(w["spread"][1]))
	aim_pitch = clampf(aim_pitch + float(w["kick"]) * (0.5 if scope_k > 0.5 else 1.0), -45.0, 45.0)
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var from := cam.global_position
	var fwd := -cam.global_transform.basis.z
	var space := get_world_3d().direct_space_state
	var s := deg_to_rad(Controls.spread_deg)
	var any_hit := false
	var last_end := from + fwd * 200.0
	for p in int(w.get("pellets", 1)):
		var dir := fwd.rotated(cam.global_transform.basis.x, randf_range(-s, s))
		dir = dir.rotated(cam.global_transform.basis.y, randf_range(-s, s))
		var to := from + dir * 200.0
		var q := PhysicsRayQueryParameters3D.create(from, to)
		q.exclude = [self]
		var hit := space.intersect_ray(q)
		var end := to
		if hit:
			end = hit.position
			_impact(hit.position)
			var col = hit.collider
			if col and col.has_method("hit"):
				var is_head: bool = hit.position.y > (col.global_position.y + 1.55)
				var dmg := randi_range(int(w["dmg"][0]), int(w["dmg"][1]))
				if is_head:
					dmg = int(dmg * HEAD_MULT)
					Missions.add("headshot")
				if randf() < CRIT_CHANCE:
					dmg = int(dmg * CRIT_MULT)
				dmg = int(dmg * Controls.dmg_mult)
				col.hit(dmg, is_head, self)
				Profile.bump("hits")
				any_hit = true
		if p == 0 or randf() < 0.35:
			_tracer(ViewModel.muzzle if (Controls.view_fp and ViewModel.active and scope_k < 0.5) else _muzzle.global_position, end)
		last_end = end
	if any_hit:
		Fx.hitmarker()
		Sfx.play("hit")
	_muzzle_flash()

# knife: short sweep in front; from behind = 'back' damage (one-shot)
func _stab() -> void:
	if _soldier: _soldier.shoot()
	Sfx.play("throw", -2.0)
	var w := Weapons.get_w("knife")
	var reach := float(w["range"])
	var fwd := -global_transform.basis.z
	var best: Node3D = null
	var bd := 1e9
	for c in get_tree().get_nodes_in_group("combatant"):
		if c == self or not ("alive" in c and c.alive): continue
		var to: Vector3 = (c as Node3D).global_position - global_position
		to.y = 0.0
		var d := to.length()
		if d > reach + 0.4 or d < 0.01: continue
		if fwd.dot(to / d) < 0.5: continue          # ~60 deg cone in front
		if d < bd: bd = d; best = c
	if best == null:
		for z in get_tree().get_nodes_in_group("zombie"):
			var tz: Vector3 = (z as Node3D).global_position - global_position
			tz.y = 0.0
			if tz.length() <= reach + 0.4 and tz.length() > 0.01 and fwd.dot(tz.normalized()) > 0.5:
				best = z; break
	if best == null or not best.has_method("hit"): return
	var dmg := int(Weapons.knife_damage(self, best) * Controls.dmg_mult)
	best.hit(dmg, false, self)
	Fx.hitmarker()
	Sfx.play("hit")

func _impact(pos: Vector3) -> void:
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 0.08; sm.height = 0.16; m.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.8, 0.3); mat.emission_enabled = true; mat.emission = Color(1, 0.6, 0.1)
	m.material_override = mat
	get_tree().current_scene.add_child(m)
	m.global_position = pos
	get_tree().create_timer(0.25).timeout.connect(m.queue_free)

func _tracer(a: Vector3, b: Vector3) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(0.03, 0.03, (b - a).length()); m.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.85, 0.4); mat.emission_enabled = true; mat.emission = Color(1, 0.7, 0.2)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mat
	get_tree().current_scene.add_child(m)
	m.global_position = (a + b) * 0.5
	if a.distance_to(b) > 0.01:
		m.look_at(b, Vector3.UP)
	get_tree().create_timer(0.04).timeout.connect(m.queue_free)

func _muzzle_flash() -> void:
	var l := OmniLight3D.new()
	l.light_color = Color(1, 0.8, 0.4); l.light_energy = 3.0; l.omni_range = 4.0
	_muzzle.add_child(l)
	get_tree().create_timer(0.04).timeout.connect(l.queue_free)
