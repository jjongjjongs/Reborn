# v3 deathmatch / team deathmatch layouts (mockup): three lanes instead of one open middle.
#   north lane / mid / south lane, each with its own character, crossed by alleys at 1/3 and 2/3,
#   so a fight can happen anywhere and every area has two ways out. Drawn as the west half and
#   mirrored (fair for teams). Writes maps/<name>_v3.txt; ascii_plan.py turns them into plans.
#   python3 maps/paint_v3.py
import os
HERE = os.path.dirname(os.path.abspath(__file__))
W, H = 34, 28
MIRROR = {"<": ">", ">": "<", "a": "d", "d": "a"}

class Canvas:
    def __init__(s): s.g = [["#"] * W for _ in range(H)]
    def r(s, x0, y0, x1, y1, c):
        for y in range(max(0, y0), min(H, y1)):
            for x in range(max(0, x0), min(W, x1)): s.g[y][x] = c
        return s
    def p(s, *pts, c="p"):
        for x, y in pts: s.g[y][x] = c
        return s
    def mirror(s):
        for y in range(H):
            for x in range(17):
                s.g[y][W - 1 - x] = MIRROR.get(s.g[y][x], s.g[y][x])
        # cars are 2 chars long: keep them off the mirror line
        return s
    def save(s, name, theme):
        for y in (0, H - 1):
            for x in range(W): s.g[y][x] = "#"
        for y in range(H): s.g[y][0] = s.g[y][W - 1] = "#"
        txt = "name: %s\ntheme: %s\nmode: dm\n---\n" % (name, theme) + "\n".join("".join(r) for r in s.g) + "\n"
        open(os.path.join(HERE, name + ".txt"), "w").write(txt)
        return txt

def base(c):
    c.r(1, 10, 5, 18, ",").r(1, 12, 3, 16, "a")              # team base (west; mirrored = blue)

out = {}
# ------------------------------------------------------------------ 다운타운 v3
# north: street + a 3.2 m parking deck along the edge (sniper lane, drop down onto the street)
# mid: an indoor lobby with 4 doors (close quarters, no long sight line through the centre)
# south: a subway tunnel under the block + a back street behind it
c = Canvas(); base(c)
c.r(3, 3, 5, 10, ".").r(5, 3, 17, 5, ".")                    # north street
c.r(3, 1, 5, 3, ".").r(5, 1, 7, 3, ">").r(7, 1, 17, 3, "8")   # deck + stairs
c.r(7, 9, 11, 19, ",").r(5, 12, 7, 16, ".")                  # west court
c.r(9, 5, 11, 9, ".")                                        # court -> north street
c.r(12, 10, 17, 18, "o").r(11, 13, 12, 15, "o").r(15, 9, 17, 10, "o").r(15, 18, 17, 19, "o")   # lobby + doors
c.r(15, 5, 17, 9, ".")                                        # lobby -> north street
c.p((14, 12), (14, 15), c="X")                               # pillars
c.r(15, 19, 17, 22, "^").r(12, 22, 17, 24, "t")              # lobby -> stairs down -> tunnel
c.r(7, 22, 9, 24, ".").r(9, 22, 12, 24, "<")                 # tunnel ramp up to the west landing
c.r(3, 18, 5, 26, ".").r(5, 24, 17, 26, ".").r(7, 24, 9, 25, ".")   # back street
c.p((8, 11), (9, 16), (6, 25), c="x").p((10, 13), c="k")
c.p((4, 4), (12, 25), (9, 4), c="L").p((6, 11), c="T").p((7, 3), (11, 25), c="V").p((3, 20), c="b")
c.p((4, 7), (12, 3), (8, 13), (14, 16), (10, 1), (4, 22), (13, 25), (16, 6))
c.mirror(); out["downtown_v3"] = c.save("downtown_v3", "city")

