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
	if _soldier and _soldier._wmodel and _wid() == "xbow":          # the loaded bolt leaves the bow when fired
		var bn := _soldier._wmodel.find_child("Bolt", true, false) as Node3D
		if bn: bn.visible = Controls.ammo > 0

func hit(dmg: int, _is_head: bool = false, attacker = null) -> void:
	if not alive or invuln_t > 0.0:
		return
	if attacker != null and team != -1 and "team" in attacker and attacker.team == team:
		return   # no friendly fire
	Radar.contact(attacker, self)
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
	_soldier.body = Profile.equipped("body").substr(5); _soldier.gear = Profile.equipped("gear").substr(5); _soldier.skin = Profile.skin_mats(Profile.equipped("skin"))
	_soldier.wfx = Profile.equipped("wfx"); _soldier.cfx = Profile.equipped("cfx"); _soldier.fx_preview = false
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
	if Soldier.WEAPONS.get(_wid(), {}).get("break", false):
		_eject_shells()                         # reloads are silent (owner's call); the shells still pop out

## break-action: the two spent shells pop out of the breech when it opens
func _eject_shells() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null: return
	var fwd := -cam.global_transform.basis.z
	var at: Vector3 = (ViewModel.muzzle - fwd * 0.42) if (Controls.view_fp and ViewModel.active) else (_muzzle.global_position - fwd * 0.45)
	var cm := CylinderMesh.new(); cm.top_radius = 0.012; cm.bottom_radius = 0.012; cm.height = 0.06; cm.radial_segments = 10; cm.rings = 1
	var mt := StandardMaterial3D.new(); mt.albedo_color = Color(0.78, 0.14, 0.1); mt.roughness = 0.5; cm.material = mt
	FxCos.burst(get_tree().current_scene, at, {"n": 2, "life": 0.9, "mesh": cm, "mat": mt, "dir": (Vector3.UP - fwd * 0.6).normalized(), "spread": 18.0,
		"vel": Vector2(2.2, 3.0), "grav": Vector3(0, -9.8, 0), "scale": Vector2(1, 1), "curve": FxCos.shrink(1.0, 1.0), "spin": 8.0, "expl": 0.8, "delay": 0.25})

func _shoot(w: Dictionary) -> void:
	_ammo[_wid()] = int(_ammo[_wid()]) - 1
	_sync_hud()
	if w.get("flame", false):
		_flame(w); return
	if w.get("nail", false):
		_nail(w); return
	if w.get("bolt", false):
		_bolt(w); return
	if w.get("tesla", false):
		_tesla(w); return
	var snd := "dbarrel" if w.get("big_flash", false) else ("shot_" + _wid() if Sfx.has("shot_" + _wid()) else "shot")
	Sfx.play(snd, -1.0 if w.get("big_flash", false) else -3.0)
	if _wid() in ["shotgun", "sniper"] and int(_ammo.get(_wid(), 0)) > 0:      # pump / work the bolt after the shot
		var wid := _wid()
		get_tree().create_timer(0.38 if wid == "shotgun" else 0.5).timeout.connect(func() -> void: if _wid() == wid: Sfx.play("pump" if wid == "shotgun" else "bolt", -4.0))
	Controls.shots += 1
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
	var shoved := {}                     # zombie -> pellets that landed (knock-back scales with them)
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
				if w.has("knock") and col.has_method("knock"):
					shoved[col] = int(shoved.get(col, 0)) + 1
					if int(shoved[col]) == 1: _blood_fx(hit.position, dir)
		if p == 0 or randf() < 0.35:
			_tracer(ViewModel.muzzle if (Controls.view_fp and ViewModel.active and scope_k < 0.5) else _muzzle.global_position, end)
		last_end = end
	for z in shoved:                    # close range = most pellets = thrown back hard
		if is_instance_valid(z) and z.has_method("knock"):
			var push: Vector3 = (z as Node3D).global_position - global_position; push.y = 0.0
			z.knock(push.normalized() * float(w["knock"]) * float(shoved[z]), 0.25 + 0.04 * float(shoved[z]))
	if any_hit:
		Fx.hitmarker()
		Sfx.play("hit")
	_muzzle_flash()
	if w.get("big_flash", false): _big_flash()

