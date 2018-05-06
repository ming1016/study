package org.yinwang.yin.ast;


import org.yinwang.yin.Scope;
import org.yinwang.yin.value.IntType;
import org.yinwang.yin.value.IntValue;
import org.yinwang.yin.value.Type;
import org.yinwang.yin.value.Value;

public class IntNum extends Node {

    public String content;
    public int value;
    public int base;


    public IntNum(String content, String file, int start, int end, int line, int col) {
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

        this.value = Integer.parseInt(content, base);
        if (sign == -1) {
            this.value = -this.value;
        }
    }


    public static IntNum parse(String content, String file, int start, int end, int line, int col) {
        try {
            return new IntNum(content, file, start, end, line, col);
        } catch (NumberFormatException e) {
            return null;
        }
    }


    public Value interp(Scope s) {
        return new IntValue(value);
    }


    @Override
    public Value typecheck(Scope s) {
        return Type.INT;
    }


    @Override
    public String toString() {
        return Integer.toString(value);
    }

}
