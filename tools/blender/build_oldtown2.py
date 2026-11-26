# Runs INSIDE Blender (sent through the blender-mcp addon's execute_code).
# Builds "구시가지 2" from the plan: walkable shapes are carved into a 1 m grid,
# everything else becomes buildings (a height field of parcels), so the outline
# follows the streets instead of a rectangle.
import bpy, json, math, os

PLAN = "/home/user/Reborn/game/assets/maps/oldtown2.json"
TEX = "/home/user/Reborn/game/assets/city/tex/"
P = json.load(open(PLAN))
W, H = P["W"], P["H"]

# ---------------------------------------------------------------- clean scene
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)
for m in list(bpy.data.meshes):
    bpy.data.meshes.remove(m)
for m in list(bpy.data.materials):
    bpy.data.materials.remove(m)

# ---------------------------------------------------------------- geometry helpers
def seg_d(px, py, a, b):
    dx, dy = b[0]-a[0], b[1]-a[1]; L2 = dx*dx + dy*dy or 1.0
    t = max(0.0, min(1.0, ((px-a[0])*dx + (py-a[1])*dy) / L2))
    qx, qy = a[0] + t*dx - px, a[1] + t*dy - py
    return math.hypot(qx, qy)
def line_d(px, py, pl):
    return min(seg_d(px, py, pl[i], pl[i+1]) for i in range(len(pl)-1))
def in_poly(px, py, pts):
    c = False; j = len(pts) - 1
    for i in range(len(pts)):
        xi, yi = pts[i]; xj, yj = pts[j]
        if (yi > py) != (yj > py) and px < (xj-xi) * (py-yi) / (yj-yi) + xi: c = not c
        j = i
    return c
def edge_d(px, py, pts):
    return min(seg_d(px, py, pts[i], pts[(i+1) % len(pts)]) for i in range(len(pts)))
HILL, HH = P["hill"], P["hill_h"]
def elev(px, py):
    s = edge_d(px, py, HILL) * (1 if in_poly(px, py, HILL) else -1)
    t = max(0.0, min(1.0, (s + 4.0) / 8.0))
    return HH * (t * t * (3 - 2 * t))

# kinds: 0 solid, 1 street, 2 plaza, 3 water, 4 bridge, 5 covered, 6 att, 7 def, 8 siteA, 9 siteB, 10 hall
K = [0] * (W*H)
for y in range(H):
    for x in range(W):
        px, py = x + .5, y + .5
        k = 0
        for pl, w in P["walks"]:
            if line_d(px, py, pl) <= w/2: k = 1; break
        for a in P["areas"]:
            if in_poly(px, py, a["pts"]): k = 6 if a["kind"] == "att" else 7 if a["kind"] == "def" else 2
        if line_d(px, py, P["under"][0]) <= P["under"][1]/2: k = 5
        if in_poly(px, py, P["hall"]): k = 10
        in_canal = line_d(px, py, P["canal"][0]) <= P["canal"][1]/2
        if in_canal and k != 5: k = 3
        for a, b, w in P["bridges"]:
            if seg_d(px, py, a, b) <= w/2 and line_d(px, py, P["canal"][0]) <= P["canal"][1]/2 + 1.5: k = 4
        if in_poly(px, py, P["siteA"]): k = 8
        if in_poly(px, py, P["siteB"]): k = 9
        K[y*W + x] = k
# openness g(p) > 0 on streets / plazas / water, < 0 inside buildings (distance in metres)
SHAPES_L = [(pl, w/2) for pl, w in P["walks"]] + [(P["under"][0], P["under"][1]/2), (P["canal"][0], P["canal"][1]/2)]
SHAPES_P = [a["pts"] for a in P["areas"]] + [P["hall"], P["siteA"], P["siteB"]]
def gopen(px, py):
    g = -99.0
    for pl, r in SHAPES_L:
        g = max(g, r - line_d(px, py, pl))
    for pts in SHAPES_P:
        d = edge_d(px, py, pts)
        g = max(g, d if in_poly(px, py, pts) else -d)
    return g
G = [[gopen(x, y) for x in range(W + 1)] for y in range(H + 1)]

def kat(x, y):
    return -1 if (x < 0 or y < 0 or x >= W or y >= H) else K[y*W + x]
def walkable(k): return k not in (0, 3, -1)

def hsh(a, b):
    s = math.sin(a * 127.1 + b * 311.7) * 43758.5453
    return s - math.floor(s)

