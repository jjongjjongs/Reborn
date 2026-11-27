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
	"Foot.L_end": "DEF-toe.L", "Foot.R_end": "DEF-toe.R",
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
	"Foot.L": "Foot.L_end", "Foot.R": "Foot.R_end",       # foot yaw: ankle->toe direction
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
var _crouch := false
var _windup := false
var _throw_t := 0.0
var _nade: Node3D
# hip height: the clips lower the hips (crouch, death); rotations alone would leave
# the body floating, so follow the source hip height change (scaled to SWAT size)
var _swat: Node3D
var _src_hips := -1
var _rs := Transform3D.IDENTITY
var _ref_hips_y := 0.0
var _hip_ratio := 1.0
var _toes := PackedInt32Array()
# 'ready' upper body: arms keep the weapon-up pose (from Pistol_Idle) while the legs
# play walk/run/crouch, so the gun is never left floating at the hip
@export var hold_ready := true
var _arm_idx := PackedInt32Array()
var _arm_rot: Array[Quaternion] = []
var _ref_toe_y := 0.0
var _aiming := false
var _dead := false
var _oneshot := 0.0
var _base := "?"
var _team := Color(0.8, 0.4, 0.3)
var _kit := Color(0, 0, 0, 0)      # helmet / plate carrier colour (alpha 0 = team-tinted default)
var cosmetic := false              # the player's own soldier: wear the shop finish on guns
var body := "mini"                 # "mini" (default toy soldier) or "swat" (shop), same skeleton
var gun_k := 1.0                   # weapon size multiplier (the chunky mini holds bigger guns)
static var test_body := ""
var cheap := false
const FACE_MATS := ["R_Skin", "R_Blush", "R_EyeWhite", "R_Iris", "R_IrisDark", "R_Pupil", "R_Shine", "R_Lash", "R_Hair", "R_Bandage"]
var fp_gun := false                # first-person arms: the gun pose comes from the view model (fp_gun_xf, soldier space)
var fp_gun_xf := Transform3D()
var pocket_off := Vector3.ZERO     # long guns: shift the shoulder pocket (bulky bodies)
var hand_back := 0.08              # wrist this far behind the grip point (big gloves: less)                 # crowd LOD: retarget every other frame
const BODIES := {"mini": "res://assets/soldier/MiniV3.glb", "swat": "res://assets/soldier/MiniSwat.glb",
	"zombie": "res://assets/soldier/MiniZombie.glb", "rookie": "res://assets/soldier/RookieT.glb",
	"rookie_b": "res://assets/soldier/RookieB.glb"}     # rookie_b: built in Blender (tools/blender/build_mini_v3.py), shading in vertex colours   # all built on the SWAT skeleton (tools/blender/build_minis.py)
var gear := "helmet"               # mini head gear: helmet / beret / mask

func setup(team_color: Color, kit: Color = Color(0, 0, 0, 0)) -> void:
	_team = team_color
	_kit = kit
	# visible body (SWAT, or the Mini Soldier test body built on the same skeleton)
	if test_body != "": body = test_body
	gun_k = 1.15 if body.begins_with("rookie") else (1.15 if BODIES.has(body) else 1.0)      # chibi Tripo body: bigger guns
	pocket_off = Vector3(0.04, 0.0, -0.15) if body.begins_with("rookie") else Vector3.ZERO    # thick vest: rifle in front of it
	hand_back = 0.08                   # measured from the skeleton in _build_gun
	var path: String = BODIES.get(body, "")
	var swat: Node3D = (load(path) as PackedScene).instantiate() if path != "" else SWAT.instantiate()
	var gears := swat.find_children("Gear_*", "", true, false)
	if gears.size() > 1:   # bodies with swappable head gear (helmet / beret / mask)
		for g in gears:
			(g as Node3D).visible = String(g.name).to_lower() == "gear_" + gear
	_swat = swat
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
	if _src != null and _tgt != null:
		_src_hips = _src.find_bone("DEF-hips")
		var th := _tgt.find_bone("Hips")
		if _src_hips >= 0 and th >= 0:
			_rs = _rel(_src)
			_ref_hips_y = (_rs * _src.get_bone_global_pose(_src_hips).origin).y
			var tgt_hips_y := (_rel(_tgt) * _tgt.get_bone_global_rest(th).origin).y
			if _ref_hips_y > 0.01:
				_hip_ratio = tgt_hips_y / _ref_hips_y
		for t in ["Foot.L_end", "Foot.R_end"]:
			var ti := _tgt.find_bone(t)
			if ti >= 0: _toes.append(ti)
		_ref_toe_y = _min_toe_y()       # standing reference (SWAT rest)
	_snapshot_ready_arms()
	_build_gun()
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

