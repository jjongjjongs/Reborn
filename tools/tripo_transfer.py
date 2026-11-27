#!/usr/bin/env python3
# Resample the Tripo atlas onto a repacked UV layout (see tools/blender/repack_tripo.py).
#   python3 tools/tripo_transfer.py NAME SIZE   -> /tmp/tripo_out/NAME_{color,orm}.jpg, NAME_normal.png
# Every triangle is rasterised in the new layout; each texel maps back through barycentrics to the old
# UVs and samples the 4096 atlas bilinearly. Edges are padded so mipmaps do not bleed.
import sys
import numpy as np
from PIL import Image
NAME = sys.argv[1]; S = int(sys.argv[2])
d = np.load("/tmp/tripo_out/%s_uv.npz" % NAME); old = d["old"]; new = d["new"]
srcs = {"color": "/tmp/tripo_out/atlas_Color.jpg", "orm": "/tmp/tripo_out/atlas_ORM.jpg", "normal": "/tmp/tripo_out/atlas_NormalGL.png"}
atl = {k: np.asarray(Image.open(p).convert("RGB"), dtype=np.float32) for k, p in srcs.items()}
AH, AW = atl["color"].shape[:2]
src_uv = np.zeros((S, S, 2), np.float32); mask = np.zeros((S, S), bool)
P = new * S
for t in range(len(P)):
    p = P[t]; q = old[t]
    x0 = int(max(0, np.floor(p[:, 0].min()))); x1 = int(min(S - 1, np.ceil(p[:, 0].max())))
    y0 = int(max(0, np.floor(p[:, 1].min()))); y1 = int(min(S - 1, np.ceil(p[:, 1].max())))
    if x1 < x0 or y1 < y0: continue
    xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
    v0 = p[1] - p[0]; v1 = p[2] - p[0]
    den = v0[0] * v1[1] - v1[0] * v0[1]
    if abs(den) < 1e-9: continue
    dx = xs - p[0, 0]; dy = ys - p[0, 1]
    b1 = (dx * v1[1] - v1[0] * dy) / den; b2 = (v0[0] * dy - dx * v0[1]) / den; b0 = 1 - b1 - b2
    e = -0.6 / max(abs(den) ** 0.5, 1e-6)          # include texels just outside the edge
    inside = (b0 >= e) & (b1 >= e) & (b2 >= e)
    if not inside.any(): continue
    uv = b0[..., None] * q[0] + b1[..., None] * q[1] + b2[..., None] * q[2]
    yy = ys[inside].astype(int); xx = xs[inside].astype(int)
    src_uv[yy, xx] = uv[inside]; mask[yy, xx] = True
# pad: grow filled texels outward a few times
for _ in range(8):
    grow = np.zeros_like(mask); acc = np.zeros_like(src_uv)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        m = np.roll(mask, (dy, dx), (0, 1)); u = np.roll(src_uv, (dy, dx), (0, 1))
        take = m & ~mask & ~grow
        acc[take] = u[take]; grow |= take
    src_uv[grow] = acc[grow]; mask |= grow
def sample(img, uv):
    x = np.clip(uv[..., 0] * AW - 0.5, 0, AW - 1.001); y = np.clip((1.0 - uv[..., 1]) * AH - 0.5, 0, AH - 1.001)
    xi = x.astype(int); yi = y.astype(int); fx = (x - xi)[..., None]; fy = (y - yi)[..., None]
    a = img[yi, xi]; b = img[yi, xi + 1]; c = img[yi + 1, xi]; dd = img[yi + 1, xi + 1]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + dd * fx) * fy
for k, img in atl.items():
    out = np.zeros((S, S, 3), np.float32); out[..., :] = (128, 128, 255) if k == "normal" else (90, 90, 90)
    out[mask] = sample(img, src_uv[mask])
    im = Image.fromarray(np.clip(out[::-1], 0, 255).astype(np.uint8))      # image rows top-down, v up
    if k == "normal": im.save("/tmp/tripo_out/%s_normal.png" % NAME)
    else: im.save("/tmp/tripo_out/%s_%s.jpg" % (NAME, k), quality=92)
print("TRANSFER", NAME, S, "filled %.1f%%" % (100.0 * mask.mean()))