# map coords -> Blender (x east, y north, z up); exported glTF lands as Godot X=x-100, Z=y-75
def V(x, y, z): return (x - W/2, -(y - H/2), z)

# ---------------------------------------------------------------- materials
def mat_tex(name, img, tint=(1, 1, 1, 1), rough=0.9):
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree; bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = rough
    if img:
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(TEX + img, check_existing=True)
        mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.blend_type = "MULTIPLY"
        mix.inputs[0].default_value = 1.0
        nt.links.new(tex.outputs["Color"], mix.inputs[6])
        mix.inputs[7].default_value = tint
        nt.links.new(mix.outputs[2], bsdf.inputs["Base Color"])
    else:
        bsdf.inputs["Base Color"].default_value = tint
    return m
MATS = [
    mat_tex("cobble", "T_Concrete_Asphalt_BaseColor.png", (0.86, 0.82, 0.76, 1)),
    mat_tex("plaza", "T_MarbleFloor_BaseColor.png", (0.86, 0.84, 0.80, 1)),
    mat_tex("water", None, (0.12, 0.28, 0.36, 1), 0.15),
    mat_tex("wood", None, (0.42, 0.30, 0.20, 1)),
    mat_tex("covered_floor", "T_Concrete_BaseColor.png", (0.62, 0.60, 0.58, 1)),
    mat_tex("att", "T_Concrete_BaseColor.png", (0.95, 0.62, 0.55, 1)),
    mat_tex("def", "T_Concrete_BaseColor.png", (0.58, 0.74, 0.95, 1)),
    mat_tex("siteA", "T_MarbleFloor_BaseColor.png", (1.0, 0.70, 0.42, 1)),
    mat_tex("siteB", "T_MarbleFloor_BaseColor.png", (1.0, 0.86, 0.50, 1)),
    mat_tex("wall_brick", "T_RedBrick_BaseColor.png"),
    mat_tex("wall_plaster", "T_Concrete_BaseColor.png", (0.95, 0.88, 0.74, 1)),
    mat_tex("wall_brick2", "T_RedBrick_BaseColor.png", (0.80, 0.68, 0.60, 1)),
    mat_tex("wall_stone", "T_Concrete_BaseColor.png", (0.72, 0.74, 0.78, 1)),
    mat_tex("wall_brick3", "T_RedBrick_BaseColor.png", (0.62, 0.48, 0.42, 1)),
    mat_tex("wall_cream", "T_Trim_BaseColor.png", (1, 1, 1, 1)),
    mat_tex("roof", "T_Concrete_BaseColor.png", (0.40, 0.40, 0.42, 1)),
    mat_tex("trim", "T_Trim_BaseColor.png"),
    mat_tex("window", "T_dark_interior.png", (0.75, 0.80, 0.90, 1), 0.25),
    mat_tex("door", None, (0.30, 0.20, 0.13, 1)),
    mat_tex("rail", None, (0.18, 0.18, 0.20, 1)),
]
MI = {m.name: i for i, m in enumerate(MATS)}
FLOOR_MAT = {1: "cobble", 2: "cobble", 4: "wood", 5: "cobble", 6: "cobble", 7: "cobble", 8: "cobble", 9: "cobble", 10: "cobble"}
WALL_LOOKS = ["wall_brick", "wall_plaster", "wall_brick2", "wall_stone", "wall_brick3", "wall_cream"]

class MB:
    def __init__(self): self.v = []; self.f = []; self.uv = []; self.m = []
    def quad(self, a, b, c, d, uvs, mat):
        n = len(self.v); self.v += [a, b, c, d]; self.f.append((n, n+1, n+2, n+3)); self.uv.append(uvs); self.m.append(MI[mat])
    def poly(self, pts, uvs, mat):
        n = len(self.v); self.v += pts; self.f.append(tuple(range(n, n + len(pts)))); self.uv.append(uvs); self.m.append(MI[mat])
    def build(self, name, collide=False):
        me = bpy.data.meshes.new(name); me.from_pydata(self.v, [], self.f)
        for mt in MATS: me.materials.append(mt)
        uvl = me.uv_layers.new(name="UVMap")
        for fi, poly in enumerate(me.polygons):
            poly.material_index = self.m[fi]
            for k, li in enumerate(poly.loop_indices):
                uvl.data[li].uv = self.uv[fi][k]
        me.validate(); me.update()
        ob = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob)
        return ob

