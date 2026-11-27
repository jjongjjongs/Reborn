# blender -b --python this.py -- NAME OUT.glb : textured, oriented gun from repack_tripo.py + tripo_transfer.py
# (muzzle +X, magazine down, centred; metallic scaled down so the generated metal is not mirror-like)
import bpy, sys
from mathutils import Vector
a = sys.argv[sys.argv.index("--") + 1:]
NAME, OUT = a[0], a[1]
bpy.ops.wm.open_mainfile(filepath="/tmp/tripo_out/%s_cut.blend" % NAME)
o = [x for x in bpy.data.objects if x.type == "MESH"][0]
me = o.data
me.uv_layers.remove(me.uv_layers["old"])
mat = bpy.data.materials.new(NAME); mat.use_nodes = True; nt = mat.node_tree
b = nt.nodes["Principled BSDF"]
def img(path, data):
    n = nt.nodes.new("ShaderNodeTexImage"); n.image = bpy.data.images.load(path)
    if data: n.image.colorspace_settings.name = "Non-Color"
    return n
c = img("/tmp/tripo_out/%s_color.jpg" % NAME, False); nt.links.new(c.outputs["Color"], b.inputs["Base Color"])
orm = img("/tmp/tripo_out/%s_orm.jpg" % NAME, True)
sep = nt.nodes.new("ShaderNodeSeparateColor"); nt.links.new(orm.outputs["Color"], sep.inputs[0])
nt.links.new(sep.outputs[1], b.inputs["Roughness"])
mm = nt.nodes.new("ShaderNodeMath"); mm.operation = "MULTIPLY"; mm.inputs[1].default_value = 1.0     # (metallic already scaled in the ORM map)
nt.links.new(sep.outputs[2], mm.inputs[0]); nt.links.new(mm.outputs[0], b.inputs["Metallic"])
nm = img("/tmp/tripo_out/%s_normal.png" % NAME, True)
nn = nt.nodes.new("ShaderNodeNormalMap"); nt.links.new(nm.outputs["Color"], nn.inputs["Color"]); nt.links.new(nn.outputs[0], b.inputs["Normal"])
me.materials.clear(); me.materials.append(mat)
# orientation (sheet: length along Y)
for v in me.vertices: v.co = Vector((v.co.y, -v.co.x, v.co.z))
vs = [v.co.copy() for v in me.vertices]
x0 = min(v.x for v in vs); x1 = max(v.x for v in vs); L = x1 - x0
def sl(a, b): return [v for v in vs if x0 + L * a <= v.x <= x0 + L * b]
def zext(s): return (max(v.z for v in s) - min(v.z for v in s)) if s else 0.0
if zext(sl(0.0, 0.08)) < zext(sl(0.92, 1.0)):
    for v in me.vertices: v.co.x = -v.co.x; v.co.y = -v.co.y
vs = [v.co.copy() for v in me.vertices]
x0 = min(v.x for v in vs); x1 = max(v.x for v in vs); L = x1 - x0
bar = sl(0.9, 1.0); zb = sum(v.z for v in bar) / max(len(bar), 1); mid = sl(0.3, 0.55)
if max(v.z for v in mid) - zb > zb - min(v.z for v in mid):
    for v in me.vertices: v.co.z = -v.co.z; v.co.y = -v.co.y
vs = [v.co.copy() for v in me.vertices]
cc = Vector([(min(v[i] for v in vs) + max(v[i] for v in vs)) / 2 for i in range(3)])
for v in me.vertices: v.co -= cc
me.update()
for p in me.polygons: p.use_smooth = True
o.name = NAME
bpy.ops.object.select_all(action="DESELECT"); o.select_set(True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_materials="EXPORT",
    export_image_format="AUTO", export_cameras=False, export_lights=False)
print("GUN", NAME, len(me.polygons), "->", OUT)
