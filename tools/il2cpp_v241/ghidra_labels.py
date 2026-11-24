#!/usr/bin/env python3
"""Write labels.tsv for tools/ghidra/DecompileIl2cpp.java.

Each line is: rva<TAB>kind<TAB>name<TAB>comment
  kind F  method entry point (Type$$Method)
  kind L  string-literal slot or the GOT entry that points at it

Usage: ghidra_labels.py <libil2cpp.so> <dump_dir> <labels.tsv>
"""
import csv
import re
import sys

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from il2cpp_dump import Elf  # noqa: E402

BAD = re.compile(r"[^A-Za-z0-9_$.<>`,\[\]]")


def clean(s):
    return BAD.sub("_", s)


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    so, dump_dir, out = sys.argv[1:]
    elf = Elf(so)
    seen = set()
    with open(out, "w", encoding="utf-8") as o:
        with open(f"{dump_dir}/methods.csv", encoding="utf-8") as fh:
            for r in csv.DictReader(fh):
                rva = int(r["rva"], 16)
                if rva in seen:
                    continue
                seen.add(rva)
                o.write(f"{rva:x}\tF\t{clean(r['type'] + '$$' + r['method'])}\t{r['signature']}\n")
        slots = {}
        with open(f"{dump_dir}/string_literals.csv", encoding="utf-8") as fh:
            for r in csv.DictReader(fh):
                if r["usage_slot_rva"]:
                    slots[int(r["usage_slot_rva"], 16)] = (int(r["index"]), r["value"])
        for rva, (i, val) in slots.items():
            short = val.replace("\t", " ").replace("\n", "\\n").replace("\r", "")[:200]
            o.write(f"{rva:x}\tL\tStringLiteral_{i}\t{short}\n")
        for got, target in elf.relocs.items():
            if target in slots:
                i, val = slots[target]
                short = val.replace("\t", " ").replace("\n", "\\n").replace("\r", "")[:200]
                o.write(f"{got:x}\tL\tGOT_StringLiteral_{i}\t{short}\n")


if __name__ == "__main__":
    main()
