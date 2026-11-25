class_name BotPlayer
extends CharacterBody3D
## M-A AI combatant (AIHuman model, simplified): find nearest living opponent ->
## path into combat range -> fire bursts with reaction delay + inaccuracy.
## Damageable like any combatant via hit(); dies and is respawned by the mode.

signal died(attacker)

const SPEED := 3.6
const GRAVITY := 20.0
const COMBAT_DIST := 18.0   # start shooting within this
const MIN_DIST := 6.0       # back off if closer
# reaction / aim spread / damage share / tactics come from Difficulty (출격 준비)
const HEAD_AIM := 0.25      # elite: share of shots aimed at the head
const BURST_MIN := 3
const BURST_MAX := 6
const BURST_COOL := 0.9
const KNIFE_IN := 2.6       # pull the knife when the target is this close
const KNIFE_OUT := 4.2      # back to the gun beyond this
# engagement range per primary [combat, min]: shotgun bots rush, snipers keep away
const RANGE := {"shotgun": [9.0, 2.0], "mp5": [12.0, 3.0], "sniper": [30.0, 12.0], "rpk": [20.0, 6.0]}
const MAX_HP := 100.0

const INVULN := 2.0

var hp := MAX_HP
var alive := true
var invuln_t := 0.0
var team := -1   # -1 = FFA; 0/1 = teams
var kills := 0
var bot_name := "BOT"
var tint := Color(0.80, 0.32, 0.30)

var _agent: NavigationAgent3D
var _muzzle: Node3D
var _soldier: Soldier
var _warmup := 0.6
var _target: Node3D
var _retarget_cd := 0.0
var _burst := 0
var _shot_cd := 0.0
var _burst_cd := 0.0
var loadout := ["m4", "pistol", "knife"]
var wid := "m4"
var _ammo := {}
var _reload_t := 0.0
var _swap_t := 0.0
var rusher := false        # some bots close in for the knife when a target is near
# grenades: lob one at a mid-range target (more likely when it's behind cover)
const NADE_MIN := 7.0
const NADE_MAX_D := 22.0
const NADE_SPREAD := 1.4      # landing error (m)
var nades := 2
var _nade_cd := randf_range(8.0, 14.0)
var _windup_t := -1.0
var _nade_to := Vector3.ZERO

func _ready() -> void:
	add_to_group("combatant")
	_soldier = Soldier.new()
	add_child(_soldier)
	_soldier.setup(tint)
	loadout = [Weapons.ORDER_PRIMARY.pick_random(), Weapons.ORDER_SECONDARY.pick_random(), "knife"]
	rusher = randf() < (0.6 if loadout[0] in ["shotgun", "mp5"] else 0.25) * Difficulty.v("tactics")
	_refill()
	_equip(loadout[0])
	_muzzle = Node3D.new(); _muzzle.position = Vector3(0.22, 1.3, -0.5)
	add_child(_muzzle)
	var col := CollisionShape3D.new()
	var cs := CapsuleShape3D.new(); cs.radius = 0.4; cs.height = 2.0
	col.shape = cs; col.position = Vector3(0, 1.0, 0)
	add_child(col)
	_agent = NavigationAgent3D.new()
	_agent.path_desired_distance = 0.6
	_agent.target_desired_distance = _combat() * 0.8
	add_child(_agent)

func hit(dmg: int, _is_head: bool = false, attacker = null) -> void:
	if not alive or invuln_t > 0.0:
		return
	if attacker != null and team != -1 and "team" in attacker and attacker.team == team:
		return   # no friendly fire
	hp -= dmg
	if hp <= 0.0:
		alive = false
		_windup_t = -1.0
		if _soldier: _soldier.windup(false); _soldier.set_dead(true)
		for c in get_children():
			if c is CollisionShape3D:
				c.set_deferred("disabled", true)
		visible = false
		Sfx.play_at("die", global_position)
		died.emit(attacker)

func respawn_at(pos: Vector3) -> void:
	alive = true
	invuln_t = INVULN
	hp = MAX_HP
	if _soldier: _soldier.set_dead(false)
	global_position = pos
	velocity = Vector3.ZERO
	visible = true
	_target = null
	_burst = 0
	_warmup = 0.4
	nades = 2
	_nade_cd = randf_range(8.0, 14.0)
	_refill()
	_equip(loadout[0])
	_windup_t = -1.0
	if _soldier: _soldier.windup(false)
	for c in get_children():
		if c is CollisionShape3D:
			c.set_deferred("disabled", false)

