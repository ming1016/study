package org.yinwang.yin.value;


public class IntValue extends Value {
    public int value;


    public IntValue(int value) {
        this.value = value;
    }


    public String toString() {
        return Integer.toString(value);
    }

}
