package org.python.indexer.ast;

import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.types.Type;

public class Str extends Node {

    static final long serialVersionUID = -6092297133232624953L;

    private String value;

    public Str() {
        this("");
    }

    public Str(Object value) {
        this(value, 0, 1);
    }

    public Str(Object value, int start, int end) {
        super(start, end);

        if (value == null) {
            this.value = "";
        } else {
            this.value = value.toString();
        }
    }

    public String getStr() {
        return value;
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        return Indexer.idx.builtins.BaseStr;
    }

    @Override
    public String toString() {
        return "<Str>";
    }

    @Override
    public void visit(NodeVisitor v) {
        v.visit(this);
    }
}
