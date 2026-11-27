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
var rusher := false
var last_shot_t := -99.0     # radar: enemies show briefly after they fire
# objective play (bomb defusal): the mode sets these
var frozen := false            # round prep: can't move or shoot
var busy := false              # planting / defusing: stand still
var objective := Vector3.INF   # where to go when not fighting
var engage_range := 0.0        # > 0: only chase enemies this close or in sight        # some bots close in for the knife when a target is near
# grenades: lob one at a mid-range target (more likely when it's behind cover)
const NADE_MIN := 7.0
const NADE_MAX_D := 22.0
const NADE_SPREAD := 1.4      # landing error (m)
var nades := 2
var _nade_cd := randf_range(8.0, 14.0)
var _windup_t := -1.0
var _nade_to := Vector3.ZERO

# ---- difficulty (per bot: "" = the level picked in 출격 준비; set for bot-vs-bot tests)
var diff := ""
func D(key: String) -> float:
	return float(Difficulty.L.get(diff if diff != "" else Controls.bot_diff, Difficulty.L["reg"])[key])

# ---- perception: bots only know what they see, hear, remember or are told (no wallhack)
const FOV_COS := -0.17          # 200 degree view cone (cos 100)
const SIGHT := 70.0
const AWARE := 7.0              # this close you are noticed from any direction
static var roam_pts: Array = [] # points spread over the map (the mode sets them: FFA spawns)
var _mem := {}                  # instance id -> {n, pos, t, vis}
var _perc_cd := 0.0
var _goal := Vector3.INF        # where we are walking when not fighting
var _goal_mem := -1             # the memory entry the goal investigates (-1 = roaming)
var _via := Vector3.INF         # flank detour on the way to the goal

static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0

## a gunshot / loud noise at `at` made by `src`: every bot in earshot remembers roughly where
static func noise(at: Vector3, src: Node, kind := "shot") -> void:
	if src == null or not src.is_inside_tree(): return
	for b in src.get_tree().get_nodes_in_group("bots"):
		(b as BotPlayer)._hear(at, src, kind)

func _hear(at: Vector3, src: Node, kind: String) -> void:
	if not alive or src == self or not _alive_of(src): return
	if team != -1 and "team" in src and src.team == team: return
	var r := D("hear_shot") if kind == "shot" else D("hear_step")
	var d := global_position.distance_to(at)
	if r <= 0.0 or d > r: return
	var err := 1.0 + d * 0.12
	_remember(src, at + Vector3(randf_range(-err, err), 0, randf_range(-err, err)), false)

func _remember(n: Node, pos: Vector3, vis: bool) -> void:
	var k := n.get_instance_id()
	var e: Dictionary = _mem.get(k, {})
	if not vis and e.get("vis", false): return       # a sound never overrides a sighting this tick
	_mem[k] = {"n": n, "pos": pos, "t": _now(), "vis": vis}

func _enemy(c: Node) -> bool:
	if c == self or not _alive_of(c): return false
	return not (team != -1 and "team" in c and c.team == team)

func _sees(c: Node3D) -> bool:
	var from := global_position + Vector3(0, 1.6, 0)
	var q := PhysicsRayQueryParameters3D.create(from, c.global_position + Vector3(0, _aim_h(c) + 0.25, 0))
	q.exclude = [self]
	var h := get_world_3d().direct_space_state.intersect_ray(q)
	return h.is_empty() or h.collider == c

func _perceive() -> void:
	var now := _now()
	for k in _mem.keys():
		var e: Dictionary = _mem[k]
		e["vis"] = false
		if now - float(e["t"]) > D("memory") or not _alive_of(e["n"]): _mem.erase(k)
	var fwd := -global_transform.basis.z
	var step_r := D("hear_step")
	for c in get_tree().get_nodes_in_group("combatant"):
		if not _enemy(c): continue
		var n3 := c as Node3D
		var to := n3.global_position - global_position
		var d := to.length()
		if d > SIGHT: continue
		var flat := Vector3(to.x, 0, to.z).normalized()
		if (d < AWARE or fwd.dot(flat) > FOV_COS) and _sees(n3):
			_remember(c, n3.global_position, true)
			_share(c, n3.global_position)
		elif step_r > 0.0 and d < step_r and "velocity" in c and Vector2(c.velocity.x, c.velocity.z).length() > 4.2:
			_hear(n3.global_position, c, "step")               # running footsteps

