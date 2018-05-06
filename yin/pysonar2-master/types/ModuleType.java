package org.python.indexer.types;

import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.Util;

public class ModuleType extends Type {

    private String file;
    private String name;
    private String qname;

    public ModuleType() { }


    @Override
    public boolean equals(Object other) {
        if (other instanceof ModuleType) {
            ModuleType co = (ModuleType) other;
            return getQname().equals(co.getQname());
        } else {
            return this == other;
        }
    }

    public ModuleType(String name, String file, Scope parent) {
        this.name = name;
        this.file = file;  // null for builtin modules
        if (file != null) {
            // This will return null iff specified file is not prefixed by
            // any path in the module search path -- i.e., the caller asked
            // the indexer to load a file not in the search path.
            qname = Util.moduleQname(file);
        }
        if (qname == null) {
            qname = name;
        }
        setTable(new Scope(parent, Scope.ScopeType.MODULE));
        getTable().setPath(qname);
        getTable().setType(this);

        // null during bootstrapping of built-in types
        if (Indexer.idx.builtins != null) {
            getTable().addSuper(Indexer.idx.builtins.BaseModule.getTable());
        }
    }

    public void setFile(String file) {
      this.file = file;
    }

    public String getFile() {
      return file;
    }

    public void setName(String name) {
      this.name = name;
    }

    public String getName() {
      return name;
    }

    public void setQname(String qname) {
      this.qname = qname;
    }

    public String getQname() {
      return qname;
    }

    @Override
    public int hashCode() {
        return "ModuleType".hashCode();
    }


    @Override
    protected void printType(CyclicTypeRecorder ctr, StringBuilder sb) {
        sb.append(getName());
    }
}
