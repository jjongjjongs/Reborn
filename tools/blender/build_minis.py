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
OUT = "/home/user/Reborn/game/assets/soldier/%s.glb" % {"soldier": "Mini", "swat": "MiniSwat", "zombie": "MiniZombie"}[STYLE]

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

def tube(pts, radii, material, group="Mini_Body", segs=14, step=0.025, ell=None, caps=True):
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
            rings.append(ring(p0 - d0 * rx0 * math.sin(k * math.pi / 8) * 0.9, d0, rx0 * f, ry0 * f))
    for sp in samples: rings.append(ring(*sp))
    if caps:
        p1, d1, rx1, ry1 = samples[-1]
        for k in (1, 2, 3):
            f = math.cos(k * math.pi / 8)
            rings.append(ring(p1 + d1 * rx1 * math.sin(k * math.pi / 8) * 0.9, d1, rx1 * f, ry1 * f))
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


# ================================================================ v3 "mini" proportions
# big round head (≈ a third of the height with the helmet), bean body, stubby mitts, big boots
WHITE = mat("EyeWhite", (0.95, 0.95, 0.95, 1), 0.3)
DARK = mat("Pupil", (0.01, 0.01, 0.012, 1), 0.2)
CHEEK = mat("Cheek", (0.60, 0.20, 0.14, 1))
BROW = mat("Brow", (0.05, 0.03, 0.02, 1))
HC = 1.80         # head centre height (head scaled x1.35: a third of the height)
if STYLE == "zombie":
    SKIN = mat("ZSkin", (0.25, 0.42, 0.18, 1))
    UNIFORM = mat("ZShirt", (0.05, 0.20, 0.08, 1))
    PANTS = mat("ZPants", (0.20, 0.12, 0.06, 1))
    KIT = mat("ZRag", (0.30, 0.24, 0.16, 1))
else:
    PANTS = UNIFORM

def face(eyes="cute"):
    ellipsoid((0.0000, -0.0135, HC), (0.2903, 0.2767, 0.3038), SKIN, "Head", seg=24, rings=14)
    for s in (1, -1):
        ellipsoid((0.2767 * s, -0.0068, HC - 0.0135), (0.0607, 0.0540, 0.0810), SKIN, "Head")          # ears
        ellipsoid((0.1553 * s, -0.2228, HC - 0.1013), (0.0540, 0.0162, 0.0338), CHEEK, "Head")      # cheeks
    if eyes == "cute":
        for s in (1, -1):
            ellipsoid((0.1013 * s, -0.2592, HC + 0.0000), (0.0675, 0.0270, 0.0810), WHITE, "Head")
            ellipsoid((0.0972 * s, -0.2767, HC - 0.0108), (0.0459, 0.0162, 0.0594), DARK, "Head")
            ellipsoid((0.1148 * s, -0.2889, HC + 0.0162), (0.0149, 0.0081, 0.0149), WHITE, "Head")   # sparkle
            rbox((0.1013 * s, -0.2565, HC + 0.1148), (0.1013, 0.0270, 0.0243), BROW, "Head", bevel=0.008)
        ellipsoid((0.0000, -0.2835, HC - 0.0810), (0.0297, 0.0203, 0.0243), SKIN, "Head")                  # nose
        ellipsoid((0.0000, -0.2633, HC - 0.1553), (0.0607, 0.0162, 0.0162), DARK, "Head")                # smile
    elif eyes == "zombie":
        ellipsoid((0.1080, -0.2538, HC + 0.0135), (0.0837, 0.0270, 0.0945), WHITE, "Head")               # big eye
        ellipsoid((0.1148, -0.2741, HC + 0.0000), (0.0297, 0.0135, 0.0297), DARK, "Head")
        ellipsoid((-0.1013, -0.2565, HC + 0.0000), (0.0513, 0.0243, 0.0405), WHITE, "Head")              # small squint
        ellipsoid((-0.1013, -0.2727, HC - 0.0027), (0.0189, 0.0108, 0.0162), DARK, "Head")
        ellipsoid((0.0000, -0.2497, HC - 0.1485), (0.1080, 0.0405, 0.0675), DARK, "Head")                    # open mouth
        for x in (-0.0540, 0.0000, 0.0540):
            rbox((x, -0.2767, HC - 0.1013), (0.0338, 0.0162, 0.0378), WHITE, "Head", bevel=0.004)  # teeth
        for k in range(4):
            rbox((-0.175 + k * 0.034, -0.2295, HC + 0.1350), (0.0108, 0.0270, 0.0675), BROW, "Head", bevel=0.002)   # stitches
        rbox((-0.1215, -0.2295, HC + 0.1350), (0.1350, 0.0162, 0.0108), BROW, "Head", bevel=0.002)
        ellipsoid((0.0810, 0.0270, HC + 0.2565), (0.1485, 0.1350, 0.0945), mat("Brain", (0.85, 0.35, 0.45, 1)), "Head")   # exposed brain
    cyl((0, -0.035, 1.56), 0.095, 0.12, SKIN, "Neck")

