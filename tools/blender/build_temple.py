# 산사 (mountain temple) bomb map in Blender: terrain from maps/temple_height.py, curved stone terrace
# walls, pond + stream, stone stairs, cave tunnel, hanok buildings (build_hanok.py), 경회루 on the pond,
# pagoda, lanterns, bridges, pines / bamboo / rocks.  blender -b --python build_temple.py -> /tmp/gbg/temple.blend
import bpy, bmesh, math, random, sys, os
import numpy as np
from mathutils import Vector, Matrix, noise
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "maps"))
from temple_layout import *
random.seed(11)
bpy.ops.wm.read_factory_settings(use_empty=True)
SC = bpy.context.scene
D = np.load("/tmp/gbg/temple_hm.npz"); HM = D["h"]; KIND = D["kind"]; RES = float(D["res"]); MG = float(D["margin"])
NY, NX = HM.shape
def B(x, y): return Vector((x - 70.0, 60.0 - y, 0.0))            # plan -> Blender
def hat(x, y):                                                     # terrain height at a plan point (bilinear)
    gx = (x + MG) * RES; gy = (y + MG) * RES
    i = int(min(max(gx, 0), NX - 2)); j = int(min(max(gy, 0), NY - 2)); fx = gx - i; fy = gy - j
    return float(HM[j, i] * (1 - fx) * (1 - fy) + HM[j, i + 1] * fx * (1 - fy) + HM[j + 1, i] * (1 - fx) * fy + HM[j + 1, i + 1] * fx * fy)
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
MATS = {}
def mat(n, rgb, r=0.8, m=0.0, vcol=False, alpha=1.0):
    if n in bpy.data.materials: return bpy.data.materials[n]
    x = bpy.data.materials.new(n); x.use_nodes = True; b = x.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (lin(rgb[0]), lin(rgb[1]), lin(rgb[2]), 1); b.inputs["Roughness"].default_value = r; b.inputs["Metallic"].default_value = m
    if vcol:
        a = x.node_tree.nodes.new("ShaderNodeVertexColor"); a.layer_name = "Col"
        x.node_tree.links.new(a.outputs[0], b.inputs["Base Color"])
    if alpha < 1.0:
        b.inputs["Alpha"].default_value = alpha; x.blend_method = "BLEND"
    return x
GROUND = mat("T_Ground", (1, 1, 1), 0.95, vcol=True)
WALLM = mat("T_Wall", (1, 1, 1), 0.9, vcol=True)
STONEM = mat("T_Stone", (0.50, 0.48, 0.44), 0.85); STEPM = mat("T_Step", (0.55, 0.53, 0.49), 0.85)
WATER = mat("T_Water", (0.22, 0.42, 0.50), 0.05, 0.0, alpha=0.85)
ROCKM = mat("T_Rock", (0.45, 0.44, 0.41), 0.95); BARK = mat("T_Bark", (0.36, 0.24, 0.16), 0.9)
PINE = mat("T_Pine", (0.16, 0.30, 0.17), 0.85); PINE2 = mat("T_Pine2", (0.20, 0.36, 0.19), 0.85)
BAMBOO = mat("T_Bamboo", (0.45, 0.62, 0.30), 0.6); BAMLEAF = mat("T_BamLeaf", (0.30, 0.52, 0.22), 0.8)
BRONZE = mat("T_Bronze", (0.35, 0.30, 0.18), 0.35, 0.8)
def link(o): SC.collection.objects.link(o); return o
def mesh_obj(name, verts, faces, m, cols=None, smooth=False):
    me = bpy.data.meshes.new(name); me.from_pydata(verts, [], faces); me.update()
    if cols is not None:
        ca = me.color_attributes.new("Col", "BYTE_COLOR", "POINT")
        for i, c in enumerate(cols): ca.data[i].color = (c[0], c[1], c[2], 1.0)
    for p in me.polygons: p.use_smooth = smooth
    o = bpy.data.objects.new(name, me); o.data.materials.append(m); return link(o)
def box(c, s, m, rot=0.0, bev=0.0, name="Stone"):
    bpy.ops.mesh.primitive_cube_add(size=1, location=c, rotation=(0, 0, rot)); o = bpy.context.active_object; o.name = name; o.scale = s
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    if bev:
        md = o.modifiers.new("b", "BEVEL"); md.width = min(bev, min(s) * 0.45); md.segments = 2; bpy.ops.object.modifier_apply(modifier="b")
    o.data.materials.append(m); return o
