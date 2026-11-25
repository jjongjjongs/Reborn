class_name Soldier
extends Node3D
## Animated SWAT trooper. The Quaternius SWAT mesh (its own simple rig) is posed
## at runtime by RETARGETING from a hidden Universal-Animation-Library mannequin
## (Rigify rig) that actually plays the 46 clips. Bones are matched by name map;
## each target bone copies the source's rotation delta from its rest pose.
## Owner drives it via drive() + shoot()/set_dead().

const SWAT: PackedScene = preload("res://assets/soldier/Swat.glb")
const ANIM: PackedScene = preload("res://assets/soldier/AnimationLibrary_Godot_Standard.gltf")

# SWAT bone -> animation-library (Rigify) bone
const MAP := {
	"Hips": "DEF-hips", "Abdomen": "DEF-spine.001", "Torso": "DEF-spine.002", "Chest": "DEF-spine.003",
	"Neck": "DEF-neck", "Head": "DEF-head",
	"Shoulder.L": "DEF-shoulder.L", "UpperArm.L": "DEF-upper_arm.L", "LowerArm.L": "DEF-forearm.L", "Hand.L": "DEF-hand.L",
	"Shoulder.R": "DEF-shoulder.R", "UpperArm.R": "DEF-upper_arm.R", "LowerArm.R": "DEF-forearm.R", "Hand.R": "DEF-hand.R",
	"UpperLeg.L": "DEF-thigh.L", "LowerLeg.L": "DEF-shin.L", "Foot.L": "DEF-foot.L",
	"UpperLeg.R": "DEF-thigh.R", "LowerLeg.R": "DEF-shin.R", "Foot.R": "DEF-foot.R",
	"Index2.L": "DEF-f_index.01.L", "Index3.L": "DEF-f_index.02.L", "Index4.L": "DEF-f_index.03.L",
	"Middle2.L": "DEF-f_middle.01.L", "Middle3.L": "DEF-f_middle.02.L", "Middle4.L": "DEF-f_middle.03.L",
	"Ring2.L": "DEF-f_ring.01.L", "Ring3.L": "DEF-f_ring.02.L", "Ring4.L": "DEF-f_ring.03.L",
	"Pinky2.L": "DEF-f_pinky.01.L", "Pinky3.L": "DEF-f_pinky.02.L", "Pinky4.L": "DEF-f_pinky.03.L",
	"Thumb2.L": "DEF-thumb.01.L", "Thumb3.L": "DEF-thumb.02.L",
	"Index2.R": "DEF-f_index.01.R", "Index3.R": "DEF-f_index.02.R", "Index4.R": "DEF-f_index.03.R",
	"Middle2.R": "DEF-f_middle.01.R", "Middle3.R": "DEF-f_middle.02.R", "Middle4.R": "DEF-f_middle.03.R",
	"Ring2.R": "DEF-f_ring.01.R", "Ring3.R": "DEF-f_ring.02.R", "Ring4.R": "DEF-f_ring.03.R",
	"Pinky2.R": "DEF-f_pinky.01.R", "Pinky3.R": "DEF-f_pinky.02.R", "Pinky4.R": "DEF-f_pinky.03.R",
	"Thumb2.R": "DEF-thumb.01.R", "Thumb3.R": "DEF-thumb.02.R",
}
const GEAR_GREY := Color(0.3098, 0.3255, 0.3529)

@export var yaw_offset := PI

var _ap: AnimationPlayer
var _src: Skeleton3D
var _tgt: Skeleton3D
var _hand_idx := -1
var _gun: Node3D
var _tgt_idx := PackedInt32Array()
var _src_idx := PackedInt32Array()
var _tgt_par := PackedInt32Array()                 # target bone's parent index
var _tgt_grest: Array[Quaternion] = []             # target bone global rest rotation
var _src_grest_inv: Array[Quaternion] = []         # source bone global rest rotation, inverted
var _loco := 0.0
var _aiming := false
var _dead := false
var _oneshot := 0.0
var _base := "?"
var _team := Color(0.8, 0.4, 0.3)
var _gun_mat := StandardMaterial3D.new()

func setup(team_color: Color, _gear: Color = Color.BLACK) -> void:
	_team = team_color
	_gun_mat.albedo_color = Color(0.07, 0.07, 0.09)
	# visible SWAT
	var swat := SWAT.instantiate()
	swat.rotation.y = yaw_offset
	add_child(swat)
	for n in _all(swat):
		if n is Skeleton3D: _tgt = n
		elif n is MeshInstance3D: _team_tint(n)
	# hidden animation driver
	var anim := ANIM.instantiate()
	anim.rotation.y = yaw_offset
	add_child(anim)
	for n in _all(anim):
		if n is AnimationPlayer: _ap = n
		elif n is Skeleton3D: _src = n
		elif n is MeshInstance3D: (n as MeshInstance3D).visible = false
	_build_map()
	_build_gun()
	if _tgt: _hand_idx = _tgt.find_bone("Hand.R")
	if _ap: _ap.play("Idle"); _base = "Idle"

