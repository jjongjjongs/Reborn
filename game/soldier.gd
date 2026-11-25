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
var _gun: Node3D
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
	_build_gun()
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
	# dark tactical uniform (faint team hue) + a vivid team-color accent region
	var uniform := _team.lerp(Color(0.15, 0.17, 0.18), 0.72)
	var accent := _team.lerp(Color(0.10, 0.10, 0.10), 0.12)
	var m0 := StandardMaterial3D.new(); m0.albedo_color = uniform; m0.roughness = 0.9
	mi.set_surface_override_material(0, m0)
	if mi.mesh and mi.mesh.get_surface_count() > 1:
		var m1 := StandardMaterial3D.new(); m1.albedo_color = accent; m1.roughness = 0.85
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

func _update_attachments() -> void:
	if _sk == null or _gun == null or _hand_idx < 0:
		return
	var body := get_parent()
	var basis: Basis = global_transform.basis
	if body is Node3D:
		basis = (body as Node3D).global_transform.basis
	var hw: Vector3 = (_sk.global_transform * _sk.get_bone_global_pose(_hand_idx)).origin
	_gun.global_transform = Transform3D(basis, hw + basis * Vector3(0.02, 0.02, 0.0))
	_gun.visible = visible and not _dead

func _all(n: Node) -> Array:
	var o: Array = [n]
	for c in n.get_children():
		o += _all(c)
	return o
