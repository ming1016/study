package org.python.indexer.demos;

import org.antlr.runtime.*;
import org.python.antlr.PythonLexer;
import org.python.antlr.PythonTree;
import org.python.antlr.RecordingErrorHandler;
import org.python.indexer.Indexer;
import org.python.indexer.ast.*;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * Decorates Python source with style runs from the index.
 */
class Styler extends DefaultNodeVisitor {

    static final Pattern BUILTIN =
            Pattern.compile("None|True|False|NotImplemented|Ellipsis|__debug__");

    /**
     * Matches the start of a triple-quote string.
     */
    private static final Pattern TRISTRING_PREFIX =
            Pattern.compile("^[ruRU]{0,2}['\"]{3}");

    private Indexer indexer;
    private String source;
    private String path;
    private List<StyleRun> styles = new ArrayList<StyleRun>();
    private Linker linker;

    /** Offsets of doc strings found by node visitor. */
    private Set<Integer> docOffsets = new HashSet<Integer>();

    public Styler(Indexer idx, Linker linker) {
        this.indexer = idx;
        this.linker = linker;
    }

    /**
     * Entry point for decorating a source file.
     * @param path absolute file path
     * @param src file contents
     */
    public List<StyleRun> addStyles(String path, String src) throws Exception {
        this.path = path;
        source = src;
        Module m = indexer.getAstForFile(path);
        if (m != null) {
            m.visit(this);
            highlightLexicalTokens();
        }
        return styles;
    }

    @Override
    public boolean visit(Name n) {
        Node parent = n.getParent();
        if (parent instanceof FunctionDef) {
            FunctionDef fn = (FunctionDef)parent;
            if (n == fn.name) {
                addStyle(n, StyleRun.Type.FUNCTION);
            } else if (n == fn.kwargs || n == fn.varargs) {
                addStyle(n, StyleRun.Type.PARAMETER);
            }
            return true;
        }

        if (BUILTIN.matcher(n.getId()).matches()) {
            addStyle(n, StyleRun.Type.BUILTIN);
            return true;
        }

        return true;
    }

    @Override
    public boolean visit(Num n) {
        addStyle(n, StyleRun.Type.NUMBER);
        return true;
    }

    @Override
    public boolean visit(Str n) {
        String s = sourceString(n.start(), n.end());
        if (TRISTRING_PREFIX.matcher(s).lookingAt()) {
            addStyle(n.start(), n.end() - n.start(), StyleRun.Type.DOC_STRING);
            docOffsets.add(n.start());  // don't re-highlight as a string
            highlightDocString(n);
        }
        return true;
    }

    private void highlightDocString(Str node) {
        String s = sourceString(node.start(), node.end());
        DocStringParser dsp = new DocStringParser(s, node, linker);
        dsp.setResolveReferences(true);
        styles.addAll(dsp.highlight());
    }

    /**
     * Use scanner to find keywords, strings and comments.
     */
    private void highlightLexicalTokens() {
        RecognizerSharedState state = new RecognizerSharedState();
        state.errorRecovery = true;  // don't issue 10 billion errors

        PythonLexer lex = new PythonLexer(
            new ANTLRStringStream(source) {
                @Override
                public String getSourceName() {
                    return path;
                }
            },
            state);

        lex.setErrorHandler(new RecordingErrorHandler() {
                @Override
                public void error(String message, PythonTree t) {
                    // don't println
                }
                @Override
                public void reportError(BaseRecognizer br, RecognitionException re) {
                    // don't println
                }
            });

        Token tok;
        while ((tok = lex.nextToken()) != Token.EOF_TOKEN) {
            switch (tok.getType()) {
                case PythonLexer.STRING: {
                    int beg = ((CommonToken)tok).getStartIndex();
                    int end = ((CommonToken)tok).getStopIndex();
                    if (!docOffsets.contains(beg)) {
                        addStyle(beg, end - beg + 1, StyleRun.Type.STRING);
                    }
                    break;
                }
                case PythonLexer.COMMENT: {
                    int beg = ((CommonToken)tok).getStartIndex();
                    int end = ((CommonToken)tok).getStopIndex();
                    String comment = tok.getText();
                    addStyle(beg, end - beg + 1, StyleRun.Type.COMMENT);
                    break;
                }
                case PythonLexer.AND:
                case PythonLexer.AS:
                case PythonLexer.ASSERT:
                case PythonLexer.BREAK:
                case PythonLexer.CLASS:
                case PythonLexer.CONTINUE:
                case PythonLexer.DEF:
                case PythonLexer.DELETE:
                case PythonLexer.ELIF:
                case PythonLexer.EXCEPT:
                case PythonLexer.FINALLY:
                case PythonLexer.FOR:
                case PythonLexer.FROM:
                case PythonLexer.GLOBAL:
                case PythonLexer.IF:
                case PythonLexer.IMPORT:
                case PythonLexer.IN:
                case PythonLexer.IS:
                case PythonLexer.LAMBDA:
                case PythonLexer.NOT:
                case PythonLexer.OR:
                case PythonLexer.ORELSE:
                case PythonLexer.PASS:
                case PythonLexer.PRINT:
                case PythonLexer.RAISE:
                case PythonLexer.RETURN:
                case PythonLexer.TRY:
                case PythonLexer.WHILE:
                case PythonLexer.WITH:
                case PythonLexer.YIELD: {
                    int beg = ((CommonToken)tok).getStartIndex();
                    int end = ((CommonToken)tok).getStopIndex();
                    addStyle(beg, end - beg + 1, StyleRun.Type.KEYWORD);
                    break;
                }
            }
        }
    }

    private void addStyle(Node e, int start, int len, StyleRun.Type type) {
        if (e == null || e.getFile() == null) {  // if it's an NUrl, for instance
            return;
        }
        addStyle(start, len, type);
    }

    private void addStyle(Node e, StyleRun.Type type) {
        if (e != null) {
            addStyle(e, e.start(), e.end() - e.start(), type);
        }
    }

    private void addStyle(int beg, int len, StyleRun.Type type) {
        styles.add(new StyleRun(type, beg, len));
    }

    private String sourceString(Node e) {
        return sourceString(e.start(), e.end());
    }

    private String sourceString(int beg, int end) {
        int a = Math.max(beg, 0);
        int b = Math.min(end, source.length());
        b = Math.max(b, 0);
        try {
            return source.substring(a, b);
        } catch (StringIndexOutOfBoundsException sx) {
            System.out.println("whoops: beg=" + a + ", end=" + b + ", len=" + source.length());
            return "";
        }
    }
}
