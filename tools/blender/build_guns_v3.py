# Concept-sheet guns built in Blender (blender -b --python this.py -- NAME):
#   lmg76 (LMG-76, Heavy Gunner) / sr7 (SR-7L, Shadow Sniper) / sm7 (SM-7, Swift Scout) / sc7 (SC-7, Tech Support)
#   ar9 (AR-9R, Rookie Assault)
# Game convention: length along +X (muzzle at +X), up +Z in Blender (= +Y in glTF), centred later by the game.
# Every block gets wide multi-segment bevels (no sharp, boxy look). Prints GRIP / FORE / BUTT anchors as
# [fraction from the butt, height fraction of the length above the centre] for soldier.gd WEAPONS.
import bpy, bmesh, math, sys
from mathutils import Vector
NAME = sys.argv[sys.argv.index("--") + 1]
OUT = {"lmg76": "rpk", "sr7": "sniper", "sm7": "mp5", "sc7": "ak", "ar9": "m4"}[NAME]
bpy.ops.wm.read_factory_settings(use_empty=True)
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
MATS = {}
def mat(name, rgb, rough=0.5, metal=0.0):
    if name in MATS: return MATS[name]
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (lin(rgb[0]), lin(rgb[1]), lin(rgb[2]), 1)
    b.inputs["Roughness"].default_value = rough; b.inputs["Metallic"].default_value = metal
    MATS[name] = m; return m
BLK = mat("G_Black", (0.13, 0.13, 0.14), 0.45, 0.35)
DGR = mat("G_Dark", (0.24, 0.24, 0.25), 0.55, 0.2)
TAN = mat("G_Tan", (0.62, 0.53, 0.38), 0.65)
OLV = mat("G_Olive", (0.36, 0.38, 0.27), 0.7)
BRASS = mat("G_Brass", (0.82, 0.63, 0.30), 0.3, 0.9)
GLASS = mat("G_Lens", (0.25, 0.3, 0.45), 0.08, 0.3)
ACC = {"lmg76": mat("G_Red", (0.70, 0.16, 0.13), 0.5), "sr7": mat("G_Purple", (0.45, 0.35, 0.85), 0.3),
       "sm7": mat("G_Teal", (0.15, 0.55, 0.58), 0.4), "sc7": mat("G_Orange", (0.95, 0.52, 0.10), 0.45),
       "ar9": mat("G_Blue", (0.20, 0.45, 0.85), 0.4)}[NAME]
OBJS = []
def fin(o, m):
    o.data.materials.clear(); o.data.materials.append(m)
    for p in o.data.polygons: p.use_smooth = True
    OBJS.append(o); return o
def box(c, s, m, bev=None, rot=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=c)
    o = bpy.context.active_object; o.scale = s
    if rot: o.rotation_euler = rot
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    w = min(s) * 0.42 if bev is None else min(bev, min(s) * 0.49)
    md = o.modifiers.new("b", "BEVEL"); md.width = w; md.segments = 5; md.limit_method = "NONE"; md.profile = 0.55
    bpy.ops.object.modifier_apply(modifier="b")
    return fin(o, m)
def cyl(c, r, L, m, axis="x", verts=32, bev=0.004):
    rot = {"x": (0, math.pi / 2, 0), "y": (math.pi / 2, 0, 0), "z": (0, 0, 0)}[axis]
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=L, location=c, rotation=rot)
    o = bpy.context.active_object; bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if bev:
        md = o.modifiers.new("b", "BEVEL"); md.width = min(bev, r * 0.4); md.segments = 3; md.limit_method = "ANGLE"
        bpy.ops.object.modifier_apply(modifier="b")
    return fin(o, m)
def slots(x0, x1, z, y, n, m):                      # handguard vent slots (dark, slightly sunk)
    for i in range(n):
        x = x0 + (x1 - x0) * (i + 0.5) / n
        box((x, y, z), ((x1 - x0) / n * 0.55, 0.006, 0.012), m, bev=0.004)
