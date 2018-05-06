package org.yinwang.rubysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.rubysonar.State;
import org.yinwang.rubysonar.types.FloatType;
import org.yinwang.rubysonar.types.Type;


public class RbFloat extends Node {

    public double value;


    public RbFloat(String s, String file, int start, int end) {
        super(file, start, end);
        s = s.replaceAll("_", "");
        this.value = Double.parseDouble(s);
    }


    @NotNull
    @Override
    public Type transform(State s) {
        return new FloatType(value);
    }


    @NotNull
    @Override
    public String toString() {
        return "(float:" + value + ")";
    }

}
