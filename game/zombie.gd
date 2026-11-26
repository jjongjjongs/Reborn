class_name Zombie
extends CharacterBody3D
## M2 enemy (PlayerMonster model): NavMesh chase -> melee attack. Headshot aware.

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
var _agent: NavigationAgent3D
var _mat: StandardMaterial3D
var _flash := 0.0
var player: Node3D

func _ready() -> void:
	# never inherit a 'platform' velocity from a body we stood on (e.g. another character that respawned far away)
	platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_DO_NOTHING
	add_to_group("zombie")
	hp = MAX_HP * hp_scale * Difficulty.v("z_hp")
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new(); cap.radius = 0.4; cap.height = 1.8
	body.mesh = cap
	_mat = StandardMaterial3D.new(); _mat.albedo_color = Color(0.35, 0.55, 0.28)
	body.material_override = _mat
	body.position = Vector3(0, 0.9, 0)
	add_child(body)
	# head marker (visual only; headshot is height-based)
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new(); hm.radius = 0.28; hm.height = 0.56; head.mesh = hm
	var hmat := StandardMaterial3D.new(); hmat.albedo_color = Color(0.5, 0.65, 0.4); head.material_override = hmat
	head.position = Vector3(0, 1.65, 0)
	add_child(head)
	var col := CollisionShape3D.new()
	var cs := CapsuleShape3D.new(); cs.radius = 0.4; cs.height = 2.0
	col.shape = cs; col.position = Vector3(0, 1.0, 0)
	add_child(col)
	_agent = NavigationAgent3D.new()
	_agent.path_desired_distance = 0.5
	_agent.target_desired_distance = ATTACK_DIST * 0.8
	add_child(_agent)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 5.0)
		_mat.albedo_color = Color(0.35, 0.55, 0.28).lerp(Color(1, 0.3, 0.2), _flash)
	_atk_cd = maxf(0.0, _atk_cd - delta)
	_warmup = maxf(0.0, _warmup - delta)
	if player == null:
		return
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	if dist <= ATTACK_DIST:
		# attack
		if _atk_cd <= 0.0:
			_atk_cd = ATTACK_COOL
			if player.has_method("take_damage"):
				player.take_damage(int(ATTACK_DMG * Difficulty.v("z_dmg")))
		velocity.x = 0.0; velocity.z = 0.0
	elif _warmup <= 0.0:
		_agent.target_position = player.global_position
		var next := _agent.get_next_path_position()
		var dir := next - global_position
		dir.y = 0.0
		# off-mesh / no path / shoved onto cover -> beeline so it walks off and drops
		if dir.length() < 0.15 or global_position.y > 0.6:
			dir = to_player
		if dir.length() > 0.05:
			dir = dir.normalized()
			velocity.x = dir.x * SPEED * spd_scale * Difficulty.v("z_spd")
			velocity.z = dir.z * SPEED * spd_scale * Difficulty.v("z_spd")
			look_at(global_position + Vector3(dir.x, 0, dir.z), Vector3.UP)
	else:
		velocity.x = 0.0; velocity.z = 0.0
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	move_and_slide()

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
	Controls.kills += 1
	Missions.add("kill"); if Controls.weapon_id == "knife": Missions.add("knife_kill")
	Controls.points += 10
	if _last_head:
		Controls.points += 5
		Controls.headshots += 1
	Sfx.play_at("die", global_position)
	died.emit()
	# fall over + fade out
	var t := create_tween()
	t.tween_property(self, "rotation_degrees:x", -90.0, 0.25)
	t.parallel().tween_property(self, "scale", Vector3(1, 1, 1) * 0.9, 0.25)
	t.tween_interval(0.4)
	t.tween_callback(queue_free)
	# disable collision so bullets pass
	for c in get_children():
		if c is CollisionShape3D:
			c.set_deferred("disabled", true)
