package org.yinwang.rubysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.rubysonar.State;
import org.yinwang.rubysonar.types.Type;


public class Return extends Node {

    public Node value;


    public Return(Node n, String file, int start, int end) {
        super(file, start, end);
        this.value = n;
        addChildren(n);
    }


    @NotNull
    @Override
    public Type transform(State s) {
        if (value == null) {
            return Type.NIL;
        } else {
            return transformExpr(value, s);
        }
    }


    @NotNull
    @Override
    public String toString() {
        return "(return:" + value + ")";
    }

}
