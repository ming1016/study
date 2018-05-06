package org.python.indexer.ast;

import org.python.indexer.Scope;
import org.python.indexer.types.DictType;
import org.python.indexer.types.Type;

import java.util.List;

public class Dict extends Node {

    static final long serialVersionUID = 318144953740238374L;

    public List<Node> keys;
    public List<Node> values;

    public Dict(List<Node> keys, List<Node> values) {
        this(keys, values, 0, 1);
    }

    public Dict(List<Node> keys, List<Node> values, int start, int end) {
        super(start, end);
        this.keys = keys;
        this.values = values;
        addChildren(keys);
        addChildren(values);
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        Type keyType = resolveListAsUnion(keys, s, tag);
        Type valType = resolveListAsUnion(values, s, tag);
        return new DictType(keyType, valType);
    }

    @Override
    public String toString() {
        return "<Dict>";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            // XXX:  should visit in alternating order
            visitNodeList(keys, v);
            visitNodeList(values, v);
        }
    }
}
