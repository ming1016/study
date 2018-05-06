package org.yinwang.yin.ast;


import org.yinwang.yin._;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class Argument {
    public List<Node> elements;
    public List<Node> positional = new ArrayList<>();
    public Map<String, Node> keywords = new LinkedHashMap<>();


    public Argument(List<Node> elements) {
        boolean hasName = false;
        boolean hasKeyword = false;

        for (int i = 0; i < elements.size(); i++) {
            if (elements.get(i) instanceof Keyword) {
                hasKeyword = true;
                i++;
            } else {
                hasName = true;
            }
        }

        if (hasName && hasKeyword) {
            _.abort(elements.get(0), "mix positional and keyword arguments not allowed: " + elements);
        }


        this.elements = elements;

        for (int i = 0; i < elements.size(); i++) {
            Node key = elements.get(i);
            if (key instanceof Keyword) {
                String id = ((Keyword) key).id;
                positional.add(((Keyword) key).asName());

                if (i >= elements.size() - 1) {
                    _.abort(key, "missing value for keyword: " + key);
                } else {
                    Node value = elements.get(i + 1);
                    if (value instanceof Keyword) {
                        _.abort(value, "keywords can't be used as values: " + value);
                    } else {
                        if (keywords.containsKey(id)) {
                            _.abort(key, "duplicated keyword: " + key);
                        }
                        keywords.put(id, value);
                        i++;
                    }
                }
            } else {
                positional.add(key);
            }
        }
    }


    public String toString() {
        StringBuilder sb = new StringBuilder();
        boolean first = true;
        for (Node e : elements) {
            if (!first) {
                sb.append(" ");
            }
            sb.append(e);
            first = false;
        }
        return sb.toString();
    }

}
