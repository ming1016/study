package org.python.indexer.ast;

import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.types.Type;
import org.python.indexer.types.UnionType;

public class IfExp extends Node {

    static final long serialVersionUID = 8516153579808365723L;

    public Node test;
    public Node body;
    public Node orelse;

    public IfExp(Node test, Node body, Node orelse) {
        this(test, body, orelse, 0, 1);
    }

    public IfExp(Node test, Node body, Node orelse, int start, int end) {
        super(start, end);
        this.test = test;
        this.body = body;
        this.orelse = orelse;
        addChildren(test, body, orelse);
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        Type type1, type2;
        resolveExpr(test, s, tag);
        int newTag = Indexer.idx.newThread();
        if (body != null) {
            type1 = resolveExpr(body, s, newTag);
        } else {
            type1 = Indexer.idx.builtins.Cont;
        }
        if (orelse != null) {
            type2 = resolveExpr(orelse, s, -newTag);
        } else {
            type2 = Indexer.idx.builtins.Cont;
        }
        return UnionType.union(type1, type2);
    }

    @Override
    public String toString() {
        return "<IfExp:" + start() + ":" + test + ":" + body + ":" + orelse + ">";
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
