package org.yinwang.yin.value;


import org.yinwang.yin.Scope;
import org.yinwang.yin.ast.Fun;

public class Closure extends Value {

    public Fun fun;
    public Scope properties;
    public Scope env;


    public Closure(Fun fun, Scope properties, Scope env) {
        this.fun = fun;
        this.properties = properties;
        this.env = env;
    }


    public String toString() {
        return fun.toString();
    }

}
