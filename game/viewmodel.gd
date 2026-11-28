class_name ViewModel
extends Node3D
## First-person weapon view (1인칭): the current weapon held by two gloved arms,
## attached to the camera. Bobs while walking, kicks on every shot (read from the
## third-person soldier's kick), dips for reloads, comes up after a swap, drops
## while a grenade is being aimed, pulls back when the muzzle would enter a wall.
## Hidden while scoped (the scope overlay takes over) and when dead.

static var active := false
static var muzzle := Vector3.ZERO     # world position of the muzzle (tracers start here)

const SLEEVE := Color(0.25, 0.27, 0.21)
# the whole first-person rig (gun, gloves, forearms) is a scaled-down copy held close to the camera, as FPS
# games do: the gun then sits in the lower right instead of reaching for the screen centre
const S := 0.62
const GLOVE := Color(0.13, 0.12, 0.11)
# per kind: right-hand grip point (camera space), weapon rotation (deg), shoulders the forearms start from
const POSE := {
	# rifles: low on the right, muzzle turned a little in so the side of the gun shows; elbows below the
	# frame (right one out to the side, left one under the gun) so the forearms come in diagonally
	"long":   {"grip": Vector3(0.185, -0.135, -0.25), "rot": Vector3(-6.0, 3.0, -5.0), "sr": Vector3(0.30, -0.30, 0.02), "sl": Vector3(-0.15, -0.30, -0.10)},
	# pistol: both arms pushed out (isosceles), the gun low-centre-right so the sights and both hands show
	"pistol": {"grip": Vector3(0.08, -0.17, -0.40), "rot": Vector3(3.0, 6.0, -4.0), "sr": Vector3(0.20, -0.32, 0.0), "sl": Vector3(-0.04, -0.32, -0.04)},
	# knife: forward hammer grip low on the right, point toward the crosshair, edge down
	"knife":  {"grip": Vector3(0.17, -0.19, -0.36), "rot": Vector3(10.0, 12.0, -8.0), "sr": Vector3(0.34, -0.46, 0.0), "sl": Vector3(-0.30, -0.8, 0.0)},
	"axe":    {"grip": Vector3(0.20, -0.30, -0.42), "rot": Vector3.ZERO, "sr": Vector3(0.34, -0.46, 0.0), "sl": Vector3(-0.30, -0.8, 0.0)},
}
## axe swing on screen (camera space): s, grip, haft pitch / yaw / roll (deg) - like Soldier.AXE_KEYS
const AXE_FP := [
	[0.00, Vector3(0.17, -0.42, -0.60), 40.0, 14.0, -16.0, Vector3(0.6, -1.0, 0.3)],     # ready: fist low right, head up in the top-right corner
	[0.22, Vector3(0.36, -0.06, -0.42), 128.0, -24.0, 10.0, Vector3(1.0, 0.2, 0.3)],     # wind-up: elbow out, arm cocked up-right, head back
	[0.36, Vector3(0.04, -0.24, -0.66), 4.0, 30.0, -42.0, Vector3(0.6, -1.0, 0.2)],      # impact: diagonal slash, head through the crosshair
	[0.56, Vector3(-0.22, -0.50, -0.55), -56.0, 60.0, -48.0, Vector3(0.3, -1.0, 0.4)],   # follow-through out the bottom-left
	[1.00, Vector3(0.17, -0.42, -0.60), 40.0, 14.0, -16.0, Vector3(0.6, -1.0, 0.3)],
]

