package org.yinwang.yin.ast;

import org.yinwang.yin.Binder;
import org.yinwang.yin.Constants;
import org.yinwang.yin.Scope;
import org.yinwang.yin.value.Value;

public class Assign extends Node {
    public Node pattern;
    public Node value;


    public Assign(Node pattern, Node value, String file, int start, int end, int line, int col) {
        super(file, start, end, line, col);
        this.pattern = pattern;
        this.value = value;
    }


    public Value interp(Scope s) {
        Value valueValue = value.interp(s);
        Binder.checkDup(pattern);
        Binder.assign(pattern, valueValue, s);
        return Value.VOID;
    }


    @Override
    public Value typecheck(Scope s) {
        Value valueValue = value.typecheck(s);
        Binder.checkDup(pattern);
        Binder.assign(pattern, valueValue, s);
        return Value.VOID;
    }


    public String toString() {
        return "(" + Constants.ASSIGN_KEYWORD + " " + pattern + " " + value + ")";
    }

}
