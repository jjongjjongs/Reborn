class_name PopupTarget
extends StaticBody3D
## 훈련 모드 표적: a person-shaped board on a hinge. Takes damage like a player
## (100 HP, head above 1.55 m counts as a headshot), falls back when it drops and
## pops up again after a moment. Hits / headshots / knockdowns go to Controls.

const HP := 100
const DOWN_TIME := 2.5

var hp := HP
var _pivot: Node3D
var _mat: StandardMaterial3D
var _flash := 0.0
var _down_t := 0.0
var _angle := 0.0          # 0 = standing, 90 = flat
var _cols: Array = []

func _ready() -> void:
	add_to_group("target")
	_pivot = Node3D.new(); add_child(_pivot)
	_mat = StandardMaterial3D.new(); _mat.albedo_color = Color(0.86, 0.80, 0.66); _mat.roughness = 0.9
	var ring := StandardMaterial3D.new(); ring.albedo_color = Color(0.85, 0.22, 0.16)
	var dark := StandardMaterial3D.new(); dark.albedo_color = Color(0.30, 0.26, 0.22)
	# silhouette: torso, head, a red ring on the chest, a post and a small base
	for part in [[Vector3(0.62, 1.05, 0.05), Vector3(0, 1.0, 0), _mat], [Vector3(0.30, 0.32, 0.05), Vector3(0, 1.72, 0), _mat],
			[Vector3(0.26, 0.26, 0.06), Vector3(0, 1.15, 0), ring], [Vector3(0.10, 0.48, 0.06), Vector3(0, 0.24, 0), dark]]:
		var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = part[0]; mi.mesh = bm
		mi.position = part[1]; mi.material_override = part[2]
		_pivot.add_child(mi)
	var base := MeshInstance3D.new(); var bb := BoxMesh.new(); bb.size = Vector3(0.7, 0.08, 0.45); base.mesh = bb
	base.material_override = dark; base.position = Vector3(0, 0.04, 0); add_child(base)
	for c in [[Vector3(0.62, 1.05, 0.2), Vector3(0, 1.0, 0)], [Vector3(0.32, 0.34, 0.2), Vector3(0, 1.72, 0)]]:
		var cs := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = c[0]; cs.shape = bs
		cs.position = c[1]; add_child(cs); _cols.append(cs)

func hit(dmg: int, is_head: bool = false, _attacker = null) -> void:
	if _down_t > 0.0: return
	Controls.hits += 1
	if is_head: Controls.headshots += 1
	_flash = 1.0
	hp -= dmg
	if hp <= 0:
		Controls.kills += 1
		_down_t = DOWN_TIME
		for cs in _cols: (cs as CollisionShape3D).set_deferred("disabled", true)
		Sfx.play("hit")

func _process(dt: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - dt * 5.0)
		_mat.albedo_color = Color(0.86, 0.80, 0.66).lerp(Color(1.0, 0.35, 0.25), _flash)
	if _down_t > 0.0:
		_down_t -= dt
		_angle = minf(90.0, _angle + dt * 400.0)
		if _down_t <= 0.0:
			hp = HP
			for cs in _cols: (cs as CollisionShape3D).set_deferred("disabled", false)
	else:
		_angle = maxf(0.0, _angle - dt * 240.0)
	_pivot.rotation_degrees.x = -_angle
