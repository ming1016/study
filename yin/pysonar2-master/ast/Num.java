package org.python.indexer.ast;

import org.python.core.PyComplex;
import org.python.core.PyFloat;
import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.types.Type;

public class Num extends Node {

    static final long serialVersionUID = -425866329526788376L;

    public Object n;

    public Num(int n) {
        this.n = n;
    }

    public Num(Object n, int start, int end) {
        super(start, end);
        this.n = n;
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        if (n instanceof PyFloat) {
            return Indexer.idx.builtins.BaseFloat;
        } else if (n instanceof PyComplex){
            return Indexer.idx.builtins.BaseComplex;
        } else {
            return Indexer.idx.builtins.BaseNum; 
        }
    }

    @Override
    public String toString() {
        return "<Num:" + n + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        v.visit(this);
    }
}