var player: PlayerBody
var _wid := ""
var _kind := "long"
var _len := 0.8
var _wdef := {}
var _holder: Node3D
var _gun: Node3D
var _wfx_node: Node3D
var _arm_r: MeshInstance3D
var _arm_l: MeshInstance3D
var _body: Soldier          # the player's own body, arms only, posed onto the first-person gun
var _hand_r: Node3D          # gloved fists (assets/fp/glove_*.glb, built by tools/blender/build_fp_gloves.py)
var _hand_l: Node3D
var _wrist_r := Vector3.ZERO  # cuff point in the glove's design frame
var _wrist_l := Vector3.ZERO
# glove files are authored Z-up in Blender: imported (x, y, z) = design (x, z, -y); this turns them back so
# design +Y = along the grip, -Z = toward the muzzle, +X = back of the right hand
const FIX := Basis(Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(0, -1, 0))
var _flash: OmniLight3D
var _flash_t := 0.0
var _t := 0.0
var _last_kick := 0.0
var _trail: SwingTrail
var _raise := 0.0          # 0 = up, 1 = fully lowered (swap / grenade)
var _reload_k := 0.0
var _push := 0.0           # 0..1: muzzle blocked by a wall -> weapon tucked down and in

func _ready() -> void:
	var sl := StandardMaterial3D.new(); sl.albedo_color = Color(0.31, 0.33, 0.24); sl.roughness = 0.95
	var gl := StandardMaterial3D.new(); gl.albedo_color = GLOVE; gl.roughness = 0.8
	_holder = Node3D.new(); add_child(_holder)
	_arm_r = _limb(sl, 0.05 * S); _arm_l = _limb(sl, 0.05 * S)
	_hand_r = _glove("r", "l"); _hand_l = _glove("l", "r")      # (the exported files came out mirrored)
	_hand_r.visible = false; _hand_l.visible = false; _arm_r.visible = false; _arm_l.visible = false
	_body = Soldier.new(); _body.cosmetic = true
	_body.body = Profile.equipped("body").substr(5); _body.gear = Profile.equipped("gear").substr(5); _body.skin = Profile.skin_mats(Profile.equipped("skin"))
	add_child(_body)
	_body.setup(Profile.suit_color(), Profile.kit_color())
	_body.fp_gun = true
	_body.arms_only()
	_flash = OmniLight3D.new(); _flash.light_color = Color(1, 0.8, 0.4); _flash.light_energy = 3.0; _flash.omni_range = 4.0
	_flash.visible = false; add_child(_flash)

func _limb(m: Material, r: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = r * 0.95; cm.bottom_radius = r * 1.35; cm.height = 0.5
	cm.radial_segments = 16; cm.rings = 1
	mi.mesh = cm; mi.material_override = m; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi); return mi

func _fist(m: Material) -> MeshInstance3D:   # rounded glove, long axis along the weapon
	var mi := MeshInstance3D.new(); var cm := CapsuleMesh.new(); cm.radius = 0.036; cm.height = 0.11
	cm.radial_segments = 10; cm.rings = 3
	mi.mesh = cm; mi.material_override = m; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi); return mi

func _glove(side: String, file: String) -> Node3D:
	var g: Node3D = (load("res://assets/fp/glove_%s.glb" % file) as PackedScene).instantiate()
	var root := Node3D.new(); root.add_child(g); add_child(root)
	g.transform = Transform3D(FIX * S, Vector3.ZERO)
	for mi in g.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		m3.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for si in m3.mesh.get_surface_count():               # the left glove is a mirror: draw both faces
			var sm := m3.mesh.surface_get_material(si)
			if sm is BaseMaterial3D:
				var c := (sm as BaseMaterial3D).duplicate() as BaseMaterial3D
				c.cull_mode = BaseMaterial3D.CULL_DISABLED
				m3.set_surface_override_material(si, c)
	var w := g.find_child("Wrist", true, false) as Node3D
	var wp: Vector3 = (FIX * w.position) * S if w else Vector3(0.06, -0.08, 0.05) * S
	if side == "r": _wrist_r = wp
	else: _wrist_l = wp
	return root

func _box(m: Material, s: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = s
	mi.mesh = bm; mi.material_override = m; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi); return mi

