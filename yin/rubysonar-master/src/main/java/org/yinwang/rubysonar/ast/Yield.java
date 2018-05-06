package org.yinwang.rubysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.rubysonar.State;
import org.yinwang.rubysonar.types.ListType;
import org.yinwang.rubysonar.types.Type;


public class Yield extends Node {

    public Node value;


    public Yield(Node n, String file, int start, int end) {
        super(file, start, end);
        this.value = n;
        addChildren(n);
    }


    @NotNull
    @Override
    public Type transform(State s) {
        if (value != null) {
            return new ListType(transformExpr(value, s));
        } else {
            return Type.NIL;
        }
    }


    @NotNull
    @Override
    public String toString() {
        return "(yield " + value + ")";
    }

}
