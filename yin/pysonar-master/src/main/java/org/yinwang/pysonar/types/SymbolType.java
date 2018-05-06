package org.yinwang.pysonar.types;

import org.jetbrains.annotations.NotNull;


public class SymbolType extends Type {

    public String name;


    public SymbolType(@NotNull String name) {
        this.name = name;
    }


    @Override
    public boolean equals(Object other) {
        if (other instanceof SymbolType) {
            return this.name.equals(((SymbolType) other).name);
        } else {
            return false;
        }
    }


    @Override
    protected String printType(CyclicTypeRecorder ctr) {
        return ":" + name;
    }
}
