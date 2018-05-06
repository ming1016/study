package org.yinwang.rubysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.rubysonar.Binder;
import org.yinwang.rubysonar.State;
import org.yinwang.rubysonar.types.Type;
import org.yinwang.rubysonar.types.UnionType;

import java.util.List;


public class Handler extends Node {

    public List<Node> exceptions;
    public Node binder;
    public Node handler;
    public Node orelse;


    public Handler(List<Node> exceptions, Node binder, Node handler, Node orelse, String file, int start, int end) {
        super(file, start, end);
        this.exceptions = exceptions;
        this.binder = binder;
        this.handler = handler;
        this.orelse = orelse;
        addChildren(binder, handler, orelse);
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

        Type ret = Type.UNKNOWN;

        if (handler != null) {
            ret = UnionType.union(ret, transformExpr(handler, s));
        }

        if (orelse != null) {
            ret = UnionType.union(ret, transformExpr(orelse, s));
        }

        return ret;
    }


    @NotNull
    @Override
    public String toString() {
        return "(handler:" + exceptions + ":" + binder + ")";
    }


}
