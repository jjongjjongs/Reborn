# Rookie Assault, v2: follows the concept sheet (chibi ~1:3 head incl. helmet, stern half-lidded eyes,
# thick brows, small frown, cheek bandage, dark hair; bulky olive helmet with pads / rails / NVG shroud,
# big smoked wraparound goggles, olive headset; olive shirt with rolled sleeves, khaki plate carrier
# + mag pouches, dark-grey straps, gloves and knee pads, khaki hip pouches, dark-brown chunky boots).
# Palette: olive drab / khaki / dark grey / team colour. Only materials named "Team..." are recoloured
# in game (patches and tabs), everything else keeps the concept colours.
# Built on the SWAT skeleton (game animations, finger curl, hand IK). Prepended at run time with the
# helper section of build_minis.py (mat / tube / chain_weights / ellipsoid / rbox / cyl / dome / smile).
OUT = "/home/user/Reborn/game/assets/soldier/Rookie.glb"
def srgb(r, g, b, a=1.0):
    f = lambda c: c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return (f(r), f(g), f(b), a)
OLIVE = mat("R_Olive", srgb(0.33, 0.35, 0.21), 0.85)
OLIVE_H = mat("R_HelmetOlive", srgb(0.37, 0.39, 0.25), 0.7)
OLIVE_D = mat("R_OliveDark", srgb(0.26, 0.28, 0.17), 0.85)
OLIVE_L = mat("R_OliveLight", srgb(0.48, 0.47, 0.34), 0.85)
KHAKI = mat("R_Khaki", srgb(0.56, 0.47, 0.33), 0.85)
KHAKI_D = mat("R_KhakiDark", srgb(0.47, 0.39, 0.27), 0.85)
DGREY = mat("R_DarkGrey", srgb(0.24, 0.24, 0.25), 0.7)
BLACK = mat("R_Black", srgb(0.10, 0.10, 0.11), 0.6)
BROWN = mat("R_BootBrown", srgb(0.30, 0.22, 0.17), 0.85)
SOLE = mat("R_Sole", srgb(0.16, 0.13, 0.11), 0.9)
SKIN = mat("R_Skin", srgb(0.93, 0.74, 0.60), 0.6)
SKIN_SH = mat("R_SkinShade", srgb(0.92, 0.70, 0.56), 0.6)
HAIR = mat("R_Hair", srgb(0.16, 0.11, 0.09), 0.7)
EYEW = mat("R_EyeWhite", srgb(0.97, 0.96, 0.94), 0.3)
IRIS = mat("R_Iris", srgb(0.36, 0.22, 0.14), 0.2)
PUPIL = mat("R_Pupil", srgb(0.08, 0.05, 0.04), 0.2)
SHINE = mat("R_Shine", (1, 1, 1, 1), 0.1)
LID = mat("R_Lid", srgb(0.14, 0.09, 0.07), 0.6)
LIP = mat("R_Lip", srgb(0.55, 0.32, 0.28), 0.6)
BAND = mat("R_Bandage", srgb(0.93, 0.80, 0.68), 0.8)
TEAM = mat("Team", srgb(0.22, 0.36, 0.72), 0.6)           # recoloured to the team colour in game
LENS = mat("R_Lens", srgb(0.36, 0.33, 0.40, 0.6), 0.05)
try:
    LENS.blend_method = "BLEND"
    LENS.node_tree.nodes["Principled BSDF"].inputs["Alpha"].default_value = 0.65
except Exception:
    pass

def ring(c, rx, ry, minor, material, bone, group="Mini_Body", zs=None):
    bpy.ops.mesh.primitive_torus_add(major_radius=1.0, minor_radius=minor / max(rx, ry), major_segments=40, minor_segments=10, location=c)
    o = bpy.context.active_object; o.scale = (rx, ry, zs if zs else max(rx, ry))
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return _finish(o, material, bone, group)
def cut(o, co, no):
    """remove the part of a mesh on the `no` side of the plane through world point co."""
    bm = bmesh.new(); bm.from_mesh(o.data)
    loc = o.location
    bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=(co[0] - loc.x, co[1] - loc.y, co[2] - loc.z), plane_no=no, clear_outer=True)
    bm.to_mesh(o.data); bm.free()
    return o

