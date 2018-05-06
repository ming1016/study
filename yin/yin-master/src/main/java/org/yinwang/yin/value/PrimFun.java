package org.yinwang.yin.value;


import org.yinwang.yin.ast.Node;

import java.util.List;

public abstract class PrimFun extends Value {
    public String name;
    public int arity;


    protected PrimFun(String name, int arity) {
        this.name = name;
        this.arity = arity;
    }


    // how to apply the primitive to args (must be positional)
    public abstract Value apply(List<Value> args, Node location);


    public abstract Value typecheck(List<Value> args, Node location);


    public String toString() {
        return name;
    }

}
