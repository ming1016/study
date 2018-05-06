package org.yinwang.pysonar;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import org.yinwang.pysonar.ast.Dummy;
import org.yinwang.pysonar.ast.Node;

import java.io.File;
import java.util.*;

public class Test {

    static Gson gson = new GsonBuilder().setPrettyPrinting().create();
    Analyzer analyzer;
    String inputDir;
    boolean exp;
    String expecteRefsFile;
    String failedRefsFile;


    public Test(String inputDir, boolean exp) {
        // make a quiet analyzer
        Map<String, Object> options = new HashMap<>();
        options.put("quiet", true);
        this.analyzer = new Analyzer(options);

        this.inputDir = inputDir;
        this.exp = exp;
        if (new File(inputDir).isDirectory()) {
            expecteRefsFile = _.makePathString(inputDir, "refs.json");
            failedRefsFile = _.makePathString(inputDir, "failed_refs.json");
        } else {
            expecteRefsFile = _.makePathString(inputDir + ".refs.json");
            failedRefsFile = _.makePathString(inputDir, ".failed_refs.json");
        }
    }


    public void runAnalysis(String dir) {
        analyzer.analyze(dir);
        analyzer.finish();
    }


    public void generateRefs() {

        List<Map<String, Object>> refs = new ArrayList<>();
        for (Map.Entry<Node, List<Binding>> e : analyzer.getReferences().entrySet()) {

            String file = e.getKey().file;

            // only record those in the inputDir
            if (file != null && file.startsWith(Analyzer.self.projectDir)) {
                file = _.projRelPath(file);
                Map<String, Object> writeout = new LinkedHashMap<>();

                Map<String, Object> ref = new LinkedHashMap<>();
                ref.put("name", e.getKey().name);
                ref.put("file", file);
                ref.put("start", e.getKey().start);
                ref.put("end", e.getKey().end);

                List<Map<String, Object>> dests = new ArrayList<>();
                for (Binding b : e.getValue()) {
                    String destFile = b.getFile();
                    if (destFile != null && destFile.startsWith(Analyzer.self.projectDir)) {
                        destFile = _.projRelPath(destFile);
                        Map<String, Object> dest = new LinkedHashMap<>();
                        dest.put("name", b.name);
                        dest.put("file", destFile);
                        dest.put("start", b.start);
                        dest.put("end", b.end);
                        dests.add(dest);
                    }
                }
                if (!dests.isEmpty()) {
                    writeout.put("ref", ref);
                    writeout.put("dests", dests);
                    refs.add(writeout);
                }
            }
        }

        String json = gson.toJson(refs);
        _.writeFile(expecteRefsFile, json);
    }


    public boolean checkRefs() {
        List<Map<String, Object>> failedRefs = new ArrayList<>();
        String json = _.readFile(expecteRefsFile);
        if (json == null) {
            _.msg("Expected refs not found in: " + expecteRefsFile +
                    "Please run Test with -exp to generate");
            return false;
        }
        List<Map<String, Object>> expectedRefs = gson.fromJson(json, List.class);
        for (Map<String, Object> r : expectedRefs) {
            Map<String, Object> refMap = (Map<String, Object>) r.get("ref");
            Dummy dummy = makeDummy(refMap);

            List<Map<String, Object>> dests = (List<Map<String, Object>>) r.get("dests");
            List<Binding> actualDests = analyzer.getReferences().get(dummy);
            List<Map<String, Object>> failedDests = new ArrayList<>();

            for (Map<String, Object> d : dests) {
                // names are ignored, they are only for human readers
                String file = _.projAbsPath((String) d.get("file"));
                int start = (int) Math.floor((double) d.get("start"));
                int end = (int) Math.floor((double) d.get("end"));

                if (!checkBindingExist(actualDests, file, start, end)) {
                    failedDests.add(d);
                }
            }

            // record the ref & failed dests if any
            if (!failedDests.isEmpty()) {
                Map<String, Object> failedRef = new LinkedHashMap<>();
                failedRef.put("ref", refMap);
                failedRef.put("dests", failedDests);
                failedRefs.add(failedRef);
            }
        }

        if (failedRefs.isEmpty()) {
            return true;
        } else {
            String failedJson = gson.toJson(failedRefs);
            _.testmsg("Failed to find refs: " + failedJson);
            _.writeFile(failedRefsFile, failedJson);
            return false;
        }
    }


    boolean checkBindingExist(List<Binding> bs, String file, int start, int end) {
        if (bs == null) {
            return false;
        }

        for (Binding b : bs) {
            if (((b.getFile() == null && file == null) ||
                    (b.getFile() != null && file != null && b.getFile().equals(file))) &&
                    b.start == start && b.end == end)
            {
                return true;
            }
        }

        return false;
    }


    public static Dummy makeDummy(Map<String, Object> m) {
        String file = _.projAbsPath((String) m.get("file"));
        int start = (int) Math.floor((double) m.get("start"));
        int end = (int) Math.floor((double) m.get("end"));
        return new Dummy(file, start, end);
    }


    public void generateTest() {
        runAnalysis(inputDir);
        generateRefs();
        _.testmsg("  * " + inputDir);
    }


    public boolean runTest() {
        runAnalysis(inputDir);
        _.testmsg("  * " + inputDir);
        return checkRefs();
    }


    // ------------------------- static part -----------------------


    public static void testAll(String path, boolean exp) {
        List<String> failed = new ArrayList<>();
        if (exp) {
            _.testmsg("generating tests");
        } else {
            _.testmsg("verifying tests");
        }

        testRecursive(path, exp, failed);

        if (exp) {
            _.testmsg("all tests generated");
        } else if (failed.isEmpty()) {
            _.testmsg("all tests passed!");
        } else {
            _.testmsg("failed some tests: ");
            for (String f : failed) {
                _.testmsg("  * " + f);
            }
        }
    }


    public static void testRecursive(String path, boolean exp, List<String> failed) {
        File file_or_dir = new File(path);

        if (file_or_dir.isDirectory()) {
            if (path.endsWith(".test")) {
                Test test = new Test(path, exp);
                if (exp) {
                    test.generateTest();
                } else {
                    if (!test.runTest()) {
                        failed.add(path);
                    }
                }
            } else {
                for (File file : file_or_dir.listFiles()) {
                    testRecursive(file.getPath(), exp, failed);
                }
            }
        }
    }


    public static void main(String[] args) throws Exception {
        Options options = new Options(args);
        List<String> argsList = options.getArgs();
        String inputDir = _.unifyPath(argsList.get(0));

        // generate expected file?
        boolean exp = options.hasOption("exp");
        testAll(inputDir, exp);
    }
}
