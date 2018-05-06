package org.yinwang.yin.ast;


import org.yinwang.yin.Scope;
import org.yinwang.yin.value.Value;

public class Delimeter extends Node {
    public String shape;


    public Delimeter(String shape, String file, int start, int end, int line, int col) {
        super(file, start, end, line, col);
        this.shape = shape;
    }


    public Value interp(Scope s) {
        return null;
    }


    @Override
    public Value typecheck(Scope s) {
        return null;
    }


    public String toString() {
        return shape;
    }
}

