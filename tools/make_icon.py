# app icon: Rookie bust (tools/blender/icon_bust.py -> /tmp/icon_bust.png) on teal->navy with an orange halo, Android sizes
from PIL import Image, ImageDraw, ImageFilter
import os
OUT = "/home/user/Reborn/game/icons"; os.makedirs(OUT, exist_ok=True)
head0 = Image.open("/tmp/icon_bust.png").convert("RGBA"); head0 = head0.crop(head0.getbbox())
def bg(S):
    im = Image.new("RGB", (S, S)); d = ImageDraw.Draw(im)
    for y in range(S):
        t = y / (S - 1); d.line([(0, y), (S, y)], fill=(int(40 + (14 - 40) * t), int(110 + (22 - 110) * t), int(120 + (34 - 120) * t)))
    return im.convert("RGBA")
def art(S, scale=1.0, with_bg=True):
    k = S / 512.0
    im = bg(S) if with_bg else Image.new("RGBA", (S, S), (0, 0, 0, 0))
    lay = Image.new("RGBA", (S, S), (0, 0, 0, 0)); d = ImageDraw.Draw(lay)
    c = S / 2; r1 = 186 * k * scale; r2 = 164 * k * scale; cy = 226 * k * scale + (S / 2) * (1 - scale)
    d.ellipse([c - r1, cy - r1, c + r1, cy + r1], fill=(255, 122, 26)); d.ellipse([c - r2, cy - r2, c + r2, cy + r2], fill=(255, 150, 60))
    w = int(420 * k * scale); h = head0.resize((w, int(head0.height * w / head0.width)), Image.LANCZOS)
    sh = Image.new("RGBA", h.size, (0, 0, 0, 0)); sh.paste((0, 0, 0, 110), (0, 0), h.split()[3]); sh = sh.filter(ImageFilter.GaussianBlur(10 * k))
    x = int((S - w) / 2); y = int(40 * k * scale + (S / 2) * (1 - scale))
    lay.alpha_composite(sh, (x + int(12 * k * scale), y + int(14 * k * scale))); lay.alpha_composite(h, (x, y))
    # keep inside the canvas (the bust runs off the bottom edge on purpose)
    im.alpha_composite(lay)
    return im
def rounded(im, r):
    m = Image.new("L", im.size, 0); ImageDraw.Draw(m).rounded_rectangle([0, 0, im.size[0] - 1, im.size[1] - 1], r, fill=255)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0)); out.paste(im, (0, 0), m); return out
art(1024).convert("RGB").save(OUT + "/icon_1024.png")
rounded(art(512), 110).save(OUT + "/icon_512.png")
art(192).convert("RGB").save(OUT + "/icon_192.png")
# adaptive icon: background = gradient only, foreground = halo + head at 72% (inside the 66% safe zone mostly)
bg(432).convert("RGB").save(OUT + "/adaptive_bg_432.png")
art(432, scale=0.72, with_bg=False).save(OUT + "/adaptive_fg_432.png")
print("ok")