func set_crouch(c: bool) -> void:
	if c != _crouch:
		_crouch = c; _base = "?"

# grenade: hold = arm cocked back with a grenade in hand; throw = release motion
func windup(on: bool) -> void:
	_windup = on and not _dead

func throw() -> void:
	_windup = false
	if _dead or _ap == null: return
	_ap.play("Spell_Simple_Shoot", 0.05); _ap.seek(0.08, true)
	_oneshot = 0.42; _throw_t = 0.42; _base = "?"

func shoot() -> void:
	if _dead or _ap == null: return
	_kick = 1.0

func set_dead(d: bool) -> void:
	if d == _dead: return
	_dead = d; _oneshot = 0.0; _base = "?"
	if _ap:
		_ap.play("Death01" if d else "Idle", 0.12)
		if d: _base = "Death01"

func _process(dt: float) -> void:
	if cheap and (Engine.get_process_frames() + get_instance_id()) % 2 == 1:
		_update_gun(); return          # crowds (zombies): retarget every other frame
	_retarget()
	if _windup:
		_apply_windup()
	_throw_t = maxf(0.0, _throw_t - dt)
	_update_gun()
	if _ap == null or _dead: return
	if _oneshot > 0.0:
		_oneshot -= dt
		return
	var want := "Idle"
	if _crouch: want = "Crouch_Fwd" if _loco > 0.12 else "Crouch_Idle"
	elif _loco > 0.85: want = "Sprint"
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
	# arms in the weapon-ready pose unless a one-shot (shoot/throw/stab) or death owns them
	if hold_ready and not _dead and _oneshot <= 0.0:
		for k in _arm_idx.size():
			_src.set_bone_pose_rotation(_arm_idx[k], _arm_rot[k])
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
	_level_feet()
	if _src_hips >= 0 and _swat != null:
		var hy := (_rs * _src.get_bone_global_pose(_src_hips).origin).y
		_swat.position.y = (hy - _ref_hips_y) * _hip_ratio
		# leg proportions differ, so a crouch can still leave the toes a few cm up:
		# pull the body down until the lowest toe is back at the standing level
		if not _dead and _toes.size() > 0:
			var lift := _min_toe_y() - _ref_toe_y
			if lift > 0.0:
				_swat.position.y -= minf(lift, 0.2)

# chunky boots: keep the toe direction from the animation but drop the foot roll, so the sole
# stays level instead of the ankle folding in (the clips roll the foot, which reads as a twisted ankle)
var _feet := PackedInt32Array()
func _level_feet() -> void:
	if _dead or _tgt == null: return
	if _feet.is_empty():
		for n in ["Foot.L", "Foot.R"]: _feet.append(_tgt.find_bone(n))
	var up := (_tgt.global_transform.basis.inverse() * Vector3.UP).normalized()
	var fwd := (_tgt.global_transform.basis.inverse() * -global_transform.basis.z).normalized()
	for f in _feet:
		if f < 0: continue
		var fr := _tgt.get_bone_global_rest(f)
		var d0 := fr.basis.y.normalized()                                         # bone axis = heel -> toe
		var d1 := _tgt.get_bone_global_pose(f).basis.y.normalized()
		# heading: point the toe where the body faces (the clips splay the feet), keep the pitch
		var fh := fwd - up * fwd.dot(up)
		var dh := d1 - up * d1.dot(up)
		if fh.length() > 0.1 and dh.length() > 0.05:
			d1 = (fh.normalized() * dh.length() + up * d1.dot(up)).normalized()
		var u0 := (up - d0 * up.dot(d0)).normalized()
		var u1 := (up - d1 * up.dot(d1)).normalized()
		if u0.length() < 0.5 or u1.length() < 0.5: continue
		var b0 := Basis(d0, u0, d0.cross(u0)); var b1 := Basis(d1, u1, d1.cross(u1))
		var g: Quaternion = (b1 * b0.transposed()).get_rotation_quaternion() * fr.basis.get_rotation_quaternion()
		var par := _tgt.get_bone_parent(f)
		var pg := _tgt.get_bone_global_pose(par).basis.get_rotation_quaternion() if par >= 0 else Quaternion.IDENTITY
		_tgt.set_bone_pose_rotation(f, pg.inverse() * g)