def rail(x0, x1, z, m, w=0.022):
    box(((x0 + x1) / 2, 0, z), (x1 - x0, w, 0.008), m, bev=0.003)
    n = int((x1 - x0) / 0.012)
    for i in range(n):
        box((x0 + (i + 0.5) * (x1 - x0) / n, 0, z + 0.006), ((x1 - x0) / n * 0.5, w, 0.006), m, bev=0.002)
def grip(x, z, m, rake=0.32, h=0.10):
    g = box((x, 0, z - h / 2), (0.034, 0.028, h), m, rot=(0, rake, 0))
    box((x - 0.012, 0, z - h * 0.35), (0.006, 0.03, h * 0.6), DGR, bev=0.002, rot=(0, rake, 0))   # finger grooves strip
    return Vector((x - math.sin(rake) * h * 0.45, 0, z - h * 0.45))
def trigger_guard(x, z):
    bpy.ops.mesh.primitive_torus_add(major_radius=0.022, minor_radius=0.0035, location=(x, 0, z - 0.018), rotation=(math.pi / 2, 0, 0))
    o = bpy.context.active_object; o.scale = (1.25, 1, 0.8); bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    fin(o, BLK)
    box((x - 0.004, 0, z - 0.012), (0.004, 0.004, 0.02), BLK, bev=0.0015, rot=(0, 0.3, 0))
def red_dot(x, z, s=1.0):
    box((x, 0, z + 0.018 * s), (0.05 * s, 0.032 * s, 0.032 * s), BLK)
    box((x + 0.026 * s, 0, z + 0.022 * s), (0.004, 0.026 * s, 0.024 * s), GLASS, bev=0.002)
    box((x, 0, z + 0.004), (0.04 * s, 0.026 * s, 0.01), DGR, bev=0.003)
    box((x - 0.005, 0, z + 0.036 * s), (0.012, 0.008, 0.006), ACC, bev=0.002)
def stock_ar(x1, z, m=TAN, L=0.17):                   # collapsible stock + buffer tube
    cyl((x1 - L * 0.45, 0, z), 0.012, L * 0.9, BLK)
    box((x1 - L * 0.75, 0, z - 0.012), (L * 0.55, 0.03, 0.05), m)
    box((x1 - L + 0.01, 0, z - 0.02), (0.02, 0.036, 0.085), m)
    box((x1 - L + 0.002, 0, z - 0.02), (0.008, 0.038, 0.09), BLK, bev=0.003)   # butt pad
    return Vector((x1 - L, 0, z - 0.015))

A = {}
if NAME == "lmg76":           # belt-fed LMG: long receiver, tan stock + handguard, box mag, ammo belt, bipod, carry handle
    box((0.0, 0, 0.0), (0.30, 0.05, 0.075), BLK)                                    # receiver
    box((0.02, 0, 0.045), (0.24, 0.046, 0.02), DGR)                                  # feed cover
    rail(-0.06, 0.12, 0.058, BLK)
    red_dot(0.04, 0.066, 1.2)
    box((0.27, 0, 0.0), (0.24, 0.056, 0.06), TAN)                                    # handguard
    slots(0.17, 0.37, 0.0, -0.029, 7, DGR); slots(0.17, 0.37, 0.0, 0.029, 7, DGR)
    cyl((0.47, 0, 0.005), 0.016, 0.20, BLK)                                          # barrel
    cyl((0.58, 0, 0.005), 0.022, 0.05, BLK)                                          # flash hider
    box((0.55, 0, 0.03), (0.01, 0.006, 0.03), BLK, bev=0.002)                        # front sight
    box((0.13, 0, 0.075), (0.03, 0.012, 0.035), BLK)                                 # carry handle post
    box((0.13, 0, 0.098), (0.09, 0.014, 0.014), BLK)
    A["grip"] = grip(-0.11, -0.03, BLK, h=0.11); trigger_guard(-0.085, -0.035)
    A["butt"] = stock_ar(-0.15, 0.0, TAN, 0.17)
    box((-0.02, 0, -0.095), (0.11, 0.075, 0.11), OLV)                                # ammo box
    box((-0.02, 0, -0.04), (0.115, 0.08, 0.012), OLV)
    box((-0.02, -0.039, -0.095), (0.04, 0.003, 0.04), mat("G_White", (0.9, 0.9, 0.88), 0.5), bev=0.002)
    for i in range(6):                                                               # brass belt
        x = 0.02 + i * 0.016
        cyl((x, -0.035, -0.02 - i * 0.004), 0.007, 0.055, BRASS, axis="y", verts=16)
    for s in (1, -1):                                                                # folded bipod
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.006, depth=0.16, location=(0.44, 0.02 * s, -0.07), rotation=(0.3 * s, 0.25, 0))
        o = bpy.context.active_object; bpy.ops.object.transform_apply(location=True, rotation=True, scale=True); fin(o, BLK)
    box((0.42, 0, -0.03), (0.03, 0.05, 0.02), BLK)
    A["fore"] = Vector((0.30, 0, -0.03))
