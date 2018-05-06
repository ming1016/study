package org.yinwang.rubysonar;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.yinwang.rubysonar.ast.Attribute;
import org.yinwang.rubysonar.ast.Name;
import org.yinwang.rubysonar.ast.Node;
import org.yinwang.rubysonar.types.FunType;
import org.yinwang.rubysonar.types.ModuleType;
import org.yinwang.rubysonar.types.Type;
import org.yinwang.rubysonar.types.UnionType;

import java.util.*;


public class State {
    public enum StateType {
        CLASS,
        INSTANCE,
        FUNCTION,
        MODULE,
        GLOBAL,
        SCOPE
    }


    @NotNull
    public Map<String, List<Binding>> table = new HashMap<>();
    @Nullable
    public State parent;      // all are non-null except global table
    @Nullable
    public State supers;
    public StateType stateType;
    public Type type;
    @NotNull
    public String path = "";


    public State(@Nullable State parent, StateType type) {
        this.parent = parent;
        this.stateType = type;
    }


    public State(@NotNull State s) {
        this.table = new HashMap<>();
        this.table.putAll(s.table);
        this.parent = s.parent;
        this.stateType = s.stateType;
        this.supers = s.supers;
        this.type = s.type;
        this.path = s.path;
    }


    // erase and overwrite this to s's contents
    public void overwrite(@NotNull State s) {
        this.table = s.table;
        this.parent = s.parent;
        this.stateType = s.stateType;
        this.supers = s.supers;
        this.type = s.type;
        this.path = s.path;
    }


    @NotNull
    public State copy() {
        return new State(this);
    }


    public void merge(State other) {
        for (Map.Entry<String, List<Binding>> e1 : this.table.entrySet()) {
            List<Binding> b1 = e1.getValue();
            List<Binding> b2 = other.table.get(e1.getKey());

            // both branch have the same name, need merge
            if (b2 != null && b1 != b2) {
                b1.addAll(b2);
            }
        }

        for (Map.Entry<String, List<Binding>> e2 : other.table.entrySet()) {
            List<Binding> b1 = this.table.get(e2.getKey());
            List<Binding> b2 = e2.getValue();

            // both branch have the same name, need merge
            if (b1 == null && b1 != b2) {
                this.update(e2.getKey(), b2);
            }
        }
    }


    public static State merge(State state1, State state2) {
        State ret = state1.copy();
        ret.merge(state2);
        return ret;
    }


    public void setParent(@Nullable State parent) {
        this.parent = parent;
    }


    public void setSuper(State sup) {
        supers = sup;
    }


    public void setStateType(StateType type) {
        this.stateType = type;
    }


    public StateType getStateType() {
        return stateType;
    }


    public boolean isGlobalName(@NotNull String name) {
        return name.startsWith("$");
    }


    public void remove(String id) {
        table.remove(id);
    }


    // create new binding and insert
    public void insert(String id, Node node, Type type, Binding.Kind kind) {
        Binding b = new Binding(node, type, kind);
        if (type.isModuleType()) {
            b.setQname(type.asModuleType().qname);
        } else {
            if (type instanceof FunType) {
                if (id.endsWith(Constants.IDSEP + "class")) {
                    b.setQname(extendPath(id, "."));
                } else {
                    b.setQname(extendPath(id, "#"));
                }
            } else {
                b.setQname(extendPath(id, "::"));
            }
        }
        update(id, b);
    }


    public String makeTagId(String id, String tag) {
        return id + Constants.IDSEP + tag;
    }


    // directly insert a given binding list
    @NotNull
    public List<Binding> update(String id, @NotNull List<Binding> bs) {
        this.table.put(id, bs);
        return bs;
    }


    @NotNull
    public List<Binding> update(String id, @NotNull Binding b) {
        List<Binding> bs = new ArrayList<>();
        bs.add(b);
        this.table.put(id, bs);
        return bs;
    }


    public void insertTagged(String id, String tag, Node node, Type type, Binding.Kind kind) {
        insert(makeTagId(id, tag), node, type, kind);
    }


    @NotNull
    public List<Binding> updateTagged(String id, String tag, @NotNull List<Binding> bs) {
        return update(makeTagId(id, tag), bs);
    }


    @NotNull
    public List<Binding> updateTagged(String id, String tag, @NotNull Binding b) {
        return update(makeTagId(id, tag), b);
    }


    public void updateType(String id, @NotNull Type type) {
        List<Binding> bs = lookup(id);
        List<Binding> replacement = new ArrayList<>();
        if (bs != null) {
            for (Binding b : bs) {
                if (b != null) {
                    replacement.add(new Binding(b.node, type, b.kind));
                }
            }
        } else {
            replacement.add(new Binding(new Name(id), type, Binding.Kind.SCOPE));
        }
        update(id, replacement);
    }


    public void setPath(@NotNull String path) {
        this.path = path;
    }


    public void setType(Type type) {
        this.type = type;
    }


    /**
     * Look up a name in the current symbol table only. Don't recurse on the
     * parent table.
     */
    @Nullable
    public List<Binding> lookupLocal(String name) {
        return table.get(name);
    }


    @Nullable
    public List<Binding> lookupLocalTagged(String name, String tag) {
        return lookupLocal(makeTagId(name, tag));
    }


    /**
     * Look up a name (String) in the current symbol table.  If not found,
     * recurse on the parent table.
     */
    @Nullable
    public List<Binding> lookup(@NotNull String name) {
        List<Binding> b = getModuleBindingIfGlobal(name);
        if (b != null) {
            return b;
        } else {
            List<Binding> ent = lookupLocal(name);
            if (ent != null) {
                return ent;
            } else {
                if (parent != null) {
                    return parent.lookup(name);
                } else {
                    return null;
                }
            }
        }
    }


