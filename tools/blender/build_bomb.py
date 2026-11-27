# 폭탄 (bomb) model, original design: rugged charge pack - bevelled base tray, 2x2 explosive blocks
# with tape bands, a control unit (screen + keypad + LED dome + antenna), coiled red / blue wires,
# carry handle. Material names are stable so skins can recolour them in game (Profile "bomb" items).
#   blender -b --python build_bomb.py            -> game/assets/bomb/bomb.glb (+ /tmp/bomb/bomb.blend)
import bpy, bmesh, math, os
from mathutils import Vector
bpy.ops.wm.read_factory_settings(use_empty=True)
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
MATS = {}
def mat(name, rgb, rough=0.6, metal=0.0, emit=0.0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (lin(rgb[0]), lin(rgb[1]), lin(rgb[2]), 1)
    b.inputs["Roughness"].default_value = rough; b.inputs["Metallic"].default_value = metal
    if emit:
        b.inputs["Emission Color"].default_value = (lin(rgb[0]), lin(rgb[1]), lin(rgb[2]), 1); b.inputs["Emission Strength"].default_value = emit
    MATS[name] = m; return m
CASE = mat("B_Case", (0.27, 0.29, 0.22), 0.7); CASE2 = mat("B_Case2", (0.18, 0.19, 0.16), 0.7)
CHARGE = mat("B_Charge", (0.80, 0.72, 0.55), 0.85); TAPE = mat("B_Tape", (0.12, 0.12, 0.13), 0.5)
PANEL = mat("B_Panel", (0.14, 0.15, 0.17), 0.45, 0.3); SCREEN = mat("B_Screen", (0.25, 1.0, 0.45), 0.2, 0.0, 2.5)
KEY = mat("B_Key", (0.55, 0.57, 0.6), 0.5); LED = mat("B_LED", (1.0, 0.15, 0.1), 0.2, 0.0, 4.0)
WR = mat("B_WireA", (0.85, 0.15, 0.12), 0.4); WB = mat("B_WireB", (0.15, 0.4, 0.9), 0.4)
METAL = mat("B_Metal", (0.6, 0.62, 0.65), 0.3, 0.9); STRIPE = mat("B_Stripe", (0.95, 0.75, 0.1), 0.5)
OBJS = []
def fin(o, m):
    o.data.materials.clear(); o.data.materials.append(m)
    for p in o.data.polygons: p.use_smooth = True
    OBJS.append(o); return o
def box(c, s, m, bev=0.012, seg=4):
    bpy.ops.mesh.primitive_cube_add(size=1, location=c); o = bpy.context.active_object; o.scale = s
    bpy.ops.object.transform_apply(scale=True)
    md = o.modifiers.new("b", "BEVEL"); md.width = min(bev, min(s) * 0.45); md.segments = seg; md.limit_method = "NONE"
    bpy.ops.object.modifier_apply(modifier="b"); return fin(o, m)
def cyl(c, r, h, m, rot=(0, 0, 0), v=24, bev=0.003):
    bpy.ops.mesh.primitive_cylinder_add(vertices=v, radius=r, depth=h, location=c, rotation=rot); o = bpy.context.active_object
    bpy.ops.object.transform_apply(rotation=True)
    if bev:
        md = o.modifiers.new("b", "BEVEL"); md.width = bev; md.segments = 2; md.limit_method = "ANGLE"; bpy.ops.object.modifier_apply(modifier="b")
    return fin(o, m)
def sph(c, r, m, sz=1.0):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=10, radius=r, location=c); o = bpy.context.active_object
    o.scale = (1, 1, sz); bpy.ops.object.transform_apply(scale=True); return fin(o, m)
