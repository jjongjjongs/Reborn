# Rookie Assault (spec: Rookie_Assault_Blender_Godot_3D_Spec) built on the SWAT skeleton so the game's
# retargeted animations, finger curl, hand IK and team tint keep working. Prepended at run time with the
# helper section of build_minis.py (mat / tube / chain_weights / ellipsoid / rbox / cyl / dome / ring).
# Proportions: built in skeleton units; the game shows it at ~0.70 scale = 1.50 m tall, head ~35 cm
# (about 1:4), shoulders ~46 cm, legs ~67 cm, hands +15 %, boots +20 %.
# Parts follow the spec's object list: Body_Base / Head / Hair / Eyes / Helmet (rails, front mount,
# patch) / Goggles (transparent lens) / Headset + Mic / Vest (front + back plate, straps, 3 mag pouches,
# utility pouch) / Belt + hip pouches / Backpack / Knee pads / Gloves with fingers / Boots.
OUT = "/home/user/Reborn/game/assets/soldier/Rookie.glb"
SKIN = mat("RSkin", (0.44, 0.26, 0.16, 1), 0.6)
HAIR = mat("RHair", (0.09, 0.035, 0.01, 1), 0.7)
GLOVE = mat("RGlove", (0.004, 0.004, 0.005, 1), 0.75)
WEB = mat("RWebbing", (0.005, 0.005, 0.004, 1), 0.85)
METAL = mat("RMetal", (0.006, 0.006, 0.007, 1), 0.35)
SOLE = mat("RSole", (0.16, 0.09, 0.04, 1), 0.9)
EYEW = mat("REyeWhite", (0.85, 0.84, 0.80, 1), 0.3)
IRIS = mat("RIris", (0.008, 0.005, 0.004, 1), 0.1)
SHINE = mat("RShine", (1, 1, 1, 1), 0.1)
BROW2 = mat("RBrow", (0.06, 0.022, 0.006, 1))
LIP = mat("RLip", (0.30, 0.12, 0.09, 1))
PATCHM = mat("RPatch", (0.15, 0.18, 0.08, 1), 0.9)
LENS2 = mat("RLens", (0.85, 0.45, 0.08, 0.45), 0.15)
try:
    LENS2.blend_method = "BLEND"
except Exception:
    pass
try:
    LENS2.node_tree.nodes["Principled BSDF"].inputs["Alpha"].default_value = 0.45
except Exception:
    pass
PANTS = UNIFORM

def ring(c, rx, ry, minor, material, bone, group="Mini_Body"):
    bpy.ops.mesh.primitive_torus_add(major_radius=1.0, minor_radius=minor / max(rx, ry), major_segments=36, minor_segments=10, location=c)
    o = bpy.context.active_object; o.scale = (rx, ry, max(rx, ry))
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return _finish(o, material, bone, group)

HC = 1.86
HR = (0.232, 0.226, 0.252)
FY = -0.035
def fsurf(x, z, out=0.0):
    t = 1.0 - (x / HR[0]) ** 2 - ((z - HC) / HR[2]) ** 2
    return FY - HR[1] * math.sqrt(max(0.0, t)) - out

# ---------------------------------------------------------------- head
ellipsoid((0, FY, HC), HR, SKIN, "Head", seg=32, rings=18)
ellipsoid((0, FY - 0.035, HC - 0.11), (0.175, 0.16, 0.13), SKIN, "Head", seg=24, rings=12)      # round U chin / cheeks
cyl((0, -0.04, 1.58), 0.078, 0.16, SKIN, "Neck")
for s in (1, -1):
    x = 0.084 * s; z = HC - 0.025
    ellipsoid((x, fsurf(x, z) + 0.004, z), (0.042, 0.012, 0.036), EYEW, "Head")                 # eye white
    ellipsoid((x, fsurf(x, z) - 0.004, z - 0.002), (0.025, 0.01, 0.031), IRIS, "Head")          # iris (big, ~25 %)
    ellipsoid((x + 0.009 * s, fsurf(x, z) - 0.011, z + 0.012), (0.008, 0.004, 0.008), SHINE, "Head")
    xb = 0.088 * s; zb = HC + 0.042
    b = rbox((xb, fsurf(xb, zb) - 0.002, zb), (0.064, 0.014, 0.014), BROW2, "Head", bevel=0.006)
    b.rotation_euler = (0, -0.22 * s, 0)                                                           # brows slope in: determined
