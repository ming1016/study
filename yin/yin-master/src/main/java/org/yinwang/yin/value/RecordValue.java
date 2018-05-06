package org.yinwang.yin.value;


import org.yinwang.yin.Constants;
import org.yinwang.yin.Scope;


public class RecordValue extends Value {

    public String name;
    public RecordType type;
    public Scope properties;


    public RecordValue(String name, RecordType type, Scope properties) {
        this.name = name;
        this.type = type;
        this.properties = properties;
    }


    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append(Constants.TUPLE_BEGIN);
        sb.append(Constants.RECORD_KEYWORD).append(" ");
        sb.append(name == null ? "_" : name);

        for (String field : properties.keySet()) {
            sb.append(" ").append(Constants.ARRAY_BEGIN);
            sb.append(field).append(" ");
            sb.append(properties.lookupLocal(field));
            sb.append(Constants.ARRAY_END);
        }

        sb.append(Constants.TUPLE_END);
        return sb.toString();
    }

}