func _share(c: Node, pos: Vector3) -> void:
	var mode := D("share")
	if mode <= 0.0 or team == -1: return
	for b in get_tree().get_nodes_in_group("bots"):
		if b == self or b.team != team or not b.alive: continue
		if mode < 2.0 and (b as Node3D).global_position.distance_to(global_position) > 25.0: continue
		(b as BotPlayer)._remember(c, pos, false)

## target = the nearest enemy we can see right now
func _pick_target() -> Node3D:
	var best: Node3D = null; var bd := 1e9
	for e in _mem.values():
		if not e["vis"]: continue
		var d := global_position.distance_to((e["n"] as Node3D).global_position)
		if d < bd: bd = d; best = e["n"]
	return best

## nothing in sight: go where we last saw / heard someone, else roam the map
func _wander(delta: float) -> void:
	# quiet moment: careful bots top up the magazine now (and put the main gun back)
	if D("cover") >= 3.0 and _reload_t <= 0.0:
		if wid != loadout[0] and wid != "knife": _equip(loadout[0])
		elif float(_ammo.get(wid, 0)) / float(Weapons.get_w(wid)["mag"]) < D("hide_ammo"): _reload_t = float(Weapons.get_w(wid)["reload"])
	if _reload_t > 0.0:
		_reload_t -= delta
		if _reload_t <= 0.0: _ammo[wid] = int(Weapons.get_w(wid)["mag"])
	# chase what we know - but a far-off fight in another lane does not pull us out of ours
	var latest := -1; var lt := -1.0
	for k in _mem.keys():
		var mp: Vector3 = _mem[k]["pos"]
		var near := mp.distance_to(global_position) < 22.0 or _lane_of(mp) == lane or roam_pts.is_empty()
		if near and float(_mem[k]["t"]) > lt: lt = float(_mem[k]["t"]); latest = k
	if latest != -1 and latest != _goal_mem:
		_goal_mem = latest; _goal = _mem[latest]["pos"]; _via = Vector3.INF
		if randf() < D("flank") and global_position.distance_to(_goal) > 14.0: _via = _flank_point(_goal)
	elif latest == -1 and _goal_mem != -1:
		_goal_mem = -1; _goal = Vector3.INF
	if _goal == Vector3.INF:
		_goal = _roam_point(); _via = Vector3.INF
	var dest := _via if _via != Vector3.INF else _goal
	var tf := dest - global_position; tf.y = 0.0
	if tf.length() < 2.0:
		if _via != Vector3.INF: _via = Vector3.INF
		else:
			if _goal_mem != -1: _mem.erase(_goal_mem)   # nobody here any more
			_goal_mem = -1; _goal = Vector3.INF
		velocity.x = 0.0; velocity.z = 0.0
		return
	_move_to(dest, tf)
	_unstick(delta)
	var mv := Vector3(velocity.x, 0, velocity.z)
	if mv.length() > 0.1: look_at(global_position + mv, Vector3.UP)

# lanes: each life the bot takes one band of the map (north / middle / south) and pushes along it
var lane := 0                   # -1 north, 0 middle, 1 south
var _push := 1.0                # +1 / -1: the x direction toward the enemy side (teams)
func _lane_of(p: Vector3) -> int:
	var b := _lane_band()
	return -1 if p.z < -b else (1 if p.z > b else 0)
func _lane_band() -> float:
	var zmin := 1e9; var zmax := -1e9
	for q in roam_pts: zmin = minf(zmin, q.z); zmax = maxf(zmax, q.z)
	return maxf((zmax - zmin) / 6.0, 4.0)
func _pick_lane() -> void:
	var r := randf()
	lane = -1 if r < 0.35 else (1 if r < 0.7 else 0)
	_push = -signf(global_position.x) if absf(global_position.x) > 3.0 else (1.0 if randf() < 0.5 else -1.0)

func _roam_point() -> Vector3:
	if roam_pts.is_empty(): return global_position
	var mine: Array = []
	for q in roam_pts:
		if _lane_of(q) == lane: mine.append(q)
	if mine.is_empty(): mine = roam_pts
	if team != -1:
		# next point along the lane toward the enemy side; at the far end turn around
		var best := Vector3.INF; var bd := 1e9
		for q in mine:
			var ahead: float = (q.x - global_position.x) * _push
			if ahead > 4.0 and ahead < bd: bd = ahead; best = q
		if best != Vector3.INF: return best
		_push = -_push
	for tries in 8:
		var p: Vector3 = mine[randi() % mine.size()]
		if p.distance_to(global_position) > 8.0: return p
	return mine[randi() % mine.size()]

