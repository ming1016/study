package org.yinwang.yin.value;


public class StringValue extends Value {
    public String value;


    public StringValue(String value) {
        this.value = value;
    }


    public String toString() {
        return "\"" + value + "\"";
    }

}
