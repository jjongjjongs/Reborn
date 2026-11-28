# Zombie-mode weapons (shop, survival only), built in Blender in the concept-gun style of build_guns_v3.py:
#   blender -b --python build_zguns.py -- NAME [--render]
#   NAME: dbarrel (더블 배럴) / axe (소방 도끼) / flamer (화염방사기) / nailgun (네일건) / xbow (폭발 석궁) / tesla (테슬라 건)
# Game convention: length along +X (muzzle / blade end at +X), up +Z, centred later by the game.
# Wide multi-segment bevels on every block (no sharp, boxy look); prints GRIP / FORE / BUTT anchors as
# [fraction from the butt, height fraction of the length above the centre] for soldier.gd WEAPONS.
import bpy, bmesh, math, sys
from mathutils import Vector
ARGV = sys.argv[sys.argv.index("--") + 1:]
NAME = ARGV[0]; RENDER = "--render" in ARGV
bpy.ops.wm.read_factory_settings(use_empty=True)
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
MATS = {}
def mat(name, rgb, rough=0.5, metal=0.0, emit=0.0):
    if name in MATS: return MATS[name]
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    c = (lin(rgb[0]), lin(rgb[1]), lin(rgb[2]), 1)
    b.inputs["Base Color"].default_value = c
    b.inputs["Roughness"].default_value = rough; b.inputs["Metallic"].default_value = metal
    if emit:
        b.inputs["Emission Color"].default_value = c; b.inputs["Emission Strength"].default_value = emit
    MATS[name] = m; return m
BLK = mat("G_Black", (0.13, 0.13, 0.14), 0.45, 0.35)
DGR = mat("G_Dark", (0.24, 0.24, 0.25), 0.55, 0.2)
STEEL = mat("Z_Steel", (0.62, 0.64, 0.67), 0.32, 0.85)
GUN = mat("Z_Gunmetal", (0.30, 0.32, 0.35), 0.35, 0.8)
WOOD = mat("Z_Wood", (0.55, 0.32, 0.16), 0.55)
WOOD2 = mat("Z_WoodDark", (0.36, 0.20, 0.10), 0.6)
RED = mat("Z_Red", (0.78, 0.14, 0.10), 0.4, 0.1)
YEL = mat("Z_Yellow", (0.96, 0.74, 0.10), 0.45)
BRASS = mat("G_Brass", (0.82, 0.63, 0.30), 0.3, 0.9)
COPPER = mat("Z_Copper", (0.86, 0.47, 0.26), 0.28, 0.95)
RUB = mat("Z_Rubber", (0.09, 0.09, 0.10), 0.85)
WHITE = mat("Z_White", (0.92, 0.91, 0.88), 0.45)
GLASS = mat("G_Lens", (0.25, 0.3, 0.45), 0.08, 0.3)
GLOW = mat("Z_Glow", (0.35, 0.85, 1.0), 0.2, 0.0, 6.0)
FLAME = mat("Z_Pilot", (1.0, 0.55, 0.12), 0.3, 0.0, 8.0)
LED = mat("Z_Led", (0.3, 1.0, 0.45), 0.3, 0.0, 5.0)
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
def cyl(c, r, L, m, axis="x", verts=32, bev=0.004, rot=None, r2=None):
    base = {"x": (0, math.pi / 2, 0), "y": (math.pi / 2, 0, 0), "z": (0, 0, 0)}[axis]
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=L, location=c, rotation=base)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=r2, depth=L, location=c, rotation=base)
    o = bpy.context.active_object
    if rot: o.rotation_euler.rotate(__import__("mathutils").Euler(rot))
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if bev:
        md = o.modifiers.new("b", "BEVEL"); md.width = min(bev, r * 0.4); md.segments = 3; md.limit_method = "ANGLE"
        bpy.ops.object.modifier_apply(modifier="b")
    return fin(o, m)
def ring(c, R, r, m, axis="x", segs=32):
    rot = {"x": (0, math.pi / 2, 0), "y": (math.pi / 2, 0, 0), "z": (0, 0, 0)}[axis]
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, major_segments=segs, minor_segments=10, location=c, rotation=rot)
    o = bpy.context.active_object; bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return fin(o, m)