    @Nullable
    public List<Binding> lookupTagged(@NotNull String name, String tag) {
        return lookup(makeTagId(name, tag));
    }


    /**
     * Look up a name in the module if it is declared as global, otherwise look
     * it up locally.
     */
    @Nullable
    public List<Binding> lookupScope(String name) {
        List<Binding> b = getModuleBindingIfGlobal(name);
        if (b != null) {
            return b;
        } else {
            return lookupLocal(name);
        }
    }


    /**
     * Look up an attribute in the type hierarchy.  Don't look at parent link,
     * because the enclosing scope may not be a super class. The search is
     * "depth first, left to right" as in Python's (old) multiple inheritance
     * rule. The new MRO can be implemented, but will probably not introduce
     * much difference.
     */
    @NotNull
    private static Set<State> looked = new HashSet<>();    // circularity prevention


    @Nullable
    public List<Binding> lookupAttr(String attr) {
        if (looked.contains(this)) {
            return null;
        } else {
            List<Binding> b = lookupLocal(attr);
            if (b != null) {
                return b;
            } else {
                if (supers != null && !supers.isEmpty()) {
                    looked.add(this);
                    b = supers.lookupAttr(attr);
                    if (b != null) {
                        looked.remove(this);
                        return b;
                    }
                    looked.remove(this);
                    return null;
                } else {
                    return null;
                }
            }
        }
    }


    @Nullable
    public List<Binding> lookupAttrTagged(String attr, String tag) {
        return lookupAttr(makeTagId(attr, tag));
    }


    public ModuleType lookupOrCreateModule(Node locator, String file) {
        Type existing = Node.transformExpr(locator, this);
        if (existing.isModuleType()) {
            return existing.asModuleType();
        } else if (locator instanceof Name) {
            List<Binding> bs = lookupAttr(((Name) locator).id);
            if (bs != null && bs.size() > 0 && bs.get(0).type.isModuleType()) {
                return bs.get(0).type.asModuleType();
            } else {
                ModuleType mt = new ModuleType(((Name) locator).id, file, this);
                this.insert(((Name) locator).id, locator, mt, Binding.Kind.MODULE);
                return mt;
            }
        } else if (locator instanceof Attribute) {
            ModuleType mod = lookupOrCreateModule(((Attribute) locator).target, file);
            ModuleType mod2 = new ModuleType(((Attribute) locator).attr.id, file, mod.table);
            mod.table.insert(((Attribute) locator).attr.id, ((Attribute) locator).attr, mod2, Binding.Kind.MODULE);
            return mod2;
        } else {
            String name = locator.toString();
            return new ModuleType(name, null, this);
        }
    }


    /**
     * Look for a binding named {@code name} and if found, return its type.
     */
    @Nullable
    public Type lookupType(String name) {
        List<Binding> bs = lookup(name);
        if (bs == null) {
            return null;
        } else {
            return makeUnion(bs);
        }
    }


    /**
     * Look for a attribute named {@code attr} and if found, return its type.
     */
    @Nullable
    public Type lookupAttrType(String attr) {
        List<Binding> bs = lookupAttr(attr);
        if (bs == null) {
            return null;
        } else {
            return makeUnion(bs);
        }
    }


    @Nullable
    public Type lookupAttrTypeTagged(String attr, String tag) {
        return lookupAttrType(makeTagId(attr, tag));
    }


    public static Type makeUnion(List<Binding> bs) {
        Type t = Type.UNKNOWN;
        for (Binding b : bs) {
            t = UnionType.union(t, b.type);
        }
        return t;
    }


    /**
     * Find a symbol table of a certain type in the enclosing scopes.
     */
    @Nullable
    public State getStateOfType(StateType type) {
        if (stateType == type) {
            return this;
        } else if (parent == null) {
            return null;
        } else {
            return parent.getStateOfType(type);
        }
    }


    /**
     * Returns the global scope (i.e. the module scope for the current module).
     */
    @NotNull
    public State getGlobalTable() {
        State result = getStateOfType(StateType.GLOBAL);
        if (result != null) {
            return result;
        } else {
            _.die("Couldn't find global table. Shouldn't happen");
            return this;
        }
    }


    /**
     * If {@code name} is declared as a global, return the module binding.
     */
    @Nullable
    private List<Binding> getModuleBindingIfGlobal(@NotNull String name) {
        if (isGlobalName(name)) {
            State module = getGlobalTable();
            if (module != this) {
                return module.lookupLocal(name);
            }
        }
        return null;
    }


    public void putAll(@NotNull State other) {
        this.table.putAll(other.table);
    }


    @NotNull
    public Set<String> keySet() {
        return table.keySet();
    }


    @NotNull
    public Collection<Binding> values() {
        List<Binding> ret = new ArrayList<>();
        for (List<Binding> bs : table.values()) {
            ret.addAll(bs);
        }
        return ret;
    }


    public boolean isEmpty() {
        return table.isEmpty();
    }


    @NotNull
    public String extendPath(@NotNull String name, String sep) {
        name = _.mainName(name);
        if (path.equals("")) {
            return name;
        } else {
            return path + sep + name;
        }
    }


    @NotNull
    @Override
    public String toString() {
        return "(state:" + getStateType() + ":" + table.keySet() + ")";
    }

}