# knife: short sweep in front; from behind = 'back' damage (one-shot)
func _stab() -> void:
	if Weapons.get_w(_wid()).has("hits"):
		_swing(); return
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

## heavy melee (axe): wind-up + swing; at `hit_at` the blade crosses the front: up to `hits` targets in
## a wide cone are hit, shoved back and splashed; a whiff only whooshes
func _swing() -> void:
	var w := Weapons.get_w(_wid())
	if _soldier: _soldier.shoot()
	Sfx.play("axe_swing", -2.0)
	var wid := _wid()
	get_tree().create_timer(float(w["hit_at"])).timeout.connect(func() -> void:
		if not is_instance_valid(self) or not alive or _wid() != wid: return
		_swing_hit(w))

func _swing_hit(w: Dictionary) -> void:
	var reach := float(w["range"]); var cone := cos(deg_to_rad(float(w["arc"])))
	var fwd := -global_transform.basis.z; fwd.y = 0.0; fwd = fwd.normalized()
	var cands := []
	for c in get_tree().get_nodes_in_group("zombie") + get_tree().get_nodes_in_group("combatant"):
		if c == self or not is_instance_valid(c): continue
		if "alive" in c and not c.alive: continue
		if c.get("_dead") == true: continue
		var to: Vector3 = (c as Node3D).global_position - global_position
		if absf(to.y) > 1.6: continue
		to.y = 0.0
		var d := to.length()
		if d > reach + 0.4 or d < 0.01 or fwd.dot(to / d) < cone: continue
		cands.append([d, c])
	cands.sort_custom(func(a, b): return a[0] < b[0])
	var n := 0
	for e in cands:
		if n >= int(w["hits"]): break
		var t: Node3D = e[1]
		if not t.has_method("hit"): continue
		var dmg := int(float(w["dmg"][0]) * Controls.dmg_mult)
		var at: Vector3 = t.global_position + Vector3(0, 1.1, 0)
		t.hit(dmg, false, self)
		var push: Vector3 = (t.global_position - global_position); push.y = 0.0
		if t.has_method("knock"): t.knock(push.normalized() * float(w["knock"]))
		_melee_fx(at, push.normalized())
		n += 1
	if n > 0:
		Fx.hitmarker(); Sfx.play("axe_hit", 1.0); Sfx.play("hit", -6.0); Controls.add_shake(0.35); Controls.vibrate(40)

## flamethrower tick (every 0.08 s while held): a burst of fire rolling out of the nozzle, and every
## zombie inside the cone (range / half-angle) that the wall does not hide is singed and set alight
var _jet: FlameJet
func _flame(w: Dictionary) -> void:
	if _soldier: _soldier.shoot()
	var cam := get_viewport().get_camera_3d()
	if cam == null: return
	var sc := get_tree().current_scene
	var fwd := -cam.global_transform.basis.z
	var fp := Controls.view_fp and ViewModel.active and scope_k < 0.5
	var mz: Vector3 = ViewModel.muzzle if fp else _muzzle.global_position
	var aim_to: Vector3 = cam.global_position + fwd * float(w["range"])
	var dir := (aim_to - mz).normalized()
	if not is_instance_valid(_jet):
		_jet = FlameJet.new(); sc.add_child(_jet)
	_jet.fp = fp
	_jet.feed(mz + dir * (0.25 if fp else 0.05), dir)
	var space := get_world_3d().direct_space_state
	var cone := cos(deg_to_rad(float(w["cone"])))
	var any := false
	for z in get_tree().get_nodes_in_group("zombie") + get_tree().get_nodes_in_group("combatant"):
		if z == self or not is_instance_valid(z) or not z.has_method("hit"): continue
		if "alive" in z and not z.alive: continue
		if z.get("_dead") == true: continue
		var c: Vector3 = (z as Node3D).global_position + Vector3(0, 1.0, 0)
		var to := c - mz; var d := to.length()
		if d > float(w["range"]) or d < 0.01 or dir.dot(to / d) < cone: continue
		var q := PhysicsRayQueryParameters3D.create(mz, c); q.exclude = [get_rid(), (z as CollisionObject3D).get_rid()]
		if not space.intersect_ray(q).is_empty(): continue
		z.hit(int(float(w["dmg"][0]) * Controls.dmg_mult), false, self)
		if z.has_method("burn"): z.burn(float(w["burn"][0]), float(w["burn"][1]) * Controls.dmg_mult, self)
		any = true
	if any and Engine.get_physics_frames() % 4 == 0: Fx.hitmarker()

