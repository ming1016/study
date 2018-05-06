package org.yinwang.yin.ast;


import org.yinwang.yin.Scope;
import org.yinwang.yin._;
import org.yinwang.yin.value.Value;

public class Keyword extends Node {
    public String id;


    public Keyword(String id, String file, int start, int end, int line, int col) {
        super(file, start, end, line, col);
        this.id = id;
    }


    public Name asName() {
        return new Name(id, file, start, end, line, col);
    }


    public Value interp(Scope s) {
        _.abort(this, "keyword used as value");
        return null;
    }


    @Override
    public Value typecheck(Scope s) {
        _.abort(this, "keyword used as value");
        return null;
    }


    public String toString() {
        return ":" + id;
    }
}
