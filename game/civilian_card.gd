class_name CivilianCard
extends StaticBody3D
## 킬하우스 민간인 표적 (blue card): hitting it costs time in the run
signal shot
var _m: StandardMaterial3D
var _flash := 0.0
func _ready() -> void:
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.62, 1.5, 0.04); mi.mesh = bm
	_m = StandardMaterial3D.new(); _m.albedo_color = Color(0.25, 0.55, 0.95); mi.material_override = _m
	mi.position.y = 1.15; add_child(mi)
	var col := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = Vector3(0.62, 1.5, 0.2); col.shape = bs; col.position.y = 1.15; add_child(col)
	var l := Label3D.new(); l.text = "민간인"; l.font_size = 40; l.pixel_size = 0.01; l.outline_size = 8; l.position = Vector3(0, 2.1, 0)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; add_child(l)
func hit(_dmg: int, _is_head: bool = false, _attacker = null) -> void:
	_flash = 1.0; Sfx.play("hurt"); shot.emit()
func _process(dt: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - dt * 3.0)
		_m.albedo_color = Color(0.25, 0.55, 0.95).lerp(Color(1, 0.2, 0.2), _flash)
