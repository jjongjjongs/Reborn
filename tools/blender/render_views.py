import bpy, math, mathutils
W, H = 200, 150
def V(x, y, z): return mathutils.Vector((x - W/2, -(y - H/2), z))
sc = bpy.context.scene
for o in [o for o in bpy.data.objects if o.type in ("CAMERA", "LIGHT")]:
    bpy.data.objects.remove(o, do_unlink=True)
sun_d = bpy.data.lights.new("Sun", "SUN"); sun_d.energy = 3.2; sun_d.angle = math.radians(3)
sun_d.color = (1.0, 0.95, 0.86)
sun = bpy.data.objects.new("Sun", sun_d); sc.collection.objects.link(sun)
sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(-35))
w = sc.world or bpy.data.worlds.new("World"); sc.world = w; w.use_nodes = True
bg = w.node_tree.nodes["Background"]; bg.inputs[0].default_value = (0.62, 0.74, 0.88, 1); bg.inputs[1].default_value = 0.9
sc.render.engine = "BLENDER_EEVEE"
sc.eevee.use_shadows = True if hasattr(sc.eevee, "use_shadows") else None
sc.eevee.shadow_cascade_size = "2048"
sc.eevee.use_gtao = True
sc.render.resolution_x, sc.render.resolution_y = 1280, 720
sc.view_settings.view_transform = "Standard"
cam_d = bpy.data.cameras.new("Cam"); cam = bpy.data.objects.new("Cam", cam_d); sc.collection.objects.link(cam); sc.camera = cam
for o in bpy.data.objects:
    if o.name.startswith("col_"): o.hide_render = True
views = {
    "overview": ((100, 205, 150), (100, 70, 0), 50),
    "top": ((100, 75, 260), (100, 74.9, 0), 40),
    "att_spawn": ((100, 143, 1.7), (98, 110, 1.6), 75),
    "west_road": ((40, 126, 1.7), (28, 92, 3.0), 75),
    "stairs": ((66, 114, 1.8), (57, 84, 5.0), 75),
    "siteA": ((66, 64, 6.5), (46, 50, 4.0), 70),
    "mid": ((104, 100, 1.7), (100, 74, 1.6), 75),
    "east_street": ((134, 136, 1.7), (166, 112, 1.6), 75),
    "under": ((122, 124, 1.6), (140, 104, 1.6), 75),
    "siteB": ((150, 92, 1.7), (165, 62, 1.6), 75),
    "def_spawn": ((100, 10, 1.7), (100, 40, 1.6), 75),
}
out = []
for name, (p, t, fov) in views.items():
    cam.location = V(*p)
    d = V(*t) - V(*p)
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    cam_d.angle = math.radians(fov)
    sc.render.filepath = "/tmp/bwork/r_%s.png" % name
    bpy.ops.render.render(write_still=True)
    out.append(name)
print("RENDERED", out)