elif NAME == "sr7":           # bolt sniper: tan chassis, long suppressor, big scope (purple lens), bipod, mag
    box((0.0, 0, 0.0), (0.22, 0.045, 0.05), BLK)                                     # action
    box((0.24, 0, -0.005), (0.30, 0.05, 0.05), TAN)                                  # chassis forend
    slots(0.12, 0.38, -0.005, -0.026, 8, DGR); slots(0.12, 0.38, -0.005, 0.026, 8, DGR)
    cyl((0.52, 0, 0.005), 0.011, 0.30, BLK)
    cyl((0.74, 0, 0.005), 0.022, 0.22, BLK, verts=40)                                 # suppressor
    rail(-0.08, 0.30, 0.03, BLK)
    cyl((0.05, 0, 0.075), 0.02, 0.26, BLK, verts=40)                                  # scope tube
    cyl((0.19, 0, 0.075), 0.03, 0.07, BLK, verts=40); cyl((0.226, 0, 0.075), 0.026, 0.004, ACC, verts=40)   # objective + lens
    cyl((-0.08, 0, 0.075), 0.026, 0.05, BLK, verts=40)
    cyl((0.05, 0, 0.105), 0.012, 0.025, BLK, axis="z"); cyl((0.05, 0.03, 0.075), 0.012, 0.022, BLK, axis="y")
    for x in (-0.02, 0.12): box((x, 0, 0.05), (0.02, 0.03, 0.03), BLK)
    cyl((0.02, 0.035, 0.02), 0.006, 0.04, BLK, axis="y"); box((0.02, 0.055, 0.02), (0.014, 0.014, 0.014), BLK, bev=0.006)   # bolt handle
    box((0.03, 0, -0.06), (0.05, 0.035, 0.07), BLK)                                  # magazine
    A["grip"] = grip(-0.09, -0.025, BLK); trigger_guard(-0.065, -0.03)
    box((-0.20, 0, -0.02), (0.18, 0.04, 0.05), TAN)                                  # skeleton stock
    box((-0.29, 0, -0.035), (0.025, 0.044, 0.11), TAN)
    box((-0.302, 0, -0.035), (0.008, 0.046, 0.115), BLK, bev=0.003)
    box((-0.22, 0, 0.022), (0.08, 0.03, 0.02), TAN)                                   # cheek riser
    A["butt"] = Vector((-0.30, 0, -0.03))
    for s in (1, -1):
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.005, depth=0.14, location=(0.37, 0.018 * s, -0.08), rotation=(0.25 * s, 0.0, 0))
        o = bpy.context.active_object; bpy.ops.object.transform_apply(location=True, rotation=True, scale=True); fin(o, BLK)
    A["fore"] = Vector((0.22, 0, -0.035))
