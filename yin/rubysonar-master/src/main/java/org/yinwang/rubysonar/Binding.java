package org.yinwang.rubysonar;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.yinwang.rubysonar.ast.Class;
import org.yinwang.rubysonar.ast.*;
import org.yinwang.rubysonar.types.ModuleType;
import org.yinwang.rubysonar.types.Type;

import java.util.LinkedHashSet;
import java.util.Set;


public class Binding implements Comparable<Object> {

    public enum Kind {
        MODULE,       // file
        CLASS,        // class definition
        METHOD,       // instance method
        CLASS_METHOD,       // class method
        ATTRIBUTE,    // attr accessed with "." on some other object
        PARAMETER,    // function param
        SCOPE,        // top-level variable ("scope" means we assume it can have attrs)
        VARIABLE,      // local variable
        CONSTANT,
    }


    @NotNull
    public Node node;
    @NotNull
    public String qname;    // qualified name
    public Type type;       // inferred type
    public Kind kind;        // name usage context

    public Set<Node> refs;

    public int start = -1;
    public int end = -1;
    public int bodyStart = -1;
    public int bodyEnd = -1;

    @Nullable
    public String file;


    public Binding(@NotNull Node node, @NotNull Type type, @NotNull Kind kind) {
        this.qname = type.table.path;
        this.type = type;
        this.kind = kind;
        this.node = node;
        refs = new LinkedHashSet<>(1);

        if (node instanceof Url) {
            String url = ((Url) node).getURL();
            if (url.startsWith("file://")) {
                file = url.substring("file://".length());
            } else {
                file = url;
            }
        } else {
            file = node.file;
        }

        initLocationInfo(node);
        Analyzer.self.registerBinding(this);
    }


    private void initLocationInfo(Node node) {
        start = node.start;
        end = node.end;

        // find the node which node is the name of
        Node bodyNode = node.parent;
        while (!(bodyNode == null ||
                bodyNode instanceof Function ||
                bodyNode instanceof Class ||
                bodyNode instanceof Module))
        {
            bodyNode = bodyNode.parent;
        }

        if ((bodyNode instanceof Function && ((Function) bodyNode).name == node) ||
                (bodyNode instanceof Class && ((Class) bodyNode).name == node) ||
                (bodyNode instanceof Module && ((Module) bodyNode).name == node))
        {
            bodyStart = bodyNode.start;
            bodyEnd = bodyNode.end;
        } else {
            bodyStart = node.start;
            bodyEnd = node.end;
        }
    }


    public Str findDocString() {
        Node fullNode = node;
        if (kind == Kind.CLASS) {
            while (fullNode != null && !(fullNode instanceof org.yinwang.rubysonar.ast.Class)) {
                fullNode = fullNode.parent;
            }
        } else if (kind == Kind.METHOD || kind == Kind.CLASS_METHOD) {
            while (fullNode != null && !(fullNode instanceof Function)) {
                fullNode = fullNode.parent;
            }
        } else if (kind == Kind.MODULE) {
            while (fullNode != null && !(fullNode instanceof Module)) {
                fullNode = fullNode.parent;
            }
        }


        if (fullNode instanceof org.yinwang.rubysonar.ast.Class) {
            return ((org.yinwang.rubysonar.ast.Class) fullNode).docstring;
        } else if (fullNode instanceof Function) {
            return ((Function) fullNode).docstring;
        } else if (fullNode instanceof Module) {
            return ((Module) fullNode).docstring;
        } else {
            return null;
        }
    }


    public void setQname(@NotNull String qname) {
        this.qname = qname;
    }


    public void addRef(Node ref) {
        refs.add(ref);
    }


    @NotNull
    public String getFirstFile() {
        Type bt = type;
        if (bt instanceof ModuleType) {
            String file = bt.asModuleType().file;
            return file != null ? file : "<built-in module>";
        }

        String file = this.file;
        if (file != null) {
            return file;
        }

        return "<built-in binding>";
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
                    _.same(file, b.file));
        }
    }


    @Override
    public int hashCode() {
        return ("" + file + start).hashCode();
    }

}
