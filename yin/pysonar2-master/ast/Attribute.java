package org.python.indexer.ast;

import org.python.indexer.Binding;
import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.types.Type;
import org.python.indexer.types.UnionType;

import java.util.Set;

import static org.python.indexer.Binding.Kind.ATTRIBUTE;

public class Attribute extends Node {

    static final long serialVersionUID = -1120979305017812255L;

    public Node target;
    public Name attr;

    public Attribute(Node target, Name attr) {
        this(target, attr, 0, 1);
    }

    public Attribute(Node target, Name attr, int start, int end) {
        super(start, end);
        setTarget(target);
        setAttr(attr);
        addChildren(target, attr);
    }

    public String getAttributeName() {
        return attr.getId();
    }

    /**
     * Sets the attribute node.  Used when constructing the AST.
     * @throws IllegalArgumentException if the param is null
     */
    public void setAttr(Name attr) {
        if (attr == null) {
            throw new IllegalArgumentException("param cannot be null");
        }
        this.attr = attr;
    }

    public Name getAttr() {
        return attr;
    }

    /**
     * Sets the target node.  Used when constructing the AST.
     * @throws IllegalArgumentException if the param is null
     */
    public void setTarget(Node target) {
        if (target == null) {
            throw new IllegalArgumentException("param cannot be null");
        }
        this.target = target;
    }

    public Node getTarget() {
        return target;
    }

    /**
     * Assign some definite value to the attribute.  Used during the name
     * resolution pass.  This method is called when this node is in the lvalue of
     * an assignment, in which case it is called in lieu of {@link #resolve}.<p>
     */
    public void setAttr(Scope s, Type v, int tag) throws Exception {
        Type targetType = resolveExpr(target, s, tag);
        if (targetType.isUnionType()) {
            Set<Type> types = targetType.asUnionType().getTypes();
            for (Type tp : types) {
                setAttrType(tp, v, tag);
            }
        } else {
            setAttrType(targetType, v, tag);
        }
    }
    
    private void setAttrType(Type targetType, Type v, int tag) {
        if (targetType.isUnknownType()) {
            Indexer.idx.putProblem(this, "Can't set attribute for UnknownType");
            return;
        }
        Binding b = targetType.getTable().putAttr(attr.getId(), attr, v, ATTRIBUTE, tag);
        if (b != null) {
            setType(attr.setType(b.getType()));
        }
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        Type targetType = resolveExpr(target, s, tag);
        if (targetType.isUnionType()) {
            Set<Type> types = targetType.asUnionType().getTypes();
            Type retType = Indexer.idx.builtins.unknown;
            for (Type tt : types) {
                retType = UnionType.union(retType, getAttrType(tt));
            }
            return retType;
        } else {
            return getAttrType(targetType);
        }
    }

    private Type getAttrType(Type targetType) {
        Binding b = targetType.getTable().lookupAttr(attr.getId());
        if (b == null) {
            Indexer.idx.putProblem(attr, "attribute not found in type: " + targetType);
            Type t = Indexer.idx.builtins.unknown;
            t.getTable().setPath(targetType.getTable().extendPath(attr.getId()));
            return t;
        } else {
            Indexer.idx.putLocation(attr, b);
            if (getParent().isCall() && b.getType().isFuncType() && targetType.isInstanceType()) {  // method call
                b.getType().asFuncType().setSelfType(targetType);
            }
            return b.getType();
        }
    }

    @Override
    public String toString() {
        return "<Attribute:" + start() + ":" + target + "." + getAttributeName() + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNode(target, v);
            visitNode(attr, v);
        }
    }
}
