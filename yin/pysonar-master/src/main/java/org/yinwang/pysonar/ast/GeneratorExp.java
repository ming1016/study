package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.ListType;
import org.yinwang.pysonar.types.Type;

import java.util.List;


public class GeneratorExp extends Node {

    public Node elt;
    public List<Comprehension> generators;


    public GeneratorExp(Node elt, List<Comprehension> generators, String file, int start, int end) {
        super(file, start, end);
        this.elt = elt;
        this.generators = generators;
        addChildren(elt);
        addChildren(generators);
    }


    /**
     * Python's list comprehension will erase any variable used in generators.
     * This is wrong, but we "respect" this bug here.
     */
    @NotNull
    @Override
    public Type transform(State s) {
        resolveList(generators, s);
        return new ListType(transformExpr(elt, s));
    }


    @NotNull
    @Override
    public String toString() {
        return "<GeneratorExp:" + start + ":" + elt + ">";
    }

}
