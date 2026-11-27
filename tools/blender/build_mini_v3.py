# Mini Soldier v3 characters, built in Blender from the concept sheets (blender -b --python this.py -- CLASS).
# T-pose, facing -Y, Z up, about 2.1 m (rig_tripo.py OWN mode rescales, measures the joints and skins it).
#  - cloth / skin are unions of primitives fused by voxel remesh + laplacian smoothing (soft, folded shapes)
#  - hard gear (helmet, pads, plates, pouches, boots) are heavily bevelled blocks, placed onto the surfaces by ray casts
#  - the face (anime eyes, brows, mouth, bandage) is layered geometry laid onto the head surface
#  - shading detail is baked into vertex colours: ray-cast ambient occlusion + cavity + fabric noise
# Out: /tmp/mv3/<CLASS>.blend (one mesh) and preview renders.
import bpy, bmesh, math, sys, os, random
from mathutils import Vector, Matrix, Quaternion, noise
from mathutils.bvhtree import BVHTree
CLASS = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "rookie"
OUTDIR = "/tmp/mv3"; os.makedirs(OUTDIR, exist_ok=True)
random.seed(7)
bpy.ops.wm.read_factory_settings(use_empty=True)
SC = bpy.context.scene

# ------------------------------------------------------------------ palette (sRGB)
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
MATS = {}
def mat(name, rgb, rough=0.8, metal=0.0, alpha=1.0):
    if name in MATS: return MATS[name]
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (lin(rgb[0]), lin(rgb[1]), lin(rgb[2]), 1)
    b.inputs["Roughness"].default_value = rough; b.inputs["Metallic"].default_value = metal
    MATS[name] = m
    return m
P = {
 "rookie": dict(uniform=(0.37, 0.38, 0.25), uniform2=(0.47, 0.47, 0.34), gear=(0.62, 0.53, 0.37), gear2=(0.52, 0.44, 0.30),
                helmet=(0.46, 0.44, 0.32), dark=(0.24, 0.24, 0.25), black=(0.11, 0.11, 0.12), boot=(0.29, 0.23, 0.19),
                team=(0.22, 0.37, 0.75)),
}[CLASS]
UNI = mat("R_Uniform", P["uniform"], 0.9); UNI2 = mat("R_Sleeve", P["uniform2"], 0.9)
GEAR = mat("R_Gear", P["gear"], 0.85); GEAR2 = mat("R_Gear2", P["gear2"], 0.85); HELM = mat("R_Helmet", P["helmet"], 0.65)
DARK = mat("R_Dark", P["dark"], 0.6); BLACK = mat("R_Black", P["black"], 0.5); BOOT = mat("R_Boot", P["boot"], 0.8)
SOLE = mat("R_Sole", (0.16, 0.13, 0.11), 0.9); TEAM = mat("Team", P["team"], 0.6); WHITE = mat("R_White", (0.93, 0.93, 0.9), 0.5)
SKIN = mat("R_Skin", (0.94, 0.75, 0.61), 0.6); SKIN2 = mat("R_Blush", (0.96, 0.66, 0.58), 0.6)
HAIR = mat("R_Hair", (0.22, 0.14, 0.10), 0.6); LASH = mat("R_Lash", (0.08, 0.05, 0.04), 0.4)
EYEW = mat("R_EyeWhite", (0.99, 0.98, 0.96), 0.25); IRIS = mat("R_Iris", (0.55, 0.36, 0.22), 0.2); IRIS2 = mat("R_IrisDark", (0.23, 0.13, 0.08), 0.2)
PUPIL = mat("R_Pupil", (0.07, 0.04, 0.03), 0.2); SHINE = mat("R_Shine", (1, 1, 1), 0.05)
LENS = mat("R_Lens", (0.42, 0.45, 0.55), 0.12, 0.0); BAND = mat("R_Bandage", (0.95, 0.85, 0.72), 0.8); BRASS = mat("R_Brass", (0.80, 0.62, 0.28), 0.35, 0.8)

SOFT = {}   # group -> [objects] fused by remesh
HARD = []

# ------------------------------------------------------------------ primitives
def _apply(o):
    bpy.context.view_layer.objects.active = o
    for x in bpy.context.selected_objects: x.select_set(False)
    o.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
def _fin(o, m, soft):
    o.data.materials.clear(); o.data.materials.append(m)
    for p in o.data.polygons: p.use_smooth = True
    if soft: SOFT.setdefault(soft, []).append(o)
    else: HARD.append(o)
    return o