ellipsoid((0, fsurf(0, HC - 0.075) - 0.012, HC - 0.075), (0.016, 0.012, 0.014), SKIN, "Head")   # small nose
rbox((0, fsurf(0, HC - 0.135, 0.0) - 0.028, HC - 0.135), (0.05, 0.008, 0.008), LIP, "Head", bevel=0.003)   # small mouth
# hair: short, shows under the helmet at the back and sides
hc = (0, FY + 0.012, HC + 0.01)
h = dome(hc, (0.240, 0.236, 0.258), HC - 0.07, HAIR, "Head", "Mini_Body")
bm = bmesh.new(); bm.from_mesh(h.data)
bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=(0, (FY - 0.09) - hc[1], 0), plane_no=(0, -1, 0), clear_outer=True)
bm.to_mesh(h.data); bm.free()

# ---------------------------------------------------------------- helmet (high cut) + goggles + headset
G = "Gear_Helmet"
dome((0, FY + 0.012, HC + 0.035), (0.262, 0.268, 0.235), HC + 0.035, KIT, "Head", G)
ring((0, FY + 0.012, HC + 0.04), 0.262, 0.268, 0.014, KIT, "Head", G)
for s in (1, -1):
    rbox((0.256 * s, FY + 0.01, HC + 0.085), (0.022, 0.22, 0.04), METAL, "Head", G, bevel=0.008)   # side rails
rbox((0, FY - 0.262, HC + 0.12), (0.085, 0.035, 0.07), METAL, "Head", G, bevel=0.01)              # front (NVG) mount
rbox((0, FY - 0.283, HC + 0.09), (0.04, 0.02, 0.05), METAL, "Head", G, bevel=0.006)
p = rbox((0, FY + 0.17, HC + 0.2), (0.11, 0.02, 0.075), PATCHM, "Head", G, bevel=0.008)            # velcro patch (back-top)
p.rotation_euler = (0.75, 0, 0)
ring((0, FY + 0.012, HC + 0.165), 0.253, 0.26, 0.011, WEB, "Head", G)                              # goggle strap
for s in (1, -1):
    x = 0.075 * s
    gf = rbox((x, FY - 0.258, HC + 0.175), (0.105, 0.045, 0.07), WEB, "Head", G, bevel=0.018)     # goggle frame
    gl = ellipsoid((x, FY - 0.283, HC + 0.175), (0.045, 0.012, 0.03), LENS2, "Head", G)           # transparent lens
for s in (1, -1):                                                                                   # headset ear cups
    cyl((0.238 * s, FY + 0.005, HC - 0.02), 0.07, 0.07, WEB, "Head", G, rot=(0, math.pi / 2, 0), verts=24)
    cyl((0.272 * s, FY + 0.005, HC - 0.02), 0.055, 0.02, METAL, "Head", G, rot=(0, math.pi / 2, 0), verts=24)
mic = tube([(0.24, FY - 0.04, HC - 0.06), (0.17, FY - 0.17, HC - 0.1), (0.06, FY - 0.235, HC - 0.125)], [0.009, 0.008, 0.008], WEB, G, segs=8)
vg = mic.vertex_groups.new(name="Head"); vg.add(list(range(len(mic.data.vertices))), 1.0, "REPLACE")
ellipsoid((0.055, FY - 0.24, HC - 0.126), (0.016, 0.016, 0.016), METAL, "Head", G)                 # mic end

