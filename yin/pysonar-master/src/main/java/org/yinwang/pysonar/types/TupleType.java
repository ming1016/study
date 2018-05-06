package org.yinwang.pysonar.types;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.Analyzer;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;


public class TupleType extends Type {

    public List<Type> eltTypes;


    public TupleType() {
        this.eltTypes = new ArrayList<>();
        table.addSuper(Analyzer.self.builtins.BaseTuple.table);
        table.setPath(Analyzer.self.builtins.BaseTuple.table.path);
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


    public void add(Type elt) {
        eltTypes.add(elt);
    }


    public Type get(int i) {
        return eltTypes.get(i);
    }


    @NotNull
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
            List<Type> types1 = eltTypes;
            List<Type> types2 = ((TupleType) other).eltTypes;

            if (types1.size() == types2.size()) {
                typeStack.push(this, other);
                for (int i = 0; i < types1.size(); i++) {
                    if (!types1.get(i).equals(types2.get(i))) {
                        typeStack.pop(this, other);
                        return false;
                    }
                }
                typeStack.pop(this, other);
                return true;
            } else {
                return false;
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
    protected String printType(@NotNull CyclicTypeRecorder ctr) {
        StringBuilder sb = new StringBuilder();

        Integer num = ctr.visit(this);
        if (num != null) {
            sb.append("#").append(num);
        } else {
            int newNum = ctr.push(this);
            boolean first = true;
            if (eltTypes.size() != 1) {
                sb.append("(");
            }

            for (Type t : eltTypes) {
                if (!first) {
                    sb.append(", ");
                }
                sb.append(t.printType(ctr));
                first = false;
            }

            if (ctr.isUsed(this)) {
                sb.append("=#").append(newNum).append(":");
            }

            if (eltTypes.size() != 1) {
                sb.append(")");
            }
            ctr.pop(this);
        }
        return sb.toString();
    }

}
