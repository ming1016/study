package org.yinwang.pysonar;

import org.jetbrains.annotations.NotNull;


public class Diagnostic {
    public enum Category {
        INFO, WARNING, ERROR
    }


    public String file;
    public Category category;
    public int start;
    public int end;
    public String msg;


    public Diagnostic(String file, Category category, int start, int end, String msg) {
        this.category = category;
        this.file = file;
        this.start = start;
        this.end = end;
        this.msg = msg;
    }


    @NotNull
    @Override
    public String toString() {
        return "<Diagnostic:" + file + ":" + category + ":" + msg + ">";
    }
}
