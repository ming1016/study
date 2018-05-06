package org.yinwang.pysonar;

import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.core.JsonGenerator;
import com.google.common.collect.Lists;
import org.yinwang.pysonar.ast.FunctionDef;
import org.yinwang.pysonar.ast.Node;
import org.yinwang.pysonar.ast.Str;
import org.yinwang.pysonar.types.FunType;
import org.yinwang.pysonar.types.Type;
import org.yinwang.pysonar.types.UnionType;

import java.io.*;
import java.util.*;
import java.util.Map.Entry;
import java.util.logging.Level;
import java.util.logging.Logger;


public class JSONDump {

    private static Logger log = Logger.getLogger(Logger.GLOBAL_LOGGER_NAME);

    private static Set<String> seenDef = new HashSet<>();
    private static Set<String> seenRef = new HashSet<>();
    private static Set<String> seenDocs = new HashSet<>();


    private static String dirname(String path) {
        return new File(path).getParent();
    }


    private static Analyzer newAnalyzer(String srcpath, String[] inclpaths) throws Exception {
        Analyzer idx = new Analyzer();
        for (String inclpath : inclpaths) {
            idx.addPath(inclpath);
        }

        idx.analyze(srcpath);
        idx.finish();

        if (idx.semanticErrors.size() > 0) {
            log.info("Analyzer errors:");
            for (Entry<String, List<Diagnostic>> entry : idx.semanticErrors.entrySet()) {
                String k = entry.getKey();
                log.info("  Key: " + k);
                List<Diagnostic> diagnostics = entry.getValue();
                for (Diagnostic d : diagnostics) {
                    log.info("    " + d);
                }
            }
        }

        return idx;
    }


    private static void writeSymJson(Binding binding, JsonGenerator json) throws IOException {
        if (binding.start < 0) {
            return;
        }

        String name = binding.name;
        boolean isExported = !(
                Binding.Kind.VARIABLE == binding.kind ||
                        Binding.Kind.PARAMETER == binding.kind ||
                        Binding.Kind.SCOPE == binding.kind ||
                        Binding.Kind.ATTRIBUTE == binding.kind ||
                        (name.length() == 0 || name.charAt(0) == '_' || name.startsWith("lambda%")));

        String path = binding.qname.replace('.', '/').replace("%20", ".");

        if (!seenDef.contains(path)) {
            seenDef.add(path);
            json.writeStartObject();
            json.writeStringField("name", name);
            json.writeStringField("path", path);
            json.writeStringField("file", binding.fileOrUrl);
            json.writeNumberField("identStart", binding.start);
            json.writeNumberField("identEnd", binding.end);
            json.writeNumberField("defStart", binding.bodyStart);
            json.writeNumberField("defEnd", binding.bodyEnd);
            json.writeBooleanField("exported", isExported);
            json.writeStringField("kind", binding.kind.toString());

            if (Binding.Kind.FUNCTION == binding.kind ||
                    Binding.Kind.METHOD == binding.kind ||
                    Binding.Kind.CONSTRUCTOR == binding.kind)
            {
                json.writeObjectFieldStart("funcData");

                // get args expression
                String argExpr = null;
                Type t = binding.type;

                if (t instanceof UnionType) {
                    t = ((UnionType) t).firstUseful();
                }

                if (t != null && t instanceof FunType) {
                    FunctionDef func = ((FunType) t).func;
                    if (func != null) {
                        argExpr = func.getArgumentExpr();
                    }
                }

                String typeExpr = binding.type.toString();

                json.writeNullField("params");

                String signature = argExpr == null ? "" : argExpr + "\n" + typeExpr;
                json.writeStringField("signature", signature);
                json.writeEndObject();
            }

            json.writeEndObject();
        }
    }


    private static void writeRefJson(Node ref, Binding binding, JsonGenerator json) throws IOException {
        if (binding.getFile() != null) {
            String path = binding.qname.replace(".", "/").replace("%20", ".");
            String key = ref.file + ":" + ref.start;
            if (!seenRef.contains(key)) {
                seenRef.add(key);
                if (binding.start >= 0 && ref.start >= 0 && !binding.isBuiltin()) {
                    json.writeStartObject();
                    json.writeStringField("sym", path);
                    json.writeStringField("file", ref.file);
                    json.writeNumberField("start", ref.start);
                    json.writeNumberField("end", ref.end);
                    json.writeBooleanField("builtin", binding.isBuiltin());
                    json.writeEndObject();
                }
            }
        }
    }


