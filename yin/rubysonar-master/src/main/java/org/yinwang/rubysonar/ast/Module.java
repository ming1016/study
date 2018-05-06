package org.yinwang.rubysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.rubysonar.Binding;
import org.yinwang.rubysonar.Constants;
import org.yinwang.rubysonar.State;
import org.yinwang.rubysonar._;
import org.yinwang.rubysonar.types.ModuleType;
import org.yinwang.rubysonar.types.Type;


public class Module extends Node {

    public Node locator;
    public Name name;
    public Block body;
    public Str docstring;


    public Module(Node locator, Block body, Str docstring, String file, int start, int end) {
        super(file, start, end);
        this.locator = locator;
        this.body = body;
        this.docstring = docstring;
        if (locator instanceof Attribute) {
            this.name = ((Attribute) locator).attr;
        } else if (locator instanceof Name) {
            this.name = (Name) locator;
        } else {
            _.die("illegal module locator: " + locator);
        }
        addChildren(locator, body);
    }


    @NotNull
    @Override
    public Type transform(@NotNull State s) {
        ModuleType mt = s.lookupOrCreateModule(locator, file);
        mt.table.insert(Constants.SELFNAME, name, mt, Binding.Kind.SCOPE);
        transformExpr(body, mt.table);
        return mt;
    }


    @NotNull
    @Override
    public String toString() {
        return "(module:" + locator + ")";
    }

}
