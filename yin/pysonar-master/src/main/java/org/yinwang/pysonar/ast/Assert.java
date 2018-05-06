package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.Type;


public class Assert extends Node {

    public Node test;
    public Node msg;


    public Assert(Node test, Node msg, String file, int start, int end) {
        super(file, start, end);
        this.test = test;
        this.msg = msg;
        addChildren(test, msg);
    }


    @NotNull
    @Override
    public Type transform(State s) {
        if (test != null) {
            transformExpr(test, s);
        }
        if (msg != null) {
            transformExpr(msg, s);
        }
        return Type.CONT;
    }


    @NotNull
    @Override
    public String toString() {
        return "<Assert:" + test + ":" + msg + ">";
    }

}
