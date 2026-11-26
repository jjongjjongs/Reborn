# Turns a hand-drawn ASCII map (2 m per character) into the plan JSON that
# build_quarter.py meshes in Blender and map_plan.gd loads in Godot.
#   python3 ascii_plan.py maps/bazaar.txt  -> game/assets/maps/<name>.json
#
# Legend (each character = 2 x 2 m):
#   #  building mass            .  street (z 0)          ,  square / yard (z 0)
#   1-9 raised floor, z = n*0.4 (3 = 1.2 m jumpable, 8 = 3.2 m storey)
#   o  room inside a building (floor 0, ceiling 3.2)
#   =  street with a tunnel running underneath     t  tunnel under a building (z -3)
#   h  bridge / overpass: walkable at 3.2 with a passage underneath (0..2.8)
#   w  shallow water (z -0.8)
#   > < v ^  stairs / ramp (heights come from the cells at both ends)
#   x  crate 1.1   X  crate stack 2.2   c  container 2.6   C  stacked containers 5.2   k  barrier 1.0
#   z  zombie spawn (survival)
#   A B  bomb sites   a d  attack / defend spawn (DM: red / blue)   p  FFA spawn   m  mid marker
#   props (stand on the surrounding floor; Godot places models + colliders):
#   L  street lamp   T  tree / palm   V  parked car (2 chars long)   b  barrels
import json, sys, os

src = sys.argv[1]
head, body = open(src, encoding="utf-8").read().split("---\n", 1)
meta = dict(l.split(":", 1) for l in head.strip().splitlines())
meta = {k.strip(): v.strip() for k, v in meta.items()}
rows = [r.rstrip("\n") for r in body.splitlines() if r.strip()]
NC = max(len(r) for r in rows); NR = len(rows)
rows = [r.ljust(NC, "#") for r in rows]
C = 2.0
W, H = NC * C, NR * C

FLOORK = {".": ("street", 0.0), ",": ("plaza", 0.0), "m": ("street", 0.0), "p": ("street", 0.0),
          "A": ("siteA", 0.0), "z": ("street", 0.0), "B": ("siteB", 0.0), "a": ("att", 0.0), "d": ("def", 0.0), "w": ("water", -0.8)}
BLOCKS = {"x": (1.1, "crate"), "X": (2.2, "crate"), "c": (2.6, "cont"), "C": (5.2, "cont"), "k": (1.0, "barrier")}
RAMPS = "<>v^"
PROPS = {"L": "lamp", "T": "tree", "V": "car", "b": "barrel"}

def ch(i, j):
    if 0 <= i < NC and 0 <= j < NR: return rows[j][i]
    return "#"
def under(i, j):
    """floor character beneath a block / prop (nearest plain floor neighbour)."""
    for di, dj in ((-1, 0), (1, 0), (0, -1), (0, 1), (-2, 0), (2, 0), (0, -2), (0, 2), (-3, 0), (3, 0)):
        c = ch(i + di, j + dj)
        if c not in BLOCKS and c not in PROPS and c != "#" and c not in RAMPS and c not in "pm": return c
    return "."
def floor_of(c, i=None, j=None):
    if (c in BLOCKS or c in PROPS) and i is not None: c = under(i, j)
    if c in FLOORK: return FLOORK[c][1]
    if c.isdigit(): return int(c) * 0.4
    return {"o": 0.0, "=": 0.0, "t": -3.0, "h": 3.2}.get(c)

def rects(pred):
    """greedy rectangles of cells where pred(i,j) holds, keyed by pred's value."""
    used = [[False] * NC for _ in range(NR)]; out = []
    for j in range(NR):
        for i in range(NC):
            if used[j][i]: continue
            v = pred(i, j)
            if v is None: continue
            i1 = i
            while i1 + 1 < NC and not used[j][i1 + 1] and pred(i1 + 1, j) == v: i1 += 1
            j1 = j
            while j1 + 1 < NR and all(not used[j1 + 1][q] and pred(q, j1 + 1) == v for q in range(i, i1 + 1)): j1 += 1
            for jj in range(j, j1 + 1):
                for ii in range(i, i1 + 1): used[jj][ii] = True
            out.append((v, i, j, i1 + 1, j1 + 1))
    return out

spaces, ramps, blocks = [], [], []
def fkey(i, j):
    c = ch(i, j)
    if c in BLOCKS or c in PROPS: c = under(i, j)
    if c in FLOORK: return ("sky",) + FLOORK[c]
    if c.isdigit(): return ("sky", "plaza", int(c) * 0.4)
    if c == "o": return ("room", "room", 0.0)
    if c == "=": return ("sky", "street", 0.0)
    if c == "h": return ("sky", "plaza", 3.2)
    return None
