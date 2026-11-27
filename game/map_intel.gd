class_name MapIntel
extends RefCounted
## Automatic map analysis for bots (built once when a map loads, from ray casts against the
## level's colliders, so new or rebuilt maps need no hand work):
##   cover  - a standing spot with a wall / crate right next to it on some side (bitmask of the
##            8 directions that are blocked at chest AND head height = full cover; low = chest only)
##   peek   - a cover spot where one step sideways opens a long view past the cover
##   choke  - a narrow passage (walls close on both sides, open along it)
##   high   - a raised spot (>= 2 m above the ground next to it) that looks down onto open ground
## Bots ask: nearest cover from a threat, a peek spot, a high spot near me.

const STEP := 2.0
const DIRS := [Vector3(1, 0, 0), Vector3(0.7071, 0, 0.7071), Vector3(0, 0, 1), Vector3(-0.7071, 0, 0.7071),
	Vector3(-1, 0, 0), Vector3(-0.7071, 0, -0.7071), Vector3(0, 0, -1), Vector3(0.7071, 0, -0.7071)]

static var points: Array = []     # {p: Vector3, cover: int (full mask), low: int, peek: bool, choke: bool, high: bool}
static var ms := 0.0
static var ready := false          # finalize() ran for this map

static func analyze(world: World3D, bounds: Rect2) -> void:
	var t0 := Time.get_ticks_usec()
	points.clear(); ready = false
	var sp := world.direct_space_state
	var nx := int(bounds.size.x / STEP); var nz := int(bounds.size.y / STEP)
	for j in nz:
		for i in nx:
			var x := bounds.position.x + (i + 0.5) * STEP; var z := bounds.position.y + (j + 0.5) * STEP
			# every walkable layer under this column (street, bridge / roof above it)
			var top := 40.0
			for layer in 3:
				var h := sp.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, top, z), Vector3(x, -10, z)))
				if h.is_empty(): break
				var hp: Vector3 = h["position"]
				if (h["normal"] as Vector3).y > 0.8 and _headroom(sp, hp):
					_add(sp, hp)
				top = hp.y - 0.3
				if top < -9.0: break
	_mark_high(sp)
	ms = (Time.get_ticks_usec() - t0) / 1000.0

static func _headroom(sp: PhysicsDirectSpaceState3D, p: Vector3) -> bool:
	var h := sp.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.1, 0), p + Vector3(0, 2.0, 0)))
	return h.is_empty()

static func _blocked(sp: PhysicsDirectSpaceState3D, from: Vector3, d: Vector3, L: float) -> float:
	var h := sp.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + d * L))
	return from.distance_to(h["position"]) if not h.is_empty() else L

static func _add(sp: PhysicsDirectSpaceState3D, p: Vector3) -> void:
	var full := 0; var low := 0
	var dist := []
	for k in 8:
		var d: Vector3 = DIRS[k]
		var chest := _blocked(sp, p + Vector3(0, 1.0, 0), d, 1.4)
		var head := _blocked(sp, p + Vector3(0, 1.7, 0), d, 1.4)
		if chest < 1.3 and head < 1.3: full |= 1 << k
		elif chest < 1.3: low |= 1 << k
		dist.append(_blocked(sp, p + Vector3(0, 1.2, 0), d, 12.0))
	# narrow passage: both sides close on one axis, the other axis open
	var choke := false
	for k in 4:
		var across: float = dist[k] + dist[k + 4]
		var along: float = dist[(k + 2) % 8] + dist[(k + 6) % 8]
		if across < 4.6 and along > 10.0: choke = true
	# peek: stepping 1 m to the side of a blocked direction gives a long view that way
	var peek := false
	if full != 0:
		for k in 8:
			if full & (1 << k) == 0: continue
			var d: Vector3 = DIRS[k]
			var side := Vector3(-d.z, 0, d.x)
			for s in [-1.0, 1.0]:
				var q: Vector3 = p + side * s * 1.1 + Vector3(0, 1.5, 0)
				if _blocked(sp, p + Vector3(0, 1.5, 0), side * s, 1.1) >= 1.05 and _blocked(sp, q, d, 14.0) >= 12.0:
					peek = true
	points.append({"p": p, "cover": full, "low": low, "peek": peek, "choke": choke, "high": false})

static func _mark_high(sp: PhysicsDirectSpaceState3D) -> void:
	for e in points:
		var p: Vector3 = e["p"]
		if p.y < 2.0: continue
		# ground 4-8 m out in some direction is >= 2 m lower and visible from here
		for d in DIRS:
			for r in [4.0, 7.0]:
				var g := sp.intersect_ray(PhysicsRayQueryParameters3D.create(p + d * r + Vector3(0, 0.5, 0), p + d * r + Vector3(0, -12, 0)))
				if g.is_empty(): continue
				var gp: Vector3 = g["position"]
				if p.y - gp.y >= 2.0 and _blocked(sp, p + Vector3(0, 1.6, 0), (gp + Vector3(0, 1.0, 0) - p - Vector3(0, 1.6, 0)).normalized(),
						(gp - p).length()) >= (gp - p).length() - 0.6:
					e["high"] = true; break
			if e["high"]: break

## once the navigation map has synced: drop spots nobody can walk to (building roofs, sealed
## yards) - closest navmesh point must be right there and reachable from `from`
static func finalize(world: World3D, from: Vector3) -> void:
	var t0 := Time.get_ticks_usec()
	var map := world.navigation_map
	var keep: Array = []
	var start := NavigationServer3D.map_get_closest_point(map, from)
	for e in points:
		var p: Vector3 = e["p"]
		var c := NavigationServer3D.map_get_closest_point(map, p)
		if Vector2(c.x - p.x, c.z - p.z).length() > 0.9 or absf(c.y - p.y) > 0.8: continue
		if e["high"] or e["peek"]:     # the spots bots travel to: check they connect
			var path := NavigationServer3D.map_get_path(map, start, c, true)
			if path.is_empty() or path[path.size() - 1].distance_to(c) > 1.0: continue
		keep.append(e)
	points = keep; ready = true
	ms += (Time.get_ticks_usec() - t0) / 1000.0

# ---------------------------------------------------------------- queries
## a full-cover spot within `radius` of `from` whose wall is between it and `threat`
static func cover_from(from: Vector3, threat: Vector3, radius := 10.0) -> Vector3:
	var best := Vector3.INF; var bd := 1e9
	for e in points:
		var p: Vector3 = e["p"]
		var m: int = e["cover"]
		if m == 0 or absf(p.y - from.y) > 1.5: continue
		var d := p.distance_to(from)
		if d > radius: continue
		var to := threat - p; to.y = 0.0; to = to.normalized()
		var ok := false
		for k in 8:
			if m & (1 << k) and (DIRS[k] as Vector3).dot(to) > 0.75: ok = true; break
		if not ok: continue
		var score := d + (0.0 if e["peek"] else 2.0)        # prefer spots you can shoot from
		if score < bd: bd = score; best = p
	return best

static func high_near(from: Vector3, radius := 25.0) -> Vector3:
	var best := Vector3.INF; var bd := 1e9
	for e in points:
		if not e["high"]: continue
		var d := (e["p"] as Vector3).distance_to(from)
		if d < radius and d < bd: bd = d; best = e["p"]
	return best

static func counts() -> Dictionary:
	var c := {"points": points.size(), "cover": 0, "peek": 0, "choke": 0, "high": 0}
	for e in points:
		if e["cover"] != 0: c["cover"] += 1
		if e["peek"]: c["peek"] += 1
		if e["choke"]: c["choke"] += 1
		if e["high"]: c["high"] += 1
	return c
