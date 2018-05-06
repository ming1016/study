package org.yinwang.pysonar.types;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.TypeStack;
import org.yinwang.pysonar._;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;


public abstract class Type {

    @NotNull
    public State table = new State(null, State.StateType.SCOPE);
    public String file = null;
    @NotNull
    protected static TypeStack typeStack = new TypeStack();


    public Type() {
    }


    public void setTable(@NotNull State table) {
        this.table = table;
    }


    public void setFile(String file) {
        this.file = file;
    }


    public boolean isNumType() {
        return this instanceof IntType || this instanceof FloatType;
    }


    public boolean isUnknownType() {
        return this == Type.UNKNOWN;
    }


    @NotNull
    public ModuleType asModuleType() {
        if (this instanceof UnionType) {
            for (Type t : ((UnionType) this).types) {
                if (t instanceof ModuleType) {
                    return t.asModuleType();
                }
            }
            _.die("Not containing a ModuleType");
            // can't get here, just to make the @NotNull annotation happy
            return new ModuleType(null, null, null);
        } else if (this instanceof ModuleType) {
            return (ModuleType) this;
        } else {
            _.die("Not a ModuleType");
            // can't get here, just to make the @NotNull annotation happy
            return new ModuleType(null, null, null);
        }
    }


    /**
     * Internal class to support printing in the presence of type-graph cycles.
     */
    protected class CyclicTypeRecorder {
        int count = 0;
        @NotNull
        private Map<Type, Integer> elements = new HashMap<>();
        @NotNull
        private Set<Type> used = new HashSet<>();


        public Integer push(Type t) {
            count += 1;
            elements.put(t, count);
            return count;
        }


        public void pop(Type t) {
            elements.remove(t);
            used.remove(t);
        }


        public Integer visit(Type t) {
            Integer i = elements.get(t);
            if (i != null) {
                used.add(t);
            }
            return i;
        }


        public boolean isUsed(Type t) {
            return used.contains(t);
        }
    }


    protected abstract String printType(CyclicTypeRecorder ctr);


    @NotNull
    @Override
    public String toString() {
        return printType(new CyclicTypeRecorder());
    }


    public static InstanceType UNKNOWN = new InstanceType(new ClassType("?", null, null));
    public static InstanceType CONT = new InstanceType(new ClassType("None", null, null));
    public static InstanceType NONE = new InstanceType(new ClassType("None", null, null));
    public static BoolType TRUE = new BoolType(BoolType.Value.True);
    public static BoolType FALSE = new BoolType(BoolType.Value.False);
    public static StrType STR = new StrType(null);
    public static IntType INT = new IntType();
    public static FloatType FLOAT = new FloatType();
    public static ComplexType COMPLEX = new ComplexType();
    public static BoolType BOOL = new BoolType(BoolType.Value.Undecided);
}
