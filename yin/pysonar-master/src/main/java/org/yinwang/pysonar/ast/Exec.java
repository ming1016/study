package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.Type;


public class Exec extends Node {

    public Node body;
    public Node globals;
    public Node locals;


    public Exec(Node body, Node globals, Node locals, String file, int start, int end) {
        super(file, start, end);
        this.body = body;
        this.globals = globals;
        this.locals = locals;
        addChildren(body, globals, locals);
    }


    @NotNull
    @Override
    public Type transform(State s) {
        if (body != null) {
            transformExpr(body, s);
        }
        if (globals != null) {
            transformExpr(globals, s);
        }
        if (locals != null) {
            transformExpr(locals, s);
        }
        return Type.CONT;
    }


    @NotNull
    @Override
    public String toString() {
        return "<Exec:" + start + ":" + end + ">";
    }

}
