#!/usr/bin/env python3
"""Install lightweight inline traces into libil2cpp.so (no device/Frida needed).

The game's own Debug logging is stripped to `ret` in release, and Android won't
let the app read the system log that says why it's torn down. So to see how far
the boot/login state machine gets, we hook a handful of IL2CPP method entries:
each hooked method, on entry, appends one ASCII letter to /sdcard/reborn_trace.bin
and then runs normally. Reading that file afterwards shows the exact execution
path and the last method reached before the ~7s teardown.

Mechanism (all within libil2cpp, so branches stay in range; no ELF surgery):
  - A donor region (a large, never-called example method) is overwritten with a
    blob = trace_write() + one stub per hook.
  - trace_write(w0=ascii) opens the file (openat/append), writes the byte + '\n',
    closes -- raw AArch64 syscalls, clobbers only caller-saved regs.
  - Each stub saves x0-x18+x30, calls trace_write with its letter, restores, then
    executes the hooked method's original first instruction and branches back to
    method+4. The first instruction of every hook target is a plain stack
    prologue (stp/str/sub), so relocating it verbatim is safe.
  - Each method's first instruction is replaced with `b <stub>`.

The stub save/restore and trace_write are assembled with llvm-mc (exact, no hand
encoding); only the two cross-region branches per hook are encoded here.

Usage: inline_trace.py <lib.so> <donor_rva_hex>
Hooks are the HOOKS table below (rva, letter, name).
"""
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile

# (rva, ascii letter, human name) -- letters show up in the trace file in order.
HOOKS = [
    (0x1C334B8, "A", "U_Logo.Initialize"),
    (0x1C3365C, "B", "U_Logo.PM_SetConnectionString.cb"),
    (0x1C33200, "C", "U_Logo.go_Check"),
    (0x1C33428, "D", "U_Logo.setExit"),
    (0x1C20E54, "E", "U_Lobby_Loading.Awake"),
    (0x1C22204, "F", "U_Lobby_Loading.setLogin"),
    (0x1C22190, "G", "U_LoginSelect.View"),
    (0x1C231C4, "H", "U_Lobby_Loading.CreateAccount"),
    (0x1C22C38, "I", "U_Lobby_Loading.setFail"),
    (0x1C25F00, "J", "U_Lobby_Loading.setError"),
    (0x1C23BDC, "K", "U_Lobby_Loading.GameServerLogin"),
    (0x1C2543C, "L", "U_Lobby_Loading.RequestMyinfo"),
    # logo -> lobby transition (the stall is here, after the connection_string cb)
    (0x1BB75E8, "M", "U_Popup.Confirm (error popup)"),
    (0x1C901F4, "N", "HttpManager.SetDefaultUrl (cb success path)"),
    (0x1A84B74, "O", "U_LoadingBar.View"),
    (0x1C32E8C, "P", "U_Logo.set_REAL"),
    (0x1C33154, "Q", "U_Logo.set_PASS"),
    (0x1C332B8, "R", "U_Logo.go_Stage"),
]


def _find_tool(base):
    # exact, then NDK bin, then versioned (llvm-18 .. llvm-14) on PATH
    ndk = os.environ.get("ANDROID_NDK_LATEST_HOME") or os.environ.get("ANDROID_NDK_ROOT") \
        or os.environ.get("ANDROID_NDK_HOME")
    cands = [base]
    if ndk:
        cands.append(os.path.join(ndk, "toolchains/llvm/prebuilt/linux-x86_64/bin", base))
    cands += [f"{base}-{v}" for v in range(20, 13, -1)]
    for c in cands:
        p = c if os.path.isabs(c) and os.path.exists(c) else shutil.which(c)
        if p:
            return p
    sys.exit(f"{base} not found (need llvm tools; set PATH or ANDROID_NDK_LATEST_HOME)")


def find_llvm_mc():
    return _find_tool("llvm-mc"), _find_tool("llvm-objcopy"), _find_tool("llvm-nm")


def enc_b(src, dst):
    off = dst - src
    assert off % 4 == 0 and -(1 << 27) <= off < (1 << 27), f"branch out of range {off}"
    return 0x14000000 | ((off >> 2) & 0x03FFFFFF)


