package org.yinwang.yin.value;


public abstract class Value {
    public static final Value VOID = new VoidValue();
    public static final Value TRUE = new BoolValue(true);
    public static final Value FALSE = new BoolValue(false);
    public static final Value ANY = new AnyType();

}