def helmet(group, goggles=True):
    dome((0.0000, 0.0068, HC + 0.0540), (0.3443, 0.3578, 0.3307), HC + 0.02, KIT, "Head", group)
    cyl((0.0000, 0.0068, HC + 0.0230), 0.3645, 0.0607, KIT, "Head", group, verts=24)
    if goggles:
        rbox((0.0000, -0.3172, HC + 0.1350), (0.3915, 0.0675, 0.1080), VISOR, "Head", group, 0.024)
        for s in (1, -1):
            cyl((0.0945 * s, -0.3551, HC + 0.1350), 0.0540, 0.0270, LENS, "Head", group, rot=(math.pi / 2, 0, 0))

def bean_body(vest=True, backpack=True):
    SPINE = [(0, -0.05, 0.84), (0, -0.05, 0.98), (0, -0.045, 1.15), (0, -0.04, 1.36), (0, -0.04, 1.48)]
    o = tube(SPINE, None, UNIFORM, ell=[(0.19, 0.14), (0.215, 0.16), (0.22, 0.165), (0.215, 0.15), (0.15, 0.11)], segs=20)
    soft.append((o, [(0, -0.05, 0.894), (0, -0.045, 0.999), (0, -0.045, 1.161), (0, -0.04, 1.377), (0, -0.04, 1.511)], ["Hips", "Abdomen", "Torso", "Chest"]))
    if vest:
        rbox((0, -0.05, 1.27), (0.50, 0.36, 0.34), KIT, "Chest", bevel=0.09)
        for x in (-0.12, 0.0, 0.12):
            rbox((x, -0.235, 1.16), (0.10, 0.05, 0.10), KIT, "Chest", bevel=0.025)
        rbox((0.13, -0.232, 1.37), (0.08, 0.02, 0.05), BADGE, "Chest", bevel=0.012)
    if backpack:
        rbox((0, 0.18, 1.28), (0.31, 0.13, 0.31), KIT, "Chest", bevel=0.06)
    rbox((0, -0.05, 0.92), (0.43, 0.32, 0.07), BOOT, "Hips", bevel=0.025)
    rbox((0.10, -0.215, 0.92), (0.07, 0.025, 0.05), BADGE, "Hips", bevel=0.01)

def limbs(boots=True, mitts=BOOT, pads=True):
    for s_ in (1, -1):
        L = "L" if s_ > 0 else "R"
        o = tube([(0.15 * s_, -0.058, 1.432), (0.334 * s_, -0.056, 1.432), (0.54 * s_, -0.08, 1.432)], [0.085, 0.075, 0.068], UNIFORM, segs=16)
        soft.append((o, [(0.12 * s_, -0.06, 1.42), (0.334 * s_, -0.056, 1.432), (0.568 * s_, -0.086, 1.432)], ["UpperArm." + L, "LowerArm." + L]))
        ellipsoid((0.20 * s_, -0.05, 1.45), (0.10, 0.10, 0.085), UNIFORM, "UpperArm." + L)               # round shoulder
        ellipsoid((0.625 * s_, -0.095, 1.43), (0.09, 0.07, 0.065), mitts, "Hand." + L)                  # mitt
        ellipsoid((0.595 * s_, -0.16, 1.42), (0.035, 0.04, 0.032), mitts, "Hand." + L)                  # thumb
        o = tube([(0.115 * s_, -0.05, 0.98), (0.121 * s_, -0.087, 0.533), (0.121 * s_, -0.07, 0.16)], [0.11, 0.092, 0.085], PANTS, segs=16)
        soft.append((o, [(0.121 * s_, -0.045, 1.05), (0.121 * s_, -0.045, 0.964), (0.121 * s_, -0.087, 0.533), (0.121 * s_, -0.062, 0.023)], ["Hips", "UpperLeg." + L, "LowerLeg." + L]))
        if pads: ellipsoid((0.121 * s_, -0.17, 0.53), (0.07, 0.04, 0.08), KIT, "LowerLeg." + L)
        if boots:
            rbox((0.121 * s_, -0.11, 0.085), (0.19, 0.34, 0.17), BOOT, "Foot." + L, bevel=0.075)       # chunky boot
            cyl((0.121 * s_, -0.075, 0.19), 0.1, 0.08, BOOT, "LowerLeg." + L, verts=24)
        else:
            ellipsoid((0.121 * s_, -0.10, 0.06), (0.09, 0.15, 0.065), SKIN, "Foot." + L)             # bare zombie feet

