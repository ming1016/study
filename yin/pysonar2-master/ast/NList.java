package org.python.indexer.ast;

import org.python.indexer.Scope;
import org.python.indexer.Util;
import org.python.indexer.types.ListType;
import org.python.indexer.types.Type;

import java.util.List;

public class NList extends Sequence {

    static final long serialVersionUID = 6623743056841822992L;

    public NList(List<Node> elts) {
        this(elts, 0, 1);
    }

    public NList(List<Node> elts, int start, int end) {
        super(elts, start, end);
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        if (elts.size() == 0) {
            return setType(new ListType());  // list<unknown>
        }

        ListType listType = new ListType();
        for (Node elt : elts) {
            listType.add(resolveExpr(elt, s, tag));
        }

        setType(listType);
        return getType();
    }

    @Override
    public String toString() {
        return "<List:" + start() + ":" + elts + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNodeList(elts, v);
        }
    }
}
