class_name SpawnUtil
## spread players round a spawn point without putting anyone inside a wall or under the floor:
## try a few nearby spots, keep one with open air between it and the point and floor under it
## keep only spawn points with floor right under them (a point over a stair well / hole drops you)
static func grounded(world: World3D, pts: Array) -> Array:
	var space := world.direct_space_state
	var ok := []
	for p in pts:
		var h := space.intersect_ray(PhysicsRayQueryParameters3D.create((p as Vector3) + Vector3(0, 0.5, 0), (p as Vector3) + Vector3(0, -2.2, 0)))
		if not h.is_empty(): ok.append(p)
	return ok if not ok.is_empty() else pts

## anyone below every floor of the map (tunnels are at -3) has fallen out
const KILL_Y := -12.0

static func near(world: World3D, p: Vector3, others: Array = []) -> Vector3:
	var space := world.direct_space_state
	var busy := func(q: Vector3) -> bool:
		for o in others:
			if is_instance_valid(o) and (o as Node3D).global_position.distance_to(q) < 1.2: return true
		return false
	if not busy.call(p): return p
	for i in 12:
		var a := TAU * i / 12.0 + randf() * 0.3
		var r := 1.2 + 0.6 * (i / 6)
		var q := p + Vector3(cos(a) * r, 0, sin(a) * r)
		var wall := PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.2, 0), q + Vector3(0, 0.2, 0))
		if not space.intersect_ray(wall).is_empty(): continue
		var down := PhysicsRayQueryParameters3D.create(q + Vector3(0, 1.5, 0), q + Vector3(0, -2.5, 0))
		var h := space.intersect_ray(down)
		if h.is_empty() or absf((h["position"] as Vector3).y - (p.y - 1.0)) > 0.6: continue
		var spot: Vector3 = h["position"] + Vector3(0, 1.0, 0)
		if busy.call(spot): continue
		return spot
	return p