# ---------------------------------------------------------------- terrain
print("terrain")
colmap = {0: (0.36, 0.33, 0.24), 1: (0.45, 0.42, 0.34), 2: (0.40, 0.37, 0.31), 3: (0.20, 0.22, 0.19), 4: (0.16, 0.24, 0.13), 5: (0.26, 0.24, 0.21), 6: (0.24, 0.25, 0.22)}
verts = []; cols = []
for j in range(NY):
    for i in range(NX):
        x = i / RES - MG; y = j / RES - MG; z = float(HM[j, i]); k = int(KIND[j, i])
        verts.append((x - 70.0, 60.0 - y, z))
        c = colmap[k]
        n = noise.noise(Vector((x * 0.15, y * 0.15, 0))) * 0.08 + noise.noise(Vector((x * 0.9, y * 0.9, 1))) * 0.04
        if k == 1:                                   # courtyards: lighter where higher (A = pale stone yard)
            c = (0.36, 0.33, 0.26) if z < 3 else ((0.40, 0.37, 0.31) if z < 6 else (0.46, 0.44, 0.40))
            if (x % 2.0) < 0.3 or (y % 2.0) < 0.3: c = (c[0] * 0.72, c[1] * 0.72, c[2] * 0.72)     # paving joints
        if k == 4: c = (0.13 + n * 0.6, 0.21 + n, 0.11 + n * 0.6)
        if k == 0:                                   # valley floor: grass / dirt mix
            g = 0.5 + noise.noise(Vector((x * 0.08, y * 0.08, 3)))
            c = (0.22 * g + 0.34 * (1 - g), 0.30 * g + 0.30 * (1 - g), 0.14 * g + 0.21 * (1 - g))
        cols.append((min(1, max(0, c[0] + n)), min(1, max(0, c[1] + n)), min(1, max(0, c[2] + n))))
faces = []
for j in range(NY - 1):
    for i in range(NX - 1):
        a = j * NX + i; faces.append((a, a + NX, a + NX + 1, a + 1))
terr = mesh_obj("Terrain", verts, faces, GROUND, cols, smooth=True)
# ---------------------------------------------------------------- terrace walls (curved stone, follows each outline)
print("walls")
def near_ramp(x, y, pad=0.6):
    for (x0, y0, h0), (x1, y1, h1), w, k in RAMPS:
        dx, dy = x1 - x0, y1 - y0; L = math.hypot(dx, dy); ux, uy = dx / L, dy / L
        t = ((x - x0) * ux + (y - y0) * uy) / L; s = abs(-(x - x0) * uy + (y - y0) * ux)
        if -0.05 <= t <= 1.05 and s <= w / 2 + pad: return True
    return False
wv = []; wf = []; wc = []
def wall_seg(p0, p1, top, bot, th=0.55):
    d = Vector((p1[0] - p0[0], p1[1] - p0[1], 0)); L = d.length
    if L < 1e-3: return
    nrm = Vector((-d.y, d.x, 0)).normalized() * th * 0.5
    a = B(*p0); b = B(*p1)
    pts = [a - nrm, b - nrm, b + nrm, a + nrm]
    base = len(wv)
    for q in pts: wv.append((q.x, q.y, bot))
    for q in pts: wv.append((q.x, q.y, top))
    for f in [(0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7), (4, 5, 6, 7)]: wf.append(tuple(base + v for v in f))
    g = 0.30 + random.uniform(-0.07, 0.07)
    for k in range(8): wc.append((g, g * 0.96, g * 0.88))
