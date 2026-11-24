// Apply IL2CPP labels and decompile selected methods (headless).
//
// Script args: <labels.tsv> <targets.txt> <out_dir> [create_all_functions=true|false]
//   labels.tsv   from tools/il2cpp_v241/ghidra_labels.py
//   targets.txt  one method name per line (Type$$Method, exact or prefix*)
// Writes <out_dir>/<name>.c for each target and appends string-literal
// comments next to decompiled lines that reference them.
//@category IL2CPP

import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileOptions;
import ghidra.app.decompiler.DecompileResults;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.symbol.SourceType;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.*;
import java.util.regex.*;

public class DecompileIl2cpp extends GhidraScript {

    @Override
    protected void run() throws Exception {
        String[] a = getScriptArgs();
        Path labels = Paths.get(a[0]);
        Path targets = Paths.get(a[1]);
        Path outDir = Paths.get(a[2]);
        boolean createAll = a.length < 4 || Boolean.parseBoolean(a[3]);
        Files.createDirectories(outDir);
        long base = currentProgram.getImageBase().getOffset();

        Map<String, Long> byName = new HashMap<>();
        Map<String, String> literalText = new HashMap<>();
        int n = 0;
        for (String line : Files.readAllLines(labels, StandardCharsets.UTF_8)) {
            String[] f = line.split("\t", 4);
            long rva = Long.parseLong(f[0], 16);
            Address addr = toAddr(base + rva);
            String name = f[2];
            try {
                createLabel(addr, name, true, SourceType.USER_DEFINED);
            } catch (Exception e) {
                // duplicate or invalid name; keep going
            }
            if (f[1].equals("F")) {
                byName.putIfAbsent(name, rva);
                if (createAll && getFunctionAt(addr) == null) {
                    disassemble(addr);
                    createFunction(addr, name);
                }
            } else if (f.length > 3) {
                literalText.put(name, f[3]);
            }
            if (++n % 10000 == 0) {
                println("labels: " + n);
            }
        }
        println("labels applied: " + n);

        DecompInterface ifc = new DecompInterface();
        ifc.setOptions(new DecompileOptions());
        ifc.openProgram(currentProgram);
        Pattern lit = Pattern.compile("(?:GOT_)?StringLiteral_\\d+");

        for (String t : Files.readAllLines(targets, StandardCharsets.UTF_8)) {
            t = t.trim();
            if (t.isEmpty() || t.startsWith("#")) continue;
            List<String> names = new ArrayList<>();
            if (t.endsWith("*")) {
                String p = t.substring(0, t.length() - 1);
                for (String k : byName.keySet()) if (k.startsWith(p)) names.add(k);
                Collections.sort(names);
            } else if (byName.containsKey(t)) {
                names.add(t);
            } else {
                println("not found: " + t);
            }
            for (String name : names) {
                Address addr = toAddr(base + byName.get(name));
                Function fn = getFunctionAt(addr);
                if (fn == null) {
                    disassemble(addr);
                    fn = createFunction(addr, name);
                }
                if (fn == null) {
                    println("cannot create function: " + name);
                    continue;
                }
                DecompileResults r = ifc.decompileFunction(fn, 120, monitor);
                String code = r.decompileCompleted() ? r.getDecompiledFunction().getC() : "// decompile failed: " + r.getErrorMessage();
                StringBuilder sb = new StringBuilder();
                sb.append("// ").append(name).append(" @ RVA 0x").append(Long.toHexString(byName.get(name))).append('\n');
                for (String line : code.split("\n")) {
                    sb.append(line);
                    Matcher m = lit.matcher(line);
                    List<String> notes = new ArrayList<>();
                    while (m.find()) {
                        String txt = literalText.get(m.group());
                        if (txt != null) notes.add('"' + txt + '"');
                    }
                    if (!notes.isEmpty()) sb.append("  /* ").append(String.join(", ", notes)).append(" */");
                    sb.append('\n');
                }
                String file = name.replaceAll("[^A-Za-z0-9_$.-]", "_");
                if (file.length() > 150) file = file.substring(0, 150);
                Files.writeString(outDir.resolve(file + ".c"), sb.toString(), StandardCharsets.UTF_8);
                println("decompiled: " + name);
            }
        }
        ifc.dispose();
    }
}