def ell(c, r, m, soft=None, rot=None, seg=24, rings=14):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, location=c)
    o = bpy.context.active_object; o.scale = r
    if rot: o.rotation_euler = rot
    _apply(o); return _fin(o, m, soft)
def cap(a, b, r, m, soft=None, r2=None):
    """capsule from a to b (radius r at a, r2 at b)"""
    a, b = Vector(a), Vector(b); r2 = r if r2 is None else r2
    d = b - a; L = d.length
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=16, location=(0, 0, 0))
    o = bpy.context.active_object
    for v in o.data.vertices:          # stretch the sphere into a capsule along z, tapering
        t = (v.co.z + 1) / 2
        rr = r + (r2 - r) * t
        z = v.co.z * (r if v.co.z < 0 else r2)
        v.co = Vector((v.co.x * rr, v.co.y * rr, (L if v.co.z > 0 else 0.0) + z))
    o.rotation_euler = d.to_track_quat("Z", "Y").to_euler(); o.location = a
    _apply(o); bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)
    return _fin(o, m, soft)
def box(c, s, m, bev=0.02, rot=None, soft=None, seg=3):
    bpy.ops.mesh.primitive_cube_add(size=1, location=c)
    o = bpy.context.active_object; o.scale = s
    if rot: o.rotation_euler = rot
    _apply(o)
    if bev > 0:
        md = o.modifiers.new("b", "BEVEL"); md.width = min(bev, min(s) * 0.49); md.segments = seg; md.limit_method = "NONE"
        bpy.ops.object.modifier_apply(modifier="b")
    return _fin(o, m, soft)
def cyl(c, r, h, m, rot=(0, 0, 0), bev=0.0, soft=None, verts=32):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=h, location=c, rotation=rot)
    o = bpy.context.active_object; _apply(o)
    if bev > 0:
        md = o.modifiers.new("b", "BEVEL"); md.width = bev; md.segments = 3; md.limit_method = "ANGLE"
        bpy.ops.object.modifier_apply(modifier="b")
    return _fin(o, m, soft)
def torus(c, R, r, m, rot=(0, 0, 0), sx=1.0, sy=1.0, soft=None):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, major_segments=48, minor_segments=12, location=c, rotation=rot)
    o = bpy.context.active_object; o.scale = (sx, sy, 1); _apply(o)
    return _fin(o, m, soft)
def tube(pts, r, m, soft=None, taper=None, flat=1.0):
    """bevelled curve through pts (radius r, optional per-point radius list)"""
    cu = bpy.data.curves.new("c", "CURVE"); cu.dimensions = "3D"; cu.bevel_depth = r; cu.bevel_resolution = 4; cu.resolution_u = 8
    sp = cu.splines.new("POLY" if len(pts) < 3 else "NURBS"); sp.points.add(len(pts) - 1)
    for i, p in enumerate(pts):
        sp.points[i].co = (p[0], p[1], p[2], 1); sp.points[i].radius = taper[i] if taper else 1.0
    if len(pts) >= 3: sp.use_endpoint_u = True; sp.order_u = 3
    cu.use_fill_caps = True
    o = bpy.data.objects.new("c", cu); SC.collection.objects.link(o)
    bpy.context.view_layer.objects.active = o
    for x in bpy.context.selected_objects: x.select_set(False)
    o.select_set(True); bpy.ops.object.convert(target="MESH")
    o = bpy.context.active_object
    return _fin(o, m, soft)
def cut(o, co, no):
    bm = bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=co, plane_no=no, clear_outer=True)
    bm.to_mesh(o.data); bm.free(); return o
def mirror_x(fn):
    for s in (1, -1): fn(s)

# ------------------------------------------------------------------ surface placement
def bvh_of(objs):
    bm = bmesh.new()
    for o in objs:
        t = bmesh.new(); t.from_mesh(o.data); t.transform(o.matrix_world)
        me = bpy.data.meshes.new("t"); t.to_mesh(me); t.free(); bm.from_mesh(me); bpy.data.meshes.remove(me)
    return BVHTree.FromBMesh(bm)
def hit(tree, origin, d):
    loc, nrm, _, _ = tree.ray_cast(Vector(origin), Vector(d).normalized(), 5.0)
    return (loc, nrm) if loc else (None, None)
