package org.python.indexer.ast;

import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.types.Type;

public class Exec extends Node {

    static final long serialVersionUID = -1840017898177850339L;

    public Node body;
    public Node globals;
    public Node locals;

    public Exec(Node body, Node globals, Node locals) {
        this(body, globals, locals, 0, 1);
    }

    public Exec(Node body, Node globals, Node locals, int start, int end) {
        super(start, end);
        this.body = body;
        this.globals = globals;
        this.locals = locals;
        addChildren(body, globals, locals);
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        if (body != null) resolveExpr(body, s, tag);
        if (globals != null) resolveExpr(globals, s, tag);
        if (locals != null) resolveExpr(locals, s, tag);
        return Indexer.idx.builtins.Cont;
    }

    @Override
    public String toString() {
        return "<Exec:" + start() + ":" + end() + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNode(body, v);
            visitNode(globals, v);
            visitNode(locals, v);
        }
    }
}
