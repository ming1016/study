package org.python.indexer.ast;

import org.python.indexer.Scope;
import org.python.indexer.types.Type;

import java.util.List;

public class Delete extends Node {

    static final long serialVersionUID = -2223255555054110766L;

    public List<Node> targets;

    public Delete(List<Node> elts) {
        this(elts, 0, 1);
    }

    public Delete(List<Node> elts, int start, int end) {
        super(start, end);
        this.targets = elts;
        addChildren(elts);
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        for (Node n : targets) {
            resolveExpr(n, s, tag);
            if (n instanceof Name) {
                s.remove(n.asName().getId());
            }
        }
        return getType();
    }

    @Override
    public String toString() {
        return "<Delete:" + targets + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNodeList(targets, v);
        }
    }
}
