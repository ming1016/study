package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.Type;
import org.yinwang.pysonar.types.UnionType;

import java.util.List;


public class Try extends Node {

    public List<Handler> handlers;
    public Block body;
    public Block orelse;
    public Block finalbody;


    public Try(List<Handler> handlers, Block body, Block orelse, Block finalbody,
               String file, int start, int end)
    {
        super(file, start, end);
        this.handlers = handlers;
        this.body = body;
        this.orelse = orelse;
        this.finalbody = finalbody;
        addChildren(handlers);
        addChildren(body, orelse);
    }


    @NotNull
    @Override
    public Type transform(State s) {
        Type tp1 = Type.UNKNOWN;
        Type tp2 = Type.UNKNOWN;
        Type tph = Type.UNKNOWN;
        Type tpFinal = Type.UNKNOWN;

        if (handlers != null) {
            for (Handler h : handlers) {
                tph = UnionType.union(tph, transformExpr(h, s));
            }
        }

        if (body != null) {
            tp1 = transformExpr(body, s);
        }

        if (orelse != null) {
            tp2 = transformExpr(orelse, s);
        }

        if (finalbody != null) {
            tpFinal = transformExpr(finalbody, s);
        }

        return new UnionType(tp1, tp2, tph, tpFinal);
    }


    @NotNull
    @Override
    public String toString() {
        return "<Try:" + handlers + ":" + body + ":" + orelse + ">";
    }

}
