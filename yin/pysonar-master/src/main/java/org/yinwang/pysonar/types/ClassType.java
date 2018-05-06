package org.yinwang.pysonar.types;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.yinwang.pysonar.State;


public class ClassType extends Type {

    public String name;
    public InstanceType canon;
    public Type superclass;


    public ClassType(@NotNull String name, @Nullable State parent) {
        this.name = name;
        this.setTable(new State(parent, State.StateType.CLASS));
        table.setType(this);
        if (parent != null) {
            table.setPath(parent.extendPath(name));
        } else {
            table.setPath(name);
        }
    }


    public ClassType(@NotNull String name, State parent, @Nullable ClassType superClass) {
        this(name, parent);
        if (superClass != null) {
            addSuper(superClass);
        }
    }


    public void setName(String name) {
        this.name = name;
    }


    public void addSuper(@NotNull Type superclass) {
        this.superclass = superclass;
        table.addSuper(superclass.table);
    }


    public InstanceType getCanon() {
        if (canon == null) {
            canon = new InstanceType(this);
        }
        return canon;
    }


    @Override
    public boolean equals(Object other) {
        return this == other;
    }


    @Override
    protected String printType(CyclicTypeRecorder ctr) {
        StringBuilder sb = new StringBuilder();
        sb.append("<").append(name).append(">");
        return sb.toString();
    }
}
