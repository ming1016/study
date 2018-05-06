package org.python.indexer.types;

import org.python.indexer.Indexer;

public class DictType extends Type {

    public Type keyType;
    public Type valueType;

    public DictType() {
        this(Indexer.idx.builtins.unknown, Indexer.idx.builtins.unknown);
    }

    public DictType(Type key0, Type val0) {
        keyType = key0;
        valueType = val0;
        getTable().addSuper(Indexer.idx.builtins.BaseDict.getTable());
        getTable().setPath(Indexer.idx.builtins.BaseDict.getTable().getPath());
    }


    public void add(Type key, Type val) {
        keyType = UnionType.union(keyType, key);
        valueType = UnionType.union(valueType, val);
    }


    public TupleType toTupleType(int n) {
        TupleType ret = new TupleType();
        for (int i = 0; i < n; i++) {
            ret.add(keyType);
        }
        return ret;
    }

    
    @Override
    public boolean equals(Object other) {
        if (typeStack.contains(this, other)) {
            return true;
        } else if (other instanceof DictType) {
            typeStack.push(this, other);
            DictType co = (DictType)other;
            boolean ret = (co.keyType.equals(keyType)
                        && co.valueType.equals(valueType));
            typeStack.pop(this, other);
            return ret;
        } else {
            return false;
        }
    }

    @Override
    public int hashCode() {
        return "DictType".hashCode();
    }
    
    @Override
    protected void printType(CyclicTypeRecorder ctr, StringBuilder sb) {
        Integer num = ctr.visit(this);
        if (num != null) {
            sb.append("#").append(num);
        } else {
            ctr.push(this);
            sb.append("{");
            keyType.printType(ctr, sb);
            sb.append(":");
            valueType.printType(ctr, sb);
            sb.append("}");
            ctr.pop(this);
        }
    }
    
}
