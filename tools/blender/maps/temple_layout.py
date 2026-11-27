# 산사 (mountain temple) bomb map - layout data shared by the height-map step and the Blender builder.
# Plan coordinates: x east 0..140, y south 0..120 (metres). Blender: X = x - 70, Y = 60 - y.
import math
W, H = 140.0, 120.0
def cr(pts, n=10):
    out = []; p = [pts[0]] + pts + [pts[-1]]
    for i in range(1, len(p) - 2):
        for k in range(n):
            t = k / n; t2 = t * t; t3 = t2 * t
            out.append(tuple(0.5 * ((2 * p[i][j]) + (-p[i - 1][j] + p[i + 1][j]) * t + (2 * p[i - 1][j] - 5 * p[i][j] + 4 * p[i + 1][j] - p[i + 2][j]) * t2
                                    + (-p[i - 1][j] + 3 * p[i][j] - 3 * p[i + 1][j] + p[i + 2][j]) * t3) for j in range(2)))
    out.append(pts[-1]); return out
OUTLINE = cr([(58, 118), (30, 112), (10, 96), (6, 72), (10, 48), (6, 26), (18, 8), (44, 4), (70, 8), (96, 4), (122, 10), (134, 30), (130, 54), (136, 76), (124, 98), (100, 112), (80, 118), (58, 118)])
# terraces: [outline, height] - later entries win where they overlap
TERRACES = [
    (cr([(20, 70), (40, 62), (64, 64), (90, 60), (118, 66), (126, 82), (110, 92), (80, 90), (50, 94), (26, 88), (20, 70)], 8), 2.4),   # 천왕문 / 범종각 / 요사채 단
    (cr([(8, 22), (14, 8), (36, 6), (52, 12), (58, 26), (54, 44), (42, 56), (26, 62), (12, 56), (6, 40), (8, 22)], 8), 4.8),             # 연못 단 (B)
    (cr([(64, 58), (84, 50), (112, 46), (128, 52), (124, 64), (104, 66), (84, 64), (66, 64), (64, 58)], 8), 4.8),                        # 만세루 앞 단
    (cr([(46, 16), (44, 6), (70, 8), (96, 4), (120, 10), (124, 22), (100, 20), (76, 26), (56, 26), (46, 16)], 8), 7.2),                 # 북쪽 언덕 (수비)
    (cr([(70, 48), (76, 28), (96, 20), (122, 22), (130, 38), (124, 50), (102, 48), (84, 52), (70, 48)], 8), 7.2),                        # 대웅전 단 (A)
]
POND = cr([(16, 28), (22, 18), (36, 16), (48, 22), (50, 34), (44, 44), (30, 48), (18, 44), (14, 36), (16, 28)], 8)
POND_SURF, POND_BED = 4.25, 3.4
STREAM = cr([(16, 46), (14, 58), (20, 74), (16, 90), (24, 104), (36, 117)], 10)
GYEONGHOERU = (31.0, 28.0, 14.0)          # centre x, y, rotation (deg)
GH_BASE = 4.8; GH_FL = 4.4; GH_DECK = GH_BASE + GH_FL + 0.36   # stone island level, upper floor height, deck top
def gh(lx, ly):
    """경회루 local (Blender-side: +x east-ish, -y = front / south) -> plan coords"""
    cx, cy, r = GYEONGHOERU; a = -math.radians(r)
    X = (cx - 70) + lx * math.cos(a) - ly * math.sin(a); Y = (60 - cy) + lx * math.sin(a) + ly * math.cos(a)
    return (X + 70, 60 - Y)
