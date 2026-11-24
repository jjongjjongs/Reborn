#!/usr/bin/env python3
"""Neutralize AArch64 functions in a .so by making them return immediately.

Used to disable the game's anti-tamper handlers that would otherwise kill the
app once it notices the embedded server library (e.g.
GameManager.OnInjectionDetected, which reports "INJECT DLL" and force-exits).
Writing `ret` at a void method's entry makes it a no-op; `--ret0` writes
`mov w0, #0; ret` for methods that must return 0/false.

Usage:
  patch_noop.py <lib.so> <rva_hex> [rva_hex ...]
  patch_noop.py <lib.so> --ret0 <rva_hex> [rva_hex ...]
"""
import struct
import sys

RET = 0xD65F03C0          # ret
MOV_W0_0 = 0x52800000     # mov w0, #0


def main():
    args = sys.argv[1:]
    if len(args) < 2:
        sys.exit(__doc__)
    path = args[0]
    ret0 = False
    rvas = []
    for a in args[1:]:
        if a == "--ret0":
            ret0 = True
        else:
            rvas.append(int(a, 16))
    data = bytearray(open(path, "rb").read())
    for rva in rvas:
        if ret0:
            struct.pack_into("<II", data, rva, MOV_W0_0, RET)
        else:
            struct.pack_into("<I", data, rva, RET)
        print(f"neutralized 0x{rva:x} ({'ret0' if ret0 else 'ret'})")
    open(path, "wb").write(data)


if __name__ == "__main__":
    main()
