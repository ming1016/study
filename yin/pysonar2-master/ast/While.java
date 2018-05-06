package org.python.indexer.ast;

import org.python.indexer.Scope;
import org.python.indexer.types.Type;

public class While extends Node {

    static final long serialVersionUID = -2419753875936526587L;

    public Node test;
    public Block body;
    public Block orelse;

    public While(Node test, Block body, Block orelse) {
        this(test, body, orelse, 0, 1);
    }

    public While(Node test, Block body, Block orelse, int start, int end) {
        super(start, end);
        this.test = test;
        this.body = body;
        this.orelse = orelse;
        addChildren(test, body, orelse);
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        resolveExpr(test, s, tag);
        if (body != null) setType(resolveExpr(body, s, tag));
        if (orelse != null) addType(resolveExpr(orelse, s, tag));
        return getType();
    }

    @Override
    public String toString() {
        return "<While:" + test + ":" + body + ":" + orelse + ":" + start() + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNode(test, v);
            visitNode(body, v);
            visitNode(orelse, v);
        }
    }
}
