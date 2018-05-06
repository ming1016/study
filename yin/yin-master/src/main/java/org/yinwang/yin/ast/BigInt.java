package org.yinwang.yin.ast;


import org.yinwang.yin.Scope;
import org.yinwang.yin.value.Value;

import java.math.BigInteger;

public class BigInt extends Node {

    public String content;
    public BigInteger value;
    public int base;


    public BigInt(String content, String file, int start, int end, int line, int col) {
        super(file, start, end, line, col);
        this.content = content;

        int sign;
        if (content.startsWith("+")) {
            sign = 1;
            content = content.substring(1);
        } else if (content.startsWith("-")) {
            sign = -1;
            content = content.substring(1);
        } else {
            sign = 1;
        }

        if (content.startsWith("0b")) {
            base = 2;
            content = content.substring(2);
        } else if (content.startsWith("0x")) {
            base = 16;
            content = content.substring(2);
        } else if (content.startsWith("0o")) {
            base = 8;
            content = content.substring(2);
        } else {
            base = 10;
        }

        BigInteger value1 = new BigInteger(content, base);
        if (sign == -1) {
            value1 = value1.negate();
        }
        this.value = value1;
    }


    public static BigInt parse(String content, String file, int start, int end, int line, int col) {
        try {
            return new BigInt(content, file, start, end, line, col);
        } catch (NumberFormatException e) {
            return null;
        }
    }


    public Value interp(Scope s) {
        return null;
    }


    @Override
    public Value typecheck(Scope s) {
        return null;
    }


    public String toString() {
        return content;
    }

}
