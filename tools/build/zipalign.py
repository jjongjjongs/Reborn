#!/usr/bin/env python3
"""Pure-Python zipalign (no Android build-tools needed).

Aligns the on-disk data offset of every STORED (uncompressed) entry so the
app can mmap it directly, matching `zipalign -p 4` plus 4096-byte alignment
for uncompressed *.so. Compressed entries are copied verbatim. Run BEFORE
signing (alignment must not change after the signature is written).

Usage: zipalign.py <in.zip> <out.zip>
"""
import struct
import sys
import zipfile


def main():
    src, dst = sys.argv[1], sys.argv[2]
    zin = zipfile.ZipFile(src)
    with open(dst, "wb") as out:
        infos = zin.infolist()
        offsets = {}
        for info in infos:
            data = zin.read(info.filename)
            raw = _raw_member(zin, info)
            local_off = out.tell()
            # Build local file header; pad the extra field so DATA is aligned.
            name = info.filename.encode("utf-8")
            if info.compress_type == zipfile.ZIP_STORED:
                align = 4096 if info.filename.endswith(".so") else 4
            else:
                align = 1
            extra = info.extra or b""
            header_len = 30 + len(name) + len(extra)
            data_start = local_off + header_len
            pad = (-data_start) % align
            if pad:
                extra = extra + b"\0" * pad
            offsets[info.filename] = local_off
            out.write(_local_header(info, name, extra))
            out.write(raw)
            if info.flag_bits & 0x08:
                out.write(_data_descriptor(info))
        cd_start = out.tell()
        for info in infos:
            out.write(_central_header(info, offsets[info.filename]))
        cd_end = out.tell()
        out.write(_eocd(len(infos), cd_start, cd_end - cd_start))
    zin.close()
    print(f"aligned {len(infos)} entries -> {dst}")


def _raw_member(zin, info):
    """Return the raw (already-compressed) bytes of the member."""
    with zin.open(info, "r") as f:
        # ZipExtFile over the compressed bytes: re-read from the raw file instead.
        pass
    fp = zin.fp
    fp.seek(info.header_offset)
    sig, = struct.unpack("<I", fp.read(4))
    fp.seek(info.header_offset + 26)
    n, m = struct.unpack("<HH", fp.read(4))
    fp.seek(info.header_offset + 30 + n + m)
    return fp.read(info.compress_size)


def _local_header(info, name, extra):
    dt = info.date_time
    dosdate = (dt[0] - 1980) << 9 | dt[1] << 5 | dt[2]
    dostime = dt[3] << 11 | dt[4] << 5 | dt[5] // 2
    return struct.pack(
        "<IHHHHHIIIHH", 0x04034B50, info.extract_version, info.flag_bits,
        info.compress_type, dostime, dosdate, info.CRC,
        info.compress_size, info.file_size, len(name), len(extra)) + name + extra


def _data_descriptor(info):
    return struct.pack("<IIII", 0x08074B50, info.CRC, info.compress_size, info.file_size)


def _central_header(info, offset):
    name = info.filename.encode("utf-8")
    extra = info.extra or b""
    comment = (info.comment or b"")
    dt = info.date_time
    dosdate = (dt[0] - 1980) << 9 | dt[1] << 5 | dt[2]
    dostime = dt[3] << 11 | dt[4] << 5 | dt[5] // 2
    return struct.pack(
        "<IHHHHHHIIIHHHHHII", 0x02014B50, info.create_version, info.extract_version,
        info.flag_bits, info.compress_type, dostime, dosdate, info.CRC,
        info.compress_size, info.file_size, len(name), len(extra), len(comment),
        0, info.internal_attr, info.external_attr, offset) + name + extra + comment


def _eocd(count, cd_start, cd_size):
    return struct.pack("<IHHHHIIH", 0x06054B50, 0, 0, count, count, cd_size, cd_start, 0)


if __name__ == "__main__":
    main()
