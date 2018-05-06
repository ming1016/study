package org.yinwang.yin.ast;


import org.yinwang.yin.Scope;
import org.yinwang.yin._;
import org.yinwang.yin.value.IntValue;
import org.yinwang.yin.value.Value;
import org.yinwang.yin.value.Vector;

import java.util.List;

public class Subscript extends Node {
    public Node value;
    public Node index;


    public Subscript(Node value, Node index, String file, int start, int end, int line, int col) {
        super(file, start, end, line, col);
        this.value = value;
        this.index = index;
    }


    @Override
    public Value interp(Scope s) {
        Value vector = value.interp(s);
        Value indexValue = index.interp(s);

        if (!(vector instanceof Vector)) {
            _.abort(value, "subscripting non-vector: " + vector);
            return null;
        }

        if (!(indexValue instanceof IntValue)) {
            _.abort(value, "subscript " + index + " is not an integer: " + indexValue);
            return null;
        }

        List<Value> values = ((Vector) vector).values;
        int i = ((IntValue) indexValue).value;

        if (i >= 0 && i < values.size()) {
            return values.get(i);
        } else {
            _.abort(this, "subscript out of bound: " + i + " v.s. [0, " + (values.size() - 1) + "]");
            return null;
        }
    }


    @Override
    public Value typecheck(Scope s) {
        return null;
    }


    public void set(Value v, Scope s) {
        Value vector = value.interp(s);
        Value indexValue = index.interp(s);

        if (!(vector instanceof Vector)) {
            _.abort(value, "subscripting non-vector: " + vector);
        }

        if (!(indexValue instanceof IntValue)) {
            _.abort(value, "subscript " + index + " is not an integer: " + indexValue);
        }

        Vector vector1 = (Vector) vector;
        int i = ((IntValue) indexValue).value;

        if (i >= 0 && i < vector1.size()) {
            vector1.set(i, v);
        } else {
            _.abort(this, "subscript out of bound: " + i + " v.s. [0, " + (vector1.size() - 1) + "]");
        }
    }


    public String toString() {
        return "(ref " + value + " " + index + ")";
    }

}
