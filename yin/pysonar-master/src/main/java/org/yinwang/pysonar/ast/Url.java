package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.Type;


/**
 * virtual-AST node used to represent virtual source locations for builtins
 * as external urls.
 */
public class Url extends Node {

    public String url;


    public Url(String url) {
        this.url = url;
    }


    @NotNull
    @Override
    public Type transform(State s) {
        return Type.STR;
    }


    @NotNull
    @Override
    public String toString() {
        return "<Url:\"" + url + "\">";
    }

}