if STYLE == "soldier":
    face("cute"); bean_body(); limbs()
    helmet("Gear_Helmet")
    ellipsoid((0.0500, 0.0135, HC + 0.2600), (0.3350, 0.3350, 0.1050), KIT, "Head", "Gear_Beret", seg=18, rings=8, rot=(0.0, -0.22, 0.0))
    cyl((0.0000, 0.0135, HC + 0.2050), 0.2850, 0.0600, KIT, "Head", "Gear_Beret", verts=24)
    rbox((-0.1215, -0.2550, HC + 0.2300), (0.0675, 0.0189, 0.0810), BADGE, "Head", "Gear_Beret", 0.01)
    helmet("Gear_Mask", goggles=False)
    ellipsoid((0.0000, -0.1553, HC - 0.0675), (0.2565, 0.1620, 0.2025), VISOR, "Head", "Gear_Mask")
    cyl((0.0000, -0.3375, HC - 0.1215), 0.0878, 0.1215, KIT, "Head", "Gear_Mask", rot=(math.pi / 2, 0, 0))
    cyl((0.0000, -0.4050, HC - 0.1215), 0.081, 0.04, mat("Filter", (0.25, 0.27, 0.25, 1)), "Head", "Gear_Mask", rot=(math.pi / 2, 0, 0))
    for s in (1, -1):
        cyl((0.1013 * s, -0.2903, HC + 0.0000), 0.0607, 0.0270, LENS, "Head", "Gear_Mask", rot=(math.pi / 2, 0, 0))
elif STYLE == "swat":
    face("cute")
    # balaclava over the lower face + ballistic helmet with the visor down
    ellipsoid((0.0000, -0.0405, HC - 0.0945), (0.3038, 0.2903, 0.2295), BOOT, "Head", "Gear_Helmet")
    dome((0.0000, 0.0000, HC + 0.0405), (0.358, 0.371, 0.351), HC - 0.027, KIT, "Head", "Gear_Helmet")
    rbox((0.0000, -0.3307, HC + 0.0270), (0.486, 0.054, 0.175), mat("Visor2", (0.08, 0.12, 0.16, 1), 0.08), "Head", "Gear_Helmet", 0.03)
    bean_body(vest=True, backpack=False)
    rbox((0, -0.24, 1.28), (0.30, 0.02, 0.07), WHITE, "Chest", bevel=0.01)          # SWAT band
    rbox((0.24, -0.06, 1.45), (0.08, 0.12, 0.10), KIT, "Chest", bevel=0.03)         # radio
    limbs()
    for s_ in (1, -1):
        ellipsoid((0.334 * s_, -0.11, 1.43), (0.06, 0.05, 0.06), KIT, ("LowerArm." + ("L" if s_ > 0 else "R")))   # elbow pads
else:   # zombie: no gear, torn shirt, bare feet, green skin
    face("zombie")
    bean_body(vest=False, backpack=False)
    for k in range(5):
        rbox((-0.16 + k * 0.08, -0.17, 0.86), (0.07, 0.04, 0.06 + 0.03 * (k % 2)), UNIFORM, "Hips", bevel=0.01)   # ragged hem
    ellipsoid((0.08, -0.18, 1.2), (0.06, 0.02, 0.05), SKIN, "Torso")                    # hole in the shirt
    limbs(boots=False, mitts=SKIN, pads=False)

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

