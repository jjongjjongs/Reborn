# Runs INSIDE Blender (blender-mcp). v3: all Mini Soldier characters (STYLE = soldier / swat / zombie): a chunky,
# big-headed toy soldier built from primitives around the SWAT armature (same
# bones, so the game's retargeted animations, hand IK and tinting work as is).
# Every part is rigidly weighted to one bone (low-poly toy look).
# Materials reuse the SWAT colours so Soldier._team_tint recolours them:
#   Swat (gear grey) = uniform -> team / suit colour, Swat_Black = vest + helmet -> kit colour.
# Head gear variants are separate meshes: Gear_Helmet, Gear_Beret, Gear_Mask.
import bpy, bmesh, math
from mathutils import Vector, Matrix

SWAT = "/home/user/Reborn/game/assets/soldier/Swat.glb"
STYLE = globals().get("STYLE", "soldier")      # soldier / swat / zombie
OUT = "/home/user/Reborn/game/assets/soldier/%s.glb" % {"soldier": "MiniV3", "swat": "MiniSwat", "zombie": "MiniZombie"}[STYLE]

for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
for m in list(bpy.data.meshes): bpy.data.meshes.remove(m)
bpy.ops.import_scene.gltf(filepath=SWAT)
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
for o in list(bpy.data.objects):
    if o.type == "MESH": bpy.data.objects.remove(o, do_unlink=True)

def mat(name, col, rough=0.8):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = col; b.inputs["Roughness"].default_value = rough
    return m
UNIFORM = mat("Swat", (0.078, 0.087, 0.102, 1))        # -> suit colour in game
KIT = mat("Swat_Black", (0.031, 0.027, 0.024, 1))      # -> helmet / vest colour in game
SKIN = mat("Skin", (0.42, 0.25, 0.15, 1))
VISOR = mat("Visor", (0.008, 0.008, 0.008, 1), 0.2)
LENS = mat("Lens", (0.9, 0.35, 0.05, 1), 0.15)
BOOT = mat("Boot", (0.012, 0.012, 0.014, 1))
BADGE = mat("Badge", (0.9, 0.7, 0.1, 1), 0.4)

parts = {}   # mesh name -> list of (object)
soft = []    # (object, chain points, chain bones): weights blended along the chain (smooth joints)

def _smoothstep(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a))); return t * t * (3 - 2 * t)

def tube(pts, radii, material, group="Mini_Body", segs=14, step=0.025, ell=None, caps=True, cap0=1.0, cap1=1.0):
    """a continuous rounded tube through pts (radius per point; ell = per-point (rx, ry) for oval
    cross sections, x = world X, y = world Y). Many rings -> bends smoothly when skinned."""
    pts = [Vector(p) for p in pts]
    samples = []   # (pos, dir, rx, ry)
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]; L = (b - a).length; n = max(2, int(L / step))
        for k in range(n + (1 if i == len(pts) - 2 else 0)):
            t = k / n
            ra = ell[i] if ell else (radii[i], radii[i]); rb = ell[i + 1] if ell else (radii[i + 1], radii[i + 1])
            samples.append((a.lerp(b, t), (b - a).normalized(), ra[0] + (rb[0] - ra[0]) * t, ra[1] + (rb[1] - ra[1]) * t))
    verts = []; faces = []
    def ring(pos, d, rx, ry):
        up = Vector((0, 0, 1)) if abs(d.z) < 0.9 else Vector((0, -1, 0))
        x = d.cross(up).normalized(); y = d.cross(x).normalized()
        if abs(d.z) >= 0.9: x, y = Vector((1, 0, 0)), Vector((0, 1, 0))   # spine: keep oval axes on X / Y
        base = len(verts)
        for k in range(segs):
            a = 2 * math.pi * k / segs
            verts.append(pos + x * math.cos(a) * rx + y * math.sin(a) * ry)
        return base
    rings = []
    if caps:   # rounded start cap
        p0, d0, rx0, ry0 = samples[0]
        for k in (3, 2, 1):
            f = math.cos(k * math.pi / 8)
            rings.append(ring(p0 - d0 * rx0 * math.sin(k * math.pi / 8) * 0.9 * cap0, d0, rx0 * f, ry0 * f))
    for sp in samples: rings.append(ring(*sp))
    if caps:
        p1, d1, rx1, ry1 = samples[-1]
        for k in (1, 2, 3):
            f = math.cos(k * math.pi / 8)
            rings.append(ring(p1 + d1 * rx1 * math.sin(k * math.pi / 8) * 0.9 * cap1, d1, rx1 * f, ry1 * f))
    for r in range(len(rings) - 1):
        for k in range(segs):
            a = rings[r] + k; b = rings[r] + (k + 1) % segs
            c = rings[r + 1] + (k + 1) % segs; d = rings[r + 1] + k
            faces.append((a, b, c, d))
    me = bpy.data.meshes.new("tube"); me.from_pydata([tuple(v) for v in verts], [], faces); me.update()
    o = bpy.data.objects.new("tube", me); bpy.context.scene.collection.objects.link(o)
    o.data.materials.append(material)
    for poly in o.data.polygons: poly.use_smooth = True
    parts.setdefault(group, []).append(o)
    return o

