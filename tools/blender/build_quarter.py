# Runs INSIDE Blender (via the blender-mcp addon). Multi-level map builder:
# every 0.5 m column of the map is a stack of solid intervals. Streets/squares
# are open to the sky at their floor height; rooms and tunnels are enclosed gaps
# (so a tunnel can run under a street and a room can sit inside a building);
# everything not opened becomes building mass. Faces are emitted only where a
# column's solid differs from its neighbour's, then merged into long quads.
import bpy, json, math

PLAN = globals().get("PLAN_OVERRIDE", "/home/user/Reborn/game/assets/maps/oldquarter.json")
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
brect = {}
for blk in P["blocks"]:
    bx, by, bw, bd, bh = blk[:5]; bk = blk[5] if len(blk) > 5 else "crate"
    for i, j in cells_in(bx, by, bx + bw, by + bd):
        if floor0[j][i] is None: continue
        brect[(i, j)] = (bx, by, bx + bw, by + bd, floor0[j][i], bh)
        sky[j][i] = max(sky[j][i], floor0[j][i] + bh); skind[j][i] = bk

THEMES = {
    # walls: (texture, tint) x6, floors: street/plaza (texture, tint), height: base, steps of 2 m
    "old": dict(walls=[("T_RedBrick_BaseColor.png", (1, 1, 1, 1)), ("T_Concrete_BaseColor.png", (0.95, 0.88, 0.74, 1)),
                       ("T_RedBrick_BaseColor.png", (0.80, 0.68, 0.60, 1)), ("T_Concrete_BaseColor.png", (0.72, 0.74, 0.78, 1)),
                       ("T_RedBrick_BaseColor.png", (0.62, 0.48, 0.42, 1)), ("T_Trim_BaseColor.png", (1, 1, 1, 1))],
                street=("T_Concrete_Asphalt_BaseColor.png", (0.86, 0.82, 0.76, 1)), plaza=("T_MarbleFloor_BaseColor.png", (0.74, 0.72, 0.68, 1)),
                base=6.0, steps=5, crate=(0.52, 0.38, 0.22, 1)),
    "desert": dict(walls=[("T_Concrete_BaseColor.png", (0.93, 0.80, 0.60, 1)), ("T_Concrete_BaseColor.png", (0.86, 0.70, 0.50, 1)),
                          ("T_Dirt_BaseColor.png", (1.0, 0.86, 0.66, 1)), ("T_Concrete_BaseColor.png", (0.98, 0.90, 0.76, 1)),
                          ("T_RedBrick_BaseColor.png", (0.95, 0.78, 0.60, 1)), ("T_Concrete_BaseColor.png", (0.80, 0.62, 0.46, 1))],
                   street=("T_Dirt_BaseColor.png", (0.92, 0.80, 0.62, 1)), plaza=("T_Concrete_BaseColor.png", (0.90, 0.80, 0.64, 1)),
                   base=4.0, steps=3, crate=(0.50, 0.36, 0.20, 1)),
    "prison": dict(walls=[("T_Concrete_BaseColor.png", (0.70, 0.72, 0.74, 1)), ("T_MetalConcrete_BaseColor.png", (0.80, 0.80, 0.80, 1)),
                          ("T_Concrete_BaseColor.png", (0.62, 0.66, 0.62, 1)), ("T_Concrete_BaseColor.png", (0.80, 0.78, 0.72, 1)),
                          ("T_MetalConcrete_BaseColor.png", (0.66, 0.70, 0.74, 1)), ("T_RedBrick_BaseColor.png", (0.70, 0.66, 0.64, 1))],
                   street=("T_Concrete_Asphalt_BaseColor.png", (0.70, 0.70, 0.70, 1)), plaza=("T_Concrete_BaseColor.png", (0.66, 0.70, 0.66, 1)),
                   base=6.0, steps=2, crate=(0.40, 0.42, 0.44, 1)),
    "harbor": dict(walls=[("T_MetalConcrete_BaseColor.png", (0.80, 0.82, 0.86, 1)), ("T_Concrete_BaseColor.png", (0.68, 0.72, 0.78, 1)),
                          ("T_RedBrick_BaseColor.png", (0.72, 0.62, 0.58, 1)), ("T_MetalConcrete_BaseColor.png", (0.62, 0.66, 0.70, 1)),
                          ("T_Concrete_BaseColor.png", (0.80, 0.78, 0.74, 1)), ("T_Trim_BaseColor.png", (0.9, 0.9, 0.95, 1))],
                   street=("T_Concrete_Asphalt_BaseColor.png", (0.72, 0.74, 0.76, 1)), plaza=("T_Concrete_BaseColor.png", (0.70, 0.72, 0.74, 1)),
                   base=6.0, steps=3, crate=(0.45, 0.33, 0.20, 1)),
    "city": dict(walls=[("T_Trim_BaseColor.png", (1, 1, 1, 1)), ("T_Concrete_BaseColor.png", (0.82, 0.84, 0.88, 1)),
                        ("T_RedBrick_BaseColor.png", (0.85, 0.75, 0.70, 1)), ("T_MetalConcrete_BaseColor.png", (0.78, 0.80, 0.84, 1)),
                        ("T_Concrete_BaseColor.png", (0.92, 0.88, 0.80, 1)), ("T_RedBrick_BaseColor.png", (1, 1, 1, 1))],
                 street=("T_Concrete_Asphalt_BaseColor.png", (0.62, 0.62, 0.64, 1)), plaza=("T_MarbleFloor_BaseColor.png", (0.80, 0.80, 0.80, 1)),
                 base=10.0, steps=7, crate=(0.30, 0.34, 0.38, 1)),
    "lab": dict(walls=[("T_MetalConcrete_BaseColor.png", (0.86, 0.88, 0.90, 1)), ("T_Concrete_BaseColor.png", (0.84, 0.86, 0.88, 1)),
                       ("T_MetalConcrete_BaseColor.png", (0.70, 0.76, 0.80, 1)), ("T_Concrete_BaseColor.png", (0.76, 0.78, 0.74, 1)),
                       ("T_Trim_BaseColor.png", (0.9, 0.92, 0.95, 1)), ("T_Concrete_BaseColor.png", (0.66, 0.68, 0.72, 1))],
                street=("T_Concrete_BaseColor.png", (0.62, 0.64, 0.66, 1)), plaza=("T_MarbleFloor_BaseColor.png", (0.78, 0.80, 0.82, 1)),
                base=6.0, steps=3, crate=(0.36, 0.40, 0.30, 1)),
}
TH = THEMES[P.get("theme", "old")]
DETAIL = {   # ground floor dressing per theme: shop fronts and awnings
    "old": dict(shop="window_lit", awn=["awning_red", "awning_green"]), "desert": dict(shop=None, awn=["awning_red", "awning_blue", "awning_green"]),
    "prison": dict(shop="shutter", awn=[]), "harbor": dict(shop="shutter", awn=[]),
    "city": dict(shop="window_lit", awn=["awning_green", "awning_blue"]), "lab": dict(shop="shutter", awn=[]),
}[P.get("theme", "old")]
MT = "/home/user/Reborn/game/assets/maps/tex/"
def parcel_top(i, j):
    pi, pj = int(i * S // 6), int(j * S // 6)
    return TH["base"] + int(hsh(pi, pj) * TH["steps"]) * 2.0 + (2.0 if hsh(pi + 9, pj + 1) > 0.88 else 0.0)
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
def mat_tex(name, img, tint=(1, 1, 1, 1), rough=0.9, alpha=False):
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree; bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = rough
    if img:
        tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = bpy.data.images.load(img if img.startswith("/") else TEX + img, check_existing=True)
        if alpha:
            nt.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"]); m.blend_method = "BLEND"; m.shadow_method = "NONE"
        mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.blend_type = "MULTIPLY"
        mix.inputs[0].default_value = 1.0
        nt.links.new(tex.outputs["Color"], mix.inputs[6]); mix.inputs[7].default_value = tint
        nt.links.new(mix.outputs[2], bsdf.inputs["Base Color"])
    else:
        bsdf.inputs["Base Color"].default_value = tint
    return m
MATS = [
    mat_tex("cobble", *TH["street"]),
    mat_tex("plaza", *TH["plaza"]),
    mat_tex("stairs", "T_Concrete_BaseColor.png", (0.80, 0.78, 0.74, 1)),
    mat_tex("room_floor", "T_MarbleFloor_BaseColor.png", (0.70, 0.66, 0.60, 1)),
    mat_tex("ceiling", "T_Concrete_BaseColor.png", (0.55, 0.55, 0.56, 1)),
    mat_tex("tunnel", "T_Concrete_BaseColor.png", (0.52, 0.54, 0.58, 1)),
    mat_tex("att", "T_Concrete_BaseColor.png", (0.95, 0.62, 0.55, 1)),
    mat_tex("def", "T_Concrete_BaseColor.png", (0.58, 0.74, 0.95, 1)),
    mat_tex("siteA", "T_MarbleFloor_BaseColor.png", (0.80, 0.56, 0.36, 1)),
    mat_tex("siteB", "T_MarbleFloor_BaseColor.png", (0.80, 0.68, 0.42, 1)),
    mat_tex("crate", MT + "crate.png", tuple(min(1.0, c * 1.92) for c in TH["crate"][:3]) + (1,)),
    mat_tex("cont0", MT + "container.png", (0.72, 0.24, 0.17, 1), 0.7),
    mat_tex("cont1", MT + "container.png", (0.20, 0.40, 0.66, 1), 0.7),
    mat_tex("cont2", MT + "container.png", (0.24, 0.52, 0.30, 1), 0.7),
    mat_tex("cont3", MT + "container.png", (0.84, 0.60, 0.16, 1), 0.7),
    mat_tex("water", "T_Concrete_BaseColor.png", (0.20, 0.34, 0.42, 1), 0.15),
    mat_tex("ledge", "T_Concrete_BaseColor.png", (0.74, 0.74, 0.76, 1)),
    mat_tex("wall0", *TH["walls"][0]),
    mat_tex("wall1", *TH["walls"][1]),
    mat_tex("wall2", *TH["walls"][2]),
    mat_tex("wall3", *TH["walls"][3]),
    mat_tex("wall4", *TH["walls"][4]),
    mat_tex("wall5", *TH["walls"][5]),
    mat_tex("roof", "T_Concrete_BaseColor.png", (0.40, 0.40, 0.42, 1)),
    mat_tex("window", "T_dark_interior.png", (0.75, 0.80, 0.90, 1), 0.25),
    mat_tex("trim", "T_Trim_BaseColor.png"),
    mat_tex("window_lit", "T_lit_interior_1.png", (1, 1, 1, 1), 0.25),
    mat_tex("door", MT + "door.png"),
    mat_tex("shutter", MT + "shutter.png"),
    mat_tex("ao", MT + "ao.png", (1, 1, 1, 1), 1.0, True),
    mat_tex("plinth", "T_Concrete_BaseColor.png", (0.48, 0.47, 0.46, 1)),
    mat_tex("frame", None, (0.20, 0.20, 0.22, 1)),
    mat_tex("sill", "T_Concrete_BaseColor.png", (0.88, 0.87, 0.84, 1)),
    mat_tex("acunit", "T_MetalConcrete_BaseColor.png", (0.80, 0.82, 0.85, 1), 0.5),
    mat_tex("awning_red", MT + "awning_red.png"),
    mat_tex("awning_green", MT + "awning_green.png"),
    mat_tex("awning_blue", MT + "awning_blue.png"),
]
MI = {m.name: i for i, m in enumerate(MATS)}
FLOOR = {"street": "cobble", "plaza": "plaza", "stairs": "stairs", "room": "room_floor", "tunnel": "tunnel",
         "att": "att", "def": "def", "siteA": "siteA", "siteB": "siteB", "crate": "crate",
         "cont0": "cont0", "cont1": "cont1", "cont2": "cont2", "cont3": "cont3", "water": "water", "barrier": "ledge"}

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
            if (mat == "crate" or mat.startswith("cont")) and (i0, j) in brect:
                bx0, by0, bx1, by1 = brect[(i0, j)][:4]
                U = lambda x: (x - bx0) / (bx1 - bx0); Vv = lambda y: (y - by0) / (by1 - by0)
                uv = [(U(x0), Vv(y0)), (U(x1), Vv(y0)), (U(x1), Vv(y1)), (U(x0), Vv(y1))]
            mb.quad(V(x0, y0, z), V(x1, y0, z), V(x1, y1, z), V(x0, y1, z), uv, mat, (0, 0, 1 if up == "t" else -1))
        for key in keys:
            if key not in runs: runs[key] = i

# ---------------------------------------------------------------- vertical faces between neighbouring columns, merged along the edge
def side_mat(i, j, z0, z1):
    if sky[j][i] is not None and z1 <= sky[j][i] + 1e-6:
        k = skind[j][i]
        return k if (k == "crate" or k == "stairs" or (k or "").startswith("cont")) else "ledge"
    if any(k == "tunnel" for _, _, k in encl[j][i]) and z1 <= 0.01:
        return "tunnel"
    return "wall%d" % parcel_look(i, j)
win = MB(); det = MB(); aos = MB(); nwin = 0
OPEN = ("street", "plaza", "att", "def", "siteA", "siteB")
def wpt(axis, c, fd, al, out, z):
    return V(c + out * fd, al, z) if axis == "x" else V(al, c + out * fd, z)
def wquad(m, axis, c, fd, s0, s1, out, z0, z1, mat, nrm, uv=None):
    m.quad(wpt(axis, c, fd, s0, out, z0), wpt(axis, c, fd, s1, out, z0), wpt(axis, c, fd, s1, out, z1), wpt(axis, c, fd, s0, out, z1),
           uv or [(0, 0), (1, 0), (1, 1), (0, 1)], mat, nrm)
def hquad(m, axis, c, fd, s0, s1, o0, o1, z, mat, up, uv=None):
    m.quad(wpt(axis, c, fd, s0, o0, z), wpt(axis, c, fd, s1, o0, z), wpt(axis, c, fd, s1, o1, z), wpt(axis, c, fd, s0, o1, z),
           uv or [(0, 0), (1, 0), (1, 1), (0, 1)], mat, (0, 0, 1 if up else -1))
def slab(m, axis, c, fd, s0, s1, o0, o1, z0, z1, mat, nrm, uv=None, back=False, bottom=True):
    """a box standing out of the wall between o0 and o1 (metres in front of it)."""
    aw = (0, -1, 0) if axis == "x" else (1, 0, 0)
    wquad(m, axis, c, fd, s0, s1, o1, z0, z1, mat, nrm, uv)
    hquad(m, axis, c, fd, s0, s1, o0, o1, z1, mat, True)
    if bottom: hquad(m, axis, c, fd, s0, s1, o0, o1, z0, mat, False)
    if back: wquad(m, axis, c, fd, s0, s1, o0, z0, z1, mat, tuple(-v for v in nrm), uv)
    for sx, sg in ((s0, -1), (s1, 1)):
        m.quad(wpt(axis, c, fd, sx, o0, z0), wpt(axis, c, fd, sx, o1, z0), wpt(axis, c, fd, sx, o1, z1), wpt(axis, c, fd, sx, o0, z1),
               [(0, 0), (1, 0), (1, 1), (0, 1)], mat, tuple(sg * v for v in aw))
def side_mat(i, j, z0, z1):
    if sky[j][i] is not None and z1 <= sky[j][i] + 1e-6:
        k = skind[j][i]
        return k if (k == "crate" or k == "stairs" or (k or "").startswith("cont")) else "ledge"
    if any(k == "tunnel" for _, _, k in encl[j][i]) and z1 <= 0.01:
        return "tunnel"
    return "wall%d" % parcel_look(i, j)
def emit_wall(axis, e, k0, k1, fd, z0, z1, mat, nf, nk, roof):
    global nwin
    c = e * S; a0, a1 = k0 * S, k1 * S; L = a1 - a0
    nrm = (fd, 0, 0) if axis == "x" else (0, -fd, 0)
    uv = [(a0 / 3, z0 / 3), (a1 / 3, z0 / 3), (a1 / 3, z1 / 3), (a0 / 3, z1 / 3)]
    if mat == "crate" or mat.startswith("cont"):
        own = ((e - 1 if fd == 1 else e), k0) if axis == "x" else (k0, (e - 1 if fd == 1 else e))
        if own in brect:
            bx0, by0, bx1, by1, base, bh = brect[own]
            s0, s1 = (by0, by1) if axis == "x" else (bx0, bx1)
            rep = 2.6 if mat.startswith("cont") else (s1 - s0)
            vh = 2.6 if mat.startswith("cont") else 1.1
            uv = [((a0 - s0) / rep, (z0 - base) / vh), ((a1 - s0) / rep, (z0 - base) / vh), ((a1 - s0) / rep, (z1 - base) / vh), ((a0 - s0) / rep, (z1 - base) / vh)]
    wquad(mb, axis, c, fd, a0, a1, 0.0, z0, z1, mat, nrm, uv)
    grounded = nf is not None and abs(z0 - nf) < 0.02 and nk != "stairs"
    if grounded and nk != "water":
        depth = 0.9 if mat.startswith("wall") else 0.55
        hquad(aos, axis, c, fd, a0, a1, 0.0, depth, nf + 0.015, "ao", True, [(0, 1), (L, 1), (L, 0), (0, 0)])
    if not mat.startswith("wall") or nf is None:
        return
    look = int(mat[4:])
    if grounded:
        slab(det, axis, c, fd, a0, a1, 0.0, 0.06, z0, z0 + 0.55, "plinth", nrm, bottom=False)
    # doors / shop fronts / awnings on walls along open ground
    if grounded and z1 - z0 >= 3.0 and nk in OPEN and L >= 2.5:
        nd = max(1, int(L // 9.0))
        for q in range(nd):
            if hsh(e * 1.31 + q * 3.1, k0 * 0.71 + fd * 0.37) > (0.6 if L < 6 else 0.85): continue
            span = L / nd
            mid = a0 + span * (q + 0.5) + (hsh(q + 0.5, e * 0.9) - 0.5) * max(0.0, span - 3.4)
            shop = DETAIL["shop"] and span >= 4.0 and hsh(e * 0.37, q + k0 * 0.13) > 0.5
            w = 2.6 if shop else 1.3
            zt = z0 + (2.4 if shop else 2.3); zb = z0 + (0.5 if shop else 0.0)
            wquad(det, axis, c, fd, mid - w / 2 - 0.14, mid + w / 2 + 0.14, 0.075, zb - (0.1 if shop else 0.0), zt + 0.14, "frame", nrm)
            wquad(det, axis, c, fd, mid - w / 2, mid + w / 2, 0.09, zb, zt, DETAIL["shop"] if shop else "door", nrm)
            if DETAIL["awn"] and hsh(mid * 0.21, e * 0.53) > 0.35:
                am = DETAIL["awn"][int(hsh(mid, e) * len(DETAIL["awn"])) % len(DETAIL["awn"])]
                p0, p1 = mid - w / 2 - 0.35, mid + w / 2 + 0.35
                for up in (True, False):
                    pts = [wpt(axis, c, fd, p0, 0.0, zt + 0.45), wpt(axis, c, fd, p1, 0.0, zt + 0.45), wpt(axis, c, fd, p1, 1.15, zt + 0.1), wpt(axis, c, fd, p0, 1.15, zt + 0.1)]
                    n = tuple(0.3 * v for v in nrm[:2]) + (1.0 if up else -1.0,)
                    det.quad(*pts, [(0, 1), (1, 1), (1, 0), (0, 0)], am, n if up else tuple(-v for v in nrm[:2]) + (-1.0,))
    # floor bands on some looks
    if look in (1, 3) and grounded:
        zz = nf + 3.1
        while zz < z1 - 1.0:
            slab(det, axis, c, fd, a0, a1, 0.0, 0.05, zz, zz + 0.14, "sill", nrm); zz += 3.2
    # windows with frame and sill; some lit
    zb = (nf if nf > z0 else z0) + 3.4
    while zb + 1.7 <= z1 - 0.6:
        n = int((L - 1.0) // 3.0)
        for q in range(max(0, n)):
            s0 = a0 + (L - n * 3.0) / 2 + q * 3.0 + 0.9; s1 = s0 + 1.2
            lit = hsh(s0 * 0.37 + zb, e * 0.11 + fd) > 0.8
            wquad(win, axis, c, fd, s0 - 0.12, s1 + 0.12, 0.03, zb - 0.12, zb + 1.72, "frame", nrm)
            wquad(win, axis, c, fd, s0, s1, 0.045, zb, zb + 1.6, "window_lit" if lit else "window", nrm)
            slab(win, axis, c, fd, s0 - 0.18, s1 + 0.18, 0.0, 0.14, zb - 0.22, zb - 0.1, "sill", nrm)
            nwin += 1
        zb += 3.2
    # cornice + parapet on the roof edge
    if roof:
        slab(det, axis, c, fd, a0, a1, 0.0, 0.2, z1 - 0.35, z1 - 0.05, "sill", nrm)
        slab(det, axis, c, fd, a0, a1, -0.25, 0.08, z1 - 0.05, z1 + 0.5, mat, nrm,
             [(a0 / 3, 0), (a1 / 3, 0), (a1 / 3, 0.18), (a0 / 3, 0.18)], back=True, bottom=False)
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
                    nf = sky[nj][ni]; nk = skind[nj][ni] if nf is not None else None
                    own = solid_of(ci, cj)
                    for z0, z1 in minus(own, solid_of(ni, nj)):
                        roof = sky[cj][ci] is None and abs(z1 - own[-1][1]) < 1e-6
                        keys.add((fd, z0, z1, side_mat(ci, cj, z0, z1), nf, nk, roof))
            for key in list(runs.keys()):
                if key in keys: continue
                k0 = runs.pop(key)
                emit_wall(axis, e, k0, k, *key)
            for key in keys:
                if key not in runs: runs[key] = k

# roof dressing: AC units and water tanks on some roofs (seen from the high spots)
def box(m, x0, y0, x1, y1, z0, z1, mat):
    m.quad(V(x0, y0, z1), V(x1, y0, z1), V(x1, y1, z1), V(x0, y1, z1), [(0, 0), (1, 0), (1, 1), (0, 1)], mat, (0, 0, 1))
    for (ax, ay, bx, by, n) in ((x0, y0, x1, y0, (0, 1, 0)), (x1, y1, x0, y1, (0, -1, 0)), (x0, y1, x0, y0, (-1, 0, 0)), (x1, y0, x1, y1, (1, 0, 0))):
        m.quad(V(ax, ay, z0), V(bx, by, z0), V(bx, by, z1), V(ax, ay, z1), [(0, 0), (1, 0), (1, 1), (0, 1)], mat, n)
def tank(m, cx, cy, z0, r, h, mat):
    nseg = 8
    pts = [(cx + r * math.cos(2 * math.pi * q / nseg), cy + r * math.sin(2 * math.pi * q / nseg)) for q in range(nseg)]
    for q in range(nseg):
        (ax, ay), (bx, by) = pts[q], pts[(q + 1) % nseg]
        mx, my = (ax + bx) / 2 - cx, -((ay + by) / 2 - cy)
        m.quad(V(ax, ay, z0), V(bx, by, z0), V(bx, by, z0 + h), V(ax, ay, z0 + h), [(q / 8, 0), ((q + 1) / 8, 0), ((q + 1) / 8, 1), (q / 8, 1)], mat, (mx, my, 0))
        m.quad(V(cx, cy, z0 + h), V(ax, ay, z0 + h), V(bx, by, z0 + h), V(cx, cy, z0 + h), [(0.5, 0.5), (0, 0), (1, 0), (0.5, 0.5)], mat, (0, 0, 1))
nprops = 0
for pj in range(int(H // 6) + 1):
    for pi in range(int(W // 6) + 1):
        hh = hsh(pi * 1.3 + 5.0, pj * 2.1 + 3.0)
        if hh < 0.4: continue
        cx = pi * 6 + 1.6 + hsh(pi, pj + 11) * 2.8; cy = pj * 6 + 1.6 + hsh(pi + 7, pj) * 2.8
        cells = [(i, j) for j in range(int((cy - 1.2) / S), int((cy + 1.2) / S) + 1) for i in range(int((cx - 1.2) / S), int((cx + 1.2) / S) + 1)]
        if any(not (0 <= i < NX and 0 <= j < NY) or sky[j][i] is not None or encl[j][i] for i, j in cells): continue
        tops = {solid_of(i, j)[-1][1] for i, j in cells}
        if len(tops) != 1: continue
        top = tops.pop()
        if hh > 0.82 and P.get("theme", "old") in ("old", "desert", "harbor"):
            tank(det, cx, cy, top, 0.75, 1.5, "acunit")
        else:
            box(det, cx - 0.7, cy - 0.45, cx + 0.7, cy + 0.45, top, top + 0.9, "acunit")
        nprops += 1

# outer skirt: the map border columns face outward too (seen from high ground)
ob = mb.build("Quarter")
if win.v: win.build("Windows")
if det.v: det.build("Detail")
if aos.v: aos.build("Shadows")
if steps.v: steps.build("Steps")   # visual only: Godot walks on smooth ramp colliders
print("faces", len(mb.f), "windows", nwin, "detail", len(det.f), "shadow", len(aos.f), "roofprops", nprops)
