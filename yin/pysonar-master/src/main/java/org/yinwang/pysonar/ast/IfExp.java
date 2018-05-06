package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.Type;
import org.yinwang.pysonar.types.UnionType;


public class IfExp extends Node {

    public Node test;
    public Node body;
    public Node orelse;


    public IfExp(Node test, Node body, Node orelse, String file, int start, int end) {
        super(file, start, end);
        this.test = test;
        this.body = body;
        this.orelse = orelse;
        addChildren(test, body, orelse);
    }


    @NotNull
    @Override
    public Type transform(State s) {
        Type type1, type2;
        transformExpr(test, s);

        if (body != null) {
            type1 = transformExpr(body, s);
        } else {
            type1 = Type.CONT;
        }
        if (orelse != null) {
            type2 = transformExpr(orelse, s);
        } else {
            type2 = Type.CONT;
        }
        return UnionType.union(type1, type2);
    }


    @NotNull
    @Override
    public String toString() {
        return "<IfExp:" + start + ":" + test + ":" + body + ":" + orelse + ">";
    }

}