def wall(mb, x0, y0, x1, y1, z0, z1, mat, s=3.0):
    # vertical quad from map point (x0,y0) to (x1,y1); outward normal = left of travel in Blender
    L = math.hypot(x1-x0, y1-y0); u0 = (x0 + y0) / s; u1 = u0 + L / s
    mb.quad(V(x0, y0, z0), V(x1, y1, z0), V(x1, y1, z1), V(x0, y0, z1),
            [(u0, z0/s), (u1, z0/s), (u1, z1/s), (u0, z1/s)], mat)

# ---------------------------------------------------------------- floors (+ canal banks)
fl = MB()
E = {}
def ev(x, y):
    key = (x, y)
    if key not in E: E[key] = elev(x, y)
    return E[key]
for y in range(H):
    for x in range(W):
        k = K[y*W + x]
        if k == 3: continue
        if not walkable(k):
            if max(G[y][x], G[y][x+1], G[y+1][x], G[y+1][x+1]) < -0.2: continue
            k = 1
        if k == 4:
            z = [0.12] * 4
        else:
            z = [ev(x, y), ev(x+1, y), ev(x+1, y+1), ev(x, y+1)]
        uv = [(x/4, -y/4), ((x+1)/4, -y/4), ((x+1)/4, -(y+1)/4), (x/4, -(y+1)/4)]
        # Blender winding: (x,y)->(x+1,y)->(x+1,y+1)->(x,y+1) in map coords points down after the y flip; reverse for +Z normal
        fl.quad(V(x, y+1, z[3]), V(x+1, y+1, z[2]), V(x+1, y, z[1]), V(x, y, z[0]), [uv[3], uv[2], uv[1], uv[0]], FLOOR_MAT[k])
        # bank walls down into the canal
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if kat(x+dx, y+dy) == 3:
                if dx == 1: wall(fl, x+1, y+1, x+1, y, -1.2, z[1] if k != 4 else 0.12, "wall_stone")
                if dx == -1: wall(fl, x, y, x, y+1, -1.2, z[0] if k != 4 else 0.12, "wall_stone")
                if dy == 1: wall(fl, x, y+1, x+1, y+1, -1.2, z[3] if k != 4 else 0.12, "wall_stone")
                if dy == -1: wall(fl, x+1, y, x, y, -1.2, z[0] if k != 4 else 0.12, "wall_stone")
floor_ob = fl.build("Floor")

wa = MB()
for y in range(H):
    for x in range(W):
        if K[y*W + x] == 3:
            wa.quad(V(x, y+1, -0.9), V(x+1, y+1, -0.9), V(x+1, y, -0.9), V(x, y, -0.9), [(0,0),(1,0),(1,1),(0,1)], "water")
water_ob = wa.build("Water")

# ---------------------------------------------------------------- buildings: smooth outline (marching squares) + parcel heights
def parcel(x, y):
    px, py = x // 7, y // 7
    base = elev(x + .5, y + .5)
    h = 7 + int(hsh(px, py) * 4) * 3 + (2 if hsh(px + 9, py + 1) > 0.85 else 0)
    return base + h, base, int(hsh(px + 3, py + 7) * len(WALL_LOOKS))
def lerp_pt(a, b, ga, gb):
    t = ga / (ga - gb)
    return (a[0] + (b[0]-a[0]) * t, a[1] + (b[1]-a[1]) * t)
def gat(p):
    return gopen(p[0], p[1])
bd = MB(); win = MB(); trim = MB()
CELL = {}
def solid_poly(x, y):
    cs = [(x, y), (x+1, y), (x+1, y+1), (x, y+1)]
    gs = [G[y][x], G[y][x+1], G[y+1][x+1], G[y+1][x]]
    pts = []   # (point, is_corner)
    for i in range(4):
        j = (i + 1) % 4
        if gs[i] < 0: pts.append((cs[i], True))
        if (gs[i] < 0) != (gs[j] < 0):
            pts.append((lerp_pt(cs[i], cs[j], gs[i], gs[j]), False))
    return pts
def facing_wall(mb, p, q, z0, z1, mat, s=3.0):
    # make the wall face the open side
    mx, my = (p[0]+q[0])/2, (p[1]+q[1])/2
    nx, ny = -(q[1]-p[1]), (q[0]-p[0]); L = math.hypot(nx, ny) or 1; nx, ny = nx/L, ny/L
    if gopen(mx + nx*0.25, my + ny*0.25) < gopen(mx - nx*0.25, my - ny*0.25):
        p, q = q, p; nx, ny = -nx, -ny
    wall(mb, p[0], p[1], q[0], q[1], z0, z1, mat, s)
    return (nx, ny)