def tube(pts, r, m):
    cu = bpy.data.curves.new("c", "CURVE"); cu.dimensions = "3D"; cu.bevel_depth = r; cu.bevel_resolution = 3; cu.resolution_u = 10
    sp = cu.splines.new("NURBS"); sp.points.add(len(pts) - 1)
    for i, p in enumerate(pts): sp.points[i].co = (p[0], p[1], p[2], 1)
    sp.use_endpoint_u = True; sp.order_u = 3; cu.use_fill_caps = True
    o = bpy.data.objects.new("c", cu); bpy.context.scene.collection.objects.link(o)
    bpy.context.view_layer.objects.active = o
    for x in bpy.context.selected_objects: x.select_set(False)
    o.select_set(True); bpy.ops.object.convert(target="MESH"); return fin(bpy.context.active_object, m)
# Blender: x right, y back, z up. Footprint ~0.46 x 0.32, height ~0.24 (+ antenna)
box((0, 0, 0.025), (0.46, 0.32, 0.05), CASE, 0.018)                       # base tray
box((0, 0, 0.052), (0.43, 0.29, 0.01), CASE2, 0.004)                      # tray rim inset
for x in (-0.2, 0.2):                                                     # hazard stripes on the tray ends
    for k in range(3): box((x, -0.11 + 0.11 * k, 0.03), (0.012, 0.05, 0.05), STRIPE, 0.003)
# 2x2 explosive blocks
for ix in (-1, 1):
    for iy in (-1, 1):
        box((0.1 * ix, 0.07 * iy, 0.105), (0.18, 0.12, 0.1), CHARGE, 0.014)
# tape bands round the blocks
for x in (-0.12, 0.12):
    box((x, 0, 0.106), (0.03, 0.3, 0.108), TAPE, 0.004)
box((0, 0, 0.106), (0.42, 0.03, 0.108), TAPE, 0.004)
# control unit on top
box((0.02, -0.01, 0.185), (0.2, 0.15, 0.06), PANEL, 0.012)
box((0.02, -0.088, 0.195), (0.13, 0.004, 0.032), SCREEN, 0.002)          # screen (front face)
box((0.02, -0.086, 0.195), (0.145, 0.004, 0.044), CASE2, 0.002)
for r in range(2):                                                         # keypad on top
    for c in range(4):
        box((-0.035 + 0.03 * c, -0.03 + 0.03 * r, 0.217), (0.022, 0.022, 0.008), KEY, 0.003)
sph((0.095, 0.03, 0.218), 0.016, LED, 0.8)                                 # LED dome
cyl((0.095, 0.03, 0.212), 0.019, 0.008, METAL)
cyl((-0.06, 0.04, 0.25), 0.004, 0.11, METAL)                               # antenna
sph((-0.06, 0.04, 0.307), 0.009, LED)
# carry handle across the back
tube([(-0.12, 0.13, 0.16), (-0.12, 0.15, 0.24), (0.0, 0.16, 0.27), (0.12, 0.15, 0.24), (0.12, 0.13, 0.16)], 0.009, CASE2)
# coiled wires: unit -> blocks
for side, m in ((-1, WR), (1, WB)):
    pts = []
    for i in range(12):
        t = i / 11.0
        a = t * math.pi * 5
        pts.append((0.02 + side * (0.1 + 0.08 * t) + 0.012 * math.cos(a), -0.06 + 0.11 * t + 0.012 * math.sin(a), 0.19 - 0.06 * t + 0.01 * math.sin(a)))
    tube(pts, 0.0045, m)
# bolts on the tray
for x in (-0.2, 0.2):
    for y in (-0.13, 0.13): cyl((x, y, 0.052), 0.008, 0.006, METAL, v=12, bev=0)
for x in bpy.context.selected_objects: x.select_set(False)
for o in OBJS: o.select_set(True)
bpy.context.view_layer.objects.active = OBJS[0]
bpy.ops.object.join()
o = bpy.context.active_object; o.name = "Bomb"
os.makedirs("/home/user/Reborn/game/assets/bomb", exist_ok=True); os.makedirs("/tmp/bomb", exist_ok=True)
bpy.ops.export_scene.gltf(filepath="/home/user/Reborn/game/assets/bomb/bomb.glb", export_format="GLB", use_selection=True, export_materials="EXPORT")
bpy.ops.wm.save_as_mainfile(filepath="/tmp/bomb/bomb.blend")
print("BOMB faces", len(o.data.polygons))
