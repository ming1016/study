package org.yinwang.yin.ast;

import org.yinwang.yin.Constants;
import org.yinwang.yin.Scope;
import org.yinwang.yin._;
import org.yinwang.yin.value.RecordType;
import org.yinwang.yin.value.Value;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;


public class RecordLiteral extends Node {

    public Map<String, Node> map = new LinkedHashMap<>();


    public RecordLiteral(List<Node> contents, String file, int start, int end, int line, int col) {
        super(file, start, end, line, col);

        if (contents.size() % 2 != 0) {
            _.abort(this, "record initializer must have even number of elements");
        }

        for (int i = 0; i < contents.size(); i += 2) {
            Node key = contents.get(i);
            Node value = contents.get(i + 1);
            if (key instanceof Keyword) {
                if (value instanceof Keyword) {
                    _.abort(value, "keywords shouldn't be used as values: " + value);
                } else {
                    map.put(((Keyword) key).id, value);
                }
            } else {
                _.abort(key, "record initializer key is not a keyword: " + key);
            }
        }
    }


    public Value interp(Scope s) {
        Scope properties = new Scope();
        for (Map.Entry<String, Node> e : map.entrySet()) {
            properties.putValue(e.getKey(), e.getValue().interp(s));
        }
        return new RecordType(null, this, properties);
    }


    @Override
    public Value typecheck(Scope s) {
        Scope properties = new Scope();
        for (Map.Entry<String, Node> e : map.entrySet()) {
            properties.putValue(e.getKey(), e.getValue().typecheck(s));
        }
        return new RecordType(null, this, properties);
    }


    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append(Constants.RECORD_BEGIN);
        boolean first = true;
        for (Map.Entry<String, Node> e : map.entrySet()) {
            if (!first) {
                sb.append(" ");
            }
            sb.append(":" + e.getKey() + " " + e.getValue());
            first = false;
        }
        sb.append(Constants.RECORD_END);
        return sb.toString();
    }
}
