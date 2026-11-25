class_name Target
extends StaticBody3D
## M1 hittable dummy: flashes on hit and counts into Controls.hits.

var _mat: StandardMaterial3D
var _flash := 0.0

func _ready() -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(1.0, 1.6, 1.0); m.mesh = bm
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.30, 0.52, 0.80)
	m.material_override = _mat
	m.position = Vector3(0, 0.8, 0)
	add_child(m)
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new(); bs.size = Vector3(1.0, 1.6, 1.0)
	col.shape = bs; col.position = Vector3(0, 0.8, 0)
	add_child(col)

func hit(_dmg: int, _is_head: bool) -> void:
	Controls.hits += 1
	_flash = 1.0

func _process(dt: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - dt * 4.0)
		_mat.albedo_color = Color(0.30, 0.52, 0.80).lerp(Color(1.0, 0.35, 0.25), _flash)
