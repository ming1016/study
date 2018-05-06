package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.ListType;
import org.yinwang.pysonar.types.Type;

import java.util.List;


public class PyList extends Sequence {

    public PyList(@NotNull List<Node> elts, String file, int start, int end) {
        super(elts, file, start, end);
    }


    @NotNull
    @Override
    public Type transform(State s) {
        if (elts.size() == 0) {
            return new ListType();  // list<unknown>
        }

        ListType listType = new ListType();
        for (Node elt : elts) {
            listType.add(transformExpr(elt, s));
            if (elt instanceof Str) {
                listType.addValue(((Str) elt).value);
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
