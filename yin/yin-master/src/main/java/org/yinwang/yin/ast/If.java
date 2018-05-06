package org.yinwang.yin.ast;

import org.yinwang.yin.Constants;
import org.yinwang.yin.Scope;
import org.yinwang.yin._;
import org.yinwang.yin.value.BoolType;
import org.yinwang.yin.value.BoolValue;
import org.yinwang.yin.value.UnionType;
import org.yinwang.yin.value.Value;

public class If extends Node {
    public Node test;
    public Node then;
    public Node orelse;


    public If(Node test, Node then, Node orelse, String file, int start, int end, int line, int col) {
        super(file, start, end, line, col);
        this.test = test;
        this.then = then;
        this.orelse = orelse;
    }


    public Value interp(Scope s) {
        Value tv = interp(test, s);
        if (((BoolValue) tv).value) {
            return interp(then, s);
        } else {
            return interp(orelse, s);
        }
    }


    @Override
    public Value typecheck(Scope s) {
        Value tv = typecheck(test, s);
        if (!(tv instanceof BoolType)) {
            _.abort(test, "test is not boolean: " + tv);
            return null;
        }
        Value type1 = typecheck(then, s);
        Value type2 = typecheck(orelse, s);
        return UnionType.union(type1, type2);
    }


    public String toString() {
        return "(" + Constants.IF_KEYWORD + " " + test + " " + then + " " + orelse + ")";
    }

}