## nail gun: one nail along the aim (with spread); it passes through up to `pierce` zombies, a nail stays
## stuck in each one it hits (a spark, a tiny blood puff), the last one / a wall stops it with a spark
func _nail(w: Dictionary) -> void:
	Sfx.play("nail", -2.0)
	Controls.shots += 1
	if _soldier: _soldier.shoot()
	_bloom = minf(_bloom + float(w["bloom"]), float(w["spread"][1]))
	aim_pitch = clampf(aim_pitch + float(w["kick"]), -45.0, 45.0)
	var cam := get_viewport().get_camera_3d()
	if cam == null: return
	var sc := get_tree().current_scene
	var s := deg_to_rad(Controls.spread_deg)
	var dir := (-cam.global_transform.basis.z).rotated(cam.global_transform.basis.x, randf_range(-s, s))
	dir = dir.rotated(cam.global_transform.basis.y, randf_range(-s, s))
	var space := get_world_3d().direct_space_state
	var from := cam.global_position
	var ex: Array[RID] = [get_rid()]
	var left := int(w["pierce"]); var end := from + dir * 60.0; var any := false
	while true:
		var q := PhysicsRayQueryParameters3D.create(from, from + dir * 60.0); q.exclude = ex
		var h := space.intersect_ray(q)
		if h.is_empty(): break
		var col = h.collider
		if col and col.has_method("hit") and left > 0:
			var head: bool = h.position.y > (col.global_position.y + 1.55)
			var dmg := int(randi_range(int(w["dmg"][0]), int(w["dmg"][1])) * (HEAD_MULT if head else 1.0) * Controls.dmg_mult)
			col.hit(dmg, head, self); any = true
			_stick_nail(col, h.position, dir)
			FxCos.burst(sc, h.position, {"n": 10, "life": 0.35, "size": 0.1, "mat": FxCos.glow_mat("glow", false), "dir": -dir, "spread": 50.0,
				"vel": Vector2(1.5, 3.5), "grav": Vector3(0, -10, 0), "color": Color(0.6, 0.04, 0.04)})
			FxCos.burst(sc, h.position, {"n": 8, "life": 0.22, "size": 0.06, "dir": -dir, "spread": 70.0, "vel": Vector2(3.0, 6.0),
				"grav": Vector3(0, -9, 0), "color": Color(1.0, 0.85, 0.45)})
			FxCos.pop(sc, h.position, Color(1.0, 0.9, 0.6), 0.5, 0.08)
			left -= 1
			ex.append((col as CollisionObject3D).get_rid()); from = h.position
			if left <= 0: end = h.position; break
		else:
			end = h.position
			FxCos.burst(sc, h.position, {"n": 8, "life": 0.25, "size": 0.05, "dir": h.normal, "spread": 60.0, "vel": Vector2(2.0, 4.0),
				"grav": Vector3(0, -9, 0), "color": Color(1.0, 0.8, 0.4)})
			break
	var mz: Vector3 = ViewModel.muzzle if (Controls.view_fp and ViewModel.active and scope_k < 0.5) else _muzzle.global_position
	_fly_nail(mz, end)
	FxCos.pop(sc, mz, Color(1.0, 0.9, 0.6), 0.35, 0.05)
	if any:
		Fx.hitmarker(); Sfx.play("hit", -8.0)

