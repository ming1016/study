package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.DictType;
import org.yinwang.pysonar.types.Type;

import java.util.List;


public class DictComp extends Node {

    public Node key;
    public Node value;
    public List<Comprehension> generators;


    public DictComp(Node key, Node value, List<Comprehension> generators, String file, int start, int end) {
        super(file, start, end);
        this.key = key;
        this.value = value;
        this.generators = generators;
        addChildren(key);
        addChildren(generators);
    }


    /**
     * Python's list comprehension will bind the variables used in generators.
     * This will erase the original values of the variables even after the
     * comprehension.
     */
    @NotNull
    @Override
    public Type transform(State s) {
        resolveList(generators, s);
        Type keyType = transformExpr(key, s);
        Type valueType = transformExpr(value, s);
        return new DictType(keyType, valueType);
    }


    @NotNull
    @Override
    public String toString() {
        return "<DictComp:" + start + ":" + key + ">";
    }

}
