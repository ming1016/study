package org.python.indexer.ast;

import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.types.Type;

public class Ellipsis extends Node {

    static final long serialVersionUID = 4148534089952252511L;

    public Ellipsis() {
    }

    public Ellipsis(int start, int end) {
        super(start, end);
    }

    @Override
    public String toString() {
        return "<Ellipsis>";
    }
    
    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        return Indexer.idx.builtins.None;
    }

    @Override
    public void visit(NodeVisitor v) {
        v.visit(this);
    }
}
