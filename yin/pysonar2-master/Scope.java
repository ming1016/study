package org.python.indexer;

import org.python.indexer.ast.Node;
import org.python.indexer.types.Type;
import org.python.indexer.types.UnionType;

import java.util.*;
import java.util.Map.Entry;

/**
 * Symbol table.
 */
public class Scope {

    public enum ScopeType {
        CLASS,
        INSTANCE,
        FUNCTION,
        MODULE,
        GLOBAL,
        SCOPE
    }

    /**
     * XXX: This table is incorrectly overloaded to contain both object
     * attributes and lexical-ish scope names, when they are in some cases
     * separate namespaces. (In particular, they're effectively the same
     * namespace for module scope and class scope, and they're different for
     * function scope, which uses the {@code func_dict} namespace for storing
     * attributes.)
     * <p/>
     * yinw: The overloading was correct. Just that the function parameters are
     * bound not in the function's table. They are bound in a fresh table which
     * is called the "invokation table", which is created at calls. Attributes
     * like im_class are bound inside a function's table when the closures are
     * created.
     */
    private Map<String, Binding> table;  // stays null for most scopes (mem opt)
    public Scope parent;
    private Scope forwarding;       // link to the closest non-class scope, for lifting functions out
    private List<Scope> supers;
    private Set<String> globalNames;
    private ScopeType scopeType;
    private Type type;
    private String path = "";
    private static int lambdaCounter = 0;

    public Scope(Scope parent, ScopeType type) {
        this.parent = parent;
        this.scopeType = type;

        if (type == ScopeType.CLASS) {
            this.forwarding = parent.getForwarding();
        } else {
            this.forwarding = this;
        }
    }


    public Scope(Scope s) {
        if (s.table != null) {
            this.table = new HashMap<String, Binding>(s.table);
        }
        this.parent = s.parent;
        this.scopeType = s.scopeType;
        this.forwarding = s.forwarding;
        this.supers = s.supers;
        this.globalNames = s.globalNames;
        this.type = s.type;
        this.path = s.path;
    }


    public void setParent(Scope parent) {
        this.parent = parent;
    }

    public Scope getParent() {
        return parent;
    }

    public Scope getForwarding() {
        if (forwarding != null) {
            return forwarding;
        } else {
            return this;
        }
    }

    public void addSuper(Scope sup) {
        if (supers == null) {
            supers = new ArrayList<Scope>();
        }
        supers.add(sup);
    }

    public void setScopeType(ScopeType type) {
        this.scopeType = type;
    }

    public ScopeType getScopeType() {
        return scopeType;
    }

    /**
     * Mark a name as being global (i.e. module scoped) for name-binding and
     * name-lookup operations in this code block and any nested scopes.
     */
    public void addGlobalName(String name) {
        if (name == null) {
            throw new IllegalArgumentException("name shouldn't be null");
        }
        if (globalNames == null) {
            globalNames = new HashSet<String>();
        }
        globalNames.add(name);
    }

    /**
     * Returns {@code true} if {@code name} appears in a {@code global}
     * statement in this scope or any enclosing scope.
     */
    public boolean isGlobalName(String name) {
        if (globalNames != null) {
            return globalNames.contains(name);
        } else if (parent != null) {
            return parent.isGlobalName(name);
        } else {
            return false;
        }
    }

    /**
     * Directly assigns a binding to a name in this table.  Does not add a new
     * definition or reference to the binding.  This form of {@code put} is
     * often followed by a call to {@link putLocation} to create a reference to
     * the binding.  When there is no code location associated with {@code id},
     * or it is otherwise undesirable to create a reference, the
     * {@link putLocation} call is omitted.
     */
    public void put(String id, Binding b) {
        getInternalTable().put(id, b);
    }

    /**
     * Adds a definition and/or reference to the table.
     * If there is no binding for {@code id}, creates one and gives it
     * {@code type} and {@code kind}.  <p>
     * <p/>
     * If a binding already exists, then add either a definition or a reference
     * at {@code loc} to the binding.  By convention we consider it a definition
     * if the type changes.  If the passed type is different from the binding's
     * current type, set the binding's type to the union of the old and new
     * types, and add a definition.  If the new type is the same, just add a
     * reference.  <p>
     * <p/>
     * If the binding already exists, {@code kind} is only updated if a
     * definition was added <em>and</em> the binding's type was previously the
     * unknown type.
     */
    public Binding put(String id, Node loc, Type type, Binding.Kind kind, int tag) {
        Binding b = lookupScope(id);
        return insertOrUpdate(b, id, loc, type, kind, tag);
    }

    /**
     * Same as {@link #put}, but adds the name as an attribute of this scope.
     * Looks up the superclass chain to see if the attribute exists, rather
     * than looking in the lexical scope chain.
     *
     * @return the new binding, or {@code null} if the current scope does
     *         not have a properly initialized path.
     */
    public Binding putAttr(String id, Node loc, Type type, Binding.Kind kind, int tag) {
        // Attributes are always part of a qualified name.  If there is no qname
        // on the target type, it's a bug (we forgot to set the path somewhere.)
        if ("".equals(path)) {
            Indexer.idx.reportFailedAssertion(
                    "Attempting to set attr '" + id + "' at location " + loc
                            + (loc != null ? loc.getFile() : "")
                            + " in scope with no path (qname) set: " + toShortString());
            return null;
        } else {
            Binding b = lookupAttr(id);
            return insertOrUpdate(b, id, loc, type, kind, tag);
        }
    }