def chain_weights(o, pts, bones, blend=0.07):
    """weight each vertex along a bone chain: segment i -> bones[i], blended across joints."""
    pts = [Vector(p) for p in pts]
    acc = [0.0]
    for i in range(len(pts) - 1): acc.append(acc[-1] + (pts[i + 1] - pts[i]).length)
    vgs = {b: (o.vertex_groups.get(b) or o.vertex_groups.new(name=b)) for b in bones}
    for v in o.data.vertices:
        p = o.matrix_world @ v.co
        best = (1e9, 0.0)
        for i in range(len(pts) - 1):
            a, b = pts[i], pts[i + 1]; ab = b - a
            t = max(0.0, min(1.0, (p - a).dot(ab) / ab.length_squared))
            d = (a + ab * t - p).length
            if d < best[0]: best = (d, acc[i] + t * ab.length)
        sv = best[1]
        w = [0.0] * len(bones)
        w[0] = 1.0
        for j in range(1, len(bones)):          # joint j sits at acc[j]
            k = _smoothstep(acc[j] - blend, acc[j] + blend, sv)
            for q in range(j): w[q] *= (1 - k)
            w[j] = k
        tot = sum(w) or 1.0
        for j, b in enumerate(bones):
            if w[j] / tot > 0.001: vgs[b].add([v.index], w[j] / tot, "REPLACE")
def _finish(o, material, bone, group, smooth=True):
    o.data.materials.clear(); o.data.materials.append(material)
    for p in o.data.polygons: p.use_smooth = smooth
    o.data.use_auto_smooth = True; o.data.auto_smooth_angle = math.radians(40)   # round surfaces smooth, box edges crisp
    vg = o.vertex_groups.new(name=bone); vg.add(list(range(len(o.data.vertices))), 1.0, "REPLACE")
    parts.setdefault(group, []).append(o)
    return o

def ellipsoid(c, r, material, bone, group="Mini_Body", seg=18, rings=10, rot=None):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, location=c)
    o = bpy.context.active_object; o.scale = r
    if rot: o.rotation_euler = rot
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return _finish(o, material, bone, group)

def limb(a, b, r, material, bone, group="Mini_Body"):
    a, b = Vector(a), Vector(b)
    d = b - a; L = d.length
    bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6, location=(a + b) / 2)
    o = bpy.context.active_object
    o.scale = (r, r, L / 2 + r * 0.55)
    o.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return _finish(o, material, bone, group)

def rbox(c, s, material, bone, group="Mini_Body", bevel=0.03):
    bpy.ops.mesh.primitive_cube_add(size=1, location=c)
    o = bpy.context.active_object; o.scale = s
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    md = o.modifiers.new("b", "BEVEL"); md.width = bevel; md.segments = 3
    bpy.ops.object.modifier_apply(modifier="b")
    return _finish(o, material, bone, group)

def cyl(c, r, depth, material, bone, group="Mini_Body", rot=(0, 0, 0), verts=20):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=c, rotation=rot)
    o = bpy.context.active_object
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return _finish(o, material, bone, group)

def dome(c, r, cut_z, material, bone, group):
    o = ellipsoid(c, r, material, bone, group, seg=24, rings=14)
    bm = bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=(0, 0, cut_z - c[2]), plane_no=(0, 0, 1), clear_inner=True)
    bm.to_mesh(o.data); bm.free()
    return o