def slab(pts, th, m, bev=0.004):
    """flat plate from a 2D outline in the XZ plane (x, z), thickness th along Y"""
    me = bpy.data.meshes.new("slab"); bm = bmesh.new()
    vs = [bm.verts.new((x, -th / 2, z)) for x, z in pts]
    f = bm.faces.new(vs); bmesh.ops.recalc_face_normals(bm, faces=[f])
    ext = bmesh.ops.extrude_face_region(bm, geom=[f])
    for v in [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]: v.co.y += th
    bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new("slab", me); bpy.context.scene.collection.objects.link(o)
    bpy.context.view_layer.objects.active = o
    md = o.modifiers.new("b", "BEVEL"); md.width = bev; md.segments = 3; md.limit_method = "ANGLE"
    for x in bpy.context.selected_objects: x.select_set(False)
    o.select_set(True); bpy.ops.object.modifier_apply(modifier="b")
    return fin(o, m)
def tube(pts, r, m, verts=16):
    """a bent hose / wire through 3D points"""
    cu = bpy.data.curves.new("t", "CURVE"); cu.dimensions = "3D"; cu.bevel_depth = r; cu.bevel_resolution = 4
    sp = cu.splines.new("BEZIER"); sp.bezier_points.add(len(pts) - 1)
    for i, p in enumerate(pts):
        bp = sp.bezier_points[i]; bp.co = p; bp.handle_left_type = bp.handle_right_type = "AUTO"
    o = bpy.data.objects.new("t", cu); bpy.context.scene.collection.objects.link(o)
    for x in bpy.context.selected_objects: x.select_set(False)
    o.select_set(True); bpy.context.view_layer.objects.active = o
    bpy.ops.object.convert(target="MESH")
    return fin(bpy.context.active_object, m)
def grip(x, z, m, rake=0.32, h=0.10, w=0.028):
    box((x, 0, z - h / 2), (0.034, w, h), m, rot=(0, rake, 0))
    for k in range(3):                                   # finger grooves
        box((x + 0.016 - math.sin(rake) * h * (0.25 + k * 0.2), 0, z - h * (0.25 + k * 0.2)), (0.006, w + 0.003, 0.012), DGR, bev=0.003, rot=(0, rake, 0))
    return Vector((x - math.sin(rake) * h * 0.45, 0, z - h * 0.45))
def trigger_guard(x, z, s=1.0):
    bpy.ops.mesh.primitive_torus_add(major_radius=0.022 * s, minor_radius=0.0035, location=(x, 0, z - 0.018 * s), rotation=(math.pi / 2, 0, 0))
    o = bpy.context.active_object; o.scale = (1.25, 1, 0.8); bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    fin(o, BLK)
    box((x - 0.004, 0, z - 0.012), (0.004, 0.004, 0.02), BLK, bev=0.0015, rot=(0, 0.3, 0))
def stripes(x0, x1, z, y, h, n, m1=YEL, m2=BLK):        # hazard stripes on a side panel
    for i in range(n):
        x = x0 + (x1 - x0) * (i + 0.5) / n
        box((x, y, z), ((x1 - x0) / n * 0.98, 0.003, h), m1 if i % 2 == 0 else m2, bev=0.001, rot=(0.0, 0.5, 0.0))

