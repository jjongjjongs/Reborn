# export the temple map for the game: blender -b --python export_temple.py
#  game/assets/maps/temple.gltf (+bin): Col_* meshes get collisions in Godot, Vis_* are visual only;
#  trees stay instances (2 shared meshes). temple.json: spawns / sites / bounds / outline / tree trunks.
#  temple_overview.png: top-down render for the radar (covers exactly x -70..70, z -60..60).
import bpy, json, math, os, sys
from mathutils import Vector
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "maps"))
from temple_layout import *
import numpy as np
bpy.ops.wm.open_mainfile(filepath="/tmp/gbg/temple.blend")
D = np.load("/tmp/gbg/temple_hm.npz"); HM = D["h"]; RES = float(D["res"]); MG = float(D["margin"])
def hat(x, y):
    i = int(round((x + MG) * RES)); j = int(round((y + MG) * RES)); return float(HM[j, i])
OUTDIR = "/home/user/Reborn/game/assets/maps"
groups = {"Col_Terrain": [], "Col_Walls": [], "Col_Buildings": [], "Col_Stone": [], "Col_Rocks": [], "Vis_Steps": [], "Vis_Water": [], "Vis_Cave": []}
trees = []
for o in list(bpy.data.objects):
    if o.type != "MESH": continue
    n = o.name
    if n.startswith("tree"):
        if o.location.z > -50: trees.append(o)
        continue
    if o.location.z < -50: bpy.data.objects.remove(o); continue           # tree prototypes
    key = ("Col_Terrain" if n.startswith("Terrain") else "Col_Walls" if n.startswith("Walls") else
           "Col_Buildings" if n.startswith("Bld_") else "Vis_Steps" if n.startswith("Step") else
           "Vis_Water" if n.startswith(("Pond", "Stream")) else "Vis_Cave" if n.startswith("CaveRock") else "Col_Rocks" if n.startswith("Rock") else "Col_Stone")
    groups[key].append(o)
# buildings: one object per building with its material colours baked into vertex colours and one material,
# so each is 1 draw call, culled off screen / out of shadow range and LOD'd by distance (was one 126k-tri mesh)
BVC = bpy.data.materials.new("BldVC"); BVC.use_nodes = True; BVC.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.7
for k, o in enumerate(groups["Col_Buildings"]):
    me = o.data
    cols = []
    for m in me.materials:
        c = (0.8, 0.8, 0.8)
        if m and m.use_nodes and "Principled BSDF" in m.node_tree.nodes: c = tuple(m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value)[:3]
        elif m: c = tuple(m.diffuse_color)[:3]
        cols.append(c)
    for a_ in list(me.color_attributes): me.color_attributes.remove(a_)
    ca = me.color_attributes.new("Col", "BYTE_COLOR", "CORNER")
    for p in me.polygons:
        c = cols[p.material_index] if cols else (0.8, 0.8, 0.8)
        for li in p.loop_indices: ca.data[li].color = (c[0], c[1], c[2], 1.0)
    me.materials.clear(); me.materials.append(BVC)
    o.name = "Col_Buildings_%02d" % k
    for x in bpy.context.selected_objects: x.select_set(False)
    o.select_set(True); bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
groups["Col_Buildings"] = []
for key, objs in groups.items():
    if not objs: continue
    for x in bpy.context.selected_objects: x.select_set(False)
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1: bpy.ops.object.join()
    j = bpy.context.active_object; j.name = key
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if key == "Col_Terrain":                                           # phone budget: ~70k triangles
        md = j.modifiers.new("d", "DECIMATE"); md.ratio = 0.28; bpy.ops.object.modifier_apply(modifier="d")
        # 4 x 4 chunks: off-screen pieces are culled, far ones LOD'd (one 70k mesh was always drawn whole)
        import bmesh as _bm
        src = j; xs = [v.co.x for v in src.data.vertices]; ys = [v.co.y for v in src.data.vertices]
        x0, x1, y0, y1 = min(xs), max(xs) + 0.01, min(ys), max(ys) + 0.01
        for ci in range(4):
            for cj in range(4):
                bm = _bm.new(); bm.from_mesh(src.data)
                gx0 = x0 + (x1 - x0) * ci / 4; gx1 = x0 + (x1 - x0) * (ci + 1) / 4
                gy0 = y0 + (y1 - y0) * cj / 4; gy1 = y0 + (y1 - y0) * (cj + 1) / 4
                dead = [f for f in bm.faces if not (gx0 <= f.calc_center_median().x < gx1 and gy0 <= f.calc_center_median().y < gy1)]
                _bm.ops.delete(bm, geom=dead, context="FACES")
                if len(bm.faces) == 0: bm.free(); continue
                me = bpy.data.meshes.new("Col_Terrain_%d%d" % (ci, cj)); bm.to_mesh(me); bm.free()
                if me.color_attributes:
                    me.color_attributes.active_color = me.color_attributes[0]; me.color_attributes.render_color_index = 0
                for m in src.data.materials: me.materials.append(m)
                bpy.context.scene.collection.objects.link(bpy.data.objects.new("Col_Terrain_%d%d" % (ci, cj), me))
        bpy.data.objects.remove(src); print("terrain chunks"); continue
    print(key, len(j.data.polygons))
