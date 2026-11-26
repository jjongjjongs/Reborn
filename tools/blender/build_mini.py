# Runs INSIDE Blender (blender-mcp). "Mini Soldier" test character: a chunky,
# big-headed toy soldier built from primitives around the SWAT armature (same
# bones, so the game's retargeted animations, hand IK and tinting work as is).
# Every part is rigidly weighted to one bone (low-poly toy look).
# Materials reuse the SWAT colours so Soldier._team_tint recolours them:
#   Swat (gear grey) = uniform -> team / suit colour, Swat_Black = vest + helmet -> kit colour.
# Head gear variants are separate meshes: Gear_Helmet, Gear_Beret, Gear_Mask.
import bpy, bmesh, math
from mathutils import Vector, Matrix

SWAT = "/home/user/Reborn/game/assets/soldier/Swat.glb"
OUT = "/home/user/Reborn/game/assets/soldier/Mini.glb"

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

# ---- head (big: the chibi part) ----
ellipsoid((0, -0.015, 1.72), (0.18, 0.17, 0.19), SKIN, "Head")
ellipsoid((0.175, -0.01, 1.71), (0.04, 0.035, 0.055), SKIN, "Head")      # ears
ellipsoid((-0.175, -0.01, 1.71), (0.04, 0.035, 0.055), SKIN, "Head")
ellipsoid((0.065, -0.178, 1.72), (0.025, 0.012, 0.03), VISOR, "Head")    # eyes (seen under the beret)
ellipsoid((-0.065, -0.178, 1.72), (0.025, 0.012, 0.03), VISOR, "Head")
ellipsoid((0, -0.19, 1.68), (0.03, 0.025, 0.03), SKIN, "Head")            # nose
ellipsoid((0.10, -0.15, 1.655), (0.035, 0.015, 0.022), mat("Cheek", (0.55, 0.22, 0.15, 1)), "Head")   # cheeks
ellipsoid((-0.10, -0.15, 1.655), (0.035, 0.015, 0.022), mat("Cheek", (0.55, 0.22, 0.15, 1)), "Head")
cyl((0, -0.03, 1.55), 0.075, 0.12, SKIN, "Neck")
# helmet + goggles (default gear)
dome((0, 0.005, 1.77), (0.235, 0.245, 0.215), 1.74, KIT, "Head", "Gear_Helmet")
cyl((0, 0.005, 1.742), 0.25, 0.04, KIT, "Head", "Gear_Helmet", verts=18)
rbox((0, -0.205, 1.80), (0.27, 0.05, 0.075), VISOR, "Head", "Gear_Helmet", 0.022)      # goggles pushed up on the helmet
cyl((0.065, -0.233, 1.80), 0.036, 0.02, LENS, "Head", "Gear_Helmet", rot=(math.pi / 2, 0, 0))
cyl((-0.065, -0.233, 1.80), 0.036, 0.02, LENS, "Head", "Gear_Helmet", rot=(math.pi / 2, 0, 0))
# beret variant
ellipsoid((0.035, 0.01, 1.87), (0.21, 0.21, 0.065), KIT, "Head", "Gear_Beret", seg=14, rings=6, rot=(0.0, -0.22, 0.0))
cyl((0, 0.01, 1.84), 0.185, 0.035, KIT, "Head", "Gear_Beret", verts=16)
rbox((-0.08, -0.175, 1.86), (0.045, 0.012, 0.055), BADGE, "Head", "Gear_Beret", 0.008)
# gas mask variant (helmet on top + mask on the face)
dome((0, 0.005, 1.77), (0.235, 0.245, 0.215), 1.74, KIT, "Head", "Gear_Mask")
cyl((0, 0.005, 1.742), 0.25, 0.04, KIT, "Head", "Gear_Mask", verts=18)
ellipsoid((0, -0.10, 1.68), (0.165, 0.11, 0.13), VISOR, "Head", "Gear_Mask")
cyl((0, -0.225, 1.64), 0.06, 0.09, KIT, "Head", "Gear_Mask", rot=(math.pi / 2, 0, 0))
cyl((0, -0.275, 1.64), 0.072, 0.03, BADGE, "Head", "Gear_Mask", rot=(math.pi / 2, 0, 0))
cyl((0.068, -0.195, 1.73), 0.04, 0.02, LENS, "Head", "Gear_Mask", rot=(math.pi / 2, 0, 0))
cyl((-0.068, -0.195, 1.73), 0.04, 0.02, LENS, "Head", "Gear_Mask", rot=(math.pi / 2, 0, 0))

