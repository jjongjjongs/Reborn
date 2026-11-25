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
const REACTION := 0.3       # retarget / react cadence (difficulty)
const DMG_MIN := 7
const DMG_MAX := 13
const SPREAD := 4.5         # aim inaccuracy (deg)
const BURST_MIN := 3
const BURST_MAX := 6
const SHOT_DELAY := 0.13
const BURST_COOL := 0.9
const MAX_HP := 100.0

const INVULN := 2.0

var hp := MAX_HP
var alive := true
var invuln_t := 0.0
var kills := 0
var bot_name := "BOT"
var tint := Color(0.80, 0.32, 0.30)

var _agent: NavigationAgent3D
var _muzzle: Node3D
var _mat: StandardMaterial3D
var _flash := 0.0
var _warmup := 0.6
var _target: Node3D
var _retarget_cd := 0.0
var _burst := 0
var _shot_cd := 0.0
var _burst_cd := 0.0

func _ready() -> void:
	add_to_group("combatant")
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new(); cap.radius = 0.4; cap.height = 1.8
	body.mesh = cap
	_mat = StandardMaterial3D.new(); _mat.albedo_color = tint
	body.material_override = _mat
	body.position = Vector3(0, 0.9, 0)
	add_child(body)
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new(); hm.radius = 0.26; hm.height = 0.52; head.mesh = hm
	var hmat := StandardMaterial3D.new(); hmat.albedo_color = tint.lightened(0.15); head.material_override = hmat
	head.position = Vector3(0, 1.62, 0)
	add_child(head)
	var gun := MeshInstance3D.new()
	var gm := BoxMesh.new(); gm.size = Vector3(0.12, 0.12, 0.6); gun.mesh = gm
	var gmat := StandardMaterial3D.new(); gmat.albedo_color = Color(0.1, 0.1, 0.12); gun.material_override = gmat
	gun.position = Vector3(0.26, 1.2, -0.3)
	add_child(gun)
	_muzzle = Node3D.new(); _muzzle.position = Vector3(0.26, 1.2, -0.7)
	add_child(_muzzle)
	var col := CollisionShape3D.new()
	var cs := CapsuleShape3D.new(); cs.radius = 0.4; cs.height = 2.0
	col.shape = cs; col.position = Vector3(0, 1.0, 0)
	add_child(col)
	_agent = NavigationAgent3D.new()
	_agent.path_desired_distance = 0.6
	_agent.target_desired_distance = COMBAT_DIST * 0.8
	add_child(_agent)

func hit(dmg: int, _is_head: bool = false, attacker = null) -> void:
	if not alive or invuln_t > 0.0:
		return
	hp -= dmg
	_flash = 1.0
	if hp <= 0.0:
		alive = false
		for c in get_children():
			if c is CollisionShape3D:
				c.set_deferred("disabled", true)
		visible = false
		died.emit(attacker)

func respawn_at(pos: Vector3) -> void:
	alive = true
	invuln_t = INVULN
	hp = MAX_HP
	global_position = pos
	velocity = Vector3.ZERO
	visible = true
	_target = null
	_burst = 0
	_warmup = 0.4
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
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 5.0)
		_mat.albedo_color = tint.lerp(Color(1, 0.9, 0.5), _flash)

	_retarget_cd -= delta
	if _retarget_cd <= 0.0:
		_retarget_cd = REACTION
		_target = _find_nearest()

	if _target != null and _alive_of(_target):
		var to := _target.global_position - global_position
		to.y = 0.0
		var dist := to.length()
		if to.length() > 0.1:
			look_at(global_position + Vector3(to.x, 0, to.z), Vector3.UP)
		if _warmup <= 0.0:
			if dist > COMBAT_DIST:
				_move_to(_target.global_position, to)
			elif dist < MIN_DIST:
				var away := -to.normalized()
				velocity.x = away.x * SPEED; velocity.z = away.z * SPEED
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

func _move_to(dest: Vector3, to_flat: Vector3) -> void:
	_agent.target_position = dest
	var next := _agent.get_next_path_position()
	var dir := next - global_position
	dir.y = 0.0
	if dir.length() < 0.15 or global_position.y > 0.6:
		dir = to_flat
	if dir.length() > 0.05:
		dir = dir.normalized()
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED

func _alive_of(n: Node) -> bool:
	return n != null and "alive" in n and n.alive

func _find_nearest() -> Node3D:
	var best: Node3D = null
	var bd := 1e9
	for c in get_tree().get_nodes_in_group("combatant"):
		if c == self or not _alive_of(c):
			continue
		var d := global_position.distance_to((c as Node3D).global_position)
		if d < bd:
			bd = d; best = c
	return best

func _has_los() -> bool:
	if _target == null:
		return false
	var from := global_position + Vector3(0, 1.4, 0)
	var to := _target.global_position + Vector3(0, 1.3, 0)
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit.is_empty() or hit.collider == _target

func _try_fire(delta: float) -> void:
	_burst_cd -= delta
	_shot_cd -= delta
	if not _has_los():
		return
	if _burst > 0:
		if _shot_cd <= 0.0:
			_fire_one()
			_burst -= 1
			_shot_cd = SHOT_DELAY
	elif _burst_cd <= 0.0:
		_burst = randi_range(BURST_MIN, BURST_MAX)
		_burst_cd = BURST_COOL

func _fire_one() -> void:
	if _target == null:
		return
	var from := _muzzle.global_position
	var aim := (_target.global_position + Vector3(0, 1.1, 0)) - from
	var dir := aim.normalized()
	var s := deg_to_rad(SPREAD)
	dir = dir.rotated(Vector3.UP, randf_range(-s, s))
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
			col.hit(randi_range(DMG_MIN, DMG_MAX), false, self)
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