# a roam point off to the side of the straight line to the goal, not much longer than going direct
func _flank_point(goal: Vector3) -> Vector3:
	var a := global_position; var line := goal - a; line.y = 0.0
	var L := line.length()
	var cands: Array = []
	for p in roam_pts:
		var q: Vector3 = p
		var off := (q - a); off.y = 0.0
		var t := off.dot(line) / maxf(L * L, 0.01)
		if t < 0.2 or t > 0.85: continue
		var lateral := (off - line * t).length()
		if lateral > 8.0 and a.distance_to(q) + q.distance_to(goal) < L * 1.7: cands.append(q)
	return cands.pick_random() if not cands.is_empty() else Vector3.INF

# ---- combat with cover (map analysis, see MapIntel). Level by difficulty "cover":
#  0 stand / walk and shoot in the open   1 fight from the nearest cover
#  2 + peek out to shoot, duck back to reload or when hurt, fall back when low
#  3 + change spot after taking hits or every few seconds, reload early, fall back toward the team
var _cover := Vector3.INF        # hiding spot (wall between it and the target)
var _peek := Vector3.INF         # one step out of it, with a view of the target
var _cover_t := 0.0
var _cover_for: Node = null
var _hits_here := 0
var _retreat_t := 0.0
var _retreated := false
var _strafe := 1.0
var _hit_t := 99.0
var _strafe_t := 0.0

func _fight(delta: float, to: Vector3, dist: float) -> void:
	var lvl := int(D("cover"))
	var los := _los_cached()
	_strafe_t -= delta
	if _strafe_t <= 0.0: _strafe_t = randf_range(0.6, 1.4); _strafe = -_strafe
	# fall back when badly hurt (once a life): toward cover away from the threat / toward the team
	if lvl >= 2 and not _retreated and hp < D("retreat_hp"):
		_retreated = true; _retreat_t = randf_range(4.0, 7.0)
		var back := global_position - to.normalized() * 10.0
		if lvl >= 3 and team != -1:
			var mates := Vector3.ZERO; var n := 0
			for b in get_tree().get_nodes_in_group("bots"):
				if b != self and b.team == team and b.alive: mates += (b as Node3D).global_position; n += 1
			if n > 0: back = mates / n
		var c := MapIntel.cover_from(back, _target.global_position, 12.0)
		_cover = c if c != Vector3.INF else back; _peek = Vector3.INF
	if _retreat_t > 0.0:
		_retreat_t -= delta
		_go(_cover, delta)
		if los: _try_fire(delta)
		return
	if lvl == 0 or MapIntel.points.is_empty():
		_open_fight(delta, to, dist, lvl == 0); return
	# pick / refresh a fighting spot near us with a wall toward the target
	_cover_t += delta
	var stale := _cover == Vector3.INF or _cover_for != _target or (lvl >= 3 and (_hits_here >= 2 or _cover_t > 7.0))
	if stale and (_cover_t > 0.8 or _cover_for != _target):
		_cover_for = _target; _cover_t = 0.0; _hits_here = 0
		_cover = MapIntel.cover_from(global_position, _target.global_position, minf(_combat(), 11.0))
		_peek = _peek_of(_cover) if _cover != Vector3.INF else Vector3.INF
	if _cover == Vector3.INF or _cover.distance_to(_target.global_position) > _combat() + 6.0:
		_open_fight(delta, to, dist, false); return
	# duck behind the wall to reload / when hurt (2+); otherwise stand at the peek spot and shoot
	if lvl >= 3 and wid == loadout[0] and int(_ammo.get(wid, 0)) <= 0 and dist < 12.0 and _reload_t <= 0.0:
		_equip(loadout[1])                       # empty up close: sidearm is faster than a reload
		return
	var mag := float(_ammo.get(wid, 0)) / float(Weapons.get_w(wid)["mag"])
	var duck := lvl >= 2 and (_reload_t > 0.0 or (hp < D("hide_hp") and _hit_t < 1.2) or (mag < D("hide_ammo") and not los and _reload_t <= 0.0))
	if duck:
		if _reload_t <= 0.0 and mag < 1.0 and (mag < D("hide_ammo") or int(_ammo.get(wid, 0)) <= 0): _reload_t = float(Weapons.get_w(wid)["reload"])
		_go(_cover, delta)
		if _reload_t > 0.0:
			_reload_t -= delta
			if _reload_t <= 0.0: _ammo[wid] = int(Weapons.get_w(wid)["mag"])
		return
	var spot := _peek if (lvl >= 2 and _peek != Vector3.INF) else _cover
	if lvl == 1 and not los: spot = global_position          # plain cover user: no view -> push in
	if not los and global_position.distance_to(spot) < 0.8:
		_move_to(_target.global_position, to)              # no shot from here: close in
	else:
		_go(spot, delta)
	_face_target()
	_try_fire(delta)