func _snapshot_ready_arms() -> void:
	if _ap == null or _src == null: return
	_ap.play("Pistol_Idle"); _ap.seek(0.4, true)
	for i in _src.get_bone_count():
		var n := _src.get_bone_name(i)
		if n.contains("shoulder") or n.contains("upper_arm") or n.contains("forearm") or n.contains("hand") \
				or n.contains("f_") or n.contains("thumb"):
			_arm_idx.append(i)
			_arm_rot.append(_src.get_bone_pose_rotation(i))
	_ap.play("Idle"); _ap.seek(0.0, true)

func _min_toe_y() -> float:
	var rt := _rel(_tgt)
	var m := 1e9
	for ti in _toes:
		m = minf(m, (rt * _tgt.get_bone_global_pose(ti).origin).y)
	return m if m < 1e8 else 0.0

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
		if body.begins_with("rookie"):           # concept palette: only the team patches / tabs take the colour
			var vcol := body == "rookie_b"          # baked AO / cavity / fabric noise in the vertex colours
			if not m.resource_name.begins_with("Team"):
				if vcol:
					var dm := (m as StandardMaterial3D).duplicate() as StandardMaterial3D
					dm.vertex_color_use_as_albedo = true
					if m.resource_name in FACE_MATS: dm.disable_receive_shadows = true   # anime face: no jagged helmet shadow
					mi.set_surface_override_material(s, dm)
				continue
			var nm2 := StandardMaterial3D.new(); nm2.albedo_color = _team; nm2.roughness = 0.6
			nm2.vertex_color_use_as_albedo = vcol
			mi.set_surface_override_material(s, nm2)
			continue
		if cv.distance_to(grey) < 0.14:        # plate carrier / gear -> full team color
			col = _team
		elif cv.distance_to(dark) < 0.12:      # dark fatigues -> team-tinted dark
			col = _kit if _kit.a > 0.0 else _team.lerp(Color(0.12, 0.12, 0.13), 0.74)
		else:
			continue                            # skin / black straps: leave as-is
		var nm := StandardMaterial3D.new()
		nm.albedo_color = col; nm.roughness = 0.85
		mi.set_surface_override_material(s, nm)

