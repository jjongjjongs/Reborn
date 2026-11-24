#!/usr/bin/env python3
"""Decrypt the RSA-obfuscated strings in Special Soldier's Assembly-CSharp.

The obfuscator stores protected strings as static byte arrays
(<PrivateImplementationDetails> RVA fields, InitializeArray'd at runtime) and
decrypts them with
<PrivateImplementationDetails>{F4B7C4DC-...}.NLNPLGOEHOB (see analysis/README.md):

  key   = 148-byte Windows PUBLICKEYBLOB ("RSA1", 1024-bit, e = 17);
          e = key[0x10..0x12] (little-endian), n = key[0x14:0x94] little-endian
  plain = for each 128-byte block c: m = int.from_bytes(c, "big") ** e mod n,
          big-endian bytes, leading zeros stripped, UTF-8; blocks concatenated
  (the *(bytes, true) overloads then drop the first two characters)

Usage:
  decrypt_strings.py <libil2cpp.so> <global-metadata.dat> <out.csv> [slot_rva ...]

Writes every RVA array in the image that decrypts to printable UTF-8, with the
metadata-usage slot(s) code reads it from. Pass slot RVAs (Ghidra addresses
minus its 0x100000 ELF base) to print just those.
"""
import csv
import struct
import sys

sys.path.insert(0, __file__.rsplit("/", 1)[0])
import il2cpp_dump as D  # noqa: E402

KEY_TYPE_SIZE = 0x94
BLOCK = 0x80


def field_blobs(md, namer):
    """Return {global_field_index: (owner_name, field_name, bytes)} for RVA array fields."""
    o, n = md.sec["fieldAndParameterDefaultValueData"]
    blob_base = o
    owner_of = {}
    for ti, t in enumerate(md.types):
        for k in range(t[D.T_FCOUNT]):
            owner_of[t[D.T_FIELD] + k] = ti
    out = {}
    for fidx, type_index, data_index in md.field_defaults:
        if data_index < 0:
            continue
        vt = namer.type_index_to_typedef(type_index)
        if vt is None or "<PrivateImplementationDetails>" not in namer.typedef_name(vt):
            continue
        size = value_type_size(namer, vt)
        if not size:
            continue
        data = md.d[blob_base + data_index: blob_base + data_index + size]
        ti = owner_of.get(fidx)
        out[fidx] = (namer.typedef_name(ti) if ti is not None else "?", md.s(md.fields[fidx][0]), data)
    return out


def value_type_size(namer, ti):
    """Byte size of a value type from MetadataRegistration.typeDefinitionsSizes."""
    elf = namer.elf
    sizes = elf.ptr(namer.mreg + 13 * 8)
    entry = elf.ptr(sizes + 8 * ti)
    if not entry:
        return None
    instance_size = elf.u32(entry)
    return instance_size - 0x10 if instance_size and instance_size > 0x10 else None


def field_slots(md, elf, namer):
    """Map metadata-usage slot RVA -> global field index for FieldInfo usages."""
    o, n = md.sec["fieldRefs"]
    refs = [struct.unpack_from("<ii", md.d, o + i * 8) for i in range(n // 8)]
    n_usages = max(namer.metadata_usages_count, max(p[0] for p in md.usage_pairs) + 1)
    usages = elf.ptr_array(namer.metadata_usages_ptr, n_usages)
    slots = {}
    for dest, enc in md.usage_pairs:
        if (enc >> 29) != 4:  # kIl2CppMetadataUsageFieldInfo
            continue
        type_index, field_local = refs[enc & 0x1FFFFFFF]
        ti = namer.type_index_to_typedef(type_index)
        if ti is None:
            continue
        slots[usages[dest]] = md.types[ti][D.T_FIELD] + field_local
    return slots


def make_decryptor(key):
    e = key[0x10] | key[0x11] << 8 | key[0x12] << 16
    n = int.from_bytes(key[0x14:0x14 + BLOCK], "little")

    def decrypt(data):
        # the blob type is padded (e.g. 131 bytes for a 128-byte array)
        data = data[:len(data) // BLOCK * BLOCK]
        if not data:
            return None
        parts = []
        for i in range(0, len(data), BLOCK):
            c = int.from_bytes(data[i:i + BLOCK], "big")
            m = pow(c, e, n)
            b = m.to_bytes((m.bit_length() + 7) // 8, "big")
            try:
                parts.append(b.decode("utf-8"))
            except UnicodeDecodeError:
                return None
        s = "".join(parts)
        return s if s and all(ch.isprintable() or ch in "\r\n\t" for ch in s) else None

    return decrypt


def main():
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    so, meta, out = sys.argv[1:4]
    wanted = [int(x, 16) for x in sys.argv[4:]]
    md = D.Metadata(meta)
    elf = D.Elf(so)
    namer = D.Namer(elf, md, D.locate_metadata_registration(elf, md))
    blobs = field_blobs(md, namer)
    slots = field_slots(md, elf, namer)
    slots_of = {}
    for s, f in slots.items():
        slots_of.setdefault(f, []).append(s)

    # the key is a Windows PUBLICKEYBLOB ("RSA1" at offset 8)
    keys = [f for f, (_, _, b) in blobs.items() if len(b) >= KEY_TYPE_SIZE and b[8:12] == b"RSA1"]
    results = []
    for kf in keys:
        dec = make_decryptor(blobs[kf][2])
        hits = []
        for f, (owner, name, data) in blobs.items():
            s = dec(data)
            if s is not None:
                hits.append((f, owner, name, s))
        if len(hits) > len(results):
            results, key_field = hits, kf
    if not results:
        sys.exit("no key decrypted anything")
    print(f"key field #{key_field} ({blobs[key_field][1]}), decrypted {len(results)} strings")

    with open(out, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["field_index", "slot_rvas", "value"])
        for f, owner, name, s in sorted(results):
            w.writerow([f, " ".join(f"0x{x:X}" for x in sorted(slots_of.get(f, []))), s])
    by_slot = {s: v for f, _, _, v in results for s in slots_of.get(f, [])}
    for s in wanted:
        print(f"0x{s:X}: {by_slot.get(s)!r}")


if __name__ == "__main__":
    main()
