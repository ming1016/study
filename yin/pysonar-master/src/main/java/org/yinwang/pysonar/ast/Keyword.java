package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.Type;


/**
 * Represents a keyword argument (name=value) in a function call.
 */
public class Keyword extends Node {

    public String arg;
    @NotNull
    public Node value;


    public Keyword(String arg, @NotNull Node value, String file, int start, int end) {
        super(file, start, end);
        this.arg = arg;
        this.value = value;
        addChildren(value);
    }


    @NotNull
    @Override
    public Type transform(State s) {
        return transformExpr(value, s);
    }


    @NotNull
    @Override
    public String toString() {
        return "(keyword:" + arg + ":" + value + ")";
    }


    @NotNull
    @Override
    public String toDisplay() {
        return arg;
    }

}
