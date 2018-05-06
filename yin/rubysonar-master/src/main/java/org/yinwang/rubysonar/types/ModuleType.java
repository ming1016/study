package org.yinwang.rubysonar.types;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.yinwang.rubysonar.State;


public class ModuleType extends Type {

    @NotNull
    public String name;
    @Nullable
    public String qname;


    public ModuleType(@NotNull String name, @Nullable String file, @NotNull State parent) {
        this.name = name;
        this.file = file;  // null for builtin modules
        if (parent.path.isEmpty()) {
            qname = name;
        } else {
            qname = parent.path + "::" + name;
        }
        setTable(new State(parent, State.StateType.MODULE));
        table.setPath(qname);
        table.setType(this);
    }


    public void setName(String name) {
        this.name = name;
    }


    @Override
    public int hashCode() {
        return "ModuleType".hashCode();
    }


    @Override
    public boolean equals(Object other) {
        if (other instanceof ModuleType) {
            ModuleType co = (ModuleType) other;
            if (file != null) {
                return file.equals(co.file);
            }
        }
        return this == other;
    }


    @Override
    protected String printType(CyclicTypeRecorder ctr) {
        return name;
    }
}
