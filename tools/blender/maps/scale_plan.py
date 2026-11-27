# Widen a map plan (x / y only, every height unchanged): python3 scale_plan.py <name> <factor>
# spaces / ramps / sites / spawns / props / mid scale with the map; blocks (crates, containers,
# barriers) keep their size and only move with it, so cover and climb heights stay the same.
import json, sys, os
name, k = sys.argv[1], float(sys.argv[2])
path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../game/assets/maps/%s.json" % name)
p = json.load(open(path))
r = lambda v: round(v * k, 3)
p["W"] = r(float(p["W"])); p["H"] = r(float(p["H"]))
for s in p["spaces"]: s[1:5] = [r(v) for v in s[1:5]]
for s in p["ramps"]: s[0:4] = [r(v) for v in s[0:4]]
for b in p["blocks"]:
    cx, cy = (b[0] + b[2] / 2) * k, (b[1] + b[3] / 2) * k
    b[0], b[1] = round(cx - b[2] / 2, 3), round(cy - b[3] / 2, 3)
for key in ("att_spawns", "def_spawns", "ffa_spawns", "zombie_spawns", "siteA", "siteB"):
    if key in p: p[key] = [[r(v) for v in pt] for pt in p[key]]
if "mid" in p: p["mid"] = [r(v) for v in p["mid"]]
for pr in p.get("props", []): pr[1], pr[2] = r(pr[1]), r(pr[2])
p["_note"] = p.get("_note", "") + " | widened x%.2f (heights unchanged) by maps/scale_plan.py" % k
json.dump(p, open(path, "w"))
print(name, p["W"], p["H"])
