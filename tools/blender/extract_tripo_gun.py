import bpy, bmesh, math
from mathutils import Vector
OUT = "/tmp/tripo_out/ar9r.glb"
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)
log = []
bpy.ops.import_scene.gltf(filepath="/tmp/tripo_out/a.glb")
mesh = [o for o in bpy.data.objects if o.type == "MESH"][0]
for o in bpy.context.selected_objects: o.select_set(False)
bpy.context.view_layer.objects.active = mesh; mesh.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
# the rifle on the sheet (box from the loose-part split)
mn = Vector((-0.032, -0.079, -0.306)) - Vector((0.003, 0.003, 0.003))
mx = Vector((-0.032 + 0.081, -0.079 + 0.265, -0.306 + 0.159)) + Vector((0.003, 0.003, 0.003))
bm = bmesh.new(); bm.from_mesh(mesh.data)
bmesh.ops.delete(bm, geom=[v for v in bm.verts if not (mn.x <= v.co.x <= mx.x and mn.y <= v.co.y <= mx.y and mn.z <= v.co.z <= mx.z)], context="VERTS")
bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=0.0002)
bm.to_mesh(mesh.data); bm.free()
log.append("gun faces %d" % len(mesh.data.polygons))
dec = mesh.modifiers.new("dec", "DECIMATE"); dec.ratio = min(1.0, 7000.0 / max(len(mesh.data.polygons), 1))
bpy.ops.object.modifier_apply(modifier="dec")
log.append("decimated %d" % len(mesh.data.polygons))
# length is along Y on the sheet: turn it onto X
for v in mesh.data.vertices:
    v.co = Vector((v.co.y, -v.co.x, v.co.z))
vs = [v.co.copy() for v in mesh.data.vertices]
x0 = min(v.x for v in vs); x1 = max(v.x for v in vs); L = x1 - x0
def sl(a, b): return [v for v in vs if x0 + L * a <= v.x <= x0 + L * b]
def zext(s): return (max(v.z for v in s) - min(v.z for v in s)) if s else 0.0
# muzzle = the thinner end (barrel), stock = the taller end
flip_x = zext(sl(0.0, 0.08)) < zext(sl(0.92, 1.0))
if flip_x:
    for v in mesh.data.vertices: v.co.x = -v.co.x; v.co.y = -v.co.y
vs = [v.co.copy() for v in mesh.data.vertices]
x0 = min(v.x for v in vs); x1 = max(v.x for v in vs); L = x1 - x0
bar = sl(0.9, 1.0); zb = sum(v.z for v in bar) / max(len(bar), 1)
mid = sl(0.3, 0.55)
up = max(v.z for v in mid) - zb; down = zb - min(v.z for v in mid)
# the magazine hangs further below the barrel line than the sight rises above it
flip_z = up > down
if flip_z:
    for v in mesh.data.vertices: v.co.z = -v.co.z; v.co.y = -v.co.y
vs = [v.co.copy() for v in mesh.data.vertices]
c = Vector([(min(v[i] for v in vs) + max(v[i] for v in vs)) / 2 for i in range(3)])
for v in mesh.data.vertices: v.co -= c
mesh.data.update()
log.append("len %.3f flip_x %s flip_z %s up %.3f down %.3f" % (L, flip_x, flip_z, up, down))
for img in bpy.data.images:
    if img.size[0] > 1024: img.scale(1024, 1024)
mesh.name = "AR9R"
for o in bpy.context.selected_objects: o.select_set(False)
mesh.select_set(True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_materials="EXPORT",
    export_image_format="JPEG", export_cameras=False, export_lights=False)
# quick side render for checking orientation
scn = bpy.context.scene
scn.render.engine = "BLENDER_EEVEE"; scn.render.resolution_x = 900; scn.render.resolution_y = 450
world = bpy.data.worlds.new("w"); scn.world = world; world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.6, 0.62, 0.65, 1)
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN")); scn.collection.objects.link(sun)
sun.rotation_euler = (math.radians(40), 0, math.radians(20)); sun.data.energy = 3.0
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); scn.collection.objects.link(cam); scn.camera = cam
cam.data.type = "ORTHO"; cam.data.ortho_scale = L * 1.15
cam.location = (0, -1, 0); cam.rotation_euler = (math.pi / 2, 0, 0)       # looking +Y: +X to the right, +Z up
scn.render.filepath = "/tmp/tripo_out/gun_side.png"
bpy.ops.render.render(write_still=True)
open("/tmp/bwork/tripo_gun.txt", "w").write("\n".join(log))
print("\n".join(log))
