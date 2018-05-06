package org.yinwang.rubysonar;

import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.core.JsonGenerator;
import org.jetbrains.annotations.NotNull;
import org.yinwang.rubysonar.ast.Function;
import org.yinwang.rubysonar.ast.Node;
import org.yinwang.rubysonar.ast.Str;
import org.yinwang.rubysonar.types.Type;

import java.io.*;
import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;


public class JSONDump {

    private static Logger log = Logger.getLogger(Logger.GLOBAL_LOGGER_NAME);

    private static Set<String> seenDef = new HashSet<>();
    private static Set<String> seenRef = new HashSet<>();


    @NotNull
    private static String dirname(@NotNull String path) {
        File f = new File(path);
        if (f.getParent() != null) {
            return f.getParent();
        } else {
            return path;
        }
    }


    private static Analyzer newAnalyzer(String projectDir, List<String> srcpath, List<String> inclpaths) {
        Analyzer idx = new Analyzer();
        idx.addPath(projectDir);
        idx.addPaths(inclpaths);
        idx.analyze(srcpath);
        idx.finish();
        return idx;
    }


    private static String kindName(Binding.Kind kind) {
        if (kind == Binding.Kind.CLASS_METHOD) {
            return "method";
        } else {
            return kind.toString().toLowerCase();
        }
    }


    private static void writeSymJson(@NotNull Binding binding, JsonGenerator json) throws IOException {
        if (binding.start < 0) {
            return;
        }

        String name = binding.node.name;
        boolean isExported = !(
                Binding.Kind.VARIABLE == binding.kind ||
                        Binding.Kind.PARAMETER == binding.kind ||
                        Binding.Kind.SCOPE == binding.kind ||
                        Binding.Kind.ATTRIBUTE == binding.kind ||
                        (name != null && (name.length() == 0 || name.startsWith("lambda%"))));

        String path = binding.qname.replace("%20", ".");

        if (!seenDef.contains(path)) {
            seenDef.add(path);

            json.writeStartObject();
            json.writeStringField("name", name);
            json.writeStringField("path", path);
            json.writeStringField("file", binding.file);
            json.writeNumberField("identStart", binding.start);
            json.writeNumberField("identEnd", binding.end);
            json.writeNumberField("defStart", binding.bodyStart);
            json.writeNumberField("defEnd", binding.bodyEnd);
            json.writeBooleanField("exported", isExported);
            json.writeStringField("kind", kindName(binding.kind));

            if (binding.kind == Binding.Kind.METHOD || binding.kind == Binding.Kind.CLASS_METHOD) {
                // get args expression
                Type t = binding.type;

                if (t.isUnionType()) {
                    t = t.asUnionType().firstUseful();
                }

                if (t != null && t.isFuncType()) {
                    Function func = t.asFuncType().func;
                    if (func != null) {
                        String signature = func.getArgList();
                        if (!signature.equals("")) {
                            signature = "(" + signature + ")";
                        }
                        json.writeStringField("signature", signature);
                    }
                }
            }

            Str docstring = binding.findDocString();
            if (docstring != null) {
                json.writeStringField("docstring", docstring.value);
            }

            json.writeEndObject();
        }
    }


    private static void writeRefJson(Node ref, Binding binding, JsonGenerator json) throws IOException {
        if (binding.file != null) {
            String path = binding.qname.replace("%20", ".");

            if (binding.start >= 0 && ref.start >= 0) {
                json.writeStartObject();
                json.writeStringField("sym", path);
                json.writeStringField("symFile", binding.node.file);
                json.writeStringField("file", ref.file);
                json.writeNumberField("start", ref.start);
                json.writeNumberField("end", ref.end);
                json.writeBooleanField("builtin", false);
                json.writeEndObject();
            }
        }
    }


    /*
     * Precondition: srcpath and inclpaths are absolute paths
     */
    private static void graph(String projectDir,
                              List<String> srcpath,
                              List<String> inclpaths,
                              OutputStream symOut,
                              OutputStream refOut) throws Exception
    {
        Analyzer idx = newAnalyzer(projectDir, srcpath, inclpaths);
        idx.multilineFunType = true;
        JsonFactory jsonFactory = new JsonFactory();
        JsonGenerator symJson = jsonFactory.createGenerator(symOut);
        JsonGenerator refJson = jsonFactory.createGenerator(refOut);
        JsonGenerator[] allJson = {symJson, refJson};
        for (JsonGenerator json : allJson) {
            json.writeStartArray();
        }

        for (Binding b : idx.getAllBindings()) {

            if (b.file != null && b.file.startsWith(projectDir)) {
                writeSymJson(b, symJson);
                writeRefJson(b.node, b, refJson);    // self reference
            }

            for (Node ref : b.refs) {
                if (ref.file != null && ref.file.startsWith(projectDir)) {
                    String key = ref.file + ":" + ref.start;
                    if (!seenRef.contains(key)) {
                        writeRefJson(ref, b, refJson);
                        seenRef.add(key);
                    }
                }
            }
        }

        for (JsonGenerator json : allJson) {
            json.writeEndArray();
            json.close();
        }
    }


    private static void info(Object msg) {
        System.out.println(msg);
    }


    private static void usage() {
        info("Usage: java org.yinwang.rubysonar.dump <source-path> <include-paths> <out-root> [verbose]");
        info("  <source-path> is path to source unit (package directory or module file) that will be graphed");
        info("  <include-paths> are colon-separated paths to included libs");
        info("  <out-root> is the prefix of the output files.  There are 3 output files: <out-root>-doc, <out-root>-sym, <out-root>-ref");
        info("  [verbose] if set, then verbose logging is used (optional)");
    }


    public static void main(String[] args) throws Exception {
        log.setLevel(Level.SEVERE);

        String projectDir;
        String outroot;
        List<String> inclpaths;
        List<String> srcpath = new ArrayList<>();

        if (args.length >= 3) {
            projectDir = args[0];
            outroot = args[1];
            inclpaths = Arrays.asList(args[2].split(":"));
            srcpath.addAll(Arrays.asList(args).subList(3, args.length));
        } else {
            usage();
            return;
        }

        OutputStream symOut = null, refOut = null;
        try {
            symOut = new BufferedOutputStream(new FileOutputStream(outroot + "-sym"));
            refOut = new BufferedOutputStream(new FileOutputStream(outroot + "-ref"));
            _.msg("graphing: " + srcpath);
            graph(projectDir, srcpath, inclpaths, symOut, refOut);
            symOut.flush();
            refOut.flush();
        } catch (FileNotFoundException e) {
            System.err.println("Could not find file: " + e);
            return;
        } finally {
            if (symOut != null) {
                symOut.close();
            }
            if (refOut != null) {
                refOut.close();
            }
        }
        log.info("SUCCESS");
    }
}
