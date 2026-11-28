# 시안 v2: ruined-downtown zombie map, detailed render (blender -b --python zcity_v2.py [-- views])
# Plan units 10 = 1 m (760 x 600 -> 76 x 60 m). Bevelled blocks + grime materials, building facades (window frames,
# broken / lit glass, ledges, shopfronts with awnings and shutters, AC units, water tanks), detailed cars / bus /
# tanker, street furniture, military checkpoint gear, rubble piles, weeds, blood, papers, volumetric haze + smoke.
import bpy, math, random, sys
from mathutils import Vector
random.seed(11)
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
def P(x, y, z=0.0): return Vector((x / 10.0 - 38.0, 30.0 - y / 10.0, z))
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def L3(c): return (lin(c[0]), lin(c[1]), lin(c[2]), 1.0)

# ---------------------------------------------------------------- materials (procedural grime)
MATS = {}
def mat(n, rgb, rough=0.8, metal=0.0, emit=0.0, grime=0.35, scale=3.0, alpha=1.0):
    if n in MATS: return MATS[n]
    m = bpy.data.materials.new(n); m.use_nodes = True; nt = m.node_tree; b = nt.nodes["Principled BSDF"]
    b.inputs["Roughness"].default_value = rough; b.inputs["Metallic"].default_value = metal
    if grime > 0:
        tc = nt.nodes.new("ShaderNodeTexCoord"); nz = nt.nodes.new("ShaderNodeTexNoise"); nz.inputs["Scale"].default_value = scale
        nz.inputs["Detail"].default_value = 8.0; nz.inputs["Roughness"].default_value = 0.65
        nt.links.new(tc.outputs["Object"], nz.inputs["Vector"])
        cr = nt.nodes.new("ShaderNodeValToRGB"); cr.color_ramp.elements[0].position = 0.35; cr.color_ramp.elements[1].position = 0.75
        dark = (rgb[0] * (1 - grime), rgb[1] * (1 - grime), rgb[2] * (1 - grime))
        cr.color_ramp.elements[0].color = L3(dark); cr.color_ramp.elements[1].color = L3(rgb)
        nt.links.new(nz.outputs["Fac"], cr.inputs["Fac"]); nt.links.new(cr.outputs["Color"], b.inputs["Base Color"])
        bump = nt.nodes.new("ShaderNodeBump"); bump.inputs["Strength"].default_value = 0.08 if metal > 0.2 else 0.18
        nt.links.new(nz.outputs["Fac"], bump.inputs["Height"]); nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])
    else:
        b.inputs["Base Color"].default_value = L3(rgb)
    if emit:
        b.inputs["Emission Color"].default_value = L3(rgb); b.inputs["Emission Strength"].default_value = emit
    if alpha < 1.0:
        b.inputs["Alpha"].default_value = alpha; m.blend_method = "BLEND"; m.shadow_method = "NONE"
    MATS[n] = m; return m
def brick_mat(n, c1, c2):
    if n in MATS: return MATS[n]
    m = bpy.data.materials.new(n); m.use_nodes = True; nt = m.node_tree; b = nt.nodes["Principled BSDF"]
    tc = nt.nodes.new("ShaderNodeTexCoord"); br = nt.nodes.new("ShaderNodeTexBrick"); br.inputs["Scale"].default_value = 4.0
    br.inputs["Color1"].default_value = L3(c1); br.inputs["Color2"].default_value = L3(c2); br.inputs["Mortar"].default_value = L3((0.5, 0.48, 0.45))
    br.inputs["Mortar Size"].default_value = 0.015
    nt.links.new(tc.outputs["Object"], br.inputs["Vector"]); nt.links.new(br.outputs["Color"], b.inputs["Base Color"])
    b.inputs["Roughness"].default_value = 0.9; MATS[n] = m; return m
def smoke_mat(n, dens, col):
    m = bpy.data.materials.new(n); m.use_nodes = True; nt = m.node_tree
    for x in list(nt.nodes): nt.nodes.remove(x)
    out = nt.nodes.new("ShaderNodeOutputMaterial"); pv = nt.nodes.new("ShaderNodeVolumePrincipled")
    tc = nt.nodes.new("ShaderNodeTexCoord"); nz = nt.nodes.new("ShaderNodeTexNoise"); nz.inputs["Scale"].default_value = 1.6; nz.inputs["Detail"].default_value = 6
    nt.links.new(tc.outputs["Object"], nz.inputs["Vector"])
    gr = nt.nodes.new("ShaderNodeTexGradient"); gr.gradient_type = "SPHERICAL"; nt.links.new(tc.outputs["Object"], gr.inputs["Vector"])
    mul = nt.nodes.new("ShaderNodeMath"); mul.operation = "MULTIPLY"; nt.links.new(nz.outputs["Fac"], mul.inputs[0]); nt.links.new(gr.outputs["Fac"], mul.inputs[1])
    mul2 = nt.nodes.new("ShaderNodeMath"); mul2.operation = "MULTIPLY"; mul2.inputs[1].default_value = dens; nt.links.new(mul.outputs[0], mul2.inputs[0])
    nt.links.new(mul2.outputs[0], pv.inputs["Density"]); pv.inputs["Color"].default_value = L3(col)
    nt.links.new(pv.outputs[0], out.inputs["Volume"]); return m

