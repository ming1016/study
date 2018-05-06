package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.Binder;
import org.yinwang.pysonar.Binding;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.Type;

import java.util.List;


public class Comprehension extends Node {

    public Node target;
    public Node iter;
    public List<Node> ifs;


    public Comprehension(Node target, Node iter, List<Node> ifs, String file, int start, int end) {
        super(file, start, end);
        this.target = target;
        this.iter = iter;
        this.ifs = ifs;
        addChildren(target, iter);
        addChildren(ifs);
    }


    @NotNull
    @Override
    public Type transform(@NotNull State s) {
        Binder.bindIter(s, target, iter, Binding.Kind.SCOPE);
        resolveList(ifs, s);
        return transformExpr(target, s);
    }


    @NotNull
    @Override
    public String toString() {
        return "<Comprehension:" + start + ":" + target + ":" + iter + ":" + ifs + ">";
    }

}