# ---- weapons & grip -------------------------------------------------------
# Real-world holds (see grip review): long guns -> butt in the right shoulder
# pocket, strong hand on the pistol grip / stock wrist, support hand under the
# handguard (shotgun: on the pump). Not aiming = low ready (muzzle ~35 deg down,
# stock still in the shoulder); aiming = shouldered, barrel level.
# Pistols -> two hands, compressed ready at the chest / isosceles when aiming.
# Knife -> hammer grip, blade forward at chest height, free hand up as a guard.
# Anchors are measured on the model side views: [fraction from the butt, height
# as a fraction of length above the model's centre].
const WEAPONS := {
	"ak":       {"len": 0.88, "kind": "long",   "butt": [0.01, 0.03],  "grip": [0.29, 0.0],   "fore": [0.66, 0.07]},
	"m4":       {"len": 0.84, "kind": "long",   "butt": [0.01, 0.04],  "grip": [0.30, -0.10], "fore": [0.70, -0.05], "fp": 0.78, "vfore": true, "fp_fore": [0.70, -0.06]},   # AR-9R (concept): vertical foregrip
	"mp5":      {"len": 0.66, "kind": "long",   "butt": [0.01, 0.06],  "grip": [0.42, -0.01], "fore": [0.76, 0.09]},
	"shotgun":  {"len": 1.00, "kind": "long",   "butt": [0.01, -0.03], "grip": [0.27, 0.01],  "fore": [0.70, 0.02]},
	"sniper":   {"len": 1.15, "kind": "long",   "butt": [0.01, -0.03], "grip": [0.26, -0.01], "fore": [0.48, 0.01]},
	"rpk":      {"len": 1.04, "kind": "long",   "butt": [0.01, 0.01],  "grip": [0.31, -0.02], "fore": [0.64, 0.08]},
	"pistol":   {"len": 0.20, "kind": "pistol", "grip": [0.17, -0.07]},
	"revolver": {"len": 0.26, "kind": "pistol", "grip": [0.13, -0.09]},
	"knife":    {"len": 0.30, "kind": "knife",  "grip": [0.17, 0.0]},
}
const READY_PITCH := 35.0      # low ready: muzzle down (deg)
# the SWAT mesh is stylised (shoulder->wrist 0.42 m vs ~0.58 m on a real adult), so
# long guns are drawn at 78% to keep the support hand on the handguard
const LONG_SCALE := 0.78
const TWIST := -22.0           # rifle stance: torso turned so the support shoulder leads
var weapon := ""
var _wdef := {}
var _wmodel: Node3D
var _aim_b := 0.0              # 0 = ready, 1 = aiming (blended)
var _kick := 0.0               # recoil 1 -> 0
var _arm := {}                 # bone indices
var _gun_s := Transform3D.IDENTITY   # gun transform in soldier space (this frame)

func _build_gun() -> void:
	_gun = Node3D.new(); add_child(_gun); _gun.top_level = true
	for b in ["UpperArm.R", "LowerArm.R", "Hand.R", "UpperArm.L", "LowerArm.L", "Hand.L", "Middle2.R", "Middle2.L", "Torso", "Neck"]:
		_arm[b] = _tgt.find_bone(b) if _tgt else -1
	# palm centre = halfway from the wrist to the knuckles: put THAT on the grip, whatever the hand size
	var hb: int = _arm["Hand.R"]; var mk: int = _arm["Middle2.R"]
	if hb >= 0 and mk >= 0: hand_back = 0.5 * _bone_s(hb).distance_to(_bone_s(mk))
	set_weapon("m4")

func set_weapon(id: String) -> void:
	if id == weapon or not WEAPONS.has(id): return
	weapon = id
	_wdef = WEAPONS[id]
	fp_shift = Vector3.ZERO
	if _wmodel: _wmodel.queue_free()
	var m: Node3D = (load("res://assets/guns/%s.glb" % id) as PackedScene).instantiate()
	var a := _model_aabb(m)
	var L: float = _len()
	var sc: float = L / maxf(a.size.x, 0.001)
	m.rotation.y = PI * 0.5            # model muzzle +X -> holder -Z (forward)
	m.scale = Vector3.ONE * sc
	m.position = -(Basis(Vector3.UP, PI * 0.5) * (a.get_center() * sc))
	_gun.add_child(m)
	_wmodel = m
	if cosmetic: Profile.apply_finish(m, "", id)

# anchor [from-butt fraction, height fraction] -> holder space (barrel -Z, butt +Z)
func _anchor(key: String) -> Vector3:
	var v: Array = _wdef[key]
	var L: float = _len()
	return Vector3(0.0, float(v[1]) * L, (0.5 - float(v[0])) * L)

func _len() -> float:
	return float(_wdef["len"]) * (LONG_SCALE if _wdef["kind"] == "long" else 1.0) * gun_k

func _model_aabb(root: Node3D) -> AABB:
	var out := AABB(); var first := true
	for c in _all(root):
		if c is MeshInstance3D:
			var t := Transform3D.IDENTITY
			var cur: Node = c
			while cur != root and cur != null:
				t = (cur as Node3D).transform * t; cur = cur.get_parent()
			var bb: AABB = t * (c as MeshInstance3D).get_aabb()
			out = bb if first else out.merge(bb); first = false
	return out

func _bone_s(idx: int) -> Vector3:
	return _rel(_tgt) * _tgt.get_bone_global_pose(idx).origin

