package org.yinwang.yin;


import org.yinwang.yin.value.BoolValue;
import org.yinwang.yin.value.Type;
import org.yinwang.yin.value.Value;
import org.yinwang.yin.value.primitives.*;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

public class Scope {

    public Map<String, Map<String, Object>> table = new LinkedHashMap<>();
    public Scope parent;


    public Scope() {
        this.parent = null;
    }


    public Scope(Scope parent) {
        this.parent = parent;
    }


    public Scope copy() {
        Scope ret = new Scope();
        for (String name : table.keySet()) {
            Map<String, Object> props = new LinkedHashMap<>();
            props.putAll(table.get(name));
            ret.table.put(name, props);
        }
        return ret;
    }


    public void putAll(Scope other) {
        for (String name : other.table.keySet()) {
            Map<String, Object> props = new LinkedHashMap<>();
            props.putAll(other.table.get(name));
            table.put(name, props);
        }
    }


    public Value lookup(String name) {
        Object v = lookupProperty(name, "value");
        if (v == null) {
            return null;
        } else if (v instanceof Value) {
            return (Value) v;
        } else {
            _.abort("value is not a Value, shouldn't happen: " + v);
            return null;
        }
    }


    public Value lookupLocal(String name) {
        Object v = lookupPropertyLocal(name, "value");
        if (v == null) {
            return null;
        } else if (v instanceof Value) {
            return (Value) v;
        } else {
            _.abort("value is not a Value, shouldn't happen: " + v);
            return null;
        }
    }


    public Value lookupType(String name) {
        Object v = lookupProperty(name, "type");
        if (v == null) {
            return null;
        } else if (v instanceof Value) {
            return (Value) v;
        } else {
            _.abort("value is not a Value, shouldn't happen: " + v);
            return null;
        }
    }


    public Value lookupLocalType(String name) {
        Object v = lookupPropertyLocal(name, "type");
        if (v == null) {
            return null;
        } else if (v instanceof Value) {
            return (Value) v;
        } else {
            _.abort("value is not a Value, shouldn't happen: " + v);
            return null;
        }
    }


    public Object lookupPropertyLocal(String name, String key) {
        Map<String, Object> item = table.get(name);
        if (item != null) {
            return item.get(key);
        } else {
            return null;
        }
    }


    public Object lookupProperty(String name, String key) {
        Object v = lookupPropertyLocal(name, key);
        if (v != null) {
            return v;
        } else if (parent != null) {
            return parent.lookupProperty(name, key);
        } else {
            return null;
        }
    }


    public Map<String, Object> lookupAllProps(String name) {
        return table.get(name);
    }


    public Scope findDefiningScope(String name) {
        Object v = table.get(name);
        if (v != null) {
            return this;
        } else if (parent != null) {
            return parent.findDefiningScope(name);
        } else {
            return null;
        }
    }


    public static Scope buildInitScope() {
        Scope init = new Scope();

        init.putValue("+", new Add());
        init.putValue("-", new Sub());
        init.putValue("*", new Mult());
        init.putValue("/", new Div());

        init.putValue("<", new Lt());
        init.putValue("<=", new LtE());
        init.putValue(">", new Gt());
        init.putValue(">=", new GtE());
        init.putValue("=", new Eq());
        init.putValue("and", new And());
        init.putValue("or", new Or());
        init.putValue("not", new Not());

        init.putValue("true", new BoolValue(true));
        init.putValue("false", new BoolValue(false));

        init.putValue("Int", Type.INT);
        init.putValue("Bool", Type.BOOL);
        init.putValue("String", Type.STRING);

        return init;
    }


    public static Scope buildInitTypeScope() {
        Scope init = new Scope();

        init.putValue("+", new Add());
        init.putValue("-", new Sub());
        init.putValue("*", new Mult());
        init.putValue("/", new Div());

        init.putValue("<", new Lt());
        init.putValue("<=", new LtE());
        init.putValue(">", new Gt());
        init.putValue(">=", new GtE());
        init.putValue("=", new Eq());
        init.putValue("and", new And());
        init.putValue("or", new Or());
        init.putValue("not", new Not());
        init.putValue("U", new U());

        init.putValue("true", Type.BOOL);
        init.putValue("false", Type.BOOL);

        init.putValue("Int", Type.INT);
        init.putValue("Bool", Type.BOOL);
        init.putValue("String", Type.STRING);
        init.putValue("Any", Value.ANY);

        return init;
    }


    public void put(String name, String key, Object value) {
        Map<String, Object> item = table.get(name);
        if (item == null) {
            item = new LinkedHashMap<>();
        }
        item.put(key, value);
        table.put(name, item);
    }


    public void putProperties(String name, Map<String, Object> props) {
        Map<String, Object> item = table.get(name);
        if (item == null) {
            item = new LinkedHashMap<>();
        }
        item.putAll(props);
        table.put(name, item);
    }


    public void putValue(String name, Value value) {
        put(name, "value", value);
    }


    public void putType(String name, Value value) {
        put(name, "type", value);
    }


    public Set<String> keySet() {
        return table.keySet();
    }


    public boolean containsKey(String key) {
        return table.containsKey(key);
    }


    public String toString() {
        StringBuffer sb = new StringBuffer();
        for (String name : table.keySet()) {
            sb.append(Constants.ARRAY_BEGIN).append(name).append(" ");
            for (Map.Entry<String, Object> e : table.get(name).entrySet()) {
                sb.append(":" + e.getKey() + " " + e.getValue());
            }
            sb.append(Constants.ARRAY_END);
        }
        return sb.toString();
    }

}
