package org.python.indexer.ast;

import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.types.Type;

public class Return extends Node {

    static final long serialVersionUID = 5795610129307339141L;

    public Node value;

    public Return(Node n) {
        this(n, 0, 1);
    }

    public Return(Node n, int start, int end) {
        super(start, end);
        this.value = n;
        addChildren(n);
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        if (value == null) {
            return Indexer.idx.builtins.None;
        } else {
            return resolveExpr(value, s, tag);
        }
    }

    @Override
    public String toString() {
        return "<Return:" + value + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNode(value, v);
        }
    }
}