func _physics_process(delta: float) -> void:
	if not alive:
		return
	if invuln_t > 0.0:
		invuln_t -= delta
		visible = fmod(invuln_t, 0.2) < 0.1
		if invuln_t <= 0.0:
			visible = true
	_warmup = maxf(0.0, _warmup - delta)

	_retarget_cd -= delta
	if _retarget_cd <= 0.0:
		_retarget_cd = Difficulty.v("react")
		_target = _find_nearest()

	if _target != null and _alive_of(_target):
		var to := _target.global_position - global_position
		to.y = 0.0
		var dist := to.length()
		if to.length() > 0.1:
			look_at(global_position + Vector3(to.x, 0, to.z), Vector3.UP)
		_nade_cd -= delta
		if _windup_t >= 0.0:
			# arm cocked back: hold still briefly, then release
			velocity.x = 0.0; velocity.z = 0.0
			_windup_t -= delta
			if _windup_t < 0.0:
				_throw_nade()
		elif _warmup <= 0.0 and nades > 0 and _nade_cd <= 0.0 and dist >= NADE_MIN and dist <= NADE_MAX_D:
			_nade_cd = randf_range(12.0, 20.0)
			var chance := (0.6 if not _has_los() else 0.2) * Difficulty.v("tactics")
			if randf() < chance:
				_nade_to = _target.global_position + Vector3(randf_range(-NADE_SPREAD, NADE_SPREAD), 0, randf_range(-NADE_SPREAD, NADE_SPREAD))
				_windup_t = 0.45
				if _soldier: _soldier.windup(true)
		if _windup_t >= 0.0:
			pass
		elif _warmup <= 0.0:
			_swap_t = maxf(0.0, _swap_t - delta)
			# close quarters: knife out, rush in and stab; back to the gun when it opens up
			if wid != "knife" and dist < KNIFE_IN:
				_equip("knife")
			elif wid == "knife" and dist > KNIFE_OUT:
				_equip(loadout[0])
			if wid == "knife":
				if dist > 1.3:
					var dn := to.normalized()
					velocity.x = dn.x * _speed(); velocity.z = dn.z * _speed()
				else:
					velocity.x = 0.0; velocity.z = 0.0
				_try_stab(delta, dist)
			elif rusher and dist < 13.0 and _has_los():
				var dr := to.normalized()           # charge in, firing, then knife
				velocity.x = dr.x * _speed(); velocity.z = dr.z * _speed()
				_try_fire(delta)
			elif dist > _combat():
				_move_to(_target.global_position, to)
			elif dist < _min_d():
				var away := -to.normalized()
				velocity.x = away.x * _speed(); velocity.z = away.z * _speed()
				_try_fire(delta)
			else:
				velocity.x = 0.0; velocity.z = 0.0
				_try_fire(delta)
		else:
			velocity.x = 0.0; velocity.z = 0.0
	else:
		velocity.x = 0.0; velocity.z = 0.0

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	move_and_slide()

	if _soldier:
		var hs := Vector2(velocity.x, velocity.z).length()
		_soldier.drive(hs / SPEED, _target != null and _alive_of(_target) and wid != "knife")

func _refill() -> void:
	for id in loadout:
		_ammo[id] = int(Weapons.get_w(id)["mag"])
	_reload_t = 0.0

func _equip(id: String) -> void:
	if _soldier and _soldier.weapon == id: return
	wid = id
	_swap_t = Weapons.SWAP_TIME
	_burst = 0
	if _soldier: _soldier.set_weapon(id)

func _combat() -> float:
	return float(RANGE.get(loadout[0], [COMBAT_DIST, MIN_DIST])[0])

func _min_d() -> float:
	return float(RANGE.get(loadout[0], [COMBAT_DIST, MIN_DIST])[1])

func _speed() -> float:
	return SPEED * float(Weapons.get_w(wid)["speed"])

func _move_to(dest: Vector3, to_flat: Vector3) -> void:
	_agent.target_position = dest
	var next := _agent.get_next_path_position()
	var dir := next - global_position
	dir.y = 0.0
	if dir.length() < 0.15 or global_position.y > 0.6:
		dir = to_flat
	if dir.length() > 0.05:
		dir = dir.normalized()
		velocity.x = dir.x * _speed()
		velocity.z = dir.z * _speed()

func _alive_of(n: Node) -> bool:
	return n != null and "alive" in n and n.alive

func _find_nearest() -> Node3D:
	var best: Node3D = null
	var bd := 1e9
	for c in get_tree().get_nodes_in_group("combatant"):
		if c == self or not _alive_of(c):
			continue
		if team != -1 and "team" in c and c.team == team:
			continue   # skip teammates
		var d := global_position.distance_to((c as Node3D).global_position)
		if d < bd:
			bd = d; best = c
	return best