HC = 1.84
HR = (0.268, 0.262, 0.285)
FY = -0.03
def fs(x, z, out=0.0):
    t = 1.0 - (x / HR[0]) ** 2 - ((z - HC) / HR[2]) ** 2
    return FY - HR[1] * math.sqrt(max(0.0, t)) - out

# ================================================================ head
hd = ellipsoid((0, FY, HC), HR, SKIN, "Head", seg=36, rings=20)
for v in hd.data.vertices:                                     # chubby cheeks, short round U jaw
    w = hd.matrix_world @ v.co
    t = max(0.0, min(1.0, (HC - w.z) / HR[2]))
    k = 1.0 + 0.10 * math.sin(t * math.pi * 0.9)
    v.co.x *= k; v.co.y = v.co.y * k - 0.02 * t * (1.0 if v.co.y < 0 else 0.0)
cyl((0, -0.04, 1.56), 0.085, 0.14, SKIN, "Neck")
for s in (1, -1):
    x = 0.098 * s; z = HC - 0.045
    ellipsoid((x, fs(x, z) + 0.006, z), (0.056, 0.012, 0.052), EYEW, "Head")
    ellipsoid((x - 0.006 * s, fs(x, z) - 0.002, z - 0.004), (0.043, 0.012, 0.047), IRIS, "Head")
    ellipsoid((x - 0.006 * s, fs(x, z) - 0.009, z - 0.004), (0.024, 0.008, 0.028), PUPIL, "Head")
    ellipsoid((x + 0.008 * s, fs(x, z) - 0.014, z + 0.014), (0.011, 0.004, 0.011), SHINE, "Head")
    lid = rbox((x, fs(x, z + 0.04) - 0.011, z + 0.035), (0.124, 0.018, 0.03), LID, "Head", bevel=0.01)   # heavy upper lid
    lid.rotation_euler = (0, 0.12 * s, 0)
    br = rbox((x, fs(x, z + 0.1) - 0.006, z + 0.1), (0.1, 0.02, 0.032), HAIR, "Head", bevel=0.012)        # thick brow, angled in
    br.rotation_euler = (0, -0.26 * s, 0)
ellipsoid((0, fs(0, HC - 0.11) - 0.03, HC - 0.11), (0.014, 0.01, 0.012), SKIN_SH, "Head")                 # tiny nose
fr = smile((0, fs(0, HC - 0.175, 0.0) - 0.045, HC - 0.168), 0.024, LIP, "Head")                          # small frown
fr.rotation_euler = (0, math.pi, 0)
bd = rbox((-0.15, fs(-0.15, HC - 0.11) - 0.012, HC - 0.11), (0.075, 0.012, 0.03), BAND, "Head", bevel=0.008)   # cheek bandage
bd.rotation_euler = (0.25, 0.55, 0.5)
h = ellipsoid((0, FY + 0.015, HC + 0.015), (0.278, 0.272, 0.292), HAIR, "Head", seg=28, rings=14)     # hair: sides + back
cut(h, (0, FY - 0.13, 0), (0, -1, 0)); cut(h, (0, 0, HC - 0.11), (0, 0, -1))
for s in (1, -1):                                                                                     # side locks in front of the ears
    sl = rbox((0.235 * s, FY - 0.13, HC - 0.03), (0.05, 0.06, 0.14), HAIR, "Head", bevel=0.02)
    sl.rotation_euler = (0, 0.25 * s, 0)

# ================================================================ helmet, goggles, headset
G = "Gear_Helmet"
hm = ellipsoid((0, FY + 0.015, HC + 0.06), (0.322, 0.33, 0.30), OLIVE_H, "Head", G, seg=32, rings=16)
cut(hm, (0, 0, HC + 0.03), (0, 0, -1))
ring((0, FY + 0.015, HC + 0.035), 0.322, 0.33, 0.02, OLIVE_D, "Head", G)
for a, z in [(0.0, 0.29), (0.75, 0.24), (-0.75, 0.24), (1.35, 0.17), (-1.35, 0.17), (2.4, 0.2), (-2.4, 0.2)]:   # blocky pads
    d = Vector((math.sin(a), -math.cos(a), 0))
    r = 0.3 if abs(a) < 1.0 else 0.31
    p = rbox((d.x * r * 0.92, FY + d.y * r * 0.92, HC + z), (0.12, 0.05, 0.075), OLIVE_D, "Head", G, bevel=0.02)
    p.rotation_euler = (0.35 if abs(a) < 1.0 else 0.0, 0, -a)