elif NAME == "sm7":           # compact SMG: short receiver, tan side panel, long stick mag, red dot, vertical grip, folding stock
    box((0.0, 0, 0.0), (0.20, 0.05, 0.06), BLK)
    box((0.03, -0.026, 0.0), (0.10, 0.004, 0.035), TAN, bev=0.002); box((0.03, 0.026, 0.0), (0.10, 0.004, 0.035), TAN, bev=0.002)
    slots(0.0, 0.07, 0.0, -0.029, 4, BLK)
    box((0.13, 0, -0.002), (0.08, 0.044, 0.05), DGR)
    cyl((0.19, 0, 0.0), 0.012, 0.06, BLK); cyl((0.225, 0, 0.0), 0.016, 0.03, BLK)
    rail(-0.07, 0.14, 0.036, BLK)
    red_dot(0.0, 0.044)
    box((-0.005, 0, -0.08), (0.03, 0.026, 0.11), DGR, rot=(0, 0.08, 0))               # stick mag
    box((-0.009, 0, -0.14), (0.034, 0.03, 0.012), BLK, bev=0.004, rot=(0, 0.08, 0))
    A["grip"] = grip(-0.07, -0.03, BLK, h=0.085); trigger_guard(-0.045, -0.034)
    box((0.12, 0, -0.06), (0.024, 0.024, 0.06), BLK)                                  # vertical foregrip
    box((0.125, -0.0125, -0.045), (0.006, 0.002, 0.012), ACC, bev=0.001)
    box((-0.16, 0, 0.0), (0.12, 0.014, 0.014), BLK)                                  # folding wire stock
    box((-0.16, 0, -0.035), (0.12, 0.014, 0.014), BLK, rot=(0, -0.25, 0))
    box((-0.225, 0, -0.022), (0.014, 0.03, 0.07), BLK)
    A["butt"] = Vector((-0.23, 0, -0.02))
    A["fore"] = Vector((0.12, 0, -0.06))
elif NAME == "ar9":          # rookie carbine: black upper + quad rail, tan stock / grip, compact scope, vertical grip, curved mag
    box((0.0, 0, 0.012), (0.20, 0.05, 0.045), BLK)                                   # upper receiver
    box((-0.01, 0, -0.024), (0.15, 0.044, 0.04), DGR)                                # lower receiver
    box((0.02, -0.026, 0.014), (0.05, 0.004, 0.016), DGR, bev=0.002)                 # ejection port
    box((-0.03, 0.026, -0.022), (0.03, 0.004, 0.012), ACC, bev=0.002)                # blue selector plate
    box((0.20, 0, 0.008), (0.21, 0.054, 0.054), BLK)                                 # quad-rail handguard
    slots(0.11, 0.29, 0.0, -0.028, 6, DGR); slots(0.11, 0.29, 0.0, 0.028, 6, DGR)
    for zz in (-0.012, 0.022):                                                       # side rail ribs
        box((0.20, -0.029, zz), (0.19, 0.004, 0.006), DGR, bev=0.002); box((0.20, 0.029, zz), (0.19, 0.004, 0.006), DGR, bev=0.002)
    rail(-0.09, 0.30, 0.038, BLK)
    cyl((0.345, 0, 0.008), 0.011, 0.08, BLK)                                         # barrel
    cyl((0.395, 0, 0.008), 0.016, 0.045, BLK)                                        # flash hider
    for k in range(3): box((0.39 + k * 0.012, 0, 0.022), (0.005, 0.034, 0.006), DGR, bev=0.002)
    box((0.285, 0, 0.056), (0.012, 0.012, 0.026), BLK, bev=0.004)                    # folded front sight
    box((-0.075, 0, 0.056), (0.016, 0.03, 0.022), BLK)                               # rear sight
    box((-0.085, 0, 0.034), (0.03, 0.02, 0.012), BLK, bev=0.004)                     # charging handle
    cyl((0.02, 0, 0.082), 0.017, 0.13, BLK, verts=40)                                # compact scope
    cyl((0.095, 0, 0.082), 0.024, 0.035, BLK, verts=40); cyl((0.1135, 0, 0.082), 0.02, 0.004, GLASS, verts=40)
    cyl((-0.05, 0, 0.082), 0.021, 0.035, BLK, verts=40)
    cyl((0.025, 0, 0.106), 0.01, 0.018, BLK, axis="z"); cyl((0.025, 0.024, 0.082), 0.01, 0.016, BLK, axis="y")
    cyl((0.025, 0, 0.116), 0.0105, 0.004, ACC, axis="z")                             # blue turret cap
    for x in (-0.02, 0.07): box((x, 0, 0.056), (0.02, 0.03, 0.026), BLK)             # scope mounts
    box((0.035, 0, -0.085), (0.036, 0.026, 0.10), BLK, rot=(0, 0.20, 0))             # curved mag
    box((0.025, 0, -0.14), (0.042, 0.03, 0.012), ACC, bev=0.004, rot=(0, 0.20, 0))
    A["grip"] = grip(-0.06, -0.035, TAN); trigger_guard(-0.035, -0.038)
    box((0.21, 0, -0.06), (0.026, 0.026, 0.07), BLK)                                 # vertical foregrip
    box((0.21, -0.0135, -0.05), (0.008, 0.002, 0.03), ACC, bev=0.001)
    A["butt"] = stock_ar(-0.10, 0.008, TAN, 0.19)
    A["fore"] = Vector((0.21, 0, -0.065))
