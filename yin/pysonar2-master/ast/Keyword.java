package org.python.indexer.ast;

import org.python.indexer.Scope;
import org.python.indexer.types.Type;

/**
 * Represents a keyword argument (name=value) in a function call.
 */
public class Keyword extends Node {

    static final long serialVersionUID = 9031782645918578266L;

    public String arg;
    public Node value;

    public Keyword(String arg, Node value) {
        this(arg, value, 0, 1);
    }

    public Keyword(String arg, Node value, int start, int end) {
        super(start, end);
        this.arg = arg;
        this.value = value;
        addChildren(value);
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        return setType(resolveExpr(value, s, tag));
    }

    public String getArg() {
        return arg;
    }

    public Node getValue() {
        return value;
    }

    @Override
    public String toString() {
        return "<Keyword:" + arg + ":" + value + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNode(value, v);
        }
    }
}
