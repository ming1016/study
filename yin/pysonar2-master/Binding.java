package org.python.indexer;

import org.python.indexer.ast.Node;
import org.python.indexer.types.ModuleType;
import org.python.indexer.types.Type;

import java.util.*;

/**
 * An {@code NBinding} collects information about a fully qualified name (qname)
 * in the code graph.<p>
 *
 * Each qname has an associated {@link org.python.indexer.types.Type}.  When a particular qname is
 * assigned values of different types at different locations, its type is
 * represented as a {@link org.python.indexer.types.UnionType}. <p>
 *
 * Each qname has a set of one or more definitions, and a set of zero or
 * more references.  Definitions and references correspond to code locations. <p>
 */
public class Binding implements Comparable<Object> {

    /**
     * In addition to its type, each binding has a {@link Kind} enumeration that
     * attempts to represent the structural role the name plays in the code.
     * This is a rough categorization that takes into account type information,
     * structural (AST) information, and possibly other semantics.  It can help
     * IDEs with presentation decisions, and can be useful to expose to users as
     * a parameter for filtering queries on the graph.
     */
    public enum Kind {
        ATTRIBUTE,  // attr accessed with "." on some other object
        CLASS,  // class definition
        CONSTRUCTOR,  // __init__ functions in classes
        FUNCTION,  // plain function
        METHOD,  // static or instance method
        MODULE,  // file
        PARAMETER,  // function param
        SCOPE,  // top-level variable ("scope" means we assume it can have attrs)
        VARIABLE  // local variable
    }
    
    // The indexer is heavily memory-constrained, so these sets are initially
    // small.  The vast majority of bindings have only one definition.
    private static final int DEF_SET_INITIAL_CAPACITY = 1;
    private static final int REF_SET_INITIAL_CAPACITY = 1;
    
    // yinw: C-style bit-field changed to straightfoward booleans.
    // The compiler should compact the space unless it is stupid.
    private boolean isStatic = false;         // static fields/methods
    private boolean isSynthetic = false;      // auto-generated bindings
    private boolean isReadonly = false;       // non-writable attributes
    private boolean isDeprecated = false;     // documented as deprecated
    private boolean isBuiltin = false;        // not from a source file

    private String name;    // unqualified name
    private String qname;   // qualified name
    private Type type;     // inferred type
    public Kind kind;      // name usage context
    public int tag;        // control-flow tag

    private Set<Def> defs;
    private Set<Ref> refs;

    
    public Binding(String id, Node node, Type type, Kind kind, int tag) {
        this(id, node, type, kind);
        this.tag = tag;
    }
    
    public Binding(String id, Node node, Type type, Kind kind) {
        this(id, node != null ? new Def(node) : null, type, kind);
    }

    public Binding(String id, Def def, Type type, Kind kind) {
        if (id == null) {
            throw new IllegalArgumentException("'id' param cannot be null");
        }
        qname = name = id;
        defs = new HashSet<Def>(DEF_SET_INITIAL_CAPACITY);
        addDef(def);
        this.type = type == null ? Indexer.idx.builtins.unknown : type;
        this.kind = kind == null ? Kind.SCOPE : kind;
    }

    /**
     * Returns the unqualified name.
     */
    public String getName() {
        return name;
    }

    /**
     * Sets the binding's qualified name.  This should in general be the
     * same as {@code binding.getType().getTable().getPath()}.
     */
    public void setQname(String qname) {
        this.qname = qname;
    }

    /**
     * Returns the qualified name.
     */
    public String getQname() {
        return qname;
    }

    /**
     * Adds {@code node} as a definition for this binding.  This is called
     * automatically (when appropriate) by adding the binding to a
     * {@link Scope}.
     */
    public void addDef(Node node) {
        if (node != null) {
            addDef(new Def(node));
        }
    }

    /**
     * Adds {@code def} as a definition for this binding.  This is called
     * automatically (when appropriate) by adding the binding to a
     * {@link Scope}.  If {@code node} is an {@link org.python.indexer.ast.Url}, and this is the
     * binding's only definition, it will be marked as a builtin.
     */
    public void addDef(Def def) {
        if (def == null) {
            return;
        }
        Set<Def> defs = getDefs();
        if (!defs.contains(def)) {
            defs.add(def);
            if (def.isURL()) {
                markBuiltin();
            }
        }
    }

