#!/usr/bin/env python3
"""Patch libil2cpp.so so the game talks to the embedded localhost server.

Wellgames.Data.GIJBACLFCAD(name) normally RSA-decrypts the server base URL
("http://fps.ss.nexon.com"). We overwrite its prologue so it ignores the
argument and returns il2cpp_string_new("http://127.0.0.1:<port>"), which both
HttpManager.cctor and SetDefaultUrl store as the base URL. No DNS, no server,
no internet — every web request then goes to the in-APK native server.

The patch is three AArch64 instructions written at the function entry, plus
the URL C-string placed just after them (inside the function body, which is
large enough and no longer executed past the tail-call):

    adr  x0, url            ; const char* url
    b    il2cpp_string_new  ; tail-call -> returns Il2CppString*
    url: "http://127.0.0.1:<port>\0"

Usage: patch_redirect.py <libil2cpp.so> <GIJBACLFCAD_rva_hex> <il2cpp_string_new_rva_hex> [port]
"""
import struct
import sys


def enc_adr(rd, rel):
    immlo = rel & 3
    immhi = (rel >> 2) & 0x7FFFF
    return 0x10000000 | (immlo << 29) | (immhi << 5) | rd


def enc_b(rel):
    assert rel % 4 == 0
    imm26 = (rel // 4) & 0x03FFFFFF
    return 0x14000000 | imm26


def main():
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    path, fn_hex, strnew_hex = sys.argv[1], sys.argv[2], sys.argv[3]
    port = int(sys.argv[4]) if len(sys.argv) > 4 else 42427
    fn = int(fn_hex, 16)
    strnew = int(strnew_hex, 16)
    url = ("http://127.0.0.1:%d" % port).encode() + b"\0"

    data = bytearray(open(path, "rb").read())
    # ELF RVA == file offset inside the first PT_LOAD (exec segment starts at 0).
    off = fn
    str_off = off + 8  # after adr(4) + b(4)
    adr = enc_adr(0, 8)                 # x0 <- pc+8 (the url bytes)
    b = enc_b(strnew - (fn + 4))        # tail-call il2cpp_string_new
    struct.pack_into("<II", data, off, adr, b)
    data[str_off:str_off + len(url)] = url

    open(path, "wb").write(data)
    print(f"patched {path}: GIJBACLFCAD@0x{fn:x} -> il2cpp_string_new(\"http://127.0.0.1:{port}\")")
    print(f"  adr=0x{adr:08x} b=0x{b:08x} url_off=0x{str_off:x} url={url!r}")


if __name__ == "__main__":
    main()
