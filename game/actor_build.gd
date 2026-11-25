class_name ActorBuild
## Shared humanoid "soldier" rig built from primitives (no external assets).
## Used by the player and bots so every combatant reads as a soldier, not a
## capsule. Collision + nav stay in the owning script; this only adds visuals.
## Returns { "mat": <torso material for hit-flash>, "muzzle": <Node3D> }.

static func _box(host: Node3D, size: Vector3, pos: Vector3, c: Color, mat: StandardMaterial3D = null) -> StandardMaterial3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size; m.mesh = bm
	if mat == null:
		mat = StandardMaterial3D.new(); mat.albedo_color = c
	m.material_override = mat
	m.position = pos
	host.add_child(m)
	return mat

static func _sphere(host: Node3D, r: float, pos: Vector3, c: Color) -> void:
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = r; sm.height = r * 2.0; m.mesh = sm
	var mat := StandardMaterial3D.new(); mat.albedo_color = c
	m.material_override = mat
	m.position = pos
	host.add_child(m)

static func soldier(host: Node3D, tint: Color, accent: Color) -> Dictionary:
	var dark := Color(0.14, 0.16, 0.20)
	var pants := Color(0.20, 0.22, 0.26)
	# legs
	_box(host, Vector3(0.17, 0.82, 0.22), Vector3(-0.11, 0.42, 0.0), pants)
	_box(host, Vector3(0.17, 0.82, 0.22), Vector3(0.11, 0.42, 0.0), pants)
	# torso (returns the material we flash on hit)
	var torso_mat := _box(host, Vector3(0.46, 0.62, 0.28), Vector3(0.0, 1.04, 0.0), tint)
	# chest rig / team accent band
	_box(host, Vector3(0.50, 0.17, 0.31), Vector3(0.0, 1.14, 0.0), accent)
	# backpack
	_box(host, Vector3(0.30, 0.40, 0.16), Vector3(0.0, 1.06, 0.17), dark)
	# arms / shoulders
	_box(host, Vector3(0.16, 0.48, 0.16), Vector3(-0.33, 1.05, 0.0), tint.darkened(0.12))
	_box(host, Vector3(0.16, 0.48, 0.16), Vector3(0.33, 1.05, 0.0), tint.darkened(0.12))
	# head + helmet (headshot zone sits above y+1.55)
	_sphere(host, 0.17, Vector3(0.0, 1.60, 0.02), Color(0.82, 0.66, 0.54))
	_sphere(host, 0.205, Vector3(0.0, 1.66, 0.0), dark)
	# rifle
	_box(host, Vector3(0.10, 0.12, 0.72), Vector3(0.24, 1.18, -0.30), Color(0.09, 0.09, 0.11))
	_box(host, Vector3(0.07, 0.20, 0.10), Vector3(0.24, 1.06, -0.18), Color(0.12, 0.12, 0.14))
	var muzzle := Node3D.new(); muzzle.position = Vector3(0.24, 1.18, -0.72)
	host.add_child(muzzle)
	return {"mat": torso_mat, "muzzle": muzzle}