func _open_fight(delta: float, to: Vector3, dist: float, walk_and_shoot: bool) -> void:
	if dist > _combat() or not _los_cached():
		_move_to(_target.global_position, to)      # out of range or blocked by walls: path in
	elif dist < _min_d():
		var away := -to.normalized()
		velocity.x = away.x * _speed(); velocity.z = away.z * _speed()
	elif walk_and_shoot:                           # rookies keep drifting sideways while they shoot
		var side := Vector3(-to.z, 0, to.x).normalized() * _strafe
		velocity.x = side.x * _speed() * 0.6; velocity.z = side.z * _speed() * 0.6
	else:
		velocity.x = 0.0; velocity.z = 0.0
	_face_target()
	_try_fire(delta)

func _go(p: Vector3, _delta: float) -> void:
	var tf := p - global_position; tf.y = 0.0
	if tf.length() < 0.35:
		velocity.x = 0.0; velocity.z = 0.0
		return
	_move_to(p, tf)
	if tf.length() < 1.2:          # last bit: slow down so we stop on the spot
		velocity.x *= 0.6; velocity.z *= 0.6

func _face_target() -> void:
	if _target == null: return
	var t := _target.global_position - global_position
	if Vector2(t.x, t.z).length() > 0.1: look_at(global_position + Vector3(t.x, 0, t.z), Vector3.UP)

## the side step out of a cover spot that has a clear line to the target
func _peek_of(c: Vector3) -> Vector3:
	if _target == null: return Vector3.INF
	var to := _target.global_position - c; to.y = 0.0; to = to.normalized()
	var side := Vector3(-to.z, 0, to.x)
	var sp := get_world_3d().direct_space_state
	for s in [1.0, -1.0]:
		var p: Vector3 = c + side * s * 1.1
		var q := PhysicsRayQueryParameters3D.create(c + Vector3(0, 1.0, 0), p + Vector3(0, 1.0, 0))
		if not sp.intersect_ray(q).is_empty(): continue
		var r := PhysicsRayQueryParameters3D.create(p + Vector3(0, 1.5, 0), _target.global_position + Vector3(0, 1.3, 0))
		r.exclude = [self, _target.get_rid()]
		if sp.intersect_ray(r).is_empty(): return p
	return Vector3.INF