for poly, lv in TERRACES + [(POND, 4.8)]:
    for i in range(len(poly) - 1):
        p0, p1 = poly[i], poly[i + 1]
        m = ((p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2)
        d = Vector((p1[0] - p0[0], p1[1] - p0[1], 0)).normalized(); out = Vector((d.y, -d.x, 0))
        # outward side: lower ground -> a retaining wall; skip where stairs cut through or the ground is as high
        ho = min(hat(m[0] + out.x * 1.2, m[1] + out.y * 1.2), hat(m[0] - out.x * 1.2, m[1] - out.y * 1.2))
        if poly is POND: ho = POND_BED; top = 4.95
        else: top = lv + 0.35
        if lv - ho < 0.6 or near_ramp(*m): continue
        # split into stones ~1.2 m long with tiny height jitter (hand-laid look)
        L = math.hypot(p1[0] - p0[0], p1[1] - p0[1]); n = max(1, int(L / 1.2))
        for k in range(n):
            a = (p0[0] + (p1[0] - p0[0]) * k / n, p0[1] + (p1[1] - p0[1]) * k / n)
            b = (p0[0] + (p1[0] - p0[0]) * (k + 1) / n, p0[1] + (p1[1] - p0[1]) * (k + 1) / n)
            wall_seg(a, b, top + random.uniform(-0.05, 0.05), ho - 0.6)
walls = mesh_obj("Walls", wv, wf, WALLM, wc)
# ---------------------------------------------------------------- water: pond + stream ribbon
print("water")
pv = [(B(x, y).x, B(x, y).y, POND_SURF) for x, y in POND[:-1]]
pond = mesh_obj("Pond", pv, [tuple(range(len(pv)))], WATER)
sv = []; sf = []
pts = STREAM
for i, (x, y) in enumerate(pts):
    if i < len(pts) - 1: d = Vector((pts[i + 1][0] - x, pts[i + 1][1] - y, 0))
    n = Vector((-d.y, d.x, 0)).normalized() * 1.7
    z = hat(x, y) + 0.35
    p = B(x, y); sv += [(p.x + n.x, p.y - n.y, z), (p.x - n.x, p.y + n.y, z)]
    if i: sf.append((2 * i - 2, 2 * i - 1, 2 * i + 1, 2 * i))
mesh_obj("Stream", sv, sf, WATER)
# ---------------------------------------------------------------- stairs (visual steps over the walkable slope)
print("stairs")
for (x0, y0, h0), (x1, y1, h1), w, k in RAMPS:
    if k in ("path", "bridge"):
        continue
    L = math.hypot(x1 - x0, y1 - y0); n = max(2, int(abs(h1 - h0) / 0.3))
    ang = math.atan2(-(y1 - y0), x1 - x0)
    for s in range(n):
        t = (s + 0.5) / n; x = x0 + (x1 - x0) * t; y = y0 + (y1 - y0) * t; z = h0 + (h1 - h0) * (s + 1) / n
        p = B(x, y)
        hb = h0 - 0.3                                     # solid flight: each step goes down to the foot
        o = box((p.x, p.y, (z + hb) / 2), (L / n + 0.02, w, z - hb), STEPM if k == "stairs" else ROCKM, rot=ang, bev=0.03, name="Step")
    if k == "stairs":                                   # side cheek stones
        for side in (-1, 1):
            dx, dy = x1 - x0, y1 - y0; nx, ny = -dy / L * (w / 2 + 0.25) * side, dx / L * (w / 2 + 0.25) * side
            if abs(h1 - h0) > 3.5 and side < 0: continue          # 경회루 stair: no cheek on the deck side
            for s in range(n):
                t = (s + 0.5) / n; x = x0 + dx * t + nx; y = y0 + dy * t + ny; z = h0 + (h1 - h0) * (s + 1) / n
                p = B(x, y); box((p.x, p.y, z - 0.1), (L / n + 0.05, 0.5, 0.9), STONEM, rot=ang, bev=0.05, name="Stone")
# ---------------------------------------------------------------- cave: rock tunnel over the cave ramp
print("cave")
(cx0, cy0, ch0), (cx1, cy1, ch1), cw, _ = [r for r in RAMPS if r[3] == "cave"][0]
L = math.hypot(cx1 - cx0, cy1 - cy0); n = int(L / 1.0)
ang = math.atan2(-(cy1 - cy0), cx1 - cx0)
for s in range(n + 1):
    t = s / n; x = cx0 + (cx1 - cx0) * t; y = cy0 + (cy1 - cy0) * t; z = ch0 + (ch1 - ch0) * t
    p = B(x, y)
    for a in range(9):                                  # arch of rough rocks
        th = math.pi * a / 8
        r = cw / 2 + 0.6 + random.uniform(-0.15, 0.25)
        off = Vector((-math.sin(ang), -math.cos(ang), 0)) * 0
        q = Vector((p.x, p.y, z)) + Vector((-math.sin(ang) * math.cos(th) * r, math.cos(ang) * math.cos(th) * r, math.sin(th) * 3.2 + 0.1))
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=random.uniform(0.7, 1.0), location=q)
        o = bpy.context.active_object; o.name = "Rock"; o.scale = (random.uniform(0.8, 1.3), random.uniform(0.8, 1.3), random.uniform(0.6, 1.0)); o.data.materials.append(ROCKM)
