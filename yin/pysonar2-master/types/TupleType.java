package org.python.indexer.types;

import org.python.indexer.Indexer;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class TupleType extends Type {

    private List<Type> eltTypes;

    public TupleType() {
        this.eltTypes = new ArrayList<Type>();
        getTable().addSuper(Indexer.idx.builtins.BaseTuple.getTable());
        getTable().setPath(Indexer.idx.builtins.BaseTuple.getTable().getPath());
    }

    public TupleType(List<Type> eltTypes) {
        this();
        this.eltTypes = eltTypes;
    }

    public TupleType(Type elt0) {
        this();
        this.eltTypes.add(elt0);
    }

    public TupleType(Type elt0, Type elt1) {
        this();
        this.eltTypes.add(elt0);
        this.eltTypes.add(elt1);
    }

    public TupleType(Type... types) {
        this();
        Collections.addAll(this.eltTypes, types);
    }

    public void setElementTypes(List<Type> eltTypes) {
        this.eltTypes = eltTypes;
    }

    public List<Type> getElementTypes() {
        return eltTypes;
    }

    public void add(Type elt) {
        eltTypes.add(elt);
    }

    public Type get(int i) {
        return eltTypes.get(i);
    }

    public ListType toListType() {
        ListType t = new ListType();
        for (Type e : eltTypes) {
            t.add(e);
        }
        return t;
    }


    @Override
    public boolean equals(Object other) {
        if (typeStack.contains(this, other)) {
            return true;
        } else if (other instanceof TupleType) {
            List<Type> types1 = getElementTypes();
            List<Type> types2 = ((TupleType) other).getElementTypes();
            if (types1.size() != types2.size()) {
                return false;
            } else {
                typeStack.push(this, other);
                for (int i = 0; i < types1.size(); i++) {
                    if (!types1.get(i).equals(types2.get(i))) {
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
        return "TupleType".hashCode();
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
            for (Type t : getElementTypes()) {
                if (!first) {
                    sbElems.append(", ");
                }
                t.printType(ctr, sbElems);
                first = false;
            }
            if (getElementTypes().size() > 1) {
                sb.append("(");
            }
            if (ctr.isUsed(this)) {
                sb.append("=#").append(newNum).append(":");
            }
            sb.append(sbElems);
            if (getElementTypes().size() > 1) {
                sb.append(")");
            }
            ctr.pop(this);
        }
    }

}
