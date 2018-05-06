package org.python.indexer.ast;

import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.types.Type;

public class AugAssign extends Node {

    static final long serialVersionUID = -6479618862099506199L;

    public Node target;
    public Node value;
    public String op;

    public AugAssign(Node target, Node value, String op) {
        this(target, value, op, 0, 1);
    }

    public AugAssign(Node target, Node value, String op, int start, int end) {
        super(start, end);
        this.target = target;
        this.value = value;
        this.op = op;
        addChildren(target, value);
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        resolveExpr(target, s, tag);
        resolveExpr(value, s, tag);
        return Indexer.idx.builtins.Cont;
    }

    @Override
    public String toString() {
        return "<AugAssign:" + target + " " + op + "= " + value + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNode(target, v);
            visitNode(value, v);
        }
    }
}
