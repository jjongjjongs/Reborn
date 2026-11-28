# 시안 render of the ruined-downtown zombie map (blender -b --python zcity_mock.py): a blockout built from the
# plan mockup (plan units 10 = 1 m, 760 x 600 -> 76 x 60 m), dusk sky, smoke, fire; several camera views.
import bpy, math, random, sys
from mathutils import Vector
random.seed(7)
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene

def P(x, y, z=0.0): return Vector((x / 10.0 - 38.0, 30.0 - y / 10.0, z))
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
MATS = {}
def mat(n, rgb, rough=0.8, metal=0.0, emit=0.0, alpha=1.0):
    if n in MATS: return MATS[n]
    m = bpy.data.materials.new(n); m.use_nodes = True; b = m.node_tree.nodes["Principled BSDF"]
    c = (lin(rgb[0]), lin(rgb[1]), lin(rgb[2]), 1); b.inputs["Base Color"].default_value = c
    b.inputs["Roughness"].default_value = rough; b.inputs["Metallic"].default_value = metal
    if emit: b.inputs["Emission Color"].default_value = c; b.inputs["Emission Strength"].default_value = emit
    if alpha < 1.0:
        b.inputs["Alpha"].default_value = alpha; m.blend_method = "BLEND"; m.shadow_method = "NONE"
    MATS[n] = m; return m
ASPH = mat("asph", (0.16, 0.16, 0.17), 0.9); SIDE = mat("side", (0.36, 0.35, 0.33)); LINE = mat("line", (0.75, 0.68, 0.35))
CONC = mat("conc", (0.48, 0.47, 0.45)); CONC2 = mat("conc2", (0.34, 0.33, 0.32)); BRICK = mat("brick", (0.45, 0.25, 0.18))
WIN = mat("win", (0.05, 0.06, 0.07), 0.2, 0.3); WINL = mat("winl", (1.0, 0.75, 0.4), 0.5, 0.0, 3.0)
BUS = mat("bus", (0.85, 0.65, 0.12), 0.5, 0.2); RUST = mat("rust", (0.35, 0.18, 0.1), 0.9)
CARS = [mat("c1", (0.3, 0.4, 0.55), 0.4, 0.4), mat("c2", (0.55, 0.15, 0.12), 0.4, 0.4), mat("c3", (0.75, 0.75, 0.73), 0.4, 0.4), mat("c4", (0.12, 0.12, 0.13), 0.4, 0.4)]
TANK = mat("tank", (0.7, 0.12, 0.1), 0.4, 0.5); STEEL = mat("steel", (0.55, 0.56, 0.58), 0.35, 0.8)
SAND = mat("sand", (0.62, 0.55, 0.4), 0.95); OLIVE = mat("olive", (0.3, 0.33, 0.22)); WHITE = mat("white", (0.85, 0.86, 0.85))
CONT = [mat("k1", (0.55, 0.32, 0.14), 0.7, 0.3), mat("k2", (0.16, 0.34, 0.5), 0.7, 0.3)]
FIRE = mat("fire", (1.0, 0.45, 0.1), 0.5, 0.0, 25.0); FIRE2 = mat("fire2", (1.0, 0.8, 0.3), 0.5, 0.0, 40.0)
SMOKE = mat("smoke", (0.12, 0.11, 0.11), 1.0, 0.0, 0.0, 0.55); SMOKE2 = mat("smoke2", (0.3, 0.28, 0.27), 1.0, 0.0, 0.0, 0.35)
RED = mat("redx", (0.65, 0.05, 0.04), 0.6); NEON = mat("neon", (0.2, 0.9, 1.0), 0.4, 0.0, 6.0); NEON2 = mat("neon2", (1.0, 0.25, 0.5), 0.4, 0.0, 6.0)
DIRT = mat("dirt", (0.27, 0.24, 0.2), 1.0); GLASSB = mat("glassb", (0.4, 0.5, 0.55), 0.1, 0.0, 0.0, 0.4)

