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
def _finish(o, material, bone, group):
    o.data.materials.clear(); o.data.materials.append(material)
    for p in o.data.polygons: p.use_smooth = False
    vg = o.vertex_groups.new(name=bone); vg.add(list(range(len(o.data.vertices))), 1.0, "REPLACE")
    parts.setdefault(group, []).append(o)
    return o

def ellipsoid(c, r, material, bone, group="Mini_Body", seg=10, rings=6, rot=None):
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
    md = o.modifiers.new("b", "BEVEL"); md.width = bevel; md.segments = 2
    bpy.ops.object.modifier_apply(modifier="b")
    return _finish(o, material, bone, group)

def cyl(c, r, depth, material, bone, group="Mini_Body", rot=(0, 0, 0), verts=12):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=c, rotation=rot)
    o = bpy.context.active_object
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return _finish(o, material, bone, group)

def dome(c, r, cut_z, material, bone, group):
    o = ellipsoid(c, r, material, bone, group, seg=14, rings=8)
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

# ---- body ----
rbox((0, -0.045, 1.02), (0.36, 0.24, 0.22), UNIFORM, "Hips", bevel=0.05)
rbox((0, -0.045, 1.28), (0.40, 0.26, 0.32), UNIFORM, "Chest", bevel=0.06)
rbox((0, -0.05, 1.27), (0.46, 0.31, 0.34), KIT, "Chest", bevel=0.05)          # plate carrier
for x in (-0.12, 0.0, 0.12):
    rbox((x, -0.215, 1.17), (0.095, 0.05, 0.10), KIT, "Chest", bevel=0.015)   # pouches
rbox((0.12, -0.21, 1.36), (0.07, 0.04, 0.05), BADGE, "Chest", bevel=0.01)     # name tag
rbox((0, 0.15, 1.28), (0.30, 0.13, 0.30), KIT, "Chest", bevel=0.04)            # small backpack
rbox((0, -0.045, 0.94), (0.40, 0.27, 0.06), BOOT, "Hips", bevel=0.015)         # belt
for s in (1, -1):
    L = "L" if s > 0 else "R"
    ellipsoid((0.20 * s, -0.05, 1.43), (0.085, 0.09, 0.075), UNIFORM, "UpperArm." + L)
    limb((0.16 * s, -0.06, 1.432), (0.334 * s, -0.056, 1.432), 0.068, UNIFORM, "UpperArm." + L)
    limb((0.334 * s, -0.056, 1.432), (0.55 * s, -0.08, 1.432), 0.062, UNIFORM, "LowerArm." + L)
    rbox((0.62 * s, -0.095, 1.43), (0.15, 0.11, 0.095), BOOT, "Hand." + L, bevel=0.03)   # glove
    limb((0.121 * s, -0.045, 0.94), (0.121 * s, -0.087, 0.533), 0.092, UNIFORM, "UpperLeg." + L)
    limb((0.121 * s, -0.087, 0.533), (0.121 * s, -0.07, 0.13), 0.08, UNIFORM, "LowerLeg." + L)
    ellipsoid((0.121 * s, -0.16, 0.53), (0.06, 0.035, 0.07), KIT, "LowerLeg." + L)          # knee pad
    rbox((0.121 * s, -0.10, 0.075), (0.16, 0.30, 0.15), BOOT, "Foot." + L, bevel=0.04)      # boot

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
