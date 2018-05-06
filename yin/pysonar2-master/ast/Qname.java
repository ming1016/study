package org.python.indexer.ast;

import org.python.indexer.Binding;
import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.Util;
import org.python.indexer.types.ModuleType;
import org.python.indexer.types.Type;

import java.io.File;

/**
 * Recursive doubly-linked list representation of a qualified module name,
 * either absolute or relative.  Similar to {@link Attribute}, but handles
 * leading dots and other import-specific special cases.<p>
 *
 * Qualified names with leading dots are given {@code NQname} elements for each
 * leading dot.  Dots separating simple names are not given {@code NQname}
 * elements. <p>
 */
public class Qname extends Node {

    static final long serialVersionUID = -5892553606852895686L;

    private Qname next;
    private Name name;

    public Qname(Qname next, Name name) {
        this(next, name, 0, 1);
    }

    public Qname(Qname next, Name name, int start, int end) {
        super(start, end);
        if (name == null)
            throw new IllegalArgumentException("null name");
        this.name = name;
        this.next = next;
        addChildren(name, next);
    }

    /**
     * Returns this component of the qname chain.
     */
    public Name getName() {
        return name;
    }

    /**
     * Returns the previous component of this qname chain, or {@code null} if
     * this is the first component.
     */
    public Qname getPrevious() {
        Node parent = getParent();
        if (parent instanceof Qname) {
            return (Qname)parent;
        }
        return null;
    }

    /**
     * Returns the next component of the chain, or {@code null} if this is
     * the last component.
     */
    public Qname getNext() {
        return next;
    }

    /**
     * Returns the last/bottom component of the chain.
     */
    public Qname getBottom() {
        return next == null ? this : next.getBottom();
    }

    /**
     * Returns {@code true} if this is the first/top component of the chain,
     * or if the name is unqualified (i.e. has only one component, no dots).
     */
    public boolean isTop() {
        return getPrevious() == null;
    }

    /**
     * Returns {@code true} if this is the last/bottom component of the chain,
     * or if the name is unqualified (i.e. has only one component, no dots).
     */
    public boolean isBottom() {
        return next == null;
    }

    /**
     * Returns {@code true} if this qname represents a simple, non-dotted module
     * name such as "os", "random" or "foo".
     */
    public boolean isUnqualified() {
        return isTop() && isBottom();
    }

    /**
     * Joins all components in this qname chain, beginning with the
     * current component.
     */
    public String toQname() {
        return isBottom() ? name.getId() : name.getId() + "." + next.toQname();
    }

    /**
     * Returns the qname down to (and including) this component, ending
     * with this component's name.  For instance, if this {@code NQname}
     * instance represents the {@code foo} in {@code org.foo.bar}, this
     * method will return {@code org.foo}.
     */
    public String thisQname() {
        Qname n = getTop();
        StringBuilder sb = new StringBuilder();
        sb.append(n.name.getId());
        while (n != this) {
            sb.append(".");
            n = n.next;
            sb.append(n.name.getId());
        }
        return sb.toString();
    }

    /**
     * Returns the top (first) component in the chain.
     */
    public Qname getTop() {
        return isTop() ? this : getPrevious().getTop();
    }

    /**
     * Returns {@code true} if this qname component is a leading dot.
     */
    public boolean isDot() {
        return ".".equals(name.getId());
    }

    /**
     * Resolves and loads the module named by this qname.
     * @return the module represented by the qname up to this point.
     */
    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        setType(name.setType(Indexer.idx.builtins.unknown));

        // Check for top-level native or standard module.
        if (isUnqualified()) {
            ModuleType mt = Indexer.idx.loadModule(name.getId());
            if (mt != null) {
                return setType(name.setType(mt));
            }
        } else {
            // Check for second-level builtin such as "os.path".
            ModuleType mt = Indexer.idx.getBuiltinModule(thisQname());
            if (mt != null) {
                setType(name.setType(mt));
                if (next != null) resolveExpr(next, s, tag);
                return mt;
            }
        }

        return resolveInFilesystem(s, tag);
    }

    private Type resolveInFilesystem(Scope s, int tag) throws Exception {
        ModuleType start = getStartModule(s);
        
        if (start == null) {
            reportUnresolvedModule();
            return Indexer.idx.builtins.unknown;
        }

        String qname = start.getTable().getPath();
        String relQname;
        if (isDot()) {
            relQname = Util.getQnameParent(qname);
        } else if (!isTop()) {
            relQname = qname + "." + name.getId();
        } else {
            // top name:  first look in current dir, then sys.path
            String dirQname = isInitPy() ? qname : Util.getQnameParent(qname);
            relQname = dirQname + "." + name.getId();
            if (Indexer.idx.loadModule(relQname) == null) {
                relQname = name.getId();
            }
        }
        
        ModuleType mod = Indexer.idx.loadModule(relQname);
        if (mod == null) {
            reportUnresolvedModule();
            return Indexer.idx.builtins.unknown;
        }
        setType(name.setType(mod));

        if (!isTop() && mod.getFile() != null) {
            Scope parentPkg = getPrevious().getTable();
            Binding mb = Indexer.idx.moduleTable.lookup(mod.getFile());
            parentPkg.put(name.getId(), mb);
        }

        if (next != null) resolveExpr(next, s, tag);
        return getType();
    }

    private boolean isInitPy()  {
        String path = getFile();
        if (path == null) {
            return false;
        }
        return new File(path).getName().equals("__init__.py");
    }

    private ModuleType getStartModule(Scope s) throws Exception {
        if (!isTop()) {
            return getPrevious().getType().asModuleType();
        }

        // Start with module for current file (i.e. containing directory).

        ModuleType start = null;
        Scope mtable = s.getGlobalTable();
        if (mtable != null) {
            start = Indexer.idx.loadModule(mtable.getPath());
            if (start != null) {
                return start;
            }
        }

        String dir = new File(getFile()).getParent();
        if (dir == null) {
            Indexer.idx.warn("Unable to find parent dir for " + getFile());
            return null;
        }

        return Indexer.idx.loadModule(dir);
    }

    private void reportUnresolvedModule() {
        addError("module not found: " + name.getId());
        Indexer.idx.recordUnresolvedModule(thisQname(), getFile());
    }

    @Override
    public String toString() {
        return "<QName:" + name + ":" + next + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNode(next, v);
            visitNode(name, v);
        }
    }
}