func _update_gun() -> void:
	if _gun == null or _tgt == null or _wdef.is_empty(): return
	var dt := get_process_delta_time()
	_aim_b = move_toward(_aim_b, 1.0 if _aiming else 0.0, dt * 6.0)
	_kick = move_toward(_kick, 0.0, dt * (4.0 if _wdef.get("kind", "") == "knife" else 9.0))
	var throwing := _windup or _throw_t > 0.0
	var show := not _dead and not throwing
	_gun.visible = visible and show and not fp_gun
	if show:
		_pose_weapon()
		_gun.global_transform = global_transform * _gun_s
	var hw: Vector3 = global_transform * _bone_s(_arm["Hand.R"])
	if _nade == null:
		_nade = Grenade.mesh(); add_child(_nade); _nade.top_level = true
	_nade.visible = visible and _windup and not _dead
	if _nade.visible:
		_nade.global_position = hw + global_transform.basis * Vector3(0.0, 0.05, 0.0)

func _pose_weapon() -> void:
	var kind: String = _wdef["kind"]
	if fp_gun:
		_gun_s = fp_gun_xf
		_place_hands(kind, _bone_s(_arm["UpperArm.L"]))
		return
	if kind == "long":
		# bladed stance: turn the torso, keep the head facing the target
		_turn_bone(_arm["Torso"], TWIST)
		_turn_bone(_arm["Neck"], -TWIST * 0.8)
	var sh_r := _bone_s(_arm["UpperArm.R"])
	var sh_l := _bone_s(_arm["UpperArm.L"])
	var reach := sh_r.distance_to(_bone_s(_arm["LowerArm.R"])) + _bone_s(_arm["LowerArm.R"]).distance_to(_bone_s(_arm["Hand.R"]))
	var k := ease(_aim_b, -1.8)
	if kind == "long":
		var pitch := deg_to_rad(lerpf(-READY_PITCH, 0.0, k) + 4.0 * _kick)
		var basis := Basis(Vector3.RIGHT, pitch)
		var pocket := sh_r + Vector3(-0.06, lerpf(-0.05, -0.01, k), -0.04) + pocket_off + Vector3(0, 0, 0.04 * _kick)
		_gun_s = Transform3D(basis, pocket - basis * _anchor("butt"))
	elif kind == "pistol":
		var mid := (sh_r + sh_l) * 0.5
		var ready_p := mid + Vector3(0.0, -0.17, -0.26)      # compressed ready
		var aim_p := mid + Vector3(0.0, 0.08, -reach - 0.04)   # isosceles: arms extended
		var gp := ready_p.lerp(aim_p, k)
		var basis := Basis(Vector3.RIGHT, deg_to_rad(9.0 * _kick))
		_gun_s = Transform3D(basis, gp - basis * _anchor("grip") + Vector3(0, 0, 0.03 * _kick))
	else:   # knife: hammer grip, blade forward, guard hand up
		var gp := sh_r + Vector3(-0.08, -0.17, -0.30 - 0.32 * sin(PI * (1.0 - _kick)))
		var basis := Basis(Vector3.RIGHT, deg_to_rad(12.0))
		_gun_s = Transform3D(basis, gp - basis * _anchor("grip"))
	_place_hands(kind, sh_l)

func _wrist_of(contact: Vector3, f_g: Vector3, n_g: Vector3, pad: float) -> Vector3:
	var gb := _gun_s.basis
	var f := (gb * f_g).normalized()
	var n := gb * n_g
	n = (n - f * n.dot(f)).normalized()
	return _gun_s * contact - n * pad - f * hand_back

func _reach(side: String) -> float:
	var u: int = _arm["UpperArm." + side]; var l: int = _arm["LowerArm." + side]; var h: int = _arm["Hand." + side]
	return _bone_s(u).distance_to(_bone_s(l)) + _bone_s(l).distance_to(_bone_s(h))