A = {}
if NAME == "dbarrel":        # break-action double barrel: twin steel barrels, walnut forend + stock, engraved receiver, exposed hammers, shell strap
    for s in (1, -1):
        cyl((0.235, 0.0205 * s, 0.014), 0.0205, 0.37, GUN, verts=40)
        cyl((0.418, 0.0205 * s, 0.014), 0.0225, 0.014, STEEL, verts=40)                # muzzle ring
        cyl((0.4245, 0.0205 * s, 0.014), 0.015, 0.004, BLK, verts=32)                  # bore
        for k in range(3): ring((0.12 + k * 0.1, 0.0205 * s, 0.014), 0.0207, 0.0015, STEEL)
    box((0.235, 0, 0.037), (0.37, 0.014, 0.007), STEEL, bev=0.002)                   # top rib
    cyl((0.41, 0, 0.044), 0.005, 0.008, BRASS, axis="z", verts=16)                    # bead sight
    box((0.17, 0, -0.016), (0.17, 0.056, 0.038), WOOD)                                # forend
    for k in range(6): box((0.15 + k * 0.02, -0.0225, -0.014), (0.012, 0.003, 0.018), WOOD2, bev=0.002, rot=(0.0, 0.7, 0.0))   # checkering
    for k in range(6): box((0.15 + k * 0.02, 0.0225, -0.014), (0.012, 0.003, 0.018), WOOD2, bev=0.002, rot=(0.0, -0.7, 0.0))
    box((0.0, 0, 0.002), (0.12, 0.062, 0.07), STEEL)                                  # receiver
    for s in (1, -1):
        box((0.0, 0.0315 * s, 0.002), (0.085, 0.003, 0.046), BRASS, bev=0.001)       # engraved side plates
        box((0.0, 0.033 * s, 0.002), (0.06, 0.002, 0.026), GUN, bev=0.001)
        ring((0.0, 0.0335 * s, 0.002), 0.01, 0.0015, BRASS, axis="y", segs=20)
        box((-0.04, 0.012 * s, 0.045), (0.012, 0.008, 0.03), GUN, bev=0.004, rot=(0, -0.5, 0))   # exposed hammers
        box((-0.05, 0.012 * s, 0.06), (0.016, 0.009, 0.008), STEEL, bev=0.003)
    cyl((0.055, 0, 0.0), 0.009, 0.056, STEEL, axis="y")                               # hinge pin
    box((-0.015, 0, 0.036), (0.05, 0.012, 0.008), GUN, bev=0.003, rot=(0, 0, 0.35))  # top lever
    A["grip"] = Vector((-0.085, 0, -0.045))
    box((-0.09, 0, -0.03), (0.1, 0.04, 0.05), WOOD, rot=(0, 0.3, 0))                   # wrist (into the stock)
    trigger_guard(-0.03, -0.03)
    box((-0.02, 0, -0.04), (0.004, 0.004, 0.022), STEEL, bev=0.0015, rot=(0, 0.3, 0))
    slab([(-0.10, 0.012), (-0.12, -0.025), (-0.16, -0.045), (-0.33, -0.085), (-0.355, -0.088), (-0.355, 0.01), (-0.30, 0.012), (-0.12, 0.034)], 0.048, WOOD, bev=0.012)   # butt stock
    box((-0.36, 0, -0.038), (0.014, 0.052, 0.1), RUB, bev=0.005)                    # recoil pad
    box((-0.24, -0.026, -0.022), (0.1, 0.004, 0.05), RUB, bev=0.002)                 # elastic shell strap
    for k in range(4):
        cyl((-0.275 + k * 0.023, -0.031, -0.02), 0.0095, 0.055, RED, axis="z", verts=20)
        cyl((-0.275 + k * 0.023, -0.031, -0.05), 0.01, 0.012, BRASS, axis="z", verts=20)
    A["butt"] = Vector((-0.362, 0, -0.038)); A["fore"] = Vector((0.17, 0, -0.036))
elif NAME == "axe":           # fire axe: long wood haft with grip tape, red head, polished edge, back pick, steel collar
    cyl((0.12, 0, 0.0), 0.021, 0.66, WOOD, verts=24)                                  # haft (round: it reads as held in a fist)
    cyl((-0.13, 0, 0.0), 0.025, 0.15, RUB, verts=24)                                  # rubber grip sleeve
    for k in range(5): ring((-0.195 + k * 0.032, 0, 0.0), 0.025, 0.0035, RUB, segs=24)   # grip ridges
    cyl((-0.212, 0, 0.0), 0.03, 0.022, RUB, verts=24)                                 # knob
    box((0.40, 0, 0.0), (0.06, 0.032, 0.044), STEEL, bev=0.008)                       # collar
    head = [(0.38, 0.022), (0.43, 0.022), (0.44, 0.05), (0.49, 0.09), (0.525, 0.12), (0.53, 0.138)]
    edge = [(0.52, 0.15), (0.48, 0.158), (0.43, 0.16), (0.38, 0.156), (0.345, 0.146), (0.335, 0.132)]
    slab(head + edge + [(0.345, 0.115), (0.365, 0.08), (0.373, 0.05)], 0.028, RED, bev=0.008)   # blade (up = +Z)
    slab([(0.53, 0.138), (0.52, 0.15), (0.48, 0.158), (0.43, 0.16), (0.38, 0.156), (0.345, 0.146), (0.335, 0.132),
          (0.35, 0.128), (0.43, 0.14), (0.515, 0.128)], 0.03, STEEL, bev=0.004)       # polished edge
    slab([(0.383, -0.022), (0.427, -0.022), (0.42, -0.07), (0.41, -0.125), (0.405, -0.135), (0.40, -0.125), (0.39, -0.07)], 0.024, RED, bev=0.006)   # back pick
    box((0.405, 0, 0.026), (0.05, 0.034, 0.012), STEEL, bev=0.004)
    for s in (1, -1): box((0.405, 0.0135 * s, 0.1), (0.07, 0.002, 0.014), WHITE, bev=0.001)   # white stencil band
    A["grip"] = Vector((-0.15, 0, 0.0)); A["fore"] = Vector((0.08, 0, 0.0)); A["butt"] = Vector((-0.225, 0, 0.0))