# ================================================================ v4 "mini": clean toy proportions
# a big round head (helmet ≈ a third of the height), smooth bean body with a fitted
# vest, mitts and chunky boots. Every part is placed by hand (no blanket scaling).
WHITE = mat("EyeWhite", (0.95, 0.95, 0.95, 1), 0.25)
EYE = mat("Eye", (0.012, 0.010, 0.012, 1), 0.08)
CHEEK = mat("Cheek", (0.62, 0.20, 0.15, 1))
BROW = mat("Brow", (0.06, 0.035, 0.02, 1))
MOUTH = mat("Mouth", (0.18, 0.04, 0.04, 1))
HC = 1.80                       # head centre
HR = (0.290, 0.278, 0.302)      # head radii
FY = -0.0135                    # head centre y
if STYLE == "zombie":
    SKIN = mat("ZSkin", (0.25, 0.42, 0.18, 1))
    UNIFORM = mat("ZShirt", (0.05, 0.20, 0.08, 1))
    PANTS = mat("ZPants", (0.20, 0.12, 0.06, 1))
    KIT = mat("ZRag", (0.30, 0.24, 0.16, 1))
    BANDAGE = mat("Bandage", (0.55, 0.50, 0.36, 1), 0.95)
    SHOE = mat("ZShoe", (0.45, 0.05, 0.04, 1), 0.7)
    STAIN = mat("ZStain", (0.02, 0.09, 0.03, 1))
    ROPE = mat("Rope", (0.33, 0.22, 0.09, 1), 0.95)
else:
    PANTS = UNIFORM

def ring(c, rx, ry, minor, material, bone, group="Mini_Body"):
    bpy.ops.mesh.primitive_torus_add(major_radius=1.0, minor_radius=minor / max(rx, ry), major_segments=36, minor_segments=10, location=c)
    o = bpy.context.active_object; o.scale = (rx, ry, max(rx, ry))
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return _finish(o, material, bone, group)

def smile(c, w, material, bone, group="Mini_Body"):
    """a small curved mouth: the lower half of a thin torus facing forward."""
    bpy.ops.mesh.primitive_torus_add(major_radius=w, minor_radius=w * 0.22, major_segments=24, minor_segments=8, location=c, rotation=(math.pi / 2, 0, 0))
    o = bpy.context.active_object
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bm = bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=(0, 0, 0.0), plane_no=(0, 0, 1), clear_outer=True)
    bm.to_mesh(o.data); bm.free()
    return _finish(o, material, bone, group)

def surf_y(x, z):
    """y of the head's front surface at (x, z) (so features sit on it, not inside)."""
    t = 1.0 - (x / HR[0]) ** 2 - ((z - HC) / HR[2]) ** 2
    return FY - HR[1] * math.sqrt(max(0.0, t))

def head(kind="cute", mouth=True, face=True):
    ellipsoid((0, FY, HC), HR, SKIN, "Head", seg=32, rings=18)
    for s in (1, -1):
        ellipsoid((0.283 * s, -0.005, HC - 0.02), (0.045, 0.04, 0.065), SKIN, "Head")
    cyl((0, -0.035, 1.555), 0.092, 0.12, SKIN, "Neck")
    if kind == "zombie":
        return zombie_face()
    if not face: return
    for s in (1, -1):
        x = 0.098 * s; z = HC - 0.01
        ellipsoid((x, surf_y(x, z) + 0.006, z), (0.042, 0.018, 0.058), EYE, "Head")                    # glossy eye
        ellipsoid((x + 0.014 * s, surf_y(x, z) - 0.009, z + 0.022), (0.013, 0.006, 0.013), WHITE, "Head")   # sparkle
        ellipsoid((x - 0.012 * s, surf_y(x, z) - 0.008, z - 0.024), (0.006, 0.004, 0.006), WHITE, "Head")
        xb = 0.102 * s; zb = HC + 0.078
        rbox((xb, surf_y(xb, zb) + 0.004, zb), (0.062, 0.016, 0.013), BROW, "Head", bevel=0.006)            # brow
        xc = 0.172 * s; zc = HC - 0.075
        ellipsoid((xc, surf_y(xc, zc) + 0.008, zc), (0.04, 0.012, 0.024), CHEEK, "Head")                     # cheek
    ellipsoid((0, surf_y(0, HC - 0.055) - 0.004, HC - 0.055), (0.021, 0.016, 0.017), SKIN, "Head")        # nose
    if mouth: smile((0, surf_y(0, HC - 0.112) - 0.002, HC - 0.112), 0.032, MOUTH, "Head")