## both hands must be able to reach their grips: if an arm is too short (chibi bodies), slide the gun
## back toward the body along its own axis until both wrists are within reach (never leave a hand hanging)
var fp_shift := Vector3.ZERO      # first person: how far the body must move toward the gun (soldier space)
func _fit_reach(targets: Array) -> void:
	var back := _gun_s.basis.z.normalized()           # gun +Z = toward the butt / shooter
	var o0 := _gun_s.origin
	_fit_loop(targets, back)
	if fp_gun:                                        # the gun is fixed on screen: move the arms instead
		fp_shift = fp_shift + (_gun_s.origin - o0)
		_gun_s.origin = o0

func _fit_loop(targets: Array, back: Vector3) -> void:
	for it in 6:
		var worst := 0.0
		for t in targets:
			var side: String = t[0]
			var w: Vector3 = _wrist_of(t[1], t[2], t[3], t[4])
			var ex := _bone_s(_arm["UpperArm." + side]).distance_to(w) - _reach(side) * 0.96
			worst = maxf(worst, ex)
		if worst <= 0.002: return
		_gun_s.origin += back * (worst + 0.004)

func _place_hands(kind: String, sh_l: Vector3) -> void:
	if kind == "long":
		var lf := [Vector3(0.35, -0.55, -0.75), Vector3(1, 0, 0), 0.03] if bool(_wdef.get("vfore", false)) else [Vector3(0.45, 0.25, -0.85), Vector3(0.2, 1, 0), 0.035]
		_fit_reach([["R", _anchor("grip"), Vector3(-0.45, -0.35, -0.82), Vector3(-1, 0, 0), 0.03], ["L", _anchor("fore"), lf[0], lf[1], lf[2]]])
	elif kind == "pistol":
		_fit_reach([["R", _anchor("grip"), Vector3(-0.3, -0.5, -0.8), Vector3(-1, 0, 0), 0.02], ["L", _anchor("grip"), Vector3(0.3, -0.5, -0.8), Vector3(1, 0, 0), 0.05]])
	if kind == "long":
		# strong hand wraps the pistol grip (palm on its right side, knuckles forward-down);
		# support hand cradles the handguard from below, palm up (or wraps a vertical foregrip)
		_hand("R", _anchor("grip"), Vector3(-0.45, -0.35, -0.82), Vector3(-1, 0, 0), 0.03, 62.0, Vector3(0.6, -1.0, 0.3))
		if bool(_wdef.get("vfore", false)):
			_hand("L", _anchor("fore"), Vector3(0.35, -0.55, -0.75), Vector3(1, 0, 0), 0.03, 70.0, Vector3(-0.6, -1.0, 0.2))
		else:
			_hand("L", _anchor("fore"), Vector3(0.45, 0.25, -0.85), Vector3(0.2, 1, 0), 0.035, 48.0, Vector3(-0.5, -1.0, 0.1))
	elif kind == "pistol":
		# strong hand high on the grip; support hand wraps over its fingers from the left
		_hand("R", _anchor("grip"), Vector3(-0.3, -0.5, -0.8), Vector3(-1, 0, 0), 0.02, 66.0, Vector3(0.8, -1.0, 0.2))
		_hand("L", _anchor("grip"), Vector3(0.3, -0.5, -0.8), Vector3(1, 0, 0), 0.05, 60.0, Vector3(-0.8, -1.0, 0.2))
	else:   # knife: hammer grip; guard hand open, palm toward the target, in front of the chest
		_hand("R", _anchor("grip"), Vector3(-0.1, -0.75, -0.65), Vector3(-1, 0, 0.2), 0.02, 72.0, Vector3(0.7, -1.0, 0.4))
		_hand("L", _gun_s.affine_inverse() * (sh_l + Vector3(0.14, -0.10, -0.30)), Vector3(0.1, 1.0, -0.2), Vector3(0.3, 0, -1), 0.0, 12.0, Vector3(-0.6, -1.0, 0.0))

