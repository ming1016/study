package org.python.indexer.ast;

import org.python.indexer.Binding;
import org.python.indexer.Builtins;
import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.types.ModuleType;
import org.python.indexer.types.Type;

import java.util.List;

public class Import extends Node {

    static final long serialVersionUID = -2180402676651342012L;

    public List<Alias> aliases;  // import foo.bar as bar, ..x.y as y

    public Import(List<Alias> aliases) {
        this(aliases, 0, 1);
    }

    public Import(List<Alias> aliases, int start, int end) {
        super(start, end);
        this.aliases = aliases;
        addChildren(aliases);
    }

    @Override
    public boolean bindsName() {
        return true;
    }

    static void bindAliases(Scope s, List<Alias> aliases, int tag) throws Exception {
        for (Alias a : aliases) {
            if (a.aname != null) {
              NameBinder.bind(s, a.aname, Indexer.idx.builtins.unknown, tag);
            }
        }
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        for (Alias a : aliases) {
            Type modtype = resolveExpr(a, s, tag);
            if (modtype.isModuleType()) {
                importName(s, tag, a, modtype.asModuleType());
            }
        }
        return Indexer.idx.builtins.Cont;
    }

    /**
     * Import a module's alias (if present) or top-level name into the current
     * scope.  Creates references to the other names in the alias.
     *
     * @param mt the module that is actually bound to the imported name.
     * for {@code import x.y.z as foo}, it is {@code z}, a sub-module
     * of {@code x.y}.  For {@code import x.y.z} it is {@code x}.
     */
    private void importName(Scope s, int tag, Alias a, ModuleType mt) throws Exception {
        if (a.aname != null) {
            if (mt.getFile() != null) {
                NameBinder.bind(s, a.aname, mt, tag);
            } else {
                // XXX:  seems like the url should be set in loadModule, not here.
                // Can't the moduleTable store url-keyed modules too?
                s.update(a.aname.getId(),
                         new Url(Builtins.LIBRARY_URL + mt.getTable().getPath() + ".html"),
                         mt, Binding.Kind.SCOPE);
            }
        }

        addReferences(s, a.qname, true/*put top name in scope*/);
    }

    static void addReferences(Scope s, Qname qname, boolean putTopInScope) {
        if (qname == null) {
            return;
        }
        if (!qname.getType().isModuleType()) {
            return;
        }
        ModuleType mt = qname.getType().asModuleType();

        String modQname = mt.getTable().getPath();
        Binding mb = Indexer.idx.lookupFirstBinding(modQname);
        if (mb == null) {
            mb = Indexer.idx.moduleTable.lookup(modQname);
        }

        if (mb == null) {
            Indexer.idx.putProblem(qname.getName(), "module not found");
            return;
        }

        Indexer.idx.putLocation(qname.getName(), mb);

        // All other references in the file should also point to this binding.
        if (putTopInScope && qname.isTop()) {
            s.put(qname.getName().getId(), mb);
        }

        addReferences(s, qname.getNext(), false);
    }

    @Override
    public String toString() {
        return "<Import:" + aliases + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNodeList(aliases, v);
        }
    }
}
