package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.ListType;
import org.yinwang.pysonar.types.Type;

import java.util.List;


public class SetComp extends Node {

    public Node elt;
    public List<Comprehension> generators;


    public SetComp(Node elt, List<Comprehension> generators, String file, int start, int end) {
        super(file, start, end);
        this.elt = elt;
        this.generators = generators;
        addChildren(elt);
        addChildren(generators);
    }


    @NotNull
    @Override
    public Type transform(State s) {
        resolveList(generators, s);
        return new ListType(transformExpr(elt, s));
    }


    @NotNull
    @Override
    public String toString() {
        return "<NSetComp:" + start + ":" + elt + ">";
    }

}
