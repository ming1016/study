package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.yinwang.pysonar.Analyzer;
import org.yinwang.pysonar.Binding;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.FunType;
import org.yinwang.pysonar.types.InstanceType;
import org.yinwang.pysonar.types.Type;
import org.yinwang.pysonar.types.UnionType;

import java.util.Set;

import static org.yinwang.pysonar.Binding.Kind.ATTRIBUTE;


public class Attribute extends Node {

    @Nullable
    public Node target;
    @NotNull
    public Name attr;


    public Attribute(@Nullable Node target, @NotNull Name attr, String file, int start, int end) {
        super(file, start, end);
        this.target = target;
        this.attr = attr;
        addChildren(target, attr);
    }


    public void setAttr(State s, @NotNull Type v) {
        Type targetType = transformExpr(target, s);
        if (targetType instanceof UnionType) {
            Set<Type> types = ((UnionType) targetType).types;
            for (Type tp : types) {
                setAttrType(tp, v);
            }
        } else {
            setAttrType(targetType, v);
        }
    }


    private void addRef(@NotNull Type targetType, @NotNull Set<Binding> bs) {
        for (Binding b : bs) {
            Analyzer.self.putRef(attr, b);
            if (parent != null && parent instanceof Call &&
                    b.type instanceof FunType && targetType instanceof InstanceType)
            {  // method call
                ((FunType) b.type).setSelfType(targetType);
            }
        }
    }


    private void setAttrType(@NotNull Type targetType, @NotNull Type v) {
        if (targetType.isUnknownType()) {
            Analyzer.self.putProblem(this, "Can't set attribute for UnknownType");
            return;
        }
        Set<Binding> bs = targetType.table.lookupAttr(attr.id);
        if (bs != null) {
            addRef(targetType, bs);
        }

        targetType.table.insert(attr.id, attr, v, ATTRIBUTE);
    }


    @NotNull
    @Override
    public Type transform(State s) {
        // the form of ::A in ruby
        if (target == null) {
            return transformExpr(attr, s);
        }

        Type targetType = transformExpr(target, s);
        if (targetType instanceof UnionType) {
            Set<Type> types = ((UnionType) targetType).types;
            Type retType = Type.UNKNOWN;
            for (Type tt : types) {
                retType = UnionType.union(retType, getAttrType(tt));
            }
            return retType;
        } else {
            return getAttrType(targetType);
        }
    }


    private Type getAttrType(@NotNull Type targetType) {
        Set<Binding> bs = targetType.table.lookupAttr(attr.id);
        if (bs == null) {
            Analyzer.self.putProblem(attr, "attribute not found in type: " + targetType);
            Type t = Type.UNKNOWN;
            t.table.setPath(targetType.table.extendPath(attr.id));
            return t;
        } else {
            addRef(targetType, bs);
            return State.makeUnion(bs);
        }
    }


    @NotNull
    @Override
    public String toString() {
        return "<Attribute:" + start + ":" + target + "." + attr.id + ">";
    }

}
