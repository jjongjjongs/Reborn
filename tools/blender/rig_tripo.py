# Rig a Tripo-generated character (GLB from an image-to-3D tool) onto the game's SWAT skeleton.
# Steps: decode meshopt + dequantize with gltf-transform first (Blender 4.0 can't read meshopt):
#   npx @gltf-transform/cli dequantize in.glb a.glb
# then run this inside Blender (blender-mcp). It cuts one T-pose figure out of the sheet (FIG box below),
# decimates to ~20k faces, turns it to face -Y, scales to 2.1 m, measures the joints from the shape
# (arm line, shoulder edge, neck, crotch, legs), moves the SWAT bones onto them, weights every vertex
# to its nearest bone segment (head-only above the neck), shrinks textures to 1024 and exports.
import bpy, bmesh, math
from mathutils import Vector
OUT = globals().get("OUT", "/home/user/Reborn/game/assets/soldier/RookieT.glb")
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)
log = []
# ---- 1. the T-pose figure, already cut out + repacked onto its own 2048 maps (repack_tripo.py + tripo_transfer.py)
OWN = globals().get("OWN", "")          # a model built by build_mini_v3.py: .blend with one mesh, materials + vertex colours
if OWN:
    bpy.ops.wm.open_mainfile(filepath=OWN)
    mesh = [o for o in bpy.data.objects if o.type == "MESH"][0]
    me = mesh.data
    log = ["figure faces %d" % len(me.polygons)]
else:
    NAME = globals().get("NAME", "char")
    bpy.ops.wm.open_mainfile(filepath="/tmp/tripo_out/%s_cut.blend" % NAME)
    mesh = [o for o in bpy.data.objects if o.type == "MESH"][0]
    me = mesh.data
    me.uv_layers.remove(me.uv_layers["old"])
    mat = bpy.data.materials.new(NAME); mat.use_nodes = True; nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    def img(path, data):
        n = nt.nodes.new("ShaderNodeTexImage"); n.image = bpy.data.images.load(path)
        if data: n.image.colorspace_settings.name = "Non-Color"
        return n
    nt.links.new(img("/tmp/tripo_out/%s_color.jpg" % NAME, False).outputs["Color"], bsdf.inputs["Base Color"])
    sep = nt.nodes.new("ShaderNodeSeparateColor"); nt.links.new(img("/tmp/tripo_out/%s_orm.jpg" % NAME, True).outputs["Color"], sep.inputs[0])
    nt.links.new(sep.outputs[1], bsdf.inputs["Roughness"]); nt.links.new(sep.outputs[2], bsdf.inputs["Metallic"])
    nn = nt.nodes.new("ShaderNodeNormalMap"); nt.links.new(img("/tmp/tripo_out/%s_normal.png" % NAME, True).outputs["Color"], nn.inputs["Color"]); nt.links.new(nn.outputs[0], bsdf.inputs["Normal"])
    me.materials.clear(); me.materials.append(mat)
    for p in me.polygons: p.use_smooth = True
    log = ["figure faces %d" % len(me.polygons)]
# ---- 3. face -Y, game height, feet on the ground
for v in (mesh.data.vertices if not OWN else []):   # turn so the face (+X in the file) looks down -Y: (x, y) -> (y, -x)
    v.co = Vector((v.co.y, -v.co.x, v.co.z))
mesh.data.update()
vs = [v.co.copy() for v in mesh.data.vertices]
zmin = min(v.z for v in vs); zmax = max(v.z for v in vs)
H = 2.1; s = H / (zmax - zmin)
cx = sum(v.x for v in vs) / len(vs); cy = sum(v.y for v in vs) / len(vs)
for v in mesh.data.vertices:
    v.co = Vector(((v.co.x - cx) * s, (v.co.y - cy) * s, (v.co.z - zmin) * s))
