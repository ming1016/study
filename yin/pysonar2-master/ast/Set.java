package org.python.indexer.ast;

import org.python.indexer.Scope;
import org.python.indexer.types.ListType;
import org.python.indexer.types.Type;

import java.util.List;

public class Set extends Sequence {

    static final long serialVersionUID = 6623743056841822992L;

    public Set(List<Node> elts) {
        this(elts, 0, 1);
    }

    public Set(List<Node> elts, int start, int end) {
        super(elts, start, end);
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        if (elts.size() == 0) {
            return setType(new ListType());  // list<unknown>
        }

        ListType listType = null;
        for (Node elt : elts) {
            if (listType == null) {
                listType = new ListType(resolveExpr(elt, s, tag));
            } else {
                listType.add(resolveExpr(elt, s, tag));
            }
        }
        if (listType != null) {
            setType(listType);
        }
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