def car(x, y, r, m, flip=False):
    a = math.radians(r); fwd = Vector((math.cos(a), math.sin(a), 0)); side = Vector((-math.sin(a), math.cos(a), 0))
    base = P(x, y, 0.0)
    if flip:                                     # on its roof
        box(base + Vector((0, 0, 0.85)), (4.2, 1.85, 0.8), m, rz=a); box(base + Vector((0, 0, 0.3)), (2.4, 1.7, 0.6), WIN, rz=a); return
    box(base + Vector((0, 0, 0.6)), (4.2, 1.85, 0.75), m, rz=a)
    box(base + Vector((0, 0, 1.2)) - fwd * 0.2, (2.3, 1.7, 0.6), WIN, rz=a)
    box(base + Vector((0, 0, 1.52)) - fwd * 0.2, (2.1, 1.6, 0.06), m, rz=a)
    for fx in (-1.35, 1.35):
        for sy in (-0.9, 0.9):
            cyl(base + fwd * fx + side * sy + Vector((0, 0, 0.35)), 0.36, 0.25, mat("tyre", (0.05, 0.05, 0.05)), rot=(math.radians(90), 0, a), v=12)
def box(c, s, m, rz=0.0, rx=0.0, ry=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=c, rotation=(rx, ry, rz)); o = bpy.context.active_object
    o.scale = s; o.data.materials.append(m); return o
def cyl(c, r, d, m, rot=(0, 0, 0), v=16, r2=None):
    if r2 is None: bpy.ops.mesh.primitive_cylinder_add(vertices=v, radius=r, depth=d, location=c, rotation=rot)
    else: bpy.ops.mesh.primitive_cone_add(vertices=v, radius1=r, radius2=r2, depth=d, location=c, rotation=rot)
    o = bpy.context.active_object; o.data.materials.append(m); return o
def sph(c, r, m, sz=1.0):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=r, location=c); o = bpy.context.active_object
    o.scale.z = sz; o.data.materials.append(m)
    for p in o.data.polygons: p.use_smooth = True
    return o

# ---------------------------------------------------------------- ground
box(P(380, 300, -0.1), (110, 100, 0.2), ASPH)
for x0, y0, x1, y1 in [(20, 380, 350, 580), (20, 20, 350, 370), (360, 20, 740, 290)]:      # sidewalk / plaza slabs
    c = P((x0 + x1) / 2, (y0 + y1) / 2, 0.08); box(c, ((x1 - x0) / 10, (y1 - y0) / 10, 0.16), SIDE)
for i in range(14): box(P(400 + i * 24, 339, 0.02), (1.2, 0.15, 0.02), LINE)              # lane dashes
for i in range(10): box(P(549, 360 + i * 22, 0.02), (0.15, 1.2, 0.02), LINE)
for i in range(60):                                                                          # cracks / patches / litter
    x, y = random.uniform(20, 740), random.uniform(20, 580)
    box(P(x, y, 0.03), (random.uniform(0.5, 3), random.uniform(0.05, 0.12), 0.02), mat("crk", (0.07, 0.07, 0.07)), rz=random.uniform(0, 3.14))
for i in range(90):                                                                          # rubble
    x, y = random.uniform(20, 740), random.uniform(20, 580); s = random.uniform(0.2, 0.7)
    box(P(x, y, s * 0.3), (s, s * 0.8, s * 0.6), random.choice([CONC, CONC2, BRICK]), rz=random.uniform(0, 3), rx=random.uniform(0, .5))

# ---------------------------------------------------------------- city around (ruined high-rises beyond the edge)
def tower(x, y, w, d, h, m, broken=True):
    base = box(P(x, y, h / 2), (w, d, h), m)
    floors = int(h / 3.2)
    for f in range(1, floors):                                                               # window bands on all four sides
        z = f * 3.2 + 0.4
        for side in (1, -1):
            box(P(x, y, z) + Vector((0, side * d / 2, 0)), (w * 0.86, 0.12, 1.3), WINL if random.random() < 0.04 else WIN)
            box(P(x, y, z) + Vector((side * w / 2, 0, 0)), (0.12, d * 0.86, 1.3), WIN)
    if broken:                                                                               # collapsed top corner
        box(P(x, y, h) + Vector((w * 0.25, d * 0.2, 0.6)), (w * 0.5, d * 0.6, 1.6), m, rz=0.2, ry=0.3)
        for k in range(4): box(P(x, y, h + 1.5) + Vector((random.uniform(-w / 3, w / 3), random.uniform(-d / 3, d / 3), random.uniform(0, 1.5))), (0.1, 0.1, 2.0), RUST, rx=random.uniform(-.6, .6))
    return base