func _build_map() -> void:
	if _tgt == null or _src == null: return
	var entries := []
	for swat_bone in MAP:
		var ti := _tgt.find_bone(swat_bone)
		var si := _src.find_bone(MAP[swat_bone])
		if ti < 0 or si < 0: continue
		entries.append({"ti": ti, "si": si, "depth": _depth(ti)})
	entries.sort_custom(func(a, b): return a["depth"] < b["depth"])   # parents before children
	for e in entries:
		_tgt_idx.append(e["ti"]); _src_idx.append(e["si"])
		_tgt_par.append(_tgt.get_bone_parent(e["ti"]))
		_tgt_grest.append(_tgt.get_bone_global_rest(e["ti"]).basis.get_rotation_quaternion())
		_src_grest_inv.append(_src.get_bone_global_rest(e["si"]).basis.get_rotation_quaternion().inverse())

func _depth(idx: int) -> int:
	var d := 0
	var p := _tgt.get_bone_parent(idx)
	while p >= 0:
		d += 1; p = _tgt.get_bone_parent(p)
	return d

func drive(loco_ratio: float, aiming: bool) -> void:
	_loco = loco_ratio; _aiming = aiming

func shoot() -> void:
	if _dead or _ap == null: return
	_ap.play("Pistol_Shoot", 0.03); _oneshot = 0.16; _base = "?"

func set_dead(d: bool) -> void:
	if d == _dead: return
	_dead = d; _oneshot = 0.0; _base = "?"
	if _ap:
		_ap.play("Death01" if d else "Idle", 0.12)
		if d: _base = "Death01"

func _process(dt: float) -> void:
	_retarget()
	_update_gun()
	if _ap == null or _dead: return
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

func _retarget() -> void:
	if _tgt == null or _src == null: return
	# model-space (global) retarget: take the source bone's rotation relative to its
	# own global rest, apply it onto the target's global rest, then convert back to a
	# local pose using the (already-updated) parent. Handles A-pose vs T-pose rigs.
	for i in _tgt_idx.size():
		var srg := _src.get_bone_global_pose(_src_idx[i]).basis.get_rotation_quaternion()
		var desired := (srg * _src_grest_inv[i]) * _tgt_grest[i]
		var par := _tgt_par[i]
		var pg := Quaternion.IDENTITY
		if par >= 0:
			pg = _tgt.get_bone_global_pose(par).basis.get_rotation_quaternion()
		_tgt.set_bone_pose_rotation(_tgt_idx[i], pg.inverse() * desired)

func _team_tint(mi: MeshInstance3D) -> void:
	if mi.mesh == null: return
	var grey := Vector3(GEAR_GREY.r, GEAR_GREY.g, GEAR_GREY.b)
	var dark := Vector3(0.192, 0.180, 0.169)
	for s in mi.mesh.get_surface_count():
		var m: Material = mi.mesh.surface_get_material(s)
		if not (m is StandardMaterial3D):
			continue
		var c := (m as StandardMaterial3D).albedo_color
		var cv := Vector3(c.r, c.g, c.b)
		var col := Color.BLACK
		if cv.distance_to(grey) < 0.14:        # plate carrier / gear -> full team color
			col = _team
		elif cv.distance_to(dark) < 0.12:      # dark fatigues -> team-tinted dark
			col = _team.lerp(Color(0.12, 0.12, 0.13), 0.74)
		else:
			continue                            # skin / black straps: leave as-is
		var nm := StandardMaterial3D.new()
		nm.albedo_color = col; nm.roughness = 0.85
		mi.set_surface_override_material(s, nm)

func _build_gun() -> void:
	_gun = Node3D.new(); add_child(_gun)
	_mesh(_gun, Vector3(0.05, 0.10, 0.34), Vector3(0, 0, -0.12))
	_mesh(_gun, Vector3(0.03, 0.03, 0.30), Vector3(0, 0.01, -0.40))
	_mesh(_gun, Vector3(0.045, 0.09, 0.14), Vector3(0, -0.01, 0.12))
	_mesh(_gun, Vector3(0.04, 0.13, 0.05), Vector3(0, -0.09, -0.06))
	_mesh(_gun, Vector3(0.018, 0.05, 0.03), Vector3(0, 0.08, -0.18))

func _mesh(parent: Node3D, size: Vector3, pos: Vector3) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new(); b.size = size; m.mesh = b
	m.material_override = _gun_mat; m.position = pos
	parent.add_child(m)

func _update_gun() -> void:
	if _gun == null or _tgt == null or _hand_idx < 0: return
	var body := get_parent()
	var basis: Basis = global_transform.basis
	if body is Node3D:
		basis = (body as Node3D).global_transform.basis
	var hw: Vector3 = (_tgt.global_transform * _tgt.get_bone_global_pose(_hand_idx)).origin
	_gun.global_transform = Transform3D(basis, hw + basis * Vector3(0.0, 0.02, -0.05))
	_gun.visible = visible and not _dead

func _all(n: Node) -> Array:
	var o: Array = [n]
	for c in n.get_children():
		o += _all(c)
	return o
