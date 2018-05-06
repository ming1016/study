package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.Type;


public class Bytes extends Node {

    public Object value;


    public Bytes(@NotNull Object value, String file, int start, int end) {
        super(file, start, end);
        this.value = value.toString();
    }


    @NotNull
    @Override
    public Type transform(State s) {
        return Type.STR;
    }


    @NotNull
    @Override
    public String toString() {
        return "(bytes: " + value + ")";
    }

}