def zombie_face():
    x, z = 0.10, HC + 0.005
    ellipsoid((x, surf_y(x, z) + 0.01, z), (0.062, 0.02, 0.07), WHITE, "Head")                              # big round eye
    ellipsoid((x + 0.006, surf_y(x, z) - 0.008, z - 0.008), (0.02, 0.008, 0.02), EYE, "Head")
    x2 = -0.10
    ellipsoid((x2, surf_y(x2, z) + 0.008, z - 0.01), (0.045, 0.016, 0.022), WHITE, "Head")                  # squint
    ellipsoid((x2, surf_y(x2, z) - 0.002, z - 0.012), (0.014, 0.008, 0.01), EYE, "Head")
    zm = HC - 0.12
    ellipsoid((0, surf_y(0, zm) + 0.01, zm), (0.085, 0.03, 0.055), MOUTH, "Head")                            # open mouth
    for xt in (-0.035, 0.0, 0.035):
        rbox((xt, surf_y(xt, zm + 0.035) - 0.004, zm + 0.03), (0.026, 0.012, 0.03), WHITE, "Head", bevel=0.005)
    for k in range(4):                                                                                       # stitched scar
        xs = -0.17 + k * 0.03
        rbox((xs, surf_y(xs, HC + 0.13) - 0.002, HC + 0.13), (0.008, 0.012, 0.05), BROW, "Head", bevel=0.003)
    rbox((-0.125, surf_y(-0.125, HC + 0.13) - 0.003, HC + 0.13), (0.11, 0.01, 0.008), BROW, "Head", bevel=0.003)
    PATCH = mat("ZPatch", (0.14, 0.28, 0.10, 1))
    for (px, pz, r) in ((0.17, HC - 0.06, 0.05), (-0.20, HC + 0.08, 0.04), (0.05, HC + 0.2, 0.035)):
        ellipsoid((px, surf_y(px, pz) + 0.012, pz), (r, 0.015, r * 0.8), PATCH, "Head")
    BRAIN = mat("Brain", (0.80, 0.32, 0.42, 1), 0.5)
    for (bx, by, bz, r) in ((0.06, 0.02, HC + 0.275, 0.085), (0.13, 0.04, HC + 0.25, 0.065), (0.02, 0.08, HC + 0.26, 0.06)):
        ellipsoid((bx, by, bz), (r, r * 0.9, r * 0.7), BRAIN, "Head")

def helmet(group, goggles=True):
    dome((0, 0.005, HC + 0.075), (0.33, 0.34, 0.30), HC + 0.055, KIT, "Head", group)
    ring((0, 0.005, HC + 0.057), 0.333, 0.343, 0.025, KIT, "Head", group)                                  # rolled rim
    if goggles:
        ring((0, 0.005, HC + 0.155), 0.312, 0.322, 0.012, BOOT, "Head", group)                             # strap
        for s in (1, -1):
            x = 0.085 * s
            cyl((x, -0.315, HC + 0.16), 0.055, 0.05, BOOT, "Head", group, rot=(math.pi / 2, 0, 0), verts=24)
            cyl((x, -0.342, HC + 0.16), 0.042, 0.012, LENS, "Head", group, rot=(math.pi / 2, 0, 0), verts=24)

def body(vest=True, backpack=True, pouches=2):
    SPINE = [(0, -0.05, 0.90), (0, -0.05, 0.98), (0, -0.045, 1.15), (0, -0.04, 1.36), (0, -0.04, 1.48)]
    o = tube(SPINE, None, UNIFORM, ell=[(0.205, 0.145), (0.215, 0.16), (0.22, 0.165), (0.212, 0.152), (0.15, 0.11)], segs=24, cap0=0.3)
    soft.append((o, [(0, -0.05, 0.894), (0, -0.045, 0.999), (0, -0.045, 1.161), (0, -0.04, 1.377), (0, -0.04, 1.511)], ["Hips", "Abdomen", "Torso", "Chest"]))
    if vest:   # fitted plate carrier: a short oval tube hugging the torso, bends with it
        o = tube([(0, -0.05, 1.07), (0, -0.045, 1.20), (0, -0.04, 1.36), (0, -0.04, 1.46)], None, KIT,
                 ell=[(0.232, 0.180), (0.240, 0.186), (0.234, 0.172), (0.20, 0.145)], segs=24)
        soft.append((o, [(0, -0.045, 0.999), (0, -0.045, 1.161), (0, -0.04, 1.377), (0, -0.04, 1.511)], ["Abdomen", "Torso", "Chest"]))
        for x in ((-0.075, 0.075) if pouches == 2 else (0.0,)):
            rbox((x, -0.225, 1.16), (0.11, 0.05, 0.10), KIT, "Torso", bevel=0.03)
        rbox((0.12, -0.212, 1.37), (0.075, 0.018, 0.045), BADGE, "Chest", bevel=0.01)
    if backpack:
        rbox((0, 0.185, 1.29), (0.30, 0.13, 0.30), KIT, "Chest", bevel=0.07)
    ring((0, -0.05, 0.935), 0.222, 0.168, 0.03, BOOT, "Hips")                                               # belt
    rbox((0.0, -0.222, 0.935), (0.07, 0.018, 0.05), BADGE, "Hips", bevel=0.012)                              # buckle

