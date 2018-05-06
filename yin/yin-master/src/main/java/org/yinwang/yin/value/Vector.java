package org.yinwang.yin.value;


import org.yinwang.yin.Constants;

import java.util.List;

public class Vector extends Value {

    public List<Value> values;


    public Vector(List<Value> values) {
        this.values = values;
    }


    public void set(int idx, Value value) {
        values.set(idx, value);
    }


    public int size() {
        return values.size();
    }


    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append(Constants.ARRAY_BEGIN);

        boolean first = true;
        for (Value v : values) {
            if (!first) {
                sb.append(" ");
            }
            sb.append(v);
            first = false;
        }

        sb.append(Constants.ARRAY_END);
        return sb.toString();
    }

}
