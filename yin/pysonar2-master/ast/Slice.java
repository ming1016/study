package org.python.indexer.ast;

import org.python.indexer.Scope;
import org.python.indexer.types.ListType;
import org.python.indexer.types.Type;

public class Slice extends Node {

    static final long serialVersionUID = 8685364390631331543L;

    public Node lower;
    public Node step;
    public Node upper;

    public Slice(Node lower, Node step, Node upper) {
        this(lower, step, upper, 0, 1);
    }

    public Slice(Node lower, Node step, Node upper, int start, int end) {
        super(start, end);
        this.lower = lower;
        this.step = step;
        this.upper = upper;
        addChildren(lower, step, upper);
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        if (lower != null) resolveExpr(lower, s, tag);
        if (step != null) resolveExpr(step, s, tag);
        if (upper != null) resolveExpr(upper, s, tag);
        return new ListType();
    }

    @Override
    public String toString() {
        return "<Slice:" + lower + ":" + step + ":" + upper + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNode(lower, v);
            visitNode(step, v);
            visitNode(upper, v);
        }
    }
}