def limbs(boots=True, mitts=BOOT, pads=True, bare_arm="", bare_leg="", shoulder=None):
    SHOULDER = shoulder or KIT
    for s_ in (1, -1):
        L = "L" if s_ > 0 else "R"
        apts = [(0.0, -0.06, 1.42), (0.15 * s_, -0.06, 1.42), (0.334 * s_, -0.056, 1.432), (0.568 * s_, -0.086, 1.432)]
        o = tube([(0.13 * s_, -0.058, 1.43), (0.334 * s_, -0.056, 1.432), (0.54 * s_, -0.08, 1.432)], [0.088, 0.075, 0.068], SKIN if bare_arm == L else UNIFORM, segs=18)
        soft.append((o, apts, ["Chest", "UpperArm." + L, "LowerArm." + L]))
        # shoulder pad: rigid on the chest, hides the arm root when the arm swings across
        ellipsoid((0.165 * s_, -0.05, 1.44), (0.095, 0.115, 0.085), SHOULDER, "Chest")
        if bare_arm == L:   # torn short sleeve, bandaged forearm
            o = tube([(0.13 * s_, -0.058, 1.43), (0.37 * s_, -0.058, 1.432)], [0.098, 0.088], UNIFORM, segs=18, cap1=0.2)
            soft.append((o, apts, ["Chest", "UpperArm." + L, "LowerArm." + L]))
            for k, (xx, dz) in enumerate(((0.375, -0.02), (0.405, 0.015), (0.385, 0.03))):
                rbox((xx * s_, -0.06 - 0.03 * (k - 1), 1.432 - 0.078 + dz * 0.3), (0.035, 0.04, 0.03), UNIFORM, "UpperArm." + L, bevel=0.01)
            for xx in (0.45, 0.49):
                cyl((xx * s_, -0.068, 1.432), 0.074, 0.03, BANDAGE, "LowerArm." + L, rot=(0, math.pi / 2, 0.15 * s_), verts=20)
        ellipsoid((0.625 * s_, -0.095, 1.43), (0.088, 0.07, 0.066), mitts, "Hand." + L, seg=20, rings=12)      # mitt
        ellipsoid((0.598 * s_, -0.158, 1.422), (0.034, 0.038, 0.032), mitts, "Hand." + L)                       # thumb
        ring((0.548 * s_, -0.082, 1.432), 0.072, 0.072, 0.018, mitts, "LowerArm." + L) if False else None
        lpts = [(0.121 * s_, -0.045, 1.05), (0.121 * s_, -0.045, 0.964), (0.121 * s_, -0.087, 0.533), (0.121 * s_, -0.062, 0.023)]
        o = tube([(0.112 * s_, -0.05, 0.96), (0.121 * s_, -0.087, 0.533), (0.121 * s_, -0.07, 0.17)], [0.104, 0.09, 0.084], SKIN if bare_leg == L else PANTS, segs=18, cap0=0.5)
        soft.append((o, lpts, ["Hips", "UpperLeg." + L, "LowerLeg." + L]))
        if bare_leg == L:   # trouser leg torn off above the knee
            o = tube([(0.112 * s_, -0.05, 0.96), (0.119 * s_, -0.075, 0.66)], [0.112, 0.10], PANTS, segs=18, cap0=0.5, cap1=0.15)
            soft.append((o, lpts, ["Hips", "UpperLeg." + L, "LowerLeg." + L]))
            for k in range(4):
                a = k * math.pi / 2 + 0.4
                rbox((0.119 * s_ + math.cos(a) * 0.09, -0.075 + math.sin(a) * 0.085, 0.645 - (k % 2) * 0.025), (0.04, 0.04, 0.04), PANTS, "UpperLeg." + L, bevel=0.012)
        if pads: ellipsoid((0.121 * s_, -0.165, 0.535), (0.062, 0.022, 0.068), PANTS, "LowerLeg." + L)
        if boots:
            rbox((0.121 * s_, -0.11, 0.085), (0.19, 0.34, 0.17), BOOT, "Foot." + L, bevel=0.08)
            ring((0.121 * s_, -0.075, 0.195), 0.092, 0.092, 0.03, BOOT, "LowerLeg." + L)                       # boot cuff
        elif bare_leg == L:
            ellipsoid((0.121 * s_, -0.10, 0.06), (0.09, 0.15, 0.065), SKIN, "Foot." + L)
            for t in range(3):
                ellipsoid(((0.121 + (t - 1) * 0.04) * s_, -0.235, 0.05), (0.022, 0.025, 0.022), SKIN, "Foot." + L)   # toes
        else:   # one beaten-up sneaker
            rbox((0.121 * s_, -0.11, 0.075), (0.18, 0.32, 0.14), SHOE, "Foot." + L, bevel=0.06)
            rbox((0.121 * s_, -0.11, 0.022), (0.19, 0.33, 0.045), WHITE, "Foot." + L, bevel=0.02)
            rbox((0.121 * s_, -0.20, 0.13), (0.08, 0.10, 0.02), WHITE, "Foot." + L, bevel=0.008)