## explosive crossbow: the bolt leaves the bow toward what the crosshair is on (the camera ray), flies on its own
func _bolt(w: Dictionary) -> void:
	Sfx.play("twang", -1.0)
	Controls.shots += 1
	if _soldier: _soldier.shoot()
	aim_pitch = clampf(aim_pitch + float(w["kick"]), -45.0, 45.0)
	var cam := get_viewport().get_camera_3d()
	if cam == null: return
	var fwd := -cam.global_transform.basis.z
	var q := PhysicsRayQueryParameters3D.create(cam.global_position, cam.global_position + fwd * 80.0); q.exclude = [get_rid()]
	var h := get_world_3d().direct_space_state.intersect_ray(q)
	var aim: Vector3 = h["position"] if h else cam.global_position + fwd * 80.0
	var mz: Vector3 = ViewModel.muzzle if (Controls.view_fp and ViewModel.active and scope_k < 0.5) else _muzzle.global_position
	var bd := (aim - mz + Vector3(0, mz.distance_to(aim) * 0.07, 0)).normalized()
	var b := XbowBolt.fire(get_tree().current_scene, mz + bd * 0.5, bd, self)       # starts past the bow (no giant fletching on screen)
	b.radius = float(w["radius"]); b.dmg_max = float(w["dmg"][0]); b.dmg_min = float(w["dmg"][1])

## tesla gun: a bolt from the electrodes to what the crosshair is on (or the zombie nearest the aim line in
## a narrow cone); then it jumps to the nearest not-yet-hit zombie within `jump` m, up to `chain` zombies,
## each jump a bit weaker; every one hit is stunned and crackles. A miss still throws a short arc forward.
func _tesla(w: Dictionary) -> void:
	Sfx.play("zap", -1.0)
	Controls.shots += 1
	if _soldier: _soldier.shoot()
	aim_pitch = clampf(aim_pitch + float(w["kick"]), -45.0, 45.0)
	var cam := get_viewport().get_camera_3d()
	if cam == null: return
	var sc := get_tree().current_scene
	var fwd := -cam.global_transform.basis.z
	var mz: Vector3 = ViewModel.muzzle if (Controls.view_fp and ViewModel.active and scope_k < 0.5) else _muzzle.global_position
	var space := get_world_3d().direct_space_state
	var rng := float(w["range"])
	var zs: Array = []
	for z in get_tree().get_nodes_in_group("zombie") + get_tree().get_nodes_in_group("combatant"):
		if z == self or not is_instance_valid(z) or not z.has_method("hit"): continue
		if ("alive" in z and not z.alive) or z.get("_dead") == true: continue
		zs.append(z)
	# first target: smallest angle off the crosshair (within ~9 deg), in range, not behind a wall
	var first: Node3D = null; var best := cos(deg_to_rad(9.0))
	for z in zs:
		var c: Vector3 = (z as Node3D).global_position + Vector3(0, 1.0, 0)
		var to := c - cam.global_position; var d := to.length()
		if d > rng or d < 0.1: continue
		var dot := fwd.dot(to / d)
		if dot < best: continue
		var q := PhysicsRayQueryParameters3D.create(mz, c); q.exclude = [get_rid(), (z as CollisionObject3D).get_rid()]
		if not space.intersect_ray(q).is_empty(): continue
		best = dot; first = z
	if first == null:
		var q2 := PhysicsRayQueryParameters3D.create(cam.global_position, cam.global_position + fwd * 7.0); q2.exclude = [get_rid()]
		var h := space.intersect_ray(q2)
		var end: Vector3 = h["position"] if h else cam.global_position + fwd * 7.0
		_arc(sc, mz, end, 0.022)
		FxCos.pop(sc, end, Color(0.5, 0.75, 1.0), 0.6, 0.1)
		return
	var hit: Array = [first]; var from := mz; var cur: Node3D = first; var dmg := float(w["dmg"][0])
	while true:
		var at: Vector3 = cur.global_position + Vector3(0, 1.1, 0)
		_arc(sc, from, at, 0.03 if hit.size() == 1 else 0.024)
		cur.hit(int(dmg * Controls.dmg_mult), false, self)
		if cur.has_method("stun"): cur.stun(float(w["stun"]))
		FxCos.pop(sc, at, Color(0.55, 0.8, 1.0), 1.0, 0.14)
		FxCos.burst(sc, at, {"n": 10, "life": 0.25, "size": 0.06, "dir": Vector3.UP, "spread": 180.0, "vel": Vector2(2.0, 5.0),
			"grav": Vector3(0, -6, 0), "color": Color(0.7, 0.9, 1.0)})
		if hit.size() >= int(w["chain"]): break
		var nxt: Node3D = null; var nd := float(w["jump"])
		for z in zs:
			if z in hit: continue
			var d := (z as Node3D).global_position.distance_to(cur.global_position)
			if d < nd: nd = d; nxt = z
		if nxt == null: break
		hit.append(nxt); from = at; cur = nxt; dmg *= float(w["falloff"])
	FxCos.flash(sc, mz, Color(0.5, 0.7, 1.0), 3.0, 6.0, 0.12)
	Fx.hitmarker(); Sfx.play("hit", -6.0)

