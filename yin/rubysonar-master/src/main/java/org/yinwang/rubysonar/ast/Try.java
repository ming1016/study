package org.yinwang.rubysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.rubysonar.State;
import org.yinwang.rubysonar.types.Type;
import org.yinwang.rubysonar.types.UnionType;


public class Try extends Node {

    public Node rescue;
    public Node body;
    public Node orelse;
    public Node finalbody;


    public Try(Node rescue, Node body, Node orelse, Node finalbody,
               String file, int start, int end)
    {
        super(file, start, end);
        this.rescue = rescue;
        this.body = body;
        this.orelse = orelse;
        this.finalbody = finalbody;
        addChildren(rescue);
        addChildren(body, orelse);
    }


    @NotNull
    @Override
    public Type transform(State s) {
        Type tp1 = Type.UNKNOWN;
        Type tp2 = Type.UNKNOWN;
        Type tph = Type.UNKNOWN;
        Type tpFinal = Type.UNKNOWN;

        if (rescue != null) {
            tph = UnionType.union(tph, transformExpr(rescue, s));
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
        return "(try:" + rescue + ":" + body + ":" + orelse + ")";
    }


}
