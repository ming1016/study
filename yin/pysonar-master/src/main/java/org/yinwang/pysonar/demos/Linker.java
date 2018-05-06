package org.yinwang.pysonar.demos;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.yinwang.pysonar.*;
import org.yinwang.pysonar.ast.Node;
import org.yinwang.pysonar.types.ModuleType;

import java.io.File;
import java.util.*;
import java.util.Map.Entry;
import java.util.regex.Pattern;


/**
 * Collects per-file hyperlinks, as well as styles that require the
 * symbol table to resolve properly.
 */
class Linker {

    private static final Pattern CONSTANT = Pattern.compile("[A-Z_][A-Z0-9_]*");

    // Map of file-path to semantic styles & links for that path.
    @NotNull
    private Map<String, List<Style>> fileStyles = new HashMap<>();

    private File outDir;  // where we're generating the output html
    private String rootPath;

    // prevent duplication in def and ref links
    Set<Object> seenDef = new HashSet<>();
    Set<Object> seenRef = new HashSet<>();


    /**
     * Constructor.
     *
     * @param root   the root of the directory tree being indexed
     * @param outdir the html output directory
     */
    public Linker(String root, File outdir) {
        rootPath = root;
        outDir = outdir;
    }


    public void findLinks(@NotNull Analyzer analyzer) {
        _.msg("Adding xref links");
        Progress progress = new Progress(analyzer.getAllBindings().size(), 50);

        for (Binding b : analyzer.getAllBindings()) {
            if (b.kind != Binding.Kind.MODULE) {
                if (Analyzer.self.hasOption("debug")) {
                    processDefDebug(b);
                } else {
                    processDef(b);
                }
                progress.tick();
            }
        }

        // highlight definitions
        _.msg("\nAdding ref links");
        progress = new Progress(analyzer.getReferences().size(), 50);

        for (Entry<Node, List<Binding>> e : analyzer.getReferences().entrySet()) {
            if (Analyzer.self.hasOption("debug")) {
                processRefDebug(e.getKey(), e.getValue());
            } else {
                processRef(e.getKey(), e.getValue());
            }
            progress.tick();
        }

        if (Analyzer.self.hasOption("report")) {
            for (List<Diagnostic> ld : analyzer.semanticErrors.values()) {
                for (Diagnostic d : ld) {
                    processDiagnostic(d);
                }
            }
        }
    }


    private void processDef(@NotNull Binding binding) {
        String qname = binding.qname;
        int hash = binding.hashCode();

        if (binding.isURL() || binding.start < 0 || seenDef.contains(hash)) {
            return;
        }

        seenDef.add(hash);
        Style style = new Style(Style.Type.ANCHOR, binding.start, binding.end);
        style.message = binding.type.toString();
        style.url = binding.qname;
        style.id = qname;
        addFileStyle(binding.getFile(), style);
    }


    private void processDefDebug(@NotNull Binding binding) {
        int hash = binding.hashCode();

        if (binding.isURL() || binding.start < 0 || seenDef.contains(hash)) {
            return;
        }

        seenDef.add(hash);
        Style style = new Style(Style.Type.ANCHOR, binding.start, binding.end);
        style.message = binding.type.toString();
        style.url = binding.qname;
        style.id = "" + Math.abs(binding.hashCode());

        Set<Node> refs = binding.refs;
        style.highlight = new ArrayList<>();


        for (Node r : refs) {
            style.highlight.add(Integer.toString(Math.abs(r.hashCode())));
        }
        addFileStyle(binding.getFile(), style);
    }


    void processRef(@NotNull Node ref, @NotNull List<Binding> bindings) {
        String qname = bindings.iterator().next().qname;
        int hash = ref.hashCode();

        if (!seenRef.contains(hash)) {
            seenRef.add(hash);

            Style link = new Style(Style.Type.LINK, ref.start, ref.end);
            link.id = qname;

            List<String> typings = new ArrayList<>();
            for (Binding b : bindings) {
                typings.add(b.type.toString());
            }
            link.message = _.joinWithSep(typings, " | ", "{", "}");

            // Currently jump to the first binding only. Should change to have a
            // hover menu or something later.
            String path = ref.file;
            if (path != null) {
                for (Binding b : bindings) {
                    if (link.url == null) {
                        link.url = toURL(b, path);
                    }

                    if (link.url != null) {
                        addFileStyle(path, link);
                        break;
                    }
                }
            }
        }
    }