    /**
     * If no bindings are found, or it is rebinding in the same thread of
     * control to a new type, then create a new binding and rewrite/shadow the
     * old one. Otherwise, use the exisitng binding and update the type.
     */
    private Binding insertOrUpdate(Binding b, String id, Node loc, Type t, Binding.Kind k, int tag) {
        if (b == null) {
            b = insertBinding(id, new Binding(id, loc, t, k, tag));
        } else if (tag == b.tag && !b.getType().equals(t)) {
            b = insertBinding(id, new Binding(id, loc, t, k, tag));
        } else {
            b.addDef(loc);
            b.setType(UnionType.union(t, b.getType()));
        }
        return b;
    }


    private Binding insertBinding(String id, Binding b) {
        switch (b.getKind()) {
            case MODULE:
                b.setQname(b.getType().getTable().getPath());
                break;
            case PARAMETER:
                b.setQname(extendPathForParam(b.getName()));
                break;
            default:
                b.setQname(extendPath(b.getName()));
                break;
        }
        Indexer.idx.putBinding(b);
        put(id, b);
        return b;
    }


    public void remove(String id) {
        if (table != null) {
            table.remove(id);
        }
    }

    /**
     * Adds a new binding for {@code id}.  If a binding already existed,
     * replaces its previous definitions, if any, with {@code loc}.  Sets the
     * binding's type to {@code type} (not a union with the previous type).
     */
    public Binding update(String id, Node loc, Type type, Binding.Kind kind) {
        if (type == null) {
            throw new IllegalArgumentException("Null type: id=" + id + ", loc=" + loc);
        }
        return update(id, new Def(loc), type, kind);
    }

    /**
     * Adds a new binding for {@code id}.  If a binding already existed,
     * replaces its previous definitions, if any, with {@code loc}.  Sets the
     * binding's type to {@code type} (not a union with the previous type).
     */
    public Binding update(String id, Def loc, Type type, Binding.Kind kind) {
        if (type == null) {
            throw new IllegalArgumentException("Null type: id=" + id + ", loc=" + loc);
        }
        Binding b = lookupScope(id);
        if (b == null) {
            return insertBinding(id, new Binding(id, loc, type, kind));
        }

        b.getDefs().clear();  // XXX:  what about updating refs & idx.locations?
        b.addDef(loc);
        b.setType(type);

        // XXX: is this a bug?  I think he meant to do this check before the
        // line above that sets b.type, if it's supposed to be like put().
        if (b.getType().isUnknownType()) {
            b.setKind(kind);
        }
        return b;
    }

    /**
     * Create a copy of the symbol table but without the links to parent, supers
     * and children. Useful for creating instances.
     *
     * @return the symbol table for use by the instance.
     */
    public Scope copy(ScopeType tableType) {
        Scope ret = new Scope(null, tableType);
        if (table != null) {
            ret.getInternalTable().putAll(table);
        }
        return ret;
    }

    public void setPath(String path) {
        if (path == null) {
            throw new IllegalArgumentException("'path' param cannot be null");
        }
        this.path = path;
    }

    public String getPath() {
        return path;
    }

    public Type getType() {
        return type;
    }

    public void setType(Type type) {
        this.type = type;
    }

    /**
     * Look up a name in the current symbol table only. Don't recurse on the
     * parent table.
     */
    public Binding lookupLocal(String name) {
        if (table == null) {
            return null;
        } else {
            return table.get(name);
        }
    }

    /**
     * Look up a name (String) in the current symbol table.  If not found,
     * recurse on the parent table.
     */
    public Binding lookup(String name) {
        Binding b = getModuleBindingIfGlobal(name);
        if (b != null) {
            return b;
        } else {
            Binding ent = lookupLocal(name);
            if (ent != null) {
                return ent;
            } else if (getParent() != null) {
                return getParent().lookup(name);
            } else {
                return null;
            }
        }
    }

    /**
     * Look up an attribute in the type hierarchy.  Don't look at parent link,
     * because the enclosing scope may not be a super class. The search is
     * "depth first, left to right" as in Python's (old) multiple inheritance
     * rule. The new MRO can be implemented, but will probably not introduce
     * much difference.
     */
    private static Set<Scope> looked = new HashSet<Scope>();    // circularity prevention

    public Binding lookupAttr(String attr) {
        if (looked.contains(this)) {
            return null;
        } else {
            Binding b = lookupLocal(attr);
            if (b != null) {
                return b;
            } else {
                if (supers != null && !supers.isEmpty()) {
                    looked.add(this);
                    for (Scope p : supers) {
                        b = p.lookupAttr(attr);
                        if (b != null) {
                            looked.remove(this);
                            return b;
                        }
                    }
                    looked.remove(this);
                    return null;
                } else {
                    return null;
                }
            }
        }
    }

