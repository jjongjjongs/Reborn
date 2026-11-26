# Runs INSIDE Blender (via the blender-mcp addon). Multi-level map builder:
# every 0.5 m column of the map is a stack of solid intervals. Streets/squares
# are open to the sky at their floor height; rooms and tunnels are enclosed gaps
# (so a tunnel can run under a street and a room can sit inside a building);
# everything not opened becomes building mass. Faces are emitted only where a
# column's solid differs from its neighbour's, then merged into long quads.
import bpy, json, math

PLAN = "/home/user/Reborn/game/assets/maps/oldquarter.json"
TEX = "/home/user/Reborn/game/assets/city/tex/"
OUT_NAME = "oldquarter"
P = json.load(open(PLAN))
W, H = P["W"], P["H"]
S = 0.5
NX, NY = int(W / S), int(H / S)
BOTTOM = -6.0

for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
for m in list(bpy.data.meshes): bpy.data.meshes.remove(m)
for m in list(bpy.data.materials): bpy.data.materials.remove(m)

def hsh(a, b):
    s = math.sin(a * 127.1 + b * 311.7) * 43758.5453
    return s - math.floor(s)

# ---------------------------------------------------------------- columns
sky = [[None] * NX for _ in range(NY)]       # sky-open floor height (or None)
skind = [[None] * NX for _ in range(NY)]     # what kind of open space (material)
encl = [[[] for _ in range(NX)] for _ in range(NY)]   # enclosed gaps (floor, ceil, kind)
def cells_in(x0, y0, x1, y1):
    i0, i1 = int(round(x0 / S)), int(round(x1 / S)); j0, j1 = int(round(y0 / S)), int(round(y1 / S))
    for j in range(max(0, j0), min(NY, j1)):
        for i in range(max(0, i0), min(NX, i1)):
            yield i, j
for k, x0, y0, x1, y1, fl, ce in P["spaces"]:
    for i, j in cells_in(x0, y0, x1, y1):
        if ce is None:
            sky[j][i] = fl; skind[j][i] = k
        else:
            encl[j][i].append((fl, ce, k))
for x0, y0, x1, y1, zl, zh, d, ce in P["ramps"]:
    for i, j in cells_in(x0, y0, x1, y1):
        cx, cy = (i + .5) * S, (j + .5) * S
        t = {"e": (cx - x0) / (x1 - x0), "w": (x1 - cx) / (x1 - x0), "s": (cy - y0) / (y1 - y0), "n": (y1 - cy) / (y1 - y0)}[d]
        z = round((zl + (zh - zl) * t) / 0.1) * 0.1
        if ce is None:
            sky[j][i] = z; skind[j][i] = "stairs"
        else:
            encl[j][i].append((z, z + ce, "stairs"))
floor0 = [row[:] for row in sky]
for bx, by, bw, bd, bh in P["blocks"]:
    for i, j in cells_in(bx, by, bx + bw, by + bd):
        if floor0[j][i] is None: continue
        sky[j][i] = max(sky[j][i], floor0[j][i] + bh); skind[j][i] = "crate"

