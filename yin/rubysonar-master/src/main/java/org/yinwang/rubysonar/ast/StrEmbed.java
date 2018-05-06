package org.yinwang.rubysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.rubysonar.State;
import org.yinwang.rubysonar.types.Type;


public class StrEmbed extends Node {

    public Node value;


    public StrEmbed(@NotNull Node value, String file, int start, int end) {
        super(file, start, end);
        this.value = value;
    }


    @NotNull
    @Override
    public Type transform(State s) {
        Type valueType = value.transform(s);
        return Type.STR;
    }


    @NotNull
    @Override
    public String toString() {
        return "#{" + value + "}";
    }

}
