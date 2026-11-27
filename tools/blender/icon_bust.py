# blender -b --python bust2.py -- GLB OUT RES : rigged character, arms lowered, transparent 3/4 bust
import bpy, math, sys
from mathutils import Vector, Matrix
a = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a[0])
arm = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
mesh = [o for o in bpy.data.objects if o.type == "MESH"][0]
bpy.context.view_layer.objects.active = arm; bpy.ops.object.mode_set(mode="POSE")
def rot_world(bn, axis, deg):
    pb = arm.pose.bones[bn]
    R = Matrix.Rotation(math.radians(deg), 4, axis)
    m = arm.matrix_world @ pb.matrix
    loc = m.to_translation()
    m2 = Matrix.Translation(loc) @ R @ Matrix.Translation(-loc) @ m
    pb.matrix = arm.matrix_world.inverted() @ m2
    bpy.context.view_layer.update()
for side, s in (("L", 1), ("R", -1)):
    rot_world("UpperArm." + side, Vector((0, 1, 0)), 68 * s)      # arms down by the sides
    rot_world("LowerArm." + side, Vector((1, 0, 0)), -25)          # slight bend forward
bpy.ops.object.mode_set(mode="OBJECT")
# vertex colours drive the shading in game: multiply them in here too
for m in mesh.data.materials:
    if not m or not m.use_nodes: continue
    nt = m.node_tree; b = nt.nodes.get("Principled BSDF")
    if not b: continue
    vc = nt.nodes.new("ShaderNodeVertexColor"); mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.blend_type = "MULTIPLY"
    mix.inputs[0].default_value = 1.0
    src = b.inputs["Base Color"]
    if src.links: nt.links.new(src.links[0].from_socket, mix.inputs[6])
    else: mix.inputs[6].default_value = src.default_value
    nt.links.new(vc.outputs[0], mix.inputs[7]); nt.links.new(mix.outputs[2], src)
sc = bpy.context.scene
R = int(a[2]) if len(a) > 2 else 1200
sc.render.engine = "BLENDER_EEVEE"; sc.render.resolution_x = R; sc.render.resolution_y = R
sc.render.film_transparent = True; sc.eevee.use_gtao = True; sc.eevee.gtao_distance = 0.15; sc.eevee.taa_render_samples = 64
sc.view_settings.view_transform = "Standard"
w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.9, 0.92, 0.95, 1); w.node_tree.nodes["Background"].inputs[1].default_value = 0.9
for rot, e in (((45, 0, 25), 3.0), ((70, 0, 210), 1.4), ((10, 0, 120), 0.7)):
    l = bpy.data.objects.new("l", bpy.data.lights.new("l", "SUN")); sc.collection.objects.link(l)
    l.rotation_euler = [math.radians(v) for v in rot]; l.data.energy = e
# frame the head + chest of the posed mesh
dg = bpy.context.evaluated_depsgraph_get(); me = mesh.evaluated_get(dg).to_mesh()
vs = [mesh.matrix_world @ v.co for v in me.vertices]
top = max(v.z for v in vs); H = top - min(v.z for v in vs)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
cam.data.type = "ORTHO"
hd = arm.matrix_world @ arm.pose.bones["Head"].head
c = Vector((hd.x, hd.y, hd.z + 0.16)); H = 2.1
print("HEAD", hd)
cam.data.ortho_scale = H * 0.6
d = Vector((0.35, -1, 0.08)).normalized()
cam.location = c + d * 10; cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
sc.render.filepath = a[1]
bpy.ops.render.render(write_still=True)
print("BUST", H)
