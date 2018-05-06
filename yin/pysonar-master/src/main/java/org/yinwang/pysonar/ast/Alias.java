package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.Type;

import java.util.List;


public class Alias extends Node {

    public List<Name> name;
    public Name asname;


    public Alias(List<Name> name, Name asname, String file, int start, int end) {
        super(file, start, end);
        this.name = name;
        this.asname = asname;
        addChildren(name);
        addChildren(asname);
    }


    @NotNull
    @Override
    public Type transform(State s) {
        return Type.UNKNOWN;
    }


    @NotNull
    @Override
    public String toString() {
        return "<Alias:" + name + " as " + asname + ">";
    }

}