for s in (1, -1):                                                                                     # side rails + pads
    rbox((0.322 * s, FY + 0.03, HC + 0.09), (0.035, 0.24, 0.05), DGREY, "Head", G, bevel=0.01)
    rbox((0.33 * s, FY + 0.12, HC + 0.13), (0.03, 0.08, 0.07), DGREY, "Head", G, bevel=0.012)
rbox((0, FY - 0.305, HC + 0.2), (0.13, 0.05, 0.1), DGREY, "Head", G, bevel=0.02)                    # NVG shroud
rbox((0, FY - 0.33, HC + 0.2), (0.07, 0.012, 0.055), BLACK, "Head", G, bevel=0.006)
vp = rbox((-0.13, FY - 0.24, HC + 0.25), (0.11, 0.03, 0.07), BLACK, "Head", G, bevel=0.012)         # velcro patch
vp.rotation_euler = (0.6, 0, 0.35)
tp = rbox((0.255, FY - 0.17, HC + 0.17), (0.03, 0.13, 0.06), TEAM, "Head", G, bevel=0.01)           # team patch
tp.rotation_euler = (0, 0, 0.55)
# wraparound goggles on the brim: front half of a flattened torus (frame) + smoked lens in front
ln = ring((0, FY + 0.015, HC + 0.085), 0.326, 0.334, 0.042, LENS, "Head", G, zs=0.34)
cut(ln, (0, FY - 0.1, 0), (0, 1, 0))
for dz in (0.13, 0.04):
    rim = ring((0, FY + 0.015, HC + dz), 0.338, 0.346, 0.013, BLACK, "Head", G, zs=0.35)
    cut(rim, (0, FY - 0.1, 0), (0, 1, 0))
for s in (1, -1):
    rbox((0.305 * s, FY - 0.13, HC + 0.085), (0.03, 0.06, 0.11), BLACK, "Head", G, bevel=0.01)   # frame ends
for s in (1, -1):                                                                                     # headset
    cyl((0.3 * s, FY + 0.01, HC - 0.05), 0.088, 0.085, OLIVE_D, "Head", G, rot=(0, math.pi / 2, 0), verts=24)
    cyl((0.345 * s, FY + 0.01, HC - 0.05), 0.07, 0.02, DGREY, "Head", G, rot=(0, math.pi / 2, 0), verts=24)
    rbox((0.355 * s, FY + 0.01, HC - 0.05), (0.012, 0.06, 0.04), TEAM, "Head", G, bevel=0.005)
mic = tube([(0.29, FY - 0.06, HC - 0.1), (0.2, FY - 0.2, HC - 0.15), (0.075, FY - 0.27, HC - 0.165)], [0.011, 0.01, 0.01], BLACK, G, segs=8)
vg = mic.vertex_groups.new(name="Head"); vg.add(list(range(len(mic.data.vertices))), 1.0, "REPLACE")
ellipsoid((0.065, FY - 0.272, HC - 0.168), (0.02, 0.02, 0.02), BLACK, "Head", G)