def onto(o, loc, nrm, out=0.0, spin=0.0):
    """o was built around the origin facing -Y; move it to loc with its -Y along nrm"""
    q = Vector((0, -1, 0)).rotation_difference(nrm)
    if spin: q = q @ Quaternion(Vector((0, -1, 0)), spin)
    o.data.transform(q.to_matrix().to_4x4())
    o.data.transform(Matrix.Translation(loc + nrm * out))
    o.data.update(); return o
def feat(kind, tree, fx, fz, size, m, out, origin_y=-2.0, spin=0.0, dirv=None):
    """a flattened feature at face coords (fx, fz): ray from the front"""
    o0 = Vector((fx, origin_y, fz)); d = dirv or Vector((0, 1, 0))
    loc, nrm = hit(tree, o0, d)
    if loc is None: return None
    if kind == "ell":
        o = ell((0, 0, 0), (size[0], size[1], size[2]), m)
    else:
        o = box((0, 0, 0), size, m, bev=min(size) * 0.45)
    return onto(o, loc, nrm, out, spin)

# ================================================================== body
H_HEAD = (0.0, -0.01, 1.56); HR = (0.30, 0.28, 0.29)
def build_rookie():
    # ---------------- skin: head, cheeks, neck, forearms
    ell(H_HEAD, HR, SKIN, "skin", seg=48, rings=32)
    ell((0, -0.045, 1.44), (0.235, 0.21, 0.155), SKIN, "skin")                  # chubby cheeks / short round jaw
    cap((0, -0.01, 1.20), (0, -0.01, 1.34), 0.085, SKIN, "skin")
    mirror_x(lambda s: cap((0.40 * s, 0, 1.14), (0.565 * s, 0, 1.14), 0.07, SKIN, "skin", 0.062))
    # ---------------- uniform: torso, arms (short, rolled sleeves), baggy trousers with folds
    ell((0, 0.0, 1.02), (0.235, 0.165, 0.22), UNI, "uni")
    ell((0, 0.0, 1.13), (0.27, 0.17, 0.12), UNI, "uni")
    ell((0, 0.0, 0.84), (0.225, 0.165, 0.11), UNI, "uni")
    torus((0, -0.01, 1.255), 0.10, 0.035, UNI, soft="cuff")                     # collar
    def arm(s):
        cap((0.18 * s, 0, 1.15), (0.39 * s, 0, 1.14), 0.098, UNI, "uni", 0.094)
        ell((0.25 * s, 0, 1.17), (0.11, 0.115, 0.10), UNI, "uni")                  # shoulder
        torus((0.395 * s, 0, 1.14), 0.093, 0.028, UNI2, rot=(0, math.pi / 2, 0), soft="cuff")   # rolled cuff
        torus((0.375 * s, 0, 1.14), 0.096, 0.022, UNI2, rot=(0, math.pi / 2, 0), soft="cuff")
    mirror_x(arm)
    def leg(s):
        cap((0.15 * s, 0.0, 0.82), (0.158 * s, -0.015, 0.49), 0.145, UNI, "uni", 0.128)
        cap((0.158 * s, -0.015, 0.49), (0.158 * s, 0.0, 0.29), 0.128, UNI, "uni", 0.122)
        ell((0.158 * s, 0.0, 0.30), (0.135, 0.135, 0.07), UNI, "uni")                # bloused over the boot
        for z, tx in ((0.36, 0.25), (0.42, -0.2), (0.62, 0.15), (0.70, -0.3)):      # cloth folds
            torus((0.158 * s, -0.008, z), 0.115, 0.016, UNI, rot=(tx, 0.15 * s, 0), soft="uni")
        box((0.275 * s, -0.01, 0.64), (0.045, 0.15, 0.17), UNI, bev=0.035)           # cargo pocket
        box((0.297 * s, -0.01, 0.705), (0.02, 0.15, 0.04), UNI, bev=0.012)          # pocket flap
    mirror_x(leg)
    # ---------------- boots
    def boot(s):
        x = 0.158 * s
        box((x, -0.06, 0.035), (0.235, 0.43, 0.07), SOLE, bev=0.03)                 # thick sole
        for k in range(6):                                                           # lugs
            box((x, -0.25 + k * 0.075, 0.005), (0.22, 0.035, 0.02), SOLE, bev=0.008)
        box((x, -0.06, 0.13), (0.22, 0.40, 0.13), BOOT, bev=0.06)                    # upper
        ell((x, -0.17, 0.10), (0.11, 0.12, 0.085), BOOT)                             # toe cap
        cap((x, 0.0, 0.09), (x, 0.0, 0.30), 0.122, BOOT, None, 0.118)                # shaft
        box((x, -0.115, 0.215), (0.07, 0.07, 0.20), BOOT, bev=0.03, rot=(-0.35, 0, 0))   # tongue
        for k in range(4):
            box((x, -0.14 + k * 0.035, 0.15 + k * 0.035), (0.09, 0.012, 0.012), BLACK, bev=0.005, rot=(-0.6, 0, 0))   # laces
        torus((x, 0.0, 0.26), 0.125, 0.018, BLACK, sx=1.0, sy=1.05)                  # ankle strap
        box((x + 0.12 * s, 0.0, 0.26), (0.02, 0.05, 0.04), DARK, bev=0.008)          # strap buckle
    mirror_x(boot)
    # ---------------- knee pads
    def knee(s):
        x = 0.158 * s
        box((x, -0.14, 0.49), (0.18, 0.08, 0.19), DARK, bev=0.05)
        box((x, -0.178, 0.49), (0.13, 0.03, 0.13), BLACK, bev=0.03)
        for sx in (1, -1):
            box((x + 0.1 * sx, -0.06, 0.49), (0.03, 0.12, 0.035), BLACK, bev=0.01)
    mirror_x(knee)
    # ---------------- belt + hip pouches
    torus((0, 0.0, 0.875), 0.235, 0.03, BLACK, sx=1.0, sy=0.74)
    box((0, -0.178, 0.875), (0.09, 0.03, 0.065), DARK, bev=0.012)
    def hip(s):
        box((0.245 * s, -0.04, 0.82), (0.07, 0.14, 0.15), GEAR, bev=0.03)
        box((0.252 * s, -0.04, 0.89), (0.075, 0.145, 0.035), GEAR2, bev=0.014)
        box((0.285 * s, -0.04, 0.855), (0.012, 0.03, 0.05), TEAM, bev=0.005)
        box((0.20 * s, -0.16, 0.81), (0.08, 0.06, 0.12), GEAR2, bev=0.025)          # front utility pouch
    mirror_x(hip)
    # ---------------- plate carrier
    box((0, -0.135, 1.05), (0.43, 0.085, 0.36), GEAR, bev=0.045)                     # front plate bag
    box((0, 0.14, 1.06), (0.43, 0.08, 0.36), GEAR, bev=0.045)                        # back plate bag
    mirror_x(lambda s: box((0.215 * s, 0.0, 0.98), (0.05, 0.27, 0.16), GEAR2, bev=0.02))     # cummerbund sides
    mirror_x(lambda s: box((0.13 * s, 0.0, 1.235), (0.09, 0.30, 0.045), GEAR2, bev=0.018))   # shoulder straps
    for k, x in enumerate((-0.12, 0.0, 0.12)):                                       # 3 mag pouches
        box((x, -0.20, 0.98), (0.11, 0.075, 0.15), GEAR2, bev=0.022)
        box((x, -0.20, 1.055), (0.115, 0.082, 0.035), GEAR, bev=0.014)
        box((x, -0.243, 1.03), (0.03, 0.01, 0.05), BLACK, bev=0.004)                 # flap tab
    box((0, -0.19, 1.16), (0.22, 0.05, 0.10), DARK, bev=0.02)                        # admin panel
    box((-0.06, -0.218, 1.16), (0.06, 0.012, 0.045), TEAM, bev=0.006)                # team tab
    for k in range(2):                                                               # white chevron emblem
        for s in (1, -1):
            box((0.05 + 0.012 * s, -0.218, 1.15 + k * 0.022), (0.03, 0.008, 0.008), WHITE, bev=0.003, rot=(0, 0.6 * s, 0))
    box((0, 0.235, 1.05), (0.34, 0.15, 0.37), GEAR2, bev=0.06)                       # assault pack
    box((0, 0.315, 1.0), (0.24, 0.05, 0.18), GEAR, bev=0.03)
    box((0, 0.24, 1.25), (0.12, 0.04, 0.03), BLACK, bev=0.01)
    # shoulder team patches (on the outer upper arm, facing front-out)
    for s in (1, -1):
        p = box((0, 0, 0), (0.085, 0.012, 0.06), TEAM, bev=0.008)
        q = Vector((0, -1, 0)).rotation_difference(Vector((0.45 * s, -1, 0.35)).normalized())
        p.data.transform(q.to_matrix().to_4x4()); p.data.transform(Matrix.Translation(Vector((0.28 * s, -0.085, 1.19))))
    # ---------------- gloves (loose grip)
    def glove(s):
        x0 = 0.575
        cyl((x0 * s, 0, 1.14), 0.085, 0.07, DARK, rot=(0, math.pi / 2, 0), bev=0.015)             # cuff
        torus((x0 * s, 0, 1.14), 0.078, 0.012, BLACK, rot=(0, math.pi / 2, 0))
        box(((x0 + 0.07) * s, 0.0, 1.14), (0.13, 0.15, 0.09), DARK, bev=0.04)                      # hand
        box(((x0 + 0.085) * s, 0.0, 1.188), (0.08, 0.12, 0.022), BLACK, bev=0.008)                 # knuckle armour
        for i, y in enumerate((-0.042, -0.014, 0.014, 0.042)):                                      # curled fingers
            r = 0.025 if i < 3 else 0.021
            y *= 1.2
            a = Vector(((x0 + 0.125) * s, y, 1.15)); b = a + Vector((0.032 * s, 0, -0.012)); c = b + Vector((0.008 * s, 0, -0.04))
            tube([a, b, c], r, DARK)
        tube([Vector(((x0 + 0.04) * s, -0.06, 1.13)), Vector(((x0 + 0.08) * s, -0.085, 1.115)), Vector(((x0 + 0.115) * s, -0.075, 1.105))], 0.027, DARK)   # thumb
    mirror_x(glove)

