package org.yinwang.rubysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.rubysonar.Analyzer;
import org.yinwang.rubysonar.Binding;
import org.yinwang.rubysonar.Constants;
import org.yinwang.rubysonar.State;
import org.yinwang.rubysonar.types.Type;

import java.util.List;


public class Name extends Node {

    @NotNull
    public final String id;  // identifier
    public NameType type;


    public Name(String id) {
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
        List<Binding> b = null;

        if (isInstanceVar()) {
            Type thisType = s.lookupType(Constants.INSTNAME);
            if (thisType != null) {
                b = thisType.table.lookup(id);
            }
        } else if (Analyzer.self.staticContext) {
            b = s.lookupTagged(id, "class");
            if (b == null) {
                b = s.lookup(id);
            }
        } else {
            b = s.lookup(id);
        }

        if (b != null) {
            Analyzer.self.putRef(this, b);
            Analyzer.self.resolved.add(this);
            Analyzer.self.unresolved.remove(this);
            return State.makeUnion(b);
        } else if (id.equals("true") || id.equals("false")) {
            return Type.BOOL;
        } else {
            Analyzer.self.putProblem(this, "unbound variable " + id);
            return Type.UNKNOWN;
        }
    }


    /**
     * Returns {@code true} if this name node is the {@code attr} child
     * (i.e. the attribute being accessed) of an {@link Attribute} node.
     */
    public boolean isAttribute() {
        return parent instanceof Attribute
                && ((Attribute) parent).getAttr() == this;
    }


    public boolean isInstanceVar() {
        return type == NameType.INSTANCE;
    }


    public boolean isGlobalVar() {
        return type == NameType.GLOBAL;
    }


    @NotNull
    @Override
    public String toDisplay() {
        return id;
    }


    @NotNull
    @Override
    public String toString() {
        return "(" + id + ":" + start + ")";
    }


}
