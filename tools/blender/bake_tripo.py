# Bake one object out of a Tripo sheet (all items share one 4096 atlas, so each item only gets a few
# hundred pixels of it): cut the item from the full-detail mesh (BOX), make a lighter copy (FACES),
# give it its own UVs and bake colour / normal / roughness / metallic from the full mesh into SIZE x SIZE
# maps, then export the light copy with them. Prepend: NAME, BOX = (min, max), FACES, SIZE, OUT, METAL.
import bpy, bmesh, math
from mathutils import Vector
SRC = globals().get("SRC", "/tmp/tripo_out/a.glb")
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)
for im in list(bpy.data.images):
    bpy.data.images.remove(im)
log = []
bpy.ops.import_scene.gltf(filepath=SRC)
hi = [o for o in bpy.data.objects if o.type == "MESH"][0]
for o in bpy.context.selected_objects: o.select_set(False)
bpy.context.view_layer.objects.active = hi; hi.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
mn = Vector(BOX[0]); mx = Vector(BOX[1])
bm = bmesh.new(); bm.from_mesh(hi.data)
bmesh.ops.delete(bm, geom=[v for v in bm.verts if not (mn.x <= v.co.x <= mx.x and mn.y <= v.co.y <= mx.y and mn.z <= v.co.z <= mx.z)], context="VERTS")
bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=0.0002)
bm.to_mesh(hi.data); bm.free()
log.append("%s high faces %d" % (NAME, len(hi.data.polygons)))
# light copy with fresh UVs
lo = hi.copy(); lo.data = hi.data.copy(); bpy.context.scene.collection.objects.link(lo)
for o in bpy.context.selected_objects: o.select_set(False)
bpy.context.view_layer.objects.active = lo; lo.select_set(True)
dec = lo.modifiers.new("dec", "DECIMATE"); dec.ratio = min(1.0, FACES / max(len(lo.data.polygons), 1))
bpy.ops.object.modifier_apply(modifier="dec")
while lo.data.uv_layers: lo.data.uv_layers.remove(lo.data.uv_layers[0])
lo.data.uv_layers.new(name="UVMap")
bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.003)
bpy.ops.object.mode_set(mode="OBJECT")
log.append("low faces %d" % len(lo.data.polygons))
# bake targets
size = max(lo.dimensions)
imgs = {}
mat = bpy.data.materials.new(NAME + "_mat"); mat.use_nodes = True
nt = mat.node_tree
for k in ("color", "normal", "rough", "metal"):
    im = bpy.data.images.new("%s_%s" % (NAME, k), SIZE, SIZE, alpha=False)
    if k != "color": im.colorspace_settings.name = "Non-Color"
    imgs[k] = im
lo.data.materials.clear(); lo.data.materials.append(mat)
def target(k):
    for n in nt.nodes: n.select = False
    n = nt.nodes.get("bake_" + k) or nt.nodes.new("ShaderNodeTexImage")
    n.name = "bake_" + k; n.image = imgs[k]; n.select = True; nt.nodes.active = n
sc = bpy.context.scene
sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 4
sc.render.bake.use_selected_to_active = True
sc.render.bake.cage_extrusion = size * 0.01; sc.render.bake.max_ray_distance = size * 0.03
sc.render.bake.margin = 6
for o in bpy.context.selected_objects: o.select_set(False)
hi.select_set(True); lo.select_set(True); bpy.context.view_layer.objects.active = lo
target("color"); sc.render.bake.use_pass_direct = False; sc.render.bake.use_pass_indirect = False; sc.render.bake.use_pass_color = True
bpy.ops.object.bake(type="DIFFUSE")
target("normal"); bpy.ops.object.bake(type="NORMAL")
target("rough"); bpy.ops.object.bake(type="ROUGHNESS")
# metallic: route the source's metallic input into emission and bake that
for m in hi.data.materials:
    t = m.node_tree; b = next((n for n in t.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if b is None: continue
    lk = b.inputs["Metallic"].links
    em = t.nodes.new("ShaderNodeEmission"); out = next(n for n in t.nodes if n.type == "OUTPUT_MATERIAL")
    if lk: t.links.new(lk[0].from_socket, em.inputs["Color"])
    else: em.inputs["Color"].default_value = (b.inputs["Metallic"].default_value,) * 3 + (1,)
    t.links.new(em.outputs[0], out.inputs["Surface"])
target("metal"); bpy.ops.object.bake(type="EMIT")
# final material on the light copy
for n in list(nt.nodes):
    if n.name.startswith("bake_"): nt.nodes.remove(n)
b = nt.nodes["Principled BSDF"]
def tex(k, x, y):
    n = nt.nodes.new("ShaderNodeTexImage"); n.image = imgs[k]; n.location = (x, y); return n
nt.links.new(tex("color", -600, 300).outputs["Color"], b.inputs["Base Color"])
nn = nt.nodes.new("ShaderNodeNormalMap"); nt.links.new(tex("normal", -600, -300).outputs["Color"], nn.inputs["Color"]); nt.links.new(nn.outputs[0], b.inputs["Normal"])
r = tex("rough", -600, 0); m = tex("metal", -600, -150)
sep = nt.nodes.new("ShaderNodeSeparateColor"); nt.links.new(r.outputs["Color"], sep.inputs[0]); nt.links.new(sep.outputs[0], b.inputs["Roughness"])
sep2 = nt.nodes.new("ShaderNodeSeparateColor"); nt.links.new(m.outputs["Color"], sep2.inputs[0])
mm = nt.nodes.new("ShaderNodeMath"); mm.operation = "MULTIPLY"; mm.inputs[1].default_value = METAL
nt.links.new(sep2.outputs[0], mm.inputs[0]); nt.links.new(mm.outputs[0], b.inputs["Metallic"])
for k, im in imgs.items():
    im.filepath_raw = "/tmp/tripo_out/%s_%s.png" % (NAME, k); im.file_format = "PNG"; im.save()
bpy.data.objects.remove(hi, do_unlink=True)
lo.name = NAME
bpy.ops.wm.save_as_mainfile(filepath="/tmp/tripo_out/%s_baked.blend" % NAME)
for o in bpy.context.selected_objects: o.select_set(False)
lo.select_set(True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_materials="EXPORT",
    export_image_format="JPEG", export_jpeg_quality=92, export_cameras=False, export_lights=False)
log.append("exported %s" % OUT)
open("/tmp/bwork/bake_%s.txt" % NAME, "w").write("\n".join(log))
print("\n".join(log))
