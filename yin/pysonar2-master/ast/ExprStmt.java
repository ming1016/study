package org.python.indexer.ast;

import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.types.Type;

/**
 * Expression statement.
 */
public class ExprStmt extends Node {

    static final long serialVersionUID = 7366113211576923188L;

    public Node value;

    public ExprStmt(Node n) {
        this(n, 0, 1);
    }

    public ExprStmt(Node n, int start, int end) {
        super(start, end);
        this.value = n;
        addChildren(n);
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        if (value != null) resolveExpr(value, s, tag);
        return Indexer.idx.builtins.Cont;
    }

    @Override
    public String toString() {
        return "<ExprStmt:" + value + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNode(value, v);
        }
    }
}