def main():
    path, donor_hex = sys.argv[1], sys.argv[2]
    donor = int(donor_hex, 16)
    mc, objcopy, nm = find_llvm_mc()
    data = bytearray(open(path, "rb").read())

    # read each hook's original first instruction word (file offset == rva here)
    origs = {}
    for rva, letter, _ in HOOKS:
        origs[letter] = struct.unpack_from("<I", data, rva)[0]

    # build the assembly blob
    lines = [".text", ".balign 4", "trace_write:",
             "  mov x9, x0", "  adr x1, pathstr", "  movn x0, #99",
             "  movz x2, #0x441", "  movz x3, #0x1b6", "  movz x8, #56", "  svc #0",
             "  cmp x0, #0", "  b.lt 1f", "  mov x5, x0",
             "  sub sp, sp, #16", "  strb w9, [sp]", "  mov w10, #10", "  strb w10, [sp, #1]",
             "  mov x0, x5", "  mov x1, sp", "  movz x2, #2", "  movz x8, #64", "  svc #0",
             "  add sp, sp, #16", "  mov x0, x5", "  movz x8, #57", "  svc #0",
             "1:", "  ret",
             "pathstr:", '  .asciz "/sdcard/reborn_trace.bin"', "  .balign 4"]
    SAVE = ["  sub sp, sp, #0xa0"] + [
        f"  stp x{2*i}, x{2*i+1}, [sp, #{hex(0x10*i)}]" for i in range(9)
    ] + ["  stp x18, x30, [sp, #0x90]"]
    REST = [f"  ldp x{2*i}, x{2*i+1}, [sp, #{hex(0x10*i)}]" for i in range(9)] + [
        "  ldp x18, x30, [sp, #0x90]", "  add sp, sp, #0xa0"]
    for rva, letter, _ in HOOKS:
        lines.append(f"stub_{letter}:")
        lines += SAVE
        lines.append(f"  movz w0, #{ord(letter)}")
        lines.append("  bl trace_write")
        lines += REST
        lines.append(f"  .inst {hex(origs[letter])}")
        lines.append(f"bk_{letter}:")
        lines.append("  .inst 0x14000000")  # placeholder b, patched below
    asm = "\n".join(lines) + "\n"

    with tempfile.TemporaryDirectory() as td:
        s = os.path.join(td, "blob.s")
        o = os.path.join(td, "blob.o")
        b = os.path.join(td, "blob.bin")
        open(s, "w").write(asm)
        subprocess.run([mc, "-triple=aarch64", "-filetype=obj", s, "-o", o], check=True)
        subprocess.run([objcopy, "-O", "binary", "--only-section=.text", o, b], check=True)
        blob = bytearray(open(b, "rb").read())
        syms = {}
        out = subprocess.run([nm, o], capture_output=True, text=True).stdout
        for line in out.splitlines():
            m = re.match(r"([0-9a-f]+)\s+\S+\s+(\S+)", line)
            if m:
                syms[m.group(2)] = int(m.group(1), 16)

    if len(blob) > 0x3000:
        sys.exit(f"blob too big: {len(blob)}")

    # patch each back-branch inside the blob: bk_X -> method+4
    for rva, letter, _ in HOOKS:
        bk = syms[f"bk_{letter}"]
        src = donor + bk
        struct.pack_into("<I", blob, bk, enc_b(src, rva + 4))

    # place blob into the donor region
    data[donor:donor + len(blob)] = blob

    # patch each method entry: first instr -> b stub_X
    for rva, letter, name in HOOKS:
        stub = donor + syms[f"stub_{letter}"]
        struct.pack_into("<I", data, rva, enc_b(rva, stub))
        print(f"  hook {letter} @ 0x{rva:x} {name} -> stub 0x{stub:x}")

    open(path, "wb").write(data)
    print(f"inline trace: {len(HOOKS)} hooks, blob {len(blob)} bytes at donor 0x{donor:x} "
          f"-> /sdcard/reborn_trace.bin")


if __name__ == "__main__":
    main()