for i, (x, y, w, d, h) in enumerate([(-90, 100, 10, 14, 26), (-90, 260, 10, 14, 18), (-90, 450, 10, 16, 34), (-90, 580, 10, 12, 22),
        (100, -90, 16, 10, 30), (300, -90, 14, 10, 20), (470, -90, 14, 10, 44), (650, -90, 16, 10, 28), (850, -90, 14, 10, 34),
        (850, 120, 10, 14, 9), (850, 300, 10, 14, 6), (850, 480, 10, 16, 8), (120, 690, 16, 10, 7), (330, 690, 14, 10, 9), (560, 690, 16, 10, 6), (760, 690, 12, 10, 8)]):
    tower(x, y, w, d, h, [CONC, BRICK, CONC2][i % 3])

# ---------------------------------------------------------------- zone 1: subway plaza, overturned bus, pharmacy
box(P(115, 515, 0.6), (7.0, 4.0, 1.2), CONC2)                                                # subway entrance block
box(P(115, 515, 1.3), (7.4, 4.4, 0.25), WIN)
for k in range(5): box(P(95 + k * 9, 520, 0.4 - k * 0.12), (0.9, 3.2, 0.2), CONC)              # steps down
box(P(115, 498, 2.6), (5.5, 0.3, 1.0), mat("sub", (0.15, 0.4, 0.75), 0.4, 0.0, 2.0))          # metro sign
bus = box(P(115, 423, 1.3), (11.0, 2.6, 2.8), BUS, rz=math.radians(-18), rx=math.radians(88)) # on its side
for k in range(5): box(P(80 + k * 15, 412 + k * 5, 2.6), (1.4, 0.1, 1.0), WIN, rz=math.radians(-18))
box(P(270, 465, 2.0), (12.0, 7.0, 4.0), BRICK)                                               # pharmacy
box(P(270, 430, 2.6), (8.0, 0.2, 1.8), mat("shut", (0.5, 0.5, 0.5), 0.6, 0.6))                # half-lowered shutter
box(P(270, 430, 4.4), (9.0, 0.3, 0.9), mat("cross", (0.1, 0.8, 0.3), 0.4, 0.0, 4.0))          # green cross sign
for k, (x, y, r) in enumerate([(232, 531, 25), (292, 551, -12), (180, 560, 60)]):
    car(x, y, r, CARS[k % 4], flip=(k == 2))
cyl(P(60, 560, 0.05), 0.8, 0.1, mat("manh", (0.05, 0.05, 0.05)))
sph(P(60, 560, 0.2), 0.6, SMOKE2, 0.6)

# ---------------------------------------------------------------- zone 2: intersection, pile-up, overpass, burning tanker
for k, (x, y, r) in enumerate([(450, 380, 30), (490, 405, -20), (620, 390, 70), (660, 470, 0), (470, 470, 110), (600, 520, -35), (520, 360, 85), (700, 410, 15)]):
    car(x, y, r, CARS[k % 4], flip=(k in (1, 5)))
# broken overpass: deck rising from the street, snapped off, rebar sticking out, pillars
a, b = P(380, 540, 0.0), P(560, 485, 5.0)
d = b - a; L = d.length; mid = (a + b) / 2
deck = box(mid, (L, 7.0, 0.8), CONC, rz=math.atan2(d.y, d.x), ry=-math.asin(d.z / L))
for t in (0.55, 0.9): cyl(a + d * t - Vector((0, 0, a.z + d.z * t / 2 + 0.1)) + Vector((0, 0, (d.z * t) / 2)), 0.6, d.z * t + 0.2, CONC2)
for k in range(12): box(b + Vector((random.uniform(-0.5, 0.5), random.uniform(-3, 3), random.uniform(-0.2, 0.3))), (0.08, 0.08, 2.5), RUST, ry=math.radians(70), rz=random.uniform(-.3, .3))
for k in range(8): box(b + Vector((random.uniform(1, 4), random.uniform(-3, 3), -4.5 + random.uniform(0, 1))), (random.uniform(1, 2.5),) * 2 + (1.0,), CONC, rz=random.uniform(0, 3), rx=random.uniform(0, .6))
tk = P(674, 530, 1.3)
cyl(tk, 1.3, 7.5, TANK, rot=(math.radians(90), 0, math.radians(10)), v=24)                    # tanker on its side, burning
box(tk + Vector((-4.6, 0.5, -0.2)), (2.4, 2.4, 2.4), mat("cab", (0.85, 0.85, 0.82), 0.4, 0.3), rz=0.2)
for k in range(16):
    c = tk + Vector((random.uniform(-3, 3), random.uniform(-1.5, 1.5), 1.0 + random.uniform(0, 1.5)))
    cyl(c, random.uniform(0.4, 0.9), random.uniform(1.5, 3.5), random.choice([FIRE, FIRE2]), v=8, r2=0.05)
