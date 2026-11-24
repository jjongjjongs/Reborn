#!/usr/bin/env python3
"""IL2CPP metadata v24.1 (Unity 2018.3) dumper for arm64 ELF libil2cpp.so.

REA's inspect-il2cpp-metadata only supports the 264-byte v24 header used by
Unity 2019.4; Unity 2018.3 writes v24.1 with a 272-byte header and different
record layouts. This script reads both files without executing anything and
writes:

  dump.cs            C#-like listing of every type, field (with offset) and
                     method (with RVA)
  methods.csv        rva,type,method,signature for every method with code
  string_literals.csv index,usage_slot_rva,value  (string literal -> global
                     slot that code loads it from; xref the slot in Ghidra)
  ghidra_names.py    Ghidra script that names functions and string slots

Usage: il2cpp_dump.py <libil2cpp.so> <global-metadata.dat> <out_dir>
"""
import csv
import os
import struct
import sys
from bisect import bisect_right

# ---------------------------------------------------------------- metadata

HEADER_SECTIONS = (
    "stringLiteral stringLiteralData string events properties methods "
    "parameterDefaultValues fieldDefaultValues fieldAndParameterDefaultValueData "
    "fieldMarshaledSizes parameters fields genericParameters "
    "genericParameterConstraints genericContainers nestedTypes interfaces "
    "vtableMethods interfaceOffsets typeDefinitions rgctxEntries images "
    "assemblies metadataUsageLists metadataUsagePairs fieldRefs "
    "referencedAssemblies attributesInfo attributeTypes "
    "unresolvedVirtualCallParameterTypes unresolvedVirtualCallParameterRanges "
    "windowsRuntimeTypeNames exportedTypeDefinitions"
).split()

# v24.1 record layouts (customAttributeIndex removed, rgctx/methodIndex kept)
TYPEDEF = struct.Struct("<19i8HII")       # 100 bytes
METHODDEF = struct.Struct("<10iI4H")      # 52 bytes
FIELDDEF = struct.Struct("<iiI")          # 12
PARAMDEF = struct.Struct("<iIi")          # 12
PROPDEF = struct.Struct("<iiiII")         # 20
IMAGEDEF = struct.Struct("<10i")          # 40 (v24.1 adds customAttribute range)
GENCONTAINER = struct.Struct("<iiii")     # ownerIndex,type_argc,is_method,genericParameterStart
USAGELIST = struct.Struct("<II")
USAGEPAIR = struct.Struct("<II")
FIELDDEFVAL = struct.Struct("<iii")


