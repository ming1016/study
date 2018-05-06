package org.yinwang.yin.ast;


import org.yinwang.yin.Constants;
import org.yinwang.yin.Scope;
import org.yinwang.yin.TypeChecker;
import org.yinwang.yin._;
import org.yinwang.yin.value.*;

import java.util.*;

public class Call extends Node {
    public Node op;
    public Argument args;


    public Call(Node op, Argument args, String file, int start, int end, int line, int col) {
        super(file, start, end, line, col);
        this.op = op;
        this.args = args;
    }


    public Value interp(Scope s) {
        Value opv = this.op.interp(s);
        if (opv instanceof Closure) {
            Closure closure = (Closure) opv;
            Scope funScope = new Scope(closure.env);
            List<Name> params = closure.fun.params;

            // set default values for parameters
            if (closure.properties != null) {
                Declare.mergeDefault(closure.properties, funScope);
            }

            if (!args.positional.isEmpty() && args.keywords.isEmpty()) {
                for (int i = 0; i < args.positional.size(); i++) {
                    Value value = args.positional.get(i).interp(s);
                    funScope.putValue(params.get(i).id, value);
                }
            } else {
                // try to bind all arguments
                for (Name param : params) {
                    Node actual = args.keywords.get(param.id);
                    if (actual != null) {
                        Value value = actual.interp(funScope);
                        funScope.putValue(param.id, value);
                    }
                }
            }
            return closure.fun.body.interp(funScope);
        } else if (opv instanceof RecordType) {
            RecordType template = (RecordType) opv;
            Scope values = new Scope();

            // set default values for fields
            Declare.mergeDefault(template.properties, values);

            // instantiate
            return new RecordValue(template.name, template, values);
        } else if (opv instanceof PrimFun) {
            PrimFun prim = (PrimFun) opv;
            List<Value> args = Node.interpList(this.args.positional, s);
            return prim.apply(args, this);
        } else {  // can't happen
            _.abort(this.op, "calling non-function: " + opv);
            return Value.VOID;
        }
    }


    @Override
    public Value typecheck(Scope s) {
        Value fun = this.op.typecheck(s);
        if (fun instanceof FunType) {
            FunType funtype = (FunType) fun;
//            TypeChecker.self.uncalled.remove(funtype);

            Scope funScope = new Scope(funtype.env);
            List<Name> params = funtype.fun.params;

            // set default values for parameters
            if (funtype.properties != null) {
                Declare.mergeType(funtype.properties, funScope);
            }

            if (!args.positional.isEmpty() && args.keywords.isEmpty()) {
                // positional
                if (args.positional.size() != params.size()) {
                    _.abort(this.op,
                            "calling function with wrong number of arguments. expected: " + params.size()
                                    + " actual: " + args.positional.size());
                }

                for (int i = 0; i < args.positional.size(); i++) {
                    Value value = args.positional.get(i).typecheck(s);
                    Value expected = funScope.lookup(params.get(i).id);
                    if (!Type.subtype(value, expected, false)) {
                        _.abort(args.positional.get(i), "type error. expected: " + expected + ", actual: " + value);
                    }
                    funScope.putValue(params.get(i).id, value);
                }
            } else {
                // keywords
                Set<String> seen = new HashSet<>();

                // try to bind all arguments
                for (Name param : params) {
                    Node actual = args.keywords.get(param.id);
                    if (actual != null) {
                        seen.add(param.id);
                        Value value = actual.typecheck(funScope);
                        Value expected = funScope.lookup(param.id);
                        if (!Type.subtype(value, expected, false)) {
                            _.abort(actual, "type error. expected: " + expected + ", actual: " + value);
                        }
                        funScope.putValue(param.id, value);
                    } else {
                        _.abort(this, "argument not supplied for: " + param);
                        return Value.VOID;
                    }
                }

                // detect extra arguments
                List<String> extra = new ArrayList<>();
                for (String id : args.keywords.keySet()) {
                    if (!seen.contains(id)) {
                        extra.add(id);
                    }
                }

                if (!extra.isEmpty()) {
                    _.abort(this, "extra keyword arguments: " + extra);
                    return Value.VOID;
                }
            }

            Object retType = funtype.properties.lookupPropertyLocal(Constants.RETURN_ARROW, "type");
            if (retType != null) {
                if (retType instanceof Node) {
                    // evaluate the return type because it might be (typeof x)
                    return ((Node) retType).typecheck(funScope);
                } else {
                    _.abort("illegal return type: " + retType);
                    return null;
                }
            } else {
                if (TypeChecker.self.callStack.contains(fun)) {
                    _.abort(op, "You must specify return type for recursive functions: " + op);
                    return null;
                }

                TypeChecker.self.callStack.add((FunType) fun);
                Value actual = funtype.fun.body.typecheck(funScope);
                TypeChecker.self.callStack.remove(fun);
                return actual;
            }
        } else if (fun instanceof RecordType) {
            RecordType template = (RecordType) fun;
            Scope values = new Scope();

            // set default values for fields
            Declare.mergeDefault(template.properties, values);

            // set actual values, overwrite defaults if any
            for (Map.Entry<String, Node> e : args.keywords.entrySet()) {
                if (!template.properties.keySet().contains(e.getKey())) {
                    _.abort(this, "extra keyword argument: " + e.getKey());
                }

                Value actual = args.keywords.get(e.getKey()).typecheck(s);
                Value expected = template.properties.lookupLocalType(e.getKey());
                if (!Type.subtype(actual, expected, false)) {
                    _.abort(this, "type error. expected: " + expected + ", actual: " + actual);
                }
                values.putValue(e.getKey(), e.getValue().typecheck(s));
            }

            // check uninitialized fields
            for (String field : template.properties.keySet()) {
                if (values.lookupLocal(field) == null) {
                    _.abort(this, "field is not initialized: " + field);
                }
            }

            // instantiate
            return new RecordValue(template.name, template, values);
        } else if (fun instanceof PrimFun) {
            PrimFun prim = (PrimFun) fun;
            if (prim.arity >= 0 && args.positional.size() != prim.arity) {
                _.abort(this, "incorrect number of arguments for primitive " +
                        prim.name + ", expecting " + prim.arity + ", but got " + args.positional.size());
                return null;
            } else {
                List<Value> args = Node.typecheckList(this.args.positional, s);
                return prim.typecheck(args, this);
            }
        } else {
            _.abort(this.op, "calling non-function: " + fun);
            return Value.VOID;
        }

    }


    public String toString() {
        if (args.positional.size() != 0) {
            return "(" + op + " " + args + ")";
        } else {
            return "(" + op + ")";
        }
    }

}
