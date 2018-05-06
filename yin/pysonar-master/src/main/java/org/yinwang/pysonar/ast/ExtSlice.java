package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.ListType;
import org.yinwang.pysonar.types.Type;

import java.util.List;


public class ExtSlice extends Node {

    public List<Node> dims;


    public ExtSlice(List<Node> dims, String file, int start, int end) {
        super(file, start, end);
        this.dims = dims;
        addChildren(dims);
    }


    @NotNull
    @Override
    public Type transform(State s) {
        for (Node d : dims) {
            transformExpr(d, s);
        }
        return new ListType();
    }


    @NotNull
    @Override
    public String toString() {
        return "<ExtSlice:" + dims + ">";
    }

}