ASPH = mat("asph", (0.13, 0.13, 0.14), 0.75, grime=0.45, scale=0.4); SIDE = mat("side", (0.42, 0.41, 0.39), grime=0.4, scale=1.0)
CURB = mat("curb", (0.55, 0.54, 0.5)); LINE = mat("line", (0.85, 0.72, 0.3), grime=0.5)
CONC = mat("conc", (0.55, 0.53, 0.5), grime=0.45); CONC2 = mat("conc2", (0.4, 0.39, 0.37), grime=0.5)
PLAST = [mat("pl1", (0.72, 0.66, 0.56)), mat("pl2", (0.62, 0.66, 0.68)), mat("pl3", (0.7, 0.55, 0.45))]
BRICK = brick_mat("brick", (0.5, 0.24, 0.17), (0.42, 0.2, 0.14)); BRICK2 = brick_mat("brick2", (0.45, 0.36, 0.28), (0.38, 0.3, 0.24))
FRAME = mat("frame", (0.2, 0.2, 0.21), 0.5, 0.4, grime=0.2); GLASS = mat("glass", (0.07, 0.09, 0.1), 0.05, 0.6, grime=0)
LIT = mat("lit", (1.0, 0.72, 0.38), 0.5, 0, 4.0, grime=0); HOLE = mat("hole", (0.02, 0.02, 0.02), 1.0, grime=0)
RUST = mat("rust", (0.38, 0.19, 0.1), grime=0.5); STEEL = mat("steel", (0.55, 0.56, 0.58), 0.35, 0.8, grime=0.3)
TYRE = mat("tyre", (0.04, 0.04, 0.04), 0.9, grime=0); CHROME = mat("chrome", (0.8, 0.8, 0.8), 0.2, 1.0, grime=0)
CARC = [mat("cc%d" % i, c, 0.35, 0.3, grime=0.25, scale=1.2) for i, c in enumerate([(0.24, 0.36, 0.55), (0.6, 0.12, 0.1), (0.78, 0.78, 0.76), (0.12, 0.12, 0.13), (0.3, 0.42, 0.3)])]
BURNT = mat("burnt", (0.1, 0.08, 0.07), 0.9, grime=0.5)
BUS = mat("bus", (0.88, 0.64, 0.1), 0.4, 0.2); TANK = mat("tank", (0.72, 0.72, 0.7), 0.35, 0.7)
SAND = mat("sand", (0.6, 0.52, 0.36), 0.95, grime=0.4, scale=8); OLIVE = mat("olive", (0.28, 0.31, 0.2), grime=0.4)
WHITE = mat("white", (0.86, 0.86, 0.84), grime=0.25); CONT = [mat("k1", (0.6, 0.3, 0.12), 0.6, 0.4), mat("k2", (0.14, 0.33, 0.5), 0.6, 0.4), mat("k3", (0.25, 0.45, 0.25), 0.6, 0.4)]
FIRE = mat("fire", (1.0, 0.42, 0.08), 0.5, 0, 30.0, grime=0); FIRE2 = mat("fire2", (1.0, 0.78, 0.3), 0.5, 0, 50.0, grime=0)
GRASS = mat("grass", (0.32, 0.38, 0.16), grime=0.4, scale=6); IVY = mat("ivy", (0.18, 0.3, 0.12), grime=0.5, scale=8)
BLOOD = mat("blood", (0.25, 0.02, 0.02), 0.3, grime=0.3); PAPER = mat("paper", (0.85, 0.83, 0.78), grime=0.1)
BAG = mat("bag", (0.05, 0.05, 0.06), 0.3, grime=0); YELLOW = mat("yel", (0.9, 0.75, 0.1), grime=0.3); BLK = mat("blk", (0.08, 0.08, 0.08))
AWN = [mat("aw%d" % i, c, 0.8, grime=0.4) for i, c in enumerate([(0.6, 0.12, 0.1), (0.15, 0.35, 0.5), (0.2, 0.45, 0.3), (0.7, 0.55, 0.15)])]
SIGN = [mat("sg%d" % i, c, 0.4, 0, 5.0, grime=0) for i, c in enumerate([(1.0, 0.2, 0.45), (0.2, 0.8, 1.0), (1.0, 0.6, 0.1), (0.3, 1.0, 0.4)])]
SIGND = mat("signd", (0.25, 0.25, 0.27), 0.5, grime=0.3)

def bev(o, w=0.04, seg=2):
    md = o.modifiers.new("b", "BEVEL"); md.width = w; md.segments = seg; md.limit_method = "ANGLE"; return o
def box(c, s, m, rz=0.0, rx=0.0, ry=0.0, b=0.04):
    bpy.ops.mesh.primitive_cube_add(size=1, location=c, rotation=(rx, ry, rz)); o = bpy.context.active_object
    o.scale = s; o.data.materials.append(m)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)     # textures at true size (no stretched bricks)
    if b and min(s) > b * 2.5: bev(o, b)
    return o
def cyl(c, r, d, m, rot=(0, 0, 0), v=16, r2=None):
    if r2 is None: bpy.ops.mesh.primitive_cylinder_add(vertices=v, radius=r, depth=d, location=c, rotation=rot)
    else: bpy.ops.mesh.primitive_cone_add(vertices=v, radius1=r, radius2=r2, depth=d, location=c, rotation=rot)
    o = bpy.context.active_object; o.data.materials.append(m)
    for p in o.data.polygons: p.use_smooth = True
    return o
def sph(c, r, m, sz=(1, 1, 1), sub=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub, radius=r, location=c); o = bpy.context.active_object
    o.scale = sz; o.data.materials.append(m)
    for p in o.data.polygons: p.use_smooth = True
    return o
def plane(c, sx, sy, m, rz=0.0):
    bpy.ops.mesh.primitive_plane_add(size=1, location=c, rotation=(0, 0, rz)); o = bpy.context.active_object
    o.scale = (sx, sy, 1); o.data.materials.append(m); return o

# ---------------------------------------------------------------- ground: asphalt, sidewalks with kerbs, plaza tiles
box(P(380, 300, -0.15), (160, 140, 0.3), ASPH, b=0)
for x0, y0, x1, y1 in [(20, 380, 350, 580), (20, 20, 350, 370), (360, 20, 740, 290)]:
    c = P((x0 + x1) / 2, (y0 + y1) / 2, 0.08); box(c, ((x1 - x0) / 10, (y1 - y0) / 10, 0.16), SIDE, b=0.03)
    box(c, ((x1 - x0) / 10 + 0.3, (y1 - y0) / 10 + 0.3, 0.14), CURB, b=0.03)