GH_ISLAND = [gh(-14.0, -10.2), gh(12.5, -10.2), gh(12.5, 9.8), gh(-14.0, 9.8), gh(-14.0, -10.2)]
GH_STAIR = (gh(-12.2, -8.3), gh(-2.6, -8.3))   # along the front edge, up to the deck
GH_LANDING = (gh(-2.6, -8.3), gh(-0.6, -8.3))   # flat landing at deck height; the railing opens right beside it
GH_GAP = (-1.6, 2.0)          # between the deck columns at x -3.2 and 0                           # railing opening: centre x, width (pavilion local)
# ramps / stairs: (x0, y0, h0) -> (x1, y1, h1), width, kind ("stairs" | "path" | "cave")
RAMPS = [
    ((64, 101, 0.0), (64, 91.0, 2.4), 4.5, "stairs"),       # 일주문 -> 천왕문 단
    ((34, 100, 0.0), (33, 88.0, 2.4), 3.5, "stairs"),       # 서쪽 오름
    ((82, 71, 2.4), (84, 62.5, 4.8), 4.0, "stairs"),        # 범종각 -> 만세루 앞
    ((100, 60, 4.8), (100, 47.5, 7.2), 3.0, "stairs"),      # 만세루 아래 -> A (between its pillars)
    ((38, 67, 2.4), (44, 54.0, 4.8), 3.5, "stairs"),        # 오솔길 -> 연못 동쪽
    ((34, 107, 0.0), (28, 90, 0.9), 3.5, "path"),           # 계곡 돌길
    ((28, 90, 0.9), (26, 74, 2.2), 3.5, "path"),
    ((26, 74, 2.2), (25, 59, 4.8), 3.5, "stairs"),          # 폭포 옆 돌계단 -> B 남쪽
    ((92, 107, 0.0), (120, 92, 1.2), 3.5, "path"),          # 대숲 능선길
    ((120, 92, 1.2), (127, 72, 3.6), 3.5, "path"),
    ((127, 72, 3.6), (125, 52, 7.2), 3.5, "stairs"),
    ((52, 77, 2.4), (79, 53, 7.2), 3.2, "cave"),            # 석굴 -> A 서쪽 (지하)
    ((54, 23, 4.8), (62, 18, 7.2), 4.0, "stairs"),          # 연못 단 -> 북쪽 (수정전)
    ((GH_STAIR[0][0], GH_STAIR[0][1], GH_BASE), (GH_STAIR[1][0], GH_STAIR[1][1], GH_DECK), 1.6, "stairs"),   # 경회루 2층
    ((GH_LANDING[0][0], GH_LANDING[0][1], GH_DECK), (GH_LANDING[1][0], GH_LANDING[1][1], GH_DECK), 1.6, "bridge"),   # 계단참
]
# bridges over the pond / stream: (x0,y0) -> (x1,y1), height, width
BRIDGES = [(gh(12.5, -3.0), gh(21.5, -3.0), 4.8, 3.0), (gh(12.5, 3.0), gh(21.5, 3.0), 4.8, 3.0),   # 경회루 동쪽 다리 2
           (gh(6.0, -10.2), gh(6.0, -21.0), 4.8, 3.0), (gh(-5.0, 9.8), gh(-5.0, 15.5), 4.8, 3.0),      # 남쪽 · 북쪽 다리
           ((14, 75), (24, 74), 2.4, 3.0), ((14, 95), (24, 96), 0.4, 3.0)]
for (x0, y0), (x1, y1), hz, w in BRIDGES:                   # bridges are walkable strips too
    RAMPS.append(((x0, y0, hz), (x1, y1, hz), w, "bridge"))
SITE_A = (102, 40); SITE_B = (31, 28)
ATT_SPAWN = (76, 112); DEF_SPAWN = (80, 12)
# buildings: (kind, x, y, rot_deg, args for build_hanok [bays, depth, mode, floor])
BUILDINGS = [
    ("hall", 104, 27, -7, [5, 3]),                 # 대웅전
    ("hall", 82, 36, 20, [3, 1]),                  # 승방 (서)
    ("hall", 126, 38, -17, [3, 1]),                # 승방 (동)
    ("pavilion", 100, 54, 0, [3, 2, "pavilion", 5.6]),    # 만세루 (아래 통과)
    ("bell", 70, 70, 12, [1, 1, "gate"]),                 # 범종각
    ("pavilion", 31, 28, 14, [6, 4, "pavilion", 4.4, -1.6, 2.0]),   # 경회루 (B) on its stone island; railing open at the stair top
    ("hall", 92, 77, 6, [3, 2]),                   # 요사채
    ("hall", 106, 82, -9, [3, 2]),
    ("hall", 86, 86, 3, [2, 2]),
    ("gate", 64, 86.5, 0, [3, 1, "gate"]),         # 천왕문 (top of the first stairs)
    ("gate", 64, 106, 0, [1, 1, "gate"]),          # 일주문 (in line with the stairs)
    ("gate", 60, 22, 6, [5, 1, "gate"]),           # 수정전 회랑
    ("hall", 80, 14, 0, [3, 2]),                   # 산신각 (수비)
]
def inside(pt, poly):
    x, y = pt; c = False; n = len(poly)
    for i in range(n):
        x1, y1 = poly[i]; x2, y2 = poly[(i + 1) % n]
        if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1 + 1e-12) + x1: c = not c
    return c
