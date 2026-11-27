# Hanok temple hall (original, parametric): stone platform + steps, red round columns, dancheong
# bands under the eaves, curved hip-and-gable (팔작) roof whose eaves sag in the middle and sweep up at
# the corners, ridge with raised ends, tile rows. blender -b --python build_hanok.py -- OUT.blend [bays] [depth_bays]
import bpy, bmesh, math, sys
from mathutils import Vector
# can also be exec()'d by another builder with ARGS = [...] and EMBED = True: then the scene is kept,
# nothing is saved and the joined object is left in RESULT
EMBED = globals().get("EMBED", False)
a = globals().get("ARGS") or (sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
OUT = a[0] if a else "/tmp/gbg/hall.blend"; NB = int(a[1]) if len(a) > 1 else 5; ND = int(a[2]) if len(a) > 2 else 3
PAV = len(a) > 3 and a[3] == "pavilion"
GATE = len(a) > 3 and a[3] == "gate"       # open gate / corridor: columns + roof only
FLH = float(a[4]) if len(a) > 4 else 4.0    # pavilion: upper floor height     # 경회루-style: stone pillars over water, open wooden upper floor
if not EMBED: bpy.ops.wm.read_factory_settings(use_empty=True)
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def mat(n, rgb, r=0.7, m=0.0):
    if n in bpy.data.materials: return bpy.data.materials[n]
    x = bpy.data.materials.new(n); x.use_nodes = True; b = x.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (lin(rgb[0]), lin(rgb[1]), lin(rgb[2]), 1); b.inputs["Roughness"].default_value = r; b.inputs["Metallic"].default_value = m
    return x
STONE = mat("H_Stone", (0.55, 0.53, 0.49), 0.85); STONE2 = mat("H_Stone2", (0.46, 0.44, 0.41), 0.9)
COL = mat("H_Column", (0.62, 0.17, 0.12), 0.6); BEAM = mat("H_Beam", (0.22, 0.48, 0.40), 0.6)
DAN1 = mat("H_Dan1", (0.85, 0.35, 0.18), 0.6); DAN2 = mat("H_Dan2", (0.95, 0.85, 0.55), 0.6); DAN3 = mat("H_Dan3", (0.25, 0.38, 0.62), 0.6)
TILE = mat("H_Tile", (0.24, 0.25, 0.27), 0.55); TILE2 = mat("H_Tile2", (0.16, 0.17, 0.18), 0.5)
DOOR = mat("H_Door", (0.55, 0.30, 0.18), 0.7); PAPER = mat("H_Paper", (0.93, 0.89, 0.78), 0.9); WALL = mat("H_Wall", (0.92, 0.88, 0.80), 0.9)
OB = []
def fin(o, m):
    o.data.materials.clear(); o.data.materials.append(m)
    for p in o.data.polygons: p.use_smooth = True
    OB.append(o); return o
def box(c, s, m, bev=0.02):
    bpy.ops.mesh.primitive_cube_add(size=1, location=c); o = bpy.context.active_object; o.scale = s
    bpy.ops.object.transform_apply(scale=True)
    if bev:
        md = o.modifiers.new("b", "BEVEL"); md.width = min(bev, min(s) * 0.45); md.segments = 3; bpy.ops.object.modifier_apply(modifier="b")
    return fin(o, m)
def cyl(c, r, h, m, v=16, r2=None):
    bpy.ops.mesh.primitive_cone_add(vertices=v, radius1=r, radius2=r2 or r * 0.88, depth=h, location=c); return fin(bpy.context.active_object, m)
BAY = 3.2; W = NB * BAY; D = ND * BAY; CH = 3.6      # column height
BAY = 3.2; W = NB * BAY; D = ND * BAY
xs = [-W / 2 + i * BAY for i in range(NB + 1)]; ys = [-D / 2 + j * BAY for j in range(ND + 1)]
if PAV:
    FL = FLH; CH = 3.4                                   # upper floor height, upper column height
    for x in xs:                                          # square stone pillars (ground floor forest)
        for y in ys: box((x, y, FL / 2), (0.62, 0.62, FL), STONE, 0.06)
    box((0, 0, FL + 0.18), (W + 1.6, D + 1.6, 0.36), DOOR, 0.04)          # wooden floor deck
    box((0, 0, FL - 0.1), (W + 1.0, D + 1.0, 0.25), BEAM, 0.03)
    for side in (-1, 1):                                                   # railing (난간)
        for k in range(int((W + 1.4) / 0.9) + 1):
            box((-(W + 1.4) / 2 + k * 0.9, side * (D + 1.4) / 2, FL + 0.7), (0.08, 0.08, 0.7), DAN1 if k % 4 == 0 else COL, 0.01)
        box((0, side * (D + 1.4) / 2, FL + 1.08), (W + 1.4, 0.12, 0.08), COL, 0.02)
        for k in range(int((D + 1.4) / 0.9) + 1):
            box((side * (W + 1.4) / 2, -(D + 1.4) / 2 + k * 0.9, FL + 0.7), (0.08, 0.08, 0.7), COL, 0.01)
        box((side * (W + 1.4) / 2, 0, FL + 1.08), (0.12, D + 1.4, 0.08), COL, 0.02)
    for x in xs:
        for y in ys:
            if x not in (xs[0], xs[-1]) and y not in (ys[0], ys[-1]): continue
            cyl((x, y, FL + 0.36 + CH / 2), 0.2, CH, COL, 16, 0.18)
    top = FL + 0.36 + CH
    # water + stone embankment so the render reads as a pond
    if not EMBED:
        bpy.ops.mesh.primitive_plane_add(size=1, location=(0, 0, 0.35)); o = bpy.context.active_object; o.scale = (W * 2.6, D * 3.2, 1)
        bpy.ops.object.transform_apply(scale=True); fin(o, mat("H_Water", (0.25, 0.45, 0.52), 0.08))
else:
    # stone platform (기단) with steps
    box((0, 0, 0.45), (W + 3.0, D + 3.0, 0.9), STONE, 0.05)
    box((0, 0, 0.93), (W + 2.6, D + 2.6, 0.06), STONE2, 0.02)
    for k in range(4):
        box((0, -(D + 3.0) / 2 - 0.35 - k * 0.35 + 1.05, 0.9 - 0.225 * (k + 1) + 0.11), (3.4, 0.36, 0.225 * (4 - k) * 1.0), STONE, 0.03)
    # columns on round stone bases
    for x in xs:
        for y in ys:
            if x not in (xs[0], xs[-1]) and y not in (ys[0], ys[-1]): continue
            cyl((x, y, 1.0), 0.32, 0.18, STONE2, 16, 0.3)
            cyl((x, y, 0.96 + CH / 2 + 0.08), 0.21, CH, COL, 16, 0.19)
    # front doors (꽃살문) + side walls (gates / corridors stay open)
    for i in (range(NB) if not GATE else []):
        cx = (xs[i] + xs[i + 1]) / 2
        box((cx, -D / 2 + 0.05, 0.96 + CH * 0.45), (BAY - 0.45, 0.08, CH * 0.85), DOOR, 0.02)
        for k in range(3):
            box((cx - BAY * 0.27 + k * BAY * 0.27, -D / 2 - 0.0, 0.96 + CH * 0.5), (BAY * 0.22, 0.09, CH * 0.62), PAPER, 0.01)
    for x in ((xs[0], xs[-1]) if not GATE else []):
        box((x, 0, 0.96 + CH * 0.45), (0.12, D - 0.4, CH * 0.85), WALL, 0.02)
    if not GATE: box((0, D / 2, 0.96 + CH * 0.45), (W - 0.4, 0.12, CH * 0.85), WALL, 0.02)

    top = 0.96 + CH
# beams + dancheong bands (창방 / 평방), brackets (공포) as stacked blocks
for y in (ys[0], ys[-1]): box((0, y, top + 0.12), (W + 0.5, 0.36, 0.3), BEAM, 0.03); box((0, y, top + 0.12), (W + 0.52, 0.38, 0.08), DAN2, 0.0)
for x in (xs[0], xs[-1]): box((x, 0, top + 0.12), (0.36, D + 0.5, 0.3), BEAM, 0.03)
for y in (ys[0], ys[-1]):
    for i in range(NB * 3 + 1):
        x = -W / 2 + i * BAY / 3
        s = -1 if y < 0 else 1
        box((x, y + s * 0.18, top + 0.4), (0.26, 0.55, 0.16), DAN3 if i % 3 else DAN1, 0.02)
        box((x, y + s * 0.3, top + 0.58), (0.22, 0.7, 0.16), BEAM, 0.02)
        box((x, y + s * 0.42, top + 0.74), (0.2, 0.85, 0.14), DAN1 if i % 3 else DAN3, 0.02)
for x in (xs[0], xs[-1]):
    for j in range(ND * 3 + 1):
        y = -D / 2 + j * BAY / 3; s = -1 if x < 0 else 1
        box((x + s * 0.3, y, top + 0.58), (0.7, 0.22, 0.16), BEAM, 0.02)
        box((x + s * 0.42, y, top + 0.74), (0.85, 0.2, 0.14), DAN1, 0.02)
# curved roof: a grid over the hip; eave line sags in the middle and lifts at the corners
EAVE = top + 0.72; OV = 2.2          # eave height, overhang
RW = W / 2 + OV; RD = D / 2 + OV; RIDGE = EAVE + 3.4; RL = W / 2 - D * 0.25
def roof_z(x, y):
    u = min(1.0, abs(x) / RW); v = min(1.0, abs(y) / RD)
    tx = max(0.0, (abs(x) - RL) / (RW - RL))
    t = min(1.0, max(v, tx))                           # 0 on the ridge line .. 1 at the eave (hip roof)
    f = 1.0 - (1.0 - t) ** 1.7                         # concave: steep near the ridge, flatter at the eave
    z = RIDGE - (RIDGE - EAVE) * f
    lift = (max(u, 0.0) ** 6) * (v ** 6)               # gentle upturn only right at the corners
    edge_lift = 0.18 * (u ** 8) + 0.18 * (v ** 8)      # eave line rises a little towards both ends
    return z + 1.0 * lift + edge_lift * (1.0 if t > 0.85 else t / 0.85)
bm = bmesh.new(); N = 48; M = 32; vs = []
for j in range(M + 1):
    row = []
    for i in range(N + 1):
        x = -RW + 2 * RW * i / N; y = -RD + 2 * RD * j / M
        row.append(bm.verts.new((x, y, roof_z(x, y))))
    vs.append(row)
for j in range(M):
    for i in range(N): bm.faces.new((vs[j][i], vs[j][i + 1], vs[j + 1][i + 1], vs[j + 1][i]))
me = bpy.data.meshes.new("roof"); bm.to_mesh(me); bm.free()
ro = bpy.data.objects.new("roof", me); bpy.context.scene.collection.objects.link(ro)
bpy.context.view_layer.objects.active = ro; ro.select_set(True)
sol = ro.modifiers.new("s", "SOLIDIFY"); sol.thickness = 0.35; bpy.ops.object.modifier_apply(modifier="s")
fin(ro, TILE)
# tile rows (기와골): ridges running down the slope on the front / back
for side in (-1, 1):
    for i in range(1, N, 2):
        x = -RW + 2 * RW * i / N
        if abs(x) > RW * 0.97: continue
        pts = []
        for j in range(0, M // 2 + 1):
            y = side * RD * (1 - j / (M / 2))
            if abs(y) < 0.2: continue
            pts.append(Vector((x, y, roof_z(x, y) + 0.07)))
        if len(pts) < 3: continue
        cu = bpy.data.curves.new("t", "CURVE"); cu.dimensions = "3D"; cu.bevel_depth = 0.09; cu.bevel_resolution = 2
        sp = cu.splines.new("POLY"); sp.points.add(len(pts) - 1)
        for k, p in enumerate(pts): sp.points[k].co = (p.x, p.y, p.z, 1)
        o = bpy.data.objects.new("t", cu); bpy.context.scene.collection.objects.link(o)
        for x2 in bpy.context.selected_objects: x2.select_set(False)
        bpy.context.view_layer.objects.active = o; o.select_set(True); bpy.ops.object.convert(target="MESH")
        fin(bpy.context.active_object, TILE2)
# ridge (용마루) with raised ends (치미)
box((0, 0, RIDGE + 0.3), (2 * RL + 0.6, 0.55, 0.55), TILE2, 0.1)
for s in (-1, 1):
    box((s * (RL + 0.2), 0, RIDGE + 0.85), (0.5, 0.6, 1.2), TILE2, 0.15)
# gable triangles (합각) on the sides
for s in (-1, 1):
    bm = bmesh.new(); xx = s * (RL + 0.05)
    v1 = bm.verts.new((xx, -D * 0.3, EAVE + 1.3)); v2 = bm.verts.new((xx, D * 0.3, EAVE + 1.3)); v3 = bm.verts.new((xx, 0, RIDGE + 0.2))
    bm.faces.new((v1, v2, v3)); me = bpy.data.meshes.new("g"); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new("g", me); bpy.context.scene.collection.objects.link(o); fin(o, DAN1)
for x in bpy.context.selected_objects: x.select_set(False)
for o in OB: o.select_set(True)
bpy.context.view_layer.objects.active = OB[0]; bpy.ops.object.join()
h = bpy.context.active_object; h.name = "Hall"
RESULT = h
if not EMBED:
    bpy.ops.wm.save_as_mainfile(filepath=OUT)
    print("HALL faces", len(h.data.polygons))