for i in range(16): box(P(380 + i * 22, 339, 0.01), (1.3, 0.14, 0.02), LINE, b=0)
for i in range(11): box(P(549, 352 + i * 21, 0.01), (0.14, 1.3, 0.02), LINE, b=0)
for k in range(8): box(P(500 + k * 12, 300, 0.01), (0.6, 2.6, 0.02), mat("zebra", (0.8, 0.8, 0.78), grime=0.5), b=0)   # crosswalk
for i in range(120):                                                                         # cracks
    x, y = random.uniform(0, 760), random.uniform(0, 600)
    box(P(x, y, 0.012), (random.uniform(0.6, 3.5), random.uniform(0.04, 0.1), 0.01), HOLE, rz=random.uniform(0, 3.14), b=0)
for i in range(6):                                                                           # puddles (reflect the sky)
    x, y = random.uniform(380, 740), random.uniform(300, 580)
    o = cyl(P(x, y, 0.015), random.uniform(0.5, 1.2), 0.01, mat("pud", (0.2, 0.2, 0.22), 0.05, 0.0, grime=0), v=20); o.scale.x = random.uniform(1, 1.8)
for i in range(18):                                                                          # blood
    x, y = random.uniform(40, 720), random.uniform(40, 580)
    o = cyl(P(x, y, 0.02), random.uniform(0.3, 0.9), 0.01, BLOOD, v=10); o.scale.x = random.uniform(1, 3); o.rotation_euler.z = random.uniform(0, 3)
for i in range(160):                                                                         # papers / litter
    x, y = random.uniform(0, 760), random.uniform(0, 600)
    plane(P(x, y, 0.03), random.uniform(0.2, 0.4), random.uniform(0.25, 0.35), PAPER, rz=random.uniform(0, 3.14))
def weeds(x, y, n=6, r=1.0):
    for k in range(n):
        o = cyl(P(x, y, 0.2) + Vector((random.uniform(-r, r), random.uniform(-r, r), 0)), random.uniform(0.15, 0.35), random.uniform(0.3, 0.8), GRASS, v=5, r2=0.0)
        o.rotation_euler = (random.uniform(-.3, .3), random.uniform(-.3, .3), 0)
for i in range(40): weeds(random.uniform(0, 760), random.uniform(0, 600), random.randint(3, 8), random.uniform(0.3, 1.2))
def rubble(x, y, r=2.5, n=16, z0=0.0):                                                       # a heap of broken concrete, bricks, rebar
    for k in range(n):
        s = random.uniform(0.25, 1.0) * r / 2.5; d = random.uniform(0, r)
        a = random.uniform(0, 6.28); h = max(0.0, (r - d) * 0.45)
        box(P(x, y, z0 + h * random.uniform(0.3, 1.0)) + Vector((math.cos(a) * d, math.sin(a) * d, 0)), (s, s * random.uniform(.5, 1), s * random.uniform(.3, .7)),
            random.choice([CONC, CONC2, BRICK, BRICK2]), rz=random.uniform(0, 3), rx=random.uniform(-.6, .6), ry=random.uniform(-.6, .6), b=0.03)
    for k in range(4): box(P(x, y, z0 + 0.6) + Vector((random.uniform(-r, r) * .5, random.uniform(-r, r) * .5, 0)), (0.05, 0.05, 2.0), RUST, rx=random.uniform(-1, 1), ry=random.uniform(-1, 1), b=0)

# ---------------------------------------------------------------- facades
def facade_windows(o_c, w, h, axis, sign, floors0, m_wall, lit=0.06, broken=0.25):
    """window grid on one face: frame, sill, dark / lit / smashed glass"""
    n = max(1, int(w / 2.6))
    for f in range(floors0, int(h / 3.2)):
        z = f * 3.2 + 1.6
        for i in range(n):
            t = (i + 0.5) / n * w - w / 2
            off = Vector((t, sign * (axis / 2 + 0.03), 0)) if axis is not None else None
            yield Vector((t, 0, z))
