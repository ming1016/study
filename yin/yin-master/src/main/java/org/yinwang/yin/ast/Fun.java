package org.yinwang.yin.ast;


import org.yinwang.yin.Constants;
import org.yinwang.yin.Scope;
import org.yinwang.yin.TypeChecker;
import org.yinwang.yin.value.Closure;
import org.yinwang.yin.value.FunType;
import org.yinwang.yin.value.Value;

import java.util.List;

public class Fun extends Node {
    public List<Name> params;
    public Node body;
    public Scope propertyForm;


    public Fun(List<Name> params, Scope propertyForm, Node body, String file, int start, int end, int line, int col) {
        super(file, start, end, line, col);
        this.params = params;
        this.propertyForm = propertyForm;     // unevaluated property form
        this.body = body;
    }


    public Value interp(Scope s) {
        // evaluate and cache the properties in the closure
        Scope properties = propertyForm == null ? null : Declare.evalProperties(propertyForm, s);
        return new Closure(this, properties, s);
    }


    @Override
    public Value typecheck(Scope s) {
        // evaluate and cache the properties in the closure
        Scope properties = propertyForm == null ? null : Declare.typecheckProperties(propertyForm, s);
        FunType ft = new FunType(this, properties, s);
        TypeChecker.self.uncalled.add(ft);
        return ft;
    }


    public String toString() {
        return "(" + Constants.FUN_KEYWORD + " (" + params + ") " + body + ")";
    }

}