# trees: under one empty, shared meshes
for t in trees: t.name = "Vis_Tree"
for x in bpy.context.selected_objects: x.select_set(False)
for o in bpy.data.objects: o.select_set(o.type == "MESH")
bpy.ops.export_scene.gltf(filepath=OUTDIR + "/temple.gltf", export_format="GLTF_SEPARATE", export_texture_dir="tex", use_selection=True,
    export_apply=True, export_materials="EXPORT", export_colors=True, export_cameras=False, export_lights=False)
# game data (Godot: x = px - 70, z = py - 60)
def G(x, y, up=1.0): return [x - 70.0, hat(x, y) + up, y - 60.0]
def ring(c, r0, n, rr=2.2):
    pts = [c]; k = 0
    while len(pts) < n:
        a = k * 2.4; r = rr * (1 + k // 6); pts.append((c[0] + math.cos(a) * r, c[1] + math.sin(a) * r)); k += 1
    return pts
att = [G(x, y) for x, y in ring(ATT_SPAWN, 0, 6)]
dfn = [G(x, y) for x, y in ring(DEF_SPAWN, 0, 6)]
def poly_c(c, rx, ry): return [[c[0] - 70 + math.cos(a) * rx, c[1] - 60 + math.sin(a) * ry] for a in [i * math.pi / 8 for i in range(16)]]
inside_trees = [[t.location.x, t.location.z, -t.location.y] for t in trees if inside((t.location.x + 70, 60 - t.location.y), OUTLINE)]
data = {"bounds": [-70, -60, 140, 120], "att": att, "def": dfn,
        "site_a": poly_c(SITE_A, 11, 8), "site_b": poly_c(SITE_B, 13, 10),
        "site_a_c": G(*SITE_A, 0.0), "site_b_c": [SITE_B[0] - 70, GH_BASE, SITE_B[1] - 60],
        "mid": G(80, 72, 0.5), "outline": [[x - 70, y - 60] for x, y in OUTLINE],
        "trunks": inside_trees,
        "cave": [[r[0][0] - 70, r[0][2], r[0][1] - 60, r[1][0] - 70, r[1][2], r[1][1] - 60, r[2]] for r in RAMPS if r[3] == "cave"]}
json.dump(data, open(OUTDIR + "/temple.json", "w"))
# radar overview: orthographic top render covering the bounds exactly
sc = bpy.context.scene
for o in list(bpy.data.objects):
    if o.name.startswith("Vis_Tree"): o.hide_render = True              # see the ground under the trees
sc.render.engine = "BLENDER_EEVEE"; sc.render.resolution_x = 1120; sc.render.resolution_y = 960
sc.view_settings.view_transform = "Standard"
w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True; w.node_tree.nodes["Background"].inputs[1].default_value = 0.8
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN")); sc.collection.objects.link(sun); sun.rotation_euler = (0.3, 0.2, 0); sun.data.energy = 2.5
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
cam.data.type = "ORTHO"; cam.data.ortho_scale = 140; cam.location = (0, 0, 120); cam.rotation_euler = (0, 0, 0)
sc.render.filepath = OUTDIR + "/temple_overview.png"; sc.render.image_settings.file_format = "PNG"
bpy.ops.render.render(write_still=True)
print("EXPORTED trees", len(trees), "trunks in map", len(inside_trees))
