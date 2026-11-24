#!/usr/bin/env python3
"""Direct-call graph for IL2CPP methods (arm64 BL instructions).

Usage:
  callers.py <libil2cpp.so> <dump_dir> callers <regex>   # who calls matching methods
  callers.py <libil2cpp.so> <dump_dir> callees <regex>   # what matching methods call

Only direct BL calls are seen; virtual/interface calls and delegates are not.
"""
import re
import struct
import sys
from bisect import bisect_right

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from il2cpp_dump import Elf  # noqa: E402
from xref_literals import load_methods  # noqa: E402


def calls(elf):
    vaddr, _, off, filesz = elf.loads[0]
    words = struct.unpack_from(f"<{filesz // 4}I", elf.d, off)
    for i, w in enumerate(words):
        if (w & 0xFC000000) == 0x94000000:  # BL imm26
            imm = w & 0x3FFFFFF
            if imm & (1 << 25):
                imm -= 1 << 26
            pc = vaddr + i * 4
            yield pc, pc + imm * 4


def main():
    if len(sys.argv) != 5 or sys.argv[3] not in ("callers", "callees"):
        sys.exit(__doc__)
    so, dump_dir, mode, pat = sys.argv[1:]
    rx = re.compile(pat)
    elf = Elf(so)
    starts, names = load_methods(dump_dir)
    start_set = dict(zip(starts, names))

    def owner(va):
        k = bisect_right(starts, va) - 1
        return names[k] if k >= 0 else "?"

    out = {}
    for pc, target in calls(elf):
        tname = start_set.get(target)
        if tname is None:
            continue
        if mode == "callers" and rx.search(tname):
            out.setdefault(tname, set()).add(owner(pc))
        elif mode == "callees":
            src = owner(pc)
            if rx.search(src):
                out.setdefault(src, []).append(tname)
    for k in sorted(out):
        print(k)
        v = sorted(out[k]) if mode == "callers" else list(dict.fromkeys(out[k]))
        for x in v:
            print("    " + x)


if __name__ == "__main__":
    main()
