#!/usr/bin/env python3
"""Patch versionCode / versionName in a binary AndroidManifest.xml.

Edits the compiled AXML in place inside an APK zip without apktool. Only
changes the two <manifest> attributes so Android treats a later build as an
update (same package + same signing key + higher versionCode).

versionName must not be longer than the current value (the AXML string pool
is fixed-width); versionCode is a plain 32-bit int attribute.

Usage: set_version.py <apk> <versionCode:int> [versionName]
"""
import struct
import sys
import zipfile
import shutil
import os

ANDROID_URI = "http://schemas.android.com/apk/res/android"


def parse_axml(data):
    # Header: 0x0003 type, then string pool chunk.
    assert struct.unpack_from("<H", data, 0)[0] == 0x0003, "not AXML"
    off = 8
    assert struct.unpack_from("<H", data, off)[0] == 0x0001, "no string pool"
    sp_size = struct.unpack_from("<I", data, off + 4)[0]
    string_count = struct.unpack_from("<I", data, off + 8)[0]
    flags = struct.unpack_from("<I", data, off + 16)[0]
    strings_start = struct.unpack_from("<I", data, off + 20)[0]
    is_utf8 = bool(flags & 0x100)
    offsets = [struct.unpack_from("<I", data, off + 28 + 4 * i)[0] for i in range(string_count)]
    base = off + strings_start
    strings = []
    for o in offsets:
        p = base + o
        if is_utf8:
            # u16 char len (maybe 2 bytes), u16 byte len
            n = data[p]
            p += 2 if n & 0x80 else 1
            blen = data[p]
            p += 2 if blen & 0x80 else 1
            strings.append(data[p:p + blen].decode("utf-8", "replace"))
        else:
            n = struct.unpack_from("<H", data, p)[0]
            strings.append(data[p + 2:p + 2 + n * 2].decode("utf-16-le", "replace"))
    return off, sp_size, strings, is_utf8


def patch(data, version_code, version_name):
    off, sp_size, strings, is_utf8 = parse_axml(data)
    data = bytearray(data)
    res_start = off + sp_size
    # Resource map chunk (type 0x0180) optional, then XML tag chunks.
    try:
        vc_idx = strings.index("versionCode")
    except ValueError:
        sys.exit("versionCode string not in pool")
    vn_idx = strings.index("versionName") if "versionName" in strings else -1
    pos = res_start
    changed = []
    while pos < len(data):
        ctype, hsize, csize = struct.unpack_from("<HHI", data, pos)
        if csize == 0:
            break
        if ctype == 0x0102:  # START_ELEMENT
            attr_start = pos + 36
            attr_count = struct.unpack_from("<H", data, pos + 28)[0]
            for a in range(attr_count):
                ao = attr_start + a * 20
                name_idx = struct.unpack_from("<i", data, ao + 4)[0]
                val_type = data[ao + 15]
                if name_idx == vc_idx and val_type == 0x10:  # INT_DEC
                    struct.pack_into("<i", data, ao + 8, version_code)   # typed resource value
                    struct.pack_into("<i", data, ao + 16, version_code)  # data
                    changed.append("versionCode=%d" % version_code)
                if version_name and name_idx == vn_idx and val_type == 0x03:  # STRING
                    str_ref = struct.unpack_from("<i", data, ao + 16)[0]
                    _set_pool_string(data, off, str_ref, version_name, is_utf8)
                    changed.append("versionName=%s" % version_name)
        pos += csize
    if not changed:
        sys.exit("nothing patched (attributes not found)")
    return bytes(data), changed


def _set_pool_string(data, sp_off, idx, new, is_utf8):
    string_count = struct.unpack_from("<I", data, sp_off + 8)[0]
    strings_start = struct.unpack_from("<I", data, sp_off + 20)[0]
    o = struct.unpack_from("<I", data, sp_off + 28 + 4 * idx)[0]
    p = sp_off + 8 + strings_start + o
    if is_utf8:
        clen = data[p]; q = p + (2 if clen & 0x80 else 1)
        blen = data[q]; q += (2 if blen & 0x80 else 1)
        old = blen
        nb = new.encode("utf-8")
        if len(nb) > old:
            sys.exit("new versionName longer than existing; pick a shorter string")
        data[q:q + len(nb)] = nb
        data[q + len(nb):q + old] = b"\0" * (old - len(nb))
    else:
        n = struct.unpack_from("<H", data, p)[0]
        nb = new.encode("utf-16-le")
        if len(new) > n:
            sys.exit("new versionName longer than existing; pick a shorter string")
        data[p + 2:p + 2 + len(nb)] = nb


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    apk, vc = sys.argv[1], int(sys.argv[2])
    vn = sys.argv[3] if len(sys.argv) > 3 else None
    z = zipfile.ZipFile(apk)
    axml = z.read("AndroidManifest.xml")
    z.close()
    new_axml, changed = patch(axml, vc, vn)
    tmp = apk + ".tmp"
    with zipfile.ZipFile(apk) as zin, zipfile.ZipFile(tmp, "w") as zout:
        for info in zin.infolist():
            data = new_axml if info.filename == "AndroidManifest.xml" else zin.read(info.filename)
            zout.writestr(info, data, compress_type=info.compress_type)
    os.replace(tmp, apk)
    print("patched:", ", ".join(changed))


if __name__ == "__main__":
    main()
