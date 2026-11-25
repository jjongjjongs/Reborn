class_name GrenadeAim
extends Node3D
## Trajectory preview while the grenade button is held: dotted arc from the hand
## plus a ring at the first impact showing the blast radius. Turns grey when the
## finger is over the cancel zone.

const DOTS := 36
var _dots: Array[MeshInstance3D] = []
var _ring: MeshInstance3D
var _center: MeshInstance3D
var _mat_dot := StandardMaterial3D.new()
var _mat_ring := StandardMaterial3D.new()
var _mat_disc := StandardMaterial3D.new()
var _disc: MeshInstance3D

func _ready() -> void:
	top_level = true
	for m in [_mat_dot, _mat_ring, _mat_disc]:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.no_depth_test = true            # stays visible through cover
	var dm := SphereMesh.new(); dm.radius = 0.045; dm.height = 0.09
	dm.radial_segments = 8; dm.rings = 4
	for i in DOTS:
		var d := MeshInstance3D.new(); d.mesh = dm; d.material_override = _mat_dot
		d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(d); _dots.append(d)
	_ring = MeshInstance3D.new()
	var tm := TorusMesh.new(); tm.inner_radius = Grenade.RADIUS - 0.12; tm.outer_radius = Grenade.RADIUS
	tm.rings = 48; tm.ring_segments = 6
	_ring.mesh = tm; _ring.material_override = _mat_ring
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	_disc = MeshInstance3D.new()
	var dk := CylinderMesh.new(); dk.top_radius = Grenade.RADIUS; dk.bottom_radius = Grenade.RADIUS
	dk.height = 0.01; dk.radial_segments = 40
	_disc.mesh = dk; _disc.material_override = _mat_disc
	_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_disc)
	_center = MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 0.18; cm.bottom_radius = 0.18; cm.height = 0.02
	_center.mesh = cm; _center.material_override = _mat_ring
	add_child(_center)
	visible = false

func show_path(points: PackedVector3Array, hit: Vector3, landed: bool, cancel: bool) -> void:
	visible = true
	_mat_dot.albedo_color = Color(0.6, 0.65, 0.7, 0.5) if cancel else Color(1.0, 0.82, 0.4, 0.95)
	_mat_ring.albedo_color = Color(0.6, 0.65, 0.7, 0.35) if cancel else Color(0.89, 0.29, 0.23, 0.75)
	# spread the dots evenly along the simulated points (skip the first few near the hand)
	var n := points.size()
	for i in DOTS:
		var d := _dots[i]
		var k := int(float(i + 1) / float(DOTS) * float(n - 1))
		if k >= n or k < 2:
			d.visible = false
			continue
		d.visible = true
		d.global_position = points[k]
	_mat_disc.albedo_color = Color(0.6, 0.65, 0.7, 0.10) if cancel else Color(0.89, 0.29, 0.23, 0.16)
	_ring.visible = landed
	_center.visible = landed
	_disc.visible = landed
	if landed:
		_disc.global_position = hit + Vector3(0, 0.04, 0)
		_ring.global_position = hit + Vector3(0, 0.05, 0)
		_center.global_position = hit + Vector3(0, 0.03, 0)
