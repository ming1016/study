package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.Binder;
import org.yinwang.pysonar.Binding;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.Type;
import org.yinwang.pysonar.types.UnionType;


public class For extends Node {

    public Node target;
    public Node iter;
    public Block body;
    public Block orelse;


    public For(Node target, Node iter, Block body, Block orelse,
               String file, int start, int end)
    {
        super(file, start, end);
        this.target = target;
        this.iter = iter;
        this.body = body;
        this.orelse = orelse;
        addChildren(target, iter, body, orelse);
    }


    @NotNull
    @Override
    public Type transform(@NotNull State s) {
        Binder.bindIter(s, target, iter, Binding.Kind.SCOPE);

        Type ret;
        if (body == null) {
            ret = Type.UNKNOWN;
        } else {
            ret = transformExpr(body, s);
        }
        if (orelse != null) {
            ret = UnionType.union(ret, transformExpr(orelse, s));
        }
        return ret;
    }


    @NotNull
    @Override
    public String toString() {
        return "<For:" + target + ":" + iter + ":" + body + ":" + orelse + ">";
    }

}
