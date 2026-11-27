# First-person gloves (blender -b --python this.py): a gloved fist wrapped around a grip cylinder
# (radius 0.019) along local +Y at the origin. Right hand: back of the hand to +X, fingers wrap round the
# front (-Z) to the left side, thumb over the top; wrist / cuff back toward +Z and down.
# The left hand is the mirror. Marker "Wrist" (an empty) = where the sleeve meets the cuff.
import bpy, bmesh, math
from mathutils import Vector
bpy.ops.wm.read_factory_settings(use_empty=True)
def srgb(r, g, b):
    f = lambda c: c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return (f(r), f(g), f(b), 1)
def mat(name, col, rough):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]; b.inputs["Base Color"].default_value = col; b.inputs["Roughness"].default_value = rough
    return m
GLOVE = mat("FP_Glove", srgb(0.36, 0.32, 0.26), 0.85)   # coyote tan: reads against black guns
PAD = mat("FP_Pad", srgb(0.20, 0.19, 0.18), 0.6)
CUFF = mat("FP_Cuff", srgb(0.20, 0.19, 0.17), 0.85)
parts = []
def tube(pts, r, m, segs=10):
    pts = [Vector(p) for p in pts]
    bm = bmesh.new(); rings = []
    smp = []
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        for k in range(6):
            smp.append((a.lerp(b, k / 6.0), (b - a).normalized()))
    smp.append((pts[-1], (pts[-1] - pts[-2]).normalized()))
    for p, d in smp:
        up = Vector((0, 1, 0)) if abs(d.y) < 0.9 else Vector((1, 0, 0))
        x = d.cross(up).normalized(); y = d.cross(x).normalized()
        rings.append([bm.verts.new(p + (x * math.cos(t) + y * math.sin(t)) * r) for t in [2 * math.pi * k / segs for k in range(segs)]])
    for i in range(len(rings) - 1):
        for k in range(segs):
            bm.faces.new((rings[i][k], rings[i][(k + 1) % segs], rings[i + 1][(k + 1) % segs], rings[i + 1][k]))
    for ring, d in ((rings[0], -1), (rings[-1], 1)):          # rounded caps
        c = sum((v.co for v in ring), Vector()) / segs
        dd = (smp[-1][1] if d > 0 else -smp[0][1]) * r * 0.9
        tip = bm.verts.new(c + dd)
        for k in range(segs):
            f = (ring[k], ring[(k + 1) % segs], tip) if d > 0 else (ring[(k + 1) % segs], ring[k], tip)
            bm.faces.new(f)
    me = bpy.data.meshes.new("t"); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new("t", me); bpy.context.scene.collection.objects.link(o)
    me.materials.append(m); [setattr(p, "use_smooth", True) for p in me.polygons]
    parts.append(o); return o
def rbox(c, s, m, rot=(0, 0, 0), bevel=0.008):
    bpy.ops.mesh.primitive_cube_add(size=1, location=c, rotation=rot)
    o = bpy.context.active_object; o.scale = s
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    md = o.modifiers.new("b", "BEVEL"); md.width = bevel; md.segments = 3
    bpy.ops.object.modifier_apply(modifier="b")
    o.data.materials.append(m); [setattr(p, "use_smooth", True) for p in o.data.polygons]
    parts.append(o); return o
def ell(c, r, m):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=10, location=c)
    o = bpy.context.active_object; o.scale = r
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(m); [setattr(p, "use_smooth", True) for p in o.data.polygons]
    parts.append(o); return o
R = 0.019 + 0.013          # finger centre line radius around the grip
def arc(y, a0, a1, r, n=6):
    return [(R * math.cos(math.radians(a0 + (a1 - a0) * k / (n - 1))), y, R * math.sin(math.radians(a0 + (a1 - a0) * k / (n - 1)))) for k in range(n)]
def build():
    # palm: on the right / back side of the grip
    rbox((0.042, 0.002, 0.018), (0.032, 0.1, 0.07), GLOVE, bevel=0.014)
    ell((0.05, -0.01, 0.045), (0.03, 0.05, 0.035), GLOVE)                      # heel of the hand
    for i, y in enumerate((0.035, 0.012, -0.011, -0.033)):                       # fingers round the front
        r = 0.0125 if i < 3 else 0.011
        tube([(0.045, y, -0.012)] + arc(y, -25, -195 + i * 6, r), r, GLOVE)
    rbox((0.047, 0.002, -0.022), (0.022, 0.09, 0.03), PAD, bevel=0.008)            # knuckle pad
    tube([(0.035, 0.04, 0.04), (0.012, 0.058, 0.02), (-0.018, 0.05, -0.002), (-0.03, 0.04, -0.018)], 0.0135, GLOVE)   # thumb
    # cuff + wrist toward the forearm (back, down, a little right)
    w = Vector((0.06, -0.05, 0.085))
    d = Vector((0.22, -0.35, 1.0)).normalized()
    tube([w - d * 0.02, w + d * 0.035], 0.036, CUFF, segs=14)
    tube([Vector((0.05, -0.02, 0.05)), w], 0.031, GLOVE, segs=12)
    return w + d * 0.035
def export(name, mirror):
    global parts
    parts = []
    wrist = build()
    for o in parts: o.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    o = bpy.context.active_object; o.name = name
    if mirror:
        for v in o.data.vertices: v.co.x = -v.co.x
        o.data.flip_normals()
        wrist.x = -wrist.x
    e = bpy.data.objects.new("Wrist", None); bpy.context.scene.collection.objects.link(e); e.location = wrist; e.parent = o
    bpy.ops.object.select_all(action="DESELECT"); o.select_set(True); e.select_set(True)
    bpy.ops.export_scene.gltf(filepath="/home/user/Reborn/game/assets/fp/%s.glb" % name, export_format="GLB", use_selection=True, export_materials="EXPORT")
    bpy.data.objects.remove(e, do_unlink=True); bpy.data.objects.remove(o, do_unlink=True)
import os
os.makedirs("/home/user/Reborn/game/assets/fp", exist_ok=True)
export("glove_r", False)
export("glove_l", True)
print("GLOVES ok")
