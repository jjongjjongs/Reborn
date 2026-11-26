class_name CamRig
## Camera shared by the modes. 1인칭 (Controls.view_fp): at the eyes with a ViewModel.
## Third-person: over-the-shoulder follow, sniper scope
## blend, and wall collision (the camera is pulled in front of anything between
## the player's head and its wanted spot, so walls never block or get seen through).

static func follow(cam: Camera3D, player: PlayerBody) -> void:
	var b := Basis.from_euler(Vector3(deg_to_rad(player.aim_pitch), deg_to_rad(player.aim_yaw), 0))
	var fwd := -b.z
	if Controls.view_fp:
		# 1인칭: eyes + weapon view model on the camera
		if cam.get_node_or_null("ViewModel") == null:
			var vm := ViewModel.new(); vm.name = "ViewModel"; vm.player = player
			cam.add_child(vm)
		cam.near = 0.03
		cam.global_position = player.global_position + Vector3(0, player.eye_h + 0.24, 0) + Controls.shake_offset()
		cam.global_basis = b
		cam.fov = lerpf(60.0, 60.0 / 2.5, player.scope_k)
		return
	cam.near = 0.05
	var pivot := player.global_position + Vector3(0, player.eye_h, 0)
	var k := player.scope_k                     # sniper scope: first person + zoom
	var want := pivot - fwd * lerpf(4.0, -0.2, k) + b.x * lerpf(0.85, 0.0, k) + Vector3(0, lerpf(0.42, 0.1, k), 0)
	var hit := false
	if k < 0.5:
		var space := player.get_world_3d().direct_space_state
		var q := PhysicsRayQueryParameters3D.create(pivot, want)
		q.exclude = [player.get_rid()]
		var h := space.intersect_ray(q)
		if h:
			var d: Vector3 = (want - pivot).normalized()
			want = h["position"] - d * 0.3
			hit = true
	# snap in when blocked (never show the inside of a wall), ease out otherwise
	cam.global_position = want if hit else cam.global_position.lerp(want, lerpf(0.35, 1.0, k))
	cam.look_at(pivot + fwd * 12.0, Vector3.UP)
	cam.fov = lerpf(65.0, 65.0 / 2.5, k)
	cam.global_position += Controls.shake_offset()


# the centre ray the camera would have for a scope blend k (0 = shoulder view, 1 = scope)
static func center_ray(player: PlayerBody, k: float) -> Array:
	var b := Basis.from_euler(Vector3(deg_to_rad(player.aim_pitch), deg_to_rad(player.aim_yaw), 0))
	var fwd := -b.z
	var pivot := player.global_position + Vector3(0, player.eye_h, 0)
	if Controls.view_fp:
		return [pivot + Vector3(0, 0.24, 0), fwd]
	var want := pivot - fwd * lerpf(4.0, -0.2, k) + b.x * lerpf(0.85, 0.0, k) + Vector3(0, lerpf(0.42, 0.1, k), 0)
	return [want, (pivot + fwd * 12.0 - want).normalized()]

# turn the aim so that the camera of blend k looks straight at `t`
# (opening / closing the scope keeps the point under the crosshair)
static func match_aim(player: PlayerBody, t: Vector3, k: float) -> void:
	for i in 6:
		var r := center_ray(player, k)
		var d: Vector3 = r[1]
		var w: Vector3 = (t - (r[0] as Vector3)).normalized()
		player.aim_yaw += rad_to_deg(atan2(-w.x, -w.z) - atan2(-d.x, -d.z))
		player.aim_pitch = clampf(player.aim_pitch + rad_to_deg(asin(clampf(w.y, -1, 1)) - asin(clampf(d.y, -1, 1))), -45.0, 45.0)
