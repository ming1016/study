package org.python.indexer.ast;

import org.python.indexer.Scope;
import org.python.indexer.types.Type;

public class With extends Node {

    static final long serialVersionUID = 560128079414064421L;

    public Node optional_vars;
    public Node context_expr;
    public Block body;

    public With(Node optional_vars, Node context_expr, Block body) {
        this(optional_vars, context_expr, body, 0, 1);
    }

    public With(Node optional_vars, Node context_expr, Block body, int start, int end) {
        super(start, end);
        this.optional_vars = optional_vars;
        this.context_expr = context_expr;
        this.body = body;
        addChildren(optional_vars, context_expr, body);
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        Type val = resolveExpr(context_expr, s, tag);
        NameBinder.bind(s, optional_vars, val, tag);
        return setType(resolveExpr(body, s, tag));
    }

    @Override
    public String toString() {
        return "<With:" + context_expr + ":" + optional_vars + ":" + body + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNode(optional_vars, v);
            visitNode(context_expr, v);
            visitNode(body, v);
        }
    }
}
