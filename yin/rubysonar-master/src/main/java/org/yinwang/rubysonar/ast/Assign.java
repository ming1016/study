package org.yinwang.rubysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.rubysonar.*;
import org.yinwang.rubysonar.types.Type;


public class Assign extends Node {

    @NotNull
    public Node target;
    @NotNull
    public Node value;


    public Assign(@NotNull Node target, @NotNull Node value, String file, int start, int end) {
        super(file, start, end);
        this.target = target;
        this.value = value;
        addChildren(target);
        addChildren(value);
    }


    @NotNull
    @Override
    public Type transform(@NotNull State s) {
        Type valueType = transformExpr(value, s);
        if (target instanceof Name && ((Name) target).isInstanceVar()) {
            Type thisType = s.lookupType(Constants.INSTNAME);
            if (thisType == null) {
                Analyzer.self.putProblem(this, "Instance variable assignment not within class");
            } else {
                thisType.table.insert(((Name) target).id, target, valueType, Binding.Kind.SCOPE);
            }
        } else if (s.stateType == State.StateType.CLASS &&
                target instanceof Name && ((Name) target).id.toUpperCase().equals(((Name) target).id))
        {
            // constant
            s.insertTagged(((Name) target).id, "class", target, valueType, Binding.Kind.CONSTANT);
        } else {
            Binder.bind(s, target, valueType);
        }
        return valueType;
    }


    @NotNull
    @Override
    public String toString() {
        return "(" + target + " = " + value + ")";
    }


}