elif NAME == "flamer":        # flamethrower: steel wand + perforated heat shield, red fuel tank under it with gauge + valve, hose, pilot light
    box((0.0, 0, 0.0), (0.22, 0.05, 0.06), GUN)                                       # body
    box((0.0, 0, 0.034), (0.18, 0.04, 0.012), DGR)
    stripes(-0.09, -0.01, 0.0, -0.0262, 0.035, 6); stripes(-0.09, -0.01, 0.0, 0.0262, 0.035, 6)
    cyl((0.22, 0, 0.01), 0.022, 0.26, STEEL, verts=40)                                # wand
    cyl((0.24, 0, 0.01), 0.032, 0.18, DGR, verts=40)                                  # heat shield
    for k in range(7):
        for a in range(8):
            th = a / 8 * math.tau
            cyl((0.17 + k * 0.022, math.cos(th) * 0.0325, 0.01 + math.sin(th) * 0.0325), 0.005, 0.003, BLK, axis="y", verts=12, bev=0,
                rot=(th - math.pi / 2, 0, 0))
    cyl((0.37, 0, 0.01), 0.026, 0.04, BLK, verts=32, r2=0.018)                        # nozzle
    cyl((0.392, 0, 0.01), 0.012, 0.006, BLK, verts=24)
    box((0.355, 0, -0.03), (0.03, 0.014, 0.016), STEEL, bev=0.004)                    # igniter bracket
    cyl((0.375, 0, -0.03), 0.006, 0.012, FLAME, verts=16, r2=0.001)                   # pilot flame
    cyl((0.10, 0, -0.07), 0.042, 0.22, RED, verts=40)                                 # fuel tank
    for x in (0.0, 0.2): cyl((x, 0, -0.07), 0.044, 0.014, STEEL, verts=40)
    cyl((0.005, 0, -0.07), 0.03, 0.02, STEEL, verts=32)                               # tank cap
    cyl((0.10, -0.044, -0.06), 0.016, 0.01, WHITE, axis="y", verts=32); cyl((0.10, -0.0495, -0.06), 0.017, 0.003, GLASS, axis="y", verts=32)   # gauge
    box((0.104, -0.051, -0.056), (0.012, 0.001, 0.002), RED, bev=0.0005, rot=(0, 0.6, 0))
    for k in range(2): box((0.05 + k * 0.1, 0, -0.025), (0.02, 0.03, 0.02), BLK, bev=0.006)   # tank straps
    cyl((0.19, 0.022, -0.04), 0.008, 0.03, BRASS, axis="z", verts=16); box((0.19, 0.022, -0.02), (0.03, 0.006, 0.006), RED, bev=0.002)   # valve
    tube([(0.205, 0.0, -0.075), (0.25, 0.015, -0.05), (0.26, 0.02, -0.01), (0.24, 0.01, 0.01)], 0.008, RUB)   # fuel hose
    A["grip"] = grip(-0.08, -0.03, RUB, h=0.10); trigger_guard(-0.055, -0.035)
    box((0.27, 0, -0.045), (0.026, 0.026, 0.07), RUB)                                 # front grip on the wand
    box((-0.14, 0, -0.01), (0.10, 0.03, 0.05), GUN); box((-0.195, 0, -0.015), (0.014, 0.04, 0.08), RUB, bev=0.004)   # short stock
    A["butt"] = Vector((-0.20, 0, -0.015)); A["fore"] = Vector((0.27, 0, -0.07))