## a jagged lightning bolt a -> b (two flickers, offsets across the line, fattest in the middle)
static func _arc(sc: Node, a: Vector3, b: Vector3, w: float) -> void:
	var d := b - a; var L := d.length()
	if L < 0.05: return
	var side := d.cross(Vector3.UP).normalized(); if side.length() < 0.1: side = Vector3.RIGHT
	var up := side.cross(d / L)
	for flick in 2:
		var n := maxi(4, int(L / 0.6))
		var pts := [a]
		for i in range(1, n):
			var t := float(i) / n; var amp := sin(PI * t) * minf(0.35, L * 0.08)
			pts.append(a + d * t + side * randf_range(-amp, amp) + up * randf_range(-amp, amp))
		pts.append(b)
		if flick == 0: FxCos._bolt_line(sc, pts, w, 0.14)
		else: sc.get_tree().create_timer(0.05).timeout.connect(func() -> void: if is_instance_valid(sc): FxCos._bolt_line(sc, pts, w * 0.8, 0.12))

static var _nail_mesh: CylinderMesh
static func _nail_m() -> CylinderMesh:
	if _nail_mesh == null:
		_nail_mesh = CylinderMesh.new(); _nail_mesh.top_radius = 0.022; _nail_mesh.bottom_radius = 0.009; _nail_mesh.height = 0.2   # chunky so it reads on a phone
		_nail_mesh.radial_segments = 6; _nail_mesh.rings = 1
		var m := StandardMaterial3D.new(); m.albedo_color = Color(0.85, 0.87, 0.9); m.metallic = 0.6; m.roughness = 0.25
		m.emission_enabled = true; m.emission = Color(0.35, 0.36, 0.4); _nail_mesh.material = m
	return _nail_mesh

## the nail itself flying (fast, but you see it) with a thin bright streak
func _fly_nail(a: Vector3, b: Vector3) -> void:
	var n := MeshInstance3D.new(); n.mesh = _nail_m(); n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(n)
	var d := (b - a); var L := d.length()
	if L < 0.05: n.queue_free(); return
	n.global_transform = Transform3D(Basis.looking_at(d / L) * Basis(Vector3.RIGHT, PI * 0.5), a)
	var tw := n.create_tween(); tw.tween_property(n, "global_position", b, L / 38.0); tw.tween_callback(n.queue_free)
	FxCos.tracer("tr_basic", get_tree().current_scene, a, b)

