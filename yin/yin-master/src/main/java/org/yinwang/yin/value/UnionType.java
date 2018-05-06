package org.yinwang.yin.value;


import org.yinwang.yin.Constants;

import java.util.Collection;
import java.util.HashSet;
import java.util.Set;

public class UnionType extends Value {

    public Set<Value> values = new HashSet<>();


    public UnionType() {

    }


    public static Value union(Collection<Value> values) {
        UnionType u = new UnionType();
        for (Value v : values) {
            u.add(v);
        }
        if (u.size() == 1) {
            return u.first();
        } else {
            return u;
        }
    }


    public static Value union(Value... values) {
        UnionType u = new UnionType();
        for (Value v : values) {
            u.add(v);
        }
        if (u.size() == 1) {
            return u.first();
        } else {
            return u;
        }
    }


    public void add(Value value) {
        if (value instanceof UnionType) {
            values.addAll(((UnionType) value).values);
        } else {
            values.add(value);
        }
    }


    public int size() {
        return values.size();
    }


    public Value first() {
        return values.iterator().next();
    }


    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append(Constants.TUPLE_BEGIN).append("U ");

        boolean first = true;
        for (Value v : values) {
            if (!first) {
                sb.append(" ");
            }
            sb.append(v);
            first = false;
        }

        sb.append(Constants.TUPLE_END);
        return sb.toString();
    }

}