elif NAME == "nailgun":       # cordless framing nailer: yellow body, black overmould grip, battery with LEDs, angled nail strip
    slab([(-0.05, 0.03), (0.13, 0.03), (0.15, 0.0), (0.15, -0.025), (0.02, -0.025), (-0.06, 0.0)], 0.046, YEL, bev=0.008)   # body
    box((0.04, 0, 0.034), (0.12, 0.036, 0.012), BLK, bev=0.004)                     # top cap
    box((0.155, 0, -0.01), (0.02, 0.026, 0.03), BLK, bev=0.006)                      # nose
    cyl((0.172, 0, -0.012), 0.006, 0.02, STEEL, verts=16)                             # safety contact tip
    box((-0.03, 0, -0.065), (0.036, 0.032, 0.09), RUB, rot=(0, 0.25, 0))              # grip
    A["grip"] = Vector((-0.04, 0, -0.06)); trigger_guard(-0.008, -0.03)
    box((-0.045, 0, -0.125), (0.08, 0.05, 0.035), BLK)                                # battery
    box((-0.045, -0.0255, -0.125), (0.05, 0.002, 0.012), YEL, bev=0.001)
    for k in range(3): cyl((-0.07 + k * 0.012, -0.026, -0.112), 0.003, 0.003, LED, axis="y", verts=12, bev=0)
    box((0.09, 0, -0.065), (0.022, 0.034, 0.09), DGR, rot=(0, -0.5, 0))               # nail magazine
    for k in range(9): cyl((0.105 - k * 0.0065, 0, -0.035 - k * 0.0095), 0.0025, 0.03, STEEL, axis="y", verts=8, bev=0, rot=(0, 0, 0))
    for s in (1, -1):
        for k in range(4): box((0.02 + k * 0.016, 0.0235 * s, 0.012), (0.008, 0.003, 0.02), BLK, bev=0.002)   # motor vents
        box((0.11, 0.0235 * s, -0.004), (0.05, 0.003, 0.02), BLK, bev=0.002)
    cyl((0.135, 0, 0.022), 0.012, 0.02, RED, axis="y", verts=24)                      # depth wheel
    box((-0.05, 0.03, -0.05), (0.008, 0.012, 0.05), STEEL, bev=0.003)                # belt hook
    A["butt"] = Vector((-0.07, 0, 0.0)); A["fore"] = Vector((0.09, 0, -0.08))
