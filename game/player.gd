class_name PlayerBody
extends CharacterBody3D
## M0 player: joystick-driven movement + jump on a CharacterBody3D.
## Built fully in code so the scene file stays trivial (safe to hand-author / CI).

const SPEED := 5.0          # player.json: moveSpeed
const JUMP_VELOCITY := 8.0  # ~1.6m apex with GRAVITY below
const GRAVITY := 20.0

func _ready() -> void:
	_build()

func _build() -> void:
	# body
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.4
	cap.height = 1.8
	body.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.62, 0.24)
	body.material_override = mat
	body.position = Vector3(0.0, 0.9, 0.0)
	add_child(body)
	# facing indicator (shows which way we point)
	var nose := MeshInstance3D.new()
	var nb := BoxMesh.new()
	nb.size = Vector3(0.25, 0.25, 0.6)
	nose.mesh = nb
	var nmat := StandardMaterial3D.new()
	nmat.albedo_color = Color(1.0, 0.85, 0.5)
	nmat.emission_enabled = true
	nmat.emission = Color(1.0, 0.6, 0.2)
	nose.material_override = nmat
	nose.position = Vector3(0.0, 1.3, -0.5)
	add_child(nose)
	# collision
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	col.shape = shape
	col.position = Vector3(0.0, 0.9, 0.0)
	add_child(col)

func _physics_process(delta: float) -> void:
	var inp := Controls.move as Vector2
	var dir := Vector3(inp.x, 0.0, inp.y)
	if dir.length() > 1.0:
		dir = dir.normalized()
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	if is_on_floor():
		if bool(Controls.consume_jump()):
			velocity.y = JUMP_VELOCITY
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()
	if dir.length() > 0.15:
		look_at(global_position + Vector3(dir.x, 0.0, dir.z), Vector3.UP)
