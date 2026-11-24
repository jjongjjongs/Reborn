#!/usr/bin/env python3
"""Annotate Ghidra C output with decrypted obfuscated strings.

Ghidra loads libil2cpp.so at 0x100000, so a slot RVA from
decrypted_strings.csv appears in decompiled code as _DAT_<rva + 0x100000>.
This appends /* "decrypted" */ to every line that references one.

Usage: annotate_decrypted.py <decrypted_strings.csv> <file.c> [...]   (in place)
"""
import csv
import re
import sys

GHIDRA_BASE = 0x100000


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    table = {}
    with open(sys.argv[1], encoding="utf-8") as fh:
        for r in csv.DictReader(fh):
            for s in r["slot_rvas"].split():
                table[int(s, 16) + GHIDRA_BASE] = r["value"]
    rx = re.compile(r"DAT_([0-9a-f]{8})")
    for path in sys.argv[2:]:
        out = []
        with open(path, encoding="utf-8") as fh:
            for line in fh:
                line = line.rstrip("\n")
                vals = [table[int(m, 16)] for m in rx.findall(line) if int(m, 16) in table]
                if vals and "/* dec:" not in line:
                    line += "  /* dec: " + ", ".join(repr(v) for v in vals) + " */"
                out.append(line)
        with open(path, "w", encoding="utf-8") as fh:
            fh.write("\n".join(out) + "\n")


if __name__ == "__main__":
    main()
