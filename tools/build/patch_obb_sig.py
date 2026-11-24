#!/usr/bin/env python3
"""Repin the APK signature hash stored in the OBB.

The game checks that the running APK's Java `Signature.hashCode()` matches a
value saved as a string in the `level2` scene (inside the OBB). After
re-signing with our own key we repin that string to OUR key's hash. OLD and
NEW must be the SAME length so the Unity asset layout is untouched (we pick a
keystore whose hash is 11 chars to match the original `-1916262714`).

Usage: patch_obb_sig.py <in.obb> <out.obb> <OLD> <NEW>
"""
import sys
import zipfile


def main():
    src, dst, old, new = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
    old_b, new_b = old.encode(), new.encode()
    if len(old_b) != len(new_b):
        sys.exit(f"OLD ({len(old_b)}) and NEW ({len(new_b)}) must be the same length")
    zin = zipfile.ZipFile(src)
    hits_total = 0
    patched_entries = []
    with zipfile.ZipFile(dst, "w") as zout:
        for info in zin.infolist():
            data = zin.read(info.filename)
            n = data.count(old_b)
            if n:
                data = data.replace(old_b, new_b)
                hits_total += n
                patched_entries.append((info.filename, n))
            zout.writestr(info, data, compress_type=info.compress_type)
    zin.close()
    for name, n in patched_entries:
        print(f"  {name}: {n} replacement(s)")
    if not hits_total:
        sys.exit(f"ERROR: {old!r} not found in {src}")
    print(f"total {hits_total} replacement(s) -> {dst}")


if __name__ == "__main__":
    main()
