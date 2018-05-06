package org.yinwang.pysonar.types;


public class IntType extends Type {

    @Override
    public boolean equals(Object other) {
        return other instanceof IntType;
    }


    @Override
    protected String printType(Type.CyclicTypeRecorder ctr) {
        return "int";
    }

}
