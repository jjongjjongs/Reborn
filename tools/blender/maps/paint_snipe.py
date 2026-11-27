# 스나전 map "협곡 전초기지 / CANYON OUTPOST" (original), 2 m per char, west half drawn + mirrored.
# Built from how sniper-only maps work (awp_ style yards, Halo sniper perches, Gears flank rules):
#  - each side: a 3.2 m sniper balcony over its spawn with barrier cover and an underpass below it
#  - no spawn-to-spawn sight line: a ruined tower in the middle splits the map
#  - three lanes of different range: NORTH = long open alley under a 2.4 m cliff ridge (pure long range),
#    MID = dunes (1.2 m, jumpable) + containers (medium range, peek and reposition),
#    SOUTH = ruined houses with a tunnel underneath (close-range flank to the enemy balcony)
#  - every power spot (ridge, balcony, watchtower) has two ways up and can be seen from somewhere else
#   python3 maps/paint_snipe.py ; python3 ascii_plan.py maps/snipe.txt ; python3 maps/scale_plan.py snipe 1.2
import os
HERE = os.path.dirname(os.path.abspath(__file__))
W, H = 44, 30
MIRROR = {"<": ">", ">": "<", "a": "d", "d": "a"}
g = [["#"] * W for _ in range(H)]
def r(x0, y0, x1, y1, c):
    for y in range(y0, y1):
        for x in range(x0, x1): g[y][x] = c
def p(*pts, c="p"):
    for x, y in pts: g[y][x] = c
# ---- west base: spawn yard, balcony (8 = 3.2 m) with stairs at both ends, underpass (h) in the middle
r(1, 10, 4, 20, "a")
r(4, 7, 5, 23, ".")                                   # service lane behind the balcony
r(5, 8, 9, 22, "8")                                   # sniper balcony
r(5, 6, 9, 8, "v")                                    # stairs up from the north alley
r(5, 13, 9, 17, "h")                                  # underpass through the balcony (walk under at 0)
r(4, 13, 5, 17, ".")
p((8, 9), (8, 12), (8, 17), c="k")                    # barrier cover along the balcony edge
# ---- NORTH lane: long alley + cliff ridge (6 = 2.4 m) along the edge
r(4, 3, 22, 7, ".")
r(4, 1, 22, 3, "6"); r(9, 3, 11, 4, "^"); r(17, 3, 19, 4, "^")    # ridge + two climbs
p((12, 5), (16, 4), c="x"); p((20, 5), c="X")                      # sparse low cover (long range)
p((10, 1), (15, 2), (21, 1), c="k")                                 # ridge parapet bits
# ---- MID field: sand plaza with dunes (3 = 1.2 m) and containers
r(9, 7, 22, 23, ",")
r(11, 9, 14, 11, "3"); r(10, 16, 13, 18, "3"); r(15, 12, 17, 15, "3"); r(17, 19, 20, 21, "3")
r(13, 7, 15, 8, "c"); r(18, 9, 20, 10, "C"); r(13, 20, 15, 21, "c"); r(10, 13, 11, 15, "c")
p((16, 17), (12, 12), (19, 16), c="x"); p((17, 11), c="k")
r(9, 19, 10, 21, "<")                                 # exposed stairs from the field up the balcony (attack route)
# ---- centre: ruined tower (mass) splitting the long middle sight line, a room at its foot
r(20, 11, 22, 19, "#"); r(20, 13, 22, 17, "o"); r(19, 14, 20, 16, "o")   # room with a west door (east by mirror)
# ---- watchtower on the south-west of mid (8) with stairs
r(14, 21, 17, 23, "8"); r(17, 21, 18, 23, "<")
# ---- SOUTH: ruined houses with a tunnel underneath (t = -3) + back street
r(4, 23, 22, 27, "#")
r(9, 24, 22, 26, "t"); r(7, 24, 9, 26, "<"); r(5, 24, 7, 26, ".")   # tunnel + ramp down from the lane
r(4, 27, 22, 29, ".")                                                # back street
p((9, 28), (15, 27), c="x"); p((12, 28), c="b"); p((7, 27), c="T"); p((18, 28), c="L")
r(4, 22, 7, 27, ".")                                                # lane bends down to the back street
# props / ffa spawns / mid marker
p((6, 4), (14, 1), c="L"); p((10, 20), (18, 8), c="T"); p((5, 25), c="b")
p((6, 4), (11, 8), (18, 13), (5, 28), (14, 27), (20, 4), (12, 22))
g[8][21] = "m"
# mirror the west half onto the east
for y in range(H):
    for x in range(W // 2):
        g[y][W - 1 - x] = MIRROR.get(g[y][x], g[y][x])
for y in (0, H - 1):
    for x in range(W): g[y][x] = "#"
for y in range(H): g[y][0] = g[y][W - 1] = "#"
txt = "name: snipe\ntheme: desert\nmode: dm\n---\n" + "\n".join("".join(row) for row in g) + "\n"
open(os.path.join(HERE, "snipe.txt"), "w").write(txt)
print(txt)