HEAD_SCALE = 1.24; HEAD_PIVOT = Vector((0, -0.01, 1.30))
def build_head_gear():
    n_hard0 = len(HARD)
    skin = [o for o in SOFT["skin"]]
    tree = bvh_of(skin[:2])
    hx, hy, hz = H_HEAD
    # ---------------- face
    def eye(s):
        x = 0.105 * s; z = 1.525
        feat("ell", tree, x, z, (0.058, 0.01, 0.066), EYEW, 0.002)
        feat("ell", tree, x - 0.006 * s, z - 0.004, (0.044, 0.01, 0.058), IRIS, 0.004)
        feat("ell", tree, x - 0.006 * s, z + 0.018, (0.044, 0.01, 0.032), IRIS2, 0.0055)     # darker top of the iris
        feat("ell", tree, x - 0.006 * s, z - 0.002, (0.02, 0.01, 0.03), PUPIL, 0.007)
        feat("ell", tree, x + 0.012 * s, z + 0.022, (0.013, 0.006, 0.014), SHINE, 0.009)
        feat("ell", tree, x - 0.02 * s, z - 0.025, (0.007, 0.004, 0.007), SHINE, 0.009)
        # thick upper lash line, slanted down toward the nose, flick at the outer corner
        pts = []
        for k in range(7):
            t = k / 6.0
            fx = x + (-0.062 + 0.124 * t) * s
            fz = z + 0.052 + 0.016 * math.sin(math.pi * t) - 0.018 * (1 - t)
            loc, nrm = hit(tree, (fx, -2, fz), (0, 1, 0))
            if loc: pts.append(loc + nrm * 0.006)
        pts.append(pts[-1] + Vector((0.022 * s, 0.004, 0.012)))
        tube(pts, 0.0085, LASH, taper=[0.7, 1.0, 1.15, 1.2, 1.2, 1.1, 1.0, 0.4])
        loc, nrm = hit(tree, (x + 0.06 * s, -2, z - 0.02), (0, 1, 0))                         # lower lid hint
        # brow: thick, angled down toward the centre
        bp = []
        for k in range(5):
            t = k / 4.0
            fx = x + (-0.07 + 0.13 * t) * s
            fz = z + 0.10 - 0.025 * (1 - t) + 0.008 * math.sin(math.pi * t)
            loc, nrm = hit(tree, (fx, -2, fz), (0, 1, 0))
            if loc: bp.append(loc + nrm * 0.006)
        tube(bp, 0.012, HAIR, taper=[1.0, 1.15, 1.1, 0.9, 0.55])
        feat("ell", tree, 0.17 * s, 1.445, (0.04, 0.006, 0.022), SKIN2, 0.0015)             # blush
    mirror_x(eye)
    feat("ell", tree, 0.0, 1.46, (0.016, 0.014, 0.012), SKIN, 0.0)                           # nose
    mp = []
    for k in range(5):                                                                       # small frown
        t = k / 4.0; fx = -0.03 + 0.06 * t; fz = 1.395 + 0.008 * math.sin(math.pi * t)
        loc, nrm = hit(tree, (fx, -2, fz), (0, 1, 0))
        if loc: mp.append(loc + nrm * 0.003)
    tube(mp, 0.0045, LASH)
    b = feat("box", tree, -0.16, 1.45, (0.075, 0.008, 0.032), BAND, 0.002, spin=0.5)       # cheek bandage
    for k in (-1, 1):
        feat("box", tree, -0.16 + 0.025 * k * math.cos(0.5), 1.45 + 0.025 * k * math.sin(0.5), (0.006, 0.006, 0.026), (BAND), 0.005, spin=0.5)
    # ---------------- hair: fringe spikes under the helmet, sideburns, back
    for i in range(11):                                       # fringe: spikes lying on the forehead
        t = i / 10.0; fx = -0.21 + 0.42 * t
        top, n1 = hit(tree, (fx * 1.05, -2, 1.71), (0, 1, 0)); bot, n2 = hit(tree, (fx, -2, 1.615 + 0.012 * math.cos(t * 9) - 0.01 * random.random()), (0, 1, 0))
        if top is None or bot is None: continue
        mid = (top + bot) / 2 + (n1 + n2).normalized() * 0.018
        tube([top + n1 * 0.012, mid, bot + n2 * 0.006], 0.026, HAIR, taper=[1.0, 0.75, 0.15])
    mirror_x(lambda s: cap((0.285 * s, -0.06, 1.66), (0.27 * s, -0.08, 1.50), 0.035, HAIR, None, 0.012))
    ell((0, 0.04, 1.58), (0.29, 0.26, 0.27), HAIR)        # back of the hair (inside the helmet / behind)
    # ---------------- helmet: high-cut shell, rim, pads, rails, NVG mount, patches
    shell = ell((0, -0.005, 1.66), (0.355, 0.365, 0.33), HELM, seg=48, rings=32)
    cut(shell, (0, -0.12, 1.60), (0.0, -0.35, -1.0))        # high cut: higher at the front
    sol = shell.modifiers.new("s", "SOLIDIFY"); sol.thickness = 0.025
    bpy.context.view_layer.objects.active = shell; bpy.ops.object.modifier_apply(modifier="s")
    st = bvh_of([shell])
    hc = Vector((0, -0.005, 1.66))
    pads = [(0.0, 1.02, 0.17, 0.13), (-0.95, 0.95, 0.16, 0.14), (0.95, 0.95, 0.16, 0.14), (-2.2, 0.9, 0.16, 0.14), (2.2, 0.9, 0.16, 0.14),
            (3.14, 0.95, 0.19, 0.15), (0.0, 1.55, 0.2, 0.15)]
    for az, el, w, h in pads:
        d = Vector((math.sin(az) * math.cos(el - 0.6), -math.cos(az) * math.cos(el - 0.6), math.sin(el - 0.6) + 0.35)).normalized()
        loc, nrm = hit(st, hc + d * 2.0, -d)
        if loc is None: continue
        p = box((0, 0, 0), (w, 0.04, h), GEAR2, bev=0.018)
        box_detail = box((0, 0, 0), (w * 0.6, 0.012, h * 0.5), GEAR, bev=0.005); onto(box_detail, loc, nrm, 0.034)
        onto(p, loc, nrm, 0.012, spin=az * 0.0)
    for s in (1, -1):                                                                        # side rails + rail clamps
        pts = []
        for k in range(6):
            az = math.pi / 2 * s + (-0.9 + 1.8 * k / 5.0) * s
            d = Vector((math.sin(az), -math.cos(az), 0.18)).normalized()
            loc, nrm = hit(st, hc + d * 2.0, -d)
            if loc: pts.append(loc + nrm * 0.015)
        tube(pts, 0.016, BLACK)
        for pp in pts[1:-1:2]:
            box(pp, (0.035, 0.035, 0.035), DARK, bev=0.01)
        d = Vector((s, 0.25, 0.25)).normalized(); loc, nrm = hit(st, hc + d * 2, -d)
        if loc: onto(box((0, 0, 0), (0.06, 0.03, 0.05), TEAM, bev=0.01), loc, nrm, 0.02)  # team patch on the side
    d = Vector((0, -0.75, 0.66)).normalized(); loc, nrm = hit(st, hc + d * 2, -d)
    if loc:
        onto(box((0, 0, 0), (0.11, 0.05, 0.09), BLACK, bev=0.02), loc, nrm, 0.02)           # NVG shroud
        onto(box((0, 0, 0), (0.06, 0.02, 0.05), DARK, bev=0.008), loc, nrm, 0.05)
    d = Vector((-0.3, 0.1, 1.0)).normalized(); loc, nrm = hit(st, hc + d * 2, -d)
    if loc: onto(box((0, 0, 0), (0.12, 0.012, 0.08), DARK, bev=0.01), loc, nrm, 0.008)    # velcro
    # goggles resting on the front of the helmet: smoked band + black frame + strap
    gz = 1.715
    lens = cyl((0, hc.y, gz), 0.37, 0.068, LENS, verts=64)
    cut(lens, (0, hc.y - 0.20, 0), (0, 1, 0))
    inner = cyl((0, hc.y, gz), 0.355, 0.2, LENS, verts=64)
    bpy.context.view_layer.objects.active = lens
    bm = lens.modifiers.new("x", "BOOLEAN"); bm.object = inner; bm.operation = "DIFFERENCE"
    bpy.ops.object.modifier_apply(modifier="x")
    HARD.remove(inner); bpy.data.objects.remove(inner, do_unlink=True)
    for dz in (0.047, -0.047):
        r = torus((0, hc.y, gz + dz * 0.78), 0.372, 0.010, BLACK, sx=1, sy=1)
        cut(r, (0, hc.y - 0.20, 0), (0, 1, 0))
    for s in (1, -1):
        box((0.30 * s, hc.y - 0.215, gz), (0.05, 0.05, 0.11), BLACK, bev=0.02, rot=(0, 0, 0.62 * s))
    strap = torus((0, hc.y + 0.02, gz + 0.01), 0.356, 0.009, BLACK, sy=1.02)
    cut(strap, (0, hc.y - 0.18, 0), (0, -1, 0))
    # headset
    def cupf(s):
        cyl((0.305 * s, -0.02, 1.53), 0.105, 0.075, HELM, rot=(0, math.pi / 2, 0), bev=0.02)
        cyl((0.35 * s, -0.02, 1.53), 0.085, 0.02, GEAR2, rot=(0, math.pi / 2, 0), bev=0.006)
        box((0.362 * s, -0.02, 1.53), (0.012, 0.07, 0.03), TEAM, bev=0.004)
        tube([Vector((0.3 * s, -0.02, 1.62)), Vector((0.31 * s, -0.02, 1.70))], 0.02, BLACK)
    mirror_x(cupf)
    tube([Vector((-0.30, -0.08, 1.48)), Vector((-0.22, -0.20, 1.42)), Vector((-0.10, -0.27, 1.40))], 0.009, BLACK)   # mic boom
    ell((-0.085, -0.272, 1.40), (0.02, 0.02, 0.02), BLACK)
    # chibi head: scale the whole head (skin, face, hair, helmet, goggles, headset) up around the neck
    M = Matrix.Translation(HEAD_PIVOT) @ Matrix.Scale(HEAD_SCALE, 4) @ Matrix.Translation(-HEAD_PIVOT)
    for o in HARD[n_hard0:] + skin[:2]:
        o.data.transform(M); o.data.update()