mesh.data.update()
vs = [v.co.copy() for v in mesh.data.vertices]
xmax = max(abs(v.x) for v in vs)
# ---- 4. joints from the shape
def band(z0, z1): return [v for v in vs if z0 <= v.z < z1]
arm_v = [v for v in vs if abs(v.x) > xmax * 0.62]
arm_z = sorted(v.z for v in arm_v)[len(arm_v) // 2]
arm_y = sorted(v.y for v in arm_v)[len(arm_v) // 2]
# torso half width at the arm line: depth (y spread) per x slice drops where the arm starts
best = xmax * 0.3
sl = band(arm_z - 0.06, arm_z + 0.06)
depth0 = None
for i in range(4, 40):
    x0 = xmax * i / 40.0
    ys = [v.y for v in sl if x0 <= abs(v.x) < x0 + xmax / 40.0]
    if len(ys) < 5: continue
    d = max(ys) - min(ys)
    if depth0 is None: depth0 = d
    if d < depth0 * 0.55: best = x0; break
shoulder_x = best
# neck: narrowest slice between the arm line and 85 % height
neck_z = arm_z + 0.1; nw = 9.0
z = arm_z + 0.05
while z < H * 0.85:
    b = [v for v in band(z, z + 0.02) if abs(v.x) < shoulder_x * 1.2]
    if len(b) > 10:
        w = max(v.x for v in b) - min(v.x for v in b)
        if w < nw: nw = w; neck_z = z
    z += 0.02
# crotch: lowest height with geometry between the legs
crotch = H * 0.3
z = 0.05 if not OWN else H * 0.2
while z < arm_z:
    if any(abs(v.x) < 0.02 for v in band(z, z + 0.02)): crotch = z; break
    z += 0.01
leg = [v for v in band(crotch * 0.45, crotch * 0.55) if v.x > 0]
leg_x = sum(v.x for v in leg) / max(len(leg), 1)
leg_y = sum(v.y for v in leg) / max(len(leg), 1)
ankle_z = H * 0.075
knee_z = ankle_z + (crotch - ankle_z) * 0.48
hips_z = crotch + 0.06
log.append("H %.2f xmax %.2f arm_z %.2f shoulder_x %.2f neck_z %.2f crotch %.2f leg_x %.2f" % (H, xmax, arm_z, shoulder_x, neck_z, crotch, leg_x))
# ---- 5. skeleton: the game's SWAT rig, joints moved onto the figure
bpy.ops.import_scene.gltf(filepath="/home/user/Reborn/game/assets/soldier/Swat.glb")
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
for o in list(bpy.data.objects):
    if o.type == "MESH" and o != mesh: bpy.data.objects.remove(o, do_unlink=True)
mwi = arm.matrix_world.inverted()
wrist_x = shoulder_x + (xmax - shoulder_x) * 0.74
elbow_x = shoulder_x + (wrist_x - shoulder_x) * 0.48
J = {   # world positions (left side, mirrored for .R)
	"Hips": Vector((0, leg_y, hips_z)), "Abdomen": Vector((0, leg_y, hips_z + (neck_z - hips_z) * 0.2)),
	"Torso": Vector((0, leg_y, hips_z + (neck_z - hips_z) * 0.45)), "Chest": Vector((0, leg_y, hips_z + (neck_z - hips_z) * 0.75)),
	"Neck": Vector((0, leg_y, neck_z)), "Head": Vector((0, leg_y, neck_z + 0.07)),
	"Shoulder.L": Vector((shoulder_x * 0.45, arm_y, arm_z - 0.02)), "UpperArm.L": Vector((shoulder_x, arm_y, arm_z)),
	"LowerArm.L": Vector((elbow_x, arm_y, arm_z)), "Hand.L": Vector((wrist_x, arm_y, arm_z)),
	"UpperLeg.L": Vector((leg_x, leg_y, crotch + 0.02)), "LowerLeg.L": Vector((leg_x, leg_y - 0.02, knee_z)), "Foot.L": Vector((leg_x, leg_y, ankle_z)),
}
for k in list(J.keys()):
    if k.endswith(".L"):
        v = J[k]; J[k[:-2] + ".R"] = Vector((-v.x, v.y, v.z))
bpy.context.view_layer.objects.active = arm
for o in bpy.context.selected_objects: o.select_set(False)
arm.select_set(True)
bpy.ops.object.mode_set(mode="EDIT")
eb = arm.data.edit_bones
old = {b.name: (b.head.copy(), b.tail.copy()) for b in eb}
hand_old = {s: old["Hand." + s][0] for s in ("L", "R")}
for b in eb:
    h, t = old[b.name]
    if b.name in J:
        nh = mwi @ J[b.name]
    else:
        side = "L" if b.name.endswith(".L") else ("R" if b.name.endswith(".R") else "")
        if side and b.name.split(".")[0][:-1] in ("Index", "Middle", "Ring", "Pinky", "Thumb"):
            # finger: keep its layout relative to the hand, scaled to the glove
            hw_old = hand_old[side]; hw_new = mwi @ J["Hand." + side]
            nh = hw_new + (h - hw_old) * ((xmax - wrist_x) / 0.25)
        else:
            continue
    d = t - h
    b.head = nh; b.tail = nh + d
bpy.ops.object.mode_set(mode="OBJECT")
# ---- 6. weights: nearest bone segment, smooth over the two closest
bpy.ops.object.mode_set(mode="POSE"); bpy.ops.object.mode_set(mode="OBJECT")
segs = []
for b in arm.data.bones:
    if b.name == "Root": continue
    child = [c for c in b.children if not c.name.startswith(("Index", "Middle", "Ring", "Pinky", "Thumb"))]
    hd = arm.matrix_world @ b.head_local
    tl = arm.matrix_world @ (child[0].head_local if len(child) == 1 else b.tail_local)
    if b.name.startswith("Head"): tl = hd + Vector((0, 0, 0.5))
    if b.name.startswith("Foot"): tl = hd + Vector((0, -0.25, -0.05))
    if b.name.startswith("Hand"): tl = hd + (Vector((1, 0, 0)) if b.name.endswith(".L") else Vector((-1, 0, 0))) * (xmax - wrist_x)
    if b.name.startswith(("Index", "Middle", "Ring", "Pinky", "Thumb", "Shoulder")): continue
    segs.append((b.name, hd, tl))
groups = {n: mesh.vertex_groups.new(name=n) for n, _, _ in segs}
def seg_d(p, a, c):
    ab = c - a; t = max(0.0, min(1.0, (p - a).dot(ab) / max(ab.length_squared, 1e-9)))
    return (a + ab * t - p).length
head_segs = [x for x in segs if x[0] in ("Head", "Neck")]
body_segs = [x for x in segs if x[0] != "Head"]
for v in mesh.data.vertices:
    p = v.co
    # above the neck everything follows the head (the big helmet must not ride on the arms)
    cand = head_segs if p.z > neck_z + 0.02 else body_segs
    if p.z > neck_z + 0.09: cand = [x for x in segs if x[0] == "Head"] + [x for x in segs if x[0] == "Head"]
    ds = sorted(((seg_d(p, a, c), n) for n, a, c in cand))
    d0, n0 = ds[0]; d1, n1 = ds[1]
    w0 = 1.0 / max(d0, 1e-4) ** 4; w1 = 1.0 / max(d1, 1e-4) ** 4
    if d1 > d0 * 1.6: w1 = 0.0
    tot = w0 + w1
    groups[n0].add([v.index], w0 / tot, "ADD")
    if w1 > 0: groups[n1].add([v.index], w1 / tot, "ADD")
mesh.parent = arm
mesh.matrix_parent_inverse = arm.matrix_world.inverted()     # keep the mesh where it is (the rig carries a 100x scale)
md = mesh.modifiers.new("Armature", "ARMATURE"); md.object = arm
mesh.name = globals().get("MESH_NAME", "Rookie_Body")
# smaller textures for mobile
for o in bpy.context.selected_objects: o.select_set(False)
arm.select_set(True); mesh.select_set(True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_skins=True, export_animations=False,
    export_materials="EXPORT", export_image_format="AUTO", export_cameras=False, export_lights=False, export_colors=True)
log.append("exported")
open("/tmp/bwork/tripo_rig.txt", "w").write("\n".join(log))
print("\n".join(log))
