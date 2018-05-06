package org.yinwang.yin.ast;


import org.yinwang.yin.Scope;
import org.yinwang.yin.value.StringType;
import org.yinwang.yin.value.StringValue;
import org.yinwang.yin.value.Type;
import org.yinwang.yin.value.Value;

public class Str extends Node {
    public String value;


    public Str(String value, String file, int start, int end, int line, int col) {
        super(file, start, end, line, col);
        this.value = value;
    }


    public Value interp(Scope s) {
        return new StringValue(value);
    }


    @Override
    public Value typecheck(Scope s) {
        return Type.STRING;
    }


    public String toString() {
        return "\"" + value + "\"";
    }

}