def building(x, y, w, d, h, wall, face=-1, shop=True, broken=False, lit=0.05, tank=True):
    c = P(x, y)
    box(c + Vector((0, 0, h / 2)), (w, d, h), wall, b=0.06)
    floors = int(h / 3.2)
    for f in range(1, floors):                                                               # ledges between floors
        box(c + Vector((0, 0, f * 3.2)), (w + 0.25, d + 0.25, 0.18), CONC, b=0.03)
    box(c + Vector((0, 0, h + 0.4)), (w + 0.1, d + 0.1, 0.8), CONC2, b=0.05)                 # parapet
    for sx, sy, fw in [(0, -1, w), (0, 1, w), (-1, 0, d), (1, 0, d)]:
        n = max(1, int(fw / 2.6))
        for f in range(1 if shop else 0, floors):
            z = f * 3.2 + 1.7
            for i in range(n):
                t = (i + 0.5) / n * fw - fw / 2
                pos = c + Vector((t if sy else sx * (w / 2 + 0.02), t if sx else sy * (d / 2 + 0.02), z))
                rot = 0.0 if sy else math.pi / 2
                box(pos, (1.5, 0.14, 1.9), FRAME, rz=rot, b=0)
                r = random.random()
                box(pos + Vector((0 if sy else sx * 0.03, sy * 0.03 if sy else 0, 0)), (1.3, 0.1, 1.7), LIT if r < lit else (HOLE if r < lit + broken else GLASS), rz=rot, b=0)
                box(pos + Vector((0 if sy else sx * 0.12, sy * 0.12 if sy else 0, -1.0)), (1.7, 0.25, 0.12), CONC, rz=rot, b=0)
                if random.random() < 0.08:                                                    # AC unit
                    box(pos + Vector((0 if sy else sx * 0.4, sy * 0.4 if sy else 0, -0.4)), (0.9, 0.6, 0.6), WHITE, rz=rot, b=0.03)
    if shop:                                                                                 # ground-floor shopfront on the street face
        sy = face
        box(c + Vector((0, sy * (d / 2 + 0.05), 1.5)), (w * 0.9, 0.12, 2.6), GLASS if random.random() < 0.5 else HOLE, b=0)
        box(c + Vector((0, sy * (d / 2 + 0.06), 2.2)), (w * 0.45, 0.1, 1.4), mat("shutter", (0.55, 0.56, 0.57), 0.5, 0.6, grime=0.5), b=0)
        aw = box(c + Vector((0, sy * (d / 2 + 0.9), 3.0)), (w * 0.85, 1.8, 0.1), random.choice(AWN), rx=-sy * 0.35, b=0)
        box(c + Vector((0, sy * (d / 2 + 0.15), 3.7)), (w * 0.6, 0.15, 0.7), random.choice(SIGN) if random.random() < 0.35 else SIGND, b=0)
    if tank and h > 9:
        cyl(c + Vector((w * 0.25, d * 0.2, h + 2.2)), 1.0, 2.0, mat("wood", (0.4, 0.3, 0.2)), v=12)
        for k in range(4): cyl(c + Vector((w * 0.25 + (k % 2 - .5) * 1.2, d * 0.2 + (k // 2 - .5) * 1.2, h + 0.8)), 0.06, 1.2, STEEL, v=6)
    if broken:                                                                               # a bite out of the top corner + rebar + debris below
        bx = c + Vector((w * 0.3, -d * 0.3, h - 2.0))
        box(bx, (w * 0.45, d * 0.45, 4.5), HOLE, b=0)
        for k in range(8): box(bx + Vector((random.uniform(-w * .2, w * .2), random.uniform(-d * .2, d * .2), 2.4)), (0.06, 0.06, 2.4), RUST, rx=random.uniform(-.5, .5), ry=random.uniform(-.5, .5), b=0)
        rubble(x + w * 3, y + d * 3 * (-face), 2.0, 12)
    for k in range(random.randint(0, 3)):                                                    # ivy
        side = random.choice([-1, 1])
        plane(c + Vector((random.uniform(-w / 3, w / 3), side * (d / 2 + 0.06), random.uniform(1, h * 0.6))), random.uniform(1, 2.5), random.uniform(2, 6), IVY).rotation_euler.x = math.pi / 2

# outer city: tall towers behind (north / west), lower shops on the camera sides
for i, (x, y, w, d, h, br) in enumerate([(-90, 90, 11, 15, 27, True), (-90, 260, 11, 14, 19, False), (-90, 440, 11, 16, 33, True), (-90, 590, 11, 12, 22, False),
        (90, -90, 16, 11, 30, False), (290, -90, 14, 11, 21, True), (470, -90, 14, 11, 43, False), (650, -90, 16, 11, 28, True), (850, -90, 13, 11, 34, False)]):
    building(x, y, w, d, h, [CONC, BRICK, PLAST[0], BRICK2, PLAST[1]][i % 5], face=1 if y < 0 else (1 if x < 0 else -1), shop=True, broken=br, lit=0.04)
for i, (x, y, w, d, h) in enumerate([(850, 130, 11, 14, 9.6), (850, 300, 11, 14, 6.4), (850, 470, 11, 15, 9.6), (110, 690, 16, 11, 6.4), (320, 690, 14, 11, 9.6), (560, 690, 16, 11, 6.4), (760, 690, 12, 11, 9.6)]):
    building(x, y, w, d, h, [PLAST[2], BRICK, PLAST[1], CONC][i % 4], face=-1 if y > 600 else 1, shop=True, broken=(i % 3 == 0), tank=False)

# ---------------------------------------------------------------- zone 1: subway plaza
for i in range(16):
    for j in range(9): box(P(42 + i * 9.5, 472 + j * 9.5, 0.17), (0.9, 0.9, 0.03), PLAST[i % 3] if (i + j) % 2 else CONC, b=0)
st = P(115, 515)
box(st + Vector((0, 0, 1.4)), (7.0, 4.6, 0.25), mat("canopy", (0.2, 0.3, 0.45), 0.4, 0.5), b=0.05)                 # entrance canopy
for sx in (-3.3, 3.3):
    for sy in (-2.1, 2.1): cyl(st + Vector((sx, sy, 0.7)), 0.08, 1.4, STEEL, v=8)
box(st + Vector((0, 0, -0.6)), (5.0, 3.6, 1.4), HOLE, b=0)
for k in range(6): box(st + Vector((-2.2 + k * 0.6, 0, -0.1 - k * 0.15)), (0.6, 3.4, 0.2), CONC, b=0.02)
box(st + Vector((0, -2.3, 1.95)), (3.5, 0.15, 0.7), mat("metro", (0.15, 0.5, 0.95), 0.4, 0, 4.0, grime=0), b=0)
# overturned city bus: body on its side, window band, wheels, smashed windscreen
bc = P(115, 423, 1.35); ba = math.radians(-18)
box(bc, (11.5, 2.7, 2.6), BUS, rz=ba, b=0.15)
for k in range(6):
    box(bc + Vector((math.cos(ba) * (k * 1.7 - 4.2), math.sin(ba) * (k * 1.7 - 4.2), 1.31)), (1.4, 1.6, 0.06), GLASS if k % 3 else HOLE, rz=ba, b=0)
for fx in (-3.6, 3.6):
    for fz in (-0.9, 0.9):
        cyl(bc + Vector((math.cos(ba) * fx, math.sin(ba) * fx, 0)) + Vector((-math.sin(ba) * 1.0, math.cos(ba) * 1.0, fz)), 0.55, 0.35, TYRE, rot=(math.radians(90), 0, ba), v=16)
rubble(150, 400, 1.8, 10)
# pharmacy (barricaded): brick, green cross, shutter half down, planks over the windows
building(270, 465, 12, 7, 6.4, BRICK, face=-1, shop=True, tank=False)
box(P(270, 428, 4.3), (1.2, 0.2, 1.2), mat("cross", (0.1, 0.85, 0.35), 0.4, 0, 6.0, grime=0), b=0); box(P(270, 428, 4.3), (0.4, 0.22, 1.2), mat("cross", (0, 0, 0)), b=0)
for k in range(5): box(P(240 + k * 14, 428, 1.6 + (k % 2) * 0.4), (1.6, 0.12, 0.2), mat("plank", (0.45, 0.32, 0.2), grime=0.5), ry=random.uniform(-.3, .3), b=0)

# ---------------------------------------------------------------- vehicles
def car(x, y, r, m, flip=False, burnt=False):
    a = math.radians(r); f = Vector((math.cos(a), math.sin(a), 0)); s = Vector((-math.sin(a), math.cos(a), 0))
    base = P(x, y); mm = BURNT if burnt else m
    up = -1 if flip else 1; z0 = 0.95 if flip else 0.0
    box(base + Vector((0, 0, z0 + up * 0.62)), (4.3, 1.85, 0.62), mm, rz=a, b=0.12)
    box(base + Vector((0, 0, z0 + up * 1.15)) - f * 0.25, (2.3, 1.7, 0.6), mm, rz=a, b=0.15)
    for k, t in enumerate((-0.95, 0.55)):
        box(base + Vector((0, 0, z0 + up * 1.15)) + f * (t - 0.25), (0.08, 1.62, 0.5), HOLE if (burnt or random.random() < 0.5) else GLASS, rz=a, b=0)
    box(base + Vector((0, 0, z0 + up * 1.15)) - f * 0.25 + s * 0.86, (2.0, 0.06, 0.45), GLASS, rz=a, b=0)
    box(base + Vector((0, 0, z0 + up * 1.15)) - f * 0.25 - s * 0.86, (2.0, 0.06, 0.45), GLASS, rz=a, b=0)
    for fx in (-1.35, 1.35):
        for sy in (-0.88, 0.88):
            cyl(base + f * fx + s * sy + Vector((0, 0, z0 + up * 0.36)), 0.36, 0.26, TYRE, rot=(math.radians(90), 0, a), v=14)
    box(base + f * 2.16 + Vector((0, 0, z0 + up * 0.55)), (0.06, 1.7, 0.18), CHROME, rz=a, b=0)
    if not burnt:
        for sy in (-0.6, 0.6): box(base + f * 2.17 + s * sy + Vector((0, 0, z0 + up * 0.75)), (0.05, 0.3, 0.12), mat("head", (1, 0.95, 0.8), emit=0.5, grime=0), rz=a, b=0)
for k, (x, y, r, fl, bu) in enumerate([(232, 531, 25, False, False), (292, 551, -12, False, True), (180, 560, 60, True, False),
        (450, 380, 30, False, False), (490, 405, -20, True, False), (620, 390, 70, False, True), (660, 465, 3, False, False), (470, 470, 110, False, False),
        (600, 520, -35, True, False), (520, 360, 85, False, False), (705, 410, 15, False, True), (420, 560, 160, False, False), (75, 330, 5, False, False), (300, 330, 175, False, True)]):
    car(x, y, r, CARC[k % len(CARC)], fl, bu)

# ---------------------------------------------------------------- zone 2: broken overpass + burning tanker
a, b = P(375, 545, 0.0), P(560, 488, 5.4)
d = b - a; Lg = d.length; yaw = math.atan2(d.y, d.x); pitch = -math.asin(d.z / Lg)
box((a + b) / 2, (Lg, 7.0, 0.9), CONC, rz=yaw, ry=pitch, b=0.08)
for sd in (-3.4, 3.4):                                                                          # barriers along the deck
    box((a + b) / 2 + Vector((-math.sin(yaw) * sd, math.cos(yaw) * sd, 0.7)), (Lg, 0.3, 0.6), CONC2, rz=yaw, ry=pitch, b=0.05)
for t in (0.5, 0.88):
    p = a + d * t; cyl(Vector((p.x, p.y, (p.z - 0.45) / 2)), 0.7, max(0.2, p.z - 0.45), CONC2, v=16)
for k in range(14): box(b + Vector((random.uniform(-.3, .3), random.uniform(-3, 3), random.uniform(-.3, .3))), (0.06, 0.06, 2.8), RUST, ry=math.radians(70) + random.uniform(-.4, .4), rz=random.uniform(-.4, .4), b=0)
rubble(585, 470, 3.0, 22)
tc = P(674, 528, 1.4); ta = math.radians(12)
cyl(tc, 1.35, 8.0, TANK, rot=(math.radians(90), 0, ta + math.pi / 2), v=28)                   # tanker trailer on its side (scorched)
box(tc + Vector((-math.cos(ta) * 5.4, -math.sin(ta) * 5.4, -0.1)), (2.6, 2.5, 2.7), BURNT, rz=ta, b=0.15)
for k in range(22):
    c = tc + Vector((random.uniform(-3.5, 3.5), random.uniform(-1.6, 1.6), 1.0 + random.uniform(0, 1.8)))
    rr = random.uniform(0.35, 0.8); sph(c, rr, random.choice([FIRE, FIRE2]), (1, 1, random.uniform(1.6, 2.6)), 2)
for k in range(8): sph(tc + Vector((random.uniform(-6, 6), random.uniform(-4, 4), -1.2)), random.uniform(0.2, 0.45), FIRE, (1, 1, 1.8), 1)   # burning puddles
L1 = bpy.data.lights.new("fire", "POINT"); L1.energy = 12000; L1.color = (1.0, 0.42, 0.12); L1.shadow_soft_size = 2.5
o = bpy.data.objects.new("fire", L1); sc.collection.objects.link(o); o.location = tc + Vector((0, 0, 3.0))
o = cyl(tc + Vector((0, 0, -1.38)), 7.0, 0.01, mat("scorch", (0.03, 0.03, 0.03), grime=0), v=24)

# ---------------------------------------------------------------- zone 3: mall (roof caved in over the atrium)
mx0, my0, mx1, my1 = 40, 40, 330, 280
c = P((mx0 + mx1) / 2, (my0 + my1) / 2); W, D = (mx1 - mx0) / 10, (my1 - my0) / 10
for sd in (1, -1):
    box(c + Vector((0, sd * D / 2, 4.6)), (W, 0.45, 9.2), PLAST[1], b=0.06)
    box(c + Vector((sd * W / 2, 0, 4.6)), (0.45, D, 9.2), PLAST[1], b=0.06)
for k in range(6):                                                                             # storefront glazing on the south face, mostly smashed
    box(P(55 + k * 47, 281, 1.8), (4.2, 0.2, 3.2), HOLE if k % 2 else GLASS, b=0)
    box(P(55 + k * 47, 281, 3.6), (4.4, 0.3, 0.3), FRAME, b=0)
for k in range(30): box(P(random.uniform(45, 320), random.uniform(283, 300), 0.18), (random.uniform(.1, .4),) * 2 + (0.02,), GLASS, rz=random.uniform(0, 3), b=0)
for (ox, oy, sx, sy) in [(0, (D / 2 + 6.5) / 2, W, D / 2 - 6.5), (0, -(D / 2 + 5.5) / 2, W, D / 2 - 5.5), ((W / 2 + 7.5) / 2, 0.5, W / 2 - 7.5, 12.0), (-(W / 2 + 7.5) / 2, 0.5, W / 2 - 7.5, 12.0)]:
    box(c + Vector((ox, oy, 4.6)), (sx, sy, 0.35), CONC2, b=0.03)
box(c + Vector((0, 0, 0.2)), (W - 0.6, D - 0.6, 0.06), mat("mallfloor", (0.6, 0.57, 0.52), 0.25, grime=0.4, scale=0.8), b=0)
for sx in (-7.6, 7.6): box(c + Vector((sx, 0.5, 5.25)), (0.08, 12.0, 0.95), mat("rail", (0.5, 0.6, 0.62), 0.1, 0, 0, grime=0, alpha=0.4), b=0)
for sy in (-5.5, 6.5): box(c + Vector((0, sy, 5.25)), (15.0, 0.08, 0.95), mat("rail", (0.5, 0.6, 0.62)), b=0)
for sx in (-9.2, 9.2):                                                                           # escalators
    box(c + Vector((sx, -1.0, 2.4)), (1.4, 8.0, 0.4), STEEL, rx=math.radians(32), b=0.05)
    for e in (-0.8, 0.8): box(c + Vector((sx + e, -1.0, 3.0)), (0.12, 8.0, 0.9), mat("rail", (0.5, 0.6, 0.62)), rx=math.radians(32), b=0)
box(c + Vector((W * 0.3, -D * 0.3, 9.2)), (W * 0.4, D * 0.4, 0.3), CONC2, b=0.04)                   # remaining roof pieces + a slab hanging in
box(c + Vector((-W * 0.33, D * 0.3, 9.2)), (W * 0.34, D * 0.4, 0.3), CONC2, b=0.04)
box(c + Vector((2.0, 2.0, 5.6)), (7.0, 5.0, 0.3), CONC2, rx=0.5, ry=0.25, b=0.04)
rubble(185, 160, 4.0, 30, 0.2)
for k in range(6): cyl(c + Vector((random.uniform(-5, 5), random.uniform(-4, 5), 0.6)), 0.6, 1.0, mat("pot", (0.4, 0.3, 0.25)), v=10)
box(c + Vector((0, -D / 2 - 0.4, 7.6)), (13, 0.25, 1.8), SIGN[0], b=0)                           # neon sign (half dead)
box(c + Vector((4, -D / 2 - 0.45, 7.6)), (5, 0.27, 1.85), SIGND, b=0)
box(P(185, 340, 0.06), (29, 5, 0.12), ASPH, b=0)                                                # ramp + fallen light pole
cyl(P(150, 340, 0.35), 0.12, 8.5, STEEL, rot=(math.radians(88), 0, math.radians(30)), v=8)

# ---------------------------------------------------------------- zone 4: military checkpoint + hospital
def sandbags(x, y, length, rot, rows=3):
    a = math.radians(rot); f = Vector((math.cos(a), math.sin(a), 0))
    for r in range(rows):
        n = int(length / 0.85)
        for k in range(n):
            p = P(x, y, 0.2 + r * 0.33) + f * ((k + 0.5 * (r % 2)) * 0.85 - length / 2)
            sph(p, 0.45, SAND, (1.0, 0.55, 0.38), 1).rotation_euler.z = a
for (x, y, l, r) in [(430, 86, 6.0, 0), (515, 106, 7.0, 0), (435, 136, 5.0, 0), (562, 150, 6.0, 90), (400, 110, 4.0, 90)]:
    sandbags(x, y, l, r)
for (x, y) in [(470, 58), (545, 58)]:                                                            # ridge tents
    t = P(x, y)
    for sd in (-1, 1): box(t + Vector((0, sd * 1.15, 1.2)), (5.0, 0.08, 2.9), OLIVE, rx=sd * math.radians(35), b=0)
    box(t + Vector((-2.5, 0, 1.0)), (0.06, 3.0, 2.0), mat("olive2", (0.22, 0.25, 0.16)), b=0)
for k in range(8): box(P(400 + k * 11, 162, 0.3), (0.9, 0.5, 0.45), OLIVE, rz=random.uniform(-.2, .2), b=0.04)   # ammo crates
for k in range(4): cyl(P(565 + k * 9, 170, 0.5), 0.35, 1.0, mat("drum", (0.25, 0.3, 0.2), 0.6, 0.3), v=14)    # drums
for (x, y) in [(380, 180), (580, 30)]:                                                           # floodlight towers
    cyl(P(x, y, 3.0), 0.08, 6.0, STEEL, v=6); box(P(x, y, 6.2), (1.2, 0.4, 0.6), BLK, b=0.03)
    box(P(x, y, 6.2) + Vector((0, -0.21, 0)), (1.0, 0.02, 0.45), mat("flood", (1, 1, 0.9), emit=8, grime=0), b=0)
for k in range(10):                                                                              # razor wire coil along the checkpoint edge
    bpy.ops.mesh.primitive_torus_add(major_radius=0.45, minor_radius=0.02, location=P(360 + k * 9.5, 180, 0.5), rotation=(0, math.radians(90), 0))
    bpy.context.active_object.data.materials.append(STEEL)
box(P(470, 120, 1.0), (2.0, 3.6, 1.8), mat("hmv", (0.3, 0.33, 0.22), 0.6, 0.2), b=0.15)          # military truck
box(P(492, 120, 1.4), (2.4, 3.6, 2.6), mat("hmv", (0.3, 0.33, 0.22)), b=0.15)
for fx in (455, 485, 505):
    for sy in (-1.8, 1.8): cyl(P(fx, 120, 0.5) + Vector((0, sy, 0)), 0.5, 0.35, TYRE, rot=(math.radians(90), 0, 0), v=14)
building(660, 140, 12, 20, 19.2, WHITE, face=1, shop=False, lit=0.12, tank=False)                 # hospital
box(P(600, 140, 1.6), (0.3, 8.0, 3.0), GLASS, b=0); box(P(592, 140, 3.4), (1.6, 9.0, 0.25), WHITE, b=0.04)   # ER doors + canopy
box(P(598, 170, 15.0), (0.3, 1.6, 1.6), mat("er", (1.0, 0.1, 0.1), 0.4, 0, 6.0, grime=0), b=0); box(P(598, 170, 15.0), (0.32, 0.5, 1.6), WHITE, b=0)
cyl(P(660, 140, 19.25), 4.0, 0.1, mat("heli", (0.25, 0.25, 0.27)), v=32)
box(P(660, 140, 19.32), (0.5, 3.2, 0.02), mat("hy", (0.9, 0.8, 0.1), grime=0), b=0); box(P(660, 140, 19.32), (2.2, 0.5, 0.02), mat("hy", (0.9, 0.8, 0.1)), b=0)
box(P(649, 140, 19.32), (0.5, 3.2, 0.02), mat("hy", (0.9, 0.8, 0.1)), b=0)
for (x, y, m, z) in [(420, 228, 0, 0), (488, 238, 1, 0), (422, 228, 2, 1)]:                       # containers (corrugated) + ladder
    cb = box(P(x, y, 1.3 + z * 2.6), (6.0, 2.4, 2.6), CONT[m], rz=0.08 if z else 0, b=0.04)
    for k in range(10): box(P(x, y, 1.3 + z * 2.6) + Vector((-2.7 + k * 0.6, 1.22, 0)), (0.18, 0.04, 2.4), CONT[m], b=0)
for k in range(10): box(P(452, 207, 0.3 + k * 0.5), (0.05, 0.5, 0.05), STEEL, b=0)
for s in (-0.25, 0.25): box(P(452, 207, 2.6) + Vector((0, s, 0)), (0.05, 0.05, 5.2), STEEL, b=0)

# ---------------------------------------------------------------- barricades between zones: jersey barriers + stripes + wire
for (x0, y0, x1, y1) in [(352, 440, 352, 505), (180, 372, 245, 372), (540, 292, 605, 292), (352, 165, 352, 235)]:
    a, b = P(x0, y0, 0.55), P(x1, y1, 0.55); n = int((b - a).length / 2.0) + 1; yaw = math.atan2((b - a).y, (b - a).x)
    for k in range(n):
        p = a.lerp(b, k / max(n - 1, 1))
        box(p, (1.95, 0.7, 1.1), CONC, rz=yaw + random.uniform(-.08, .08), b=0.12)
        box(p + Vector((0, 0, 0.3)), (1.6, 0.72, 0.18), YELLOW if k % 2 else BLK, rz=yaw, b=0)

# ---------------------------------------------------------------- street furniture
for (x, y, r, bent) in [(370, 300, 0, False), (730, 300, 0, True), (370, 580, 0, False), (360, 20, 0, True), (20, 375, 0, False), (240, 375, 0, True)]:
    p = P(x, y); pole = cyl(p + Vector((0, 0, 3.2)), 0.1, 6.4, STEEL, v=8)
    if bent: pole.rotation_euler = (math.radians(25), 0, random.uniform(0, 6))
    else: box(p + Vector((0.8, 0, 6.3)), (1.6, 0.25, 0.2), STEEL, b=0)
for (x, y) in [(536, 320), (565, 320)]:                                                          # traffic lights (dead)
    cyl(P(x, y, 2.2), 0.09, 4.4, mat("tl", (0.15, 0.15, 0.15)), v=8); box(P(x, y, 4.6), (0.4, 0.35, 1.1), BLK, b=0.04)
    for k, col in enumerate([(0.3, 0.05, 0.05), (0.3, 0.25, 0.05), (0.05, 0.25, 0.08)]):
        cyl(P(x, y, 4.95 - k * 0.35) + Vector((0, -0.18, 0)), 0.11, 0.05, mat("tlc%d" % k, col, emit=(3.0 if k == 1 else 0.0), grime=0), rot=(math.radians(90), 0, 0), v=12)
for (x, y) in [(355, 395), (375, 290), (745, 300)]:
    cyl(P(x, y, 0.4), 0.18, 0.8, mat("hyd", (0.75, 0.1, 0.08), grime=0.3), v=10)                 # hydrants
for i in range(30):                                                                              # trash bags, bins, tyres, barrels
    x, y = random.uniform(30, 740), random.uniform(30, 590); kind = random.random()
    if kind < 0.5: sph(P(x, y, 0.3), 0.4, BAG, (1.0, 0.9, 0.7), 2)
    elif kind < 0.7: cyl(P(x, y, 0.55), 0.35, 1.1, mat("bin", (0.25, 0.35, 0.3), 0.6, 0.3), v=12)
    elif kind < 0.85: cyl(P(x, y, 0.15), 0.4, 0.28, TYRE, v=14)
    else: cyl(P(x, y, 0.45), 0.32, 0.9, mat("barrel", (0.55, 0.2, 0.1), 0.6, 0.3), rot=(random.choice([0, math.pi / 2]), 0, random.uniform(0, 3)), v=14)
for (x, y) in [(30, 300), (330, 20), (740, 560), (20, 590)]:                                     # dead trees
    p = P(x, y); cyl(p + Vector((0, 0, 2.0)), 0.18, 4.0, mat("bark", (0.22, 0.18, 0.14)), v=7)
    for k in range(5):
        br = cyl(p + Vector((0, 0, 2.6 + k * 0.4)), 0.06, 2.0, mat("bark", (0.22, 0.18, 0.14)), v=5); br.rotation_euler = (random.uniform(.6, 1.2), 0, random.uniform(0, 6))
for (x, y) in [(560, 420), (130, 470), (620, 220), (260, 340)]: rubble(x, y, 1.6, 10)

# ---------------------------------------------------------------- smoke columns (volumes) + haze
for (x, y, h, r) in [(674, 528, 26, 3.0), (170, 70, 20, 2.5), (-90, 440, 34, 3.0), (650, -90, 30, 3.0), (470, -90, 40, 3.0)]:
    base = P(x, y, 2.0)
    for k in range(5):
        z = k * h / 5.0; rr = r + k * 1.2
        o = sph(base + Vector((k * 1.6, k * 0.8, z + rr * 0.6)), rr, smoke_mat("smk%d" % k, 1.4 - k * 0.15, (0.14, 0.13, 0.12)), (1, 1, 1.3), 2)

w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True; nt = w.node_tree
sky = nt.nodes.new("ShaderNodeTexSky"); sky.sky_type = "NISHITA"; sky.sun_elevation = math.radians(5); sky.sun_rotation = math.radians(240)
sky.air_density = 3.5; sky.dust_density = 8.0
nt.links.new(sky.outputs[0], nt.nodes["Background"].inputs[0]); nt.nodes["Background"].inputs[1].default_value = 0.75
vs = nt.nodes.new("ShaderNodeVolumeScatter"); vs.inputs["Density"].default_value = 0.006; vs.inputs["Color"].default_value = L3((0.95, 0.7, 0.55))
nt.links.new(vs.outputs[0], nt.nodes["World Output"].inputs["Volume"])
sun = bpy.data.lights.new("sun", "SUN"); sun.energy = 4.0; sun.color = (1.0, 0.55, 0.33); sun.angle = math.radians(2)
so = bpy.data.objects.new("sun", sun); sc.collection.objects.link(so); so.rotation_euler = (math.radians(70), 0, math.radians(150))
fill = bpy.data.lights.new("fill", "SUN"); fill.energy = 0.5; fill.color = (0.5, 0.6, 0.9)
fo = bpy.data.objects.new("fill", fill); sc.collection.objects.link(fo); fo.rotation_euler = (math.radians(40), 0, math.radians(-30))
sc.render.engine = "BLENDER_EEVEE"; ee = sc.eevee
ee.taa_render_samples = 64; ee.use_gtao = True; ee.gtao_distance = 1.5; ee.use_bloom = True; ee.bloom_intensity = 0.06
ee.use_soft_shadows = True; ee.shadow_cascade_size = "4096"; ee.use_ssr = True; ee.use_volumetric_shadows = True
ee.volumetric_end = 250.0; ee.volumetric_tile_size = "4"
sc.view_settings.view_transform = "Filmic"; sc.view_settings.look = "Medium High Contrast"
sc.render.resolution_x = 1600; sc.render.resolution_y = 900

cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
def shot(name, pos, tgt, lens=24):
    cam.location = pos; cam.data.lens = lens; cam.data.clip_end = 600
    cam.rotation_euler = (tgt - pos).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = "/tmp/zc2_%s.png" % name; bpy.ops.render.render(write_still=True); print("SHOT", name)
which = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
views = {
    "aerial":   (P(760, 770, 60), P(380, 300, 0), 26),
    "crossing": (P(400, 330, 6.0), P(690, 530, 1.0), 20),
    "plaza":    (P(330, 590, 2.0), P(110, 440, 1.6), 22),
    "mall":     (Vector((-31.0, 23.0, 6.4)), Vector((-17.0, 11.0, 1.2)), 16),          # inside: 2nd-floor balcony across the atrium
    "checkpoint": (P(600, 280, 2.0), P(450, 80, 2.4), 20),                           # from the street over the sandbags to the tents
    "plaza2":   (P(330, 560, 1.8), P(120, 470, 1.8), 20),                             # subway plaza: bus, metro entrance, pharmacy
}
for k, v in views.items():
    if not which or k in which: shot(k, *v)
print("RENDERED")