# ================================================================== assemble
def fuse(group, voxel, smooth_iter, target):
    objs = SOFT[group]
    for x in bpy.context.selected_objects: x.select_set(False)
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    o = bpy.context.active_object
    mats = [m for m in o.data.materials]
    md = o.modifiers.new("r", "REMESH"); md.mode = "VOXEL"; md.voxel_size = voxel; md.use_smooth_shade = True
    bpy.ops.object.modifier_apply(modifier="r")
    md = o.modifiers.new("l", "LAPLACIANSMOOTH"); md.iterations = smooth_iter; md.lambda_factor = 0.8; md.use_volume_preserve = True
    bpy.ops.object.modifier_apply(modifier="l")
    if len(o.data.polygons) > target:
        md = o.modifiers.new("d", "DECIMATE"); md.ratio = target / len(o.data.polygons)
        bpy.ops.object.modifier_apply(modifier="d")
    o.data.materials.clear(); o.data.materials.append(mats[0])
    for p in o.data.polygons: p.use_smooth = True
    return o

build_rookie()
# the face needs the head surface before it is fused: place features on the raw head + cheek ellipsoids
build_head_gear()
fused = [fuse("skin", 0.006, 4, 30000), fuse("uni", 0.008, 6, 45000), fuse("cuff", 0.006, 3, 8000)]
allo = fused + HARD
for x in bpy.context.selected_objects: x.select_set(False)
for o in allo: o.select_set(True)
bpy.context.view_layer.objects.active = allo[0]
bpy.ops.object.join()
body = bpy.context.active_object; body.name = "Mini_" + CLASS
me = body.data
BELT = 0.86; K = 0.80
for v in me.vertices:
    v.co.z = v.co.z * K if v.co.z < BELT else v.co.z - BELT * (1 - K)
