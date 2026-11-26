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
const GLOVE := Color(0.13, 0.12, 0.11)
# per kind: right-hand grip point (camera space), weapon rotation (deg), shoulders the forearms start from
const POSE := {
	"long":   {"grip": Vector3(0.24, -0.21, -0.38), "rot": Vector3(1.0, -2.0, 0.0), "sr": Vector3(0.36, -0.44, 0.02), "sl": Vector3(0.02, -0.50, -0.16)},
	"pistol": {"grip": Vector3(0.14, -0.15, -0.48), "rot": Vector3(1.0, -2.0, 0.0), "sr": Vector3(0.26, -0.44, -0.10), "sl": Vector3(0.02, -0.44, -0.14)},
	"knife":  {"grip": Vector3(0.25, -0.20, -0.38), "rot": Vector3(25.0, 25.0, -20.0), "sr": Vector3(0.34, -0.46, 0.0), "sl": Vector3(-0.30, -0.8, 0.0)},
}

var player: PlayerBody
var _wid := ""
var _kind := "long"
var _len := 0.8
var _wdef := {}
var _holder: Node3D
var _gun: Node3D
var _arm_r: MeshInstance3D
var _arm_l: MeshInstance3D
var _hand_r: MeshInstance3D
var _hand_l: MeshInstance3D
var _flash: OmniLight3D
var _flash_t := 0.0
var _t := 0.0
var _last_kick := 0.0
var _raise := 0.0          # 0 = up, 1 = fully lowered (swap / grenade)
var _reload_k := 0.0
var _push := 0.0           # 0..1: muzzle blocked by a wall -> weapon tucked down and in

func _ready() -> void:
	var sl := StandardMaterial3D.new(); sl.albedo_color = SLEEVE; sl.roughness = 0.95
	var gl := StandardMaterial3D.new(); gl.albedo_color = GLOVE; gl.roughness = 0.8
	_holder = Node3D.new(); add_child(_holder)
	_arm_r = _limb(sl, 0.042); _arm_l = _limb(sl, 0.040)
	_hand_r = _fist(gl); _hand_l = _fist(gl)
	_flash = OmniLight3D.new(); _flash.light_color = Color(1, 0.8, 0.4); _flash.light_energy = 3.0; _flash.omni_range = 4.0
	_flash.visible = false; add_child(_flash)

func _limb(m: Material, r: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); var cm := CapsuleMesh.new(); cm.radius = r; cm.height = 0.5
	cm.radial_segments = 10; cm.rings = 2
	mi.mesh = cm; mi.material_override = m; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi); return mi

func _fist(m: Material) -> MeshInstance3D:   # rounded glove, long axis along the weapon
	var mi := MeshInstance3D.new(); var cm := CapsuleMesh.new(); cm.radius = 0.036; cm.height = 0.11
	cm.radial_segments = 10; cm.rings = 3
	mi.mesh = cm; mi.material_override = m; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi); return mi

func _box(m: Material, s: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = s
	mi.mesh = bm; mi.material_override = m; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi); return mi

func _set_weapon(id: String) -> void:
	_wid = id
	_wdef = Soldier.WEAPONS.get(id, Soldier.WEAPONS["m4"])
	_kind = String(_wdef.get("kind", "long"))
	_len = float(_wdef["len"])
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
	m.rotation.y = PI * 0.5              # model muzzle +X -> holder -Z
	m.scale = Vector3.ONE * sc
	m.position = -(Basis(Vector3.UP, PI * 0.5) * (ab.get_center() * sc))
	_gun = m
	_raise = 1.0                          # bring the new weapon up

func _anchor(key: String) -> Vector3:   # [from-butt fraction, height fraction] -> holder space
	var v: Array = _wdef.get(key, _wdef["grip"])
	return Vector3(0.0, float(v[1]) * _len, (0.5 - float(v[0])) * _len)

func _process(dt: float) -> void:
	active = Controls.view_fp
	visible = Controls.view_fp and player != null and is_instance_valid(player) and player.alive and player.scope_k < 0.5
	if not visible: return
	if Controls.weapon_id != _wid: _set_weapon(Controls.weapon_id)
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
	if kick > _last_kick + 0.3 and _kind != "knife":
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
		rec = Vector3(0, 0.01 * kk, 0.06 * kk * (1.0 if _kind == "long" else 0.7)); rec_rot = Vector3(5.0 * kk, 0, 0)
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
	var rot: Vector3 = pose["rot"] + Vector3(rec_rot.x - 28.0 * _reload_k - 40.0 * _raise - 32.0 * _push, rec_rot.y + 28.0 * _push, rec_rot.z + 22.0 * _reload_k)
	var bas := Basis.from_euler(Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z)))
	var target: Vector3 = grip + bob + rec + Vector3(-0.02 * _push, -0.10 * _reload_k - 0.30 * _raise - 0.05 * _push, 0.08 * _push)
	_holder.transform = Transform3D(bas, target - bas * _anchor("grip"))
	# hands + forearms
	var hr: Vector3 = _holder.transform * _anchor("grip")
	var hl: Vector3
	if _kind == "long": hl = _holder.transform * _anchor("fore") + bas * Vector3(0, -0.035, 0)   # under the handguard
	elif _kind == "pistol": hl = hr + bas * Vector3(-0.045, -0.025, 0.02)                          # cupping the grip
	else: hl = pose["sl"]
	_place_limb(_arm_r, pose["sr"], hr)
	_place_limb(_arm_l, pose["sl"], hl)
	var hb := bas * Basis(Vector3.RIGHT, PI * 0.5)       # capsule axis (Y) -> along the barrel
	_hand_r.transform = Transform3D(hb, hr + bas * Vector3(0, -0.02, 0.0))
	_hand_l.transform = Transform3D(hb, hl + bas * Vector3(0, -0.01, 0.0))
	_hand_l.visible = _kind != "knife"; _arm_l.visible = _kind != "knife"
	# muzzle (tracers / flash)
	var mz: Vector3 = _holder.transform * Vector3(0, _anchor("grip").y + 0.03, -_len * 0.5)
	_flash.position = mz
	muzzle = cam.global_transform * mz

func _place_limb(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var d := b - a
	var L := d.length()
	(mi.mesh as CapsuleMesh).height = L + 0.06
	var y := d / maxf(L, 0.001)
	var x := y.cross(Vector3.BACK).normalized()
	if x.length() < 0.1: x = Vector3.RIGHT
	var z := x.cross(y)
	mi.transform = Transform3D(Basis(x, y, z), (a + b) * 0.5)