func _throw_nade() -> void:
	if not alive or nades <= 0:
		if _soldier: _soldier.windup(false)
		return
	var origin := global_position + Vector3(0, 1.55, 0) + global_transform.basis.x * 0.25
	Grenade.spawn(get_tree().current_scene, origin, Grenade.lob_velocity(origin, _nade_to), self)
	nades -= 1
	if _soldier: _soldier.throw()
	Sfx.play_at("throw", origin)

func _aim_h(n: Node) -> float:
	return float(n.aim_h) if "aim_h" in n else 1.1

func _has_los() -> bool:
	if _target == null:
		return false
	var from := global_position + Vector3(0, 1.4, 0)
	var to := _target.global_position + Vector3(0, _aim_h(_target) + 0.2, 0)
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit.is_empty() or hit.collider == _target

func _try_fire(delta: float) -> void:
	_burst_cd -= delta
	_shot_cd -= delta
	if _swap_t > 0.0:
		return
	if _reload_t > 0.0:
		_reload_t -= delta
		if _reload_t <= 0.0:
			_ammo[wid] = int(Weapons.get_w(wid)["mag"])
		return
	if int(_ammo.get(wid, 0)) <= 0:
		_reload_t = float(Weapons.get_w(wid)["reload"])
		return
	if not _has_los():
		return
	var w := Weapons.get_w(wid)
	var auto := bool(w.get("auto", false))
	if _burst > 0:
		if _shot_cd <= 0.0:
			_fire_one(w)
			_burst -= 1
			# semi-auto/bolt guns: slower human tap rate
			_shot_cd = Weapons.interval(wid) * (1.0 if auto else 1.6) + (0.0 if auto else randf_range(0.05, 0.25))
	elif _burst_cd <= 0.0:
		_burst = randi_range(BURST_MIN, BURST_MAX) if auto else randi_range(1, 3)
		_burst_cd = BURST_COOL + (0.6 if wid == "sniper" else 0.0)

func _try_stab(delta: float, dist: float) -> void:
	_shot_cd -= delta
	if _swap_t > 0.0 or _shot_cd > 0.0 or dist > float(Weapons.get_w("knife")["range"]):
		return
	_shot_cd = Weapons.interval("knife") + randf_range(0.0, 0.2)
	if _soldier: _soldier.shoot()
	Sfx.play_at("throw", global_position, -4.0)
	if _target and _target.has_method("hit"):
		_target.hit(int(Weapons.knife_damage(self, _target) * Difficulty.v("dmg") * 1.33), false, self)

func _fire_one(w: Dictionary) -> void:
	if _target == null:
		return
	_ammo[wid] = int(_ammo[wid]) - 1
	var from := _muzzle.global_position
	Sfx.play_at("shot", from, -4.0)
	if _soldier: _soldier.shoot()
	var head_aim := Controls.bot_diff == "elite" and randf() < HEAD_AIM
	var aim := (_target.global_position + Vector3(0, _aim_h(_target) + (0.45 if head_aim else 0.0), 0)) - from
	var base := aim.normalized()
	var acc := Difficulty.v("spread") * (0.45 if wid == "sniper" else 1.0) + (float(w["spread"][0]) if w.has("pellets") else 0.0)
	var s := deg_to_rad(acc)
	for p in int(w.get("pellets", 1)):
		var dir := base.rotated(Vector3.UP, randf_range(-s, s))
		dir = dir.rotated(global_transform.basis.x, randf_range(-s, s))
		var to := from + dir * 120.0
		var q := PhysicsRayQueryParameters3D.create(from, to)
		q.exclude = [self]
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		var end := to
		if hit:
			end = hit.position
			var col = hit.collider
			if col and col.has_method("hit"):
				var is_head: bool = hit.position.y > ((col as Node3D).global_position.y + 1.55)
				var dmg := randi_range(int(w["dmg"][0]), int(w["dmg"][1])) * Difficulty.v("dmg") * (1.6 if is_head else 1.0)
				col.hit(maxi(1, int(dmg)), is_head, self)
		if p == 0 or randf() < 0.3:
			_tracer(from, end)

func _tracer(a: Vector3, b: Vector3) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(0.025, 0.025, (b - a).length()); m.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.5, 0.4); mat.emission_enabled = true; mat.emission = Color(1, 0.4, 0.2)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mat
	get_tree().current_scene.add_child(m)
	m.global_position = (a + b) * 0.5
	if a.distance_to(b) > 0.01:
		m.look_at(b, Vector3.UP)
	get_tree().create_timer(0.04).timeout.connect(m.queue_free)