def parcel_top(i, j):
    pi, pj = int(i * S // 6), int(j * S // 6)
    return 6.0 + int(hsh(pi, pj) * 5) * 2.0 + (2.0 if hsh(pi + 9, pj + 1) > 0.88 else 0.0)
def parcel_look(i, j):
    return int(hsh(int(i * S // 6) + 3, int(j * S // 6) + 7) * 6)

SOLID = [[None] * NX for _ in range(NY)]
def solid_of(i, j):
    if SOLID[j][i] is not None: return SOLID[j][i]
    top = sky[j][i] if sky[j][i] is not None else parcel_top(i, j)
    if sky[j][i] is None and encl[j][i]:
        top = max(top, max(c for _, c, _ in encl[j][i]) + 2.0)
    iv = [(BOTTOM, top)]
    for fl, ce, _ in encl[j][i]:
        nv = []
        for a, b in iv:
            if ce <= a or fl >= b: nv.append((a, b)); continue
            if a < fl: nv.append((a, fl))
            if ce < b: nv.append((ce, b))
        iv = nv
    SOLID[j][i] = iv
    return iv
def minus(A, B):
    out = []
    for a, b in A:
        segs = [(a, b)]
        for c, d in B:
            ns = []
            for x, y in segs:
                if d <= x or c >= y: ns.append((x, y)); continue
                if x < c: ns.append((x, c))
                if d < y: ns.append((d, y))
            segs = ns
        out += [s for s in segs if s[1] - s[0] > 0.01]
    return out

# ---------------------------------------------------------------- materials
def mat_tex(name, img, tint=(1, 1, 1, 1), rough=0.9):
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree; bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = rough
    if img:
        tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = bpy.data.images.load(TEX + img, check_existing=True)
        mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.blend_type = "MULTIPLY"
        mix.inputs[0].default_value = 1.0
        nt.links.new(tex.outputs["Color"], mix.inputs[6]); mix.inputs[7].default_value = tint
        nt.links.new(mix.outputs[2], bsdf.inputs["Base Color"])
    else:
        bsdf.inputs["Base Color"].default_value = tint
    return m
MATS = [
    mat_tex("cobble", "T_Concrete_Asphalt_BaseColor.png", (0.86, 0.82, 0.76, 1)),
    mat_tex("plaza", "T_MarbleFloor_BaseColor.png", (0.74, 0.72, 0.68, 1)),
    mat_tex("stairs", "T_Concrete_BaseColor.png", (0.80, 0.78, 0.74, 1)),
    mat_tex("room_floor", "T_MarbleFloor_BaseColor.png", (0.70, 0.66, 0.60, 1)),
    mat_tex("ceiling", "T_Concrete_BaseColor.png", (0.55, 0.55, 0.56, 1)),
    mat_tex("tunnel", "T_Concrete_BaseColor.png", (0.52, 0.54, 0.58, 1)),
    mat_tex("att", "T_Concrete_BaseColor.png", (0.95, 0.62, 0.55, 1)),
    mat_tex("def", "T_Concrete_BaseColor.png", (0.58, 0.74, 0.95, 1)),
    mat_tex("siteA", "T_MarbleFloor_BaseColor.png", (0.80, 0.56, 0.36, 1)),
    mat_tex("siteB", "T_MarbleFloor_BaseColor.png", (0.80, 0.68, 0.42, 1)),
    mat_tex("crate", None, (0.52, 0.38, 0.22, 1)),
    mat_tex("ledge", "T_Concrete_BaseColor.png", (0.74, 0.74, 0.76, 1)),
    mat_tex("wall0", "T_RedBrick_BaseColor.png"),
    mat_tex("wall1", "T_Concrete_BaseColor.png", (0.95, 0.88, 0.74, 1)),
    mat_tex("wall2", "T_RedBrick_BaseColor.png", (0.80, 0.68, 0.60, 1)),
    mat_tex("wall3", "T_Concrete_BaseColor.png", (0.72, 0.74, 0.78, 1)),
    mat_tex("wall4", "T_RedBrick_BaseColor.png", (0.62, 0.48, 0.42, 1)),
    mat_tex("wall5", "T_Trim_BaseColor.png"),
    mat_tex("roof", "T_Concrete_BaseColor.png", (0.40, 0.40, 0.42, 1)),
    mat_tex("window", "T_dark_interior.png", (0.75, 0.80, 0.90, 1), 0.25),
    mat_tex("trim", "T_Trim_BaseColor.png"),
]
MI = {m.name: i for i, m in enumerate(MATS)}
FLOOR = {"street": "cobble", "plaza": "plaza", "stairs": "stairs", "room": "room_floor", "tunnel": "tunnel",
         "att": "att", "def": "def", "siteA": "siteA", "siteB": "siteB", "crate": "crate"}

class MB:
    def __init__(self): self.v = []; self.f = []; self.uv = []; self.m = []
    def quad(self, a, b, c, d, uvs, mat, nrm=None):
        if nrm is not None:
            u = [b[k] - a[k] for k in range(3)]; w = [c[k] - a[k] for k in range(3)]
            cr = (u[1]*w[2]-u[2]*w[1], u[2]*w[0]-u[0]*w[2], u[0]*w[1]-u[1]*w[0])
            if sum(cr[k] * nrm[k] for k in range(3)) < 0:
                a, b, c, d = d, c, b, a; uvs = [uvs[3], uvs[2], uvs[1], uvs[0]]
        if mat == "stairs" and getattr(self, "alt", None) is not None:
            return self.alt.quad(a, b, c, d, uvs, mat)
        n = len(self.v); self.v += [a, b, c, d]; self.f.append((n, n+1, n+2, n+3)); self.uv.append(uvs); self.m.append(MI[mat])
    def build(self, name):
        me = bpy.data.meshes.new(name); me.from_pydata(self.v, [], self.f)
        for mt in MATS: me.materials.append(mt)
        uvl = me.uv_layers.new(name="UVMap")
        for fi, poly in enumerate(me.polygons):
            poly.material_index = self.m[fi]
            for k, li in enumerate(poly.loop_indices): uvl.data[li].uv = self.uv[fi][k]
        me.validate(); me.update()
        ob = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob)
        return ob
def V(x, y, z): return (x - W / 2, -(y - H / 2), z)


# ---------------------------------------------------------------- horizontal faces, merged along rows
mb = MB(); steps = MB(); mb.alt = steps
def top_mat(i, j, z):
    if sky[j][i] is not None and abs(z - sky[j][i]) < 1e-6:
        return FLOOR.get(skind[j][i], "cobble")
    for fl, ce, k in encl[j][i]:
        if abs(z - fl) < 1e-6: return FLOOR.get(k, "room_floor")
    return "roof"
for j in range(NY):
    runs = {}
    for i in range(NX + 1):
        keys = set()
        if i < NX:
            tun = any(k == "tunnel" for _, _, k in encl[j][i])
            for a, b in solid_of(i, j):
                keys.add(("t", b, top_mat(i, j, b)))
                if a > BOTTOM + 0.01: keys.add(("b", a, "tunnel" if tun else "ceiling"))
        for key in list(runs.keys()):
            if key in keys: continue
            i0 = runs.pop(key); up, z, mat = key
            x0, x1, y0, y1 = i0 * S, i * S, j * S, (j + 1) * S
            uv = [(x0 / 4, y0 / 4), (x1 / 4, y0 / 4), (x1 / 4, y1 / 4), (x0 / 4, y1 / 4)]
            mb.quad(V(x0, y0, z), V(x1, y0, z), V(x1, y1, z), V(x0, y1, z), uv, mat, (0, 0, 1 if up == "t" else -1))
        for key in keys:
            if key not in runs: runs[key] = i

# ---------------------------------------------------------------- vertical faces between neighbouring columns, merged along the edge
def side_mat(i, j, z0, z1):
    if sky[j][i] is not None and z1 <= sky[j][i] + 1e-6:
        return {"crate": "crate", "stairs": "stairs"}.get(skind[j][i], "ledge")
    if any(k == "tunnel" for _, _, k in encl[j][i]) and z1 <= 0.01:
        return "tunnel"
    return "wall%d" % parcel_look(i, j)
win = MB(); nwin = 0
def emit_wall(axis, e, k0, k1, fd, z0, z1, mat, nfloor):
    global nwin
    c = e * S; a0, a1 = k0 * S, k1 * S
    if axis == "x":
        P0, P1 = (c, a0), (c, a1); nrm = (fd, 0, 0)      # world x == map x
    else:
        P0, P1 = (a0, c), (a1, c); nrm = (0, -fd, 0)     # world y == -map y
    L = a1 - a0
    uv = [(0, z0 / 3), (L / 3, z0 / 3), (L / 3, z1 / 3), (0, z1 / 3)]
    mb.quad(V(P0[0], P0[1], z0), V(P1[0], P1[1], z0), V(P1[0], P1[1], z1), V(P0[0], P0[1], z1), uv, mat, nrm)
    if mat.startswith("wall") and nfloor is not None:
        off = 0.04 * fd
        zb = max(z0, nfloor) + 3.4
        while zb + 1.7 <= z1 - 0.6:
            n = int((L - 1.0) // 3.0)
            for q in range(max(0, n)):
                s0 = a0 + (L - n * 3.0) / 2 + q * 3.0 + 0.9
                s1 = s0 + 1.2
                if axis == "x": A, B = (c + off, s0), (c + off, s1)
                else: A, B = (s0, c - off), (s1, c - off)
                win.quad(V(A[0], A[1], zb), V(B[0], B[1], zb), V(B[0], B[1], zb + 1.6), V(A[0], A[1], zb + 1.6),
                         [(0, 0), (1, 0), (1, 1), (0, 1)], "window", nrm); nwin += 1
            zb += 3.2
for axis in ("x", "y"):
    E = NX if axis == "x" else NY        # interior edges 1..E-1
    K = NY if axis == "x" else NX        # run direction length
    for e in range(1, E):
        runs = {}
        for k in range(K + 1):
            keys = set()
            if k < K:
                A = (e - 1, k) if axis == "x" else (k, e - 1)
                B = (e, k) if axis == "x" else (k, e)
                for (ci, cj), (ni, nj), fd in ((A, B, 1), (B, A, -1)):
                    nf = sky[nj][ni]
                    for z0, z1 in minus(solid_of(ci, cj), solid_of(ni, nj)):
                        keys.add((fd, z0, z1, side_mat(ci, cj, z0, z1), nf if (nf is not None and z1 > nf + 5) else None))
            for key in list(runs.keys()):
                if key in keys: continue
                k0 = runs.pop(key); fd, z0, z1, mat, nfl = key
                emit_wall(axis, e, k0, k, fd, z0, z1, mat, nfl)
            for key in keys:
                if key not in runs: runs[key] = k

# outer skirt: the map border columns face outward too (seen from high ground)
ob = mb.build("Quarter")
if win.v: win.build("Windows")
if steps.v: steps.build("Steps")   # visual only: Godot walks on smooth ramp colliders
print("faces", len(mb.f), "windows", nwin)