## first-person arms: keep only the triangles skinned to the arm / hand bones (any body)
const ARM_BONES := ["Shoulder", "UpperArm", "LowerArm", "Hand", "Thumb", "Index", "Middle", "Ring", "Pinky"]
func arms_only() -> void:
	for mi in find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.skin == null or not (m.mesh is ArrayMesh) or not m.visible:
			m.visible = false; continue
		var skel := m.get_node_or_null(m.skeleton) as Skeleton3D
		var am := ArrayMesh.new()
		for si in m.mesh.get_surface_count():
			var arr: Array = m.mesh.surface_get_arrays(si)
			var bones = arr[Mesh.ARRAY_BONES]; var wts = arr[Mesh.ARRAY_WEIGHTS]; var idx = arr[Mesh.ARRAY_INDEX]
			if bones == null or idx == null: continue
			var nv: int = (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			var per := int((bones as PackedInt32Array).size() / max(nv, 1))
			var is_arm := PackedByteArray(); is_arm.resize(nv)
			var name_ok := {}
			for v in nv:
				var bi := 0; var bw := -1.0
				for j in per:
					var w: float = wts[v * per + j]
					if w > bw: bw = w; bi = bones[v * per + j]
				if not name_ok.has(bi):
					var nm := m.skin.get_bind_name(bi)
					if nm == "" and skel: nm = skel.get_bone_name(m.skin.get_bind_bone(bi))
					var ok := false
					for p in ARM_BONES:
						if nm.begins_with(p): ok = true
					name_ok[bi] = ok
				is_arm[v] = 1 if name_ok[bi] else 0
			var keep := PackedInt32Array()
			for t in range(0, (idx as PackedInt32Array).size(), 3):
				if is_arm[idx[t]] and is_arm[idx[t + 1]] and is_arm[idx[t + 2]]:
					keep.append(idx[t]); keep.append(idx[t + 1]); keep.append(idx[t + 2])
			if keep.is_empty(): continue
			arr[Mesh.ARRAY_INDEX] = keep
			var fl: int = int(m.mesh.surface_get_format(si)) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, fl)
			var mat := m.get_active_material(si)
			am.surface_set_material(am.get_surface_count() - 1, mat)
		if am.get_surface_count() == 0:
			m.visible = false; continue
		m.mesh = am
		for si in am.get_surface_count(): m.set_surface_override_material(si, null)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

# place one hand on the weapon. contact/f/n are in gun space: f = wrist->knuckles
# direction, n = palm normal (toward the part being held), pad = palm thickness
func _hand(side: String, contact: Vector3, f_g: Vector3, n_g: Vector3, pad: float, curl: float, pole: Vector3) -> void:
	var gb := _gun_s.basis
	var f := (gb * f_g).normalized()
	var n := gb * n_g
	n = (n - f * n.dot(f)).normalized()
	var wrist := _wrist_of(contact, f_g, n_g, pad)
	_ik_hand(side, wrist, pole)
	var h: int = _arm["Hand." + side]
	var mi := _tgt.find_bone("Middle2." + side)
	var ii := _tgt.find_bone("Index2." + side)
	var pi := _tgt.find_bone("Pinky2." + side)
	if h < 0 or mi < 0 or ii < 0 or pi < 0: return
	var hp := _bone_s(h)
	var fc := (_bone_s(mi) - hp).normalized()
	var sc := _bone_s(ii) - _bone_s(pi)
	sc = (sc - fc * sc.dot(fc)).normalized()
	var sd := f.cross(n) if side == "R" else n.cross(f)    # index-side direction
	var q := (Basis(f, sd, f.cross(sd)) * Basis(fc, sc, fc.cross(sc)).inverse()).get_rotation_quaternion()
	_rot_bone_s(h, q)
	# curl the fingers toward the palm (each joint adds to its parent's bend)
	var axis := f.cross(n).normalized()
	for fn in ["Index", "Middle", "Ring", "Pinky"]:
		for seg in [2, 3, 4]:
			_rot_bone_s(_tgt.find_bone("%s%d.%s" % [fn, seg, side]), Quaternion(axis, deg_to_rad(curl)))
	for seg in [2, 3]:
		_rot_bone_s(_tgt.find_bone("Thumb%d.%s" % [seg, side]), Quaternion(axis, deg_to_rad(curl * 0.35)))

