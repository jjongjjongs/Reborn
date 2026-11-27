# Repack one item of a Tripo sheet onto its own texture (run with: blender -b --python this.py -- NAME xmin ymin zmin xmax ymax zmax)
# The sheet's items all share one 4096 atlas in scattered islands. This cuts the item out of the simplified sheet
# (seams intact), copies its UVs, evens the island scale and packs them WITHOUT rotation (so tangent-space normals
# stay valid), then writes per-triangle old/new UVs for tools/tripo_transfer.py to resample the atlas, and saves
# the cut mesh (.blend) for the next step.
import bpy, bmesh, sys
import numpy as np
from mathutils import Vector
a = sys.argv[sys.argv.index("--") + 1:]
NAME = a[0]; mn = Vector(map(float, a[1:4])); mx = Vector(map(float, a[4:7]))
SRC = "/tmp/tripo_out/s.glb"
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
o = [x for x in bpy.data.objects if x.type == "MESH"][0]
bpy.context.view_layer.objects.active = o; o.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bm = bmesh.new(); bm.from_mesh(o.data)
bmesh.ops.delete(bm, geom=[f for f in bm.faces if not all(mn.x <= v.co.x <= mx.x and mn.y <= v.co.y <= mx.y and mn.z <= v.co.z <= mx.z for v in f.verts)], context="FACES")
bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
bm.to_mesh(o.data); bm.free()
me = o.data
old = me.uv_layers[0]; old.name = "old"
new = me.uv_layers.new(name="new"); me.uv_layers.active = new
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.uv.select_all(action="SELECT")
bpy.ops.uv.average_islands_scale()
bpy.ops.uv.pack_islands(rotate=False, margin=0.003)
bpy.ops.object.mode_set(mode="OBJECT")
me.calc_loop_triangles()
n = len(me.loop_triangles)
loops = np.zeros(n * 3, dtype=np.int64)
me.loop_triangles.foreach_get("loops", loops)
ou = np.zeros(len(me.loops) * 2); nu = np.zeros(len(me.loops) * 2)
me.uv_layers["old"].data.foreach_get("uv", ou); me.uv_layers["new"].data.foreach_get("uv", nu)
ou = ou.reshape(-1, 2)[loops].reshape(n, 3, 2); nu = nu.reshape(-1, 2)[loops].reshape(n, 3, 2)
np.savez("/tmp/tripo_out/%s_uv.npz" % NAME, old=ou, new=nu)
bpy.ops.wm.save_as_mainfile(filepath="/tmp/tripo_out/%s_cut.blend" % NAME)
print("REPACK", NAME, "tris", n)
