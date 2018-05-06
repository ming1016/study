package org.python.indexer.ast;

import org.python.indexer.Scope;
import org.python.indexer.types.Type;

public class Index extends Node {

    static final long serialVersionUID = -8920941673115420849L;

    public Node value;

    public Index(Node n) {
        this(n, 0, 1);
    }

    public Index(Node n, int start, int end) {
        super(start, end);
        this.value = n;
        addChildren(n);
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        return resolveExpr(value, s, tag);
    }

    @Override
    public String toString() {
        return "<Index:" + value + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNode(value, v);
        }
    }
}