class Metadata:
    def __init__(self, path):
        self.d = open(path, "rb").read()
        magic, ver = struct.unpack_from("<Ii", self.d, 0)
        if magic != 0xFAB11BAF:
            sys.exit("not a global-metadata.dat")
        vals = struct.unpack_from("<66I", self.d, 8)
        self.sec = {n: (vals[2 * i], vals[2 * i + 1]) for i, n in enumerate(HEADER_SECTIONS)}
        if ver != 24 or self.sec["stringLiteral"][0] != 272:
            sys.exit(f"expected v24.1 (272-byte header), got version {ver}")
        self.types = self._table("typeDefinitions", TYPEDEF)
        self.methods = self._table("methods", METHODDEF)
        self.fields = self._table("fields", FIELDDEF)
        self.params = self._table("parameters", PARAMDEF)
        self.props = self._table("properties", PROPDEF)
        self.images = self._table("images", IMAGEDEF)
        self.gcontainers = self._table("genericContainers", GENCONTAINER)
        self.gparams = self._table("genericParameters", struct.Struct("<iihhHH"))  # 16 bytes
        self.usage_lists = self._table("metadataUsageLists", USAGELIST)
        self.usage_pairs = self._table("metadataUsagePairs", USAGEPAIR)
        self.field_defaults = self._table("fieldDefaultValues", FIELDDEFVAL)
        o, n = self.sec["nestedTypes"]
        self.nested = struct.unpack_from(f"<{n // 4}i", self.d, o)
        self._str_off = self.sec["string"][0]

    def _table(self, name, st):
        o, n = self.sec[name]
        if n % st.size:
            sys.exit(f"{name}: size {n} not a multiple of {st.size}")
        return [st.unpack_from(self.d, o + i * st.size) for i in range(n // st.size)]

    def s(self, idx):
        o = self._str_off + idx
        return self.d[o:self.d.index(b"\0", o)].decode("utf-8", "replace")

    def literal(self, i):
        lo = self.sec["stringLiteral"][0]
        ln, idx = struct.unpack_from("<II", self.d, lo + i * 8)
        o = self.sec["stringLiteralData"][0] + idx
        return self.d[o:o + ln].decode("utf-8", "replace")

    @property
    def literal_count(self):
        return self.sec["stringLiteral"][1] // 8


# TypeDefinition field indices
T_NAME, T_NS, T_BYVAL, T_BYREF, T_DECL, T_PARENT, T_ELEM, T_RGS, T_RGC, T_GC, \
    T_FLAGS, T_FIELD, T_METHOD, T_EVENT, T_PROP, T_NESTED, T_IFACE, T_VT, T_IOFF, \
    T_MCOUNT, T_PCOUNT, T_FCOUNT, T_ECOUNT, T_NCOUNT, T_VTCOUNT, T_ICOUNT, T_IOCOUNT, \
    T_BITS, T_TOKEN = range(29)
# MethodDefinition field indices
M_NAME, M_DECL, M_RET, M_PARAM, M_GC, M_INDEX, M_INVOKER, M_DELEG, M_RGS, M_RGC, \
    M_TOKEN, M_FLAGS, M_IFLAGS, M_SLOT, M_PCOUNT = range(15)

# ---------------------------------------------------------------- ELF


class Elf:
    def __init__(self, path):
        self.d = open(path, "rb").read()
        if self.d[:4] != b"\x7fELF" or self.d[4] != 2 or struct.unpack_from("<H", self.d, 18)[0] != 183:
            sys.exit("expected a 64-bit arm64 ELF")
        phoff, = struct.unpack_from("<Q", self.d, 32)
        phentsize, phnum = struct.unpack_from("<HH", self.d, 54)
        self.loads = []
        dyn = None
        for i in range(phnum):
            p_type, _, off, vaddr, _, filesz, memsz, _ = struct.unpack_from("<IIQQQQQQ", self.d, phoff + i * phentsize)
            if p_type == 1:
                self.loads.append((vaddr, memsz, off, filesz))
            elif p_type == 2:
                dyn = (off, filesz)
        self.relocs = {}
        tags = {}
        for i in range(dyn[1] // 16):
            t, v = struct.unpack_from("<qQ", self.d, dyn[0] + i * 16)
            if t == 0:
                break
            tags[t] = v
        rela, relasz = tags.get(7), tags.get(8, 0)
        if rela is not None:
            ro = self.v2o(rela)
            for i in range(relasz // 24):
                r_off, r_info, r_add = struct.unpack_from("<QQq", self.d, ro + i * 24)
                if r_info & 0xFFFFFFFF == 1027:  # R_AARCH64_RELATIVE
                    self.relocs[r_off] = r_add
        self.data_segs = [s for s in self.loads if s[0] != 0] or self.loads

    def v2o(self, va):
        for vaddr, memsz, off, filesz in self.loads:
            if vaddr <= va < vaddr + filesz:
                return off + va - vaddr
        return None

    def mapped(self, va):
        return any(v <= va < v + m for v, m, _, _ in self.loads)

    def ptr(self, va):
        if va in self.relocs:
            return self.relocs[va]
        o = self.v2o(va)
        return None if o is None else struct.unpack_from("<Q", self.d, o)[0]

    def u64(self, va):
        o = self.v2o(va)
        return None if o is None else struct.unpack_from("<Q", self.d, o)[0]

    def i64(self, va):
        o = self.v2o(va)
        return None if o is None else struct.unpack_from("<q", self.d, o)[0]

    def u32(self, va):
        o = self.v2o(va)
        return None if o is None else struct.unpack_from("<I", self.d, o)[0]

    def i32(self, va):
        o = self.v2o(va)
        return None if o is None else struct.unpack_from("<i", self.d, o)[0]

    def ptr_array(self, va, n):
        return [self.ptr(va + 8 * i) for i in range(n)]


def find_registration(elf, count, check):
    """Find a struct where a `count` u64 is immediately followed by a pointer."""
    hits = []
    for r in elf.relocs:
        if elf.u64(r - 8) == count and check(r - 8):
            hits.append(r - 8)
    return hits


def locate_code_registration(elf, md):
    n_ptrs = max(m[M_INDEX] for m in md.methods) + 1
    # CodeRegistration v24.1 begins with methodPointersCount, methodPointers
    def ok(base):
        p = elf.ptr(base + 8)
        return p is not None and elf.mapped(p)
    hits = find_registration(elf, n_ptrs, ok)
    if len(hits) != 1:
        sys.exit(f"CodeRegistration: expected 1 candidate, found {len(hits)} (count {n_ptrs})")
    return hits[0], n_ptrs


def locate_metadata_registration(elf, md):
    ntypes = len(md.types)
    # ... fieldOffsetsCount(=ntypes), fieldOffsets, typeDefinitionsSizesCount(=ntypes), typeDefinitionsSizes
    cands = []
    for r in elf.relocs:
        if elf.u64(r - 8) == ntypes and elf.u64(r + 8) == ntypes and (r + 16) in elf.relocs:
            base = r - 8 - 10 * 8
            types_count = elf.u64(base + 6 * 8)
            if types_count and 0 < types_count < 1_000_000 and (base + 7 * 8) in elf.relocs:
                cands.append(base)
    if len(cands) != 1:
        sys.exit(f"MetadataRegistration: expected 1 candidate, found {len(cands)}")
    return cands[0]


# ---------------------------------------------------------------- type names

PRIMS = {1: "void", 2: "bool", 3: "char", 4: "sbyte", 5: "byte", 6: "short", 7: "ushort",
         8: "int", 9: "uint", 10: "long", 11: "ulong", 12: "float", 13: "double",
         14: "string", 22: "TypedReference", 24: "IntPtr", 25: "UIntPtr", 28: "object"}


class Namer:
    def __init__(self, elf, md, mreg):
        self.elf, self.md, self.mreg = elf, md, mreg
        self.types_count = elf.u64(mreg + 6 * 8)
        self.type_ptrs = elf.ptr_array(elf.ptr(mreg + 7 * 8), self.types_count)
        self.field_offsets_ptr = elf.ptr(mreg + 11 * 8)
        self.metadata_usages_count = elf.u64(mreg + 14 * 8)
        self.metadata_usages_ptr = elf.ptr(mreg + 15 * 8)
        self._tdname = {}

    def typedef_name(self, ti, full=True):
        key = (ti, full)
        if key in self._tdname:
            return self._tdname[key]
        t = self.md.types[ti]
        name = self.md.s(t[T_NAME])
        if t[T_DECL] != -1:
            decl_ti = self.type_index_to_typedef(t[T_DECL])
            if decl_ti is not None:
                name = self.typedef_name(decl_ti, full) + "." + name
        elif full:
            ns = self.md.s(t[T_NS])
            if ns:
                name = ns + "." + name
        self._tdname[key] = name
        return name

    def il2cpp_type(self, ptr):
        data = self.elf.u64(ptr)
        bits = self.elf.u32(ptr + 8)
        return data, (bits >> 16) & 0xFF, (bits >> 30) & 1

    def type_index_to_typedef(self, type_index):
        data, kind, _ = self.il2cpp_type(self.type_ptrs[type_index])
        if kind in (0x11, 0x12):
            return data & 0xFFFFFFFF
        return None

    def generic_param_name(self, idx):
        g = self.md.gparams[idx]
        return self.md.s(g[1])

    def type_name_ptr(self, ptr, full=False):
        elf = self.elf
        data, kind, byref = self.il2cpp_type(ptr)
        if kind in PRIMS:
            n = PRIMS[kind]
        elif kind in (0x11, 0x12):
            n = self.typedef_name(data & 0xFFFFFFFF, full)
            n = n.split("`")[0] if "`" in n else n
        elif kind == 0x15:  # GENERICINST
            gc = elf.ptr(ptr) if ptr in elf.relocs else data
            td = elf.i64(gc)
            ctx_inst = elf.ptr(gc + 8)
            n = self.typedef_name(td, full).split("`")[0]
            if ctx_inst:
                argc = elf.u64(ctx_inst)
                argv = elf.ptr(ctx_inst + 8)
                args = [self.type_name_ptr(elf.ptr(argv + 8 * i)) for i in range(argc)]
                n += "<" + ", ".join(args) + ">"
        elif kind == 0x1D:  # SZARRAY
            inner = elf.ptr(ptr) if ptr in elf.relocs else data
            n = self.type_name_ptr(inner, full) + "[]"
        elif kind == 0x14:  # ARRAY
            arr = elf.ptr(ptr) if ptr in elf.relocs else data
            rank = elf.u32(arr + 8) & 0xFF
            n = self.type_name_ptr(elf.ptr(arr), full) + "[" + "," * (rank - 1) + "]"
        elif kind == 0x0F:  # PTR
            inner = elf.ptr(ptr) if ptr in elf.relocs else data
            n = self.type_name_ptr(inner, full) + "*"
        elif kind in (0x13, 0x1E):  # VAR / MVAR
            n = self.generic_param_name(data & 0xFFFFFFFF)
        else:
            n = f"<type 0x{kind:x}>"
        return ("ref " if byref else "") + n

    def type_name(self, type_index, full=False):
        if type_index < 0 or type_index >= self.types_count:
            return "?"
        return self.type_name_ptr(self.type_ptrs[type_index], full)

    def field_offset(self, ti, fi_local):
        tbl = self.elf.ptr(self.field_offsets_ptr + 8 * ti)
        if not tbl:
            return None
        return self.elf.i32(tbl + 4 * fi_local)


# ---------------------------------------------------------------- output

def method_flags(f):
    acc = {1: "private", 2: "internal", 3: "internal", 4: "protected", 5: "protected internal", 6: "public"}.get(f & 7, "")
    out = [acc] if acc else []
    if f & 0x10:
        out.append("static")
    if f & 0x400:
        out.append("abstract")
    elif f & 0x40 and not f & 0x20:
        out.append("virtual" if f & 0x100 else "override")
    if f & 0x2000:
        out.append("extern")
    return " ".join(out)


def field_flags(f):
    acc = {1: "private", 2: "internal", 3: "internal", 4: "protected", 5: "protected internal", 6: "public"}.get(f & 7, "")
    out = [acc] if acc else []
    if f & 0x40:
        out.append("const")
    else:
        if f & 0x10:
            out.append("static")
        if f & 0x20:
            out.append("readonly")
    return " ".join(out)


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    so_path, md_path, out = sys.argv[1:]
    os.makedirs(out, exist_ok=True)
    md = Metadata(md_path)
    elf = Elf(so_path)
    creg, n_ptrs = locate_code_registration(elf, md)
    mreg = locate_metadata_registration(elf, md)
    method_ptrs = elf.ptr_array(elf.ptr(creg + 8), n_ptrs)
    namer = Namer(elf, md, mreg)
    print(f"CodeRegistration 0x{creg:x} ({n_ptrs} method pointers), "
          f"MetadataRegistration 0x{mreg:x} ({namer.types_count} types)")

    image_of = {}
    for im in md.images:
        for ti in range(im[2], im[2] + im[3]):
            image_of[ti] = md.s(im[0])

    rows = []
    with open(os.path.join(out, "dump.cs"), "w", encoding="utf-8") as cs:
        for ti, t in enumerate(md.types):
            tname = namer.typedef_name(ti)
            cs.write(f"\n// Image: {image_of.get(ti, '?')}  TypeDefIndex: {ti}\n")
            f = t[T_FLAGS]
            kind = "interface" if f & 0x20 else "class"
            parent = ""
            if t[T_PARENT] >= 0:
                pn = namer.type_name(t[T_PARENT])
                if pn in ("ValueType",):
                    kind = "struct"
                elif pn == "Enum":
                    kind = "enum"
                elif pn != "object":
                    parent = " : " + pn
            cs.write(f"{kind} {tname}{parent}\n{{\n")
            if t[T_FCOUNT]:
                cs.write("\t// Fields\n")
            for k in range(t[T_FCOUNT]):
                fd = md.fields[t[T_FIELD] + k]
                off = namer.field_offset(ti, k)
                tp_ptr = namer.type_ptrs[fd[1]]
                attrs = elf.u32(tp_ptr + 8) & 0xFFFF
                fl = field_flags(attrs)
                offs = f" // 0x{off:X}" if off is not None and not (attrs & 0x10) else ""
                cs.write(f"\t{fl} {namer.type_name(fd[1])} {md.s(fd[0])};{offs}\n")
            if t[T_MCOUNT]:
                cs.write("\n\t// Methods\n")
            for k in range(t[T_MCOUNT]):
                mi = t[T_METHOD] + k
                m = md.methods[mi]
                mname = md.s(m[M_NAME])
                ps = []
                for p in range(m[M_PCOUNT]):
                    pd = md.params[m[M_PARAM] + p]
                    ps.append(f"{namer.type_name(pd[2])} {md.s(pd[0])}")
                sig = f"{namer.type_name(m[M_RET])} {mname}({', '.join(ps)})"
                rva = method_ptrs[m[M_INDEX]] if m[M_INDEX] >= 0 else 0
                if rva:
                    cs.write(f"\t// RVA: 0x{rva:X}\n")
                    rows.append((rva, tname, mname, sig))
                cs.write(f"\t{method_flags(m[M_FLAGS])} {sig} {{ }}\n")
            cs.write("}\n")

    with open(os.path.join(out, "methods.csv"), "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["rva", "type", "method", "signature"])
        for r in sorted(rows):
            w.writerow([f"0x{r[0]:X}", r[1], r[2], r[3]])

    # string literal usages: metadataUsages[destination] is a global slot
    # Like Il2CppDumper, size the table from the metadata (the registration
    # count field can be smaller than the highest destination index).
    n_usages = max(namer.metadata_usages_count, max(p[0] for p in md.usage_pairs) + 1)
    usages = elf.ptr_array(namer.metadata_usages_ptr, n_usages)
    lit_slot = {}
    for dest, enc in md.usage_pairs:
        if (enc >> 29) == 5:  # kIl2CppMetadataUsageStringLiteral
            lit_slot.setdefault(enc & 0x1FFFFFFF, usages[dest])
    with open(os.path.join(out, "string_literals.csv"), "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["index", "usage_slot_rva", "value"])
        for i in range(md.literal_count):
            slot = lit_slot.get(i)
            w.writerow([i, f"0x{slot:X}" if slot else "", md.literal(i)])

    # Ghidra script: name functions and string-literal slots
    seen = set()
    with open(os.path.join(out, "ghidra_names.py"), "w", encoding="utf-8") as g:
        g.write("# Apply IL2CPP names. Run from Ghidra Script Manager (Jython/PyGhidra).\n")
        g.write("from ghidra.program.model.symbol import SourceType\n")
        g.write("base = currentProgram.getImageBase().getOffset()\n")
        g.write("def A(o): return toAddr(base + o)\n")
        g.write("def F(o, n):\n    a = A(o)\n    f = getFunctionAt(a) or createFunction(a, n)\n"
                "    if f: f.setName(n, SourceType.USER_DEFINED)\n")
        g.write("def L(o, n):\n    createLabel(A(o), n, True, SourceType.USER_DEFINED)\n")
        g.write("NAMES = [\n")
        for rva, tname, mname, _ in sorted(rows):
            if rva in seen:
                continue
            seen.add(rva)
            n = (tname + "$$" + mname).replace(" ", "_")
            g.write(f"    (0x{rva:X}, {n!r}),\n")
        g.write("]\nfor o, n in NAMES:\n    try: F(o, n)\n    except Exception as e: print(o, e)\n")
        g.write("SLOTS = [\n")
        for i, slot in sorted(lit_slot.items()):
            g.write(f"    (0x{slot:X}, 'StringLiteral_{i}'),\n")
        g.write("]\nfor o, n in SLOTS:\n    try: L(o, n)\n    except Exception as e: print(o, e)\n")

    print(f"types={len(md.types)} methods={len(md.methods)} with_code={len(rows)} "
          f"string_literals={md.literal_count} literal_slots={len(lit_slot)}")


if __name__ == "__main__":
    main()
