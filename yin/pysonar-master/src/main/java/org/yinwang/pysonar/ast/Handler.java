package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.Binder;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.Type;

import java.util.List;


public class Handler extends Node {

    public List<Node> exceptions;
    public Node binder;
    public Block body;


    public Handler(List<Node> exceptions, Node binder, Block body, String file, int start, int end) {
        super(file, start, end);
        this.binder = binder;
        this.exceptions = exceptions;
        this.body = body;
        addChildren(binder, body);
        addChildren(exceptions);
    }


    @NotNull
    @Override
    public Type transform(@NotNull State s) {
        Type typeval = Type.UNKNOWN;
        if (exceptions != null) {
            typeval = resolveUnion(exceptions, s);
        }
        if (binder != null) {
            Binder.bind(s, binder, typeval);
        }
        if (body != null) {
            return transformExpr(body, s);
        } else {
            return Type.UNKNOWN;
        }
    }


    @NotNull
    @Override
    public String toString() {
        return "(handler:" + start + ":" + exceptions + ":" + binder + ")";
    }

}