L1 = bpy.data.lights.new("fire", "POINT"); L1.energy = 9000; L1.color = (1.0, 0.45, 0.15); L1.shadow_soft_size = 2.0
o = bpy.data.objects.new("fire", L1); sc.collection.objects.link(o); o.location = tk + Vector((0, 0, 3.0))

# ---------------------------------------------------------------- zone 3: mall (roof caved in over the atrium)
mx0, my0, mx1, my1 = 40, 40, 330, 280
c = P((mx0 + mx1) / 2, (my0 + my1) / 2); W, D = (mx1 - mx0) / 10, (my1 - my0) / 10
for side in (1, -1):
    box(c + Vector((0, side * D / 2, 4.5)), (W, 0.4, 9.0), CONC)
    box(c + Vector((side * W / 2, 0, 4.5)), (0.4, D, 9.0), CONC)
for k in range(5):                                                                            # shop windows, smashed (south side)
    box(P(60 + k * 58, 280, 1.8), (4.2, 0.5, 3.0), GLASSB)
for k in range(3): box(P(70 + k * 100, 282, 0.4), (3.0, 1.2, 0.3), GLASSB, rz=random.uniform(-.3, .3))
for (ox, oy, sx, sy) in [(0, (D / 2 + 6.5) / 2, W, D / 2 - 6.5), (0, -(D / 2 + 5.5) / 2, W, D / 2 - 5.5),
        ((W / 2 + 7.5) / 2, 0.5, W / 2 - 7.5, 12.0), (-(W / 2 + 7.5) / 2, 0.5, W / 2 - 7.5, 12.0)]:   # 2nd floor slab around the atrium
    box(c + Vector((ox, oy, 4.5)), (sx, sy, 0.35), CONC2)
box(c + Vector((0, 0, 0.17)), (W, D, 0.1), mat("tile2", (0.42, 0.4, 0.37), 0.4))
for x in (-7.6, 7.6): box(c + Vector((x, 0.5, 5.2)), (0.2, 12.0, 1.0), GLASSB)                 # balcony rails
for x in (-9.0, 9.0): box(c + Vector((x, -1.0, 2.3)), (1.4, 7.5, 0.35), STEEL, rx=math.radians(33))   # escalators
box(c + Vector((W * 0.3, -D * 0.3, 9.0)), (W * 0.4, D * 0.4, 0.3), CONC2)                     # what is left of the roof
box(c + Vector((-W * 0.35, D * 0.3, 9.0)), (W * 0.3, D * 0.4, 0.3), CONC2)
for k in range(10): box(c + Vector((random.uniform(-6, 6), random.uniform(-5, 6), random.uniform(0.3, 1.0))), (random.uniform(1, 3),) * 2 + (0.5,), CONC2, rz=random.uniform(0, 3), rx=random.uniform(0, .5))
box(c + Vector((0, -D / 2 - 0.5, 7.5)), (12, 0.3, 2.2), NEON2)                                # flickering sign
box(P(185, 335, 0.08), (29, 5, 0.1), ASPH)                                                    # ramp road
cyl(P(150, 340, 0.4), 0.15, 8.0, STEEL, rot=(math.radians(85), 0, math.radians(30)))         # fallen street light

# ---------------------------------------------------------------- zone 4: military checkpoint + hospital
for (x, y, l, r) in [(430, 86, 6, 0), (515, 106, 7, 0), (435, 136, 5, 0), (560, 150, 6, 90)]:
    for row in range(3):
        for k in range(int(l / 0.9)):
            box(P(x, y, 0.25 + row * 0.42) + Vector((k * 0.9 - l / 2 + row * 0.3, 0, 0)) if r == 0 else P(x, y, 0.25 + row * 0.42) + Vector((0, k * 0.9 - l / 2, 0)),
                (0.85, 0.5, 0.4), SAND)
for (x, y) in [(470, 60), (540, 60)]:                                                         # tents
    t = cyl(P(x, y, 1.4), 2.6, 2.8, OLIVE, v=4, r2=0.2); t.rotation_euler.z = math.radians(45); t.scale = (1.0, 1.4, 1.0)