# ---------------------------------------------------------------- torso, vest, belt, pack
SPINE = [(0, -0.05, 0.90), (0, -0.05, 0.99), (0, -0.045, 1.16), (0, -0.04, 1.37), (0, -0.04, 1.49)]
o = tube(SPINE, None, UNIFORM, ell=[(0.200, 0.140), (0.195, 0.14), (0.205, 0.15), (0.21, 0.15), (0.13, 0.1)], segs=24, cap0=0.3)
soft.append((o, [(0, -0.05, 0.894), (0, -0.045, 0.999), (0, -0.045, 1.161), (0, -0.04, 1.377), (0, -0.04, 1.511)], ["Hips", "Abdomen", "Torso", "Chest"]))
o = tube([(0, -0.05, 1.06), (0, -0.045, 1.2)], None, KIT, ell=[(0.222, 0.168), (0.228, 0.172)], segs=24, cap0=0.2, cap1=0.2)   # cummerbund
soft.append((o, [(0, -0.045, 0.999), (0, -0.045, 1.161), (0, -0.04, 1.377)], ["Abdomen", "Torso"]))
rbox((0, -0.215, 1.29), (0.34, 0.06, 0.36), KIT, "Chest", bevel=0.035)                       # front plate bag
rbox((0, 0.125, 1.29), (0.34, 0.055, 0.36), KIT, "Chest", bevel=0.035)                       # back plate bag
for s in (1, -1):
    rbox((0.115 * s, -0.045, 1.475), (0.075, 0.33, 0.035), KIT, "Chest", bevel=0.012)        # shoulder straps
for k, x in enumerate((-0.105, 0.0, 0.105)):                                                   # 3 mag pouches
    rbox((x, -0.268, 1.2), (0.09, 0.055, 0.13), KIT, "Chest", bevel=0.015)
    rbox((x, -0.268, 1.275), (0.07, 0.035, 0.03), METAL, "Chest", bevel=0.006)                 # mag tops
rbox((0.17, -0.2, 1.12), (0.07, 0.07, 0.1), KIT, "Torso", bevel=0.018)                        # utility pouch
rbox((-0.09, -0.252, 1.42), (0.11, 0.03, 0.06), PATCHM, "Chest", bevel=0.008)                  # name patch
ring((0, -0.05, 0.935), 0.212, 0.158, 0.025, WEB, "Hips")                                      # belt
rbox((0, -0.208, 0.935), (0.075, 0.02, 0.05), METAL, "Hips", bevel=0.01)                        # buckle
for s in (1, -1):
    rbox((0.215 * s, -0.04, 0.88), (0.06, 0.12, 0.12), KIT, "Hips", bevel=0.02)               # hip pouches
rbox((0, 0.235, 1.28), (0.28, 0.13, 0.32), KIT, "Chest", bevel=0.05)                           # assault pack
rbox((0, 0.245, 1.43), (0.29, 0.14, 0.05), KIT, "Chest", bevel=0.02)

# ---------------------------------------------------------------- arms, gloves with fingers, legs, boots
def bone_head(name):
    b = arm.data.bones[name]; return arm.matrix_world @ b.head_local