for t, label in ((0.0, "in"), (1.0, "out")):           # glow at the cave mouths
    x = cx0 + (cx1 - cx0) * t; y = cy0 + (cy1 - cy0) * t
# ---------------------------------------------------------------- buildings
print("buildings")
HANOK = open(os.path.join(HERE, "build_hanok.py")).read()
def building(kind, x, y, rot, args):
    g = {"EMBED": True, "LOW": True, "ARGS": ["/tmp/x.blend"] + [str(v) for v in args], "__name__": "hanok"}
    exec(HANOK, g)
    o = g["RESULT"]; o.name = "Bld_" + kind
    z = GH_BASE if (x, y) == (31, 28) else hat(x, y)
    if kind == "pavilion" and (x, y) != (31, 28): z = hat(x, y + 4)     # 만세루: stands at the foot of the stairs
    p = B(x, y); o.location = (p.x, p.y, z - (0.0 if kind in ("pavilion",) else 0.15)); o.rotation_euler.z = -math.radians(rot)
    if kind == "bell":
        bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=0.75, radius2=0.5, depth=1.6, location=(p.x, p.y, z + 2.8)); b = bpy.context.active_object; b.name = "Stone_bell"; b.data.materials.append(BRONZE)
    return o
for kind, x, y, rot, args in BUILDINGS: building(kind, x, y, rot, args)
# ---------------------------------------------------------------- pagoda + lanterns at A
print("pagoda")
ax, ay = SITE_A; p = B(ax, ay); z0 = hat(ax, ay)
box((p.x, p.y, z0 + 0.35), (3.6, 3.6, 0.7), STONEM, bev=0.05)
box((p.x, p.y, z0 + 1.2), (2.4, 2.4, 1.0), STONEM, bev=0.04)
zz = z0 + 1.7
for k in range(3):
    w = 2.6 - k * 0.4
    box((p.x, p.y, zz + 0.65), (w * 0.55, w * 0.55, 1.3 - k * 0.2), STONEM, bev=0.04); zz += 1.3 - k * 0.2
    box((p.x, p.y, zz + 0.1), (w, w, 0.2), STONEM, bev=0.06)
    box((p.x, p.y, zz + 0.28), (w * 0.8, w * 0.8, 0.16), STONEM, bev=0.05); zz += 0.44
bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.25, radius2=0.05, depth=1.2, location=(p.x, p.y, zz + 0.6)); bpy.context.active_object.name = "Stone_top"; bpy.context.active_object.data.materials.append(BRONZE)
for dx in (-8, 8):
    q = B(ax + dx, ay + 2); zq = hat(ax + dx, ay + 2)
    box((q.x, q.y, zq + 0.6), (0.4, 0.4, 1.2), STONEM); box((q.x, q.y, zq + 1.45), (0.9, 0.9, 0.5), STONEM, bev=0.05)
    box((q.x, q.y, zq + 1.85), (1.1, 1.1, 0.2), STONEM, bev=0.06)
# ---------------------------------------------------------------- bridges
(lx0, ly0), (lx1, ly1) = GH_LANDING                              # stair landing: stone slab on two posts, deck height
lc = B((lx0 + lx1) / 2, (ly0 + ly1) / 2); lang = math.atan2(-(ly1 - ly0), lx1 - lx0); lL = math.hypot(lx1 - lx0, ly1 - ly0)
box((lc.x, lc.y, GH_DECK - 0.2), (lL, 1.6, 0.4), STEPM, rot=lang, bev=0.03)
box((lc.x, lc.y, (GH_BASE - 0.2 + GH_DECK - 0.4) / 2), (lL, 1.7, GH_DECK - 0.2 - GH_BASE), STONEM, rot=lang, bev=0.04)   # solid stone pier under the landing
isl = [B(x, y) for x, y in GH_ISLAND[:-1]]                     # 경회루 stone island (cut stone, a step above the water)
mesh_obj("Stone_island", [(q.x, q.y, GH_BASE - 1.5) for q in isl] + [(q.x, q.y, GH_BASE) for q in isl],
    [(0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7), (4, 5, 6, 7)], STONEM)
