# height + surface-kind grid for the temple map (python3 temple_height.py -> /tmp/gbg/temple_hm.npz)
import numpy as np, math, sys, os
from PIL import Image, ImageDraw
from scipy.ndimage import distance_transform_edt, gaussian_filter
sys.path.insert(0, os.path.dirname(__file__)); from temple_layout import *
RES = 2.0                                            # cells per metre
M = 24.0                                             # mountain margin round the plan
NX, NY = int((W + 2 * M) * RES) + 1, int((H + 2 * M) * RES) + 1
def mask(poly):
    im = Image.new("L", (NX, NY), 0); ImageDraw.Draw(im).polygon([((x + M) * RES, (y + M) * RES) for x, y in poly], fill=1)
    return np.array(im, dtype=bool)
inside_m = mask(OUTLINE)
h = np.zeros((NY, NX)); kind = np.zeros((NY, NX), dtype=np.uint8)   # 0 ground, 1 terrace, 2 ramp, 3 water, 4 mountain, 5 cave, 6 stream bed
yy, xx = np.mgrid[0:NY, 0:NX] / RES - M
rng = np.random.default_rng(3)
noise = gaussian_filter(rng.normal(0, 1, (NY, NX)), 6) * 6.0
h += noise * 0.12 * inside_m                         # gentle bumps on the valley floor
for poly, lv in TERRACES:
    m = mask(poly); h[m] = lv; kind[m] = 1
# pond
pm = mask(POND); d_in = distance_transform_edt(pm) / RES
sd = np.min([np.hypot(xx - a, yy - b) for a, b in POND_SHORES], axis=0)
slope = np.where(sd < 3.0, 0.3, np.where(sd < 5.0, 0.3 + (sd - 3.0) * 0.45, 1.2))      # beaches: 0.3 m per m
h[pm] = np.maximum(POND_BED, 4.8 - np.minimum(d_in * slope, 1.4))[pm]; kind[pm] = 3
# stream: a channel 0.6 m below its banks, waterfalls where the terraces step
sm = np.zeros((NY, NX), dtype=bool)
im = Image.new("L", (NX, NY), 0); ImageDraw.Draw(im).line([((x + M) * RES, (y + M) * RES) for x, y in STREAM], fill=1, width=1)
sd_ = distance_transform_edt(~np.array(im, dtype=bool)) / RES          # metres from the stream's centre line
h -= 0.6 * np.clip((2.4 - sd_) / 1.4, 0.0, 1.0)                         # flat bed 1 m each side, banks at ~23 deg: walk in, walk out
sm = sd_ < 1.7; kind[sm] = 6
im_ = mask(GH_ISLAND); h[im_] = GH_BASE; kind[im_] = 1                       # 경회루 stone island
# ramps / paths / cave (override)
for (x0, y0, h0), (x1, y1, h1), w, k in RAMPS:
    dx, dy = x1 - x0, y1 - y0; L = math.hypot(dx, dy); ux, uy = dx / L, dy / L
    t = ((xx - x0) * ux + (yy - y0) * uy) / L
    s = np.abs(-(xx - x0) * uy + (yy - y0) * ux)
    ww = w + 0.5 if k == "stairs" else (w - 0.2 if k == "bridge" else w)   # stairs: walkable slope as wide as the steps, under the cheek stones (no gaps to get stuck in)
    m = (t >= -0.02) & (t <= 1.02) & (s <= ww / 2)
    tt = np.clip(t, 0, 1)
    if k == "stairs": tt = np.floor(tt * L / 0.45) * 0.45 / L * 0 + tt     # smooth slope (steps are drawn as a mesh)
    h[m] = h0 + (h1 - h0) * tt[m]; kind[m] = 5 if k == "cave" else (1 if k == "bridge" else 2)
# landings: where a stair / path / tunnel ends with lower ground ahead, carry its end height on for RAMP_PAD m
for (x0, y0, h0), (x1, y1, h1), w, k in RAMPS:
    if k == "bridge" or h1 == GH_DECK: continue           # 경회루 stair has its own stone landing
    dx, dy = x1 - x0, y1 - y0; L = math.hypot(dx, dy); ux, uy = dx / L, dy / L
    t = ((xx - x0) * ux + (yy - y0) * uy) / L; s = np.abs(-(xx - x0) * uy + (yy - y0) * ux)
    for lo, hi, he in ((-RAMP_PAD / L, -0.02, h0), (1.02, 1 + RAMP_PAD / L, h1)):
        m = (t >= lo) & (t <= hi) & (s <= w / 2 + 0.25) & (h < he - 0.3) & inside_m & (kind != 2) & (kind != 5)
        if m.any():
            h[m] = he; kind[m] = np.where(kind[m] == 0, 1, kind[m]); print("landing", k, round(he, 1), int(m.sum()))
# mountains outside the valley
dist_out = distance_transform_edt(~inside_m) / RES
mnt = 9.0 + np.minimum(dist_out, 20) * 1.0 + gaussian_filter(rng.normal(0, 1, (NY, NX)), 4) * 8.0
edge = np.clip(dist_out / 1.5, 0, 1)
h = np.where(inside_m, h, np.maximum(h, h * (1 - edge) + mnt * edge)); kind[~inside_m] = 4
# no traps: flood the walkable cells from both spawns (a step of <= 0.65 m is walkable); any ground pocket
# nobody can climb out of (a strip between terraces, the meadow under the cave) is raised to its lowest rim
from scipy import ndimage
from collections import deque
walk = (kind != 4) & (h < 20)
for it in range(12):
    seen = np.zeros_like(walk)
    q = deque()
    for sx, sy in (ATT_SPAWN, DEF_SPAWN):
        c = (int(round((sy + M) * RES)), int(round((sx + M) * RES))); seen[c] = True; q.append(c)
    while q:
        j, i = q.popleft()
        for a_, b_ in ((j + 1, i), (j - 1, i), (j, i + 1), (j, i - 1)):
            if 0 <= a_ < NY and 0 <= b_ < NX and walk[a_, b_] and not seen[a_, b_] and abs(h[a_, b_] - h[j, i]) <= 0.65:
                seen[a_, b_] = True; q.append((a_, b_))
    lab, n = ndimage.label(walk & ~seen & np.isin(kind, (0, 1, 6)))
    if n == 0: break
    for c in range(1, n + 1):
        m = lab == c
        rim = ndimage.binary_dilation(m) & ~m & walk & seen
        if not rim.any(): continue
        lvl = float(h[rim].min()); h[m] = np.maximum(h[m], lvl) if lvl > h[m].max() else lvl
        print("filled pocket", int(m.sum()), "cells to", round(lvl, 2))
os.makedirs("/tmp/gbg", exist_ok=True)
np.savez("/tmp/gbg/temple_hm.npz", h=h.astype(np.float32), kind=kind, res=RES, margin=M)
print("HM", h.shape, float(h.min()), float(h.max()))
