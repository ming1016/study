package org.python.indexer.types;

import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.ast.FunctionDef;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class FunType extends Type {

    public class Arrow {
        public Type from;
        public Type to;

        public Arrow(Type from, Type to) {
            this.from = from;
            this.to = to;
        }
    }

    private List<Arrow> arrows = new ArrayList<Arrow>();
    public FunctionDef func;
    public ClassType cls = null;
    private Scope env;
    public Type selfType;                 // self's type for calls
    public List<Type> defaultTypes;       // types for default parameters (evaluated at def time)

    public FunType() {
    }

    public FunType(FunctionDef func, Scope env) {
        this.func = func;
        this.env = env;
    }

    public FunType(Type from, Type to) {
        setMapping(from, to);
        getTable().addSuper(Indexer.idx.builtins.BaseFunction.getTable());
        getTable().setPath(Indexer.idx.builtins.BaseFunction.getTable().getPath());
    }


    public boolean contains(Type from) {
        for (Arrow a : arrows) {
            if (Type.subtypeOf(a.from, from)) {
                return true;
            }
        }
        return false;
    }


    public void setMapping(Type from, Type to) {
        if (arrows.isEmpty()) {
            arrows.add(new Arrow(from, to));
        } else {
            List<Arrow> newArrows = new ArrayList<Arrow>();

            for (Arrow a : arrows) {
                if (!Type.subtypeOf(from, a.from)) {
                    newArrows.add(a);
                }
            }

            arrows = newArrows;

            if (!contains(from)) {
                arrows.add(new Arrow(from, to));
            }
        }
    }


    public Type getMapping(Type from) {
        for (Arrow a : arrows) {
            if (from.equals(a.from)) {
                return a.to;
            }
        }
        return null;
    }


    public Type getReturnType() {
        if (!arrows.isEmpty()) {
            return arrows.get(0).to;
        } else {
            return Indexer.idx.builtins.unknown;
        }
    }


    public FunctionDef getFunc() {
        return func;
    }

    public Scope getEnv() {
        return env;
    }

    public ClassType getCls() {
        return cls;
    }

    public void setCls(ClassType cls) {
        this.cls = cls;
    }

    public Type getSelfType() {
        return selfType;
    }

    public void setSelfType(Type selfType) {
        this.selfType = selfType;
    }

    public void clearSelfType() {
        this.selfType = null;
    }

    public List<Type> getDefaultTypes() {
        return defaultTypes;
    }

    public void setDefaultTypes(List<Type> defaultTypes) {
        this.defaultTypes = defaultTypes;
    }


    @Override
    public boolean equals(Object other) {
        if (other instanceof FunType) {
            FunType fo = (FunType) other;
            if (fo.getFunc() == null && getFunc() == null) {
                return true;
            } else if (fo.getFunc() != null && getFunc() != null) {
                return fo.getFunc().equals(getFunc());
            } else {
                return false;
            }
        } else {
            return false;
        }
    }


    static Type removeNoneReturn(Type toType) {
        if (toType.isUnionType()) {
            Set<Type> types = new HashSet<Type>(toType.asUnionType().getTypes());
            types.remove(Indexer.idx.builtins.Cont);
            return UnionType.newUnion(types);
        } else {
            return toType;
        }
    }


    @Override
    public int hashCode() {
        return "FunType".hashCode();
    }


    @Override
    protected void printType(CyclicTypeRecorder ctr, StringBuilder sb) {

        Integer num = ctr.visit(this);
        if (num != null) {
            sb.append("#").append(num);
        } else {
            int newNum = ctr.push(this);

            int i = 0;
            for (Arrow a : arrows) {
                a.from.printType(ctr, sb);
                sb.append(" -> ");
                a.to.printType(ctr, sb);
                if (i < arrows.size() - 1) {
                    sb.append(" | ");
                }
                i++;
            }

            if (ctr.isUsed(this)) {
                sb.append("=#").append(newNum).append(": ");
            }
            ctr.pop(this);
        }
    }

}
