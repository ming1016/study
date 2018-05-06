package org.yinwang.yin.value;


public class FloatValue extends Value {
    public double value;


    public FloatValue(double value) {
        this.value = value;
    }


    public String toString() {
        return Double.toString(value);
    }

}
