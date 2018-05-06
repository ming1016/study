package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.Analyzer;
import org.yinwang.pysonar.Binding;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.Type;

import java.util.List;
import java.util.Set;


public class Name extends Node {

    @NotNull
    public final String id;  // identifier
    public NameType type;


    public Name(String id) {
        // generated name
        this(id, null, -1, -1);
    }


    public Name(@NotNull String id, String file, int start, int end) {
        super(file, start, end);
        this.id = id;
        this.name = id;
        this.type = NameType.LOCAL;
    }


    public Name(@NotNull String id, NameType type, String file, int start, int end) {
        super(file, start, end);
        this.id = id;
        this.type = type;
    }


    @NotNull
    @Override
    public Type transform(@NotNull State s) {
        Set<Binding> b = s.lookup(id);
        if (b != null) {
            Analyzer.self.putRef(this, b);
            Analyzer.self.resolved.add(this);
            Analyzer.self.unresolved.remove(this);
            return State.makeUnion(b);
        } else if (id.equals("True") || id.equals("False")) {
            return Type.BOOL;
        } else {
            Analyzer.self.putProblem(this, "unbound variable " + id);
            Analyzer.self.unresolved.add(this);
            Type t = Type.UNKNOWN;
            t.table.setPath(s.extendPath(id));
            return t;
        }
    }


    /**
     * Returns {@code true} if this name node is the {@code attr} child
     * (i.e. the attribute being accessed) of an {@link Attribute} node.
     */
    public boolean isAttribute() {
        return parent instanceof Attribute
                && ((Attribute) parent).attr == this;
    }


    @NotNull
    @Override
    public String toString() {
        return "(" + id + ":" + start + ")";
    }


    @NotNull
    @Override
    public String toDisplay() {
        return id;
    }

}
