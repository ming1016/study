package org.python.indexer;

public class Diagnostic {
    public enum Type {
        INFO, WARNING, ERROR
    }

    public String file;
    public Type type;
    public int start;
    public int end;
    public int line;
    public int column;
    public String msg;

    public Diagnostic(String file, Type type, int start, int end, String msg) {
        this.type = type;
        this.file = file;
        this.start = start;
        this.end = end;
        this.msg = msg;
    }

    // XXX:  support line/column

    @Override
    public String toString() {
        return "<Diagnostic:" + file + ":" + type + ":" + msg + ">";
    }
}
