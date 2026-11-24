#!/usr/bin/env python3
"""Merge a Unity OBB expansion back into the APK -> one self-contained APK.

This game is a Unity "Split Application Binary" build: the APK ships only the
first scene and the rest lives in main.<vc>.<pkg>.obb. Copying every
`assets/*` entry from the OBB into the APK's `assets/*` gives Unity the full
data set inside the APK, so no separate OBB file is needed. The two never
collide (the split partitions the data).

Output is UNSIGNED and UNALIGNED — run tools/build/repack_sign.sh afterwards
(it strips any old signature, zipaligns, and signs). Use the signature-pinned
OBB (patch_obb_sig.py) so the merged APK's assets carry our cert hash.

NOTE: Unity still probes getObbDir() at launch; with all data in the APK it
should load from the APK and not require the OBB, but verify on a device.

Usage: merge_obb_into_apk.py <in.apk> <in.obb> <out.apk>
"""
import sys
import zipfile


def main():
    apk_path, obb_path, out_path = sys.argv[1:4]
    apk = zipfile.ZipFile(apk_path)
    obb = zipfile.ZipFile(obb_path)
    apk_names = set(apk.namelist())
    obb_assets = [i for i in obb.infolist() if i.filename.startswith("assets/")]
    collisions = [i.filename for i in obb_assets if i.filename in apk_names]
    if collisions:
        sys.exit(f"refusing: {len(collisions)} path collisions, e.g. {collisions[:5]}")

    added = 0
    with zipfile.ZipFile(out_path, "w") as out:
        # copy the APK verbatim (preserve each entry's compression)
        for info in apk.infolist():
            out.writestr(info, apk.read(info.filename), compress_type=info.compress_type)
        # append the OBB's assets at the same paths
        for info in obb_assets:
            out.writestr(info, obb.read(info.filename), compress_type=info.compress_type)
            added += 1
    apk.close()
    obb.close()
    print(f"merged {added} OBB asset entries into {out_path}")


if __name__ == "__main__":
    main()
