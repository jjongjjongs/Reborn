#!/usr/bin/env python3
"""Assemble the self-contained embedded-server APK.

Takes the shipped APK + OBB, the redirect-patched arm64 libil2cpp.so, and the
compiled libreborn.so, and produces one UNSIGNED APK that:
  - loads libreborn.so (the in-APK localhost server) via libil2cpp's DT_NEEDED
    (added with patchelf before this runs),
  - sends the game's web requests to 127.0.0.1 (the redirect patch),
  - contains all scene data (OBB merged in) so no OBB file is needed,
  - ships arm64-v8a only (the embedded patches target arm64).

Run tools/build/repack_sign.sh on the output to align + sign.

Usage:
  build_embedded.py <in.apk> <in.obb> <patched_libil2cpp_arm64.so> <libreborn_arm64.so> <out.apk>
"""
import sys
import zipfile


def main():
    apk_path, obb_path, il2cpp_path, reborn_path, out_path = sys.argv[1:6]
    apk = zipfile.ZipFile(apk_path)
    obb = zipfile.ZipFile(obb_path)
    il2cpp = open(il2cpp_path, "rb").read()
    reborn = open(reborn_path, "rb").read()

    apk_names = set(apk.namelist())
    obb_assets = [i for i in obb.infolist() if i.filename.startswith("assets/")]
    collisions = [i.filename for i in obb_assets if i.filename in apk_names]
    if collisions:
        sys.exit(f"OBB/APK collision: {collisions[:5]}")

    IL2CPP = "lib/arm64-v8a/libil2cpp.so"
    REBORN = "lib/arm64-v8a/libreborn.so"
    dropped = added = 0
    with zipfile.ZipFile(out_path, "w") as out:
        for info in apk.infolist():
            name = info.filename
            if name.startswith("lib/armeabi-v7a/"):
                dropped += 1
                continue  # arm64-only build
            if name == IL2CPP:
                out.writestr(info, il2cpp, compress_type=info.compress_type)
                continue
            out.writestr(info, apk.read(name), compress_type=info.compress_type)
        # add the embedded server lib (stored, so it mmaps cleanly)
        ri = zipfile.ZipInfo(REBORN)
        ri.compress_type = zipfile.ZIP_STORED
        ri.external_attr = 0o644 << 16
        out.writestr(ri, reborn)
        # merge the OBB scene data
        for info in obb_assets:
            out.writestr(info, obb.read(info.filename), compress_type=info.compress_type)
            added += 1
    apk.close()
    obb.close()
    print(f"embedded APK: replaced {IL2CPP}, added {REBORN}, merged {added} OBB assets, "
          f"dropped {dropped} armeabi-v7a entries -> {out_path}")


if __name__ == "__main__":
    main()
