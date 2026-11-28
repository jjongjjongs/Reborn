class_name Zombie
extends CharacterBody3D
## M2 enemy (mini zombie body on the soldier rig): NavMesh chase -> swipe attack. Headshot aware.

const SPEED := 2.4
const GRAVITY := 20.0
const ATTACK_DIST := 1.8
const ATTACK_COOL := 1.1
const ATTACK_DMG := 10
const MAX_HP := 60.0

signal died

var hp_scale := 1.0
var spd_scale := 1.0
var hp := MAX_HP
var _atk_cd := 0.0
var _warmup := 0.6   # idle until the nav map is synced
var _dead := false
var _last_head := false
var _repath_t := 0.0
var _agent: NavigationAgent3D
var _body: Soldier
var _flash := 0.0
var player: Node3D
var respawn_pts: Array = []      # where a hopelessly stuck zombie is put back (wave spawns)
var _stuck_t := 0.0
var _stuck_hits := 0
var _climbing := false
var _climb_tw: Tween
var _stuck_from := Vector3.ZERO

func _ready() -> void:
	# never inherit a 'platform' velocity from a body we stood on (e.g. another character that respawned far away)
	platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_DO_NOTHING
	add_to_group("zombie")
	hp = MAX_HP * hp_scale * Difficulty.v("z_hp")
	# body: the soldier rig with the zombie mesh, arms reaching forward (the pistol-ready pose, gun hidden)
	_body = Soldier.new(); _body.body = "zombie"; _body.cheap = true
	add_child(_body)
	_body.setup(Color(0.35, 0.55, 0.28))
	_body.set_weapon("pistol")
	if _body._wmodel: _body._wmodel.visible = false
	_body.drive(0.0, true)
	var col := CollisionShape3D.new()
	var cs := CapsuleShape3D.new(); cs.radius = 0.4; cs.height = 2.1
	col.shape = cs; col.position = Vector3(0, 1.05, 0)
	add_child(col)
	_agent = NavigationAgent3D.new()
	_agent.path_desired_distance = 0.5
	_agent.target_desired_distance = ATTACK_DIST * 0.8
	_agent.link_reached.connect(_on_link)
	add_child(_agent)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if _flash > 0.0:   # hit: a quick flinch backwards
		_flash = maxf(0.0, _flash - delta * 6.0)
		_body.rotation.x = -0.18 * _flash
	if _climbing:
		velocity = Vector3.ZERO
		return
	_atk_cd = maxf(0.0, _atk_cd - delta)
	_warmup = maxf(0.0, _warmup - delta)
	if player == null:
		return
	if global_position.y < -8.0 and not respawn_pts.is_empty():   # fell out of the world: back to a spawn
		global_position = respawn_pts[randi() % respawn_pts.size()]; velocity = Vector3.ZERO
	var to_player := player.global_position - global_position
	var dy := absf(to_player.y)
	to_player.y = 0.0
	var dist := to_player.length()
	if dist <= ATTACK_DIST and dy < 1.6:     # not through a roof / from under the canopy
		# attack
		if _atk_cd <= 0.0:
			_atk_cd = ATTACK_COOL
			_body.throw()                  # overhead swipe
			if player.has_method("take_damage"):
				player.take_damage(int(ATTACK_DMG * Difficulty.v("z_dmg")))
		velocity.x = 0.0; velocity.z = 0.0
		if dist > 0.1: look_at(global_position + to_player, Vector3.UP)
	elif _warmup <= 0.0:
		_repath_t -= delta
		if _repath_t <= 0.0 or player.global_position.distance_squared_to(_agent.target_position) > 4.0:   # re-plan ~3x a second, not every frame
			_agent.target_position = player.global_position; _repath_t = 0.3 + randf() * 0.1
		var next := _agent.get_next_path_position()
		var dir := next - global_position
		dir.y = 0.0
		# no path (target unreachable / we are off the mesh): head straight at the player
		if dir.length() < 0.15 and _agent.is_navigation_finished():
			dir = to_player
		if dir.length() > 0.05:
			dir = dir.normalized()
			velocity.x = dir.x * SPEED * spd_scale * Difficulty.v("z_spd")
			velocity.z = dir.z * SPEED * spd_scale * Difficulty.v("z_spd")
			look_at(global_position + Vector3(dir.x, 0, dir.z), Vector3.UP)
		# stuck watchdog: barely moved for a while while chasing -> sidestep, then put back at a spawn
		_stuck_t += delta
		if _agent.is_navigation_finished() or dist < 4.0:   # waiting under the player is not "stuck"
			_stuck_t = 0.0; _stuck_hits = 0; _stuck_from = global_position
		elif _stuck_t > 1.2:
			var moved := global_position.distance_to(_stuck_from)
			if moved < 0.4:
				_stuck_hits += 1
				if _stuck_hits >= 3 and not respawn_pts.is_empty():
					global_position = respawn_pts[randi() % respawn_pts.size()]
					velocity = Vector3.ZERO; _stuck_hits = 0
				else:
					var side := Vector3(-dir.z, 0, dir.x) * (1.0 if randf() < 0.5 else -1.0)
					global_position += side * 0.35 + Vector3(0, 0.05, 0)
			else:
				_stuck_hits = 0
			_stuck_t = 0.0; _stuck_from = global_position
	else:
		velocity.x = 0.0; velocity.z = 0.0
	_body.drive(clampf(Vector2(velocity.x, velocity.z).length() / 5.0, 0.0, 0.6), true)   # shamble: walk / jog, never sprint
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	var want := Vector3(velocity.x, 0, velocity.z) * delta
	move_and_slide()
	# step up low ledges (stair sides, kerbs) instead of walking into them
	if is_on_wall() and is_on_floor() and want.length() > 0.001:
		var up := Vector3(0, 0.32, 0)
		if not test_move(global_transform, up) and not test_move(global_transform.translated(up), want * 3.0):
			global_position += up + want