func _set_weapon(id: String) -> void:
	_wid = id
	_wdef = Soldier.WEAPONS.get(id, Soldier.WEAPONS["m4"])
	_kind = String(_wdef.get("kind", "long"))
	_len = float(_wdef["len"]) * float(_wdef.get("fp", 1.0)) * S     # bulky models drawn a bit smaller up close
	if _gun: _gun.queue_free()
	var m: Node3D = (load("res://assets/guns/%s.glb" % id) as PackedScene).instantiate()
	_holder.add_child(m)
	var ab := AABB(); var first := true
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var g := mi as MeshInstance3D
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var bx: AABB = (m.global_transform.affine_inverse() * g.global_transform) * g.get_aabb()
		ab = bx if first else ab.merge(bx); first = false
	var sc := _len / maxf(ab.size.x, 0.001)
	var rb := Basis(Vector3.UP, PI * 0.5)              # model muzzle +X -> holder -Z
	if _wdef.get("flip", false): rb = Basis(Vector3.BACK, PI) * rb
	m.transform = Transform3D(rb * Basis.from_scale(Vector3.ONE * sc), -(rb * (ab.get_center() * sc)))
	_gun = m
	Profile.apply_finish(m, "", id)
	if is_instance_valid(_wfx_node): _wfx_node.queue_free()
	var wf := Profile.equipped("wfx")
	if wf != "wfx_none": _wfx_node = FxCos.weapon_fx(wf, _holder, _len, 0.45)
	if _body: _body.set_weapon(id)
	_raise = 1.0                          # bring the new weapon up

func _anchor(key: String) -> Vector3:   # [from-butt fraction, height fraction] -> holder space
	var v: Array = _wdef.get(key, _wdef["grip"])
	return Vector3(0.0, float(v[1]) * _len, (0.5 - float(v[0])) * _len)

