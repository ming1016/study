package org.yinwang.rubysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.rubysonar.State;
import org.yinwang.rubysonar.types.ListType;
import org.yinwang.rubysonar.types.Type;

import java.util.List;


public class Array extends Node {

    @NotNull
    public List<Node> elts;


    public Array(@NotNull List<Node> elts, String file, int start, int end) {
        super(file, start, end);
        this.elts = elts;
        addChildren(elts);
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
        return "(array:" + elts + ")";
    }

}
