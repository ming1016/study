package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.ListType;
import org.yinwang.pysonar.types.Type;

import java.util.List;


public class PySet extends Sequence {

    public PySet(List<Node> elts, String file, int start, int end) {
        super(elts, file, start, end);
    }


    @NotNull
    @Override
    public Type transform(State s) {
        if (elts.size() == 0) {
            return new ListType();
        }

        ListType listType = null;
        for (Node elt : elts) {
            if (listType == null) {
                listType = new ListType(transformExpr(elt, s));
            } else {
                listType.add(transformExpr(elt, s));
            }
        }

        return listType;
    }


    @NotNull
    @Override
    public String toString() {
        return "<List:" + start + ":" + elts + ">";
    }

}