elif NAME == "xbow":          # explosive crossbow: tan/black stock, recurve limbs with cams, string, scope, loaded red explosive bolt
    box((0.08, 0, 0.0), (0.42, 0.034, 0.04), BLK)                                    # rail / barrel
    box((0.10, 0, 0.024), (0.36, 0.012, 0.008), DGR, bev=0.003)                      # flight groove
    box((0.0, 0, -0.012), (0.12, 0.044, 0.05), mat("G_Tan", (0.62, 0.53, 0.38), 0.65))
    for s in (1, -1):                                                                 # limbs swept back + cams
        tube([(0.29, 0.0, 0.0), (0.30, 0.09 * s, -0.005), (0.27, 0.17 * s, -0.005), (0.24, 0.23 * s, 0.0)], 0.009, DGR)
        cyl((0.24, 0.23 * s, 0.0), 0.022, 0.012, GUN, axis="z", verts=32)
        cyl((0.24, 0.23 * s, 0.0), 0.007, 0.016, STEEL, axis="z", verts=16)
        tube([(0.232, 0.225 * s, 0.0), (0.12, 0.10 * s, 0.006), (0.06, 0.0, 0.012)], 0.0018, WHITE)   # string
    box((0.29, 0, 0.0), (0.03, 0.06, 0.044), GUN)                                     # riser
    box((0.31, 0, -0.04), (0.012, 0.012, 0.05), STEEL)                                # stirrup
    box((0.32, 0, -0.065), (0.06, 0.05, 0.008), STEEL, bev=0.003)
    B0 = len(OBJS)                                                                    # the loaded bolt: its own mesh "Bolt" (hidden when fired)
    cyl((0.13, 0, 0.012), 0.004, 0.38, STEEL, verts=12)                               # bolt shaft
    cyl((0.33, 0, 0.012), 0.012, 0.04, RED, verts=24)                                 # explosive head
    for k in range(2): cyl((0.317 + k * 0.02, 0, 0.012), 0.0125, 0.004, YEL, verts=24)
    cyl((0.36, 0, 0.012), 0.012, 0.022, RED, verts=24, r2=0.002)
    for a in range(3):                                                                # fletching
        th = a / 3 * math.tau
        box((-0.03, math.cos(th) * 0.008, 0.012 + math.sin(th) * 0.008), (0.04, 0.002, 0.012), mat("Z_Orange", (0.95, 0.52, 0.10), 0.45), bev=0.001, rot=(th, 0, 0))
    BOLT = OBJS[B0:]; del OBJS[B0:]
    cyl((0.06, 0, 0.075), 0.017, 0.15, BLK, verts=40)                                 # scope
    cyl((0.14, 0, 0.075), 0.022, 0.03, BLK, verts=40); cyl((0.156, 0, 0.075), 0.019, 0.003, GLASS, verts=40)
    for x in (0.02, 0.10): box((x, 0, 0.045), (0.016, 0.024, 0.04), BLK)
    A["grip"] = grip(-0.06, -0.03, BLK); trigger_guard(-0.035, -0.034)
    box((0.17, 0, -0.045), (0.08, 0.04, 0.04), mat("G_Tan", (0.62, 0.53, 0.38), 0.65))   # forend
    slab([(-0.08, 0.01), (-0.26, -0.01), (-0.27, -0.09), (-0.24, -0.09), (-0.12, -0.04), (-0.08, -0.03)], 0.038, mat("G_Tan", (0.62, 0.53, 0.38), 0.65), bev=0.008)   # skeleton stock
    box((-0.272, 0, -0.05), (0.01, 0.042, 0.1), RUB, bev=0.003)
    A["butt"] = Vector((-0.275, 0, -0.05)); A["fore"] = Vector((0.17, 0, -0.065))
else:                         # tesla: dark receiver, glass tube with glow, copper coils, ceramic insulators, 3 electrode prongs, capacitor drum
    box((0.0, 0, 0.0), (0.20, 0.05, 0.065), GUN)                                      # receiver
    box((0.0, 0, 0.038), (0.16, 0.04, 0.012), DGR)
    cyl((-0.02, 0, 0.065), 0.035, 0.11, COPPER, verts=40)                             # capacitor drum on top
    for k in range(5): ring((-0.065 + k * 0.022, 0, 0.065), 0.036, 0.0035, GUN)
    cyl((0.20, 0, 0.012), 0.018, 0.22, GLOW, verts=40)                                 # energy tube
    cyl((0.20, 0, 0.012), 0.0245, 0.22, mat("Z_Glass", (0.75, 0.9, 1.0), 0.05, 0.0), verts=40)
    for k in range(6): ring((0.11 + k * 0.035, 0, 0.012), 0.028, 0.006, COPPER)       # coils
    for x in (0.10, 0.31):                                                            # end caps
        cyl((x, 0, 0.012), 0.032, 0.02, GUN, verts=40)
    for k in range(3):                                                                # ceramic insulator stack
        cyl((0.06 + k * 0.014, 0, 0.012), 0.03 - k * 0.003, 0.009, WHITE, verts=32)
    for a in range(3):                                                                # electrode prongs converging
        th = a / 3 * math.tau + math.pi / 2
        y = math.cos(th) * 0.024; z = 0.012 + math.sin(th) * 0.024
        tube([(0.31, y, z), (0.36, y * 1.25, z * 1.0 + (0.004 if z > 0.012 else -0.004)), (0.40, y * 0.35, 0.012 + (z - 0.012) * 0.35)], 0.004, COPPER)
        cyl((0.40, y * 0.35, 0.012 + (z - 0.012) * 0.35), 0.006, 0.01, GLOW, verts=16, bev=0)
    tube([(-0.06, 0.03, 0.06), (0.0, 0.04, 0.02), (0.08, 0.034, 0.02), (0.11, 0.028, 0.02)], 0.004, RED)   # cables
    tube([(-0.06, -0.03, 0.06), (0.0, -0.04, 0.02), (0.08, -0.034, 0.02), (0.11, -0.028, 0.02)], 0.004, BLK)
    A["grip"] = grip(-0.07, -0.033, RUB); trigger_guard(-0.045, -0.037)
    box((0.04, 0, -0.065), (0.06, 0.044, 0.05), BLK)                                  # battery
    box((0.04, -0.0225, -0.065), (0.03, 0.002, 0.016), GLOW, bev=0.001)
    box((0.20, 0, -0.04), (0.026, 0.026, 0.06), RUB)                                  # front grip
    box((-0.15, 0, -0.012), (0.10, 0.03, 0.05), GUN); box((-0.205, 0, -0.02), (0.014, 0.04, 0.085), RUB, bev=0.004)
    A["butt"] = Vector((-0.21, 0, -0.02)); A["fore"] = Vector((0.20, 0, -0.07))