if STYLE == "soldier":
    head("cute"); body(); limbs()
    helmet("Gear_Helmet")
    ellipsoid((0.045, 0.0, HC + 0.255), (0.33, 0.33, 0.10), KIT, "Head", "Gear_Beret", seg=28, rings=10, rot=(0.0, -0.2, 0.0))
    ring((0, -0.005, HC + 0.195), 0.29, 0.28, 0.03, KIT, "Head", "Gear_Beret")
    rbox((-0.12, surf_y(-0.12, HC + 0.215) - 0.02, HC + 0.215), (0.06, 0.015, 0.07), BADGE, "Head", "Gear_Beret", 0.012)
    helmet("Gear_Mask", goggles=False)
    ellipsoid((0, -0.135, HC - 0.06), (0.25, 0.17, 0.19), VISOR, "Head", "Gear_Mask", seg=28, rings=14)
    cyl((0, -0.31, HC - 0.12), 0.07, 0.09, KIT, "Head", "Gear_Mask", rot=(math.pi / 2, 0, 0), verts=24)
    cyl((0, -0.36, HC - 0.12), 0.078, 0.025, mat("Filter", (0.25, 0.27, 0.25, 1)), "Head", "Gear_Mask", rot=(math.pi / 2, 0, 0), verts=24)
    for s in (1, -1):
        cyl((0.098 * s, -0.285, HC - 0.005), 0.052, 0.025, LENS, "Head", "Gear_Mask", rot=(math.pi / 2, 0, 0), verts=24)
elif STYLE == "swat":
    head("cute", face=False)
    # black balaclava over the head with an eye opening (skin patch), helmet with the visor flipped up
    BALA = mat("Balaclava", (0.012, 0.012, 0.014, 1), 0.9)
    ellipsoid((0, FY + 0.004, HC - 0.02), (0.296, 0.284, 0.30), BALA, "Head", "Gear_Helmet", seg=32, rings=18)
    BR = (0.268, 0.292, 0.062); BZ = HC - 0.025                                                               # eye slit (front half only)
    o = ellipsoid((0, FY - 0.002, BZ), BR, SKIN, "Head", "Gear_Helmet", seg=32, rings=12)
    bm = bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=(0, -0.10 - (FY - 0.002), 0), plane_no=(0, 1, 0), clear_outer=True)
    bm.to_mesh(o.data); bm.free()
    def slit_y(x): return FY - 0.002 - BR[1] * math.sqrt(max(0.0, 1 - (x / BR[0]) ** 2))
    for s in (1, -1):
        x = 0.092 * s
        ellipsoid((x, slit_y(x) + 0.004, BZ), (0.036, 0.014, 0.042), EYE, "Head", "Gear_Helmet")
        ellipsoid((x + 0.012 * s, slit_y(x) - 0.009, BZ + 0.016), (0.011, 0.005, 0.011), WHITE, "Head", "Gear_Helmet")
        xb = 0.10 * s
        rbox((xb, slit_y(xb) + 0.002, BZ + 0.05), (0.06, 0.014, 0.012), BROW, "Head", "Gear_Helmet", bevel=0.005)
    dome((0, 0.0, HC + 0.08), (0.34, 0.35, 0.31), HC + 0.06, KIT, "Head", "Gear_Helmet")
    ring((0, 0.0, HC + 0.062), 0.343, 0.353, 0.026, KIT, "Head", "Gear_Helmet")
    VIS = mat("Visor2", (0.04, 0.06, 0.08, 1), 0.05)
    ellipsoid((0, -0.19, HC + 0.27), (0.25, 0.09, 0.06), VIS, "Head", "Gear_Helmet", seg=28, rings=10, rot=(-0.55, 0, 0))   # visor up
    body(vest=True, backpack=False, pouches=1)
    rbox((0, 0.137, 1.22), (0.17, 0.012, 0.05), WHITE, "Torso", bevel=0.008)                                   # SWAT band (back)
    rbox((-0.12, -0.212, 1.37), (0.06, 0.03, 0.08), KIT, "Chest", bevel=0.015)                                  # radio
    limbs()