for y in range(H):
    for x in range(W):
        if max(G[y][x], G[y][x+1], G[y+1][x+1], G[y+1][x]) >= 0 and min(G[y][x], G[y][x+1], G[y+1][x+1], G[y+1][x]) >= 0:
            continue
        pts = solid_poly(x, y)
        if len(pts) < 3: continue
        top, base, look = parcel(x, y)
        CELL[(x, y)] = top
        lm = WALL_LOOKS[look]
        P3 = [V(p[0], p[1], top) for p, _ in pts]
        # top face, wound to face up
        area = sum(P3[i][0]*P3[(i+1) % len(P3)][1] - P3[(i+1) % len(P3)][0]*P3[i][1] for i in range(len(P3)))
        if area < 0: P3 = P3[::-1]
        bd.poly(P3, [(v[0]/4, v[1]/4) for v in P3], "roof")
        n = len(pts)
        for i in range(n):
            (p, pc), (q, qc) = pts[i], pts[(i+1) % n]
            if not pc and not qc:
                # contour edge -> street facade
                nx, ny = facing_wall(bd, p, q, -1.5, top, lm)
                L = math.hypot(q[0]-p[0], q[1]-p[1])
                mx, my = (p[0]+q[0])/2 + nx*0.04, (p[1]+q[1])/2 + ny*0.04
                ex, ey = (q[0]-p[0]) / 2, (q[1]-p[1]) / 2
                if L > 0.75 and (x + y) % 2 == 0:
                    f = base + 3.4
                    while f < top - 1.6:
                        k_ = 0.42 / max(L / 2, 0.42)
                        win.quad(V(mx - ex*k_, my - ey*k_, f - 0.7), V(mx + ex*k_, my + ey*k_, f - 0.7),
                                 V(mx + ex*k_, my + ey*k_, f + 0.7), V(mx - ex*k_, my - ey*k_, f + 0.7), [(0,0),(1,0),(1,1),(0,1)], "window")
                        f += 3.0
                    if hsh(x * 3.1, y * 1.7) < 0.07:
                        g0 = elev(mx, my); k2 = 0.55 / max(L / 2, 0.55)
                        win.quad(V(mx - ex*k2, my - ey*k2, g0), V(mx + ex*k2, my + ey*k2, g0),
                                 V(mx + ex*k2, my + ey*k2, g0 + 2.3), V(mx - ex*k2, my - ey*k2, g0 + 2.3), [(0,0),(1,0),(1,1),(0,1)], "door")
                # cornice band sticking out 0.3 m
                a0 = (p[0] + nx*0.3, p[1] + ny*0.3); b0 = (q[0] + nx*0.3, q[1] + ny*0.3)
                facing_wall(trim, a0, b0, top - 0.55, top, "trim", 1.0)
            else:
                # along a cell edge: wall only where the neighbour cell is lower (or open)
                mx, my = (p[0]+q[0])/2, (p[1]+q[1])/2
                if abs(p[0]-q[0]) < 1e-6:
                    nxc, nyc = (x + 1, y) if abs(p[0] - (x+1)) < 1e-6 else (x - 1, y)
                else:
                    nxc, nyc = (x, y + 1) if abs(p[1] - (y+1)) < 1e-6 else (x, y - 1)
                if nxc < 0 or nyc < 0 or nxc >= W or nyc >= H: continue
                ntop = parcel(nxc, nyc)[0]
                if ntop < top - 0.01:
                    # point the wall toward the neighbour cell
                    cx, cy = nxc + .5, nyc + .5
                    nx, ny = -(q[1]-p[1]), (q[0]-p[0])
                    if (cx - mx) * nx + (cy - my) * ny < 0: p, q = q, p
                    wall(bd, p[0], p[1], q[0], q[1], ntop, top, lm)
bld_ob = bd.build("Buildings"); win_ob = win.build("Windows"); trim_ob = trim.build("Cornices")

# ---------------------------------------------------------------- painted zones (exact shapes), roofs
dz = MB()
def flat_poly(mb, pts, z, mat):
    P3 = [V(p[0], p[1], z) for p in pts]
    area = sum(P3[i][0]*P3[(i+1) % len(P3)][1] - P3[(i+1) % len(P3)][0]*P3[i][1] for i in range(len(P3)))
    if area < 0: P3 = P3[::-1]
    mb.poly(P3, [(v[0]/4, v[1]/4) for v in P3], mat)