me.update()
print("faces", len(me.polygons), "verts", len(me.vertices))

# ------------------------------------------------------------------ baked shading in vertex colours: AO + cavity + fabric noise
tree = BVHTree.FromObject(body, bpy.context.evaluated_depsgraph_get())
me.calc_normals_split() if hasattr(me, "calc_normals_split") else None
dirs = []
for i in range(14):
    z = 1 - (i + 0.5) / 14; r = math.sqrt(max(0, 1 - z * z)); a = i * 2.39996
    dirs.append(Vector((r * math.cos(a), r * math.sin(a), z)))
ao = [0.0] * len(me.vertices)
for v in me.vertices:
    n = v.normal; q = Vector((0, 0, 1)).rotation_difference(n)
    o0 = v.co + n * 0.003; occ = 0.0
    for d in dirs:
        dd = q @ d
        h = tree.ray_cast(o0, dd, 0.12)
        if h[0] is not None: occ += (1.0 - h[3] / 0.12) * d.z
    ao[v.index] = occ / sum(d.z for d in dirs)
cav = [0.0] * len(me.vertices); cnt = [0] * len(me.vertices)
for e in me.edges:
    a, b = e.vertices; va, vb = me.vertices[a], me.vertices[b]
    d = (vb.co - va.co); L = d.length
    if L < 1e-6: continue
    d /= L
    cav[a] += va.normal.dot(d); cav[b] += vb.normal.dot(-d); cnt[a] += 1; cnt[b] += 1