# ------------------------------------------------------------------ 사막 시장 v3
# north: a long covered souk (indoor lane with stalls); mid: small fountain square ringed by two
# roof terraces (power spots, reachable by stairs, exposed); south: canal you can wade + quays
c = Canvas(); base(c)
c.r(3, 3, 6, 10, ".").r(6, 3, 17, 6, "o")                    # souk hall
c.p((8, 4), (11, 4), (14, 4), c="x")                          # stalls
c.r(9, 6, 11, 9, "o").r(9, 8, 11, 10, ".")                   # souk side door -> alley
c.r(15, 6, 17, 10, ".")                                      # souk -> square
c.r(5, 10, 9, 18, ",").r(5, 12, 12, 16, ".")                 # west court + street to the square
c.r(12, 10, 17, 18, ",").r(16, 13, 17, 15, "k")              # fountain square (fountain in the middle)
c.r(9, 9, 12, 12, "8").r(9, 12, 11, 14, "^")                 # roof terrace over the square + stairs
c.r(15, 18, 17, 20, ".")                                      # square -> canal
c.r(3, 17, 5, 25, ".").r(5, 20, 17, 21, ".").r(5, 21, 17, 23, "w").r(5, 23, 17, 25, ".")   # quays + canal
c.p((13, 11), (13, 16), (7, 24), c="x").p((6, 14), (10, 20), c="b").p((7, 10), (12, 24), c="T").p((4, 5), (8, 20), c="L")
c.p((4, 7), (12, 4), (7, 13), (14, 12), (10, 10), (4, 21), (12, 23), (16, 8))
c.mirror(); out["bazaar_v3"] = c.save("bazaar_v3", "desert")

# ------------------------------------------------------------------ 교도소 v3
# north: cell corridor (indoor, cells as side pockets); mid: exercise yard with a guard tower in the
# centre (high ground everyone can see); west/east: canteen as an indoor flank; south: escape tunnel
c = Canvas(); base(c)
c.r(3, 3, 6, 10, ".").r(6, 2, 17, 5, "o")                    # cell corridor
for x in (7, 11, 15): c.r(x, 5, x + 2, 7, "o")               # cells off the corridor
c.r(13, 7, 15, 9, "o").r(13, 8, 15, 10, ".")                 # corridor -> yard door
c.r(5, 10, 9, 18, "o").r(4, 13, 5, 15, "o").r(9, 12, 10, 14, "o")   # canteen (indoor flank)
c.p((6, 12), (7, 15), c="k")                                  # tables
c.r(10, 9, 17, 19, ",")                                       # yard
c.r(15, 12, 17, 16, "8").r(13, 13, 15, 15, ">")              # guard tower + stairs
c.p((11, 10), (12, 17), c="X").p((11, 14), c="k")
c.r(15, 19, 17, 22, "^").r(9, 22, 17, 24, "t").r(6, 22, 9, 24, "<").r(5, 22, 6, 24, ".")   # yard -> tunnel
c.r(3, 18, 5, 26, ".").r(5, 24, 17, 26, ".")                 # outer service road
c.p((4, 4), (10, 25), c="L").p((6, 25), (14, 25), c="b")
c.p((4, 7), (10, 3), (7, 16), (12, 12), (11, 18), (4, 23), (13, 25), (16, 10))
c.mirror(); out["cell_v3"] = c.save("cell_v3", "prison")

# ------------------------------------------------------------------ 컨테이너 항구 v3
# north: warehouse hall (indoor, containers inside); mid: container yard with stacks that cut
# the long sight lines; south: pier with a crane platform over the quay
c = Canvas(); base(c)
c.r(3, 3, 5, 10, ".").r(5, 4, 6, 6, "o").r(6, 2, 17, 7, "o")   # warehouse
c.p((8, 3), (8, 5), (12, 4), c="c")
c.r(10, 7, 12, 9, "o").r(15, 7, 17, 9, "o")                   # warehouse -> yard doors
c.r(5, 9, 17, 20, ",").r(5, 12, 6, 16, ",")                  # container yard
c.r(8, 10, 10, 12, "C").r(12, 13, 14, 15, "C").r(8, 15, 10, 17, "c").r(15, 10, 17, 11, "c").r(14, 17, 16, 18, "c")
c.p((11, 11), (7, 13), (13, 18), c="x").p((10, 16), c="X")
c.r(3, 18, 5, 23, ".").r(3, 20, 17, 23, ".")                 # quay
c.r(13, 19, 17, 20, ".").r(14, 20, 17, 22, "8").r(12, 20, 14, 22, ">")   # crane platform + stairs
c.r(1, 23, 17, 27, "w").r(6, 23, 8, 26, ".")                 # water + a short jetty
c.p((4, 4), (9, 21), c="L").p((5, 21), (11, 21), c="b").p((6, 20), c="V")
c.p((4, 7), (10, 3), (7, 11), (12, 16), (11, 9), (4, 21), (7, 24), (16, 13))
c.mirror(); out["harbor_v3"] = c.save("harbor_v3", "harbor")

if __name__ == "__main__":
    for k, v in out.items(): print(k); print(v)
