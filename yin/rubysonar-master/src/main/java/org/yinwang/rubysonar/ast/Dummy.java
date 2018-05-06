package org.yinwang.rubysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.rubysonar.State;
import org.yinwang.rubysonar.types.Type;


/**
 * dummy node for locating purposes only
 * rarely used
 */
public class Dummy extends Node {

    public Dummy(String file, int start, int end) {
        super(file, start, end);
    }


    @NotNull
    @Override
    protected Type transform(State s) {
        return Type.UNKNOWN;
    }

}
