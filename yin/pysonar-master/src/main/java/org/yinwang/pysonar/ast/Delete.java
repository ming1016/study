package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.Type;

import java.util.List;


public class Delete extends Node {

    public List<Node> targets;


    public Delete(List<Node> elts, String file, int start, int end) {
        super(file, start, end);
        this.targets = elts;
        addChildren(elts);
    }


    @NotNull
    @Override
    public Type transform(@NotNull State s) {
        for (Node n : targets) {
            transformExpr(n, s);
            if (n instanceof Name) {
                s.remove(((Name) n).id);
            }
        }
        return Type.CONT;
    }


    @NotNull
    @Override
    public String toString() {
        return "<Delete:" + targets + ">";
    }

}
