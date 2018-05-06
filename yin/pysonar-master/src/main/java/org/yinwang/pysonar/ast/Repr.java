package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.Type;


public class Repr extends Node {

    public Node value;


    public Repr(Node n, String file, int start, int end) {
        super(file, start, end);
        this.value = n;
        addChildren(n);
    }


    @NotNull
    @Override
    public Type transform(State s) {
        if (value != null) {
            transformExpr(value, s);
        }
        return Type.STR;
    }


    @NotNull
    @Override
    public String toString() {
        return "<Repr:" + value + ">";
    }

}
