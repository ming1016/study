package org.python.indexer.types;

import org.python.indexer.Scope;

public class ClassType extends Type {

    private String name;
    private InstanceType canon;

    public ClassType() {
        this("<unknown>", null);
    }


    @Override
    public boolean equals(Object other) {
//        if (other instanceof ClassType) {
//            ClassType co = (ClassType) other;
//            return name.equals(co.getName());
//        } else {
            return this == other;
//        }
    }


    public ClassType(String name, Scope parent) {
        this.name = name;
        this.setTable(new Scope(parent, Scope.ScopeType.CLASS));
        this.getTable().setType(this);
        if (parent != null) {
            this.getTable().setPath(parent.extendPath(name));
        } else {
            this.getTable().setPath(name);
        }
    }

    public ClassType(String name, Scope parent, ClassType superClass) {
        this(name, parent);
        if (superClass != null) {
            addSuper(superClass);
        }
    }

    public void setName(String name) {
      this.name = name;
    }

    public String getName() {
      return name;
    }

    public void addSuper(Type sp) {
        getTable().addSuper(sp.getTable());
    }
    
    public InstanceType getCanon() throws Exception {
        if (canon == null) {
            canon = new InstanceType(this, null, null, 0);
        }
        return canon;
    }

    public void setCanon(InstanceType canon) {
        this.canon = canon;
    }


    @Override
    public int hashCode() {
        return "ClassType".hashCode();
    }


    // XXX: Type equality for ClassType is now object identity, because classes
    // can have have multiple definition sites so they shouldn't be considered
    // identical even if they have the
    // same path name (qname). NInstance type equality is now rigorously
    // defined.
    
    @Override
    protected void printType(CyclicTypeRecorder ctr, StringBuilder sb) {
        sb.append("<").append(getName()).append(">");
    }

}