for (x0, y0), (x1, y1), hz, w in BRIDGES:
    L = math.hypot(x1 - x0, y1 - y0); ang = math.atan2(-(y1 - y0), x1 - x0); c = B((x0 + x1) / 2, (y0 + y1) / 2)
    box((c.x, c.y, hz - 0.15), (L, w, 0.3), STONEM, rot=ang, bev=0.05)
    for side in (-1, 1):
        nx, ny = -math.sin(ang) * side * (w / 2), math.cos(ang) * side * (w / 2)     # perpendicular to the deck
        box((c.x + nx, c.y + ny, hz + 0.35), (L, 0.2, 0.7), STONEM, rot=ang, bev=0.05)
# ---------------------------------------------------------------- nature: pines, bamboo, rocks
print("nature")
def pine_proto():
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.22, depth=7, location=(0, 0, 3.5)); t = bpy.context.active_object; t.data.materials.append(BARK)
    parts = [t]
    for k in range(4):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=1.0, location=(random.uniform(-0.8, 0.8), random.uniform(-0.8, 0.8), 4.6 + k * 1.0))
        c = bpy.context.active_object; c.scale = (2.2 - k * 0.35, 2.0 - k * 0.3, 0.75); c.data.materials.append(PINE if k % 2 else PINE2); parts.append(c)
    for x in bpy.context.selected_objects: x.select_set(False)
    for q in parts: q.select_set(True)
    bpy.context.view_layer.objects.active = t; bpy.ops.object.join(); o = bpy.context.active_object
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True); o.location = (0, 0, -100); return o
def bamboo_proto():
    parts = []
    for k in range(9):
        a = random.uniform(0, 6.28); r = random.uniform(0, 1.2)
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.07, depth=random.uniform(6, 9), location=(math.cos(a) * r, math.sin(a) * r, 4))
        c = bpy.context.active_object; c.data.materials.append(BAMBOO); parts.append(c)
    for k in range(4):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=1.3, location=(random.uniform(-1, 1), random.uniform(-1, 1), 6.5 + k * 0.6))
        c = bpy.context.active_object; c.data.materials.append(BAMLEAF); parts.append(c)
    for x in bpy.context.selected_objects: x.select_set(False)
    for q in parts: q.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]; bpy.ops.object.join(); o = bpy.context.active_object
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True); o.location = (0, 0, -100); return o
PP = pine_proto(); BP = bamboo_proto()
def free_spot(x, y, r=3.0):
    for poly, lv in TERRACES:
        if inside((x, y), poly): return False
    if inside((x, y), POND) or near_ramp(x, y, 2.5): return False
    for k, bx, by, *_ in BUILDINGS:
        if math.hypot(bx - x, by - y) < 9: return False
    return True
count = 0
for i in range(900):
    x = random.uniform(-20, 160); y = random.uniform(-20, 140)
    ins = inside((x, y), OUTLINE)
    if ins and (not free_spot(x, y) or random.random() < 0.55): continue
    bam = 112 < x < 140 and 55 < y < 105
    o = bpy.data.objects.new("tree", (BP if bam else PP).data); link(o)
    s = random.uniform(0.8, 1.3); o.scale = (s, s, s * random.uniform(0.85, 1.2))
    o.location = (B(x, y).x, B(x, y).y, hat(x, y) - 0.2); o.rotation_euler = (random.uniform(-0.06, 0.06), random.uniform(-0.06, 0.06), random.uniform(0, 6.28))
    count += 1
for i in range(70):                                     # boulders on the valley floor / stream banks
    x = random.uniform(4, 136); y = random.uniform(4, 116)
    if not inside((x, y), OUTLINE) or not free_spot(x, y): continue
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=random.uniform(0.6, 1.6), location=(B(x, y).x, B(x, y).y, hat(x, y)))
    o = bpy.context.active_object; o.name = "Rock"; o.scale = (random.uniform(0.8, 1.4), random.uniform(0.8, 1.4), random.uniform(0.5, 0.9)); o.data.materials.append(ROCKM)
    for v in o.data.vertices: v.co *= 1.0 + noise.noise(v.co * 2.0) * 0.25
print("trees", count)
bpy.ops.wm.save_as_mainfile(filepath="/tmp/gbg/temple.blend")
print("TEMPLE_SAVED")
