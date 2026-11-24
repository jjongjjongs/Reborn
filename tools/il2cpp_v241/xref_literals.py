#!/usr/bin/env python3
"""Find which IL2CPP methods load given string literals (arm64).

IL2CPP code reads a string literal from a global slot with
    ADRP xN, slot@PAGE ; LDR xM, [xN, slot@PAGEOFF]
(often via a GOT entry that holds the slot address). This scans .text for that pair, using the slots from string_literals.csv
written by il2cpp_dump.py, and maps each hit to the containing method from
methods.csv.

Usage: xref_literals.py <libil2cpp.so> <dump_dir> <regex> [<regex> ...]
"""
import csv
import re
import struct
import sys
from bisect import bisect_right

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from il2cpp_dump import Elf  # noqa: E402


def load_methods(dump_dir):
    rows = []
    with open(f"{dump_dir}/methods.csv", encoding="utf-8") as fh:
        for r in csv.DictReader(fh):
            rows.append((int(r["rva"], 16), r["type"] + "$$" + r["method"]))
    rows.sort()
    return [r[0] for r in rows], [r[1] for r in rows]


def scan(elf, slots):
    """Return {slot: [insn_va, ...]} for ADRP/LDR(64-bit) pairs hitting slots."""
    by_page = {}
    for s in slots:
        by_page.setdefault(s & ~0xFFF, set()).add(s)
    # executable segment is the first PT_LOAD
    vaddr, memsz, off, filesz = elf.loads[0]
    words = struct.unpack_from(f"<{filesz // 4}I", elf.d, off)
    hits = {s: [] for s in slots}
    n = len(words)
    for i, w in enumerate(words):
        if (w & 0x9F000000) != 0x90000000:
            continue
        pc = vaddr + i * 4
        immlo = (w >> 29) & 3
        immhi = (w >> 5) & 0x7FFFF
        imm = (immhi << 2) | immlo
        if imm & (1 << 20):
            imm -= 1 << 21
        page = (pc & ~0xFFF) + (imm << 12)
        targets = by_page.get(page)
        if not targets:
            continue
        rd = w & 0x1F
        for j in range(i + 1, min(i + 8, n)):
            w2 = words[j]
            if (w2 & 0xFFC00000) == 0xF9400000 and ((w2 >> 5) & 0x1F) == rd:
                addr = page + ((w2 >> 10) & 0xFFF) * 8
                if addr in targets:
                    hits[addr].append(vaddr + j * 4)
                break
    return hits


def main():
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    so, dump_dir, pats = sys.argv[1], sys.argv[2], [re.compile(p) for p in sys.argv[3:]]
    elf = Elf(so)
    lits = []
    with open(f"{dump_dir}/string_literals.csv", encoding="utf-8") as fh:
        for r in csv.DictReader(fh):
            if r["usage_slot_rva"] and any(p.search(r["value"]) for p in pats):
                lits.append((int(r["index"]), int(r["usage_slot_rva"], 16), r["value"]))
    starts, names = load_methods(dump_dir)
    # Code usually reaches the slot through a GOT entry holding its address.
    want = {s for _, s, _ in lits}
    via_got = {}
    for r, add in elf.relocs.items():
        if add in want:
            via_got[r] = add
    raw = scan(elf, want | set(via_got))
    hits = {s: list(raw.get(s, [])) for s in want}
    for got, s in via_got.items():
        hits[s].extend(raw.get(got, []))
    for idx, slot, val in lits:
        print(f"[{idx}] {val!r}  (slot 0x{slot:X})")
        for va in hits[slot]:
            k = bisect_right(starts, va) - 1
            fn = names[k] if k >= 0 else "?"
            print(f"    0x{va:X}  {fn}+0x{va - starts[k]:X}")


if __name__ == "__main__":
    main()
