package org.yinwang.rubysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.rubysonar.State;
import org.yinwang.rubysonar.types.IntType;
import org.yinwang.rubysonar.types.Type;

import java.math.BigInteger;


public class RbInt extends Node {

    public BigInteger value;


    public RbInt(String s, String file, int start, int end) {
        super(file, start, end);

        s = s.toLowerCase();
        s = s.replaceAll("_", "");
        int sign = 1;

        if (s.startsWith("+")) {
            s = s.substring(1);
        } else if (s.startsWith("-")) {
            s = s.substring(1);
            sign = -1;
        }

        int base;
        if (s.startsWith("0b")) {
            base = 2;
            s = s.substring(2);
        } else if (s.startsWith("0o")) {
            base = 8;
            s = s.substring(2);
        } else if (s.startsWith("0x")) {
            base = 16;
            s = s.substring(2);
        } else if (s.startsWith("x")) {
            base = 16;
            s = s.substring(1);
        } else if (s.startsWith("0d")) {
            base = 10;
            s = s.substring(2);
        } else {
            base = 10;
        }

        value = new BigInteger(s, base);
        if (sign == -1) {
            value = value.negate();
        }
    }


    @NotNull
    @Override
    public Type transform(State s) {
        return new IntType(value);
    }


    @NotNull
    @Override
    public String toString() {
        return "(int:" + value + ")";
    }

}