func _process(dt: float) -> void:
	active = Controls.view_fp
	visible = Controls.view_fp and player != null and is_instance_valid(player) and player.alive and player.scope_k < 0.5
	if not visible: return
	if Controls.weapon_id != _wid: _set_weapon(Controls.weapon_id)
	if _gun and _wid == "xbow":
		var bn := _gun.find_child("Bolt", true, false) as Node3D
		if bn: bn.visible = Controls.ammo > 0
	_t += dt
	var cam := get_parent() as Camera3D
	# where the right hand holds the grip (camera space) per weapon kind
	var pose: Dictionary = POSE[_kind]
	var grip: Vector3 = pose["grip"]
	# walk bob
	var hs := Vector2(player.velocity.x, player.velocity.z).length()
	var mv := clampf(hs / 5.0, 0.0, 1.0)
	var bob := Vector3(sin(_t * 7.0) * 0.010, -absf(cos(_t * 7.0)) * 0.012, 0.0) * mv
	# recoil / knife lunge (the 3rd-person soldier's kick goes 1 -> 0 after each shot)
	var kick: float = player._soldier._kick if player._soldier else 0.0
	if kick > _last_kick + 0.3 and not _kind in ["knife", "axe"]:
		_flash.visible = true; _flash_t = 0.04
	_last_kick = kick
	_flash_t -= dt
	if _flash_t <= 0.0: _flash.visible = false
	var rec := Vector3.ZERO; var rec_rot := Vector3.ZERO
	if _kind == "knife":
		var l: float = sin(PI * (1.0 - kick)) if kick > 0.0 else 0.0
		rec = Vector3(-0.06 * l, 0.04 * l, -0.22 * l); rec_rot = Vector3(-30.0 * l, 0, 25.0 * l)
	else:
		var kk := kick * kick
		rec = Vector3(0, 0.01 * kk, 0.06 * kk * (1.0 if _kind == "long" else 0.7)) * S; rec_rot = Vector3(5.0 * kk, 0, 0)
	# reload dip, swap / grenade lowering
	_reload_k = move_toward(_reload_k, 1.0 if Controls.reloading else 0.0, dt * 5.0)
	var low := 1.0 if (Controls.nade_aiming or Controls.swapping) else 0.0
	_raise = move_toward(_raise, low, dt * (6.0 if low < _raise else 8.0))
	# keep the muzzle out of walls
	var space := player.get_world_3d().direct_space_state
	var fwd := -cam.global_transform.basis.z
	var reach := 0.45 + _len * 0.6
	var q := PhysicsRayQueryParameters3D.create(cam.global_position, cam.global_position + fwd * reach)
	q.exclude = [player.get_rid()]
	var h := space.intersect_ray(q)
	var want_push: float = (reach - cam.global_position.distance_to(h["position"])) if h else 0.0
	_push = lerpf(_push, clampf(want_push / 0.45, 0.0, 1.0), minf(1.0, dt * 12.0))   # 0..1 how blocked
	# pose the weapon: grip anchor at `grip`
	var brk := 1.0 if bool(_wdef.get("break", false)) else 0.0      # break-action: muzzle tipped down, gun rolled and brought in so the open breech faces the eye
	var rot: Vector3 = pose["rot"] + Vector3(rec_rot.x - (28.0 - 10.0 * brk) * _reload_k - 40.0 * _raise - 32.0 * _push, rec_rot.y + 28.0 * _push + 8.0 * brk * _reload_k, rec_rot.z + (22.0 - 10.0 * brk) * _reload_k)
	var bas := Basis.from_euler(Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z)))
	var target: Vector3 = grip + bob + rec + Vector3(-0.02 * _push - 0.07 * brk * _reload_k, -(0.10 - 0.17 * brk) * _reload_k - 0.30 * _raise - 0.05 * _push, 0.08 * _push + 0.05 * brk * _reload_k)
	if _kind == "axe":                     # the swing owns the pose (lowering for swaps / grenades still applies)
		var ap := _axe_fp(1.0 - kick if kick > 0.0 else 0.0)
		target = (ap[0] as Vector3) + bob + Vector3(0, -0.30 * _raise, 0)
		bas = Basis(Vector3.RIGHT, deg_to_rad(-40.0 * _raise)) * (ap[1] as Basis)
		if _body and _body._tgt:                 # straight wrist: hand along the forearm (as in third person)
			var kk := _len / maxf(_body._len(), 0.001)
			var sh_m: Vector3 = _body._bone_s(_body._arm["UpperArm.R"]); var el_m: Vector3 = _body._bone_s(_body._arm["LowerArm.R"])
			var ua: float = sh_m.distance_to(el_m) * kk; var la: float = el_m.distance_to(_body._bone_s(_body._arm["Hand.R"])) * kk
			var rs0: Vector3 = target + Vector3(0.10, -0.30, 0.95).normalized() * (ua + la) * 0.92
			var want := bas * Vector3.FORWARD
			var hb: float = _body.hand_back * kk
			for it in 3:
				bas = Soldier.straight_grip(rs0, target - (bas * Soldier.AXE_F).normalized() * hb, ua, la, ap[2], want, Soldier.AXE_F)
			_body._axe_pole = _body.transform.basis.inverse() * (ap[2] as Vector3)
		var sw := 1.0 - kick if kick > 0.0 else 0.0
		if sw > 0.2 and sw < 0.5:
			if _trail == null: _trail = SwingTrail.new(false); add_child(_trail); _trail.life = 0.12
			var hd: Array = _wdef["head"]
			var ht := Transform3D(bas, target - bas * _anchor("grip"))          # camera space, like the holder
			_trail.add(ht * Vector3(0, 0, (0.5 - float(hd[0])) * _len), ht * Vector3(0, -0.12 * _len, (0.5 - float(hd[1])) * _len))
	_holder.transform = Transform3D(bas, target - bas * _anchor("grip"))
	# hands + forearms
	var hr: Vector3 = _holder.transform * _anchor("grip")
	var hl: Vector3
	if _kind == "long": hl = _holder.transform * _anchor("fore") + bas * Vector3(0, -0.035, 0)   # under the handguard
	elif _kind == "pistol": hl = hr + bas * Vector3(-0.03, -0.012, -0.012) * S                       # support hand wraps the strong hand
	else: hl = pose["sl"]
	if _kind == "long" and bool(_wdef.get("vfore", false)):
		hl = _holder.transform * _anchor("fore")
	# the body's arms: put its shoulders below the frame (right one behind the grip, left one under the
	# support hand, a little turned like a bladed stance) and let its own hand IK take the grips
	var rs: Vector3 = hr + bas * Vector3(0.05, -0.09, 0.15)
	var ls: Vector3
	if _kind == "long": ls = hl + bas * Vector3(-0.10, -0.12, 0.17)
	else:
		# handguns / knife: shoulders placed from the body's own arm length and shoulder width (as drawn
		# here), so short chibi arms still reach the grip instead of hanging off-screen
		var kk := _len / maxf(_body._len(), 0.001) if _body and _body._tgt else 1.0
		var rr: float = _body._reach("R") * kk if _body and _body._tgt else 0.18
		var sw: float = _body._bone_s(_body._arm["UpperArm.R"]).distance_to(_body._bone_s(_body._arm["UpperArm.L"])) * kk if _body and _body._tgt else 0.24
		rs = hr + ((Vector3(0.10, -0.30, 0.95).normalized() * rr * 0.92) if _kind == "axe" else bas * (Vector3(0.10, -0.30, 0.95).normalized() * rr * 0.92))   # axe: shoulder fixed in camera space (the wrist solve used it)
		ls = rs + Vector3(-sw, 0.0, 0.0 if _kind == "pistol" else 0.04)
	_pose_body(rs, ls)
	_hand_l.visible = false; _arm_l.visible = false; _hand_r.visible = false; _arm_r.visible = false
	# muzzle (tracers / flash)
	var mz: Vector3 = _holder.transform * Vector3(0, _anchor("grip").y + 0.03, -_len * 0.5)
	_flash.position = mz
	muzzle = cam.global_transform * mz

