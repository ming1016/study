package org.python.indexer.ast;

import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.types.Type;

public class Break extends Node {

    static final long serialVersionUID = 2114759731430768793L;

    public Break() {
    }

    public Break(int start, int end) {
        super(start, end);
    }

    @Override
    public String toString() {
        return "<Break>";
    }

    @Override
    public void visit(NodeVisitor v) {
        v.visit(this);
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        return Indexer.idx.builtins.None;
    }
}
