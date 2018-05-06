package org.yinwang.rubysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.yinwang.rubysonar.Analyzer;
import org.yinwang.rubysonar.State;
import org.yinwang.rubysonar._;
import org.yinwang.rubysonar.types.Type;
import org.yinwang.rubysonar.types.UnionType;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;


public abstract class Node implements java.io.Serializable {

    public String file;
    public int start = -1;
    public int end = -1;
    public String name;
    public String path;
    public Node parent = null;


    public Node() {
    }


    public Node(String file, int start, int end) {
        this.file = file;
        this.start = start;
        this.end = end;
    }


    public void setParent(Node parent) {

        this.parent = parent;
    }


    @NotNull
    public Node getAstRoot() {
        if (parent == null) {
            return this;
        }
        return parent.getAstRoot();
    }


    public void addChildren(@Nullable Node... nodes) {
        if (nodes != null) {
            for (Node n : nodes) {
                if (n != null) {
                    n.setParent(this);
                }
            }
        }
    }


    public void addChildren(@Nullable Collection<? extends Node> nodes) {
        if (nodes != null) {
            for (Node n : nodes) {
                if (n != null) {
                    n.setParent(this);
                }
            }
        }
    }


    public void setFile(String file) {
        this.file = file;
    }


    @NotNull
    public static Type transformExpr(@NotNull Node n, State s) {
        return n.transform(s);
    }


    @NotNull
    protected abstract Type transform(State s);


    protected void addWarning(String msg) {
        Analyzer.self.putProblem(this, msg);
    }


    protected void addError(String msg) {
        Analyzer.self.putProblem(this, msg);
    }


    @NotNull
    protected Type resolveUnion(@NotNull Collection<? extends Node> nodes, State s) {
        Type result = Type.UNKNOWN;
        for (Node node : nodes) {
            Type nodeType = transformExpr(node, s);
            result = UnionType.union(result, nodeType);
        }
        return result;
    }


    @Nullable
    static protected List<Type> resolveList(@Nullable Collection<? extends Node> nodes, State s) {
        if (nodes == null) {
            return null;
        } else {
            List<Type> ret = new ArrayList<>();
            for (Node n : nodes) {
                ret.add(transformExpr(n, s));
            }
            return ret;
        }
    }


    // nodes are equal if they are from the same file and same starting point
    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof Node)) {
            return false;
        } else {
            Node node = (Node) obj;
            return (this.start == node.start &&
                    this.end == node.end &&
                    _.same(this.file, node.file));
        }
    }


    @Override
    public int hashCode() {
        return (file + ":" + start + ":" + end).hashCode();
    }


    public String toDisplay() {
        return "";
    }


    @NotNull
    @Override
    public String toString() {
        return "(node:" + file + ":" + name + ":" + start + ")";
    }

}