    void processRefDebug(@NotNull Node ref, @NotNull List<Binding> bindings) {
        int hash = ref.hashCode();

        if (!seenRef.contains(hash)) {
            seenRef.add(hash);

            Style link = new Style(Style.Type.LINK, ref.start, ref.end);
            link.id = Integer.toString(Math.abs(hash));

            List<String> typings = new ArrayList<>();
            for (Binding b : bindings) {
                typings.add(b.type.toString());
            }
            link.message = _.joinWithSep(typings, " | ", "{", "}");

            link.highlight = new ArrayList<>();
            for (Binding b : bindings) {
                link.highlight.add(Integer.toString(Math.abs(b.hashCode())));
            }

            // Currently jump to the first binding only. Should change to have a
            // hover menu or something later.
            String path = ref.file;
            if (path != null) {
                for (Binding b : bindings) {
                    if (link.url == null) {
                        link.url = toURL(b, path);
                    }

                    if (link.url != null) {
                        addFileStyle(path, link);
                        break;
                    }
                }
            }
        }
    }


    /**
     * Returns the styles (links and extra styles) generated for a given file.
     *
     * @param path an absolute source path
     * @return a possibly-empty list of styles for that path
     */
    public List<Style> getStyles(String path) {
        return stylesForFile(path);
    }


    private List<Style> stylesForFile(String path) {
        List<Style> styles = fileStyles.get(path);
        if (styles == null) {
            styles = new ArrayList<>();
            fileStyles.put(path, styles);
        }
        return styles;
    }


    private void addFileStyle(String path, Style style) {
        stylesForFile(path).add(style);
    }


    /**
     * Add additional highlighting styles based on information not evident from
     * the AST.
     */
    private void addSemanticStyles(@NotNull Binding nb) {
        boolean isConst = CONSTANT.matcher(nb.name).matches();
        switch (nb.kind) {
            case SCOPE:
                if (isConst) {
                    addSemanticStyle(nb, Style.Type.CONSTANT);
                }
                break;
            case VARIABLE:
                addSemanticStyle(nb, isConst ? Style.Type.CONSTANT : Style.Type.IDENTIFIER);
                break;
            case PARAMETER:
                addSemanticStyle(nb, Style.Type.PARAMETER);
                break;
            case CLASS:
                addSemanticStyle(nb, Style.Type.TYPE_NAME);
                break;
        }
    }


    private void addSemanticStyle(@NotNull Binding binding, Style.Type type) {
        String path = binding.getFile();
        if (path != null) {
            addFileStyle(path, new Style(type, binding.start, binding.end));
        }
    }


    private void processDiagnostic(@NotNull Diagnostic d) {
        Style style = new Style(Style.Type.WARNING, d.start, d.end);
        style.message = d.msg;
        style.url = d.file;
        addFileStyle(d.file, style);
    }


    @Nullable
    private String toURL(@NotNull Binding binding, String filename) {

        if (binding.isBuiltin()) {
            return binding.getURL();
        }

        String destPath;
        if (binding.type instanceof ModuleType) {
            destPath = binding.type.asModuleType().file;
        } else {
            destPath = binding.getFile();
        }

        if (destPath == null) {
            return null;
        }

        String anchor = "#" + binding.qname;
        if (binding.getFirstFile().equals(filename)) {
            return anchor;
        }

        if (destPath.startsWith(rootPath)) {
            String relpath;
            if (filename != null) {
                relpath = _.relPath(filename, destPath);
            } else {
                relpath = destPath;
            }

            if (relpath != null) {
                return relpath + ".html" + anchor;
            } else {
                return anchor;
            }
        } else {
            return "file://" + destPath + anchor;
        }
    }

}
