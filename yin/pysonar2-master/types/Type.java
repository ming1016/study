package org.python.indexer.types;

import org.python.indexer.Builtins;
import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.TypeStack;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public abstract class Type {

    public Scope table;

    protected static final String LIBRARY_URL = Builtins.LIBRARY_URL;
    protected static final String TUTORIAL_URL = Builtins.TUTORIAL_URL;
    protected static final String REFERENCE_URL = Builtins.REFERENCE_URL;

    protected static TypeStack typeStack = new TypeStack();


    public Type() {
    }

    public void setTable(Scope table) {
        this.table = table;
    }

    public Scope getTable() {
        if (table == null) {
            table = new Scope(null, Scope.ScopeType.SCOPE);
        }
        return table;
    }


    /**
     * Returns {@code true} if this Python type is implemented in native code
     * (i.e., C, Java, C# or some other host language.)
     */
    public boolean isNative() {
        return Indexer.idx.builtins.isNative(this);
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
        return (this == Indexer.idx.builtins.BaseNum ||
                this == Indexer.idx.builtins.BaseFloat ||
                this == Indexer.idx.builtins.BaseComplex);
    }

    public boolean isStrType() {
        return this == Indexer.idx.builtins.BaseStr;
    }

    public boolean isTupleType() {
        return this instanceof TupleType;
    }

    public boolean isUnionType() {
        return this instanceof UnionType;
    }

    public boolean isUnknownType() {
        return this instanceof UnknownType;
    }

    public ClassType asClassType() {
        return (ClassType) this;
    }

    public DictType asDictType() {
        return (DictType) this;
    }

    public FunType asFuncType() {
        return (FunType) this;
    }

    public InstanceType asInstanceType() {
        return (InstanceType) this;
    }

    public ListType asListType() {
        return (ListType) this;
    }

    public ModuleType asModuleType() {
        if (this.isUnionType()) {
            for (Type t : this.asUnionType().getTypes()) {
                if (t.isModuleType()) {
                    return t.asModuleType();
                }
            }
            return null;
        } else if (this.isModuleType()) {
            return (ModuleType) this;
        } else {
            return null;
        }
    }

    public TupleType asTupleType() {
        return (TupleType) this;
    }

    public UnionType asUnionType() {
        return (UnionType) this;
    }

    public UnknownType asUnknownType() {
        return (UnknownType) this;
    }

    public static boolean subtypeOf(Type type1, Type type2) {
        if (typeStack.contains(type1, type2)) {
            return true;
        } else if (type1 instanceof TupleType && type2 instanceof TupleType) {
            List<Type> elems1 = ((TupleType) type1).getElementTypes();
            List<Type> elems2 = ((TupleType) type2).getElementTypes();

            if (elems1.size() == elems2.size()) {
                typeStack.push(type1, type2);
                for (int i = 0; i < elems1.size(); i++) {
                    if (!elems2.get(i).isUnknownType() &&
                            !elems1.get(i).equals(elems2.get(i))) {
                        typeStack.pop(type1, type2);
                        return false;
                    }
                }
                typeStack.pop(type1, type2);
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    /**
     * Internal class to support printing in the presence of type-graph cycles.
     */
    protected class CyclicTypeRecorder {
        int count = 0;
        private Map<Type, Integer> elements = new HashMap<Type, Integer>();
        private Map<Type, Integer> used = new HashMap<Type, Integer>();

        /**
         * Get the instance number for the specified type.
         *
         * @return the instance number:  positive if the type was already recorded,
         *         or its negative if the type was just recorded and assigned a number.
         */
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
                used.put(t, 1);
            }
            return i;
        }

        public boolean isUsed(Type t) {
            return used.containsKey(t);
        }

    }

    public abstract boolean equals(Object other);

    protected abstract void printType(CyclicTypeRecorder ctr, StringBuilder sb);


    @Override
    public String toString() {
        StringBuilder input = new StringBuilder();
        printType(new CyclicTypeRecorder(), input);
        return input.toString();
    }

}