DM = meta.get("mode", "dm") != "bomb"
for v, i0, j0, i1, j1 in rects(fkey):
    if DM and v[1] in ("att", "def"): v = (v[0], "street", v[2])
    kind = v[1] if v[0] == "sky" else "room"
    spaces.append([kind, i0 * C, j0 * C, i1 * C, j1 * C, v[2], 3.2 if v[0] == "room" else None])
for v, i0, j0, i1, j1 in rects(lambda i, j: ch(i, j) if ch(i, j) in "=th" else None):
    if v in "=t": spaces.append(["tunnel", i0 * C, j0 * C, i1 * C, j1 * C, -3.0, -0.25])
    else: spaces.append(["street", i0 * C, j0 * C, i1 * C, j1 * C, 0.0, 2.8])
for v, i0, j0, i1, j1 in rects(lambda i, j: ch(i, j) if ch(i, j) in RAMPS else None):
    if v in "<>":
        jm = (j0 + j1) // 2
        a, b = floor_of(ch(i0 - 1, jm), i0 - 1, jm), floor_of(ch(i1, jm), i1, jm)
        d = "e" if (b or 0) >= (a or 0) else "w"
    else:
        im = (i0 + i1) // 2
        a, b = floor_of(ch(im, j0 - 1), im, j0 - 1), floor_of(ch(im, j1), im, j1)
        d = "s" if (b or 0) >= (a or 0) else "n"
    if a is None or b is None:
        print("ramp without floor at both ends", v, i0, j0, file=sys.stderr); a = a or 0.0; b = b or 0.0
    ramps.append([i0 * C, j0 * C, i1 * C, j1 * C, min(a, b), max(a, b), d, None])
n_cont = 0
for v, i0, j0, i1, j1 in rects(lambda i, j: ch(i, j) if ch(i, j) in BLOCKS else None):
    h, kind = BLOCKS[v]
    if kind == "cont": kind = "cont%d" % (n_cont % 4); n_cont += 1
    pad = 0.0 if kind.startswith("cont") or kind == "barrier" else 0.25
    blocks.append([i0 * C + pad, j0 * C + pad, (i1 - i0) * C - 2 * pad, (j1 - j0) * C - 2 * pad, h, kind])

props = []
for v, i0, j0, i1, j1 in rects(lambda i, j: ch(i, j) if ch(i, j) in PROPS else None):
    if v == "V":   # cars: one per 1x2 / 2x1 run
        horiz = (i1 - i0) >= (j1 - j0)
        n = max(1, ((i1 - i0) if horiz else (j1 - j0)) // 2)
        for q in range(n):
            if horiz: props.append(["car", (i0 + 2 * q + 1) * C, (j0 + j1) / 2 * C, 90])
            else: props.append(["car", (i0 + i1) / 2 * C, (j0 + 2 * q + 1) * C, 0])
    else:
        for jj in range(j0, j1):
            for ii in range(i0, i1):
                props.append([PROPS[v], (ii + .5) * C, (jj + .5) * C, 0])

def cells_of(c):
    return [((i + .5) * C, (j + .5) * C) for j in range(NR) for i in range(NC) if rows[j][i] == c]
def pick(pts, n=5):
    if not pts: return []
    pts = sorted(pts)
    return [list(pts[int(k * (len(pts) - 1) / max(1, n - 1))]) for k in range(n)]
def bbox(c):
    pts = cells_of(c)
    if not pts: return None
    x0 = min(p[0] for p in pts) - 1; x1 = max(p[0] for p in pts) + 1
    y0 = min(p[1] for p in pts) - 1; y1 = max(p[1] for p in pts) + 1
    return [[x0, y0], [x1, y0], [x1, y1], [x0, y1]]

plan = {"name": meta["name"], "theme": meta.get("theme", "old"), "mode": meta.get("mode", "dm"), "W": W, "H": H,
        "_note": "generated by tools/blender/ascii_plan.py from " + os.path.basename(src),
        "spaces": spaces, "ramps": ramps, "blocks": blocks,
        "att_spawns": pick(cells_of("a")), "def_spawns": pick(cells_of("d")),
        "ffa_spawns": [list(p) for p in cells_of("p")], "zombie_spawns": [list(p) for p in cells_of("z")], "props": props}
if bbox("A"): plan["siteA"] = bbox("A")
if bbox("B"): plan["siteB"] = bbox("B")
mids = cells_of("m"); plan["mid"] = list(mids[0]) if mids else [W / 2, H / 2]
out = os.path.join(os.path.dirname(__file__), "../../game/assets/maps/%s.json" % meta["name"])
json.dump(plan, open(out, "w"), indent=1)
print(meta["name"], "%dx%d m" % (W, H), len(spaces), "spaces", len(ramps), "ramps", len(blocks), "blocks", len(props), "props",
      "ffa", len(plan["ffa_spawns"]), "att", len(plan["att_spawns"]), "def", len(plan["def_spawns"]))
