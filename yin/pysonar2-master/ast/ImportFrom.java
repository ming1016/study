package org.python.indexer.ast;

import org.python.indexer.Binding;
import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.types.ModuleType;
import org.python.indexer.types.Type;

import java.util.List;
import java.util.Map.Entry;

/**
 * Handles import from statements such as {@code from moduleA import a, b as c, d}
 * and {@code from foo.bar.moduleB import *}. <p>
 *
 * The indexer's implementation of import * uses different semantics from
 * all the other forms of import.  It's basically a bug, although the jury
 * is still out as to which implementation is better. <p>
 *
 * For the others we define name bindings anywhere an actual name is
 * introduced into the scope containing the import statement, and references
 * to the imported module or name everywhere else.  This mimics the behavior
 * of Python at runtime, but it may be confusing to anyone with only a casual
 * understanding of Python's data model, who might think it works more like
 * Java. <p>
 *
 * For import * we just enter the imported names into the symbol table,
 * which lets other code reference them, but the references "pass through"
 * automatically to the module from which the names were imported. <p>
 *
 * To illustate the difference, consider the following four modules:
 * <pre>
 *  moduleA.py:
 *     a = 1
 *     b = 2
 *
 *  moduleB.py:
 *     c = 3
 *     d = 4
 *
 *  moduleC.py:
 *     from moduleA import a, b
 *     from moduleB import *
 *     print a  # indexer finds definition of 'a' 2 lines up
 *     print b  # indexer finds definition of 'b' 3 lines up
 *     print c  # indexer finds definition of 'c' in moduleB
 *     print d  # indexer finds definition of 'd' in moduleB
 *
 *  moduleD.py:
 *     import moduleC
 *     print moduleC.a  # indexer finds definition of 'a' in moduleC
 *     print moduleC.b  # indexer finds definition of 'b' in moduleC
 *     print moduleC.c  # indexer finds definition of 'c' in moduleB
 *     print moduleC.c  # indexer finds definition of 'd' in moduleB
 * </pre>
 * To make import * work like the others, we need only create bindings
 * for the imported names.  But where would the bindings be located?
 * Assuming that we were to co-locate them all at the "*" name node,
 * clicking on a reference to any of the names would jump to the "*".
 * It's not clear that this is a better user experience. <p>
 *
 * We could make the other import statement forms work like {@code import *},
 * but that path is even more fraught with confusing inconsistencies.
 */
public class ImportFrom extends Node {

    static final long serialVersionUID = 5070549408963950138L;

    // from ...a.b.c import x, foo as bar, y
    // from y.z import *
    public String module;  // "...a.b.c"
    public Qname qname;  // ".", ".", ".", "a", "b", "c"
    public List<Alias> aliases;  // "x", "foo" [as] "bar", "y"

    public ImportFrom(String module, Qname qname, List<Alias> aliases) {
        this(module, qname, aliases, 0, 1);
    }

    public ImportFrom(String module, Qname qname, List<Alias> aliases,
                      int start, int end) {
        super(start, end);
        this.module = module;
        this.qname = qname;
        this.aliases = aliases;
        addChildren(qname);
        addChildren(aliases);
    }

    @Override
    public boolean bindsName() {
        return true;
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        resolveExpr(qname, s, tag);

        Type bottomType = qname.getBottom().getType();
        if (!bottomType.isModuleType()) {
            return setType(Indexer.idx.builtins.unknown);
        }
        ModuleType mt = (ModuleType)bottomType;
        setType(mt);

        Import.addReferences(s, qname, false /* don't put top name in scope */);

        if (isImportStar()) {
            importStar(s, mt);
            return getType();
        }

        for (Alias a : aliases) {
            resolveAlias(s, mt, a);
        }
        return Indexer.idx.builtins.Cont;
    }

    public boolean isImportStar() {
        return aliases.size() == 1 && "*".equals(aliases.get(0).name);
    }

    /**
     * Resolve "foo [as bar]" in "from x[.y] import foo [as bar]".
     * There are several possibilities for "foo":  it could be a file
     * in the directory "x[.y]", or it could be a name exported by
     * the module "x[.y]" (from its __init__.py), or it could be a
     * public name in the file "x/y.py".
     *
     * @param scope the scope into which names should be imported
     * @param mt the non-{@code null} module "x[.y]".  Could refer to
     *        either x/y.py or x/y/__init__.py.
     * @param a the "foo [as bar]" component of the import statement
     */
    private void resolveAlias(Scope scope, ModuleType mt, Alias a) throws Exception {
        // Possibilities 1 & 2:  x/y.py or x/y/__init__.py
        Binding entry = mt.getTable().lookup(a.name);

        if (entry == null) {
            // Possibility 3:  try looking for x/y/foo.py
            String mqname = qname.toQname() + "." + a.qname.toQname();
            ModuleType mt2 = Indexer.idx.loadModule(mqname);
            if (mt2 != null) {
                entry = Indexer.idx.lookupFirstBinding(mt2.getTable().getPath());
            }
        }
        if (entry == null) {
            addError(a, "name " + a.qname.getName().getId()
                     + " not found in module " + this.module);
            return;
        }
        String qname = a.qname.getName().getId();
        String aname = a.aname != null ? a.aname.getId() : null;

        // Create references for both the name and the alias (if present).
        // Then if "foo", add "foo" to scope.  If "foo as bar", add "bar".
        Indexer.idx.putLocation(a.qname.getName(), entry);
        if (aname != null) {
            Indexer.idx.putLocation(a.aname, entry);
            scope.put(aname, entry);
        } else {
            scope.put(qname, entry);
        }
    }

    private void importStar(Scope s, ModuleType mt) throws Exception {
        if (mt == null || mt.getFile() == null) {
            return;
        }

        Module mod = Indexer.idx.getAstForFile(mt.getFile());
        if (mod == null) {
            return;
        }

        List<String> names = mod.getExportedNames(mt);
        if (!names.isEmpty()) {
            for (String name : names) {
                Binding nb = mt.getTable().lookupLocal(name);
                if (nb != null) {
                    s.put(name, nb);
                }
            }
        } else {
            // Fall back to importing all names not starting with "_".
            for (Entry<String, Binding> e : mt.getTable().entrySet()) {
                if (!e.getKey().startsWith("_")) {
                    s.put(e.getKey(), e.getValue());
                }
            }
        }
    }

    @Override
    public String toString() {
        return "<FromImport:" + module + ":" + aliases + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNode(qname, v);
            visitNodeList(aliases, v);
        }
    }
}
