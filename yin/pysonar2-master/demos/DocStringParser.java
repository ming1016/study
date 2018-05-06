package org.python.indexer.demos;

import org.python.indexer.*;
import org.python.indexer.ast.Str;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Scans doc strings looking for interesting stuff to highlight or hyperlink.
 */
class DocStringParser {

    /**
     * Only try to resolve possible qnames of at least this length.
     * Helps cut down on noise.
     */
    private static final int MIN_TYPE_NAME_LENGTH = 4;

    /**
     * Matches an unqualified Python identifier.
     */
    private static final String IDENT = "[a-zA-Z_][a-zA-Z0-9_]*";

    /**
     * Matches probable type names.  Does loose matching; caller must do more checks.
     */
    private static final Pattern TYPE_NAME =
            Pattern.compile(
                // any two or more identifiers joined with dots.
                IDENT + "\\." + IDENT + "(?:\\." + IDENT + ")*\\b"

                // a capitalized word that isn't all-caps
                + "|\\b[A-Z][a-zA-Z0-9_]*?[a-z][a-zA-Z0-9_]*\\b"

                // an __identifier__
                + "|(?<![a-zA-Z0-9_])?__[a-zA-Z][a-zA-Z_]*?__");

    private boolean resolveReferences = true;
    private int docOffset;  // doc string start offset
    private String docString;  // the doc string text
    private Scope scope;  // scope for name lookups
    private String file;  // file containing the doc string

    private Set<Integer> offsets = new HashSet<Integer>();  // styles we've already added
    private List<StyleRun> styles = new ArrayList<StyleRun>();
    private Linker linker;

    /**
     * Constructor.
     * @param comment the doc string or doc-comment text
     * @param node the AST node for the doc string
     */
    public DocStringParser(String comment, Str node, Linker linker) {
        docOffset = node.start();
        docString = comment;
        scope = node.getEnclosingNamespace();
        file = node.getFile();
        this.linker = linker;
    }

    /**
     * Configures whether to highlight syntactically or semantically.
     *
     * @param resolve {@code true} to do name resolution, {@code false}
     *        to guess purely based on syntax in the doc string.
     *        Pass {@code false} if you're using the highlighter to
     *        syntax-highlight a file (i.e. no code graph or indexing.)
     */
    public void setResolveReferences(boolean resolve) {
        resolveReferences = resolve;
    }

    public boolean isResolvingReferences() {
        return resolveReferences;
    }

    /**
     * Main entry point.
     *
     * @return the non-{@code null} but possibly empty list of additional
     *         styles for the doc string.
     */
    public List<StyleRun> highlight() {
        if (resolveReferences) {
            scanCommentForTypeNames();
        }

        return styles;
    }

    /**
     * Try to match potential type names against the code graph.
     * If any match, graph references and styles are added for them.
     */
    private void scanCommentForTypeNames() {
        Matcher m = TYPE_NAME.matcher(docString);
        while (m.find()) {
            String qname = m.group();
            int beg = m.start() + docOffset;

            // If we already added a style here, skip this one.
            if (offsets.contains(beg)) {
                continue;
            }

            // Arbitrarily require them to be at least N chars, to reduce noise.
            if (qname.length() < MIN_TYPE_NAME_LENGTH) {
                continue;
            }

            checkForReference(beg, qname);
        }
    }

    /**
     * Look for the name in the current scope.  If found, and its
     * qname is a valid binding in the graph, record a reference.
     */
    private void checkForReference(int offset, String qname) {
        Binding nb;
        if (qname.indexOf('.') == -1) {
            nb = scope.lookup(qname);
            if (nb == null) {
                nb = Indexer.idx.globaltable.lookup(qname);
            }
        } else {
            nb = Indexer.idx.lookupFirstBinding(qname);
        }

        if (nb != null) {
            linker.processRef(new Ref(file, offset, qname), nb);
        }
    }

    private void addStyle(int beg, int len, StyleRun.Type type) {
        styles.add(new StyleRun(type, beg, len));
        offsets.add(beg);
    }
}
