package org.yinwang.pysonar.types;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import java.util.Collection;
import java.util.HashSet;
import java.util.Set;


public class UnionType extends Type {

    public Set<Type> types;


    public UnionType() {
        this.types = new HashSet<>();
    }


    public UnionType(@NotNull Type... initialTypes) {
        this();
        for (Type nt : initialTypes) {
            addType(nt);
        }
    }


    public boolean isEmpty() {
        return types.isEmpty();
    }


    /**
     * Returns true if t1 == t2 or t1 is a union type that contains t2.
     */
    static public boolean contains(Type t1, Type t2) {
        if (t1 instanceof UnionType) {
            return ((UnionType) t1).contains(t2);
        } else {
            return t1.equals(t2);
        }
    }


    static public Type remove(Type t1, Type t2) {
        if (t1 instanceof UnionType) {
            Set<Type> types = new HashSet<>(((UnionType) t1).types);
            types.remove(t2);
            return UnionType.newUnion(types);
        } else if (t1 != Type.CONT && t1 == t2) {
            return Type.UNKNOWN;
        } else {
            return t1;
        }
    }


    @NotNull
    static public Type newUnion(@NotNull Collection<Type> types) {
        Type t = Type.UNKNOWN;
        for (Type nt : types) {
            t = union(t, nt);
        }
        return t;
    }


    public void setTypes(Set<Type> types) {
        this.types = types;
    }


    public void addType(@NotNull Type t) {
        if (t instanceof UnionType) {
            types.addAll(((UnionType) t).types);
        } else {
            types.add(t);
        }
    }


    public boolean contains(Type t) {
        return types.contains(t);
    }


    // take a union of two types
    // with preference: other > None > Cont > unknown
    @NotNull
    public static Type union(@NotNull Type u, @NotNull Type v) {
        if (u.equals(v)) {
            return u;
        } else if (u != Type.UNKNOWN && v == Type.UNKNOWN) {
            return u;
        } else if (v != Type.UNKNOWN && u == Type.UNKNOWN) {
            return v;
        } else if (u != Type.NONE && v == Type.NONE) {
            return u;
        } else if (v != Type.NONE && v == Type.NONE) {
            return v;
        } else {
            return new UnionType(u, v);
        }
    }


    /**
     * Returns the first alternate whose type is not unknown and
     * is not {@link org.yinwang.pysonar.Analyzer.idx.builtins.None}.
     *
     * @return the first non-unknown, non-{@code None} alternate, or {@code null} if none found
     */
    @Nullable
    public Type firstUseful() {
        for (Type type : types) {
            if (!type.isUnknownType() && type != Type.NONE) {
                return type;
            }
        }
        return null;
    }


    @Override
    public boolean equals(Object other) {
        if (typeStack.contains(this, other)) {
            return true;
        } else if (other instanceof UnionType) {
            Set<Type> types1 = types;
            Set<Type> types2 = ((UnionType) other).types;
            if (types1.size() != types2.size()) {
                return false;
            } else {
                typeStack.push(this, other);
                for (Type t : types2) {
                    if (!types1.contains(t)) {
                        typeStack.pop(this, other);
                        return false;
                    }
                }
                for (Type t : types1) {
                    if (!types2.contains(t)) {
                        typeStack.pop(this, other);
                        return false;
                    }
                }
                typeStack.pop(this, other);
                return true;
            }
        } else {
            return false;
        }
    }


    @Override
    public int hashCode() {
        return "UnionType".hashCode();
    }


    @Override
    protected String printType(@NotNull CyclicTypeRecorder ctr) {
        StringBuilder sb = new StringBuilder();

        Integer num = ctr.visit(this);
        if (num != null) {
            sb.append("#").append(num);
        } else {
            int newNum = ctr.push(this);
            boolean first = true;
            sb.append("{");

            for (Type t : types) {
                if (!first) {
                    sb.append(" | ");
                }
                sb.append(t.printType(ctr));
                first = false;
            }

            if (ctr.isUsed(this)) {
                sb.append("=#").append(newNum).append(":");
            }

            sb.append("}");
            ctr.pop(this);
        }

        return sb.toString();
    }

}
