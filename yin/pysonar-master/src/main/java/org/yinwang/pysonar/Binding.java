package org.yinwang.pysonar;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.yinwang.pysonar.ast.*;
import org.yinwang.pysonar.types.ModuleType;
import org.yinwang.pysonar.types.Type;
import org.yinwang.pysonar.types.UnionType;

import java.util.LinkedHashSet;
import java.util.Set;


public class Binding implements Comparable<Object> {

    public enum Kind {
        ATTRIBUTE,    // attr accessed with "." on some other object
        CLASS,        // class definition
        CONSTRUCTOR,  // __init__ functions in classes
        FUNCTION,     // plain function
        METHOD,       // static or instance method
        MODULE,       // file
        PARAMETER,    // function param
        SCOPE,        // top-level variable ("scope" means we assume it can have attrs)
        VARIABLE      // local variable
    }


    private boolean isStatic = false;         // static fields/methods
    private boolean isSynthetic = false;      // auto-generated bindings
    private boolean isBuiltin = false;        // not from a source file

    @NotNull
    public String name;     // unqualified name
    @NotNull
    public Node node;
    @NotNull
    public String qname;    // qualified name
    public Type type;       // inferred type
    public Kind kind;        // name usage context

    public Set<Node> refs = new LinkedHashSet<>(1);

    // fields from Def
    public int start = -1;
    public int end = -1;
    public int bodyStart = -1;
    public int bodyEnd = -1;

    @Nullable
    public String fileOrUrl;


    public Binding(@NotNull String id, @NotNull Node node, @NotNull Type type, @NotNull Kind kind) {
        this.name = id;
        this.qname = type.table.path;
        this.type = type;
        this.kind = kind;
        this.node = node;

        if (node instanceof Url) {
            String url = ((Url) node).url;
            if (url.startsWith("file://")) {
                fileOrUrl = url.substring("file://".length());
            } else {
                fileOrUrl = url;
            }
        } else {
            fileOrUrl = node.file;
            if (node instanceof Name) {
                name = ((Name) node).id;
            }
        }

        initLocationInfo(node);
        Analyzer.self.registerBinding(this);
    }


    private void initLocationInfo(Node node) {
        start = node.start;
        end = node.end;

        Node parent = node.parent;
        if ((parent instanceof FunctionDef && ((FunctionDef) parent).name == node) ||
                (parent instanceof ClassDef && ((ClassDef) parent).name == node))
        {
            bodyStart = parent.start;
            bodyEnd = parent.end;
        } else if (node instanceof Module) {
            name = ((Module) node).name;
            start = 0;
            end = 0;
            bodyStart = node.start;
            bodyEnd = node.end;
        } else {
            bodyStart = node.start;
            bodyEnd = node.end;
        }
    }


    public Str getDocstring() {
        Node parent = node.parent;
        if ((parent instanceof FunctionDef && ((FunctionDef) parent).name == node) ||
                (parent instanceof ClassDef && ((ClassDef) parent).name == node))
        {
            return parent.getDocString();
        } else {
            return node.getDocString();
        }
    }


    public void setQname(@NotNull String qname) {
        this.qname = qname;
    }


    public void addRef(Node node) {
        refs.add(node);
    }


    // merge one more type into the type
    // used by stateful assignments which we can't track down the control flow
    public void addType(Type t) {
        type = UnionType.union(type, t);
    }


    public void setType(Type type) {
        this.type = type;
    }


    public void setKind(Kind kind) {
        this.kind = kind;
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


    public boolean isBuiltin() {
        return isBuiltin;
    }


    @NotNull
    public String getFirstFile() {
        Type bt = type;
        if (bt instanceof ModuleType) {
            String file = bt.asModuleType().file;
            return file != null ? file : "<built-in module>";
        }

        String file = getFile();
        if (file != null) {
            return file;
        }

        return "<built-in binding>";
    }


    @Nullable
    public String getFile() {
        return isURL() ? null : fileOrUrl;
    }


    @Nullable
    public String getURL() {
        return isURL() ? fileOrUrl : null;
    }


    public boolean isURL() {
        return fileOrUrl != null && fileOrUrl.startsWith("http://");
    }


    /**
     * Bindings can be sorted by their location for outlining purposes.
     */
    public int compareTo(@NotNull Object o) {
        return start - ((Binding) o).start;
    }


    @NotNull
    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("(binding:");
        sb.append(":kind=").append(kind);
        sb.append(":node=").append(node);
        sb.append(":type=").append(type);
        sb.append(":qname=").append(qname);
        sb.append(":refs=");
        if (refs.size() > 10) {
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


    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof Binding)) {
            return false;
        } else {
            Binding b = (Binding) obj;
            return (start == b.start &&
                    end == b.end &&
                    _.same(fileOrUrl, b.fileOrUrl));
        }
    }


    @Override
    public int hashCode() {
        return node.hashCode();
    }

}
