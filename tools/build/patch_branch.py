#!/usr/bin/env python3
"""Make one AArch64 function tail-call another (b <to>) at its entry.

Used to skip a method and run a different one with the same `this`/args. e.g.
redirect U_Lobby_Loading.SocialLogin (the Google-login dance that crashes on a
re-signed APK) straight into ConnectPlatForm (the guest platform-connect that
talks to the embedded server).

Usage: patch_branch.py <lib.so> <from_rva_hex> <to_rva_hex>
"""
import struct
import sys


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    path, a, b = sys.argv[1], int(sys.argv[2], 16), int(sys.argv[3], 16)
    data = bytearray(open(path, "rb").read())
    rel = (b - a) // 4
    if not (-(1 << 25) <= rel < (1 << 25)):
        sys.exit("target out of range for a single B")
    struct.pack_into("<I", data, a, 0x14000000 | (rel & 0x03FFFFFF))
    open(path, "wb").write(data)
    print(f"0x{a:x} -> b 0x{b:x}")


if __name__ == "__main__":
    main()
