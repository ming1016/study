package org.yinwang.pysonar.types;


public class FloatType extends Type {

    @Override
    public boolean equals(Object other) {
        return other instanceof FloatType;
    }


    @Override
    protected String printType(CyclicTypeRecorder ctr) {
        return "float";
    }

}