# ---- body: continuous skinned tubes (torso, arms, legs) + rigid gear on top ----
SPINE = [(0, -0.05, 0.86), (0, -0.05, 0.999), (0, -0.045, 1.161), (0, -0.04, 1.377), (0, -0.04, 1.47)]
o = tube(SPINE, None, UNIFORM, ell=[(0.17, 0.12), (0.18, 0.125), (0.19, 0.13), (0.205, 0.135), (0.15, 0.11)], segs=18)
soft.append((o, [(0, -0.05, 0.894), (0, -0.045, 0.999), (0, -0.045, 1.161), (0, -0.04, 1.377), (0, -0.04, 1.511)], ["Hips", "Abdomen", "Torso", "Chest"]))
o = tube([(0, -0.035, 1.46), (0, -0.035, 1.62)], [0.07, 0.07], SKIN, caps=False)
soft.append((o, [(0, -0.043, 1.45), (0, -0.043, 1.511), (0, -0.043, 1.587), (0, -0.043, 1.70)], ["Chest", "Neck", "Head"]))
rbox((0, -0.05, 1.29), (0.46, 0.30, 0.32), KIT, "Chest", bevel=0.07)           # plate carrier
for x in (-0.12, 0.0, 0.12):
    rbox((x, -0.21, 1.18), (0.095, 0.05, 0.10), KIT, "Chest", bevel=0.02)     # pouches
rbox((0.12, -0.205, 1.38), (0.07, 0.03, 0.05), BADGE, "Chest", bevel=0.012)   # name tag
rbox((0, 0.15, 1.30), (0.29, 0.12, 0.29), KIT, "Chest", bevel=0.05)            # small backpack
rbox((0, -0.05, 0.93), (0.38, 0.27, 0.06), BOOT, "Hips", bevel=0.02)           # belt
rbox((0.10, -0.19, 0.93), (0.07, 0.03, 0.05), BADGE, "Hips", bevel=0.01)      # buckle
for s_ in (1, -1):
    L = "L" if s_ > 0 else "R"
    arm_pts = [(0.15 * s_, -0.058, 1.432), (0.334 * s_, -0.056, 1.432), (0.55 * s_, -0.082, 1.432)]
    o = tube(arm_pts, [0.072, 0.064, 0.056], UNIFORM, segs=14)
    soft.append((o, [(0.12 * s_, -0.06, 1.42), (0.334 * s_, -0.056, 1.432), (0.568 * s_, -0.086, 1.432)], ["UpperArm." + L, "LowerArm." + L]))
    ellipsoid((0.19 * s_, -0.05, 1.445), (0.085, 0.09, 0.07), UNIFORM, "UpperArm." + L)          # shoulder
    # glove: rounded fist + thumb + cuff
    ellipsoid((0.625 * s_, -0.095, 1.428), (0.075, 0.058, 0.05), BOOT, "Hand." + L)
    ellipsoid((0.60 * s_, -0.15, 1.42), (0.03, 0.035, 0.026), BOOT, "Hand." + L)
    cyl((0.555 * s_, -0.085, 1.432), 0.06, 0.04, BOOT, "LowerArm." + L, rot=(0, math.pi / 2, 0))
    leg_pts = [(0.115 * s_, -0.05, 0.99), (0.121 * s_, -0.087, 0.533), (0.121 * s_, -0.07, 0.14)]
    o = tube(leg_pts, [0.098, 0.082, 0.074], UNIFORM, segs=14)
    soft.append((o, [(0.121 * s_, -0.045, 1.05), (0.121 * s_, -0.045, 0.964), (0.121 * s_, -0.087, 0.533), (0.121 * s_, -0.062, 0.023)], ["Hips", "UpperLeg." + L, "LowerLeg." + L]))
    ellipsoid((0.121 * s_, -0.158, 0.53), (0.062, 0.035, 0.072), KIT, "LowerLeg." + L)        # knee pad
    rbox((0.121 * s_, -0.10, 0.075), (0.16, 0.30, 0.15), BOOT, "Foot." + L, bevel=0.06)      # boot
    cyl((0.121 * s_, -0.075, 0.17), 0.085, 0.07, BOOT, "LowerLeg." + L, verts=20)            # boot top

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
