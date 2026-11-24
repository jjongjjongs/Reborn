#!/usr/bin/env python3
"""Surgically remove Facebook auto-init <provider> elements from a binary
AndroidManifest.xml (AXML), so the native Facebook SDK never initializes.

The FB SDK auto-initializes from the manifest via content providers
(FacebookInitProvider / MarketingInitProvider) before any Unity/C# code runs,
and on a re-signed APK its app-settings Graph fetch fails (HTTP 400 for app id
1499779786990739, key-hash mismatch). Disabling the game's C# FacebookManager
does nothing because this init is native + manifest-driven. Removing the
provider elements stops it with no recompilation of resources.

Each targeted <provider> has no children, so its START_TAG chunk is immediately
followed by its END_TAG chunk; we splice both out and fix the file-header size.

Usage: strip_fb_manifest.py <in_AndroidManifest.xml> <out> [class1 class2 ...]
Defaults to the three Facebook providers.
"""
import struct
import sys

DEFAULT_TARGETS = [
    "com.facebook.internal.FacebookInitProvider",
    "com.facebook.marketing.internal.MarketingInitProvider",
    "com.facebook.FacebookContentProvider",
]

START_TAG = 0x0102
END_TAG = 0x0103
ATTR_SZ = 20


def strip_fb_providers(raw, targets=None, log=None):
    """Return AXML bytes with the targeted <provider> elements removed.

    raw: bytes/bytearray of a binary AndroidManifest.xml.
    Raises ValueError if it is not AXML or a provider has children.
    """
    targets = set(targets) if targets else set(DEFAULT_TARGETS)
    data = bytearray(raw)
    if data[0:4] != b"\x03\x00\x08\x00":
        raise ValueError("not an AXML file")

    def u16(o):
        return struct.unpack_from("<H", data, o)[0]

    def u32(o):
        return struct.unpack_from("<I", data, o)[0]

    # string pool
    sp_off = 8
    sp_size = u32(sp_off + 4)
    strcount = u32(sp_off + 8)
    flags = u32(sp_off + 16)
    strstart = u32(sp_off + 20)
    base = sp_off + strstart
    offs = [u32(sp_off + 28 + 4 * i) for i in range(strcount)]
    utf8 = (flags & 0x100) != 0

    def getstr(i):
        if i == 0xFFFFFFFF or i >= strcount:
            return None
        o = base + offs[i]
        if utf8:
            n = data[o]
            c = 2 if (n & 0x80) else 1
            o2 = o + c
            bl = data[o2]
            c2 = 2 if (bl & 0x80) else 1
            blen = bl if c2 == 1 else (((bl & 0x7F) << 8) | data[o2 + 1])
            o3 = o2 + c2
            return bytes(data[o3:o3 + blen]).decode("utf-8", "replace")
        n = u16(o)
        return bytes(data[o + 2:o + 2 + 2 * n]).decode("utf-16-le", "replace")

    strs = [getstr(i) for i in range(strcount)]

    # walk top-level chunks; collect [start,end) byte ranges to delete
    pos = sp_off + sp_size
    kill = []
    while pos < len(data):
        ctype = u16(pos)
        csize = u32(pos + 4)
        if ctype == START_TAG:
            name_i = u32(pos + 20)
            nm = strs[name_i] if name_i != 0xFFFFFFFF else None
            if nm == "provider":
                acount = u16(pos + 28)
                ao = pos + 36
                cls = None
                for _ in range(acount):
                    a_name = u32(ao + 4)
                    a_raw = u32(ao + 8)
                    if strs[a_name] if a_name != 0xFFFFFFFF else None:
                        if strs[a_name] == "name":
                            cls = strs[a_raw] if a_raw != 0xFFFFFFFF else None
                    ao += ATTR_SZ
                if cls in targets:
                    nxt = pos + csize
                    if u16(nxt) != END_TAG:
                        raise ValueError(f"provider {cls} has children; aborting")
                    end = nxt + u32(nxt + 4)
                    kill.append((pos, end, cls))
        pos += csize

    if not kill:
        raise ValueError("no targeted FB providers found")

    # splice from the end so earlier offsets stay valid
    for start, end, cls in sorted(kill, reverse=True):
        del data[start:end]
        if log:
            log(f"removed <provider> {cls} ({end - start} bytes)")

    # fix file header total size (u32 at offset 4)
    struct.pack_into("<I", data, 4, len(data))
    return bytes(data)


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    inp, outp = sys.argv[1], sys.argv[2]
    targets = sys.argv[3:] or None
    raw = open(inp, "rb").read()
    out = strip_fb_providers(raw, targets, log=lambda m: sys.stderr.write(m + "\n"))
    open(outp, "wb").write(out)
    print(f"stripped FB providers: {len(raw)} -> {len(out)} bytes")


if __name__ == "__main__":
    main()