func _ready() -> void:
	add_to_group("bots")
	_pick_lane.call_deferred()
	# never inherit a 'platform' velocity from a body we stood on (e.g. another character that respawned far away)
	platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_DO_NOTHING
	add_to_group("combatant")
	_soldier = Soldier.new()
	add_child(_soldier)
	_soldier.gear = ["helmet", "helmet", "beret", "mask"][randi() % 4]
	_soldier.setup(tint)
	loadout = [Weapons.ORDER_PRIMARY.pick_random(), Weapons.ORDER_SECONDARY.pick_random(), "knife"]
	rusher = randf() < (0.6 if loadout[0] in ["shotgun", "mp5"] else 0.25) * D("tactics")
	_refill()
	_equip(loadout[0])
	_muzzle = Node3D.new(); _muzzle.position = Vector3(0.22, 1.3, -0.5)
	add_child(_muzzle)
	var col := CollisionShape3D.new()
	var cs := CapsuleShape3D.new(); cs.radius = 0.4; cs.height = 2.15
	col.shape = cs; col.position = Vector3(0, 1.075, 0)
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
	_hit_t = 0.0; _hits_here += 1
	if attacker != null and attacker is Node3D and _alive_of(attacker):
		_remember(attacker, (attacker as Node3D).global_position + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2)), false)
		var to := (attacker as Node3D).global_position - global_position
		if Vector2(to.x, to.z).length() > 0.5: look_at(global_position + Vector3(to.x, 0, to.z), Vector3.UP)
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
	_mem.clear(); _goal = Vector3.INF; _goal_mem = -1; _via = Vector3.INF
	_pick_lane()
	_cover = Vector3.INF; _peek = Vector3.INF; _cover_for = null; _retreated = false; _retreat_t = 0.0; _hits_here = 0
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

	_hit_t += delta
	if not MapIntel.ready and not MapIntel.points.is_empty(): MapIntel.finalize(get_world_3d(), global_position)
	_perc_cd -= delta
	if _perc_cd <= 0.0:
		_perc_cd = 0.2 + randf() * 0.05
		_perceive()
	_retarget_cd -= delta
	if _retarget_cd <= 0.0:
		_retarget_cd = D("react")
		_target = _pick_target()

	if frozen or busy:
		velocity.x = 0.0; velocity.z = 0.0
		if not is_on_floor(): velocity.y -= GRAVITY * delta
		move_and_slide()
		if _soldier: _soldier.drive(0.0, false)
		return

	if _engaged():
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
			var chance := (0.6 if not _has_los() else 0.2) * D("tactics")
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
			else:
				_fight(delta, to, dist)
		else:
			velocity.x = 0.0; velocity.z = 0.0
	elif objective != Vector3.INF:
		var tf := objective - global_position; tf.y = 0.0
		if tf.length() > 1.4:
			_move_to(objective, tf)
			_unstick(delta)
			var mv := Vector3(velocity.x, 0, velocity.z)
			if mv.length() > 0.1: look_at(global_position + mv, Vector3.UP)
		else:
			velocity.x = 0.0; velocity.z = 0.0
	else:
		_wander(delta)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	move_and_slide()

	if _soldier:
		var hs := Vector2(velocity.x, velocity.z).length()
		_soldier.drive(hs / SPEED, _engaged() and wid != "knife")

# stuck on a corner while walking to the objective: sidestep for a moment
var _stuck_t := 0.0
var _last_pos := Vector3.ZERO
var _side_t := 0.0
var _side_dir := Vector3.ZERO
func _unstick(delta: float) -> void:
	if _side_t > 0.0:
		_side_t -= delta
		velocity.x = _side_dir.x * _speed(); velocity.z = _side_dir.z * _speed()
		return
	if global_position.distance_to(_last_pos) < 0.6 * delta * _speed():
		_stuck_t += delta
	else:
		_stuck_t = 0.0
	_last_pos = global_position
	if _stuck_t > 0.8:
		_stuck_t = 0.0
		var f := Vector3(velocity.x, 0, velocity.z).normalized()
		_side_dir = f.rotated(Vector3.UP, PI * 0.5 * (1.0 if randf() < 0.5 else -1.0))
		_side_t = 0.5

# fight the current target? With an objective, ignore far enemies we can't see
func _engaged() -> bool:
	if _target == null or not _alive_of(_target):
		return false
	if objective == Vector3.INF or engage_range <= 0.0:
		return true
	var d := global_position.distance_to(_target.global_position)
	return d <= engage_range or _los_cached()

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
	if dir.length() < 0.15:
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

var _los_t := 0.0
var _los_v := false
func _los_cached() -> bool:
	# LOS checked a few times a second (path-in decision), not every frame
	var now := Time.get_ticks_msec() / 1000.0
	if now - _los_t > 0.25:
		_los_t = now; _los_v = _has_los()
	return _los_v

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
		_target.hit(int(Weapons.knife_damage(self, _target) * D("dmg") * 1.33), false, self)

func _fire_one(w: Dictionary) -> void:
	if _target == null:
		return
	_ammo[wid] = int(_ammo[wid]) - 1
	last_shot_t = Time.get_ticks_msec() / 1000.0
	BotPlayer.noise(global_position, self)
	var from := _muzzle.global_position
	Sfx.play_at("shot", from, -4.0)
	if _soldier: _soldier.shoot()
	var head_aim := Controls.bot_diff == "elite" and randf() < HEAD_AIM
	var aim := (_target.global_position + Vector3(0, _aim_h(_target) + (0.45 if head_aim else 0.0), 0)) - from
	var base := aim.normalized()
	var acc := D("spread") * (0.45 if wid == "sniper" else 1.0) + (float(w["spread"][0]) if w.has("pellets") else 0.0)
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
				var dmg := randi_range(int(w["dmg"][0]), int(w["dmg"][1])) * D("dmg") * (1.6 if is_head else 1.0)
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