for x in bpy.context.selected_objects: x.select_set(False)
for o in OBJS: o.select_set(True)
bpy.context.view_layer.objects.active = OBJS[0]
bpy.ops.object.join()
gun = bpy.context.active_object; gun.name = NAME
vs = [v.co.copy() for v in gun.data.vertices]
if "BOLT" in globals() and BOLT:
    for x in bpy.context.selected_objects: x.select_set(False)
    for o in BOLT: o.select_set(True)
    bpy.context.view_layer.objects.active = BOLT[0]; bpy.ops.object.join()
    bolt = bpy.context.active_object; bolt.name = "Bolt"; bolt.data.name = "Bolt"
    vs += [v.co.copy() for v in bolt.data.vertices]
    gun.select_set(True)
x0 = min(v.x for v in vs); x1 = max(v.x for v in vs); L = x1 - x0
zc = (min(v.z for v in vs) + max(v.z for v in vs)) / 2
for k in ("butt", "grip", "fore"):
    p = A[k]
    print("ANCHOR %s %s [%.2f, %.2f]" % (NAME, k, (p.x - x0) / L, (p.z - zc) / L))
print("LEN %s %.3f tris %d" % (NAME, L, sum(len(p.vertices) - 2 for p in gun.data.polygons)))
import os; os.makedirs("/tmp/zg", exist_ok=True)
if "--export" in ARGV:        # into the game (glTF: Y up, the game turns +X to the muzzle / blade end)
    bpy.ops.export_scene.gltf(filepath="/home/user/Reborn/game/assets/guns/%s.glb" % NAME, export_format="GLB", use_selection=True, export_materials="EXPORT")
bpy.ops.wm.save_as_mainfile(filepath="/tmp/zg/%s.blend" % NAME)
if RENDER:                    # 3/4 beauty shot for the concept sheet
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"; sc.render.resolution_x = 900; sc.render.resolution_y = 520
    sc.eevee.use_gtao = True; sc.eevee.gtao_distance = 0.05; sc.eevee.use_soft_shadows = True; sc.eevee.use_bloom = True
    sc.eevee.taa_render_samples = 64
    sc.render.film_transparent = True; sc.view_settings.view_transform = "Filmic"; sc.view_settings.look = "Medium High Contrast"
    w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.55, 0.58, 0.62, 1); w.node_tree.nodes["Background"].inputs[1].default_value = 0.7
    for rot, e, col in (((55, 10, 35), 4.0, (1.0, 0.96, 0.9)), ((65, 0, 215), 2.5, (0.75, 0.85, 1.0)), ((-20, 0, 120), 1.2, (1, 1, 1))):
        l = bpy.data.objects.new("l", bpy.data.lights.new("l", "SUN")); sc.collection.objects.link(l)
        l.rotation_euler = [math.radians(a) for a in rot]; l.data.energy = e; l.data.color = col; l.data.angle = math.radians(8)
    ys = [v.y for v in vs]; zs = [v.z for v in vs]
    tgt = Vector(((x0 + x1) / 2, (min(ys) + max(ys)) / 2, (min(zs) + max(zs)) / 2))
    ext = max(L, max(zs) - min(zs), max(ys) - min(ys))
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
    cam.data.lens = 70
    d = Vector((0.33, -1.0, 0.3)).normalized()
    cam.location = tgt + d * (ext * 2.7)
    cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = "/tmp/zg/%s.png" % NAME
    bpy.ops.render.render(write_still=True)
    print("RENDERED", NAME)