for i in range(len(cav)): cav[i] = cav[i] / max(cnt[i], 1)
col = me.color_attributes.new("Col", "BYTE_COLOR", "POINT")
fac = [1.0] * len(me.vertices)
mat_of = {}
for p in me.polygons:
    for vi in p.vertices: mat_of[vi] = me.materials[p.material_index].name
for v in me.vertices:
    a = ao[v.index]; c = cav[v.index]
    f = (1.0 - 0.75 * min(1.0, a)) * (1.0 - 0.9 * max(0.0, c)) * (1.0 + 0.35 * max(0.0, -c))
    mn = mat_of.get(v.index, "")
    if mn in ("R_Uniform", "R_Sleeve", "R_Gear", "R_Gear2"):              # fabric: coarse mottling + fine weave noise
        f *= 0.9 + 0.12 * noise.noise(v.co * 9.0) + 0.05 * noise.noise(v.co * 90.0)
    if mn in ("R_Boot", "R_Sole", "R_Uniform") and v.co.z < 0.4:             # dust low down
        f *= 0.85 + 0.15 * min(1.0, v.co.z / 0.4)
    if mn in ("R_EyeWhite", "R_Iris", "R_IrisDark", "R_Pupil", "R_Shine", "R_Lash", "R_Skin", "R_Blush"):
        f = max(f, 0.92) if mn != "R_Skin" else 0.55 + 0.45 * f
    fac[v.index] = max(0.12, min(1.0, f))
nbr = [[] for _ in me.vertices]
for e in me.edges:
    a, b = e.vertices; nbr[a].append(b); nbr[b].append(a)
skinv = [i for i in range(len(fac)) if mat_of.get(i, "") == "R_Skin"]
for it in range(6):                                  # skin: soft, even shading (no blotches)
    new = {i: (fac[i] + sum(fac[j] for j in nbr[i])) / (1 + len(nbr[i])) for i in skinv}
    for i, f in new.items(): fac[i] = f
for i in skinv: fac[i] = 0.82 + 0.18 * fac[i]
for i, f in enumerate(fac):
    col.data[i].color = (f, f, f, 1.0)
me.color_attributes.active_color = col
bpy.ops.wm.save_as_mainfile(filepath="%s/%s.blend" % (OUTDIR, CLASS))
print("SAVED", len(me.polygons))