# rotate a bone by q (soldier space) about its own origin
func _rot_bone_s(b: int, q: Quaternion) -> void:
	if b < 0: return
	var g := _tgt.get_bone_global_pose(b).basis.get_rotation_quaternion()
	var new_g: Quaternion = _kt.inverse() * q * _kt * g
	var p := _tgt.get_bone_parent(b)
	var pg := Quaternion.IDENTITY
	if p >= 0: pg = _tgt.get_bone_global_pose(p).basis.get_rotation_quaternion()
	_tgt.set_bone_pose_rotation(b, pg.inverse() * new_g)

# two-bone IK in soldier space: put the wrist at `target`, elbow toward `pole`
func _ik_hand(side: String, target: Vector3, pole: Vector3) -> void:
	var u: int = _arm["UpperArm." + side]
	var l: int = _arm["LowerArm." + side]
	var h: int = _arm["Hand." + side]
	if u < 0 or l < 0 or h < 0: return
	var s := _bone_s(u)
	var a := s.distance_to(_bone_s(l))
	var b := _bone_s(l).distance_to(_bone_s(h))
	var to := target - s
	var d := clampf(to.length(), absf(a - b) + 0.01, a + b - 0.005)
	var n := to.normalized()
	var x := (a * a - b * b + d * d) / (2.0 * d)
	var hh := sqrt(maxf(a * a - x * x, 0.0))
	var p := pole - n * pole.dot(n)
	if p.length() < 0.001: p = Vector3.DOWN
	var elbow := s + n * x + p.normalized() * hh
	_point_bone(u, l, elbow - s)
	_point_bone(l, h, (s + n * d) - elbow)

func _turn_bone(b: int, deg: float) -> void:
	if b < 0: return
	var g := _tgt.get_bone_global_pose(b).basis.get_rotation_quaternion()
	var q := Quaternion(Vector3.UP, deg_to_rad(deg))
	var new_g: Quaternion = _kt.inverse() * q * _kt * g
	var p := _tgt.get_bone_parent(b)
	var pg := Quaternion.IDENTITY
	if p >= 0: pg = _tgt.get_bone_global_pose(p).basis.get_rotation_quaternion()
	_tgt.set_bone_pose_rotation(b, pg.inverse() * new_g)

func _point_bone(b: int, c: int, dir_s: Vector3) -> void:
	var rt := _rel(_tgt)
	var gb := _tgt.get_bone_global_pose(b)
	var cur := ((rt * _tgt.get_bone_global_pose(c).origin) - (rt * gb.origin)).normalized()
	var q := _arc(cur, dir_s.normalized())
	var new_g: Quaternion = _kt.inverse() * q * _kt * gb.basis.get_rotation_quaternion()
	var p := _tgt.get_bone_parent(b)
	var pg := Quaternion.IDENTITY
	if p >= 0: pg = _tgt.get_bone_global_pose(p).basis.get_rotation_quaternion()
	_tgt.set_bone_pose_rotation(b, pg.inverse() * new_g)

# windup pose: no throw clip in the library, so aim the right arm's bones (in this
# node's space, +Z = behind) after retargeting: elbow up/back, hand behind the head
func _apply_windup() -> void:
	_aim_bone("UpperArm.R", "LowerArm.R", Vector3(0.25, 0.25, 1.0))
	_aim_bone("LowerArm.R", "Hand.R", Vector3(0.0, 1.0, 0.45))

func _aim_bone(bone: String, child: String, dir_s: Vector3) -> void:
	var b := _tgt.find_bone(bone)
	var c := _tgt.find_bone(child)
	if b < 0 or c < 0: return
	var rt := _rel(_tgt)
	var gb := _tgt.get_bone_global_pose(b)
	var gc := _tgt.get_bone_global_pose(c)
	var cur := ((rt * gc.origin) - (rt * gb.origin)).normalized()
	var q := _arc(cur, dir_s.normalized())
	var new_g: Quaternion = _kt.inverse() * q * _kt * gb.basis.get_rotation_quaternion()
	var p := _tgt.get_bone_parent(b)
	var pg := Quaternion.IDENTITY
	if p >= 0: pg = _tgt.get_bone_global_pose(p).basis.get_rotation_quaternion()
	_tgt.set_bone_pose_rotation(b, pg.inverse() * new_g)

func _all(n: Node) -> Array:
	var o: Array = [n]
	for c in n.get_children():
		o += _all(c)
	return o