for s_ in (1, -1):
    L = "L" if s_ > 0 else "R"
    apts = [(0.0, -0.06, 1.42), (0.15 * s_, -0.06, 1.42), (0.334 * s_, -0.056, 1.432), (0.568 * s_, -0.086, 1.432)]
    o = tube([(0.13 * s_, -0.058, 1.43), (0.334 * s_, -0.056, 1.432), (0.55 * s_, -0.08, 1.432)], [0.078, 0.066, 0.058], UNIFORM, segs=16)
    soft.append((o, apts, ["Chest", "UpperArm." + L, "LowerArm." + L]))
    ellipsoid((0.16 * s_, -0.05, 1.445), (0.085, 0.105, 0.075), KIT, "Chest")                  # shoulder pad (vest)
    c = cyl((0.548 * s_, -0.082, 1.432), 0.064, 0.05, GLOVE, "Hand." + L, rot=(0, math.pi / 2, 0), verts=16)   # glove cuff
    rbox((0.645 * s_, -0.09, 1.432), (0.15, 0.12, 0.062), GLOVE, "Hand." + L, bevel=0.025)    # palm (+15 %)
    for f in ("Index", "Middle", "Ring", "Pinky"):
        p2, p3, p4 = bone_head(f + "2." + L), bone_head(f + "3." + L), bone_head(f + "4." + L)
        tip = p4 + (p4 - p3) * 0.45
        r = 0.019 if f == "Pinky" else 0.022
        o = tube([tuple(p2), tuple(p3), tuple(p4), tuple(tip)], [r, r * 0.97, r * 0.94, r * 0.9], GLOVE, segs=8, step=0.012)
        soft.append((o, [tuple(p2), tuple(p3), tuple(p4), tuple(tip)], [f + "2." + L, f + "3." + L, f + "4." + L]))
    t2, t3 = bone_head("Thumb2." + L), bone_head("Thumb3." + L)
    ttip = t3 + (t3 - t2) * 1.1
    o = tube([tuple(t2 + (t2 - t3) * 0.6), tuple(t2), tuple(t3), tuple(ttip)], [0.021, 0.021, 0.02, 0.018], GLOVE, segs=8, step=0.012)
    soft.append((o, [tuple(t2 + (t2 - t3) * 0.6), tuple(t2), tuple(t3), tuple(ttip)], ["Hand." + L, "Thumb2." + L, "Thumb3." + L]))
    lpts = [(0.121 * s_, -0.045, 1.05), (0.121 * s_, -0.045, 0.964), (0.121 * s_, -0.087, 0.533), (0.121 * s_, -0.062, 0.023)]
    o = tube([(0.112 * s_, -0.05, 0.96), (0.121 * s_, -0.087, 0.533), (0.121 * s_, -0.07, 0.2)], [0.098, 0.084, 0.072], PANTS, segs=18, cap0=0.5)
    soft.append((o, lpts, ["Hips", "UpperLeg." + L, "LowerLeg." + L]))
    rbox((0.121 * s_, -0.16, 0.54), (0.115, 0.05, 0.13), KIT, "LowerLeg." + L, bevel=0.03)       # knee pad
    rbox((0.121 * s_, -0.188, 0.54), (0.075, 0.02, 0.07), METAL, "LowerLeg." + L, bevel=0.01)
    rbox((0.121 * s_, -0.125, 0.09), (0.205, 0.40, 0.15), GLOVE, "Foot." + L, bevel=0.07)       # boot (+20 %)
    rbox((0.121 * s_, -0.125, 0.025), (0.215, 0.41, 0.05), SOLE, "Foot." + L, bevel=0.02)       # sole
    rbox((0.121 * s_, -0.21, 0.17), (0.08, 0.13, 0.02), WEB, "Foot." + L, bevel=0.008)          # laces
    ring((0.121 * s_, -0.07, 0.21), 0.085, 0.085, 0.03, GLOVE, "LowerLeg." + L)                  # boot collar

for o, pts, bones in soft:
    chain_weights(o, pts, bones)

made = []
for name, objs in parts.items():
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    o = bpy.context.active_object; o.name = name; o.data.name = name
    mw = o.matrix_world.copy()
    o.parent = arm
    o.matrix_world = mw
    md = o.modifiers.new("Armature", "ARMATURE"); md.object = arm
    made.append(o)
bpy.ops.object.select_all(action="DESELECT")
arm.select_set(True)
for o in made: o.select_set(True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_skins=True,
    export_animations=False, export_materials="EXPORT", export_cameras=False, export_lights=False)
print("rookie", [(o.name, len(o.data.polygons)) for o in made])