cA = [sum(p[0] for p in P["siteA"])/4, sum(p[1] for p in P["siteA"])/4]
cB = [sum(p[0] for p in P["siteB"])/4, sum(p[1] for p in P["siteB"])/4]
flat_poly(dz, P["siteA"], elev(*cA) + 0.03, "siteA")
flat_poly(dz, P["siteB"], elev(*cB) + 0.03, "siteB")
for a in P["areas"]:
    if a["kind"] in ("att", "def"):
        c = [sum(p[0] for p in a["pts"])/len(a["pts"]), sum(p[1] for p in a["pts"])/len(a["pts"])]
        flat_poly(dz, a["pts"], elev(*c) + 0.03, a["kind"])
zone_ob = dz.build("Zones")
rf = MB()
# covered passage roof: marching squares on the passage's own field, 4.2 m above the floor
UPL, UR = P["under"][0], P["under"][1] / 2 + 0.6
def upass(px, py): return UR - line_d(px, py, UPL)
for y in range(H):
    for x in range(W):
        cs = [(x, y), (x+1, y), (x+1, y+1), (x, y+1)]
        gs = [upass(*c) for c in cs]
        if max(gs) < 0: continue
        pts = []
        for i2 in range(4):
            j2 = (i2 + 1) % 4
            if gs[i2] >= 0: pts.append(cs[i2])
            if (gs[i2] >= 0) != (gs[j2] >= 0): pts.append(lerp_pt(cs[i2], cs[j2], gs[i2], gs[j2]))
        if len(pts) < 3: continue
        z = elev(x + .5, y + .5) + 4.2
        flat_poly(rf, pts, z, "roof")
        P3 = [V(p[0], p[1], z - 0.25) for p in pts]
        area = sum(P3[k][0]*P3[(k+1) % len(P3)][1] - P3[(k+1) % len(P3)][0]*P3[k][1] for k in range(len(P3)))
        if area > 0: P3 = P3[::-1]
        rf.poly(P3, [(v[0]/4, v[1]/4) for v in P3], "covered_floor")
# market canopy over the hall: exact polygon + 4 pillars
flat_poly(rf, P["hall"], 6.0, "roof")
P3 = [V(p[0], p[1], 5.75) for p in P["hall"]][::-1]
rf.poly(P3, [(v[0]/4, v[1]/4) for v in P3], "covered_floor")
for (hx, hy) in P["hall"]:
    cx = hx + (0.8 if hx < 170 else -0.8); cy = hy + (0.8 if hy < 52 else -0.8)
    for (ax, ay, bx, by) in ((cx-.3, cy-.3, cx+.3, cy-.3), (cx+.3, cy-.3, cx+.3, cy+.3), (cx+.3, cy+.3, cx-.3, cy+.3), (cx-.3, cy+.3, cx-.3, cy-.3)):
        wall(rf, ax, ay, bx, by, 0, 6.0, "wall_stone", 3.0)
roof_ob = rf.build("Roofs")
rl = MB()
for (a, b, w) in P["bridges"]:
    for s in (-1, 1):
        x0, x1 = a[0] + s * w/2, b[0] + s * w/2
        for side in (-0.06, 0.06):
            wall(rl, x0 + side, a[1], x1 + side, b[1], 0.12, 1.1, "rail", 1.0)
            wall(rl, x1 + side, b[1], x0 + side, a[1], 0.12, 1.1, "rail", 1.0)
rail_ob = rl.build("Rails")

# invisible blocker over the canal so nobody walks into the water (Godot: collision only)
cb = MB()
for y in range(H):
    for x in range(W):
        if K[y*W + x] == 3:
            cb.quad(V(x, y+1, 2.5), V(x+1, y+1, 2.5), V(x+1, y, 2.5), V(x, y, 2.5), [(0,0),(1,0),(1,1),(0,1)], "water")
            for (dx, dy, ax, ay, bx, by) in ((1, 0, x+1, y+1, x+1, y), (-1, 0, x, y, x, y+1), (0, 1, x, y+1, x+1, y+1), (0, -1, x+1, y, x, y)):
                if kat(x+dx, y+dy) != 3: wall(cb, ax, ay, bx, by, -1.0, 2.5, "water")
col_ob = cb.build("col_canal")
col_ob.hide_render = True

print("BUILT", len(bld_ob.data.polygons), len(floor_ob.data.polygons), len(win_ob.data.polygons))