    private static void writeDocJson(Binding binding, Analyzer idx, JsonGenerator json) throws Exception {
        String path = binding.qname.replace('.', '/').replace("%20", ".");

        if (!seenDocs.contains(path)) {
            seenDocs.add(path);

            Str doc = binding.getDocstring();

            if (doc != null) {
                json.writeStartObject();
                json.writeStringField("sym", path);
                json.writeStringField("file", binding.fileOrUrl);
                json.writeStringField("body", doc.value);
                json.writeNumberField("start", doc.start);
                json.writeNumberField("end", doc.end);
                json.writeEndObject();
            }
        }
    }


    /*
     * Precondition: srcpath and inclpaths are absolute paths
     */
    private static void graph(String srcpath,
                              String[] inclpaths,
                              OutputStream symOut,
                              OutputStream refOut,
                              OutputStream docOut) throws Exception
    {
        // Compute parent dirs, sort by length so potential prefixes show up first
        List<String> parentDirs = Lists.newArrayList(inclpaths);
        parentDirs.add(dirname(srcpath));
        Collections.sort(parentDirs, new Comparator<String>() {
            @Override
            public int compare(String s1, String s2) {
                int diff = s1.length() - s2.length();
                if (0 == diff) {
                    return s1.compareTo(s2);
                }
                return diff;
            }
        });

        Analyzer idx = newAnalyzer(srcpath, inclpaths);
        idx.multilineFunType = true;
        JsonFactory jsonFactory = new JsonFactory();
        JsonGenerator symJson = jsonFactory.createGenerator(symOut);
        JsonGenerator refJson = jsonFactory.createGenerator(refOut);
        JsonGenerator docJson = jsonFactory.createGenerator(docOut);
        JsonGenerator[] allJson = {symJson, refJson, docJson};
        for (JsonGenerator json : allJson) {
            json.writeStartArray();
        }

        for (Binding b : idx.getAllBindings()) {
            String path = b.qname.replace('.', '/').replace("%20", ".");

            if (b.getFile() != null) {
                if (b.getFile().startsWith(srcpath)) {
                    writeSymJson(b, symJson);
                    writeDocJson(b, idx, docJson);
                }
            }

            for (Node ref : b.refs) {
                if (ref.file != null) {
                    if (ref.file.startsWith(srcpath)) {
                        writeRefJson(ref, b, refJson);
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
        info("Usage: java org.yinwang.pysonar.dump <source-path> <include-paths> <out-root> [verbose]");
        info("  <source-path> is path to source unit (package directory or module file) that will be graphed");
        info("  <include-paths> are colon-separated paths to included libs");
        info("  <out-root> is the prefix of the output files.  There are 3 output files: <out-root>-doc, <out-root>-sym, <out-root>-ref");
        info("  [verbose] if set, then verbose logging is used (optional)");
    }


    public static void main(String[] args) throws Exception {
        if (args.length < 3 || args.length > 4) {
            usage();
            return;
        }

        log.setLevel(Level.SEVERE);
        if (args.length >= 4) {
            log.setLevel(Level.ALL);
            log.info("LOGGING VERBOSE");
            log.info("ARGS: " + Arrays.toString(args));
        }

        String srcpath = args[0];
        String[] inclpaths = args[1].split(":");
        String outroot = args[2];

        String symFilename = outroot + "-sym";
        String refFilename = outroot + "-ref";
        String docFilename = outroot + "-doc";
        OutputStream symOut = null, refOut = null, docOut = null;
        try {
            docOut = new BufferedOutputStream(new FileOutputStream(docFilename));
            symOut = new BufferedOutputStream(new FileOutputStream(symFilename));
            refOut = new BufferedOutputStream(new FileOutputStream(refFilename));
            _.msg("graphing: " + srcpath);
            graph(srcpath, inclpaths, symOut, refOut, docOut);
            docOut.flush();
            symOut.flush();
            refOut.flush();
        } catch (FileNotFoundException e) {
            System.err.println("Could not find file: " + e);
            return;
        } finally {
            if (docOut != null) {
                docOut.close();
            }
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
