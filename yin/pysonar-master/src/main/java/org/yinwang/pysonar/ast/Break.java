package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.Type;


public class Break extends Node {

    public Break(String file, int start, int end) {
        super(file, start, end);
    }


    @NotNull
    @Override
    public String toString() {
        return "(break)";
    }


    @NotNull
    @Override
    public Type transform(State s) {
        return Type.NONE;
    }
}