for k in range(6): box(P(400 + k * 12, 160, 0.35), (0.9, 0.5, 0.5), OLIVE)                    # ammo crates
box(P(660, 140, 9.0), (12.0, 20.0, 18.0), WHITE)                                              # hospital
for f in range(1, 5):
    box(P(600, 140, f * 3.6), (0.12, 18.0, 1.4), WIN)
box(P(600, 160, 15.5), (0.3, 6.0, 1.2), mat("er", (1.0, 0.1, 0.1), 0.4, 0.0, 5.0))           # red ER sign
cyl(P(660, 140, 18.05), 4.0, 0.1, mat("heli", (0.25, 0.25, 0.27)))                            # rooftop helipad
box(P(660, 140, 18.12), (0.6, 3.6, 0.02), WHITE); box(P(660, 140, 18.12), (2.4, 0.6, 0.02), WHITE, rz=0);
for (x, y, m) in [(420, 225, 0), (485, 235, 1), (420, 225, 1)]:                               # containers + ladder
    box(P(x, y, 1.3 + (2.6 if (x, y, m) == (420, 225, 1) else 0)), (6.0, 2.4, 2.6), CONT[m], rz=0.1 if m else 0)
for k in range(10): box(P(450, 205, 0.3 + k * 0.5), (0.05, 0.5, 0.05), STEEL)

# barricades between zones (concrete jersey walls + wire)
for (x0, y0, x1, y1) in [(352, 440, 352, 500), (180, 372, 240, 372), (540, 292, 600, 292), (352, 170, 352, 230)]:
    a, b = P(x0, y0, 0.5), P(x1, y1, 0.5); n = int((b - a).length / 2.0) + 1
    for k in range(n):
        box(a.lerp(b, k / max(n - 1, 1)), (1.9, 0.6, 1.0), CONC, rz=math.atan2((b - a).y, (b - a).x))

# ---------------------------------------------------------------- smoke columns
for (x, y, h) in [(674, 520, 22), (170, 60, 18), (-60, 450, 30), (820, 120, 26), (470, -70, 30)]:
    base = P(x, y, 2.0)
    for k in range(9):
        z = k * h / 9.0; r = 1.5 + k * 0.6
        sph(base + Vector((k * 0.6 + random.uniform(-.5, .5), k * 0.3, z)), r, SMOKE if k < 5 else SMOKE2, 0.8)

# ---------------------------------------------------------------- sky + light
w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True
nt = w.node_tree; sky = nt.nodes.new("ShaderNodeTexSky"); sky.sky_type = "NISHITA"
sky.sun_elevation = math.radians(4); sky.sun_rotation = math.radians(250); sky.air_density = 3.0; sky.dust_density = 6.0
nt.links.new(sky.outputs[0], nt.nodes["Background"].inputs[0]); nt.nodes["Background"].inputs[1].default_value = 0.7
sun = bpy.data.lights.new("sun", "SUN"); sun.energy = 3.5; sun.color = (1.0, 0.55, 0.35); sun.angle = math.radians(3)
so = bpy.data.objects.new("sun", sun); sc.collection.objects.link(so); so.rotation_euler = (math.radians(68), 0, math.radians(250 - 90))
sc.render.engine = "BLENDER_EEVEE"; sc.eevee.taa_render_samples = 48; sc.eevee.use_gtao = True; sc.eevee.use_bloom = True
sc.eevee.use_soft_shadows = True; sc.eevee.shadow_cascade_size = "2048"
sc.view_settings.view_transform = "Filmic"; sc.view_settings.look = "Medium High Contrast"
sc.render.resolution_x = 1600; sc.render.resolution_y = 900

cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
def shot(name, pos, tgt, lens=24):
    cam.location = pos; cam.data.lens = lens
    cam.rotation_euler = (tgt - pos).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = "/tmp/zc_%s.png" % name; bpy.ops.render.render(write_still=True)
if "--views" not in sys.argv: shot("aerial", P(760, 760, 62), P(380, 300, 0), 26)
shot("plaza", P(60, 470, 1.8), P(330, 520, 1.5), 20)
shot("crossing", P(410, 335, 6.5), P(690, 520, 1.0), 20)
shot("mall", P(80, 110, 6.6), P(230, 190, 0.5), 15)
shot("checkpoint", P(400, 265, 1.8), P(520, 70, 2.0), 20)
print("RENDERED")