static func _axe_fp(s: float) -> Array:
	var i := 0
	while i < AXE_FP.size() - 2 and s > float(AXE_FP[i + 1][0]): i += 1
	var a: Array = AXE_FP[i]; var b: Array = AXE_FP[i + 1]
	var t := clampf((s - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.001), 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)
	return [(a[1] as Vector3).lerp(b[1], t), Basis(Vector3.UP, deg_to_rad(lerpf(a[3], b[3], t))) * Basis(Vector3.RIGHT, deg_to_rad(lerpf(a[2], b[2], t))) * Basis(Vector3.BACK, deg_to_rad(lerpf(a[4], b[4], t))), (a[5] as Vector3).lerp(b[5], t)]

func _pose_body(rs: Vector3, ls: Vector3) -> void:
	if _body == null or _body._tgt == null: return
	var rs_m: Vector3 = _body._bone_s(_body._arm["UpperArm.R"])
	var ls_m: Vector3 = _body._bone_s(_body._arm["UpperArm.L"])
	var k := _len / maxf(_body._len(), 0.001)          # same arm : gun proportion as in third person
	var xm := (rs_m - ls_m).normalized(); var ym := (Vector3.UP - xm * Vector3.UP.dot(xm)).normalized()
	var xt := (rs - ls).normalized(); var yt := (Vector3.UP - xt * Vector3.UP.dot(xt)).normalized()
	var r := Basis(xt, yt, xt.cross(yt)) * Basis(xm, ym, xm.cross(ym)).inverse()
	var b := r.scaled(Vector3.ONE * k)
	_body.transform = Transform3D(b, rs - b * rs_m)
	_body.transform.origin -= b * _body.fp_shift       # short arms: bring the shoulders to the gun
	_body.fp_gun_xf = _body.transform.affine_inverse() * _holder.transform * Transform3D(Basis.from_scale(Vector3.ONE * k), Vector3.ZERO)

func _place_limb(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var d := b - a
	var L := d.length()
	(mi.mesh as CylinderMesh).height = L + 0.02
	var y := d / maxf(L, 0.001)
	var x := y.cross(Vector3.BACK).normalized()
	if x.length() < 0.1: x = Vector3.RIGHT
	var z := x.cross(y)
	mi.transform = Transform3D(Basis(x, y, z), (a + b) * 0.5)
