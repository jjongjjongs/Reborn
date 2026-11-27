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
h[pm] = np.maximum(POND_BED, 4.8 - np.minimum(d_in, 1.2) * 1.2)[pm]; kind[pm] = 3
# stream: a channel 0.6 m below its banks, waterfalls where the terraces step
sm = np.zeros((NY, NX), dtype=bool)
im = Image.new("L", (NX, NY), 0); ImageDraw.Draw(im).line([((x + M) * RES, (y + M) * RES) for x, y in STREAM], fill=1, width=int(3.2 * RES)); sm = np.array(im, dtype=bool)
h[sm] = h[sm] - 0.6; kind[sm] = 6
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
# mountains outside the valley
dist_out = distance_transform_edt(~inside_m) / RES
mnt = 9.0 + np.minimum(dist_out, 20) * 1.0 + gaussian_filter(rng.normal(0, 1, (NY, NX)), 4) * 8.0
edge = np.clip(dist_out / 1.5, 0, 1)
h = np.where(inside_m, h, np.maximum(h, h * (1 - edge) + mnt * edge)); kind[~inside_m] = 4
os.makedirs("/tmp/gbg", exist_ok=True)
np.savez("/tmp/gbg/temple_hm.npz", h=h.astype(np.float32), kind=kind, res=RES, margin=M)
print("HM", h.shape, float(h.min()), float(h.max()))
