package org.python.indexer.ast;

import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.types.Type;

public class Repr extends Node {

    static final long serialVersionUID = -7920982714296311413L;

    public Node value;

    public Repr(Node n) {
        this(n, 0, 1);
    }

    public Repr(Node n, int start, int end) {
        super(start, end);
        this.value = n;
        addChildren(n);
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        if (value != null) resolveExpr(value, s, tag);
        return setType(Indexer.idx.builtins.BaseStr);
    }

    @Override
    public String toString() {
        return "<Repr:" + value +  ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNode(value, v);
        }
    }
}
