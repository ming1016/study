package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.Type;

import java.util.List;


public class Global extends Node {

    public List<Name> names;


    public Global(List<Name> names, String file, int start, int end) {
        super(file, start, end);
        this.names = names;
        addChildren(names);
    }


    @NotNull
    @Override
    public Type transform(State s) {
        // Do nothing here because global names are processed by NBlock
        return Type.CONT;
    }


    @NotNull
    @Override
    public String toString() {
        return "<Global:" + names + ">";
    }

}