## a nail left sticking out of the zombie where it went in (falls away with it)
func _stick_nail(z: Node, at: Vector3, dir: Vector3) -> void:
	var n := MeshInstance3D.new(); n.mesh = _nail_m(); n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	z.add_child(n)
	n.global_transform = Transform3D(Basis.looking_at(dir) * Basis(Vector3.RIGHT, PI * 0.5), at - dir * 0.04)
	get_tree().create_timer(4.0).timeout.connect(func() -> void: if is_instance_valid(n): n.queue_free())

## double barrel: a big orange flash + a puff of grey smoke at the muzzle, a hard camera kick
func _big_flash() -> void:
	var sc := get_tree().current_scene
	var mz: Vector3 = ViewModel.muzzle if (Controls.view_fp and ViewModel.active and scope_k < 0.5) else _muzzle.global_position
	var fwd := -get_viewport().get_camera_3d().global_transform.basis.z
	FxCos.pop(sc, mz + fwd * 0.25, Color(1.0, 0.7, 0.3), 1.3, 0.08)
	FxCos.flash(sc, mz, Color(1.0, 0.75, 0.4), 2.5, 4.0, 0.08)
	var sm := FxCos.glow_mat("glow", false)
	FxCos.burst(sc, mz + fwd * 0.9, {"n": 12, "life": 0.9, "size": 0.32, "mat": sm, "dir": fwd, "spread": 22.0, "vel": Vector2(1.0, 2.6),
		"grav": Vector3(0, 0.6, 0), "damp": Vector2(2, 3), "scale": Vector2(0.8, 1.8), "color": Color(0.9, 0.9, 0.88, 0.32)})
	Controls.add_shake(0.5); Controls.vibrate(60)

## a smaller splash where shot lands on a zombie
func _blood_fx(at: Vector3, dir: Vector3) -> void:
	var bm := FxCos.glow_mat("glow", false)
	FxCos.burst(get_tree().current_scene, at, {"n": 16, "life": 0.45, "size": 0.1, "mat": bm, "dir": (dir + Vector3(0, 0.4, 0)).normalized(), "spread": 35.0,
		"vel": Vector2(2.0, 4.5), "grav": Vector3(0, -12, 0), "scale": Vector2(0.6, 1.3), "color": Color(0.6, 0.04, 0.04)})

## blood splash + a short white impact ring where a heavy blow lands
func _melee_fx(at: Vector3, dir: Vector3) -> void:
	var sc := get_tree().current_scene
	var bm := FxCos.glow_mat("glow", false)          # soft round drops, not squares
	FxCos.burst(sc, at, {"n": 34, "life": 0.55, "size": 0.12, "mat": bm, "dir": (dir + Vector3(0, 0.6, 0)).normalized(), "spread": 40.0,
		"vel": Vector2(2.5, 5.5), "grav": Vector3(0, -12, 0), "scale": Vector2(0.6, 1.4), "color": Color(0.6, 0.04, 0.04)})
	FxCos.burst(sc, at, {"n": 10, "life": 0.35, "size": 0.22, "mat": bm, "dir": Vector3.UP, "spread": 180.0,
		"vel": Vector2(0.5, 1.5), "grav": Vector3(0, -4, 0), "color": Color(0.45, 0.02, 0.02)})
	FxCos.shock(sc, at, Color(1, 0.95, 0.85, 0.8), 0.28, 0.16, true)
	FxCos.pop(sc, at, Color(1.0, 0.85, 0.6), 0.9, 0.12)

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
	FxCos.tracer(Profile.equipped("tracer"), get_tree().current_scene, a, b)
	return
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
