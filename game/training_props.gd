class_name TrainingDummy
extends StaticBody3D
## 훈련장 더미: a grey mini soldier that takes damage like a player (100 HP, head above 1.55 m =
## headshot), shows floating damage numbers and an HP bar, goes down at 0 and gets back up.
## mode: 0 standing, 1 strafing left-right, 2 crouched.

var mode := 0
var hp := 100.0
var _body: Soldier
var _bar: MeshInstance3D
var _down_t := 0.0
var _t := 0.0
var _home := Vector3.ZERO
var _col: CollisionShape3D

func _ready() -> void:
	_body = Soldier.new(); add_child(_body)
	_body.setup(Color(0.55, 0.58, 0.62), Color(0.25, 0.27, 0.30))
	_body.set_weapon("m4")
	rotation_degrees.y = 180.0
	_col = CollisionShape3D.new(); var cs := CapsuleShape3D.new(); cs.radius = 0.4
	cs.height = 1.4 if mode == 2 else 2.15; _col.shape = cs; _col.position.y = cs.height * 0.5; add_child(_col)
	if mode == 2: _body.set_crouch(true)
	var top := 2.2 if mode == 2 else 2.95
	var bg := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(1.2, 0.1, 0.02); bg.mesh = bm
	var dm := StandardMaterial3D.new(); dm.albedo_color = Color(0.15, 0.16, 0.18); dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg.material_override = dm; bg.position = Vector3(0, top, 0); add_child(bg)
	_bar = MeshInstance3D.new(); var bm2 := BoxMesh.new(); bm2.size = Vector3(1.2, 0.1, 0.03); _bar.mesh = bm2
	var rm := StandardMaterial3D.new(); rm.albedo_color = Color(0.92, 0.28, 0.22); rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_bar.material_override = rm; _bar.position = Vector3(0, top, -0.01); add_child(_bar)
	var l := Label3D.new(); l.text = ["정지", "좌우 이동", "앉음"][mode]; l.font_size = 44; l.pixel_size = 0.01
	l.outline_size = 8; l.position = Vector3(0, top + 0.3, 0); l.rotation_degrees.y = 180.0; l.double_sided = false; add_child(l)

func hit(dmg: int, is_head: bool = false, _attacker = null) -> void:
	if _down_t > 0.0: return
	Controls.hits += 1
	if is_head: Controls.headshots += 1
	hp -= dmg
	_number(dmg, is_head)
	if hp <= 0.0:
		Controls.kills += 1
		Missions.add("target")
		_down_t = 2.5; _body.set_dead(true); _col.set_deferred("disabled", true)
		Sfx.play("hit")
	_bar.scale.x = maxf(hp, 0.0) / 100.0
	_bar.position.x = -0.6 * (1.0 - _bar.scale.x)

func _number(dmg: int, head: bool) -> void:
	var l := Label3D.new(); l.text = "-%d" % dmg; l.font_size = 64 if head else 52; l.pixel_size = 0.01
	l.modulate = Color(1.0, 0.85, 0.2) if head else Color(1, 1, 1); l.outline_size = 10
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; l.no_depth_test = true
	add_child(l); l.position = Vector3(randf_range(-0.4, 0.4), (1.6 if mode == 2 else 2.2), 0)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y + 0.9, 0.8)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.chain().tween_callback(l.queue_free)

func _process(dt: float) -> void:
	if _down_t > 0.0:
		_down_t -= dt
		if _down_t <= 0.0:
			hp = 100.0; _bar.scale.x = 1.0; _bar.position.x = 0.0
			_body.set_dead(false); _col.set_deferred("disabled", false)
			if mode == 2: _body.set_crouch(true)
		return
	if mode == 1:                   # strafe 2.5 m each way around where it was placed
		if _t == 0.0: _home = position
		_t += dt
		var x := sin(_t * 1.1) * 2.5
		position = _home + Vector3(x, 0, 0)
		_body.drive(0.5, true)
		_body.rotation_degrees.y = 0.0
	else:
		_body.drive(0.0, true)