else:
    head("zombie")
    body(vest=False, backpack=False)
    for k in range(6):   # ragged shirt hem
        rbox((-0.19 + k * 0.076, -0.17 + abs(k - 2.5) * 0.004, 0.865 - (k % 2) * 0.02), (0.07, 0.05, 0.07), UNIFORM, "Hips", bevel=0.015)
    o = tube([(0, -0.05, 0.875), (0, -0.05, 0.955)], None, PANTS, ell=[(0.205, 0.147), (0.214, 0.158)], segs=24, cap0=0.3, cap1=0.2)   # trouser seat
    soft.append((o, [(0, -0.05, 0.85), (0, -0.05, 0.98)], ["Hips"]))
    # torn hole with ribs showing
    ellipsoid((0.09, -0.198, 1.17), (0.065, 0.02, 0.055), mat("ZDark", (0.10, 0.20, 0.07, 1)), "Torso")
    for k in range(3):
        rbox((0.09, -0.214, 1.135 + k * 0.032), (0.085 - abs(k - 1) * 0.02, 0.012, 0.012), WHITE, "Torso", bevel=0.005)
    for (sx, sz, r) in ((-0.10, 1.05, 0.05), (-0.04, 1.27, 0.035), (0.15, 1.03, 0.03)):                     # stains
        ellipsoid((sx, -0.05 - 0.163 * math.sqrt(max(0.0, 1 - (sx / 0.218) ** 2)) - 0.004, sz), (r, 0.01, r * 0.8), STAIN, "Torso")
    ring((0, -0.045, 1.49), 0.155, 0.12, 0.028, UNIFORM, "Chest")                                               # stretched collar
    ring((0, -0.05, 0.94), 0.222, 0.168, 0.018, ROPE, "Hips")                                                   # rope belt
    rbox((-0.13, -0.215, 0.925), (0.035, 0.03, 0.06), ROPE, "Hips", bevel=0.012)                                # knot
    for (px, pz, r) in ((0.30, 1.505, 0.035), (-0.50, 1.497, 0.03)):                                              # rot patches on arms
        ellipsoid((px, -0.07, pz), (r, r * 0.8, 0.014), mat("ZPatch2", (0.14, 0.28, 0.10, 1)), "UpperArm.L" if px > 0 else "LowerArm.R")
    limbs(boots=False, mitts=SKIN, pads=False, bare_arm="L", bare_leg="R", shoulder=UNIFORM)

for o, pts, bones in soft:
    chain_weights(o, pts, bones)

# ---- join per group, skin to the armature ----
made = []
for name, objs in parts.items():
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    o = bpy.context.active_object; o.name = name; o.data.name = name
    mw = o.matrix_world.copy()
    o.parent = arm
    o.matrix_world = mw                       # keep the world placement under the armature
    md = o.modifiers.new("Armature", "ARMATURE"); md.object = arm
    made.append(o)
bpy.ops.object.select_all(action="DESELECT")
arm.select_set(True)
for o in made: o.select_set(True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_skins=True,
    export_animations=False, export_materials="EXPORT", export_cameras=False, export_lights=False)
print("mini", [(o.name, len(o.data.vertices)) for o in made], "arm", arm.matrix_world.to_scale(), arm.parent.name if arm.parent else "-")

