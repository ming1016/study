package org.python.indexer.demos;

import org.python.indexer.Indexer;
import org.python.indexer.Progress;
import org.python.indexer.Util;

import java.io.File;
import java.util.List;

/**
 * Simple proof-of-concept demo app for the indexer.  Generates a static-html
 * cross-referenced view of the code in a file or directory, using the index to
 * create links and outlines.  <p>
 *
 * The demo not attempt to show general cross references (declarations and uses
 * of a symbol) from the index, nor does it display the inferred type
 * information or generated error/warning diagnostics.  It could be made to do
 * these things, as well as be made more configurable and generally useful, with
 * additional effort.<p>
 *
 * Run it from jython source tree root dir with; e.g., to index <code>/usr/lib/python2.4/email</code>
 * <pre>
 * ant jar &amp;&amp; java -classpath ./dist/jython.jar org.python.indexer.demos.HtmlDemo /usr/lib/python2.4 /usr/lib/python2.4/email
 * </pre>
 *
 * Fully indexing the Python standard library may require a more complete build to pick up all the dependencies:
 * <pre>
 * rm -rf ./html/ &amp;&amp; ant clean &amp;&amp; ant jar &amp;&amp; ant jar-complete &amp;&amp; java -classpath ./dist/jython.jar org.python.indexer.demos.HtmlDemo /usr/lib/python2.4 /usr/lib/python2.4
 * </pre>
 *
 * You can alternately use Jython's version of the Python library.
 * The following command will index the whole thing:
 * <pre>
 * ant jar-complete &amp;&amp; java -classpath ./dist/jython.jar org.python.indexer.demos.HtmlDemo ./CPythonLib ./CPythonLib
 * </pre>
 */
public class HtmlDemo {

    private static final File OUTPUT_DIR =
            new File(new File("html").getAbsolutePath());

    private static final String CSS =
            "a {text-decoration: none; color: red}\n" +
                    "table, th, td { border: 1px solid lightgrey; padding: 5px; corner: rounded; }\n" +
                    ".builtin {color: #5b4eaf;}\n" +
                    ".comment, .block-comment {color: #005000; font-style: italic;}\n" +
                    ".constant {color: #888888;}\n" +
                    ".decorator {color: #778899;}\n" +
                    ".doc-string {color: #005000;}\n" +
                    ".error {border-bottom: 1px solid red;}\n" +
                    ".field-name {color: #2e8b57;}\n" +
                    ".function {color: #880000;}\n" +
                    ".identifier {color: #8b7765;}\n" +
                    ".info {border-bottom: 1px dotted RoyalBlue;}\n" +
                    ".keyword {color: #0000cd;}\n" +
                    ".lineno {color: #aaaaaa;}\n" +
                    ".number {color: #483d8b;}\n" +
                    ".parameter {color: #2e8b57;}\n" +
                    ".string {color: #4169e1;}\n" +
                    ".type-name {color: #4682b4;}\n" +
                    ".warning {border-bottom: 1px dotted orange;}\n";

    private  static final String JS =
            "<script language=\"JavaScript\" type=\"text/javascript\">\n" +
                    "var highlighted = new Array();\n" +
                    "function highlight()\n" +
                    "{\n" +
                    "    // clear existing highlights\n" +
                    "    for (var i = 0; i < highlighted.length; i++) {\n" +
                    "        var elm = document.getElementById(highlighted[i]);\n" +
                    "        if (elm != null) {\n" +
                    "            elm.style.backgroundColor = 'white';\n" +
                    "        }\n" +
                    "    }\n" +
                    "    highlighted = new Array();\n" +
                    "    for (var i = 0; i < arguments.length; i++) {\n" +
                    "        var elm = document.getElementById(arguments[i]);\n" +
                    "        if (elm != null) {\n" +
                    "            elm.style.backgroundColor='lightblue';\n" +
                    "        }\n" +
                    "        highlighted.push(arguments[i]);\n" +
                    "    }\n" +
                    "} </script>\n";


    private Indexer indexer;
    private String rootPath;
    private Linker linker;