# ================================================================ torso: shirt, plate carrier, belt, pack
SPINE = [(0, -0.05, 0.90), (0, -0.05, 0.99), (0, -0.045, 1.16), (0, -0.04, 1.37), (0, -0.04, 1.49)]
o = tube(SPINE, None, OLIVE, ell=[(0.215, 0.15), (0.21, 0.15), (0.225, 0.165), (0.225, 0.16), (0.14, 0.11)], segs=24, cap0=0.3)
soft.append((o, [(0, -0.05, 0.894), (0, -0.045, 0.999), (0, -0.045, 1.161), (0, -0.04, 1.377), (0, -0.04, 1.511)], ["Hips", "Abdomen", "Torso", "Chest"]))
o = tube([(0, -0.05, 1.06), (0, -0.045, 1.22)], None, KHAKI, ell=[(0.245, 0.183), (0.25, 0.188)], segs=24, cap0=0.2, cap1=0.2)   # cummerbund
soft.append((o, [(0, -0.045, 0.999), (0, -0.045, 1.161), (0, -0.04, 1.377)], ["Abdomen", "Torso"]))
rbox((0, -0.232, 1.3), (0.39, 0.075, 0.38), KHAKI, "Chest", bevel=0.045)                       # front plate
rbox((0, 0.14, 1.3), (0.39, 0.07, 0.38), KHAKI, "Chest", bevel=0.045)                          # back plate
for s in (1, -1):
    rbox((0.13 * s, -0.045, 1.49), (0.085, 0.36, 0.04), DGREY, "Chest", bevel=0.015)           # shoulder straps
    rbox((0.155 * s, -0.272, 1.46), (0.04, 0.012, 0.05), TEAM, "Chest", bevel=0.006)          # team tabs
rbox((0, -0.282, 1.39), (0.2, 0.04, 0.1), DGREY, "Chest", bevel=0.02)                          # admin pouch
rbox((0, -0.304, 1.39), (0.06, 0.006, 0.04), KHAKI_D, "Chest", bevel=0.004)                   # logo plate
for x in (-0.12, 0.0, 0.12):                                                                      # 3 mag pouches
    rbox((x, -0.29, 1.21), (0.105, 0.06, 0.15), KHAKI_D, "Chest", bevel=0.02)
    rbox((x, -0.29, 1.27), (0.1, 0.064, 0.04), KHAKI, "Chest", bevel=0.012)                   # flap
rbox((0.2, -0.21, 1.12), (0.08, 0.08, 0.11), KHAKI_D, "Torso", bevel=0.02)                    # utility pouch
ring((0, -0.05, 0.935), 0.228, 0.168, 0.03, DGREY, "Hips")                                       # belt
rbox((0, -0.222, 0.935), (0.085, 0.025, 0.055), BLACK, "Hips", bevel=0.01)
for s in (1, -1):
    rbox((0.225 * s, -0.08, 0.875), (0.075, 0.15, 0.15), KHAKI, "Hips", bevel=0.025)          # hip pouches
    rbox((0.265 * s, -0.08, 0.92), (0.012, 0.04, 0.04), TEAM, "Hips", bevel=0.005)
rbox((0, 0.25, 1.28), (0.3, 0.13, 0.34), KHAKI_D, "Chest", bevel=0.055)                       # assault pack
rbox((0, 0.32, 1.22), (0.2, 0.04, 0.14), KHAKI, "Chest", bevel=0.02)

# ================================================================ arms (rolled sleeves), gloves, legs, boots
def bone_head(name):
    b = arm.data.bones[name]; return arm.matrix_world @ b.head_local
