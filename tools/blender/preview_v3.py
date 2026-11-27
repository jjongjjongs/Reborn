# blender -b --python preview_v3.py -- CLASS : front / side / back / face renders of /tmp/mv3/CLASS.blend
import bpy, math, sys
from mathutils import Vector
CLASS = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.open_mainfile(filepath="/tmp/mv3/%s.blend" % CLASS)
sc = bpy.context.scene
sc.render.engine = "BLENDER_EEVEE"; sc.render.resolution_x = 700; sc.render.resolution_y = 900
sc.eevee.use_gtao = True; sc.eevee.gtao_distance = 0.2; sc.eevee.use_soft_shadows = True
sc.view_settings.view_transform = "Standard"
w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.85, 0.86, 0.88, 1); w.node_tree.nodes["Background"].inputs[1].default_value = 0.9
for rot, e in (((50, 0, 30), 3.0), ((60, 0, 200), 1.2)):
    l = bpy.data.objects.new("l", bpy.data.lights.new("l", "SUN")); sc.collection.objects.link(l)
    l.rotation_euler = [math.radians(a) for a in rot]; l.data.energy = e
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
cam.data.type = "ORTHO"
for name, d, c, scl in [("front", Vector((0, -1, 0)), Vector((0, 0, 0.98)), 2.3), ("side", Vector((1, -0.15, 0)), Vector((0, 0, 0.98)), 2.3),
                        ("back", Vector((0, 1, 0)), Vector((0, 0, 0.98)), 2.3), ("face", Vector((0.25, -1, 0.05)), Vector((0, 0, 1.48)), 0.85)]:
    cam.data.ortho_scale = scl
    cam.location = c + d.normalized() * 5
    cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = "/tmp/mv3/%s_%s.png" % (CLASS, name)
    bpy.ops.render.render(write_still=True)
print("RENDERED")
