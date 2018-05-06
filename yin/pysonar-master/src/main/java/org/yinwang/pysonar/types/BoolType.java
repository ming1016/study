package org.yinwang.pysonar.types;

import org.yinwang.pysonar.Analyzer;
import org.yinwang.pysonar.State;


public class BoolType extends Type {

    public enum Value {
        True,
        False,
        Undecided
    }


    public Value value;
    public State s1;
    public State s2;


    public BoolType(Value value) {
        this.value = value;
    }


    public BoolType(State s1, State s2) {
        this.value = Value.Undecided;
        this.s1 = s1;
        this.s2 = s2;
    }


    public void setValue(Value value) {
        this.value = value;
    }


    public void setS1(State s1) {
        this.s1 = s1;
    }


    public void setS2(State s2) {
        this.s2 = s2;
    }


    public BoolType swap() {
        return new BoolType(s2, s1);
    }


    @Override
    public boolean equals(Object other) {
        return (other instanceof BoolType);
    }


    @Override
    protected String printType(CyclicTypeRecorder ctr) {
        if (Analyzer.self.hasOption("debug")) {
            return "bool(" + value + ")";
        } else {
            return "bool";
        }
    }
}
