class_name Soldier
extends Node3D
## Animated soldier built on the Quaternius CC0 mannequin (46 clips). Reskinned
## as a tactical trooper: dark uniform, bone-tracked helmet + team-colored plate
## carrier, and a rifle. Gear/weapon follow the animated bones' WORLD positions
## but take the body's orientation (so no dependency on each bone's local axes).
## Owner drives it via drive() + shoot()/set_dead().

const SRC: PackedScene = preload("res://assets/soldier/AnimationLibrary_Godot_Standard.gltf")

@export var yaw_offset := PI

var _ap: AnimationPlayer
var _sk: Skeleton3D
var _hand_idx := -1
var _head_idx := -1
var _chest_idx := -1
var _gun: Node3D
var _helmet: Node3D
var _vest: Node3D
var _loco := 0.0
var _aiming := false
var _dead := false
var _oneshot := 0.0
var _base := "?"
var _gear_dark := StandardMaterial3D.new()
var _team := Color(0.8, 0.4, 0.3)

func setup(team_color: Color, _gear: Color = Color(0.11, 0.12, 0.14)) -> void:
	_team = team_color
	_gear_dark.albedo_color = Color(0.12, 0.13, 0.16)
	var inst := SRC.instantiate()
	inst.rotation.y = yaw_offset
	add_child(inst)
	for n in _all(inst):
		if n is AnimationPlayer:
			_ap = n
		elif n is Skeleton3D:
			_sk = n
		elif n is MeshInstance3D:
			_tint(n)
	if _sk != null:
		_hand_idx = _sk.find_bone("DEF-hand.R")
		_head_idx = _sk.find_bone("DEF-head")
		_chest_idx = _sk.find_bone("DEF-spine.003")
	_build_gun()
	_build_gear()
	if _ap:
		_ap.play("Idle"); _base = "Idle"

func drive(loco_ratio: float, aiming: bool) -> void:
	_loco = loco_ratio; _aiming = aiming

func shoot() -> void:
	if _dead or _ap == null:
		return
	_ap.play("Pistol_Shoot", 0.03)
	_oneshot = 0.16; _base = "?"

func set_dead(d: bool) -> void:
	if d == _dead:
		return
	_dead = d; _oneshot = 0.0; _base = "?"
	if _ap:
		_ap.play("Death01" if d else "Idle", 0.12)
		if d: _base = "Death01"

func _process(dt: float) -> void:
	_update_attachments()
	if _ap == null or _dead:
		return
	if _oneshot > 0.0:
		_oneshot -= dt
		return
	var want := "Idle"
	if _loco > 0.85: want = "Sprint"
	elif _loco > 0.45: want = "Jog_Fwd"
	elif _loco > 0.12: want = "Walk"
	elif _aiming: want = "Pistol_Idle"
	if want != _base:
		_base = want
		_ap.play(want, 0.15)

# ---- appearance ----
func _tint(mi: MeshInstance3D) -> void:
	# darker, desaturated team hue so the body reads as a uniform, not a blob
	var uniform := _team.lerp(Color(0.14, 0.16, 0.19), 0.58)
	var m0 := StandardMaterial3D.new(); m0.albedo_color = uniform
	m0.roughness = 0.9
	mi.set_surface_override_material(0, m0)
	if mi.mesh and mi.mesh.get_surface_count() > 1:
		var m1 := StandardMaterial3D.new(); m1.albedo_color = Color(0.10, 0.11, 0.13)
		m1.roughness = 0.9
		mi.set_surface_override_material(1, m1)

func _mesh(parent: Node3D, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new(); b.size = size; m.mesh = b
	m.material_override = mat; m.position = pos
	parent.add_child(m)

func _build_gun() -> void:
	_gun = Node3D.new(); add_child(_gun)
	var body := _gear_dark
	# receiver, barrel, stock, mag, sight — extends forward along -Z
	_mesh(_gun, Vector3(0.05, 0.10, 0.34), Vector3(0, 0, -0.12), body)
	_mesh(_gun, Vector3(0.03, 0.03, 0.30), Vector3(0, 0.01, -0.40), body)
	_mesh(_gun, Vector3(0.045, 0.09, 0.14), Vector3(0, -0.01, 0.12), body)
	_mesh(_gun, Vector3(0.04, 0.13, 0.05), Vector3(0, -0.09, -0.06), body)
	_mesh(_gun, Vector3(0.018, 0.05, 0.03), Vector3(0, 0.08, -0.18), body)

func _build_gear() -> void:
	var team_mat := StandardMaterial3D.new(); team_mat.albedo_color = _team; team_mat.roughness = 0.75
	# plate carrier (team color — the main team identifier)
	_vest = Node3D.new(); add_child(_vest)
	_mesh(_vest, Vector3(0.40, 0.42, 0.26), Vector3(0, 0, 0), team_mat)
	_mesh(_vest, Vector3(0.44, 0.10, 0.28), Vector3(0, 0.10, 0), _gear_dark)
	_mesh(_vest, Vector3(0.14, 0.16, 0.02), Vector3(0, -0.02, -0.14), _gear_dark)
	# helmet
	_helmet = Node3D.new(); add_child(_helmet)
	var dome := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 0.16; sm.height = 0.28; dome.mesh = sm
	dome.material_override = _gear_dark
	_helmet.add_child(dome)
	_mesh(_helmet, Vector3(0.34, 0.05, 0.34), Vector3(0, -0.04, 0), _gear_dark)  # brim

func _update_attachments() -> void:
	if _sk == null:
		return
	var body := get_parent()
	var basis: Basis = global_transform.basis
	if body is Node3D:
		basis = (body as Node3D).global_transform.basis
	var vis := visible and not _dead
	if _gun != null and _hand_idx >= 0:
		var hw: Vector3 = (_sk.global_transform * _sk.get_bone_global_pose(_hand_idx)).origin
		_gun.global_transform = Transform3D(basis, hw + basis * Vector3(0.02, 0.02, 0.0))
		_gun.visible = vis
	if _helmet != null and _head_idx >= 0:
		var hd: Vector3 = (_sk.global_transform * _sk.get_bone_global_pose(_head_idx)).origin
		_helmet.global_transform = Transform3D(basis, hd + basis * Vector3(0.0, 0.07, 0.0))
		_helmet.visible = vis
	if _vest != null and _chest_idx >= 0:
		var cw: Vector3 = (_sk.global_transform * _sk.get_bone_global_pose(_chest_idx)).origin
		_vest.global_transform = Transform3D(basis, cw + basis * Vector3(0.0, 0.0, -0.04))
		_vest.visible = vis

func _all(n: Node) -> Array:
	var o: Array = [n]
	for c in n.get_children():
		o += _all(c)
	return o