    private void makeOutputDir() throws Exception {
        if (!OUTPUT_DIR.exists()) {
            OUTPUT_DIR.mkdirs();
            info("Created directory: " + OUTPUT_DIR.getAbsolutePath());
        }
    }

    private void start(File stdlib, File fileOrDir) throws Exception {
        long start = System.currentTimeMillis();

        File rootDir = fileOrDir.isFile() ? fileOrDir.getParentFile() : fileOrDir;
        rootPath = rootDir.getCanonicalPath();

        indexer = new Indexer();
        indexer.addPath(stdlib.getCanonicalPath());
        Util.msg("Building index");
        indexer.loadFileRecursive(fileOrDir.getCanonicalPath());
        indexer.finish();

        Util.msg(indexer.getStatusReport());

        long end = System.currentTimeMillis();
        Util.msg("Finished indexing in: " + Util.timeString(end - start));

        start = System.currentTimeMillis();
        generateHtml();
        end = System.currentTimeMillis();
        Util.msg("Finished generating HTML in: " + Util.timeString(end - start));
    }

    private void generateHtml() throws Exception {
        Util.msg("\nGenerating HTML");
        makeOutputDir();

        linker = new Linker(rootPath, OUTPUT_DIR);
        linker.findLinks(indexer);

        int rootLength = rootPath.length();
        Progress progress = new Progress(100, 100);

        for (String path : indexer.getLoadedFiles()) {
            if (path.startsWith(rootPath)) {
                progress.tick();
                File destFile = Util.joinPath(OUTPUT_DIR, path.substring(rootLength));
                destFile.getParentFile().mkdirs();
                String destPath = destFile.getAbsolutePath() + ".html";
                String html = markup(path);
                Util.writeFile(destPath, html);
            }
        }
        progress.end();
        Util.msg("Wrote " + indexer.getLoadedFiles().size() + " files to " + OUTPUT_DIR);
    }

    private String markup(String path) throws Exception {
        String source = Util.readFile(path);

        List<StyleRun> styles = new Styler(indexer, linker).addStyles(path, source);
        styles.addAll(linker.getStyles(path));

        String styledSource = new StyleApplier(path, source, styles).apply();
        String outline = new HtmlOutline(indexer).generate(path);

        StringBuilder sb = new StringBuilder();
        sb.append("<html><head title=\"").append(path).append("\">")
                .append("<style type='text/css'>\n").append(CSS).append("</style>\n")
                .append(JS)
                .append("</head>\n<body>\n")
                .append("<table width=100% border='1px solid gray'><tr><td valign='top'>")
                .append(outline)
                .append("</td><td>")
                .append("<pre>").append(addLineNumbers(styledSource)).append("</pre>")
                .append("</td></tr></table></body></html>");
        return sb.toString();
    }

    private String addLineNumbers(String source) {
        StringBuilder result = new StringBuilder((int)(source.length() * 1.2));
        int count = 1;
        for (String line : source.split("\n")) {
            result.append("<span class='lineno'>");
            result.append(count++);
            result.append("</span> ");
            result.append(line);
            result.append("\n");
        }
        return result.toString();
    }

    private static void abort(String msg) {
        System.err.println(msg);
        System.exit(1);
    }

    private static void info(Object msg) {
        System.out.println(msg);
    }

    private static void usage() {
        info("Usage:  java org.python.indexer.HtmlDemo <python-stdlib> <file-or-dir>");
        info("  first arg specifies the root of the python standard library");
        info("  second arg specifies file or directory for which to generate the index");
        info("Example that generates an index for just the email libraries:");
        info(" java org.python.indexer.HtmlDemo ./CPythonLib ./CPythonLib/email");
        System.exit(0);
    }

    private static File checkFile(String path) {
        File f = new File(path);
        if (!f.canRead()) {
            abort("Path not found or not readable: " + path);
        }
        return f;
    }

    public static void main(String[] args) throws Exception {
        if (args.length < 2 || args.length > 3) {
            usage();
        }

        File fileOrDir = checkFile(args[1]);
        File stdlib = checkFile(args[0]);

        if (!stdlib.isDirectory()) {
            abort("Not a directory: " + stdlib);
        }

        new HtmlDemo().start(stdlib, fileOrDir);
    }
}
