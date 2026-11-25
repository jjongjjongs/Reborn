class_name PlayerBody
extends CharacterBody3D
## M1 player: aim-relative movement, look (yaw/pitch), hitscan shooting with
## dynamic accuracy, ammo + reload. Built in code.

const SPEED := 5.0
const JUMP_VELOCITY := 8.0
const GRAVITY := 20.0

# weapon (rifle-ish, M4). Real tuning moves to weapons.json later.
const FIRE_INTERVAL := 0.11
const MAG := 30
const RELOAD_TIME := 1.5
const SPREAD_MIN := 0.8
const SPREAD_MAX := 7.0
const BLOOM_PER_SHOT := 0.55
const BLOOM_RECOVER := 7.0   # deg/sec

var aim_yaw := 0.0     # degrees
var aim_pitch := 0.0   # degrees (camera only)
var _bloom := 0.0
var _fire_cd := 0.0
var _reload_t := 0.0
var _muzzle: Node3D

func _ready() -> void:
	_build()

func _build() -> void:
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new(); cap.radius = 0.4; cap.height = 1.8
	body.mesh = cap
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.95, 0.62, 0.24)
	body.material_override = mat
	body.position = Vector3(0, 0.9, 0)
	add_child(body)
	# gun stub + muzzle (points -Z = forward)
	var gun := MeshInstance3D.new()
	var gm := BoxMesh.new(); gm.size = Vector3(0.14, 0.14, 0.7); gun.mesh = gm
	var gmat := StandardMaterial3D.new(); gmat.albedo_color = Color(0.1, 0.1, 0.12); gun.material_override = gmat
	gun.position = Vector3(0.28, 1.25, -0.35)
	add_child(gun)
	_muzzle = Node3D.new(); _muzzle.position = Vector3(0.28, 1.25, -0.75)
	add_child(_muzzle)
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new(); shape.radius = 0.4; shape.height = 1.8
	col.shape = shape; col.position = Vector3(0, 0.9, 0)
	add_child(col)

func _physics_process(delta: float) -> void:
	# look
	var l := Controls.consume_look()
	aim_yaw -= l.x
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
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	if is_on_floor():
		if Controls.consume_jump():
			velocity.y = JUMP_VELOCITY
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()

	# reload
	if _reload_t > 0.0:
		_reload_t -= delta
		if _reload_t <= 0.0:
			Controls.ammo = MAG
			Controls.reloading = false
	elif Controls.consume_reload() and Controls.ammo < MAG:
		_start_reload()

	# fire
	_fire_cd = maxf(0.0, _fire_cd - delta)
	if Controls.fire_held and _fire_cd <= 0.0 and _reload_t <= 0.0:
		if Controls.ammo > 0:
			_shoot()
			_fire_cd = FIRE_INTERVAL
		else:
			_start_reload()

	# dynamic spread
	var moving := inp.length() > 0.1
	_bloom = maxf(0.0, _bloom - BLOOM_RECOVER * delta)
	Controls.spread_deg = clampf(SPREAD_MIN + (2.0 if moving else 0.0) + _bloom, SPREAD_MIN, SPREAD_MAX)

func _start_reload() -> void:
	_reload_t = RELOAD_TIME
	Controls.reloading = true

func _shoot() -> void:
	Controls.ammo -= 1
	_bloom = minf(_bloom + BLOOM_PER_SHOT, SPREAD_MAX)
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var from := cam.global_position
	var dir := -cam.global_transform.basis.z
	# apply spread cone
	var s := deg_to_rad(Controls.spread_deg)
	dir = dir.rotated(cam.global_transform.basis.x, randf_range(-s, s))
	dir = dir.rotated(cam.global_transform.basis.y, randf_range(-s, s))
	var to := from + dir * 200.0
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [self]
	var hit := space.intersect_ray(q)
	var end := to
	if hit:
		end = hit.position
		_impact(hit.position)
		var col = hit.collider
		if col and col.has_method("on_hit"):
			col.on_hit()
	_tracer(_muzzle.global_position, end)
	_muzzle_flash()

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
