class_name Soldier
extends Node3D
## Animated character wrapper around the Quaternius CC0 mannequin (46 clips).
## Owner drives it each frame via drive() + shoot()/set_dead(); this picks and
## crossfades the right animation. Scale is 1.0 (model ~1.83m, feet at y=0).

const SRC: PackedScene = preload("res://assets/soldier/AnimationLibrary_Godot_Standard.gltf")

@export var yaw_offset := PI   # model faces +Z by default; flip to face owner -Z

var _ap: AnimationPlayer
var _sk: Skeleton3D
var _loco := 0.0
var _aiming := false
var _dead := false
var _oneshot := 0.0
var _base := "?"

func setup(team_color: Color, gear: Color = Color(0.11, 0.12, 0.14)) -> void:
	var inst := SRC.instantiate()
	inst.rotation.y = yaw_offset
	add_child(inst)
	for n in _all(inst):
		if n is AnimationPlayer:
			_ap = n
		elif n is Skeleton3D:
			_sk = n
		elif n is MeshInstance3D:
			_tint(n, team_color, gear)
	_attach_rifle()
	if _ap:
		_ap.play("Idle")
		_base = "Idle"

func drive(loco_ratio: float, aiming: bool) -> void:
	_loco = loco_ratio
	_aiming = aiming

func shoot() -> void:
	if _dead or _ap == null:
		return
	_ap.play("Pistol_Shoot", 0.03)
	_oneshot = 0.16
	_base = "?"   # force base to replay once the one-shot ends

func set_dead(d: bool) -> void:
	if d == _dead:
		return
	_dead = d
	_oneshot = 0.0
	_base = "?"
	if _ap:
		_ap.play("Death01" if d else "Idle", 0.12)
		if d:
			_base = "Death01"

func _process(dt: float) -> void:
	if _ap == null or _dead:
		return
	if _oneshot > 0.0:
		_oneshot -= dt
		return
	var want := "Idle"
	if _loco > 0.85:
		want = "Sprint"
	elif _loco > 0.45:
		want = "Jog_Fwd"
	elif _loco > 0.12:
		want = "Walk"
	elif _aiming:
		want = "Pistol_Idle"
	if want != _base:
		_base = want
		_ap.play(want, 0.15)

func _tint(mi: MeshInstance3D, team: Color, gear: Color) -> void:
	var m0 := StandardMaterial3D.new()
	m0.albedo_color = team
	mi.set_surface_override_material(0, m0)
	if mi.mesh and mi.mesh.get_surface_count() > 1:
		var m1 := StandardMaterial3D.new()
		m1.albedo_color = gear
		mi.set_surface_override_material(1, m1)

func _attach_rifle() -> void:
	if _sk == null:
		return
	var idx := _sk.find_bone("DEF-hand.R")
	if idx < 0:
		return
	var ba := BoneAttachment3D.new()
	ba.bone_name = "DEF-hand.R"
	_sk.add_child(ba)
	var gun := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(0.055, 0.11, 0.5)
	gun.mesh = bm
	var gmat := StandardMaterial3D.new(); gmat.albedo_color = Color(0.07, 0.07, 0.09)
	gun.material_override = gmat
	gun.position = Vector3(0.0, -0.02, -0.18)
	ba.add_child(gun)

func _all(n: Node) -> Array:
	var o: Array = [n]
	for c in n.get_children():
		o += _all(c)
	return o