    public void addRef(Ref ref) {
        getRefs().add(ref);
    }

    /**
     * Returns the first definition, which by convention is treated as
     * the one that introduced the binding.
     */
    public Def getSignatureNode() {
        return getDefs().isEmpty() ? null : getDefs().iterator().next();
    }

    public void setType(Type type) {
        this.type = type;
    }

    public Type getType() {
        return type;
    }

    public void setKind(Kind kind) {
        this.kind = kind;
    }

    public Kind getKind() {
        return kind;
    }

    public void markStatic() {
        isStatic = true;
    }

    public boolean isStatic() {
        return isStatic;
    }

    public void markSynthetic() {
        isSynthetic = true;
    }

    public boolean isSynthetic() {
        return isSynthetic;
    }

    public void markReadOnly() {
        isReadonly = true;
    }

    public boolean isReadOnly() {
        return isReadonly;
    }

    public boolean isDeprecated() {
        return isDeprecated;
    }

    public void markDeprecated() {
        isDeprecated = true;
    }

    public boolean isBuiltin() {
        return isBuiltin;
    }

    public void markBuiltin() {
        isBuiltin = true;
    }

    /**
     * Bindings can be sorted by their location for outlining purposes.
     */
    public int compareTo(Object o) {
        return getSignatureNode().getStart() - ((Binding)o).getSignatureNode().getStart();
    }
    
    /**
     * Return the (possibly empty) set of definitions for this binding.
     * @return the defs
     */
    public Set<Def> getDefs() {
        if (defs == null) {
            defs = new HashSet<Def>(DEF_SET_INITIAL_CAPACITY);
        }
        return defs;
    }
    
    public Def getDef() {
        if (defs == null || defs.isEmpty()) {
            return null;
        } else {
            return defs.iterator().next();
        }
    }

    /**
     * Returns the number of definitions found for this binding.
     */
    public int getNumDefs() {
        return defs == null ? 0 : defs.size();
    }

    public boolean hasRefs() {
        return refs == null ? false : !refs.isEmpty();
    }

    public int getNumRefs() {
        return refs == null ? 0 : refs.size();
    }

    /**
     * Returns the set of references to this binding.
     */
    public Set<Ref> getRefs() {
        if (refs == null) {
            refs = new HashSet<Ref>(REF_SET_INITIAL_CAPACITY);
        }
        return refs;
    }

    /**
     * Returns a filename associated with this binding, for debug
     * messages.
     * @return the filename associated with the type (if present)
     *     or the first definition (if present), otherwise a string
     *     describing what is known about the binding's source.
     */
    public String getFirstFile() {
        Type bt = getType();
        if (bt instanceof ModuleType) {
            String file = bt.asModuleType().getFile();
            return file != null ? file : "<built-in module>";
        }
        if (defs != null) {
            for (Def def : defs) {
                String file = def.getFile();
                if (file != null) {
                    return file;
                }
            }
            return "<built-in binding>";
        }
        return "<unknown source>";
    }

    @Override
    public String toString() {
        StringBuilder sb =  new StringBuilder();
        sb.append("<Binding:").append(qname);
        sb.append(":type=").append(type);
        sb.append(":kind=").append(kind);
        sb.append(":defs=").append(defs);
        sb.append(":refs=");
        if (getRefs().size() > 10) {
            sb.append("[");
            sb.append(refs.iterator().next());
            sb.append(", ...(");
            sb.append(refs.size() - 1);
            sb.append(" more)]");
        } else {
            sb.append(refs);
        }
        sb.append(">");
        return sb.toString();
    }

    /*
     * Multiple bindings can exist for the same qname, but they should appear at
     * different locations. Otherwise they are considered the same by the equals
     * method of NBinding.
     */
    @Override
    public boolean equals(Object o) {
        if (o instanceof Binding) {
            Binding other = (Binding)o;
            return other.getDef().equals(getDef());
        } else {
            return false;
        }
    }

}
