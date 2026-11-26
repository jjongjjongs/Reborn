# Small procedural textures for map details (crates, containers, doors, contact
# shadow, awnings). Writes game/assets/maps/tex/*.png — read by build_quarter.py.
import os, random
from PIL import Image, ImageDraw, ImageFilter
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../game/assets/maps/tex")
os.makedirs(OUT, exist_ok=True)
R = random.Random(7)

def noise(im, amt):
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            n = R.randint(-amt, amt)
            c = px[x, y]
            px[x, y] = tuple(max(0, min(255, v + n)) for v in c[:3]) + tuple(c[3:])
    return im

# wooden crate: planks + darker frame + diagonal brace
im = Image.new("RGB", (256, 256), (150, 108, 64)); d = ImageDraw.Draw(im)
for k in range(8):
    y = k * 32; shade = R.randint(-14, 14)
    d.rectangle([0, y, 255, y + 31], fill=(150 + shade, 108 + shade, 64 + shade // 2))
    d.line([0, y, 255, y], fill=(92, 64, 36), width=2)
d.rectangle([0, 0, 255, 255], outline=(98, 68, 38), width=22)
d.line([20, 236, 236, 20], fill=(118, 84, 48), width=22)
d.line([20, 236, 236, 20], fill=(98, 68, 38), width=3)
for x, y in ((11, 11), (244, 11), (11, 244), (244, 244)): d.ellipse([x - 4, y - 4, x + 4, y + 4], fill=(60, 60, 60))
noise(im, 10).filter(ImageFilter.SMOOTH).save(os.path.join(OUT, "crate.png"))

# corrugated container side (greyscale, tinted per colour in the material)
im = Image.new("RGB", (256, 256), (200, 200, 200)); d = ImageDraw.Draw(im)
for x in range(0, 256, 16):
    d.rectangle([x, 0, x + 7, 255], fill=(228, 228, 228)); d.rectangle([x + 8, 0, x + 9, 255], fill=(150, 150, 150))
d.rectangle([0, 0, 255, 255], outline=(120, 120, 120), width=8)
for k in range(30):
    x, y = R.randint(0, 255), R.randint(0, 255)
    d.ellipse([x, y, x + R.randint(4, 18), y + R.randint(2, 10)], fill=(150, 120, 100))
noise(im, 8).save(os.path.join(OUT, "container.png"))

# door: two panels with a frame
im = Image.new("RGB", (128, 256), (88, 60, 40)); d = ImageDraw.Draw(im)
d.rectangle([0, 0, 127, 255], outline=(60, 40, 26), width=10)
d.rectangle([22, 22, 105, 116], outline=(66, 44, 28), width=6)
d.rectangle([22, 136, 105, 234], outline=(66, 44, 28), width=6)
d.ellipse([96, 124, 106, 134], fill=(190, 170, 110))
noise(im, 8).save(os.path.join(OUT, "door.png"))

# metal shutter (shops / garages)
im = Image.new("RGB", (256, 256), (150, 152, 156)); d = ImageDraw.Draw(im)
for y in range(0, 256, 12): d.line([0, y, 255, y], fill=(110, 112, 116), width=3)
noise(im, 6).save(os.path.join(OUT, "shutter.png"))

# contact shadow strip: black, alpha fading away from the wall (u = along, v = 0 at wall)
im = Image.new("RGBA", (16, 64), (0, 0, 0, 0)); px = im.load()
for y in range(64):
    a = int(150 * (1 - y / 63.0) ** 2)
    for x in range(16): px[x, y] = (0, 0, 0, a)
im.save(os.path.join(OUT, "ao.png"))

# awning stripes
for name, c1, c2 in (("awning_red", (180, 52, 40), (232, 220, 196)), ("awning_green", (52, 120, 70), (230, 222, 200)), ("awning_blue", (40, 86, 150), (230, 226, 210))):
    im = Image.new("RGB", (128, 64), c1); d = ImageDraw.Draw(im)
    for x in range(0, 128, 32): d.rectangle([x + 16, 0, x + 31, 63], fill=c2)
    noise(im, 6).save(os.path.join(OUT, name + ".png"))
print("textures ->", os.path.normpath(OUT))
