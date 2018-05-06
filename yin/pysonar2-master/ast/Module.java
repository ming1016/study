package org.python.indexer.ast;

import org.python.indexer.*;
import org.python.indexer.types.ModuleType;
import org.python.indexer.types.Type;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

public class Module extends Node {

    static final long serialVersionUID = -7737089963380450802L;

    public String name;
    public Block body;

    private String file;  // input source file path
    private String md5;   // input source file md5

    public Module() {
    }

    public Module(String name) {
        this.name = name;
    }

    public Module(Block body, int start, int end) {
        super(start, end);
        this.body = body;
        addChildren(this.body);
    }

    public void setFile(String file) throws Exception {
        this.file = file;
        this.name = Util.moduleNameFor(file);
        this.md5 = Util.getMD5(new File(file));
    }

    public void setFile(File path) throws Exception {
        file = path.getCanonicalPath();
        name = Util.moduleNameFor(file);
        md5 = Util.getMD5(path);
    }

    /**
     * Used when module is parsed from an in-memory string.
     * @param path file path
     * @param md5 md5 message digest for source contents
     */
    public void setFileAndMD5(String path, String md5) throws Exception {
        file = path;
        name = Util.moduleNameFor(file);
        this.md5 = md5;
    }

    @Override
    public String getFile() {
        return file;
    }

    public String getMD5() {
        return md5;
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        ModuleType mt = new ModuleType(Util.moduleNameFor(file), file, Indexer.idx.globaltable);
        s.put(file, new Url("file://" + file), mt, Binding.Kind.MODULE, tag);
        resolveExpr(body, mt.getTable(), tag);
        resolveExportedNames(mt);
        return mt;
    }

    /**
     * If the module defines an {@code __all__} variable, resolve references
     * to each of the elements.
     */
    private void resolveExportedNames(Type t) throws Exception {
        if (t.isUnionType()) {
            for (Type u : t.asUnionType().getTypes()) {
                if (u.isModuleType()) {
                    t = u.asModuleType();
                    break;
                }
            }
        }
        for (Str nstr : getExportedNameNodes(t)) {
            Binding b = t.getTable().lookupLocal(nstr.getStr());
            if (b != null) {
                Indexer.idx.putLocation(nstr, b);
            }
        }
    }

    /**
     * Attempt to determine the actual value of the "__all__" variable in the
     * target module.  If we can parse it, return the list of exported names.<p>
     *
     * @return the list of exported names.  Returns {@code null} if __all__ is
     *         missing, or if its initializer is not a simple list of strings.
     *         We don't generate a warning, since complex expressions such as
     *         {@code __all__ = [name for name in dir() if name[0] == "e"]}
     *         are valid provided the expr result is a string list.
     */
    public List<String> getExportedNames(Type t) throws Exception {
        List<String> exports = new ArrayList<String>();
        for (Str nstr : getExportedNameNodes(t)) {
            exports.add(nstr.getStr());
        }
        return exports;
    }

    /**
     * If the module defines an {@code __all__} variable, returns the string
     * elements of the variable's list value.
     * @return any exported name nodes found, or an empty list if none found
     */
    public List<Str> getExportedNameNodes(Type t) throws Exception {
        List<Str> exports = new ArrayList<Str>();
        Binding all = t.getTable().lookupLocal("__all__");
        if (all== null) {
            return exports;
        }
        Def def = all.getSignatureNode();
        if (def == null) {
            return exports;
        }
        Node __all__ = getDeepestNodeAtOffset(def.getStart());
        if (!(__all__ instanceof Name)) {
            return exports;
        }
        Node assign = __all__.getParent();
        if (!(assign instanceof Assign)) {
            return exports;
        }
        Node rvalue = ((Assign)assign).rvalue;
        if (!(rvalue instanceof NList)) {
            return exports;
        }
        for (Node elt : ((NList)rvalue).elts) {
            if (elt instanceof Str) {
                Str nstr = (Str)elt;
                if (nstr.getStr() != null) {
                    exports.add(nstr);
                }
            }
        }
        return exports;
    }

    public String toLongString() {
        return "<Module:" + body + ">";
    }

    @Override
    public String toString() {
        return "<Module:" + getFile() + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNode(body, v);
        }
    }
}
