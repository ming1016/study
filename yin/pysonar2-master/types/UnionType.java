package org.python.indexer.types;

import org.python.indexer.Indexer;

import java.util.Collection;
import java.util.HashSet;
import java.util.Set;

/**
 * A union type is a set of several other types. During a union operation,
 * destructuring happens and unknown types are unified.
 */
public class UnionType extends Type {

    private Set<Type> types;

    public UnionType() {
        this.types = new HashSet<Type>();
    }

    public UnionType(Type... initialTypes) {
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
            Set<Type> types = new HashSet<Type>(((UnionType) t1).getTypes());
            types.remove(t2);
            return UnionType.newUnion(types);
        } else if (t1 == t2) {
            return Indexer.idx.builtins.unknown;
        } else {
            return t1;
        }
    }


    static public Type newUnion(Collection<Type> types) {
        Type t = Indexer.idx.builtins.unknown;
        for (Type nt : types) {
            t = union(t, nt);
        }
        return t;
    }

    public void setTypes(Set<Type> types) {
        this.types = types;
    }

    public Set<Type> getTypes() {
        return types;
    }

    public void addType(Type t) {
        if (t.isUnionType()) {
            types.addAll(t.asUnionType().types);
        } else {
            types.add(t);
        }
    }

    public boolean contains(Type t) {
        return types.contains(t);
    }

    public static Type union(Type u, Type v) {
        if (u.equals(v)) {
            return u;
        } else if (u.isUnknownType()) {
            return v;
        } else if (v.isUnknownType()) {
            return u;
        } else {
            return new UnionType(u, v);
        }
    }


    /**
     * Returns the first alternate whose type is not unknown and
     * is not {@link Indexer.idx.builtins.None}.
     *
     * @return the first non-unknown, non-{@code None} alternate, or {@code null} if none found
     */
    public Type firstUseful() {
        for (Type type : types) {
            if (!type.isUnknownType() && type != Indexer.idx.builtins.None) {
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
            Set<Type> types1 = getTypes();
            Set<Type> types2 = ((UnionType) other).getTypes();
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
    protected void printType(CyclicTypeRecorder ctr, StringBuilder sb) {
        Integer num = ctr.visit(this);
        if (num != null) {
            sb.append("#").append(num);
        } else {
            StringBuilder sbElems = new StringBuilder();
            int newNum = ctr.push(this);
            boolean first = true;
            for (Type t : types) {
                if (!first) {
                    sbElems.append(" | ");
                }
                t.printType(ctr, sbElems);
                first = false;
            }
            sb.append("{");
            if (ctr.isUsed(this)) {
                sb.append("=#").append(newNum).append(":");
            }
            sb.append(sbElems);
            sb.append("}");
            ctr.pop(this);
        }
    }

}