    /**
     * Look for a binding named {@code name} and if found, return its type.
     */
    public Type lookupType(String name) {
        Binding b = lookup(name);
        if (b == null) {
            return null;
        } else {
            return b.getType();
        }
    }

    /**
     * Look for a attribute named {@code attr} and if found, return its type.
     */
    public Type lookupAttrType(String attr) {
        Binding b = lookupAttr(attr);
        if (b == null) {
            return null;
        } else {
            return b.getType();
        }
    }

    /**
     * Look up a name in the module if it is declared as global, otherwise look
     * it up locally.
     */
    public Binding lookupScope(String name) {
        Binding b = getModuleBindingIfGlobal(name);
        if (b != null) {
            return b;
        } else {
            return lookupLocal(name);
        }
    }

    /**
     * Find a symbol table of a certain type in the enclosing scopes.
     */
    private Scope getSymtabOfType(ScopeType type) {
        if (scopeType == type) {
            return this;
        } else if (parent == null) {
            return null;
        } else {
            return parent.getSymtabOfType(type);
        }
    }

    /**
     * Returns the global scope (i.e. the module scope for the current module).
     */
    public Scope getGlobalTable() {
        Scope result = getSymtabOfType(ScopeType.MODULE);
        if (result == null) {
            Indexer.idx.reportFailedAssertion("No module table found for " + this);
            result = this;
        }
        return result;
    }

    /**
     * If {@code name} is declared as a global, return the module binding.
     */
    private Binding getModuleBindingIfGlobal(String name) {
        if (isGlobalName(name)) {
            Scope module = getGlobalTable();
            if (module != null && module != this) {
                return module.lookupLocal(name);
            }
        }
        return null;
    }

    /**
     * Merge all records from another symbol table. Used by {@code import from *}.
     */
    public void merge(Scope other) {
        getInternalTable().putAll(other.table);
    }

    public Set<String> keySet() {
        if (table != null) {
            return table.keySet();
        } else {
            return Collections.emptySet();
        }
    }

    public Collection<Binding> values() {
        if (table != null) {
            return table.values();
        }
        Collection<Binding> result = Collections.emptySet();
        return result;
    }

    public Set<Entry<String, Binding>> entrySet() {
        if (table != null) {
            return table.entrySet();
        }
        Set<Entry<String, Binding>> result = Collections.emptySet();
        return result;
    }

    public boolean isEmpty() {
        return table == null ? true : table.isEmpty();
    }

    /**
     * Dismantles all resources allocated by this scope.
     */
    public void clear() {
        if (table != null) {
            table.clear();
            table = null;
        }
        parent = null;
        if (supers != null) {
            supers.clear();
            supers = null;
        }
        if (globalNames != null) {
            globalNames.clear();
            globalNames = null;
        }
        if (looked != null) {
            looked.clear();
            looked = null;
        }
    }

    public String newLambdaName() {
        return "lambda%" + (++lambdaCounter);
    }

    /**
     * Generates a qname for a parameter of a function or method.
     * There is not enough context for {@link #extendPath} to differentiate
     * params from locals, so callers must use this method when the name is
     * known to be a parameter name.
     */
    public String extendPathForParam(String name) {
        if (path.isEmpty()) {
            throw new IllegalStateException("Not inside a function");
        }
        StringBuilder sb = new StringBuilder();
        sb.append(path).append("@").append(name);
        return sb.toString();
    }

    /**
     * Constructs a qualified name by appending {@code name} to this scope's qname. <p>
     * <p/>
     * The indexer uses globally unique fully qualified names to address
     * identifier definition sites.  Many Python identifiers are already
     * globally addressable using dot-separated package, class and attribute
     * names. <p>
     * <p/>
     * Function variables and parameters are not globally addressable in the
     * language, so the indexer uses a special path syntax for creating globally
     * unique qualified names for them.  By convention the syntax is "@" for
     * parameters and "&amp;" for local variables.
     *
     * @param name a name to append to the current qname
     * @return the qname for {@code name}.  Does not change this scope's path.
     */
    public String extendPath(String name) {
        if (name.endsWith(".py")) {
            name = Util.moduleNameFor(name);
        }
        if (path.equals("")) {
            return name;
        }
        String sep;
        switch (scopeType) {
            case MODULE:
            case CLASS:
            case INSTANCE:
            case SCOPE:
                sep = ".";
                break;
            case FUNCTION:
                sep = "&";
                break;
            default:
                System.err.println("unsupported context for extendPath: " + scopeType);
                return path;
        }
        return path + sep + name;
    }

    private Map<String, Binding> getInternalTable() {
        if (this.table == null) {
            this.table = new HashMap<String, Binding>();
        }
        return this.table;
    }


    @Override
    public String toString() {
        return "<Scope:" + getScopeType() + ":" + path + ":" +
                (table == null ? "{}" : table.keySet()) + ">";
    }

    public String toShortString() {
        return "<Scope:" + getScopeType() + ":" + path + ">";
    }
}
