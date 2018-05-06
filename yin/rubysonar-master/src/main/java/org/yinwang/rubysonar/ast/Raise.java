package org.yinwang.rubysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.rubysonar.State;
import org.yinwang.rubysonar.types.Type;


public class Raise extends Node {

    public Node exceptionType;
    public Node inst;
    public Node traceback;


    public Raise(Node exceptionType, Node inst, Node traceback, String file, int start, int end) {
        super(file, start, end);
        this.exceptionType = exceptionType;
        this.inst = inst;
        this.traceback = traceback;
        addChildren(exceptionType, inst, traceback);
    }


    @NotNull
    @Override
    public Type transform(State s) {
        if (exceptionType != null) {
            transformExpr(exceptionType, s);
        }
        if (inst != null) {
            transformExpr(inst, s);
        }
        if (traceback != null) {
            transformExpr(traceback, s);
        }
        return Type.CONT;
    }


    @NotNull
    @Override
    public String toString() {
        return "(raise:" + traceback + ":" + exceptionType + ")";
    }


}
