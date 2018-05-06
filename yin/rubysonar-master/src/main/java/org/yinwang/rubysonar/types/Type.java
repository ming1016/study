package org.yinwang.rubysonar.types;

import org.jetbrains.annotations.NotNull;
import org.yinwang.rubysonar.Analyzer;
import org.yinwang.rubysonar.State;
import org.yinwang.rubysonar.TypeStack;
import org.yinwang.rubysonar._;

import java.math.BigInteger;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;


public abstract class Type {

    @NotNull
    public State table = new State(Analyzer.self.globaltable, State.StateType.INSTANCE);
    public String file = null;
    public boolean mutated = false;


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


    public boolean isMutated() {
        return mutated;
    }


    public void setMutated(boolean mutated) {
        this.mutated = mutated;
    }


    public boolean isBool() {
        return this instanceof BoolType;
    }


    public boolean isUndecidedBool() {
        return isBool() && asBool().value == BoolType.Value.Undecided &&
                asBool().s1 != null && asBool().s2 != null;
    }


    public BoolType asBool() {
        return (BoolType) this;
    }


    public boolean isClassType() {
        return this instanceof ClassType;
    }


    public boolean isDictType() {
        return this instanceof DictType;
    }


    public boolean isFuncType() {
        return this instanceof FunType;
    }


    public boolean isInstanceType() {
        return this instanceof InstanceType;
    }


    public boolean isListType() {
        return this instanceof ListType;
    }


    public boolean isModuleType() {
        return this instanceof ModuleType;
    }


    public boolean isNumType() {
        return this instanceof IntType || this instanceof FloatType;
    }


    public boolean isIntType() {
        return this instanceof IntType;
    }


    public boolean isFloatType() {
        return this instanceof FloatType;
    }


    public boolean isStrType() {
        return this == STR;
    }


    public boolean isTupleType() {
        return this instanceof TupleType;
    }


    public boolean isUnionType() {
        return this instanceof UnionType;
    }


    public boolean isUnknownType() {
        return this == Type.UNKNOWN;
    }


    @NotNull
    public ClassType asClassType() {
        return (ClassType) this;
    }


    @NotNull
    public DictType asDictType() {
        return (DictType) this;
    }


    @NotNull
    public IntType asIntType() {
        return (IntType) this;
    }


    @NotNull
    public FloatType asFloatType() {
        return (FloatType) this;
    }


    @NotNull
    public FunType asFuncType() {
        return (FunType) this;
    }


    @NotNull
    public InstanceType asInstanceType() {
        return (InstanceType) this;
    }


    @NotNull
    public ListType asListType() {
        return (ListType) this;
    }


    @NotNull
    public ModuleType asModuleType() {
        if (this.isUnionType()) {
            for (Type t : this.asUnionType().types) {
                if (t.isModuleType()) {
                    return t.asModuleType();
                }
            }
            _.die("Not containing a ModuleType");
            // can't get here, just to make the @NotNull annotation happy
            return new ModuleType(null, null, null);
        } else if (this.isModuleType()) {
            return (ModuleType) this;
        } else {
            _.die("Not a ModuleType");
            // can't get here, just to make the @NotNull annotation happy
            return new ModuleType(null, null, null);
        }
    }


    @NotNull
    public TupleType asTupleType() {
        return (TupleType) this;
    }


    @NotNull
    public UnionType asUnionType() {
        return (UnionType) this;
    }


    public boolean isTrue() {
        if (this == TRUE) {
            return true;
        }
        if (this == FALSE || this.isUndecidedBool()) {
            return false;
        }
        if (this.isIntType() && (this.asIntType().lt(BigInteger.ZERO) || this.asIntType().gt(BigInteger.ZERO))) {
            return true;
        }
        if (this.isIntType() && this.asIntType().isZero()) {
            return false;
        }
        if (this.isFloatType() && (this.asFloatType().lt(0) || this.asFloatType().gt(0))) {
            return true;
        }
        if (this.isFloatType() && this.asFloatType().isZero()) {
            return false;
        }
        if (this != NIL) {
            return true;
        }
        return false;
    }


    public boolean isFalse() {
        if (this == FALSE) {
            return true;
        }
        if (this == TRUE || this.isUndecidedBool()) {
            return false;
        }
        if (this.isIntType() && this.asIntType().isZero()) {
            return true;
        }
        if (this.isFloatType() && this.asFloatType().isZero()) {
            return true;
        }
        if (this == NIL) {
            return true;
        }
        return false;
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
    public static InstanceType CONT = new InstanceType(new ClassType("nil", null, null));
    public static InstanceType NIL = new InstanceType(new ClassType("nil", null, null));
    public static StrType STR = new StrType(null);
    public static IntType INT = new IntType();
    public static FloatType FLOAT = new FloatType();
    public static BoolType BOOL = new BoolType(BoolType.Value.Undecided);
    public static BoolType TRUE = new BoolType(BoolType.Value.True);
    public static BoolType FALSE = new BoolType(BoolType.Value.False);
}
