package org.python.indexer.ast;

import org.python.indexer.Scope;
import org.python.indexer.types.TupleType;
import org.python.indexer.types.Type;

import java.util.List;

public class Tuple extends Sequence {

    static final long serialVersionUID = -7647425038559142921L;

    public Tuple(List<Node> elts) {
        this(elts, 0, 1);
    }

    public Tuple(List<Node> elts, int start, int end) {
        super(elts, start, end);
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        TupleType thisType = new TupleType();
        for (Node e : elts) {
            thisType.add(resolveExpr(e, s, tag));
        }
        return setType(thisType);
    }

    @Override
    public String toString() {
        return "<Tuple:" + start() + ":" + elts + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNodeList(elts, v);
        }
    }
}