for s_ in (1, -1):
    L = "L" if s_ > 0 else "R"
    apts = [(0.0, -0.06, 1.42), (0.15 * s_, -0.06, 1.42), (0.334 * s_, -0.056, 1.432), (0.568 * s_, -0.086, 1.432)]
    o = tube([(0.13 * s_, -0.058, 1.43), (0.31 * s_, -0.057, 1.432)], [0.1, 0.092], OLIVE, segs=18, cap1=0.3)   # sleeve
    soft.append((o, apts, ["Chest", "UpperArm." + L, "LowerArm." + L]))
    o = tube([(0.3 * s_, -0.057, 1.432), (0.36 * s_, -0.058, 1.432)], [0.102, 0.1], OLIVE_L, segs=18, cap0=0.3, cap1=0.3)   # rolled cuff
    soft.append((o, apts, ["Chest", "UpperArm." + L, "LowerArm." + L]))
    o = tube([(0.33 * s_, -0.057, 1.432), (0.54 * s_, -0.08, 1.432)], [0.078, 0.07], SKIN, segs=16)                   # forearm
    soft.append((o, apts, ["Chest", "UpperArm." + L, "LowerArm." + L]))
    ellipsoid((0.17 * s_, -0.05, 1.46), (0.1, 0.12, 0.085), OLIVE, "Chest")                                         # shoulder
    tp = rbox((0.235 * s_, -0.06, 1.49), (0.07, 0.11, 0.02), TEAM, "UpperArm." + L, bevel=0.008)                    # arm patch
    tp.rotation_euler = (0, 0.35 * s_, 0)
    cyl((0.545 * s_, -0.082, 1.432), 0.078, 0.07, DGREY, "Hand." + L, rot=(0, math.pi / 2, 0), verts=18)           # glove cuff
    rbox((0.65 * s_, -0.09, 1.432), (0.17, 0.14, 0.078), DGREY, "Hand." + L, bevel=0.03)                          # palm
    rbox((0.67 * s_, -0.09, 1.475), (0.1, 0.11, 0.025), BLACK, "Hand." + L, bevel=0.01)                           # knuckle pad
    for f in ("Index", "Middle", "Ring", "Pinky"):
        p2, p3, p4 = bone_head(f + "2." + L), bone_head(f + "3." + L), bone_head(f + "4." + L)
        tip = p4 + (p4 - p3) * 0.45
        r = 0.022 if f == "Pinky" else 0.026
        o = tube([tuple(p2), tuple(p3), tuple(p4), tuple(tip)], [r, r, r * 0.96, r * 0.9], DGREY, segs=8, step=0.012)
        soft.append((o, [tuple(p2), tuple(p3), tuple(p4), tuple(tip)], [f + "2." + L, f + "3." + L, f + "4." + L]))
    t2, t3 = bone_head("Thumb2." + L), bone_head("Thumb3." + L)
    ttip = t3 + (t3 - t2) * 1.0
    o = tube([tuple(t2 + (t2 - t3) * 0.6), tuple(t2), tuple(t3), tuple(ttip)], [0.027, 0.027, 0.026, 0.023], DGREY, segs=8, step=0.012)
    soft.append((o, [tuple(t2 + (t2 - t3) * 0.6), tuple(t2), tuple(t3), tuple(ttip)], ["Hand." + L, "Thumb2." + L, "Thumb3." + L]))
    lpts = [(0.121 * s_, -0.045, 1.05), (0.121 * s_, -0.045, 0.964), (0.121 * s_, -0.087, 0.533), (0.121 * s_, -0.062, 0.023)]
    o = tube([(0.112 * s_, -0.05, 0.96), (0.121 * s_, -0.087, 0.62), (0.121 * s_, -0.087, 0.45), (0.121 * s_, -0.07, 0.22)], [0.13, 0.118, 0.112, 0.096], OLIVE, segs=20, cap0=0.5)   # baggy cargo pants
    soft.append((o, lpts, ["Hips", "UpperLeg." + L, "LowerLeg." + L]))
    rbox((0.205 * s_, -0.06, 0.76), (0.04, 0.12, 0.14), OLIVE_D, "UpperLeg." + L, bevel=0.02)    # cargo pocket
    rbox((0.121 * s_, -0.185, 0.54), (0.14, 0.06, 0.16), DGREY, "LowerLeg." + L, bevel=0.035)    # knee pad
    rbox((0.121 * s_, -0.215, 0.54), (0.09, 0.02, 0.09), BLACK, "LowerLeg." + L, bevel=0.012)
    ring((0.121 * s_, -0.09, 0.5), 0.1, 0.1, 0.014, BLACK, "LowerLeg." + L)                       # pad strap
    rbox((0.121 * s_, -0.13, 0.1), (0.23, 0.44, 0.17), BROWN, "Foot." + L, bevel=0.075)          # chunky boot
    rbox((0.121 * s_, -0.13, 0.03), (0.245, 0.455, 0.06), SOLE, "Foot." + L, bevel=0.02)          # thick sole
    rbox((0.121 * s_, -0.235, 0.18), (0.085, 0.14, 0.022), BLACK, "Foot." + L, bevel=0.008)      # laces
    ring((0.121 * s_, -0.075, 0.23), 0.095, 0.095, 0.035, BROWN, "LowerLeg." + L)                  # boot collar
ring((-0.121, -0.06, 0.75), 0.112, 0.112, 0.014, BLACK, "UpperLeg.R")                               # thigh strap

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