# a climb link on the path (jump routes up to roofs): lean into the wall and haul up to the top.
# Slow on purpose: the roof buys the player time, it is not a safe spot.
func _on_link(details: Dictionary) -> void:
	if _dead or _climbing: return
	var a: Vector3 = details.get("link_entry_position", global_position)
	var b: Vector3 = details.get("link_exit_position", global_position)
	if b.y < a.y + 0.6: return                 # going down: just walk off the edge
	_climbing = true
	var flat := Vector3(b.x - a.x, 0, b.z - a.z)
	if flat.length() > 0.1: look_at(global_position + flat, Vector3.UP)
	var steps: Array = []
	var owner_n = details.get("owner", null)
	if owner_n is Node and (owner_n as Node).has_meta("via"): steps = ((owner_n as Node).get_meta("via") as Array).duplicate()
	steps.append(b)
	_body.rotation.x = -0.3                     # lean in, arms reaching up
	var t := create_tween(); _climb_tw = t
	var cur := global_position
	for st in steps:                            # hop up each step: haul up, then onto it
		var p: Vector3 = st
		var rise := maxf(p.y - cur.y, 0.0)
		t.tween_property(self, "global_position", Vector3(cur.x, p.y + 0.25, cur.z).lerp(Vector3(p.x, p.y + 0.25, p.z), 0.3), 0.25 + 0.3 * rise)
		t.tween_property(self, "global_position", p + Vector3(0, 0.08, 0), 0.22)
		t.tween_interval(0.12)
		cur = p
	t.tween_callback(func() -> void:
		_climbing = false; _body.rotation.x = 0.0; _stuck_t = 0.0; _stuck_from = global_position)

func hit(dmg: int, is_head: bool = false, _attacker = null) -> void:
	if _dead:
		return
	_last_head = is_head
	hp -= dmg
	_flash = 1.0
	if hp <= 0.0:
		_die()

func _die() -> void:
	_dead = true
	FxCos.my_kill(self)
	_climbing = false
	if _climb_tw and _climb_tw.is_valid(): _climb_tw.kill()
	Controls.kills += 1
	Missions.add("kill"); if Controls.weapon_id == "knife": Missions.add("knife_kill")
	Controls.points += 10
	if _last_head:
		Controls.points += 5
		Controls.headshots += 1
	Sfx.play_at("die", global_position)
	died.emit()
	# death animation, then sink into the floor
	_body.rotation.x = 0.0
	_body.set_dead(true)
	var t := create_tween()
	t.tween_interval(1.1)
	t.tween_property(_body, "position:y", -0.6, 0.5)
	t.tween_callback(queue_free)
	# disable collision so bullets pass
	for c in get_children():
		if c is CollisionShape3D:
			c.set_deferred("disabled", true)
