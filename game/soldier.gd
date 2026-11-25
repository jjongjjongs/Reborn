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
# limbs whose rest pose differs (A-pose vs T-pose): align by joint->child direction
const LIMB_CHILD := {
	"Shoulder.L": "UpperArm.L", "UpperArm.L": "LowerArm.L", "LowerArm.L": "Hand.L",
	"Shoulder.R": "UpperArm.R", "UpperArm.R": "LowerArm.R", "LowerArm.R": "Hand.R",
	"UpperLeg.L": "LowerLeg.L", "LowerLeg.L": "Foot.L",
	"UpperLeg.R": "LowerLeg.R", "LowerLeg.R": "Foot.R",
	"Hand.L": "Middle2.L", "Hand.R": "Middle2.R",
	"Index2.L": "Index3.L", "Index3.L": "Index4.L", "Middle2.L": "Middle3.L", "Middle3.L": "Middle4.L",
	"Ring2.L": "Ring3.L", "Ring3.L": "Ring4.L", "Pinky2.L": "Pinky3.L", "Pinky3.L": "Pinky4.L",
	"Thumb2.L": "Thumb3.L",
	"Index2.R": "Index3.R", "Index3.R": "Index4.R", "Middle2.R": "Middle3.R", "Middle3.R": "Middle4.R",
	"Ring2.R": "Ring3.R", "Ring3.R": "Ring4.R", "Pinky2.R": "Pinky3.R", "Pinky3.R": "Pinky4.R",
	"Thumb2.R": "Thumb3.R",
}

@export var yaw_offset := PI

var _ap: AnimationPlayer
var _src: Skeleton3D
var _tgt: Skeleton3D
var _hand_idx := -1
var _gun: Node3D
var _tgt_idx := PackedInt32Array()
var _src_idx := PackedInt32Array()
var _tgt_par := PackedInt32Array()                 # target bone's parent index
var _tgt_grest: Array[Quaternion] = []             # target bone global rest rotation (soldier space)
var _src_grest_inv: Array[Quaternion] = []         # source bone global rest rotation (soldier space), inverted
var _align: Array[Quaternion] = []                 # rotates target rest bone dir onto source rest bone dir
var _ks := Quaternion.IDENTITY                     # source skeleton rotation in soldier space
var _kt := Quaternion.IDENTITY                     # target skeleton rotation in soldier space
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
	# reference pose = source standing Idle (not its bind rest, whose orientation
	# differs from the animated clips); SWAT's own rest is also a standing pose
	if _ap:
		_ap.play("Idle"); _ap.seek(0.0, true)
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
		entries.append({"ti": ti, "si": si, "depth": _depth(ti), "name": swat_bone})
	entries.sort_custom(func(a, b): return a["depth"] < b["depth"])   # parents before children
	# both skeletons expressed in this node's space (they may carry different
	# import rotations, e.g. Blender's Z-up fix, and a 100x scale)
	var rs := _rel(_src)
	var rt := _rel(_tgt)
	_ks = rs.basis.get_rotation_quaternion()
	_kt = rt.basis.get_rotation_quaternion()
	for e in entries:
		var ti: int = e["ti"]
		var si: int = e["si"]
		_tgt_idx.append(ti); _src_idx.append(si)
		_tgt_par.append(_tgt.get_bone_parent(ti))
		var tr: Quaternion = _kt * _tgt.get_bone_global_rest(ti).basis.get_rotation_quaternion()
		var sr: Quaternion = _ks * _src.get_bone_global_pose(si).basis.get_rotation_quaternion()
		_tgt_grest.append(tr)
		_src_grest_inv.append(sr.inverse())
		# limbs: re-aim the target's rest limb along the source's rest limb (A vs T pose)
		var al := Quaternion.IDENTITY
		var nm: String = e["name"]
		if LIMB_CHILD.has(nm):
			var tc := _tgt.find_bone(LIMB_CHILD[nm])
			var sc := _src.find_bone(MAP[LIMB_CHILD[nm]])
			if tc >= 0 and sc >= 0:
				var dt := (rt * _tgt.get_bone_global_rest(tc).origin) - (rt * _tgt.get_bone_global_rest(ti).origin)
				var ds := (rs * _src.get_bone_global_pose(sc).origin) - (rs * _src.get_bone_global_pose(si).origin)
				if dt.length() > 0.0001 and ds.length() > 0.0001:
					al = _arc(dt.normalized(), ds.normalized())
		_align.append(al)

func _arc(a: Vector3, b: Vector3) -> Quaternion:
	var c := a.cross(b)
	var d := a.dot(b)
	if d < -0.9999:
		var axis := a.cross(Vector3.RIGHT)
		if axis.length() < 0.01: axis = a.cross(Vector3.FORWARD)
		return Quaternion(axis.normalized(), PI)
	return Quaternion(c.x, c.y, c.z, 1.0 + d).normalized()

func _rel(n: Node3D) -> Transform3D:
	# transform of n relative to this Soldier (works before entering the tree)
	var t := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != self:
		if cur is Node3D: t = (cur as Node3D).transform * t
		cur = cur.get_parent()
	return t

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
	var kt_inv := _kt.inverse()
	for i in _tgt_idx.size():
		var sc: Quaternion = _ks * _src.get_bone_global_pose(_src_idx[i]).basis.get_rotation_quaternion()
		# source motion from its rest, applied to the target rest re-aimed along the
		# source's rest bone direction -> target limb points where the source limb points
		var desired: Quaternion = sc * _src_grest_inv[i] * _align[i] * _tgt_grest[i]
		var d_skel: Quaternion = kt_inv * desired
		var par := _tgt_par[i]
		var pg := Quaternion.IDENTITY
		if par >= 0:
			pg = _tgt.get_bone_global_pose(par).basis.get_rotation_quaternion()
		_tgt.set_bone_pose_rotation(_tgt_idx[i], pg.inverse() * d_skel)

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