else:                        # sc7: support carbine, tan stock + handguard with orange accents, holo sight, vertical grip
    box((0.0, 0, 0.0), (0.18, 0.048, 0.06), BLK)
    box((0.0, 0, -0.012), (0.13, 0.044, 0.03), DGR)
    box((0.19, 0, 0.0), (0.20, 0.054, 0.055), TAN)
    slots(0.11, 0.27, 0.0, -0.028, 5, BLK); slots(0.11, 0.27, 0.0, 0.028, 5, BLK)
    box((0.25, -0.028, 0.012), (0.04, 0.003, 0.012), ACC, bev=0.002); box((0.25, 0.028, 0.012), (0.04, 0.003, 0.012), ACC, bev=0.002)
    cyl((0.33, 0, 0.003), 0.012, 0.10, BLK); cyl((0.39, 0, 0.003), 0.017, 0.04, BLK)
    rail(-0.08, 0.28, 0.034, BLK)
    box((0.03, 0, 0.065), (0.07, 0.04, 0.05), BLK)                                    # holo sight hood
    box((0.03, 0, 0.065), (0.06, 0.03, 0.035), GLASS, bev=0.006)
    box((0.03, 0, 0.093), (0.02, 0.02, 0.008), ACC, bev=0.002)
    box((0.03, 0, -0.08), (0.035, 0.026, 0.11), DGR, rot=(0, 0.15, 0))               # curved-ish mag
    box((0.022, 0, -0.136), (0.04, 0.03, 0.012), ACC, bev=0.004, rot=(0, 0.15, 0))
    A["grip"] = grip(-0.06, -0.03, BLK); trigger_guard(-0.035, -0.034)
    box((0.21, 0, -0.06), (0.024, 0.024, 0.065), BLK)                                 # vertical foregrip
    A["butt"] = stock_ar(-0.09, 0.0, TAN, 0.19)
    box((-0.16, -0.022, -0.012), (0.03, 0.004, 0.012), ACC, bev=0.002)
    A["fore"] = Vector((0.21, 0, -0.065))

for x in bpy.context.selected_objects: x.select_set(False)
for o in OBJS: o.select_set(True)
bpy.context.view_layer.objects.active = OBJS[0]
bpy.ops.object.join()
gun = bpy.context.active_object; gun.name = NAME
vs = [v.co for v in gun.data.vertices]
x0 = min(v.x for v in vs); x1 = max(v.x for v in vs); L = x1 - x0
zc = (min(v.z for v in vs) + max(v.z for v in vs)) / 2
for k in ("butt", "grip", "fore"):
    p = A[k]
    print("ANCHOR %s %s [%.2f, %.2f]" % (NAME, k, (p.x - x0) / L, (p.z - zc) / L))
print("LEN %s %.3f tris %d" % (NAME, L, len(gun.data.polygons)))
bpy.ops.export_scene.gltf(filepath="/home/user/Reborn/game/assets/guns/%s.glb" % OUT, export_format="GLB", use_selection=True, export_materials="EXPORT")
bpy.ops.wm.save_as_mainfile(filepath="/tmp/mv3/gun_%s.blend" % NAME)
