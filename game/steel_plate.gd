class_name SteelPlate
extends StaticBody3D
## 철판 표적: rings and swings when hit (counts as a hit)
var radius := 0.25
var _disc: MeshInstance3D
var _swing := 0.0
func _ready() -> void:
	_disc = MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = radius; cm.bottom_radius = radius; cm.height = 0.03
	_disc.mesh = cm; var m := StandardMaterial3D.new(); m.albedo_color = Color(0.82, 0.80, 0.74); m.metallic = 0.5; m.roughness = 0.4
	_disc.material_override = m; _disc.rotation_degrees.x = 90; add_child(_disc)
	var col := CollisionShape3D.new(); var cs := CylinderShape3D.new(); cs.radius = radius; cs.height = 0.06; col.shape = cs
	col.rotation_degrees.x = 90; add_child(col)
func hit(_dmg: int, _is_head: bool = false, _attacker = null) -> void:
	Controls.hits += 1
	Sfx.play_at("ding", global_position)
	_swing = 1.0
func _process(dt: float) -> void:
	if _swing > 0.0:
		_swing = maxf(0.0, _swing - dt * 1.5)
		_disc.rotation_degrees.x = 90.0 + sin(_swing * 18.0) * 25.0 * _swing
