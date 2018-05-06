package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;

import java.util.List;


public abstract class Sequence extends Node {

    @NotNull
    public List<Node> elts;


    public Sequence(@NotNull List<Node> elts, String file, int start, int end) {
        super(file, start, end);
        this.elts = elts;
        addChildren(elts);
    }

}
